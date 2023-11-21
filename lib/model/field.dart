import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:csv/csv.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

import '../constant.dart';
import 'customized_parameters.dart';
import 'measured_data.dart';

final double _APPi = 0.8 *
    1.00; // Area per plant (row x interRow spacing) (m2); PC edited the value from 0.60*0.60 to 0.80*1.00 based on data from BRR2021-Y1.
final int _nsl = 5; // number of soil layers
//double _depth = 0.9; // soil depth in m
late final double _lw = 0.9 / _nsl; //depth/_nsl;// thickness of a layer in m
//double layers      = 0:(_nsl-1) * depth/_nsl;// soil layer positions
late final double _lvol =
    _lw * _APPi; //depth*_APPi/_nsl;// volume of one soil layer
// unit conversion factors
//double s_day = 60 * 60 * 24;
//double m_day = 60 * 24;
//double m5_day = 12 * 24;
final double _BD =
    1360; // soil bulk density in (kg/m3) # Burrirum 1.36, Ratchaburi 1.07 g.cm3
//double raiInm2 = 1600; // area of one rai in m2

double _cuttingDryMass = 75.4; //g
double _leafAge = 75;
double _SRL = 39.0; //m/g

double _iStart = 0;
double _iend = 0;
bool _zerodrain = true;
//double _igstart = 0;
//double _igend = 0;
//todo needs to be based on planting date provided by user.then weather should start at right point
double _iTheta = 0.22;
double _thm = 0.18; //drier todo make
double _ths = 0.3; //field capacity, not saturation todo rename
double _thr = 0.015; // residual water content
double _thg = 0.02;
double _rateFlow = 1.3;

//todo helper function
double relTheta(double th) {
  return (lim((th - _thr) / (_ths - _thr)));
}

double lim(double x, {double xl = 0, double xu = 1}) {
  if (x > xu) {
    return (xu);
  } else if (x < xl) {
    return (xl);
  } else {
    return x;
  }
}

List<double> multiplyLists(List<double> l1, List<double> l2) {
  var n = min(l1.length, l2.length);
  return (new List<double>.generate(n, (i) => l1[i] * l2[i]));
}

List<double> multiplyListsWithConstant(List<double> l, double c) {
  return (new List<double>.generate(l.length, (i) => l[i] * c));
  //return(l.map( (number) => number *c));
}

double getStress(double clab, double dm,
    {double low = -0.02, double high = -9999.9, bool swap = false}) {
  if (high < -9999.0) high = low + 0.01;
  final dm1 = max(dm, 0.001);
  final cc = clab / dm1;
  var rr = lim((cc - low) / (high - low));
  if (swap) rr = 1.0 - rr;
  return (rr);
}

double monod(double conc, {double Imax = 0.0, double Km = 1.0}) {
  double pc = max(0.0, conc);
  return (pc * Imax / (Km + pc));
}

double logistic(double x,
    {double x0 = 0.33, double xc = 100, double k = 0.2, double m = 0.85}) {
  return (x0 + (m - x0) / (1 + exp(-k * (x - xc))));
}

double photoFixMean(double ppfd, double lai,
    {double kdf = -0.47,
    double Pn_max = 29.37,
    double phi = 0.05553,
    double k = 0.90516}) {
  double r = 0;
  int n = 30; //higher more precise, lower faster
  double b = 4 * k * Pn_max;
  for (int i = 0; i < n; ++i) {
    double kf = exp(kdf * lai * (i + 0.5) / n);
    double I = ppfd * kf;
    double x0 = phi * I;
    double x1 = x0 + Pn_max;
    double p = x1 - sqrt(x1 * x1 - b * x0);
    r += p;
  }
  r *= -12e-6 * 60 * 60 * 24 * kdf * _APPi * lai / n / (2 * k);
  return (r);
}

double fSLA(ct) {
  return (logistic(ct, x0: 0.04, xc: 60, k: 0.1, m: 0.0264));
}

// water uptake
fKroot(th, rl) {
  final rth = relTheta(th);
  final kadj = min(1.0, pow(rth / 0.4, 1.5));
  final Ksr = 0.01;
  return (Ksr * kadj * rl);
}

fWaterStress(minV, maxV, the) {
  final s = 1 / (maxV - minV);
  final i = -1 * minV * s;
  return (lim(i + s * relTheta(the)));
}

class Field {
  String fieldName;
  int dAP; //day after plant
  String startTime;
  bool irrigationCheck; //(determined from model or adjust by user)
  double amountOfIrrigation; // luong nuoc tuoi tieu (mm/day)
  List<double> yields; // predicted by model
  String checkYieldDate; //
  CustomizedParameters customizedParameters;
  MeasuredData measuredData;
  String startIrrigation;
  String endIrrigation;
  double _autoIrrigateTime = -1;
  List<List<double>> _results = [];
  final int _iTime = 0;
  final int _iDOY = 0;
  final _iRadiation = 4;
  final _iRain = 1;
  final int _iRH = 5;
  final _iTemp = 3;
  final int _iWind = 6;
  final int _iIrrigation = 7;

  Field(
      this.fieldName,
      this.startTime,
      this.dAP,
      this.irrigationCheck,
      this.amountOfIrrigation,
      this.yields,
      this.checkYieldDate,
      this.customizedParameters,
      this.measuredData,
      this.startIrrigation,
      this.endIrrigation);

  Field.newOne(String name)
      : fieldName = name,
        startTime = DateTime.now().toString(),
        dAP = 0,
        irrigationCheck = false,
        amountOfIrrigation = 0,
        yields = [0],
        checkYieldDate = "",
        customizedParameters = CustomizedParameters.newOne(name),
        measuredData = MeasuredData.newOne(name),
        startIrrigation = '',
        endIrrigation = '';

  /// todo getData

  Future<void> getAutoIrrigationFromDb() async {
    await customizedParameters.getAutoIrrigationFromDb();
  } //(done)

