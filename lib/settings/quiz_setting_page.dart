import 'package:flutter/material.dart';
import '../services/quiz_service.dart';

class QuizSettingsPage extends StatefulWidget {
  final String currentLanguage;
  final Function(String) onChangeLanguage;
  final bool isDarkMode;
  final void Function(bool) onThemeChanged;

  const QuizSettingsPage({
    Key? key,
    required this.currentLanguage,
    required this.onChangeLanguage,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  _QuizSettingsPageState createState() => _QuizSettingsPageState();
}

class _QuizSettingsPageState extends State<QuizSettingsPage> {
  late Future<List<Map<String, String>>> _categories;
  String _selectedCategory = '9';
  String _selectedDifficulty = 'easy';
  int _numberOfQuestions = 5;

  @override
  void initState() {
    super.initState();
    _categories = QuizService().fetchCategories();
  }

  Widget _buildLanguageCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _translate('language'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: widget.currentLanguage,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: const [
                DropdownMenuItem<String>(
                  value: 'fr',
                  child: Text('Français', style: TextStyle(fontSize: 16)),
                ),
                DropdownMenuItem<String>(
                  value: 'en',
                  child: Text('English', style: TextStyle(fontSize: 16)),
                ),
                DropdownMenuItem<String>(
                  value: 'ar',
                  child: Text('العربية', style: TextStyle(fontSize: 16)),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.onChangeLanguage(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _translate(String key) {
    final translations = {
      'language': {
        'en': 'Language',
        'fr': 'Langue',
        'ar': 'اللغة'
      },
      'category': {
        'en': 'Category',
        'fr': 'Catégorie',
        'ar': 'الفئة'
      },
      'difficulty': {
        'en': 'Difficulty',
        'fr': 'Difficulté',
        'ar': 'الصعوبة'
      },
      'question_count': {
        'en': 'Number of questions',
        'fr': 'Nombre de questions',
        'ar': 'عدد الأسئلة'
      },
      'start_quiz': {
        'en': 'START QUIZ',
        'fr': 'COMMENCER LE QUIZ',
        'ar': 'ابدأ الاختبار'
      }
    };

    return translations[key]?[widget.currentLanguage] ?? key;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres du Quiz'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.deepPurple,
        actions: [
          Row(
            children: [
              const Icon(Icons.dark_mode, color: Colors.deepPurple),
              Switch(
                value: widget.isDarkMode,
                onChanged: widget.onThemeChanged,
                activeColor: Colors.deepPurple,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: FutureBuilder<List<Map<String, String>>>(
          future: _categories,
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
              return _buildErrorScreen('Aucune catégorie disponible');
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  _buildLanguageCard(),
                  const SizedBox(height: 20),
                  _buildCategoryCard(snapshot.data!),
                  const SizedBox(height: 20),
                  _buildDifficultyCard(),
                  const SizedBox(height: 20),
                  _buildQuestionCountCard(),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/quiz',
                        arguments: {
                          'category': _selectedCategory,
                          'difficulty': _selectedDifficulty,
                          'numberOfQuestions': _numberOfQuestions,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text(
                      'COMMENCER LE QUIZ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(List<Map<String, String>> categories) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Catégorie',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['id'],
                  child: Text(
                    category['name']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Difficulté',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: const [
                DropdownMenuItem<String>(
                  value: 'easy',
                  child: Text('Facile', style: TextStyle(fontSize: 16)),
                ),
                DropdownMenuItem<String>(
                  value: 'medium',
                  child: Text('Moyen', style: TextStyle(fontSize: 16)),
                ),
                DropdownMenuItem<String>(
                  value: 'hard',
                  child: Text('Difficile', style: TextStyle(fontSize: 16)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCountCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nombre de questions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _numberOfQuestions,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: const [
                DropdownMenuItem<int>(
                  value: 5,
                  child: Text('5 Questions', style: TextStyle(fontSize: 16)),
                ),
                DropdownMenuItem<int>(
                  value: 10,
                  child: Text('10 Questions', style: TextStyle(fontSize: 16)),
                ),
                DropdownMenuItem<int>(
                  value: 15,
                  child: Text('15 Questions', style: TextStyle(fontSize: 16)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _numberOfQuestions = value!;
                });
              },
            ),
          ],
        ),
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