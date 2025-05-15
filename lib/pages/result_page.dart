import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class ResultsPage extends StatefulWidget {
  final String currentLanguage;
  final TranslationService translationService;

  const ResultsPage({
    super.key,
    required this.currentLanguage,
    required this.translationService,
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
      'try_again': 'Try again',
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

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final score = args['score'] as int;
    final total = args['total'] as int;
    final percentage = (score / total * 100).round();
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
                    '$score / $total',
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
            if (!isSuccess)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  _translatedTexts['try_again'] ?? 'Try again',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.deepPurple,
                  ),
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