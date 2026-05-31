import 'package:flutter/material.dart';

class OpinionTabBar extends StatelessWidget {
  final TabController controller;
  final String opinion1;
  final String opinion2;

  const OpinionTabBar({
    super.key,
    required this.controller,
    required this.opinion1,
    required this.opinion2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        splashBorderRadius: BorderRadius.circular(10),
        padding: const EdgeInsets.all(4),
        tabs: [
          Tab(
            height: 36,
            child: Text(opinion1, overflow: TextOverflow.ellipsis),
          ),
          Tab(
            height: 36,
            child: Text(opinion2, overflow: TextOverflow.ellipsis),
          ),
          const Tab(
            height: 36,
            child: Text('통계'),
          ),
        ],
      ),
    );
  }
}
