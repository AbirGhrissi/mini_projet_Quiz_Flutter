import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../model/score_model.dart';
import '../services/quiz_service.dart';
import '../model/quiz_model.dart';
import '../services/translation_service.dart';
import '../services/score_service.dart';

class QuizPage extends StatefulWidget {
  final String currentLanguage;
  final TranslationService translationService;

  const QuizPage({
    super.key,
    required this.currentLanguage,
    required this.translationService,
  });

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late Future<List<Question>> _questions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _totalQuestions = 0;
  bool _isAnswerSelected = false;
  String? _selectedAnswer;
  int _timeLeft = 30;
  late Timer _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final int _questionDuration = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          if (_timeLeft == 5) {
            _playSound('warning');
          }
        } else {
          _playSound('timeout');
          _moveToNextQuestion();
        }
      });
    });
  }

  Future<void> _playSound(String soundType) async {
    try {
      final soundFile = 'sounds/${soundType}_${widget.currentLanguage}.wav';
      await _audioPlayer.play(AssetSource(soundFile));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _moveToNextQuestion() {
    _timer.cancel();
    setState(() {
      if (_currentQuestionIndex < _totalQuestions - 1) {
        _currentQuestionIndex++;
        _timeLeft = _questionDuration;
        _isAnswerSelected = false;
        _selectedAnswer = null;
        _startTimer();
      } else {
        _saveScore();
        Navigator.pushReplacementNamed(
          context,
          '/results',
          arguments: {
            'score': _score,
            'total': _totalQuestions,
          },
        );
      }
    });
  }

  Future<void> _saveScore() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final scoreService = ScoreService();
    await scoreService.saveScore(QuizScore(
      category: args['category'].toString(),
      difficulty: args['difficulty'].toString(),
      score: _score,
      total: _totalQuestions,
      date: DateTime.now(),
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    _totalQuestions = args['numberOfQuestions'] as int;
    _questions = QuizService().fetchQuestions(
      args['category'] as String,
      args['difficulty'] as String,
      _totalQuestions,
    );
  }

  void _answerQuestion(String selectedOption, String correctAnswer) async {
    _timer.cancel();

    final translatedSelected = widget.currentLanguage == 'en'
        ? selectedOption
        : await widget.translationService.translateText(selectedOption);

    final translatedCorrect = widget.currentLanguage == 'en'
        ? correctAnswer
        : await widget.translationService.translateText(correctAnswer);

    setState(() {
      _isAnswerSelected = true;
      _selectedAnswer = selectedOption;

      if (translatedSelected == translatedCorrect) {
        _score++;
        _playSound('correct');
      } else {
        _playSound('wrong');
      }

      Future.delayed(const Duration(milliseconds: 1500), () {
        _moveToNextQuestion();
      });
    });
  }

  Widget _buildTranslatedQuestion(String questionText) {
    return FutureBuilder<String>(
      future: widget.currentLanguage == 'en'
          ? Future.value(questionText)
          : widget.translationService.translateText(questionText),
      builder: (context, snapshot) {
        final displayText = snapshot.data ?? questionText;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              displayText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTranslatedOption(String option, bool isCorrect, bool isSelected) {
    return FutureBuilder<String>(
      future: widget.currentLanguage == 'en'
          ? Future.value(option)
          : widget.translationService.translateText(option),
      builder: (context, snapshot) {
        final displayText = snapshot.data ?? option;

        Color buttonColor = Colors.white;
        if (_isAnswerSelected) {
          if (isSelected) {
            buttonColor = isCorrect ? Colors.green.shade100 : Colors.red.shade100;
          } else if (isCorrect) {
            buttonColor = Colors.green.shade100;
          }
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: buttonColor,
            border: Border.all(
              color: _isAnswerSelected && isSelected
                  ? isCorrect ? Colors.green : Colors.red
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isAnswerSelected
                  ? null
                  : () => _answerQuestion(option, isCorrect ? option : ''),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 16,
                          color: _isAnswerSelected && isSelected
                              ? isCorrect
                              ? Colors.green.shade900
                              : Colors.red.shade900
                              : Colors.black,
                        ),
                      ),
                    ),
                    if (_isAnswerSelected && isSelected)
                      Icon(
                        isCorrect ? Icons.check : Icons.close,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _translate(String key) {
    final translations = {
      'question': {'en': 'Question', 'fr': 'Question', 'ar': 'سؤال'},
      'no_questions': {
        'en': 'No questions available',
        'fr': 'Aucune question disponible',
        'ar': 'لا توجد أسئلة متاحة'
      },
      'back': {'en': 'Back', 'fr': 'Retour', 'ar': 'رجوع'}
    };

    return translations[key]?[widget.currentLanguage] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_translate('question')} ${_currentQuestionIndex + 1}/$_totalQuestions',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _timeLeft > 5 ? Colors.deepPurple : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_timeLeft ${widget.currentLanguage == 'en' ? 's' : 's'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Question>>(
        future: _questions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorScreen(snapshot.error.toString());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildErrorScreen(_translate('no_questions'));
          }

          final currentQuestion = snapshot.data![_currentQuestionIndex];
          final progress = (_currentQuestionIndex + 1) / _totalQuestions;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  color: Colors.deepPurple,
                  minHeight: 6,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _timeLeft / _questionDuration,
                  backgroundColor: Colors.grey[200],
                  color: _timeLeft > 5 ? Colors.green : Colors.red,
                  minHeight: 4,
                ),
                const SizedBox(height: 16),
                _buildTranslatedQuestion(currentQuestion.question),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: currentQuestion.options.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final option = currentQuestion.options[index];
                      final isCorrect = option == currentQuestion.correctAnswer;
                      final isSelected = option == _selectedAnswer;

                      return _buildTranslatedOption(
                        option,
                        isCorrect,
                        isSelected,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.deepPurple,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              _translate('back'),
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}