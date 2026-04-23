class Item {
  String text;
  bool done;

  Item({
    required this.text,
    this.done = false,
  });

  // 👉 da JSON a oggetto
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      text: json['text'] as String,
      done: json['done'] as bool,
    );
  }

  // 👉 da oggetto a JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'done': done,
    };
  }
}