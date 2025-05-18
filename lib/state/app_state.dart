// app_state.dart
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  String _language = 'fr';
  bool _isDarkMode = false;

  String get language => _language;
  bool get isDarkMode => _isDarkMode;

  Future<void> setLanguage(String newLanguage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLanguage);
    _language = newLanguage;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    _isDarkMode = value;
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('language') ?? 'fr';
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
}