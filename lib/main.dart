import 'package:flutter/material.dart';
import 'package:mini_projet/pages/login_page.dart';
import 'package:mini_projet/utils/local_db.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';


import 'model/user.dart';
import 'settings/quiz_setting_page.dart';
import 'pages/quiz_page.dart';
import 'pages/result_page.dart';
import 'pages/leaderboard_page.dart';
import 'services/translation_service.dart';
import 'services/notification_service.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserAdapter());
  }

  await LocalDB.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp(cameras: cameras));
}


class MyApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

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
        '/auth': (context) => LoginPage(cameras: cameras),
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
        '/results': (context) => ResultsPage(
          currentLanguage: _currentLanguage,
          translationService: _translationService,
        ),
        '/leaderboard': (context) => const LeaderboardPage(),
      },
    );
  }
}
