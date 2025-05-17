import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_page.dart';
import 'settings/quiz_setting_page.dart';
import 'pages/quiz_page.dart';
import 'pages/result_page.dart';
import 'pages/leaderboard_page.dart';
import 'services/translation_service.dart';
import 'services/notification_service.dart';
import 'pages/historique_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _currentLanguage = 'fr';
  bool _isDarkMode = false;
  late TranslationService _translationService;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _initTranslationService();
    _initializeNotifications();
  }

  void _initTranslationService() {
    _translationService = TranslationService(
      sourceLanguage: 'en',
      targetLanguage: _currentLanguage,
    );
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() {
      _isDarkMode = value;
    });
  }

  void _changeLanguage(String newLanguage) async {
    setState(() {
      _currentLanguage = newLanguage;
    });

    _translationService.dispose();
    _translationService = TranslationService(
      sourceLanguage: 'en',
      targetLanguage: newLanguage,
    );
  }

  void _initializeNotifications() {
    NotificationService().initialize();
    NotificationService().showDailyReminder();
  }

  @override
  void dispose() {
    _translationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz App',
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurpleAccent,
        ),
      )
          : ThemeData.light().copyWith(
        primaryColor: Colors.deepPurple,
        colorScheme: const ColorScheme.light(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurpleAccent,
        ),
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthPage(),
        '/': (context) => QuizSettingsPage(
          currentLanguage: _currentLanguage,
          onChangeLanguage: _changeLanguage,
          onThemeChanged: _setDarkMode,
          isDarkMode: _isDarkMode,
        ),
        '/quiz': (context) => QuizPage(
          currentLanguage: _currentLanguage,
          translationService: _translationService,
        ),
        '/leaderboard': (context) => const LeaderboardPage(),
        '/history': (context) => const QuizHistoryPage(),
      },
    );
  }
}
