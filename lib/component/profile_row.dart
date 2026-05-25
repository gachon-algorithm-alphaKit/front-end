import 'package:flutter/material.dart';

class ProfileRow extends StatelessWidget {
  final String label, value;
  const ProfileRow({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ],
  );
}
