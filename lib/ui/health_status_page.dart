
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../model/field.dart';
import '../model/health_record.dart';

class HealthStatus extends StatefulWidget  {
  Field field;

  HealthStatus(this.field);

  @override
  createState() => HealthListScreen(this.field);
}

class HealthListScreen extends State<HealthStatus> {
  final Field field;
  HealthListScreen(this.field);

  List<HealthRecord> healthRecords = [HealthRecord(name: "No record", time: "No record", imagePath: "assets/flu_image.jpg")];
  @override
  void initState() {
    getListFromFirebase();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Health Records"),
      ),
      body: ListView.builder(
        itemCount: healthRecords.length,
        itemBuilder: (context, index) {
          return HealthRecordItem(healthRecord: healthRecords[index]);
        },
      ),
    );
  }

  Future<void> getListFromFirebase() async {
    final DatabaseReference databaseReference = FirebaseDatabase(databaseURL: 'https://directionproject-1e798-default-rtdb.firebaseio.com/').reference()
        .child("user/${field.fieldName}/disease");

    try {
      DatabaseEvent databaseEvent = await databaseReference.once();
      DataSnapshot dataSnapshot = databaseEvent.snapshot;
      healthRecords.clear();
      Map<dynamic, dynamic> data = (dataSnapshot.value) as Map<dynamic, dynamic>;
      List<Map<dynamic, dynamic>> resultList = [];
      data.forEach((key, value) {
        resultList.add(value as Map<dynamic, dynamic>);
      });
      for ( var item in resultList) {
        setState(() {
          String name = item['disease'];
          String time = item['time'];
          String pathImage = item['urlImage'];
          healthRecords.add(HealthRecord(name: name, time: time, imagePath: pathImage));
        });
      }
    } catch (error) {
      print("Error: $error");
    }
  }
}

class HealthRecordItem extends StatelessWidget {
  final HealthRecord healthRecord;

  HealthRecordItem({required this.healthRecord});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(healthRecord.name),
      subtitle: Text("Time: ${healthRecord.time}"),
      leading: Image.network(
        '${healthRecord.imagePath}',
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) {
            // Image has been successfully loaded
            return child;
          } else {
            // Image is still loading
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            );
          }
        },
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          // Error loading image, display a placeholder with a green tint
          return Container(
            color: Colors.green,  // Set background color to green
            child: Icon(
              Icons.error,
              color: Colors.white,  // Set icon color to white
              size: 50.0,  // Set icon size
            ),
          );
        },
      ),
    );
  }
}