  Future<void> getCustomizedParametersFromDb() async {
    await customizedParameters.getDataFromDb();
  } //(done)

  Future<void> getMeasuredDataFromDb() async {
    // await writeWeatherDataToCsvFile();
    // await loadAllWeatherDataFromCsvFile();
    // var data = _weatherData.last;
    // this.measuredData.radiation = data[_iRadiation];
    // this.measuredData.rainFall = data[_iRain];
    // this.measuredData.relativeHumidity = data[_iRH];
    // this.measuredData.temperature = data[_iTemp];
    // this.measuredData.windSpeed = data[_iWind];
    this.measuredData.getWeatherDataFromDb();
    this.measuredData.getHumidityDataFromDb();
  }

  Future<void> getIrrigationCheckFromDb() async {
    DataSnapshot snapshot = await FirebaseDatabase.instance
        .ref('${Constant.USER}/${this.fieldName}/${Constant.IRRIGATION_CHECK}')
        .get();
    var a = snapshot.value.toString().toLowerCase();
    if (a == 'true')
      this.irrigationCheck = true;
    else
      this.irrigationCheck = false;
  }

  Future<void> getGeneralDataFromDb() async {
    DataSnapshot snapshot = await FirebaseDatabase.instance
        .ref('${Constant.USER}/${this.fieldName}')
        .get();
    var a = snapshot.child('${Constant.IRRIGATION_CHECK}').value;
    if (a.toString() == 'true')
      this.irrigationCheck = true;
    else
      this.irrigationCheck = false;
    a = snapshot.child('${Constant.START_IRRIGATION}').value;
    this.startIrrigation = a.toString();
    a = snapshot.child('${Constant.END_IRRIGATION}').value;
    this.endIrrigation = a.toString();
    a = snapshot.child('${Constant.START_TIME}').value;
  }

  Future<void> getDataFromDb() async {
    await getGeneralDataFromDb();
    await getCustomizedParametersFromDb();
    // await getMeasuredDataFromDb();
  }

  Future<void> updateGeneralDataToDb() async {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('${Constant.USER}/${this.fieldName}');
    ref.update({
      "${Constant.START_IRRIGATION}": this.startIrrigation,
      "${Constant.END_IRRIGATION}": this.endIrrigation
    });
  }

  List<List<dynamic>> _weatherData = [];

  Future<List<List<dynamic>>> loadAllWeatherDataFromCsvFile() async {
    String csvData = await rootBundle.loadString('assets/images/weather_Thailand.csv');

    // Lấy thư mục ứng dụng trên thiết bị
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    // Tạo đường dẫn cho tệp CSV trên thiết bị
    String csvFilePath = '$appDocPath/data_weather.csv';
    List<List<dynamic>> weatherData = [];
    String path = "";
    final String directory = (await getApplicationSupportDirectory()).path;
    path = csvFilePath;
    final csvFile = new File(path).openRead();
    weatherData = await csvFile
        .transform(utf8.decoder)
        .transform(
          CsvToListConverter(),
        )
        .toList();
    _weatherData = weatherData;
    return weatherData;
  }

  //todo predict yield of the field day by day (test)
  List<double> predictYield() {
    return yields = _results[0];
  }

  List<double> getTopSoilWetness() {
    List<double> r = _results[1];
    var cr =
        r.map((el) => double.parse((100.0 * relTheta(el)).toStringAsFixed(2)));
    return cr.toList();
  }

  List<double> getIrrigation() {
    List<double> r = List.generate(
        _results[2].length, (index) => _results[2][index].roundToDouble());
    return r;
  }

  List<double> getDoy() {
    List<double> r = List.generate(
        _results[8].length, (index) => _results[8][index].roundToDouble());
    return r;
  }

  List<double> getLai() {
    List<double> r = List.generate(_results[3].length,
        (index) => double.parse((_results[3][index]).toStringAsFixed(2)));
    return r;
  }

  List<double> getCLab() {
    List<double> r = List.generate(_results[4].length,
        (index) => double.parse((_results[4][index]).toStringAsFixed(2)));
    return r;
  }

  List<double> getPhotoSynthesis() {
    List<double> r = List.generate(_results[5].length,
        (index) => double.parse((_results[5][index]).toStringAsFixed(2)));
    return r;
  }

  List<double> getTopsoilNContent() {
    List<double> r = List.generate(_results[6].length,
        (index) => double.parse((_results[6][index]).toStringAsFixed(2)));
    return r;
  }

  List<double> getNStatus() {
    List<double> r = List.generate(_results[7].length,
        (index) => double.parse((_results[7][index]).toStringAsFixed(2)));
    return r;
  }

  List<DateTime> getResultDay() {
    List<DateTime> r = List.generate(
        _results[8].length, (index) => _getDay(_results[8][index]));
    return r;
  }

  DateTime getDay(double day) {
    return _getDay(day);
  }

  Future<List<List<dynamic>>> _getAllWeatherDataFromDb(
      bool check, DateTime dateTime) async {
    List<List<dynamic>> data = [];
    DataSnapshot snapshot = await FirebaseDatabase.instance
        .ref('${Constant.USER}/${this.fieldName}/${Constant.MEASURED_DATA}')
        .orderByKey()
        .get();
    if (snapshot.exists) {
      for (var day in snapshot.children) {
        for (var j = 0; j < day.children.length; j++) {
          DataSnapshot time = day.children.elementAt(j);
          DateTime timeToCompare =
              DateTime.parse("${day.key.toString()} ${time.key.toString()}");

          if (check) {
            if (timeToCompare.isBefore(dateTime) ||
                timeToCompare.isAtSameMomentAs(dateTime)) continue;
          }

          var timeField = time.child('time').value.toString();
          double doy =
              double.parse(_getDoy(DateTime.parse(timeField)).toString());
          double radiation = double.parse(
              time.child('${Constant.RADIATION}').value.toString());
          double rain = double.parse(
              time.child('${Constant.RAIN_FALL}').value.toString());
          double relativeHumidity = double.parse(
              time.child('${Constant.RELATIVE_HUMIDITY}').value.toString());
          double temperature = double.parse(
              time.child('${Constant.TEMPERATURE}').value.toString());
          double wind = double.parse(
              time.child('${Constant.WIND_SPEED}').value.toString());
          var result = [
            timeField,
            doy,
            radiation,
            rain,
            relativeHumidity,
            temperature,
            wind,
            0.0 //for irrigation
          ];
          data.add(result);
        }
      }
      data.sort((a, b) => a[1].compareTo(b[1]));
    }
    data.add([]);
    return data;
  }

