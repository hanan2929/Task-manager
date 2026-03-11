import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// --- MODELS ---

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

class Task {
  final int id;
  String title;
  final DateTime createdAt;
  List<NoteBlock> blocks;
  bool isCompleted;
  bool isArchived;

  Task({
    required this.id,
    required this.title,
    required this.createdAt,
    List<NoteBlock>? blocks,
    this.isCompleted = false,
    this.isArchived = false,
  }) : blocks = blocks ?? [NoteBlock(text: "")];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'isCompleted': isCompleted,
        'isArchived': isArchived,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? 0,
      title: json['title'] ?? "Untitled",
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      blocks: (json['blocks'] as List?)
              ?.map((b) => NoteBlock.fromJson(b))
              .toList() ??
          [NoteBlock(text: "")],
      isCompleted: json['isCompleted'] == true,
      isArchived: json['isArchived'] == true,
    );
  }
}

// --- DATA SERVICES ---

class TaskData {
  static const String _tasksKey = 'tasks';

  static Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString(_tasksKey);
    if (tasksString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(tasksString);
        return decoded
            .map((item) => Task.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint("Error loading tasks: $e");
        return [];
      }
    }
    return [];
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_tasksKey, encoded);
  }

  static Future<void> shareTaskAsPdf(Task task) async {
    final pdf = pw.Document();
    final List<pw.Widget> pdfContent = [];
    pdfContent.add(pw.Header(level: 0, text: task.title));
    pdfContent.add(pw.Text("Created: ${task.createdAt.toString()}"));
    pdfContent.add(pw.SizedBox(height: 20));

    for (var block in task.blocks) {
      if (block.text.isNotEmpty) {
        pdfContent.add(pw.Paragraph(text: block.text));
      }
      if (block.imagePath != null && block.imagePath!.isNotEmpty) {
        final imageFile = File(block.imagePath!);
        if (imageFile.existsSync()) {
          final image = pw.MemoryImage(imageFile.readAsBytesSync());
          pdfContent.add(pw.Center(child: pw.Image(image, height: 300)));
          pdfContent.add(pw.SizedBox(height: 10));
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pdfContent,
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${task.title.replaceAll(' ', '_')}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], subject: task.title);
  }
}
