import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/quiz_service.dart';
import '../model/quiz_model.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

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
  int _timeLeft = 30; // 30 secondes par question
  late Timer _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final int _questionDuration = 30; // Durée en secondes

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
          // Jouer un son d'avertissement quand il reste 5 secondes
          if (_timeLeft == 5) {
            _playSound('sounds/warning.wav');
          }
        } else {
          _playSound('sounds/timeout.wav');
          _moveToNextQuestion();
        }
      });
    });
  }

  Future<void> _playSound(String soundFile) async {
    await _audioPlayer.play(AssetSource(soundFile));
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

  void _answerQuestion(String selectedOption, String correctAnswer) {
    _timer.cancel();
    setState(() {
      _isAnswerSelected = true;
      _selectedAnswer = selectedOption;

      if (selectedOption == correctAnswer) {
        _score++;
        _playSound('sounds/correct.wav');
      } else {
        _playSound('sounds/wrong.wav');
      }

      Future.delayed(const Duration(milliseconds: 1500), () {
        _moveToNextQuestion();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Question ${_currentQuestionIndex + 1}/$_totalQuestions'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _timeLeft > 5 ? Colors.deepPurple : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_timeLeft s',
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
            return _buildErrorScreen('Aucune question disponible');
          }

          final currentQuestion = snapshot.data![_currentQuestionIndex];
          final progress = (_currentQuestionIndex + 1) / _totalQuestions;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Barre de progression du quiz
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  color: Colors.deepPurple,
                  minHeight: 6,
                ),
                const SizedBox(height: 8),
                // Barre de temps restant
                LinearProgressIndicator(
                  value: _timeLeft / _questionDuration,
                  backgroundColor: Colors.grey[200],
                  color: _timeLeft > 5 ? Colors.green : Colors.red,
                  minHeight: 4,
                ),
                const SizedBox(height: 16),
                // Carte de la question
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      currentQuestion.question,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Options de réponse
                Expanded(
                  child: ListView.separated(
                    itemCount: currentQuestion.options.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final option = currentQuestion.options[index];
                      final isCorrect = option == currentQuestion.correctAnswer;
                      final isSelected = option == _selectedAnswer;

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
                                : () => _answerQuestion(option, currentQuestion.correctAnswer),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _isAnswerSelected && isSelected
                                            ? isCorrect ? Colors.green.shade900 : Colors.red.shade900
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
            child: const Text(
              'Retour',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
