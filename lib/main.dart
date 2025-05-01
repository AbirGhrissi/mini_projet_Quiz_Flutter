import 'package:flutter/material.dart';
import 'settings/quiz_setting_page.dart';
import 'pages/quiz_page.dart';
import 'pages/result_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      title: 'Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const QuizSettingsPage(),
        '/quiz': (context) => const QuizPage(),
        '/results': (context) => const ResultsPage(),
      },
    );
  }
}