import 'package:direction/firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
//import 'package:direction/main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  DatabaseReference ref = FirebaseDatabase.instance.ref("field2");
  ref.onValue.listen((DatabaseEvent event) {
    final data = event.snapshot.value;
    print("------$data");
    //runApp(MyApp());
  });
}