import 'package:flutter/material.dart';
import 'homepage.dart';

void main() {
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Task Manager",
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: "Roboto",
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF667eea),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            fontFamily: "Roboto",
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
