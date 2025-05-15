import 'package:flutter/material.dart';
import '../services/score_service.dart';
import '../model/score_model.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scoreService = ScoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await scoreService.clearScores();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scores effacés')),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<QuizScore>>(
        future: scoreService.getScores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun score enregistré'));
          }

          final scores = snapshot.data!..sort((a, b) => b.score.compareTo(a.score));

          return ListView.builder(
            itemCount: scores.length,
            itemBuilder: (context, index) {
              final score = scores[index];
              final percentage = (score.score / score.total * 100).round();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: percentage >= 70
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    child: Text(
                      '$percentage%',
                      style: TextStyle(
                        color: percentage >= 70 ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('${score.category} - ${score.difficulty}'),
                  subtitle: Text(
                    '${score.date.day}/${score.date.month}/${score.date.year}',
                  ),
                  trailing: Text(
                    '${score.score}/${score.total}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}