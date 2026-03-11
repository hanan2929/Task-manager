import 'package:flutter/material.dart';
import 'notes.dart';
import 'OAuth.dart';
import 'listsData.dart';
import 'archive_screen.dart';

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
    final loadedTasks = await TaskData.loadTasks();
    setState(() {
      _tasks = loadedTasks;
      if (_tasks.isNotEmpty) {
        _idCounter = _tasks.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
      }
    });
  }

  Future<void> _saveTasks() async {
    await TaskData.saveTasks(_tasks);
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
            onPressed: () => Navigator.pop(context),
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
              setState(() {
                _tasks.remove(task);
              });
              _saveTasks();
              Navigator.pop(context);
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
                  setState(() {
                    task.isArchived = true;
                  });
                  _saveTasks();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Task moved to archive")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.green),
                title: const Text("Share"),
                onTap: () {
                  Navigator.pop(context);
                  TaskData.shareTaskAsPdf(task);
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
        content: Text("Title: ${task.title}"),
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
    final visibleTasks = _tasks.where((t) => !t.isArchived).toList();

    return Scaffold(
      appBar: AppBar(
        leading: PopupMenuButton<String>(
          icon: const Padding(
            padding: EdgeInsets.all(4.0),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.deepPurpleAccent),
            ),
          ),
          onSelected: (value) async {
            if (value == 'Profile') {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const OAuthScreen()));
              setState(() {}); // Rebuild on return
            } else if (value == 'Archive') {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => ArchiveScreen(tasks: _tasks, onUpdate: _saveTasks)));
              setState(() {}); // Rebuild on return to show unarchived tasks
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'Profile', child: ListTile(leading: Icon(Icons.person), title: Text('Profile'))),
            const PopupMenuItem<String>(value: 'Archive', child: ListTile(leading: Icon(Icons.archive), title: Text('Archive'))),
            const PopupMenuItem<String>(value: 'Settings', child: ListTile(leading: Icon(Icons.settings), title: Text('Settings'))),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(value: 'Login', child: ListTile(leading: Icon(Icons.login), title: Text('Login'))),
            const PopupMenuItem<String>(value: 'Logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Logout', style: TextStyle(color: Colors.red)))),
          ],
        ),
        title: const Text("Task Manager"),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _addTask(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF764ba2)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visibleTasks.isEmpty
                  ? const Center(child: Text("No tasks yet!", style: TextStyle(color: Colors.white70, fontSize: 18)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: visibleTasks.length,
                      itemBuilder: (context, index) {
                        final task = visibleTasks[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 6,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (context) => NoteScreen(task: task, onSave: _saveTasks)));
                              setState(() {}); // Rebuild on return to show updated title
                            },
                            onLongPress: () => _showTaskOptions(task),
                            title: Text("${index + 1}. ${task.title}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 22)),
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
