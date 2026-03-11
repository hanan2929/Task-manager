import 'package:flutter/material.dart';
import 'listsData.dart';

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
                    child: ListTile(
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
