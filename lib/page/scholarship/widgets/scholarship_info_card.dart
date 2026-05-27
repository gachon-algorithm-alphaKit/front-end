import 'package:flutter/material.dart';

// 가상 위젯 - SingleChildScrollView 대용 가천대 요구사항 (실제 구현)
class WidgetBidirectionalScroll extends StatelessWidget {
  final Widget child;
  const WidgetBidirectionalScroll({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: child);
  }
}

class ScholarshipInfoCard extends StatelessWidget {
  final double gpa;
  final int grade;
  final int incomeLevel;
  final int minAmount;
  final int personalTuition;
  final int minPercentage;
  final bool awardedLastSemester;
  final String filter;
  final VoidCallback onEditTap;
  final ValueChanged<String> onFilterChanged;

  const ScholarshipInfoCard({
    super.key,
    required this.gpa,
    required this.grade,
    required this.incomeLevel,
    required this.minAmount,
    required this.personalTuition,
    required this.minPercentage,
    required this.awardedLastSemester,
    required this.filter,
    required this.onEditTap,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 내 정보 행
          Row(
            children: [
              const Text('내 정보', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text('직접 입력 (향후 학생 DB 자동 연동)', style: TextStyle(fontSize: 9, color: Colors.teal.shade700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _infoChip('학점', '${(gpa * 10).floor() / 10}점', Colors.teal),
                      const SizedBox(width: 8),
                      _infoChip('학년', '$grade학년', Colors.indigo),
                      const SizedBox(width: 8),
                      _infoChip('소득분위', '$incomeLevel분위', Colors.orange),
                      const SizedBox(width: 8),
                      _infoChip('직전수혜', awardedLastSemester ? 'O' : 'X', Colors.red),
                      const SizedBox(width: 8),
                      if (minAmount > 0) _infoChip('최소금액', '${minAmount ~/ 10000}만↑', Colors.deepPurple),
                      if (minAmount > 0 || (personalTuition > 0 && minPercentage > 0)) const SizedBox(width: 8),
                      if (personalTuition > 0 && minPercentage > 0) _infoChip('커버율', '$minPercentage%↑', Colors.blue),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: onEditTap,
                child: const Text('수정', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // 필터 탭
          WidgetBidirectionalScroll(
            child: Row(
              children: ['매칭순', '마감순', '금액순']
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => onFilterChanged(f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(color: filter == f ? Colors.teal.shade600 : Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            f,
                            style: TextStyle(fontSize: 13, color: filter == f ? Colors.white : Colors.grey.shade700, fontWeight: filter == f ? FontWeight.bold : FontWeight.normal),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: color)),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    ),
  );
}
