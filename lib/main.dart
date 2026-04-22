import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }
 
  Future pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    image = File(pickedFile.path);
    setState(() {});
    readText();
  }

  Future saveItems() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> data =
      items.map((e) => jsonEncode(e)).toList();
  prefs.setStringList("shopping_list", data);
  }

  Future loadItems() async {
  final prefs = await SharedPreferences.getInstance();
  List<String>? data = prefs.getStringList("shopping_list");
  if (data != null) {
    setState(() {
      items = data
        .map((e) => Map<String, dynamic>.from(jsonDecode(e)))
        .toList();
    });
  }
}

  Future readText() async {
    final inputImage = InputImage.fromFile(image!);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    setState(() {
      result = recognizedText.text;
      items = result
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => {"text": e, "done": false})
        .toList();
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
          Expanded(
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      return Dismissible(
    key: Key(items[index]["text"] + index.toString()),
    direction: DismissDirection.horizontal, // swipe da destra a sinistra
    onDismissed: (direction) {
      setState(() {
        items.removeAt(index);
      });
      saveItems();
    },
    background: Container(
      color: Colors.red,
      padding: EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      child: Icon(Icons.delete, color: Colors.white),
    ),
    child: CheckboxListTile(
      value: items[index]["done"],
      onChanged: (value) {
        setState(() {
          items[index]["done"] = value;
        });
        saveItems();
      },
      title: TextField(
        controller: TextEditingController(text: items[index]["text"]),
        onChanged: (value) {
          items[index]["text"] = value;
          saveItems();
        },
        decoration: InputDecoration(border: InputBorder.none),
      ),
    ),
  );
    },
  ),
)
        ],
      ),
    );
  }
}