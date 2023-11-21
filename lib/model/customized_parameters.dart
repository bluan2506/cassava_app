import 'package:firebase_database/firebase_database.dart';

import '../constant.dart';

class CustomizedParameters {
  String fieldName;
  double fieldCapacity;
  bool autoIrrigation;
  double irrigationDuration; //(hour)
  double dripRate; //(l/hole/hour)
  double distanceBetweenHoles; //(cm)
  double distanceBetweenRows; //cm
  double scaleRain; //(%)
  double fertilizationLevel;
  double acreage;
  int numberOfHoles;

  CustomizedParameters(
      this.fieldName,
      this.acreage,
      this.fieldCapacity,
      this.autoIrrigation,
      this.irrigationDuration,
      this.dripRate,
      this.distanceBetweenHoles,
      this.distanceBetweenRows,
      this.scaleRain,
      this.fertilizationLevel,
      this.numberOfHoles); //(%)

  CustomizedParameters.newOne(name)
      : this.fieldName = name,
        this.acreage = 50.0,
        this.fieldCapacity = 71,
        this.distanceBetweenHoles = 30,
        this.irrigationDuration = 7,
        this.distanceBetweenRows = 100,
        this.dripRate = 1.6,
        this.fertilizationLevel = 100,
        this.scaleRain = 100,
        this.numberOfHoles = 8,
        this.autoIrrigation = true;

  Future<void> getAutoIrrigationFromDb() async {
    DataSnapshot snapshot = await FirebaseDatabase.instance
        .ref(
            '${Constant.USER}/${this.fieldName}/${Constant.CUSTOMIZED_PARAMETERS}')
        .get();
    var a = snapshot.child('${Constant.AUTO_IRRIGATION}');
    String s = a.value.toString().toLowerCase();
    if (s == 'true')
      this.autoIrrigation = true;
    else
      this.autoIrrigation = false;
  }

  Future<void> getDataFromDb() async {
    DataSnapshot snapshot = await FirebaseDatabase.instance
        .ref(
            '${Constant.USER}/${this.fieldName}/${Constant.CUSTOMIZED_PARAMETERS}')
        .get();
    var a = snapshot.child('${Constant.AUTO_IRRIGATION}');
    String s = a.value.toString().toLowerCase();
    if (s == 'true')
      this.autoIrrigation = true;
    else
      this.autoIrrigation = false;
    a = snapshot.child('${Constant.FIELD_CAPACITY}');
    this.fieldCapacity = double.parse(a.value.toString());
    a = snapshot.child('${Constant.IRRIGATION_DURATION}');
    this.irrigationDuration = double.parse(a.value.toString());
    a = snapshot.child('${Constant.DRIP_RATE}');
    this.dripRate = double.parse(a.value.toString());
    a = snapshot.child('${Constant.DISTANCE_BETWEEN_ROWS}');
    this.distanceBetweenRows = double.parse(a.value.toString());
    a = snapshot.child('${Constant.DISTANCE_BETWEEN_HOLES}');
    this.distanceBetweenHoles = double.parse(a.value.toString());
    a = snapshot.child('${Constant.SCALE_RAIN}');
    this.scaleRain = double.parse(a.value.toString());
    a = snapshot.child('${Constant.FERTILIZATION_LEVEL}');
    this.fertilizationLevel = double.parse(a.value.toString());
    a = snapshot.child("${Constant.ACREAGE}");
    this.acreage = double.parse(a.value.toString());
    a = snapshot.child("${Constant.NUMBER_OF_HOLES}");
    this.numberOfHoles = int.parse(a.value.toString());
  }

  Future<void> updateDataToDb() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(
        '${Constant.USER}/${this.fieldName}/${Constant.CUSTOMIZED_PARAMETERS}');
    await ref.update({
      "${Constant.FIELD_CAPACITY}": this.fieldCapacity,
      "${Constant.ACREAGE}": this.acreage,
      "${Constant.IRRIGATION_DURATION}": this.irrigationDuration,
      "${Constant.DRIP_RATE}": this.dripRate,
      "${Constant.DISTANCE_BETWEEN_HOLES}": this.distanceBetweenHoles,
      "${Constant.DISTANCE_BETWEEN_ROWS}": this.distanceBetweenRows,
      "${Constant.SCALE_RAIN}": this.scaleRain,
      "${Constant.FERTILIZATION_LEVEL}": this.fertilizationLevel,
      "${Constant.AUTO_IRRIGATION}": this.autoIrrigation,
      "${Constant.NUMBER_OF_HOLES}": this.numberOfHoles,
    });
  }
}
