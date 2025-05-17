import 'package:flutter/material.dart';
import 'package:mini_projet/pages/quiz_page.dart';
import '../services/translation_service.dart';
import '../model/quiz_model.dart';
import '../services/quiz_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResultsPage extends StatefulWidget {
  final int score;
  final int total;
  final List<Question> questions;
  final String currentLanguage;
  final TranslationService translationService;
  final Map<String, dynamic> quizArgs;

  const ResultsPage({
    super.key,
    required this.score,
    required this.total,
    required this.questions,
    required this.currentLanguage,
    required this.translationService,
    required this.quizArgs,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late Map<String, String> _translatedTexts = {};
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _translateStaticTexts();
    _saveToHistory();
    _saveLastScore(); // <-- Important pour affichage dans Drawer
  }

  Future<void> _translateStaticTexts() async {
    setState(() => _isTranslating = true);

    final englishTexts = {
      'title': 'Results',
      'congratulations': 'Congratulations!',
      'well_done': 'Well done!',
      'quiz_completed': 'You completed the quiz',
      'final_score': 'Final score',
      'new_quiz': 'New quiz',
      'try_again': 'Try again with same questions',
      'success_threshold': '70% to pass',
    };

    if (widget.currentLanguage == 'en') {
      setState(() {
        _translatedTexts = englishTexts;
        _isTranslating = false;
      });
      return;
    }

    final translated = <String, String>{};
    for (final entry in englishTexts.entries) {
      try {
        translated[entry.key] =
        await widget.translationService.translateText(entry.value);
      } catch (e) {
        translated[entry.key] = entry.value;
      }
    }

    setState(() {
      _translatedTexts = translated;
      _isTranslating = false;
    });
  }

  Future<void> _saveToHistory() async {
    final percentage = (widget.score / widget.total * 100).round();

    await HiveQuizHistoryService.saveQuizResult({
      'score': widget.score,
      'total': widget.total,
      'percentage': percentage,
      'date': DateTime.now().toString(),
    });
  }

  Future<void> _saveLastScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastScore', widget.score);
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.score / widget.total * 100).round();
    final isSuccess = percentage >= 70;

    if (_isTranslating) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_translatedTexts['title'] ?? 'Results'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSuccess ? Colors.green.shade50 : Colors.orange.shade50,
                border: Border.all(
                  color: isSuccess ? Colors.green : Colors.orange,
                  width: 3,
                ),
              ),
              child: Icon(
                isSuccess ? Icons.emoji_events : Icons.sentiment_neutral,
                size: 60,
                color: isSuccess ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isSuccess
                  ? _translatedTexts['congratulations'] ?? 'Congratulations!'
                  : _translatedTexts['well_done'] ?? 'Well done!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _translatedTexts['quiz_completed'] ?? 'You completed the quiz',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _translatedTexts['final_score'] ?? 'Final score',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.score} / ${widget.total}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _translatedTexts['success_threshold'] ?? '70% to pass',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: Text(
                      _translatedTexts['new_quiz'] ?? 'New quiz',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.deepPurple),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizPage(
                      currentLanguage: widget.currentLanguage,
                      translationService: widget.translationService,
                    ),
                    settings: RouteSettings(arguments: {
                      ...widget.quizArgs,
                      'preloadedQuestions': widget.questions,
                    }),
                  ),
                );
              },
              child: Text(
                _translatedTexts['try_again'] ??
                    'Try again with same questions',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.translationService.dispose();
    super.dispose();
  }
}