  createWeatherDataFile() async {
    List<List<dynamic>> data = [
      [
        "Time",
        "Doy",
        "Radiation",
        "Rain",
        "Relative Humidity",
        "Temperature",
        "Wind",
        "Irrigation"
      ],
      []
    ];
    String csvData = ListToCsvConverter().convert(data);
    final String directoryPath = (await getApplicationSupportDirectory()).path;
    final Directory _userDirectory =
        Directory('$directoryPath/${Constant.USER}');
    final String _userDirectoryPath;
    if (await _userDirectory.exists()) {
      _userDirectoryPath = _userDirectory.path;
    } else {
      final Directory _newDirectory =
          await _userDirectory.create(recursive: true);
      _userDirectoryPath = _newDirectory.path;
    }
    final path = "$_userDirectoryPath/${this.fieldName}.csv";
    final File file = File(path);
    await file.writeAsString(csvData);
  }

  // todo update weather csv file
  writeWeatherDataToCsvFile() async {
    final String directory = (await getApplicationSupportDirectory()).path;
    final path = "$directory/${Constant.USER}/${this.fieldName}.csv";
    final File file = File(path);
    if (await file.exists() == false) {
      await createWeatherDataFile();
    }
    //checking for add new data from database
    List<List<dynamic>> listData = [];
    final csvFile = new File(path).openRead();
    listData = await csvFile
        .transform(utf8.decoder)
        .transform(
          CsvToListConverter(),
        )
        .toList();
    bool check = true;
    if (listData.length < 2) {
      check = false;
    }
    DateTime dateTime = DateTime.now(); // for initialize
    if (check == true) {
      var s = listData[listData.length - 1][_iTime];
      dateTime = DateTime.parse(s);
    }

    //update data
    List<List<dynamic>> data = [];
    await _getAllWeatherDataFromDb(check, dateTime).then((value) => {
          for (var index in value) data.add(index),
        });

    String csvData = ListToCsvConverter().convert(data);
    await file.writeAsString(csvData, mode: FileMode.append);
  }

  downloadWeatherDataFile() async {
    String? directory = "";
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      //add more permission to request here.
    ].request();
    if (statuses[Permission.storage]!.isGranted) {
      var dir = await DownloadsPathProvider.downloadsDirectory;
      if (dir != null) {
        String saveName = "${this.fieldName}.csv";
        var directoryPath = dir.path;

        final Directory _userDirectory =
            Directory('$directoryPath/${Constant.USER}');
        final String _userDirectoryPath;
        if (await _userDirectory.exists()) {
          _userDirectoryPath = _userDirectory.path;
        } else {
          final Directory _newDirectory =
              await _userDirectory.create(recursive: true);
          _userDirectoryPath = _newDirectory.path;
        }

        String savePath = _userDirectoryPath + "/$saveName";
        final File file = File(savePath);
        String csvData = ListToCsvConverter().convert(_weatherData);
        await file.writeAsString(csvData);
      }
    }
  }

  runModel() async {
    //update data
    // await writeWeatherDataToCsvFile();
    // await createCsvFileFromAsset();
    await loadAllWeatherDataFromCsvFile();
    // await getCustomizedParametersFromDb();
    //run model
    await _simulate();
    // if (this.customizedParameters.autoIrrigation) _updateAutoIrrigationInfo();
    // if (this.customizedParameters.autoIrrigation) updateIrrigationToDb();
  }

//in order to displaying for user
  double getIrrigationAmount() {
    var length = _results[2].length;
    double irr = (length > 1)
        ? _results[2].last - _results[2][length - 2]
        : _results[2][0];
    return irr * 0.1; //convert from m3/ha to l/m2
  }

  String getIrrigationTime() {
    var day = _getDay(_results[8].last);
    String formattedDate = DateFormat('dd-MM-yyyy').format(day);
    return formattedDate;
  }

