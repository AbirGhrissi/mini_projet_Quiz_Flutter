import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/quiz_model.dart';

class QuizService {
  static const String _baseUrl = 'https://opentdb.com/api.php';
  static const String _categoryUrl = 'https://opentdb.com/api_category.php';
  static const int _maxRetries = 2;
  static const Duration _timeoutDuration = Duration(seconds: 10);

  // Fonction pour récupérer les catégories disponibles
  Future<List<Map<String, String>>> fetchCategories() async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        final response = await http.get(Uri.parse(_categoryUrl))
            .timeout(_timeoutDuration);

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          if (data['trivia_categories'] == null) {
            throw Exception('Format de réponse inattendu');
          }

          return (data['trivia_categories'] as List)
              .map<Map<String, String>>((category) => {
            'id': category['id'].toString(),
            'name': category['name'].toString(),
          })
              .toList();
        } else {
          throw Exception(
              'Erreur HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } catch (e) {
        attempt++;
        if (attempt >= _maxRetries) {
          throw Exception(
              'Échec du chargement des catégories après $_maxRetries tentatives: $e');
        }
        await Future.delayed(Duration(seconds: 1));
      }
    }
    throw Exception('Impossible de charger les catégories');
  }

  // Fonction pour récupérer les questions
  Future<List<Question>> fetchQuestions(
      String category, String difficulty, int numberOfQuestions) async {
    if (numberOfQuestions <= 0 || numberOfQuestions > 50) {
      throw Exception('Le nombre de questions doit être entre 1 et 50');
    }

    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        final uri = Uri.parse(
            '$_baseUrl?amount=$numberOfQuestions&category=$category&difficulty=$difficulty&type=multiple');

        final response = await http.get(uri).timeout(_timeoutDuration);

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));

          if (data['response_code'] != 0) {
            throw Exception(_getApiErrorMessage(data['response_code']));
          }

          if (data['results'] == null || (data['results'] as List).isEmpty) {
            throw Exception('Aucune question disponible pour ces paramètres');
          }

          return (data['results'] as List)
              .map<Question>((q) => Question.fromJson(q))
              .toList();
        } else {
          throw Exception(
              'Erreur HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } catch (e) {
        attempt++;
        if (attempt >= _maxRetries) {
          throw Exception(
              'Échec du chargement des questions après $_maxRetries tentatives: $e');
        }
        await Future.delayed(Duration(seconds: 1));
      }
    }
    throw Exception('Impossible de charger les questions');
  }

  String _getApiErrorMessage(int code) {
    switch (code) {
      case 1:
        return 'La base de données ne contient pas assez de questions pour votre requête';
      case 2:
        return 'Paramètres de requête invalides';
      case 3:
        return 'Token de session invalide';
      case 4:
        return 'Token de session épuisé. Veuillez réessayer plus tard';
      default:
        return 'Erreur inconnue de l\'API (code: $code)';
    }
  }
}