import 'package:flutter/material.dart';

import '../../../api/scholarship_service.dart';
import '../../../component/common_widgets.dart';
import '../../../model/scholarship_model.dart';

class ScholarshipCard extends StatelessWidget {
  final Scholarship scholarship;
  final double userGpa;
  final int userIncomeLevel;

  const ScholarshipCard({super.key, required this.scholarship, required this.userGpa, required this.userIncomeLevel});

  @override
  Widget build(BuildContext context) {
    final s = scholarship;
    final days = s.dDay >= 0 ? s.dDay : ScholarshipService.daysLeft(s.deadline);
    final scoreColor = s.matchScore >= 80
        ? Colors.green
        : s.matchScore >= 60
        ? Colors.orange
        : s.matchScore >= 40
        ? Colors.red
        : Colors.grey;
    final isUrgent = days >= 0 && days <= 3;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: s.matchScore >= 80 ? Colors.teal.shade200 : Colors.grey.shade200, width: s.matchScore >= 80 ? 1.5 : 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${s.matchScore}점',
              style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor, fontSize: 13),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 40,
              height: 4,
              child: LinearProgressIndicator(
                value: s.matchScore / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                s.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (s.isFullyMatched)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                child: const Text(
                  '지원 가능',
                  style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            if (isUrgent)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  '마감 임박! D-$days',
                  style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(s.organization ?? '가천대학교', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(width: 8),
              Text(
                s.amountLabel,
                style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          // 지원 조건
          if (s.requiredGpa > 0) _condRow(Icons.grade_outlined, '학점 조건', '${s.requiredGpa} 이상', userGpa >= s.requiredGpa ? Colors.green : Colors.red, null),
          if (s.requiredIncomeBracket < 10)
            _condRow(
              Icons.account_balance_outlined,
              '소득분위',
              '${s.requiredIncomeBracket}분위 이하',
              userIncomeLevel >= s.requiredIncomeBracket ? Colors.green : Colors.red,
              null,
            ),
          _condRow(Icons.autorenew_outlined, '중복수혜', s.duplicateAllowed ? '가능 (직전학기 수혜 무관)' : '불가 (직전학기 수혜자 불가)', s.duplicateAllowed ? Colors.green : Colors.red, null),
          _condRow(Icons.event_outlined, '마감일', s.deadline ?? '미정', days >= 0 ? Colors.black87 : Colors.grey, null),
          if (s.detail != null) ...[const SizedBox(height: 8), Text(s.detail!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.5))],
          const SizedBox(height: 12),
          // 신청 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // TODO: 공유 기능 연결
                  },
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('공유', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal.shade600,
                    side: BorderSide(color: Colors.teal.shade200),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    // TODO: ScholarshipService.getApplyUrl → 외부 신청 페이지
                    final url = await ScholarshipService.getApplyUrl(s.scholarshipId);
                    if (url != null) openUrl(url);
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('신청하기', style: TextStyle(fontSize: 13)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _condRow(IconData icon, String label, String value, Color statusColor, String? tooltip) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ),
        Expanded(
          child: Row(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
              ),
              if (tooltip != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: tooltip,
                  child: Icon(Icons.help_outline, size: 14, color: Colors.grey.shade400),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
