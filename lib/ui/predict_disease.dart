
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';

import '../model/field.dart';

class PredictDisease extends StatelessWidget {

  final Field field;
  PredictDisease(this.field);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cassava Leaf Classification',

      home: Home(this.field),

      debugShowCheckedModeBanner: false,
    );
  }
}

class Home extends StatefulWidget {
  final Field field;
  Home(this.field);
  @override
  _HomeState createState() => _HomeState(this.field);
}

class _HomeState extends State<Home> {
  final Field field;
  bool _loading = true;
  File? _image;
  List _output = ["hello"];
  final picker = ImagePicker(); //allows us to pick image from gallery or camera
  _HomeState(this.field);

  @override
  void initState() {
    //initS is the first function that is executed by default when this class is called
    super.initState();
    loadModel().then((value) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    //dis function disposes and clears our memory
    super.dispose();
    Tflite.close();
  }

  classifyImage(Field field, File image) async {
    //this function runs the model on the image
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 5, //the amout of categories our neural network can predict
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    uploadFile(image, output![0]['label']);
    setState(() {
      _output = output!;
      _loading = false;
    });
  }

  loadModel() async {
    //this function loads our model
    await Tflite.loadModel(
        model: 'assets/model.tflite', labels: 'assets/labels.txt');
  }

  pickImage() async {
    //this function to grab the image from camera
    var image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;
    setState(() {
      _image = File(image.path);
    });

    await classifyImage(field, _image!);
  }

  Future uploadFile(File image, String disease) async {
    String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = 'images/${field.fieldName}/$disease/$uniqueFileName';
    final ref = FirebaseStorage.instance.refFromURL('gs://testfield-db.appspot.com').child(path);
    UploadTask uploadTask = ref.putFile(image);

    final snapshot = await uploadTask.whenComplete(() => {});

    final urlDownload = await snapshot.ref.getDownloadURL();
    print('Download link: $urlDownload');
    uploadData(field, urlDownload);
  }

  Future<void> uploadData(Field field, String urlDownload) async {
    try {
      CollectionReference users = FirebaseFirestore.instance.collection(field.fieldName);

      await users.add({
        'time': DateTime.now().toString(),
        'disease': _output[0],
        'urlImage': urlDownload,
      });

      print('Data uploaded successfully!');
    } catch (e) {
      print('Error uploading data: $e');
    }
  }

  pickGalleryImage() async {
    //this function to grab the image from gallery
    var image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;


    setState(() {
      _image = File(image.path);
    });
    classifyImage(field, _image!);
  }

  Widget BackgroundImage(var height,var width){
    return Container(height: height,width : width,child : Image.asset('assets/cassava.jpg',fit: BoxFit.cover,));
  }

  Widget Result(var height,var width){

    try {
      _output[0]['label'];
    } catch (e) {
      return Center(child: Container(child: Text('cant identify',style: TextStyle(fontSize: 30),),));
    }

    return Container(

      child: Column(

        mainAxisAlignment: MainAxisAlignment.start,children: [
        Text(_output[0]['label'].toString(),textAlign: TextAlign.center,style: TextStyle(fontSize: 30),),
        SizedBox(height: 10,),
        Container(decoration: BoxDecoration(border: Border.all(width: 4,color: Colors.black)),height: height/1.5,width: width/1.2,child: Image.file(_image!,fit: BoxFit.cover,),),


      ],),
    );
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          centerTitle: true,
          title: Text(
            'Cassava Leaf Classification',
            style: TextStyle(
              color: Colors.white,

              fontSize: 20,
            ),
          ),
        ),
        floatingActionButton:  Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(

                child: Icon(

                    Icons.photo_album
                ),
                backgroundColor: Colors.green,
                onPressed: () {
                  pickGalleryImage();
                },
                heroTag: null,
              ),
              SizedBox(
                width: 10,
              ),
              FloatingActionButton(
                child: Icon(
                    Icons.camera
                ),
                backgroundColor: Colors.green,
                onPressed: (){
                  pickImage();
                },
                heroTag: null,
              )
            ]
        )
        ,
        body: Center(
            child : _image!=null ? Result(height,width):BackgroundImage(height,width)
        )
    );
  }
}