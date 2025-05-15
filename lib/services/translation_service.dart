import 'package:flutter/cupertino.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  final OnDeviceTranslator _translator;

  TranslationService({required String sourceLanguage, required String targetLanguage})
      : _translator = OnDeviceTranslator(
    sourceLanguage: _convertToMlKitLanguage(sourceLanguage),
    targetLanguage: _convertToMlKitLanguage(targetLanguage),
  );

  static TranslateLanguage _convertToMlKitLanguage(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return TranslateLanguage.french;
      case 'ar':
        return TranslateLanguage.arabic;
      default:
        return TranslateLanguage.english;
    }
  }

  Future<String> translateText(String text) async {
    try {
      if (_translator.sourceLanguage == _translator.targetLanguage) {
        return text;
      }
      return await _translator.translateText(text);
    } catch (e) {
      debugPrint('Erreur de traduction: $e');
      return text;
    }
  }

  void dispose() {
    _translator.close();
  }
}