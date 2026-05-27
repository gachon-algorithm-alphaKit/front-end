import 'package:flutter/material.dart';

import '../../../component/common_widgets.dart';
import '../../../model/route_model.dart';

/// 경로 결과 요약 카드 (최적 경로 + 세그먼트 타일)
class RouteResultCard extends StatelessWidget {
  final RouteResult result;

  const RouteResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text('최적 경로', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '총 ${result.totalDistanceM.round()}m',
                  style: const TextStyle(fontSize: 13, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (result.orderedStops.length > 2) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: result.orderedStops.asMap().entries.map((e) {
                final isFirst = e.key == 0;
                final isLast = e.key == result.orderedStops.length - 1;
                final Color bg = isFirst
                    ? Colors.green
                    : isLast
                    ? Colors.red
                    : Colors.orange;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: bg.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(fontSize: 11, color: bg, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          ...result.segments.asMap().entries.map((e) => _segmentTile(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _segmentTile(int idx, WaypointResult seg) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                '${idx + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            if (idx < result.segments.length - 1) Container(width: 2, height: 32, color: Colors.blueAccent.withValues(alpha: 0.3)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${seg.from} → ${seg.to}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('${seg.distanceM.round()}m  |  ${seg.path.join(' → ')}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    ),
  );
}
