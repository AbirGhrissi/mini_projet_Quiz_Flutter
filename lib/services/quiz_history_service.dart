import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QuizHistoryService {
  static const _historyKey = 'quizHistory';

  /// Sauvegarde un résultat de quiz dans l'historique.
  /// Le paramètre [result] est une Map contenant les détails du résultat.
  static Future<void> saveQuizResult(Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);

    List<Map<String, dynamic>> history = [];
    if (historyJson != null) {
      // Charger l'historique existant
      final List<dynamic> decoded = jsonDecode(historyJson);
      history = decoded.cast<Map<String, dynamic>>();
    }

    // Ajouter le nouveau résultat au début (optionnel)
    history.insert(0, result);

    // Limiter l'historique à 50 entrées max (optionnel)
    if (history.length > 50) {
      history = history.sublist(0, 50);
    }

    // Sauvegarder l'historique mis à jour
    final encoded = jsonEncode(history);
    await prefs.setString(_historyKey, encoded);
  }

  /// Récupère tout l'historique de quiz.
  static Future<List<Map<String, dynamic>>> getQuizHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);

    if (historyJson == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(historyJson);
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Efface l'historique complet
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
