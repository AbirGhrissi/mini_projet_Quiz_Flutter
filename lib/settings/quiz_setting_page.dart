import 'package:flutter/material.dart';
import '../main.dart';
import '../pages/historique_page.dart';
import '../pages/login_page.dart';
import '../services/quiz_service.dart';
import '../utils/local_db.dart';


class QuizSettingsPage extends StatefulWidget {
  final String currentLanguage;
  final Function(String) onChangeLanguage;
  final bool isDarkMode;
  final void Function(bool) onThemeChanged;
  final int? lastScore;

  const QuizSettingsPage({
    Key? key,
    required this.currentLanguage,
    required this.onChangeLanguage,
    required this.isDarkMode,
    required this.onThemeChanged,
    this.lastScore = 0, // valeur par défaut ici
  }) : super(key: key);

  @override
  _QuizSettingsPageState createState() => _QuizSettingsPageState();
}

class _QuizSettingsPageState extends State<QuizSettingsPage> {
  late Future<List<Map<String, String>>> _categories;
  String _selectedCategory = '9';
  String _selectedDifficulty = 'easy';
  int _numberOfQuestions = 5;
  bool _isSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _categories = QuizService().fetchCategories();
  }

  String _translate(String key) {
    final translations = {
      'language': {'en': 'Language', 'fr': 'Langue', 'ar': 'اللغة'},
      'category': {'en': 'Category', 'fr': 'Catégorie', 'ar': 'الفئة'},
      'difficulty': {'en': 'Difficulty', 'fr': 'Difficulté', 'ar': 'الصعوبة'},
      'question_count': {
        'en': 'Number of questions',
        'fr': 'Nombre de questions',
        'ar': 'عدد الأسئلة'
      },
      'start_quiz': {
        'en': 'START QUIZ',
        'fr': 'COMMENCER LE QUIZ',
        'ar': 'ابدأ الاختبار'
      },
      'last_score': {
        'en': 'Last score',
        'fr': 'Dernier score',
        'ar': 'آخر نتيجة'
      },
      'history': {
        'en': 'Quiz History',
        'fr': 'Historique des Quiz',
        'ar': 'سجل الاختبارات'
      },
      'mode_sombre': {
        'en': 'Dark Mode',
        'fr': 'Mode sombre',
        'ar': 'الوضع الداكن'
      },
    };

    return translations[key]?[widget.currentLanguage] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_translate('start_quiz')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.deepPurple,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'Paramètres',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            SwitchListTile(
              title: Text(_translate("mode_sombre")),
              value: widget.isDarkMode,
              onChanged: (value) {
                widget.onThemeChanged(value);
              },
              secondary: const Icon(Icons.dark_mode),
            ),
            SwitchListTile(
              title: const Text("Activer le son"),
              value: _isSoundEnabled,
              onChanged: (value) {
                setState(() {
                  _isSoundEnabled = value;
                });
              },
              secondary: Icon(_isSoundEnabled ? Icons.volume_up : Icons.volume_off),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(_translate("language")),
              trailing: DropdownButton<String>(
                value: widget.currentLanguage,
                onChanged: (value) {
                  if (value != null) {
                    widget.onChangeLanguage(value); // pareil, appelle parent directement
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'fr', child: Text("Français")),
                  DropdownMenuItem(value: 'en', child: Text("English")),
                  DropdownMenuItem(value: 'ar', child: Text("العربية")),
                ],
              ),
            ),
            if (widget.lastScore != null)
              ListTile(
                leading: const Icon(Icons.score),
                title: Text(
                  '${_translate("last_score")} : ${widget.lastScore}/100',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(_translate("history")),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuizHistoryPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: () async {
                Navigator.pop(context);
                await LocalDB.logoutUser();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => LoginPage(cameras: cameras),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: FutureBuilder<List<Map<String, String>>>(
          future: _categories,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
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
                          'soundEnabled': _isSoundEnabled,
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
                    child: Text(
                      _translate('start_quiz'),
                      style: const TextStyle(
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
    return _buildCard(
      label: _translate('category'),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        isExpanded: true,
        decoration: _inputDecoration(),
        items: categories.map((category) {
          return DropdownMenuItem<String>(
            value: category['id'],
            child: Text(category['name']!, style: const TextStyle(fontSize: 16)),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value!;
          });
        },
      ),
    );
  }

  Widget _buildDifficultyCard() {
    return _buildCard(
      label: _translate('difficulty'),
      child: DropdownButtonFormField<String>(
        value: _selectedDifficulty,
        isExpanded: true,
        decoration: _inputDecoration(),
        items: const [
          DropdownMenuItem(value: 'easy', child: Text('Facile')),
          DropdownMenuItem(value: 'medium', child: Text('Moyen')),
          DropdownMenuItem(value: 'hard', child: Text('Difficile')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedDifficulty = value!;
          });
        },
      ),
    );
  }

  Widget _buildQuestionCountCard() {
    return _buildCard(
      label: _translate('question_count'),
      child: DropdownButtonFormField<int>(
        value: _numberOfQuestions,
        isExpanded: true,
        decoration: _inputDecoration(),
        items: const [
          DropdownMenuItem(value: 5, child: Text('5 Questions')),
          DropdownMenuItem(value: 10, child: Text('10 Questions')),
          DropdownMenuItem(value: 15, child: Text('15 Questions')),
        ],
        onChanged: (value) {
          setState(() {
            _numberOfQuestions = value!;
          });
        },
      ),
    );
  }

  Widget _buildCard({required String label, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildErrorScreen(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 24),
          Text(message, style: const TextStyle(fontSize: 18, color: Colors.deepPurple), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour', style: TextStyle(fontSize: 16, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
