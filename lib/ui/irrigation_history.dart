import 'package:direction/constant.dart';
import 'package:intl/intl.dart';
import '../model/irrigation_record.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../styles.dart';

class IrrigationHistory extends StatefulWidget {
  final String fieldName;

  IrrigationHistory(this.fieldName);

  @override
  createState() => _IrrigationHistoryState(this.fieldName);
}

class _IrrigationHistoryState extends State<IrrigationHistory> {
  final String fieldName;
  List<IrrigationRecord> irrigationRecords = [];

  _IrrigationHistoryState(this.fieldName);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${AppLocalizations.of(context)!.irrigationHistory}"),
      ),
      body: _loadDataBeforeRenderBody(),
    );
  }

  Widget _refreshBody() {
    return RefreshIndicator(
        child: _loadDataBeforeRenderBody(), onRefresh: _pullFresh);
  }

  Future<void> _pullFresh() async {
    setState(() {
      this.irrigationRecords = [];
      _loadData();
    });
  }

  Widget _loadDataBeforeRenderBody() {
    return FutureBuilder(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${snapshot.error} occurred',
              style: TextStyle(fontSize: 18),
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          return _renderBody();
        } else
          return Center(
            child: CircularProgressIndicator(),
          );
      },
    );
  }

  Widget _renderBody() {
    List<Widget> result = [];
    for(var element in this.irrigationRecords) {
      result.add(_renderIrrigationRecord(element));
    }
    return Container(
      child: ListView(
        children: result,
      ),
    );
  }
  Widget _renderIrrigationRecord(IrrigationRecord irrigationRecord) {
    String formattedDate = DateFormat("HH:mm dd-MM-yyyy").format(irrigationRecord.time);
    return Container(
      decoration: Styles.boxDecoration,
      height: 120,
      padding: EdgeInsets.fromLTRB(25.0, 15.0, 15.0, 15.0),
      margin: EdgeInsets.only(top: 20.0, left: 15, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text("User: ${irrigationRecord.userName}", style: Styles.timeTitle),
          Text("${AppLocalizations.of(context)!.startingIrrigationTime}: $formattedDate", style: Styles.timeTitle,),
          Text("${AppLocalizations.of(context)!.durationOfIrrigation}: ${double.parse(irrigationRecord.duration.toStringAsFixed(2))} (s)", style: Styles.timeTitle),
          Text("${AppLocalizations.of(context)!.amountOfIrrigation}: ${double.parse(irrigationRecord.amount.toStringAsFixed(2))} (l/m^2)", style: Styles.timeTitle)
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    // DataSnapshot snapshot =
    //     await FirebaseDatabase.instance.ref("${Constant.USER}/${this.fieldName}/${Constant.IRRIGATION_HISTORY}").get();

    // for (var child in snapshot.children) {
    //   double amount = double.parse(child.child('amount').value.toString());
    //   double duration = double.parse(child.child('duration').value.toString());
    //   DateTime time = DateTime.parse(child.child("startIrrigation").value.toString());
    //   this.irrigationRecords.add(IrrigationRecord(userName: 'Luan', amount: amount, duration: duration, time: time));
    // }

    var headers = {'Content-Type': 'text/plain'};
    var body = '$fieldName';

    final response = await http.post(
        Uri.parse('${Constant.BASE_URL}getHistoryIrrigation'),
        headers: headers, body: body
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> list = [];

      for (var item in data) {
        list.add(Map<String, dynamic>.from(item));
      }

      for (var history in list) {
        String userName = history['userName'];
        double amount = history['amount'];
        double duration = history['duration'];
        String dateTime = history['time'];
        this.irrigationRecords.add(IrrigationRecord(userName: userName, amount: amount, duration: duration, time: DateTime.parse(dateTime)));
      }
    } else {
      print('Failed to fetch data. Status code: ${response.statusCode}');
    }
    this.irrigationRecords.sort((a,b){
      if (a.time.isBefore(b.time)) return 1;
      else return 0;
    });
    // this.irrigationRecords.sort((a, b) => b.time.compareTo(a.time));
  }
}
