import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../constant.dart';

class MeasuredData {
  String fieldName;
  double rainFall; //(measure)
  double relativeHumidity; //(measure) do am khong khi
  double temperature; //(measure) nhiet do khong khi
  double windSpeed; //(measure)
  double radiation; //(measure) buc xa be mat cay trong
  double soil30Humidity;
  double soil60Humidity;

  MeasuredData(
      this.fieldName,
      this.rainFall,
      this.relativeHumidity,
      this.temperature,
      this.windSpeed,
      this.radiation,
      this.soil30Humidity,
      this.soil60Humidity);

  Future<void> getHumidityDataFromDb() async {
    DateTime currentTime = DateTime.now();
    DataSnapshot snapshot = await FirebaseDatabase.instance
        .ref('${Constant.USER}/${this.fieldName}/${Constant.SOIL_HUMIDITY}')
        .get();

    DataSnapshot day = snapshot.children.last;
    var duration = currentTime.difference(DateTime.parse(day.key.toString()));
    for (var iDay in snapshot.children) {
      DateTime tmp = DateTime.parse(iDay.key.toString());
      if (duration > currentTime.difference(tmp)) {
        duration = currentTime.difference(tmp);
        day = iDay;
      }
    }

    DataSnapshot time = day.children.last;
    //var dur = currentTime.difference(DateTime.parse(time.child('time').value.toString()));
    for (var iTime in day.children) {
      DateTime tmp = DateTime.parse(iTime.child('time').value.toString());
      if (duration > currentTime.difference(tmp)) {
        duration = currentTime.difference(tmp);
        time = iTime;
      }
    }
    this.soil30Humidity = double.parse(time.child('humidity30').value.toString());
    this.soil60Humidity = double.parse(time.child('humidity60').value.toString());
  }

  Future<void> getWeatherDataFromDb() async{
    DateTime currentTime = DateTime.now();
    DataSnapshot snapshot = await FirebaseDatabase.instance
        .ref('${Constant.USER}/${this.fieldName}/${Constant.MEASURED_DATA}')
        .get();

    DataSnapshot day = snapshot.children.last;
    var duration = currentTime.difference(DateTime.parse(day.key.toString()));
    for (var iDay in snapshot.children) {
      DateTime tmp = DateTime.parse(iDay.key.toString());
      if (duration > currentTime.difference(tmp)) {
        duration = currentTime.difference(tmp);
        day = iDay;
      }
    }

    DataSnapshot time = day.children.last;
    //var dur = currentTime.difference(DateTime.parse(time.child('time').value.toString()));
    for (var iTime in day.children) {
      DateTime tmp = DateTime.parse(iTime.child('time').value.toString());
      if (duration > currentTime.difference(tmp)) {
        duration = currentTime.difference(tmp);
        time = iTime;
      }
    }

    this.radiation =
        double.parse(time.child('${Constant.RADIATION}').value.toString());
    this.rainFall =
        double.parse(time.child('${Constant.RAIN_FALL}').value.toString());
    this.relativeHumidity = double.parse(
        time.child('${Constant.RELATIVE_HUMIDITY}').value.toString());
    this.temperature =
        double.parse(time.child('${Constant.TEMPERATURE}').value.toString());
    this.windSpeed =
        double.parse(time.child('${Constant.WIND_SPEED}').value.toString());
  }

  MeasuredData.newOne(String name)
      : fieldName = name,
        rainFall = 0,
        relativeHumidity = 0,
        temperature = 0,
        windSpeed = 0,
        radiation = 0,
        soil30Humidity = 0,
        soil60Humidity = 0;


}
