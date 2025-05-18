import 'package:hive/hive.dart';
import '../utils/local_db.dart';

class HiveQuizHistoryService {
  static const String _boxName = 'quizHistoryBox';

  static Future<Box<List>> _getBox() async {
    return Hive.box<List>(_boxName);
  }

  static String? _getUserKey() {
    final user = LocalDB.getCurrentUser();
    return user?.name;
  }

  /// Sauvegarder un résultat pour l'utilisateur courant
  static Future<void> saveQuizResult(Map<String, dynamic> result) async {
    final box = await _getBox();
    final userKey = _getUserKey();
    if (userKey == null) return;

    final existing = box.get(userKey, defaultValue: [])!;
    final casted = existing.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();

    final updated = [result, ...casted];

    if (updated.length > 50) {
      updated.removeRange(50, updated.length);
    }

    await box.put(userKey, updated);
  }
  /// meilleur score
  static Future<Map<String, dynamic>?> getBestScore() async {
    final box = await _getBox();
    final userKey = _getUserKey();
    if (userKey == null) return null;

    final history = box.get(userKey, defaultValue: [])!;
    final casted = history.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();

    if (casted.isEmpty) return null;

    casted.sort((a, b) => (b['percentage'] as num).compareTo(a['percentage'] as num));
    return casted.first;
  }


  /// Récupérer l'historique de l'utilisateur courant
  static Future<List<Map<String, dynamic>>> getQuizHistory() async {
    final box = await _getBox();
    final userKey = _getUserKey();
    if (userKey == null) return [];

    final history = box.get(userKey, defaultValue: [])!.cast<Map>();
    return history.cast<Map<String, dynamic>>();
  }

  /// Supprimer l'historique de l'utilisateur courant
  static Future<void> clearHistory() async {
    final box = await _getBox();
    final userKey = _getUserKey();
    if (userKey == null) return;
    await box.delete(userKey);
  }

  static saveQuizHistory(List<Map<String, dynamic>> allHistory) {}
}
