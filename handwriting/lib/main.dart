import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? image;
  String result = "";

  Future pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    image = File(pickedFile.path);
    setState(() {});
    readText();
  }

  Future readText() async {
    final inputImage = InputImage.fromFile(image!);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    setState(() {
      result = recognizedText.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OCR App")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: pickImage,
            child: Text("Scatta foto"),
          ),
          if (image != null) Image.file(image!, height: 200),
          Expanded(child: SingleChildScrollView(child: Text(result))),
        ],
      ),
    );
  }
}