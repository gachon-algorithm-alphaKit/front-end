import 'package:flutter/material.dart';

class VoteCountBadge extends StatelessWidget {
  final int count;
  const VoteCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade50,
            Colors.deepPurple.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.deepPurple.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_alt_rounded,
            size: 16,
            color: Colors.deepPurple.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            '총 $count명 참여',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
