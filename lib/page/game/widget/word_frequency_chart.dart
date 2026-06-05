import 'package:flutter/material.dart';

class WordFrequencyChart extends StatelessWidget {
  final Map<String, int> frequencies;
  final int minimumComments;

  const WordFrequencyChart({super.key, required this.frequencies, this.minimumComments = 10});

  @override
  Widget build(BuildContext context) {
    if (frequencies.isEmpty) {
      return _buildEmptyState();
    }

    final maxValue = frequencies.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Icon(Icons.analytics_rounded, size: 20, color: Colors.deepPurple.shade600),
              const SizedBox(width: 8),
              Text(
                '자주 언급된 키워드',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
        ...frequencies.entries.map((entry) {
          final ratio = entry.value / maxValue;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    entry.key,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio.clamp(0.05, 1.0),
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600]),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${entry.value}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.deepPurple.shade600),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('댓글이 더 모이면 통계를 보여드립니다 📊', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
