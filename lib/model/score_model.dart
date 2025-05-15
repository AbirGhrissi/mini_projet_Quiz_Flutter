import 'dart:convert';

class QuizScore {
  final String category;
  final String difficulty;
  final int score;
  final int total;
  final DateTime date;

  QuizScore({
    required this.category,
    required this.difficulty,
    required this.score,
    required this.total,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'difficulty': difficulty,
      'score': score,
      'total': total,
      'date': date.toIso8601String(),
    };
  }

  factory QuizScore.fromMap(Map<String, dynamic> map) {
    return QuizScore(
      category: map['category'],
      difficulty: map['difficulty'],
      score: map['score'],
      total: map['total'],
      date: DateTime.parse(map['date']),
    );
  }

  String toJson() => json.encode(toMap());
  factory QuizScore.fromJson(String source) => QuizScore.fromMap(json.decode(source));
}