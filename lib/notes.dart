import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'listsData.dart';

class NoteScreen extends StatefulWidget {
  final Task task;
  final VoidCallback onSave;
  const NoteScreen({super.key, required this.task, required this.onSave});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (var block in widget.task.blocks) {
      _controllers.add(TextEditingController(text: block.text));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, int index) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        final newBlock = NoteBlock(imagePath: image.path, text: "");
        widget.task.blocks.insert(index + 1, newBlock);
        _controllers.insert(index + 1, TextEditingController(text: ""));
      });
      widget.onSave();
    }
  }

  void _removeBlock(int index) {
    setState(() {
      if (widget.task.blocks.length > 1) {
        widget.task.blocks.removeAt(index);
        _controllers[index].dispose();
        _controllers.removeAt(index);
      } else {
        widget.task.blocks[0].imagePath = null;
        widget.task.blocks[0].text = "";
        _controllers[0].text = "";
      }
    });
    widget.onSave();
  }

  void _showImageOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery, index); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera, index); },
            ),
          ],
        ),
      ),
    );
  }

  void _performSave() {
    for (int i = 0; i < widget.task.blocks.length; i++) {
      widget.task.blocks[i].text = _controllers[i].text;
    }
    widget.onSave();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _performSave, icon: const Icon(Icons.save)),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: widget.task.blocks.length,
        itemBuilder: (context, index) {
          final block = widget.task.blocks[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (block.imagePath != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(block.imagePath!), fit: BoxFit.cover, width: double.infinity, height: 200),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => _removeBlock(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              TextField(
                controller: _controllers[index],
                maxLines: null,
                decoration: const InputDecoration(hintText: "Start typing...", border: InputBorder.none),
                style: const TextStyle(fontSize: 16),
                onChanged: (text) {
                   widget.task.blocks[index].text = text;
                   widget.onSave();
                },
              ),
              if (index == widget.task.blocks.length - 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => _showImageOptions(index),
                    icon: const Icon(Icons.add_a_photo, color: Color(0xFF667eea), size: 22),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
