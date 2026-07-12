// lib/main.dart

import 'package:flutter/material.dart';

import 'screens/chat_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot Ruta Óptima ESPAM-MFL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0d47a1),
          primary: const Color(0xff1565c0),
          secondary: const Color(0xff00a86b),
          surface: Colors.white,
        ),
      ),
      home: const ChatScreen(),
    );
  }
}