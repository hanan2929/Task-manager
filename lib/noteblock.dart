class NoteBlock {
  String? imagePath;
  String text;

  NoteBlock({
    this.imagePath,
    this.text = "",
  });

  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'text': text,
      };

  factory NoteBlock.fromJson(Map<String, dynamic> json) => NoteBlock(
        imagePath: json['imagePath'],
        text: json['text'] ?? "",
      );
}
