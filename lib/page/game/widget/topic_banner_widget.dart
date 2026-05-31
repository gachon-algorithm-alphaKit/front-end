import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../provider/topic_provider.dart';
import '../game_dashboard_page.dart';

class TopicBannerWidget extends ConsumerWidget {
  const TopicBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeState = ref.watch(activeTopicProvider);

    if (activeState.isLoading || activeState.topic == null) {
      return const SizedBox.shrink(); // Hide if loading or no active topic
    }

    final topic = activeState.topic!;
    final stat = activeState.voteStat;
    
    final total = stat?.totalCount ?? topic.totalVoteCount;
    final op1Count = stat?.opinion1Count ?? 0;
    final op2Count = stat?.opinion2Count ?? 0;
    
    int op1Percent = 50;
    int op2Percent = 50;
    if (total > 0) {
      op1Percent = (op1Count / total * 100).round();
      op2Percent = 100 - op1Percent;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GameDashboardPage()),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '오늘의 토픽',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              topic.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      topic.opinion1,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'VS',
                    style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      topic.opinion2,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Expanded(
                    flex: op1Percent == 0 && op2Percent == 0 ? 1 : op1Percent,
                    child: Container(height: 6, color: Colors.white),
                  ),
                  Expanded(
                    flex: op1Percent == 0 && op2Percent == 0 ? 1 : op2Percent,
                    child: Container(height: 6, color: Colors.amber),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$op1Percent%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('$total명 참여', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                Text('$op2Percent%', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
