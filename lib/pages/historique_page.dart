import 'package:flutter/material.dart';
import '../services/quiz_history_service.dart';

class QuizHistoryPage extends StatefulWidget {
  const QuizHistoryPage({super.key});

  @override
  State<QuizHistoryPage> createState() => _QuizHistoryPageState();
}

class _QuizHistoryPageState extends State<QuizHistoryPage> {
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>? _bestScore;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await HiveQuizHistoryService.getQuizHistory();

    if (history.isNotEmpty) {
      history.sort((a, b) =>
          (b['percentage'] ?? 0).compareTo(a['percentage'] ?? 0));
      setState(() {
        _bestScore = history.first;
        _history = history.sublist(1);
      });
    } else {
      setState(() {
        _bestScore = null;
        _history = [];
      });
    }
  }

  Future<void> _clearHistory() async {
    await HiveQuizHistoryService.clearHistory();
    setState(() {
      _bestScore = null;
      _history = [];
    });
  }

  Future<void> _deleteScore(Map<String, dynamic> scoreToDelete) async {
    final allHistory = await HiveQuizHistoryService.getQuizHistory();
    allHistory.removeWhere((entry) =>
    entry['date'] == scoreToDelete['date'] &&
        entry['score'] == scoreToDelete['score'] &&
        entry['total'] == scoreToDelete['total']);
    await HiveQuizHistoryService.saveQuizHistory(allHistory);
    _loadHistory();
  }

  Widget _buildScoreTile(Map<String, dynamic> item) {
    final date = DateTime.tryParse(item['date'] ?? '');
    final formattedDate = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : 'Date inconnue';
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
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Supprimer ce score ?'),
              content: const Text(
                  'Voulez-vous vraiment supprimer ce quiz de l\'historique ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deleteScore(item);
                  },
                  child: const Text('Supprimer'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Quiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: (_history.isEmpty && _bestScore == null)
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
      body: (_history.isEmpty && _bestScore == null)
          ? const Center(child: Text('Aucun historique trouvé.'))
          : ListView(
        children: [
          if (_bestScore != null) ...[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                '🏆 Meilleur score',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildScoreTile(_bestScore!),
            const Divider(),
          ],
          if (_history.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                '📋 Autres scores',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ..._history.map((item) => _buildScoreTile(item)).toList(),
          ]
        ],
      ),
    );
  }
}
