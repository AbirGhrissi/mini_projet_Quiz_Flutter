import 'package:flutter/material.dart';
import '../services/quiz_history_service.dart';

class QuizHistoryPage extends StatefulWidget {
  const QuizHistoryPage({super.key});

  @override
  State<QuizHistoryPage> createState() => _QuizHistoryPageState();
}

class _QuizHistoryPageState extends State<QuizHistoryPage> {
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await QuizHistoryService.getQuizHistory();
    setState(() {
      _history = history;
    });
  }

  Future<void> _clearHistory() async {
    await QuizHistoryService.clearHistory();
    setState(() {
      _history = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Quiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _history.isEmpty
                ? null
                : () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Effacer l\'historique'),
                  content: const Text(
                      'Voulez-vous vraiment supprimer tout l\'historique ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearHistory();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Effacer'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: _history.isEmpty
          ? const Center(child: Text('Aucun historique trouvé.'))
          : ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          final date = DateTime.tryParse(item['date'] ?? '');
          final formattedDate =
          date != null ? '${date.day}/${date.month}/${date.year}' : '';
          final score = item['score'] ?? 0;
          final total = item['total'] ?? 0;
          final percent = item['percentage'] ?? 0;

          return ListTile(
            leading: CircleAvatar(
              child: Text('$percent%'),
              backgroundColor: percent >= 70 ? Colors.green : Colors.orange,
            ),
            title: Text('Score: $score / $total'),
            subtitle: Text('Date: $formattedDate'),
          );
        },
      ),
    );
  }
}
