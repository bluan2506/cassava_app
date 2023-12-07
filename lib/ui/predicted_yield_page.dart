import 'dart:io';

import 'package:csv/csv.dart';
import 'package:direction/styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constant.dart';
import '../model/field.dart';
import 'package:flutter/material.dart';

class PredictedYieldPage extends StatefulWidget {
  final Field field;

  PredictedYieldPage(this.field);

  @override
  createState() => _PredictedYieldPageState(this.field);
}

class _PredictedYieldPageState extends State<PredictedYieldPage> {
  final Field field;
  late Future<List<double>> data;
  late Future<void> fetchDataFuture;

  _PredictedYieldPageState(this.field);

  @override
  void initState() {
    fetchDataFuture = fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!
            .predictTheYieldOfField(this.field.fieldName)),
      ),
      body:FutureBuilder<void>(
        future: fetchDataFuture,
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
      ),
    );
  }

  Future<void> fetchData() async {
    var headers = {'Content-Type': 'text/plain'};
    var body = '${field.fieldName}';

    final response = await http.post(
      Uri.parse('${Constant.BASE_URL}calculateModel'),
        headers: headers, body: body
    );

    if (response.statusCode == 200) {
      List<List<double>> responseData = (jsonDecode(response.body) as List)
          .map((e) => (e as List).cast<double>())
          .toList();

      // Now you can work with responseData, which should be a List of Lists of ints.
      field.results = responseData;
      print(responseData);
    } else {
      print('Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

//N status (ratio to optimal)
  Widget _renderBody() {
    fetchData();
    List<Widget> result = [];
    var xData = this.field.getDoy();
    var xTitle = this.field.getResultDay();
    result.add(_renderChart(AppLocalizations.of(context)!.yield, xData,
        this.field.predictYield(), xTitle));
    result.add(_renderChart(AppLocalizations.of(context)!.irrigation, xData,
        this.field.getIrrigation(), xTitle));
    result.add(_renderChart(AppLocalizations.of(context)!.leafAreaIndex, xData,
        this.field.getLai(), xTitle));
    result.add(_renderChart(AppLocalizations.of(context)!.labileCarbon, xData,
        this.field.getCLab(), xTitle));
    result.add(_renderChart(AppLocalizations.of(context)!.topsoilWetness, xData,
        this.field.getTopSoilWetness(), xTitle));
    result.add(_renderChart(AppLocalizations.of(context)!.photosynthesis, xData,
        this.field.getPhotoSynthesis(), xTitle));
    result.add(_renderChart(AppLocalizations.of(context)!.topsoilNContent,
        xData, this.field.getTopsoilNContent(), xTitle));
    result.add(_renderChart(AppLocalizations.of(context)!.nStatus, xData,
        this.field.getNStatus(), xTitle));

    List<List<dynamic>> rows = <List<dynamic>>[];
    rows.add(["time", "irrigation", "predictYield"]);
    for (int i = 0; i < xData.length; i++) {
      rows.add([xTitle[i].toString(), this.field.getIrrigation()[i], this.field.predictYield()[i]]);
    }
    writeDataToCsv(field, rows);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          children: result,
        ),
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    return Container(
      margin: EdgeInsets.only(top: 5),
      child: RotationTransition(
        turns: new AlwaysStoppedAnimation(-15 / 360),
        child: Text("${DateFormat('dd-MM').format(this.field.getDay(value))}"),
      ),
    );
  }

//Text("${DateFormat('dd-MM').format(this.field.getDay(value))}")
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    return Container(
      child: Text("${double.parse(value.toStringAsFixed(2))}"),
    );
  }

  Widget _renderChart(String title, List<double> xData, List<double> yData,
      List<DateTime> xTitle) {
    var points = getChartPoints(xData, yData);
    return Container(
      margin: EdgeInsets.only(bottom: 30, left: 5, right: 5),
      padding: EdgeInsets.all(20),
      decoration: Styles.boxDecoration,
      child: Column(
        children: [
          Container(
            child: Text(
              title,
              style: Styles.predictPageTitle,
            ),
          ),
          SizedBox(
            height: 300,
            width: 400,
            child: AspectRatio(
              aspectRatio: 2,
              child: LineChart(LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: points
                        .map((point) => FlSpot(point.x, point.y))
                        .toList(),
                    isCurved: false,
                    dotData: FlDotData(
                      show: false,
                    ),
                    color: Colors.green,
                    belowBarData: BarAreaData(
                        show: true, color: Colors.green.withOpacity(0.2)),
                  ),
                ],
                borderData: FlBorderData(
                  border:
                      const Border(bottom: BorderSide(), left: BorderSide()),
                ),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: (xData.length / 2.5),
                          reservedSize: 30,
                          getTitlesWidget: bottomTitleWidgets)),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: false,
                          interval: yData.length / 2,
                          reservedSize: 30,
                          getTitlesWidget: leftTitleWidgets)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  List<ChartPoint> getChartPoints(List<double> xData, List<double> yData) {
    assert(xData.length == yData.length);
    List<ChartPoint> points = [];
    for (int i = 0; i < xData.length; i++) {
      ChartPoint tmp = ChartPoint(x: xData[i], y: yData[i]);
      points.add(tmp);
    }
    return points;
  }
  static Future<void> writeDataToCsv(Field field, List<List<dynamic>> rows) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String csvFilePath = '$appDocPath/${field.fieldName}.csv';
    File csvFile = File(csvFilePath);
    String csvData = const ListToCsvConverter().convert(rows);
    csvFile.writeAsString(csvData);
  }
}

class ChartPoint {
  final double x;
  final double y;

  ChartPoint({required this.x, required this.y});
}
