import 'package:flutter/material.dart';

// 최소 장학금 금액 선택지 (원 단위, 0 = 제한없음)
const List<int> kMinAmountOptions = [0, 500000, 1000000, 2000000, 3000000];

String amountLabel(int amount) {
  if (amount == 0) return '제한없음';
  final man = amount ~/ 10000;
  return '$man만원 이상';
}

class ScholarshipEditDialog extends StatefulWidget {
  final double initialGpa;
  final int initialGrade;
  final int initialIncomeLevel;
  final bool initialAwardedLastSemester;
  final int initialMinAmount;
  final int initialPersonalTuition;
  final int initialMinPercentage;
  final void Function(double gpa, int grade, int income, bool awarded, int minAmount, int personalTuition, int minPercentage) onSave;

  const ScholarshipEditDialog({
    super.key,
    required this.initialGpa,
    required this.initialGrade,
    required this.initialIncomeLevel,
    required this.initialAwardedLastSemester,
    required this.initialMinAmount,
    required this.initialPersonalTuition,
    required this.initialMinPercentage,
    required this.onSave,
  });

  @override
  State<ScholarshipEditDialog> createState() => _ScholarshipEditDialogState();
}

class _ScholarshipEditDialogState extends State<ScholarshipEditDialog> {
  late double gpa;
  late int grade;
  late int income;
  late bool awarded;
  late int minAmount;
  late int personalTuition;
  late int minPercentage;
  late TextEditingController gpaCtrl;
  late TextEditingController tuitionCtrl;

  @override
  void initState() {
    super.initState();
    gpa = widget.initialGpa;
    grade = widget.initialGrade;
    income = widget.initialIncomeLevel;
    awarded = widget.initialAwardedLastSemester;
    minAmount = widget.initialMinAmount;
    personalTuition = widget.initialPersonalTuition;
    minPercentage = widget.initialMinPercentage;
    gpaCtrl = TextEditingController(text: gpa.toStringAsFixed(1));
    tuitionCtrl = TextEditingController(text: personalTuition == 0 ? '' : (personalTuition ~/ 10000).toString());
  }

  @override
  void dispose() {
    gpaCtrl.dispose();
    tuitionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('내 정보 수정', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // GPA — up/down 버튼 + 직접 입력
            Row(
              children: [
                const Text('학점', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const Spacer(),
                IconButton(
                  onPressed: gpa > 0.0
                      ? () {
                          setState(() {
                            gpa = (((gpa - 0.1).clamp(0.0, 4.5) * 10).floor() / 10);
                            gpaCtrl.text = gpa.toStringAsFixed(1);
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  color: Colors.teal,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: gpaCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.teal.shade600, width: 1.5),
                      ),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null) {
                        setState(() {
                          gpa = ((parsed.clamp(0.0, 4.5) * 10).floor() / 10);
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  onPressed: gpa < 4.5
                      ? () {
                          setState(() {
                            gpa = (((gpa + 0.1).clamp(0.0, 4.5) * 10).floor() / 10);
                            gpaCtrl.text = gpa.toStringAsFixed(1);
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  color: Colors.teal,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 학년
            Row(
              children: [
                const Text('학년', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const Spacer(),
                DropdownButton<int>(
                  value: grade,
                  items: List.generate(6, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}학년'))),
                  onChanged: (v) => setState(() => grade = v!),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 소득분위
            Row(
              children: [
                const Text('소득분위', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const Spacer(),
                DropdownButton<int>(
                  value: income,
                  items: List.generate(10, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}분위'))),
                  onChanged: (v) => setState(() => income = v!),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 직전 학기 수여 여부
            Row(
              children: [
                const Expanded(
                  child: Text('직전 학기 수여 여부', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => awarded = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: awarded ? Colors.teal.shade600 : Colors.grey.shade100,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                      border: Border.all(color: awarded ? Colors.teal.shade600 : Colors.grey.shade300),
                    ),
                    child: Text(
                      '예',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: awarded ? Colors.white : Colors.grey.shade600),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => awarded = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: !awarded ? Colors.teal.shade600 : Colors.grey.shade100,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                      border: Border.all(color: !awarded ? Colors.teal.shade600 : Colors.grey.shade300),
                    ),
                    child: Text(
                      '아니요',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: !awarded ? Colors.white : Colors.grey.shade600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 최소 장학금 금액 필터
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('최소 장학금 금액', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kMinAmountOptions.map((amt) {
                final selected = minAmount == amt;
                return GestureDetector(
                  onTap: () => setState(() => minAmount = amt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? Colors.teal.shade600 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? Colors.teal.shade600 : Colors.grey.shade300),
                    ),
                    child: Text(
                      amountLabel(amt),
                      style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? Colors.white : Colors.grey.shade700),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 개인 등록금 및 커버 비율
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('개인 등록금 (만원)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tuitionCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '예: 400(400만원)',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (v) {
                personalTuition = (int.tryParse(v) ?? 0) * 10000;
              },
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('요구 장학금 커버 비율 (%)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [0, 10, 30, 50, 100].map((pct) {
                final selected = minPercentage == pct;
                return GestureDetector(
                  onTap: () => setState(() => minPercentage = pct),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? Colors.teal.shade600 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? Colors.teal.shade600 : Colors.grey.shade300),
                    ),
                    child: Text(
                      pct == 0 ? '제한없음' : '$pct% 이상',
                      style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? Colors.white : Colors.grey.shade700),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: () {
            widget.onSave(gpa, grade, income, awarded, minAmount, personalTuition, minPercentage);
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade600),
          child: const Text('저장 및 재조회'),
        ),
      ],
    );
  }
}
