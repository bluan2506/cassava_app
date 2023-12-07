import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/field.dart';
import 'package:direction/styles.dart';
import '../constant.dart';
import '../model/measured_data.dart';

double _boxHeight = 100;
double _boxWidth = 150;
class DetailIrrigation extends StatefulWidget {
  final Field field;

  DetailIrrigation(this.field);

  @override
  createState() => _DetailIrrigationState(this.field);
}

class _DetailIrrigationState extends State<DetailIrrigation> {
  final Field field;
  DateTime selectedStartTime = DateTime.now();
  double amount = 0.0; //l/m2

  _DetailIrrigationState(this.field);

  @override
  void initState() {
    super.initState();
    // _loadData();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_appBarText()}'),
      ),
      body: _refreshBody()
    );
  }

  Widget _refreshBody() {
    return RefreshIndicator(child: _loadDataBeforeRenderBody(), onRefresh: _pullFresh);
  }

  Future<void> _pullFresh() async{
    setState(() {
      _loadData();
    });
  }

  Widget _loadDataBeforeRenderBody() {
    return FutureBuilder(
      future: fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Return a loading indicator while waiting for data
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          // Handle error state
          return Text('Error: ${snapshot.error}');
        } else {
          // Data has been fetched, render your actual widget
          return _renderBody();
        }
      },
    );
  }

  Future<void> fetchData() async{
    await fetchWeatherData(field);
    await fetchHumidityData(field);
  }

  Future<void> fetchWeatherData(Field field) async {
    var header = {'Content-Type': 'text/plain'};
    final response = await http.post(Uri.parse('${Constant.BASE_URL}getWeatherData'),
        headers: header, body: '${field.fieldName}');
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> list = [];

      for (var item in data) {
        list.add(Map<String, dynamic>.from(item));
      }
        var result = list[list.length - 1];
        double rainFall = result['rainFall'];
        double relativeHumidity = result['relativeHumidity'];
        double temperature = result['temperature'];
        double windSpeed = result['windSpeed'];
        double radiation = result['radiation'];
        this.field.measuredData = MeasuredData(field.fieldName, rainFall, relativeHumidity, temperature, windSpeed, radiation, 0, 0);
    }
  }

  Future<void> fetchHumidityData(Field field) async {
    var header = {'Content-Type': 'text/plain'};
    final response = await http.post(Uri.parse('${Constant.BASE_URL}getHumidityRecentTime'),
        headers: header, body: '${field.fieldName}');
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
        double humidity30 = data['humidity30'];
        double humidity60 = data['humidity60'];
        this.field.measuredData.soil30Humidity = humidity30;
        this.field.measuredData.soil60Humidity = humidity60;
    }
  }

  Future<void> _loadData() async {
    await this.field.getGeneralDataFromDb();
    await this.field.getMeasuredDataFromDb();
    if (true) {
      if (!this.field.customizedParameters.autoIrrigation) {
        DataSnapshot snapshot = await FirebaseDatabase.instance
            .ref(
                '${Constant.USER}/${this.field.fieldName}/${Constant.IRRIGATION_INFORMATION}')
            .get();
        if (!snapshot.exists) {
          final Map<String, dynamic> updates = {};
          updates["${Constant.IRRIGATION_INFORMATION}"] = {
            "time": this.selectedStartTime,
            "duration": this.amount *
                this.field.customizedParameters.acreage /
                this.field.customizedParameters.dripRate /
                this.field.customizedParameters.numberOfHoles
          };
          FirebaseDatabase.instance
              .ref('${Constant.USER}/${this.field.fieldName}')
              .update(updates);
        } else {
          var s = snapshot.child('time').value.toString();
          this.selectedStartTime = DateTime.parse(s);
          s = snapshot.child('duration').value.toString();
          var duration = double.parse(s);
          double tmp = (duration *
              this.field.customizedParameters.dripRate /
              this.field.customizedParameters.acreage *
              this.field.customizedParameters.numberOfHoles /
              3600);
          this.amount = double.parse(tmp.toStringAsFixed(4));
        }
      }
    }
  }

  Widget _renderWeatherData() {
    return Container(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _decoratedContainer(
                    "${AppLocalizations.of(context)!.radiation}",
                    "${this.field.measuredData.radiation.toString()} [MJm^(-2)h^(-1)]",
                    _boxHeight,
                    _boxWidth),
                _decoratedContainer("${AppLocalizations.of(context)!.rainFall}",
                    this.field.measuredData.rainFall.toString(), 100, 150)
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _decoratedContainer(
                    "${AppLocalizations.of(context)!.relativeHumidity}",
                    "${this.field.measuredData.relativeHumidity.toString()} [%]",
                    _boxHeight,
                    _boxWidth),
                _decoratedContainer(
                    "${AppLocalizations.of(context)!.temperature}",
                    "${this.field.measuredData.temperature.toString()} [℃]",
                    _boxHeight,
                    _boxWidth)
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _decoratedContainer(
                    "${AppLocalizations.of(context)!.windSpeed}",
                    "${this.field.measuredData.windSpeed.toString()} [m s^(-1)]",
                    _boxHeight,
                    _boxWidth),
                _renderIrrigationStatus()
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _renderSoilHumidity(true),
                _renderSoilHumidity(false)
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _renderIrrigationStatus() {
    return Container(
      width: _boxWidth,
      height: _boxHeight,
      decoration: Styles.boxDecoration,
      child: (this.field.irrigationCheck)
          ? Lottie.asset('assets/animations/water-drop.json')
          : Lottie.asset('assets/animations/energyshares-plant5.json'),
    );
  }

  Widget _renderSoilHumidity(bool humidity30) {
    return (humidity30)
        ? _decoratedContainer("${AppLocalizations.of(context)!.soil30Humidity}",
            "${this.field.measuredData.soil30Humidity.toStringAsFixed(2)}%", _boxHeight, _boxWidth)
        : _decoratedContainer("${AppLocalizations.of(context)!.soil60Humidity}",
            "${this.field.measuredData.soil60Humidity.toStringAsFixed(2)}%", _boxHeight, _boxWidth);
  }

  Widget _decoratedContainer(
      String title, String value, double height, double width) {
    return Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      decoration: Styles.boxDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$title", textAlign: TextAlign.center,),
          Text("$value", textAlign: TextAlign.center,),
        ],
      ),
    );
  }

  String _appBarText() {
    String s = '';
    if (this.field.customizedParameters.autoIrrigation) {
      s = '${this.field.fieldName} (${AppLocalizations.of(context)!.autoIrrigation})';
    } else
      s = '${AppLocalizations.of(context)!.manualIrrigation}';
    return s;
  }

  Widget _renderIrrigationAmountByModel() {
    return Container(
      height: 50,
      width: 335,
      margin: EdgeInsets.only(top: 20),
      alignment: Alignment.center,
      decoration: Styles.boxDecoration,
      child: Text(
          '${AppLocalizations.of(context)!.amountOfIrrigationToday} ${this.field.nextIrrigationAmount()}'),
    );
  }

  Widget _renderBody() {
    return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
      child: Column(
        children: [
          _renderWeatherData(),
          (this.field.irrigationCheck)
              ? _irrigatingBody()
              : _notIrrigatingBody(),
        ],
      ),
    ));
  }

  //be irrigating
  Widget _irrigatingBody() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          (this.field.customizedParameters.autoIrrigation)
              ? _renderIrrigationAmountByModel()
              : Container(),
          Container(
            child: Text(
              '${AppLocalizations.of(context)!.startingIrrigationTime}: ${this.field.startIrrigation}',
              style: Styles.timeTitle,
            ),
            height: 50,
            padding: const EdgeInsets.all(3.0),
            margin: EdgeInsets.only(top: 30, bottom: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                borderRadius: new BorderRadius.circular(25),
                border: Border.all(color: Styles.blueColor)),
          ),
          Container(
            child: Text(
              '${AppLocalizations.of(context)!.endingIrrigationTime}: ${this.field.endIrrigation}',
              style: Styles.timeTitle,
            ),
            height: 50,
            padding: const EdgeInsets.all(3.0),
            margin: EdgeInsets.only(bottom: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                borderRadius: new BorderRadius.circular(25),
                border: Border.all(color: Styles.blueColor)),
          ),
          Container(
            child: Text(
              '${AppLocalizations.of(context)!.amountOfIrrigation}: ${this.amount} (l/m^2)',
              style: Styles.timeTitle,
            ),
            height: 50,
            padding: const EdgeInsets.all(3.0),
            margin: EdgeInsets.only(bottom: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                borderRadius: new BorderRadius.circular(25),
                border: Border.all(color: Styles.blueColor)),
          ),
        ],
      ),
    );
  }

  //not be irrigating
  Widget _notIrrigatingBody() {
    if (this.field.customizedParameters.autoIrrigation)
      return _autoNotIrrigation();
    else
      return _manualNotIrrigation();
  }

  Widget _autoNotIrrigation() {
    return Container(
        child: Column(
      children: [
        Container(
          height: 100,
          width: 330,
          padding: EdgeInsets.only(left: 10),
          margin: EdgeInsets.only(top: 30),
          decoration: Styles.boxDecoration,
          alignment: Alignment.center,
          child: Text(
            "${AppLocalizations.of(context)!.amountOfIrrigationFor} ${this.field.getIrrigationTime()}: ${this.field.getIrrigationAmount()} (l/m2)",
            style: Styles.textDefault,
          ),
        ),
      ],
    ));
  }

  // "The amount of Irrigation for ${this.field.getIrrigationTime()}",
  // "${this.field.getIrrigationAmount()} (l/m2)",

  Widget _manualNotIrrigation() {
    return Container(
      height: 400,
      width: 330,
      padding: EdgeInsets.only(left: 10),
      margin: EdgeInsets.only(top: 30),
      decoration: Styles.boxDecoration,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.only(top: 20, bottom: 10),
            alignment: Alignment.center,
            child: Text(
              '${AppLocalizations.of(context)!.startingTime}: ${this.selectedStartTime}',
              style: Styles.timeTitle,
            ),
          ),
          Container(
            height: 100,
            width: 150,
            alignment: Alignment.center,
            padding: EdgeInsets.only(bottom: 20),
            child: SizedBox(
              height: 60,
              width: 230,
              child: OutlinedButton(
                child: Text(
                  '${AppLocalizations.of(context)!.chooseIrrigationTime}',
                  style: Styles.timeTitle,
                ),
                onPressed: () => _dateTimePickerWidget(context),
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              "${AppLocalizations.of(context)!.amountOfIrrigation}: ${this.amount} (l/m2)",
              style: Styles.timeTitle,
            ),
          ),
          _renderAmountOfIrrigationTextField(),
          _renderConfirmButton(),
        ],
      ),
    );
  }

  _dateTimePickerWidget(BuildContext context) async {
    return DatePicker.showDateTimePicker(
      context,
      //dateFormat: 'dd MMMM yyyy HH:mm',
      currentTime: DateTime.now(),
      minTime: DateTime(2018),
      maxTime: DateTime(2100),
      //onMonthChangeStartWithFirstDate: true,
      onConfirm: (dateTime) {
        // this.selectedStartTime = dateTime;
        this.selectedStartTime = dateTime;
        print(this.selectedStartTime);
      },
    );
  }

  Widget _renderAmountOfIrrigationTextField() {
    return Container(
      alignment: Alignment.center,
      child: SizedBox(
        width: 250,
        height: 50,
        child: TextField(
          onSubmitted: (value) {
            if (value.isNotEmpty) this.amount = double.parse(value);
          },
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter(RegExp(r'[0-9.]'), allow: true)
          ],
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hoverColor: Colors.blue,
            hintText:
                '${AppLocalizations.of(context)!.enterAmountOfIrrigation}',
          ),
        ),
      ),
    );
  }

  Widget _renderConfirmButton() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.only(top: 20),
      child: ElevatedButton(
        style: ButtonStyle(
            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(15)),
            backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ))),
        child: Text(
          '${AppLocalizations.of(context)!.confirm}',
          style: Styles.locationTileTitleLight,
        ),
        onPressed: () => {
          setState(() {
            final Map<String, dynamic> updates = {};
            double setDuration = this.amount *
                this.field.customizedParameters.acreage /
                (this.field.customizedParameters.dripRate *
                    this.field.customizedParameters.numberOfHoles) *
                3600;
            updates["${Constant.IRRIGATION_INFORMATION}"] = {
              "time": this.selectedStartTime.toString(),
              "duration": setDuration,
              "amount": this.amount,
              // "${day}": tIrr
            };
            FirebaseDatabase.instance
                .ref('${Constant.USER}/${this.field.fieldName}')
                .update(updates);
          })
        },
      ),
    );
  }
}
