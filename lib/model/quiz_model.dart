class Question {
  final String question;
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final incorrectAnswers = List<String>.from(json['incorrect_answers']);
    final correctAnswer = json['correct_answer'] as String;
    final options = [...incorrectAnswers, correctAnswer]..shuffle();

    return Question(
      question: json['question'] as String,
      options: options,
      correctAnswer: correctAnswer,
    );
  }
}