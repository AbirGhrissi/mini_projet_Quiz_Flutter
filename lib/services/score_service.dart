import 'package:shared_preferences/shared_preferences.dart';
import '../model/score_model.dart';

class ScoreService {
  static const String _scoresKey = 'quiz_scores';

  Future<List<QuizScore>> getScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getStringList(_scoresKey) ?? [];
    return scoresJson.map((json) => QuizScore.fromJson(json)).toList();
  }

  Future<void> saveScore(QuizScore score) async {
    final prefs = await SharedPreferences.getInstance();
    final scores = await getScores();
    scores.add(score);
    await prefs.setStringList(
      _scoresKey,
      scores.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> clearScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scoresKey);
  }
}