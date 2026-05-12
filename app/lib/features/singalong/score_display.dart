import 'package:flutter/material.dart';
import 'scoring_pipeline.dart';

class ScoreDisplay extends StatelessWidget {
  final List<LineScore> lineScores;
  final int totalScore;

  const ScoreDisplay({
    super.key,
    required this.lineScores,
    required this.totalScore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Total score
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _scoreColor(totalScore).withAlpha(30),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text('Total Score',
                  style: Theme.of(context).textTheme.labelMedium),
              Text('$totalScore',
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.copyWith(color: _scoreColor(totalScore))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Per-line scores
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: lineScores.map((ls) {
            return Chip(
              label: Text('${ls.score}'),
              avatar: CircleAvatar(
                backgroundColor: _scoreColor(ls.score),
                child: Text('${ls.lineIndex + 1}',
                    style: const TextStyle(fontSize: 10, color: Colors.white)),
              ),
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
