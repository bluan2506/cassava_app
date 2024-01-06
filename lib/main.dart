import 'dart:convert';

import 'package:direction/constant.dart';
import 'package:direction/info.dart';
import 'package:direction/ui/home.dart';
import 'package:flutter/material.dart';

//TODO ios language support needs additional steps in xcode, see website above
import 'package:fluttertoast/fluttertoast.dart';

//database management
import 'dart:io' show Platform;
import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

//project files
import 'package:direction/page_welcome.dart';
import 'package:direction/ui/field_list.dart';
import 'styles.dart';

//import 'package:direction/classFields.dart';
var readFile = 0;

Future main() async {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(), // Set the home property to the LoginPage
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    //add this line to cmd to connect device to localhost
    //adb reverse tcp:8081 tcp:8081
    final String apiUrl = "${Constant.BASE_URL}login";

    final response = await http.post(
      Uri.parse(apiUrl),
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng Nhập'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg_login.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  String email = emailController.text;
                  String password = passwordController.text;

                  try {
                    Map<String, dynamic> response = await loginUser(email, password);
                    print(response);

                    // Handle the response data here
                    bool success = response['success'];
                    String message = response['message'];
                    Map<String, dynamic> data = response['data'];

                    if (success) {
                      // Successfully logged in
                      print("Đăng nhập thành công");
                      Info.userName = data['userName'];
                      Info.email = data['email'];
                      Info.password = data['password'];
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Home()),
                      );
                      Fluttertoast.showToast(
                        msg: "Login successfully",
                        toastLength: Toast.LENGTH_SHORT, // or Toast.LENGTH_LONG
                        gravity: ToastGravity.BOTTOM, // Location where the toast should appear
                        timeInSecForIosWeb: 1, // Time duration for which the toast should be visible
                        backgroundColor: Colors.grey,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    } else {
                      // Failed to log in
                      print("Đăng nhập thất bại");
                      print("Message: $message");
                      Fluttertoast.showToast(
                        msg: "Login fail",
                        toastLength: Toast.LENGTH_SHORT, // or Toast.LENGTH_LONG
                        gravity: ToastGravity.BOTTOM, // Location where the toast should appear
                        timeInSecForIosWeb: 1, // Time duration for which the toast should be visible
                        backgroundColor: Colors.grey,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    }
                  } catch (e) {
                    print("Error: $e");
                    Fluttertoast.showToast(
                      msg: "Login fail",
                      toastLength: Toast.LENGTH_SHORT, // or Toast.LENGTH_LONG
                      gravity: ToastGravity.BOTTOM, // Location where the toast should appear
                      timeInSecForIosWeb: 1, // Time duration for which the toast should be visible
                      backgroundColor: Colors.grey,
                      textColor: Colors.white,
                      fontSize: 16.0,
                    );
                  }
                },
                child: Text('Đăng Nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
