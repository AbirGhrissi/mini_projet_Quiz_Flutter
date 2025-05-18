import 'dart:convert';

import 'package:flutter/material.dart';
import '../main.dart';
import '../model/user.dart';
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
    this.lastScore = 0,
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
  User? _currentUser = LocalDB.getCurrentUser();

  @override
  void initState() {
    super.initState();
    _categories = QuizService().fetchCategories();
    _loadCurrentUser();
  }

  void _loadCurrentUser() async {
    final user = await LocalDB.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
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
      'easy': {
        'en': 'Easy',
        'fr': 'Facile',
        'ar': 'سهل',
      },
      'medium': {
        'en': 'Medium',
        'fr': 'Moyen',
        'ar': 'متوسط',
      },
      'hard': {
        'en': 'Hard',
        'fr': 'Difficile',
        'ar': 'صعب',
      },
      'questions': {
        'en': 'questions',
        'fr': 'questions',
        'ar': 'أسئلة',
      },
      'category_general_knowledge': {
        'fr': 'Culture générale',
        'en': 'General Knowledge',
        'ar': 'المعرفة العامة',
      },
      'category_entertainment_books': {
        'fr': 'Livres',
        'en': 'Entertainment: Books',
        'ar': 'كتب',
      },
      'category_entertainment_film': {
        'fr': 'Films',
        'en': 'Entertainment: Film',
        'ar': 'أفلام',
      },
      'category_entertainment_music': {
        'fr': 'Musique',
        'en': 'Entertainment: Music',
        'ar': 'موسيقى',
      },
      'category_entertainment_musicals_theatres': {
        'fr': 'Comédies musicales et théâtres',
        'en': 'Entertainment: Musicals & Theatres',
        'ar': 'المسرحيات الموسيقية والمسرح',
      },
      'category_entertainment_television': {
        'fr': 'Télévision',
        'en': 'Entertainment: Television',
        'ar': 'تلفزيون',
      },
      'category_entertainment_video_games': {
        'fr': 'Jeux vidéo',
        'en': 'Entertainment: Video Games',
        'ar': 'ألعاب الفيديو',
      },
      'category_entertainment_board_games': {
        'fr': 'Jeux de société',
        'en': 'Entertainment: Board Games',
        'ar': 'ألعاب الطاولة',
      },
      'category_science_nature': {
        'fr': 'Science et nature',
        'en': 'Science & Nature',
        'ar': 'العلوم والطبيعة',
      },
      'category_science_computers': {
        'fr': 'Informatique',
        'en': 'Science: Computers',
        'ar': 'الحواسيب',
      },
      'category_science_mathematics': {
        'fr': 'Mathématiques',
        'en': 'Science: Mathematics',
        'ar': 'الرياضيات',
      },
      'category_mythology': {
        'fr': 'Mythologie',
        'en': 'Mythology',
        'ar': 'الأساطير',
      },
      'category_sports': {
        'fr': 'Sports',
        'en': 'Sports',
        'ar': 'الرياضة',
      },
      'category_geography': {
        'fr': 'Géographie',
        'en': 'Geography',
        'ar': 'الجغرافيا',
      },
      'category_history': {
        'fr': 'Histoire',
        'en': 'History',
        'ar': 'التاريخ',
      },
      'category_politics': {
        'fr': 'Politique',
        'en': 'Politics',
        'ar': 'السياسة',
      },
      'category_art': {
        'fr': 'Art',
        'en': 'Art',
        'ar': 'الفن',
      },
      'category_celebrities': {
        'fr': 'Célébrités',
        'en': 'Celebrities',
        'ar': 'المشاهير',
      },
      'category_animals': {
        'fr': 'Animaux',
        'en': 'Animals',
        'ar': 'الحيوانات',
      },
      'category_vehicles': {
        'fr': 'Véhicules',
        'en': 'Vehicles',
        'ar': 'المركبات',
      },
      'category_entertainment_comics': {
        'fr': 'Bandes dessinées',
        'en': 'Entertainment: Comics',
        'ar': 'القصص المصورة',
      },
      'category_science_gadgets': {
        'fr': 'Gadgets',
        'en': 'Science: Gadgets',
        'ar': 'الأدوات',
      },
        'category_entertainment_japanese_anime_manga': {
          'fr': 'Anime japonais et Manga',
          'en': 'Entertainment: Japanese Anime & Manga',
          'ar': 'الأنمي والمانغا اليابانية',
        },
        'category_entertainment_cartoon_animations': {
          'fr': 'Dessins animés',
          'en': 'Entertainment: Cartoon & Animations',
          'ar': 'الرسوم المتحركة',
        },
      'welcome_message': {
        'en': 'Welcome, {name}',
        'fr': 'Bienvenue, {name}',
        'ar': 'مرحبا بك، {name}'
      },
      'welcome_generic': {
        'en': 'Welcome',
        'fr': 'Bienvenue',
        'ar': 'مرحبا بك'
      },
    };

    return translations[key]?[widget.currentLanguage] ?? key;
  }

  String _translateWithParams(String key, Map<String, String> params) {
    String translation = _translate(key);
    params.forEach((key, value) {
      translation = translation.replaceAll('{$key}', value);
    });
    return translation;
  }

  String _getCategoryTranslationKey(String categoryName) {
    // Liste des correspondances spéciales
    final specialCases = {
      'Entertainment: Japanese Anime & Manga': 'category_entertainment_japanese_anime_manga',
      'Entertainment: Cartoon & Animations': 'category_entertainment_cartoon_animations',
      'Science & Nature': 'category_science_nature',
      'Entertainment: Musicals & Theatres': 'category_entertainment_musicals_theatres',
      // Ajoutez d'autres cas spéciaux si nécessaire
    };

    // Vérifie d'abord si c'est un cas spécial
    if (specialCases.containsKey(categoryName)) {
      return specialCases[categoryName]!;
    }

    // Conversion standard pour les autres cas
    return 'category_${categoryName.toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(':', '')
        .replaceAll('&', '')
        .replaceAll(' ', '')}';
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
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_currentUser != null && _currentUser!.imageBase64 != null)
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: MemoryImage(
                        base64Decode(_currentUser!.imageBase64),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _currentUser != null && _currentUser!.name != null
                        ? _translateWithParams('welcome_message', {'name': _currentUser!.name!})
                        : _translate('welcome_generic'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
            SwitchListTile(
              title: Text(_translate("mode_sombre")),
              value: widget.isDarkMode,
              onChanged: (value) {
                widget.onThemeChanged(!widget.isDarkMode);
                Future.delayed(Duration.zero, () {
                  if (mounted) {
                    setState(() {});
                  }
                });
              },
            ),
            SwitchListTile(
              title: Text(widget.currentLanguage == 'fr'
                  ? "Activer le son"
                  : widget.currentLanguage == 'en'
                  ? "Enable sound"
                  : "تفعيل الصوت"),
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
                    widget.onChangeLanguage(value);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'fr', child: Text("Français")),
                  DropdownMenuItem(value: 'en', child: Text("English")),
                  DropdownMenuItem(value: 'ar', child: Text("العربية")),
                ],
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
              title: Text(widget.currentLanguage == 'fr'
                  ? 'Déconnexion'
                  : widget.currentLanguage == 'en'
                  ? 'Logout'
                  : 'تسجيل الخروج'),
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
          String translationKey = _getCategoryTranslationKey(category['name']!);
          return DropdownMenuItem<String>(
            value: category['id'],
            child: Text(
              _translate(translationKey),
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
    );
  }

  Widget _buildDifficultyCard() {
    return _buildCard(
      label: _translate('difficulty'),
      child: DropdownButtonFormField<String>(
        value: _selectedDifficulty,
        isExpanded: true,
        decoration: _inputDecoration(),
        items: [
          DropdownMenuItem(value: 'easy', child: Text(_translate('easy'))),
          DropdownMenuItem(value: 'medium', child: Text(_translate('medium'))),
          DropdownMenuItem(value: 'hard', child: Text(_translate('hard'))),
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
        items: [
          DropdownMenuItem(value: 5, child: Text('5 ${_translate('questions')}')),
          DropdownMenuItem(value: 10, child: Text('10 ${_translate('questions')}')),
          DropdownMenuItem(value: 15, child: Text('15 ${_translate('questions')}')),
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
            child: Text(
                widget.currentLanguage == 'fr'
                    ? 'Retour'
                    : widget.currentLanguage == 'en'
                    ? 'Back'
                    : 'العودة',
                style: const TextStyle(fontSize: 16, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}