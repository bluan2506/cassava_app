import 'dart:io';

import 'package:flutter/material.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;

  ImagePreviewScreen({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Preview Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.file(File(imagePath)),
            SizedBox(height: 20), // Khoảng trắng giữa hình ảnh và button
            // ElevatedButton(
              // onPressed: () {
              //   // Xử lý khi button được nhấn
              //   Navigator.push(
              //     context,
              //     // MaterialPageRoute(builder: (context) => NextScreen()), // NextScreen là màn hình bạn muốn chuyển đến
              //   );
              // },
              // child: Text('Chuyển đến Màn hình mới'),
            // ),
          ],
        ),
      ),
    );
  }
}