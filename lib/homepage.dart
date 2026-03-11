import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notes.dart';
import 'noteblock.dart';
import 'OAuth.dart';

// Task model
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
      isCompleted: json['isCompleted'] == true, // Robust check for boolean
      isArchived: json['isArchived'] == true,   // Robust check for boolean
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Task> _tasks = [];
  int _idCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(tasksString);
        setState(() {
          _tasks = decoded
              .map((item) => Task.fromJson(item as Map<String, dynamic>))
              .toList();
          if (_tasks.isNotEmpty) {
            _idCounter = _tasks.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
          }
        });
      } catch (e) {
        debugPrint("Error loading tasks: $e");
      }
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('tasks', encoded);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTask() {
    final String taskTitle = _controller.text.trim();
    if (taskTitle.isEmpty) {
      _focusNode.requestFocus();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Task"),
        content: Text("Are you sure you want to add this task: \"$taskTitle\"?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _focusNode.requestFocus();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _tasks.add(
                  Task(
                    id: _idCounter++,
                    title: taskTitle,
                    createdAt: DateTime.now(),
                    blocks: [NoteBlock(text: "")],
                  ),
                );
                _controller.clear();
              });
              _saveTasks();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Task added successfully")),
              );
              _focusNode.requestFocus();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _editTask(Task task) {
    final TextEditingController editController = TextEditingController(text: task.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Task Name"),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final newTitle = editController.text.trim();
              if (newTitle.isNotEmpty) {
                setState(() {
                  task.title = newTitle;
                });
                _saveTasks();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Task renamed")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.remove(task);
    });
    _saveTasks();
  }

  void _archiveTask(Task task) {
    setState(() {
      task.isArchived = true;
    });
    _saveTasks();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Task moved to archive"),),

    );
  }

  void _confirmDelete(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(task);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Task deleted")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _shareTask(Task task) async {
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

    try {
      await Share.shareXFiles([XFile(file.path)], subject: task.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sharing PDF: $e")),
        );
      }
    }
  }

  void _showTaskOptions(Task task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: const Text("Details"),
                onTap: () {
                  Navigator.pop(context);
                  _showTaskDetails(task);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text("Edit"),
                onTap: () {
                  Navigator.pop(context);
                  _editTask(task);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive, color: Colors.purple),
                title: const Text("Move to Archive"),
                onTap: () {
                  Navigator.pop(context);
                  _archiveTask(task);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.green),
                title: const Text("Share"),
                onTap: () {
                  Navigator.pop(context);
                  _shareTask(task);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete"),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(task);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Task Details"),
        content: Text(
          "Title: ${task.title}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter tasks to show only non-archived ones
    final visibleTasks = _tasks.where((t) => t.isArchived == false).toList();
    final archivedTasks = _tasks.where((task) => task.isArchived == true).toList();

    return Scaffold(
      appBar: AppBar(
        leading: PopupMenuButton<String>(
          icon: const Padding(
            padding: EdgeInsets.all(4.0),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
          onSelected: (value) {
            if (value == 'Profile') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OAuthScreen(),
                ),
              );
            } else if (value == 'Archive') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArchiveScreen(tasks: _tasks, onUpdate: _saveTasks),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Navigate to: $value")),
              );
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'Profile',
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('Profile'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'Archive',
              child: ListTile(
                leading: Icon(Icons.archive),
                title: Text('Archive'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'Settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'Login',
              child: ListTile(
                leading: Icon(Icons.login),
                title: Text('Login'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'Logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
        title: const Text("Task Manager"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Enter new task...",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _addTask(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF764ba2),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visibleTasks.isEmpty
                  ? const Center(
                child: Text(
                  "No tasks yet!",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: visibleTasks.length,
                itemBuilder: (context, index) {
                  final task = visibleTasks[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 6,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteScreen(task: task, onSave: _saveTasks),
                          ),
                        );
                      },
                      onLongPress: () => _showTaskOptions(task),
                      title: Text(
                        "${index + 1}. ${task.title}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// New Archive Screen
class ArchiveScreen extends StatefulWidget {
  final List<Task> tasks;
  final VoidCallback onUpdate;
  const ArchiveScreen({super.key, required this.tasks, required this.onUpdate});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  void _showArchiveTaskOptions(Task task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.unarchive, color: Colors.blue),
                title: const Text("Unarchive"),
                onTap: () {
                  setState(() {
                    task.isArchived = false;
                  });
                  widget.onUpdate();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Task unarchived")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete"),
                onTap: () {
                  setState(() {
                    widget.tasks.remove(task);
                  });
                  widget.onUpdate();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Task deleted")),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final archivedTasks = widget.tasks.where((t) => t.isArchived == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Archive"),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: archivedTasks.isEmpty
            ? const Center(
                child: Text(
                  "Archive is empty",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: archivedTasks.length,
                itemBuilder: (context, index) {
                  final task = archivedTasks[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 6,
                    margin: const EdgeInsets.only(bottom: 12),
                  child:   ListTile(
                      title: Text(task.title),
                      onLongPress: () => _showArchiveTaskOptions(task),
                      trailing: const Icon(Icons.more_vert),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
