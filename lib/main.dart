import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'item.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

void main() {
  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.green,
  ),
  home: Home(),
);
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
  
}

class _HomeState extends State<Home> {
  File? image;
  String result = "";
  List<Item> items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }
  void addItem() {
  TextEditingController controller = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Nuovo elemento"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Es. pane"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annulla"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  items.add(Item(text: controller.text.trim()));
                });
                saveItems();
              }
              Navigator.pop(context);
            },
            child: Text("Aggiungi"),
          ),
        ],
      );
    },
  );
}

bool isValidItem(String text) {
  // evita roba tipo "123", "***", ecc
  if (text.length < 2) return false;
  if (RegExp(r"^[^a-zA-Z]+$").hasMatch(text)) return false;
  return true;
}

List<Item> parseItemsAdvanced(String text) {
  // normalizza tutto
  String cleaned = text
      .toLowerCase()
      .replaceAll("\n", ",")
      .replaceAll(RegExp(r"[•\-–]"), ",")
      .replaceAll(" e ", ","); // pane e latte → pane, latte

  return cleaned
      .split(RegExp(r"[,\;]"))
      .map((e) => e.trim())
      .where((e) => isValidItem(e))
      .map((e) => Item(text: e))
      .toList();
}

Future<String> preprocessImage(String path) async {
  // carica immagine
  final image = cv.imread(path);

  // scala in grigio
  final gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY);

  

  // aumenta contrasto (threshold)
  final result = cv.threshold(
  gray,
  0,
  255,
  cv.THRESH_BINARY + cv.THRESH_OTSU,
);

// prendi solo l'immagine
final thresholdImage = result.$2;

  // salva immagine temporanea
  final outputPath = path.replaceAll(".jpg", "_processed.jpg");
  cv.imwrite(outputPath, thresholdImage);

  return outputPath;
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
      items.map((e) => jsonEncode(e.toJson())).toList();
  prefs.setStringList("shopping_list", data);
}

Future loadItems() async {
  final prefs = await SharedPreferences.getInstance();
  List<String>? data = prefs.getStringList("shopping_list");

  if (data != null) {
    setState(() {
      items = data
          .map((e) => Item.fromJson(jsonDecode(e)))
          .toList();
    });
  }
}

  Future readText() async {
   Future readText() async {
  final processedPath = await preprocessImage(image!.path);

  final inputImage = InputImage.fromFilePath(processedPath);
  final textRecognizer = TextRecognizer();

  final recognizedText =
      await textRecognizer.processImage(inputImage);

  setState(() {
    result = recognizedText.text;
    items = parseItemsAdvanced(result);
  });
}

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
  onPressed: addItem,
  icon: Icon(Icons.add),
  label: Text("Add new Item"),
),
      appBar: AppBar(
  title: Text(
    "Shopping List",
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  centerTitle: true,
),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: pickImage,
            child: Text("Scatta foto"),
          ),
          if (image != null) Image.file(image!, height: 200),
          Expanded(
            
  child:
  items.isEmpty
    ? Center(
        child: Text(
          "Nessun elemento 🛒",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
  : ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      return Dismissible(
    key: Key(items[index].text + index.toString()),
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
    child: Card(
  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: CheckboxListTile(
    value: items[index].done,
onChanged: (value) {
  setState(() {
    items[index].done = value!;
  });
  saveItems();
},
    title: TextField(
  controller: TextEditingController(text: items[index].text),
  style: TextStyle(
    decoration: items[index].done
        ? TextDecoration.lineThrough
        : TextDecoration.none,
    color: items[index].done ? Colors.grey : Colors.black,
  ),
  onChanged: (value) {
    items[index].text = value;
    saveItems();
  },
  decoration: InputDecoration(border: InputBorder.none),
),
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