import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mini_projet/pages/login_page.dart';
import 'package:mini_projet/state/app_state.dart';
import 'package:mini_projet/utils/local_db.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'model/user.dart';
import 'settings/quiz_setting_page.dart';
import 'pages/quiz_page.dart';
import 'pages/leaderboard_page.dart';
import 'services/translation_service.dart';
import 'services/notification_service.dart';
import 'pages/historique_page.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserAdapter());
  }

  await LocalDB.init();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState()..loadPreferences(),
      child: MyApp(cameras: cameras),
    ),
  );
}

class MyApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late TranslationService _translationService;
  String? _currentLanguage; // Pour suivre la langue actuelle

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _currentLanguage = appState.language;
    _translationService = _createTranslationService(appState.language);
  }

  TranslationService _createTranslationService(String language) {
    return TranslationService(
      sourceLanguage: 'en',
      targetLanguage: language,
    );
  }



  @override
  void dispose() {
    _translationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (_currentLanguage != appState.language) {
          _currentLanguage = appState.language;
          _translationService.dispose();
          _translationService = _createTranslationService(appState.language);
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Quiz App',
          theme: appState.isDarkMode
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
              currentLanguage: appState.language,
              onChangeLanguage: (lang) => appState.setLanguage(lang),
              onThemeChanged: (isDark) => appState.setDarkMode(isDark),
              isDarkMode: appState.isDarkMode,
            ),
            '/quiz': (context) => QuizPage(
              currentLanguage: appState.language,
              translationService: _translationService,
            ),
            '/leaderboard': (context) => const LeaderboardPage(),
            '/history': (context) => const QuizHistoryPage(),
          },
        );
      },
    );
  }
}