//write to db
  _updateAutoIrrigationInfo() {
    var length = _results[2].length;
    double irr = (length > 1)
        ? _results[2].last - _results[2][length - 2]
        : _results[2][0];
    irr *= 0.1; // convert to l/m2
    var duration = irr *
        this.customizedParameters.acreage /
        (this.customizedParameters.dripRate *
            this.customizedParameters.numberOfHoles) *
        3600; //convert to second
    DateTime day = _getDay(_results[8].last);
    day.add(Duration(hours: 8));
    DateTime d = DateTime (day.year, day.month, day.day, 8, day.minute, day.second);
    final Map<String, dynamic> updates = {};
    updates["${Constant.IRRIGATION_INFORMATION}"] = {
      "amount": irr,
      "duration": duration,
      "time": d.toString(),
      // "${day}": tIrr
    };
    FirebaseDatabase.instance
        .ref('${Constant.USER}/${this.fieldName}')
        .update(updates);
  }

  //return doy
  // double nextIrrigationDate() {
  //   double current = _getDoy(DateTime.now());
  //   double doy = -1;
  //   doy = _results[8].last + 1; // irrigation for the next day
  //   return doy - current;
  // }

  Future<void> updateIrrigationToDb() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(
        '${Constant.USER}/${this.fieldName}/${Constant.IRRIGATION_INFORMATION}');
    await ref.update({
      "amount": this.nextIrrigationAmount(),
      "time": DateUtils.dateOnly(DateTime.now())
    });
  }

  double nextIrrigationAmount() {
    double r = -1;
    int length = _results[2].length;
    r = _results[2][length - 1] - _results[2][length - 2];
    return r;
  }

  double hourlyET(
      final tempC,
      final radiation,
      final relativeHumidity,
      final wind,
      final doy,
      final latitude,
      final longitude,
      final elevation,
      final longZ,
      final height) {
    final hours = (doy % 1) * 24;
    final tempK = tempC + 273.16;

    final Rs = radiation * 3600 / 1e+06; // radiation mean Ra
    final P = 101.3 *
        pow((293 - 0.0065 * elevation) / 293,
            5.256); // cong thuc tinh ap suat khong khi o do cao elevation
    final psi = 0.000665 * P; // cong thuc tinh gamma

    final Delta = 2503 *
        exp((17.27 * tempC) / (tempC + 237.3)) /
        (pow(tempC + 237.3, 2)); // cong thuc tinh delta- cai hinh tam giac
    final eaSat = 0.61078 *
        exp((17.269 * tempC) /
            (tempC +
                237.3)); // cong thuc tinh ap suat hoi bao hoa tai nhiet do K
    final ea = (relativeHumidity / 100) * eaSat;

    final DPV = eaSat - ea;
    final dr = 1 + 0.033 * (cos(2 * pi * doy / 365.0)); //dr
    final delta = 0.409 *
        sin((2 * pi * doy / 365.0) -
            1.39); // cong thuc tinh delta nhung cai hinh cai moc
    final phi = latitude * (pi / 180);
    final b = 2.0 * pi * (doy - 81.0) / 364.0;

    final Sc = 0.1645 * sin(2 * b) - 0.1255 * cos(b) - 0.025 * sin(b);
    final hourAngle = (pi / 12) *
        ((hours +
                0.06667 * (longitude * pi / 180.0 - longZ * pi / 180.0) +
                Sc) -
            12.0); // w
    final w1 = hourAngle - ((pi) / 24);
    final w2 = hourAngle + ((pi) / 24);
    final hourAngleS = acos(-tan(phi) * tan(delta)); // Ws
    final w1c = (w1 < -hourAngleS)
        ? -hourAngleS
        : (w1 > hourAngleS)
            ? hourAngleS
            : (w1 > w2)
                ? w2
                : w1;
    final w2c = (w2 < -hourAngleS)
        ? -hourAngleS
        : (w2 > hourAngleS)
            ? hourAngleS
            : w2;

    final Beta =
        asin((sin(phi) * sin(delta) + cos(phi) * cos(delta) * cos(hourAngle)));

    final Ra = (Beta <= 0)
        ? 1e-45
        : ((12 / pi) * 4.92 * dr) *
            (((w2c - w1c) * sin(phi) * sin(delta)) +
                (cos(phi) * cos(delta) * (sin(w2) - sin(w1))));

    final Rso = (0.75 + 2e-05 * elevation) * Ra;

    final RsRso = (Rs / Rso <= 0.3)
        ? 0.0
        : (Rs / Rso >= 1)
            ? 1.0
            : Rs / Rso;
    final fcd = (1.35 * RsRso - 0.35 <= 0.05)
        ? 0.05
        : (1.35 * RsRso - 0.35 < 1)
            ? 1.35 * RsRso - 0.35
            : 1;

    final Rna = ((1 - 0.23) * Rs) -
        (2.042e-10 *
            fcd *
            (0.34 - 0.14 * sqrt(ea)) *
            pow(tempK, 4)); // cong thuc tinh Rn

    final Ghr = (Rna > 0)
        ? 0.04
        : 0.2; // G for hourly depend on Rna (or Rn in EThourly)

    final Gday = Rna * Ghr;
    final wind2 = wind * (4.87 / (log(67.8 * height - 5.42)));
    final windf = (radiation > 1e-6) ? 0.25 : 1.7;

    final EThourly = ((0.408 * Delta * (Rna - Gday)) +
            (psi * (66 / tempK) * wind2 * (DPV))) /
        (Delta + (psi * (1 + (windf * wind2))));

    return (EThourly);
  }

  Future<void> _simulate() async {
    _iStart = _weatherData[1][_iDOY].toDouble();
    _iend = _weatherData[_weatherData.length - 1][_iDOY].toDouble();
    _autoIrrigateTime = -1;
    var w = ode2initValues(); //initialize to start simulate
    _results = [];
    for (var i = 0; i < 9; i++) {
      _results.add([]);
    }
    var day = 0;
    for (int i = 2; i < _weatherData.length - 1; i++) {
      //get weather data
      List<double> wd = []; //weatherData
      var rain = (_weatherData[i][_iRain]).toDouble();
      wd.add(rain); //wd[0]
      var tempC = (_weatherData[i][_iTemp]).toDouble();
      wd.add(tempC); //wd[1]
      var radiation = _weatherData[i][_iRadiation];
      wd.add(2.5 *
          radiation); // ppfd = 2.5 * radiation, wd[2], photosynthetic photon flux density
      var relativeHumidity = _weatherData[i][_iRH];
      var wind = _weatherData[i][_iWind];
      var doy = _weatherData[i][_iDOY];
      var et0 = hourlyET(
          tempC,
          radiation,
          relativeHumidity,
          wind,
          doy,
          Constant.latitude,
          Constant.longitude,
          Constant.elevation,
          Constant.longitude,
          Constant.height);
      wd.add(et0); //wd[3]
      var irr = _weatherData[i][_iIrrigation];
      wd.add(0.0); //for irrigation,wd[4]
      var dt = (_weatherData[i][_iDOY] - _weatherData[i - 1][_iDOY]).toDouble();
      wd.add(dt);

      //do step
      rk4Step(doy - _iStart, w, dt, wd);

      //if the next time is in a next day
      if (_weatherData[i + 1][_iDOY].floor() - doy.floor() > 0) {
        //day = doy.ceil();
        _results[0]
            .add(w[3] * 10 / _APPi); //yield, convert g/plant to kg/ha (default)
        _results[1].add(w[9 + 2 * _nsl]); //theta
        _results[2].add(w[9 + 5 * _nsl]); //irrigation
        _results[3].add(w[4] / _APPi); //lai
        _results[4].add(
            100.0 + 100.0 * w[8] / max(1.0, w[0] + w[1] + w[2] + w[3])); //clab
        _results[5].add(w[9 + 5 * _nsl + 5]); //photo
        _results[6].add(w[9 + 3 * _nsl]); //topsoil ncont
        int ri = 9 + 4 * _nsl;
        final Nopt = 45 * w[0] + 2 * w[3] + 20 * w[1] + 20 * w[2];
        _results[7].add((w.sublist(ri, ri + _nsl))
                .reduce((value, element) => value + element) /
            max(1.0, Nopt)); //nupt
        _results[8].add(doy); //doy
        day++;
      }
    }
  }

  List<double> ode2(final double ct, final List<double> y, List<double> wd) {
    int cnt = -1;
    final LDM = y[++cnt]; // Leaf Dry Mass (g)
    final SDM = y[++cnt]; // Stem Dry Mass (g)
    final RDM = y[++cnt]; // Root Dry Mass (g)
    final SRDM = y[++cnt]; // Storage Root Dry Mass (g)
    final LA = y[++cnt]; // Leaf Area (m2)

    final mDMl = y[++cnt]; //intgrl("mDMl", 0, "mGRl");
    //var mDMld = y[7];//intgrl("mDMld", 0, "mGRld");
    final mDMs = y[++cnt]; //intgrl("mDMs", cuttingDryMass, "mGRs");
    //final mDM = y[9];//intgrl("mDM", 0, "mGR");
    ++cnt; //final mDMsr = y[++cnt]; //intgrl("mDMsr", 0, "mGRsr");
    //final TR = intgrl("TR", 0, "RR"); // Total Respiration (g C)
    final Clab = y[++cnt]; // labile carbon pool
    ++cnt;
    final rlL = y.sublist(cnt, cnt += _nsl); //Root length per layer (m)
    //final RL = sumList(RL_l); // Root length (m)

    final nrtL = y.sublist(cnt, cnt += _nsl); //Root tips per layer
    final NRT = nrtL.reduce((value, element) => value + element); // Root tips
    final thetaL = y.sublist(
        cnt, cnt += _nsl); //volumetric soil water content for each layer

    //final Ncont_l   = intgrl("Ncont",[4.83+35, 10.105, 16.05]*_lvol*BD,"NcontR");// N-content in a soil layer (mg);
    final ncontL = y.sublist(cnt, cnt += _nsl);
    final nuptL = y.sublist(cnt, cnt += _nsl);
    final Nupt = nuptL.reduce((value, element) => value + element);

    final TDM = LDM + SDM + RDM + SRDM + Clab; // Total Dry Mass (g)
    final cDm = 0.43; // carbon to dry matter ratio (g C/g DM)

    // temperature
    final leafTemp = wd[1]; //return ([rain, temp, ppfd, et0, irri])
    /*  fitted to El-Sharkawy-etal-1984-fig2 with adj R2 of 0.8709
    and divided by the max value of 27.24, which is slightly lower than our Pnmax
    (Intercept) d$temperature          d$x2
 -0.832097717   0.124485738  -0.002114081 */
    final TSphot = lim(-0.832097717 +
        0.124485738 * leafTemp -
        0.002114081 * pow(leafTemp, 2)); // todo temperature curve fitting

    final TSshoot = lim(-1.5 + 0.125 * leafTemp) * lim(7.4 - 0.2 * leafTemp);
    final TSroot = 1.0; // effect of temperature on root sink strength

// water uptake
//     fKroot(th, rl) {
//       final rth = relTheta(th);
//       final kadj = min(1.0, pow(rth / 0.4, 1.5));
//       final Ksr = 0.01;
//       return (Ksr * kadj * rl);
//     }

    final krootL =
        new List<double>.generate(_nsl, (i) => fKroot(thetaL[i], rlL[i]));
    final Kroot = max(
        1e-8,
        krootL.reduce(
            (value, element) => value + element)); //sums up all elements.
    final thEquiv = Kroot > 1e-8
        ? (multiplyLists(thetaL, krootL))
                .reduce((value, element) => value + element) /
            Kroot
        : thetaL[0]; //equivalent soil water potential

    //water stress
    fWstress(minv, maxv, the) {
      final s = 1 / (maxv - minv);
      final i = -1 * minv * s;
      return (lim(i + s * relTheta(the)));
    }

    final WStrans = fWstress(0.05, 0.5,
        thEquiv); //*(1.0-fWstress(0.9, 1.0, thEquiv));//feddes like todo look at DSSAT
    final WSphot =
        fWstress(0.05, 0.3, thEquiv); //*(1.0-fWstress(0.9, 1.0, thEquiv));
    final WSshoot =
        fWstress(0.2, 0.55, thEquiv); //*(1.0-fWstress(0.9, 1.0, thEquiv));
    final WSroot = 1;
    final WSleafSenescence = 1.0 -
        fWstress(0.0, 0.2, thEquiv); // 0 for non, 1 for enhanced scenescence

    // water in soil
    //irrigation either not (rained), or from file, or auto.
    // file/auto should switch on current date?
    var irrigation = this.customizedParameters.autoIrrigation
        ? wd[4]
        : 0.0; //return ([rain, temp, ppfd, et0, irri])
    //auto irrigation if necessary and not provided by file.
    //todo, switching maybe not 100% stable in numerical scheme. should be ok with rk4
    var _fcThreshHold = this.customizedParameters.fieldCapacity;
    _fcThreshHold *= (_ths - _thr) / 100;
    _fcThreshHold += _thr;
    //var _autoIrrigateTime = _getDoy(DateTime.parse(this.startIrrigation));
    //var _stopIrrigation = _getDoy(DateTime.parse(this.endIrrigation));
    var _autoIrrigationDuration = this.customizedParameters.irrigationDuration /
        24; //convert from hour to day
    var dhr = this.customizedParameters.dripRate; // l/hour
    var dhd = this.customizedParameters.distanceBetweenHoles; //cm
    var dld = this.customizedParameters.distanceBetweenRows; //cm
    var _autoIrrigate = dhr * 24.0 / (dhd * dld / 10000.0);
    if (irrigation < 1e-6 &&
        _autoIrrigateTime < ct + _autoIrrigationDuration &&
        _fcThreshHold > _thr &&
        thEquiv < _fcThreshHold) {
      _autoIrrigateTime = ct;
    }
    if (ct < _autoIrrigateTime + _autoIrrigationDuration) {
      irrigation += _autoIrrigate;
    }

    final precipitation = this.customizedParameters.scaleRain / 100 * wd[0] +
        irrigation; //return ([rain, temp, ppfd, et0, irri])

    // Transpiration
    final ET0reference = wd[3]; //return ([rain, temp, ppfd, et0, irri])
    final ETrainFactor = (precipitation > 0) ? 1 : 0; // todo smooth this
    final kdf = -0.47;
    final ll =
        exp(kdf * LA / _APPi); // fraction of light falling on soil surface
    final cropFactor = max(1 - ll * 0.8, ETrainFactor);
    final transpiration = cropFactor * ET0reference; //su thoat hoi nuoc
    final swfe = pow(relTheta(thetaL[0]), 2.5); //todo time since rain
    final actFactor = max(ll * swfe, ETrainFactor);
    final evaporation = actFactor * ET0reference; // su bay hoi

    final actualTranspiration =
        transpiration * WStrans; // uptake in liter/day per m2
    final wuptrL =
        multiplyListsWithConstant(krootL, actualTranspiration / Kroot);
    //Wupt    = intgrl("Wupt",rep(0.,_nsl),"WuptR")     , # Water uptake (l)

    var drain = 0.0;
    var qFlow = List.generate(_nsl + 1, (index) => 0.0);
    qFlow[0] = (precipitation - evaporation) / (_lw * 1000.0);
    for (var i = 1; i < qFlow.length; ++i) {
      final thdown = (i < _nsl)
          ? thetaL[i]
          : (_zerodrain)
              ? thetaL[i - 1] + _thg
              : _thm;
      qFlow[i] +=
          (thetaL[i - 1] + _thg - thdown) * _rateFlow * (thetaL[i - 1] / _ths) +
              4.0 * max(thetaL[i - 1] - _ths, 0);
    }
    var dThetaDt = List.generate(
        _nsl, (i) => qFlow[i] - qFlow[i + 1] - wuptrL[i] / (_lw * 1000.0));
    for (var e in dThetaDt) {
      assert(!e.isNaN, print("dThetaDt: $dThetaDt qFlow: $qFlow"));
    }
    drain = qFlow[_nsl] * _lw * 1000; //back to mm

    // nutrient stress effects
    double fNSstress(double upt, double low, double high) {
      double rr = (upt - low) / (high - low);
      return lim(rr);
    }

    // nutrient concentrations in the plant
    final Nopt = 45 * LDM + 7 * SRDM + 20 * SDM + 20 * RDM;
    final NuptLimiter = 1.0 - fNSstress(Nupt, 2.0 * Nopt, 3.0 * Nopt);
    //nutrient uptake
    final nuptrL = new List<double>.generate(
        _nsl,
        (i) => monod(ncontL[i] * _BD / (1000 * thetaL[i]),
            //mg/kg * kg/m3 / l/m3=mg/l
            Imax: NuptLimiter * rlL[i] * 0.8,
            Km: 12.0 * 0.5));
    for (var e in nuptrL) {
      assert(!e.isNaN, print("ncont_l=$ncontL theta_l=$thetaL"));
    }

    final ncontrL = List.generate(_nsl, (index) => 0.0); //mg/kg/day
    late final List<double> _NminR_l = new List<double>.generate(
        _nsl,
        (d) =>
            this.customizedParameters.fertilizationLevel /
            100 *
            36 /
            (_lvol * _BD) /
            pow(d + 1, 2)); //todo highly _nsl dependent
    for (var i = 0; i < _nsl; ++i) {
      ncontrL[i] = _NminR_l[i];
      ncontrL[i] -= nuptrL[i] / (_BD * _lvol); //mg/day/ (m3*kg/m3)
      final Nl = ncontL[i];
      final Nu = (i > 0) ? ncontL[i - 1] : -ncontL[i];
      //final Nd = (i < (_nsl - 1)) ? Ncont_l[i + 1] : -Ncont_l[i];//zero flux bottom
      final Nd = (i < (_nsl - 1)) ? ncontL[i + 1] : 0.0; //leaching
      // no diffusion, just mass flow with water.
      ncontrL[i] += qFlow[i] * (Nu + Nl) / 2.0 - qFlow[i + 1] * (Nl + Nd) / 2.0;
    }

    for (var e in ncontrL) {
      // assert(!e.isNaN, print("ncont_l=$ncontL qFlow=$qFlow theta=$thetaL"));
    }

    //final NcontR_l =  substractLists(_NminR_l, NuptR_l); // change in N in soil (mg/day)
    final NSphot = (Nopt > 1e-3) ? fNSstress(Nupt, 0.7 * Nopt, Nopt) : 1.0;
    final NSshoot =
        (Nopt > 1e-3) ? fNSstress(Nupt, 0.7 * Nopt, 0.9 * Nopt) : 1.0;
    final NSroot =
        (Nopt > 1e-3) ? fNSstress(Nupt, 0.5 * Nopt, 0.7 * Nopt) : 1.0;
    //final NSsroot = 1.0;
    // 1 for fast leaf senescence when plant is stressed for N
    final NSleafSenescence =
        (Nopt > 1.0) ? 1.0 - fNSstress(Nupt, 0.8 * Nopt, Nopt) : 0.0;

    // sink strength
    final mGRl = logistic(ct, x0: 0.3, xc: 70, k: 0, m: 0.9);
    final mGRld = logistic(ct, x0: 0.0, xc: 70.0 + _leafAge, k: 0.1, m: -0.90);
    final mGRs = logistic(ct, x0: 0.2, xc: 95, k: 0.219, m: 1.87) +
        logistic(ct, x0: 0.0, xc: 209, k: 0.219, m: 1.87 - 0.84);
    final mGRr = 0.02 + (0.2 + exp(-0.8 * ct - 0.2)) * mGRl;
    final mGRsr = min(7.08, pow(max(0.0, (ct - 32.3) * 0.02176), 2));
    final mDMr = 0.02 * ct +
        1.25 +
        0.25 * ct -
        1.25 * exp(-0.8 * ct) * mGRl +
        (0.25 + exp(-0.8 * ct)) * mDMl;

    // carbon limitations
    final CSphot = getStress(Clab, TDM,
        low: 0.05, swap: true); //Lower photosynthesis when starche accumulates
    final CSshoota = getStress(Clab, TDM,
        low: -0.05); //do not allocat to shoot when starche levels are low
    final CSshootl =
        lim(5 - LA / _APPi); // do not allocat to shoot when LAI is high
    final CSshoot = CSshoota * CSshootl;
    final CSroot = getStress(Clab, TDM, low: -0.03);
    final CSsrootl = getStress(Clab, TDM, low: -0.0);
    final CSsrooth = getStress(Clab, TDM, low: 0.01, high: 0.20);
    final starchRealloc =
        getStress(Clab, TDM, low: -0.2, high: -0.1, swap: true) * -0.05 * SRDM;
    final CSsroot = CSsrootl + 2 * CSsrooth;
    final SFleaf = WSshoot * NSshoot * TSshoot * CSshootl;
    final SFstem = WSshoot *
        NSshoot *
        TSshoot *
        CSshoot; //todo are leaf and stem not coupled?
    final SFroot = WSroot * NSroot * TSroot * CSroot;
    final SFsroot = CSsroot;

    final CsinkL = cDm * mGRl * SFleaf; //*
    //((mDMl > 1 && ct > 500)
    //    ? LDM / mDMl
    //    : 1); //todo LDM includes dead leafs
    // todo mDMs and mDMr seem off?
    final CsinkS =
        cDm * mGRs * SFstem; //* ((mDMs > 30 && ct > 500) ? SDM / mDMs : 1);
    final CsinkR =
        cDm * mGRr * SFroot; //* ((mDMr > 1 && ct > 300) ? RDM / mDMr : 1);
    final CsinkSR = cDm * mGRsr * SFsroot -
        starchRealloc; // todo check this * ((mDMsr > 5) ? SRDM / mDMsr : 1);
    final Csink = CsinkL + CsinkS + CsinkR + CsinkSR;

    // biomass partitioning
    final a2l = CsinkL / max(1e-10, Csink);
    final a2s = CsinkS / max(1e-10, Csink);
    final a2r = CsinkR / max(1e-10, Csink);
    final a2sr = CsinkSR / max(1e-10, Csink);

    // carbon to growth
    final CFG = Csink; // carbon needed for growth (g C/day)
    // increase in plant dry Mass (g DM/day) not including labile carbon pool
    final IDM = Csink / cDm;

    //photosynthesis
    final PPFD = wd[2]; //return ([rain, temp, ppfd, et0, irri])
    final SFphot = min(min(TSphot, WSphot), min(NSphot, CSphot));
    final CFR = photoFixMean(PPFD, LA / _APPi, Pn_max: 29.37 * SFphot);

    final SDMR = a2s * IDM; // stem growth rate (g/day)
    final SRDMR = a2sr * IDM; // storage root growth rate (g/day)

    final SLA = fSLA(ct);
    // Leaf Senescence, note that this does not lead to reallocation here
    // todo leaf senescence is absolute, not less if plant is small. Can lead to rapid loss of LA.
    // note that this should have delays on LDM or LA instead of this.
    final LDRstress = WSleafSenescence * NSleafSenescence * LDM * -1.0;
    final LDRage = mGRld * ((mDMl > 0) ? LDM / mDMl : 1.0);
    assert(LDRstress <= 1e-6 && LDRage <= 1e-6,
        "LDRstress: $LDRstress LDRage: $LDRage");
    final LDRm = max(-LDM, LDRstress + LDRage);
    final LDRa = max(-LA, fSLA(max(0.0, ct - _leafAge)) * LDRm);
    final LAeR = SLA * a2l * IDM + LDRa; // Leaf Area expansion Rate (m2/day)
    final LDMR = a2l * IDM +
        LDRm; //+ mGRld; // leaf growth rate (g/day) - death rate (g/day)

    final RDMR = a2r * IDM; // fine root growth rate (g/day)
    final RLR = _SRL * RDMR;
    final rlrL = new List<double>.generate(_nsl, (i) => RLR * nrtL[i] / NRT);
    var ln0 = 0.0;
    final nrtrL = new List<double>.generate(_nsl, (i) => 0.0);
    for (var i = 0; i < _nsl; ++i) {
      final ln1 = rlrL[i];
      nrtrL[i] = ln1 * 60.0 + max(0, (ln0 - ln1 - 6.0 * _lw) * 10.0 / _lw);
      ln0 = ln1;
    }

    // respiration
    //final RR = 0.018 * RDM + 0.002 * SRDM + 0.018 * LDM + 0.002 * SDM;
    final mRR = 0.003 * RDM + 0.0002 * SRDM + 0.003 * LDM + 0.0002 * SDM;
    final gRR = 1.8 * RDMR + 0.2 * SRDMR + 1.8 * (LDMR - LDRm) + 0.4 * SDMR;
    final RR = mRR + gRR;

    // labile pool
    final ClabR = (CFR - CFG - RR) / cDm;

    //mark_result
    // construct array of rates, make sure order is same as in y.
    cnt = -1;
    var YR = new List<double>.generate(9, (index) => 0.0);
    YR[++cnt] = LDMR;
    YR[++cnt] = SDMR;
    YR[++cnt] = RDMR;
    YR[++cnt] = SRDMR;
    YR[++cnt] = LAeR;

    YR[++cnt] = mGRl;
    YR[++cnt] = mGRs;
    YR[++cnt] = mGRsr.toDouble(); //pow returns num not sure how to avoid this
    YR[++cnt] = ClabR;

    YR = [...YR, ...rlrL, ...nrtrL, ...dThetaDt, ...ncontrL, ...nuptrL];
    for (var e in YR) {
      // assert(!e.isNaN,
      //     print("rates: $YR, states:$y, weather:$wd, ET:$ET0reference"));
    }

    YR.add(irrigation); //just for reporting amount of water needed //34
    YR.add(wd[0]); //rain//35
    YR.add(actualTranspiration); //just for reporting amount of water needed//36
    YR.add(evaporation);
    YR.add(drain);
    YR.add(CFR);
    YR.add(PPFD);

    assert(YR.length == y.length);

    for (var e in YR) {
      // assert(!e.isNaN,
      //     print("rates: $YR, states:$y, weather:$wd, ET:$ET0reference"));
    }

    return (YR);
  }

  void rk4Step(double t, List<double> y, double dt, List<double> wd) {
    var yp =
        List<double>.from(y, growable: false); // needs to be an explicit copy
    //print('y0=$y');
    var r1 = ode2(t, yp, wd);
    var t1 = t + 0.5 * dt;
    var t2 = t + dt;
    intStep(yp, r1, 0.5 * dt);
    var r2 = ode2(t1, yp, wd);
    for (int i = 0; i < y.length; i++) yp[i] = y[i]; //reset
    intStep(yp, r2, 0.5 * dt);
    var r3 = ode2(t1, yp, wd);
    for (int i = 0; i < y.length; i++) yp[i] = y[i]; //reset
    intStep(yp, r3, dt);
    var r4 = ode2(t2, yp, wd);
    for (int i = 0; i < r4.length; i++)
      r4[i] = (r1[i] + 2 * (r2[i] + r3[i]) + r4[i]) / 6; //rk4
    //print('y1=$y');
    intStep(y, r4, dt); //final integration
    //print('y2=$y');
  }

  List<double> ode2initValues() {
    var yi = new List<double>.generate(9 + _nsl * 5, (index) => 0.0);
    final iTheta = new List<double>.generate(
        _nsl, (index) => _iTheta + index * _thg); //todo
    /*# c(4.83, 10.105, 16.05, 12.955, 6.75, 4.89, 3.73) mg/kg
      # fertilizer 45 kg/rai urea (46% N) and 250 kg chicken manure with 0.5-0.9% N?
      # (45*0.46 + 250*0.07)*1e6/1600/(lvol*BD)=73 mg/kg
      # probably half of the manure is mineral. */
    final iNcont = [
      39.830,
      10.105,
      16.050,
      8.0, //guessed
      8.0, //guessed
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0
    ]; //we have no measurements for deeper layers.
    final iNRT = 6.0;
    yi[1] = _cuttingDryMass; //SDM
    yi[6] = _cuttingDryMass; //mDMs

    yi[9 + _nsl] = iNRT;
    //yi[13] = 0;
    //yi[14] = 0;
    for (int i = 0; i < _nsl; ++i) {
      //...RLR_l, ...NRTR_l, ...dThetaDt, ...NcontR_l, ...NuptR_l
      yi[9 + 2 * _nsl + i] = iTheta[i];
      yi[9 + 3 * _nsl + i] =
          iNcont[i] * this.customizedParameters.fertilizationLevel / 100;
      yi[9 + 4 * _nsl + i] = _cuttingDryMass * 30.0 / _nsl;
    }

    yi.add(0.0); //for irrigation
    yi.add(0.0); //for rain
    yi.add(0.0); //for trans
    yi.add(0.0); //for evap
    yi.add(0.0); //for drainage
    yi.add(0.0); //for cum photosynthesis
    yi.add(0.0); //for cum light

    //print("yi=$yi");

    return (yi);
  }

  void intStep(final List<double> y, final List<double> r, final double dt) {
    assert(y.length == r.length);
    for (int i = 0; i < y.length; ++i) {
      y[i] += dt * r[i];
    }
  }

  double _getDoy(DateTime sd) {
    final rsd = new DateTime(sd.year, 1, 1, 0, 0);
    double doy = sd.difference(rsd).inDays.toDouble();
    doy += sd.hour / 24.0 +
        sd.minute / (24.0 * 60.0) +
        sd.second / (24.0 * 60.0 * 60.0);
    return (doy);
  }

  DateTime _getDay(double day) {
    DateTime r = DateTime.now();
    final rsd = new DateTime(r.year, 1, 1, 0, 0);
    r = DateUtils.dateOnly(rsd.add(Duration(days: day.ceil())));
    return r;
  }

  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  static Future<void> createCsvFileFromAsset() async {
    // Đọc nội dung của tệp CSV từ thư mục assets
    String csvData = await rootBundle.loadString('assets/images/weather_Thailand.csv');

    // Lấy thư mục ứng dụng trên thiết bị
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    // Tạo đường dẫn cho tệp CSV trên thiết bị
    String csvFilePath = '$appDocPath/data_weather.csv';

    // Ghi nội dung vào tệp CSV trên thiết bị
    File csvFile = File(csvFilePath);
    await csvFile.writeAsString(csvData);

    print('CSV file created at: $csvFilePath');
    log('CSV file created at: $csvFilePath' as num);
  }
}
