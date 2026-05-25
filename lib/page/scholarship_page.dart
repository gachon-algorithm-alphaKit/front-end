import 'package:flutter/material.dart';

import '../api/scholarship_service.dart';
import '../component/common_widgets.dart';
import '../model/scholarship_model.dart';

class ScholarshipPage extends StatefulWidget {
  const ScholarshipPage({super.key});
  @override
  State<ScholarshipPage> createState() => _ScholarshipPageState();
}

class _ScholarshipPageState extends State<ScholarshipPage> {
  // TODO: 학생 정보는 로그인된 사용자의 실제 데이터로 교체
  double _gpa = 3.8;
  int _grade = 3, _incomeLevel = 5;
  bool _awardedLastSemester = false; // 직전 학기 수여 여부
  List<Scholarship> _scholarships = [];
  bool _isLoading = false;
  String _filter = '전체';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    // TODO: ScholarshipService.fetch → 크롤링 DB + 서버 스코어링
    final r = await ScholarshipService.fetch(_gpa, _grade, _incomeLevel);
    setState(() {
      _scholarships = r;
      _isLoading = false;
    });
  }

  List<Scholarship> get _filtered {
    switch (_filter) {
      case '적합':
        return _scholarships.where((s) => s.score >= 80).toList();
      case '확인필요':
        return _scholarships
            .where((s) => s.score >= 60 && s.score < 80)
            .toList();
      case '마감임박':
        return _scholarships.where((s) {
          final d = ScholarshipService.daysLeft(s.deadline);
          return d >= 0 && d <= 7;
        }).toList();
      default:
        return _scholarships;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: buildAppBar('장학 제도 탐색', Colors.teal.shade600),
      body: Column(
        children: [
          // 내 정보 카드 + 필터 탭 (하나의 흰 블록, 하단 둥근 마감)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 내 정보 행
                Row(
                  children: [
                    const Text(
                      '내 정보',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '직접 입력 (향후 학생 DB 자동 연동)',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _infoChip(
                      '학점',
                      '${(_gpa * 10).floor() / 10}점',
                      Colors.teal,
                    ),
                    const SizedBox(width: 8),
                    _infoChip('학년', '$_grade학년', Colors.indigo),
                    const SizedBox(width: 8),
                    _infoChip('소득분위', '$_incomeLevel분위', Colors.orange),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showInfoEdit(),
                      child: const Text('수정', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // 필터 탭
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['전체', '적합', '확인필요', '마감임박']
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _filter = f),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: _filter == f
                                      ? Colors.teal.shade600
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _filter == f
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: _filter == f
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
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
          ),

          // 장학금 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.money_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '해당 조건의 장학금이 없습니다',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _scholarshipCard(_filtered[i]),
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _scholarshipCard(Scholarship s) {
    final days = ScholarshipService.daysLeft(s.deadline);
    final scoreColor = s.score >= 80
        ? Colors.green
        : s.score >= 60
        ? Colors.orange
        : Colors.grey;
    final isUrgent = days >= 0 && days <= 7;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: s.score >= 80 ? Colors.teal.shade200 : Colors.grey.shade200,
          width: s.score >= 80 ? 1.5 : 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            '${s.score}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: scoreColor,
              fontSize: 15,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                s.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isUrgent)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'D-$days',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                s.organization ?? '가천대학교',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              Text(
                s.amountLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.teal.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          // 지원 조건
          if (s.requiredGpa > 0)
            _condRow(
              Icons.grade_outlined,
              '학점 조건',
              '${s.requiredGpa} 이상',
              _gpa >= s.requiredGpa ? Colors.green : Colors.red,
            ),
          if (s.requiredIncomeBracket < 10)
            _condRow(
              Icons.account_balance_outlined,
              '소득분위',
              '${s.requiredIncomeBracket}분위 이하',
              _incomeLevel <= s.requiredIncomeBracket
                  ? Colors.green
                  : Colors.red,
            ),
          _condRow(
            Icons.event_outlined,
            '마감일',
            s.deadline ?? '미정',
            days >= 0 ? Colors.black87 : Colors.grey,
          ),
          if (s.detail != null) ...[
            const SizedBox(height: 8),
            Text(
              s.detail!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
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
                    final url = await ScholarshipService.getApplyUrl(
                      s.scholarshipId,
                    );
                    if (url != null) openUrl(url);
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('신청하기', style: TextStyle(fontSize: 13)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _condRow(
    IconData icon,
    String label,
    String value,
    Color statusColor,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ],
    ),
  );

  void _showInfoEdit() {
    double gpa = _gpa;
    int grade = _grade, income = _incomeLevel;
    bool awarded = _awardedLastSemester;
    final gpaCtrl = TextEditingController(text: gpa.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, set) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '내 정보 수정',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // GPA — up/down 버튼 + 직접 입력
                Row(
                  children: [
                    const Text(
                      '학점',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: gpa > 0.0
                          ? () {
                              gpa =
                                  (((gpa - 0.1).clamp(0.0, 4.5) * 10).floor() /
                                  10);
                              gpaCtrl.text = gpa.toStringAsFixed(1);
                              set(() {});
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
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
                            borderSide: BorderSide(
                              color: Colors.teal.shade600,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (v) {
                          final parsed = double.tryParse(v);
                          if (parsed != null) {
                            gpa = ((parsed.clamp(0.0, 4.5) * 10).floor() / 10);
                            set(() {});
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: gpa < 4.5
                          ? () {
                              gpa =
                                  (((gpa + 0.1).clamp(0.0, 4.5) * 10).floor() /
                                  10);
                              gpaCtrl.text = gpa.toStringAsFixed(1);
                              set(() {});
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
                    const Text(
                      '학년',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton<int>(
                      value: grade,
                      items: List.generate(
                        4,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}학년'),
                        ),
                      ),
                      onChanged: (v) => set(() => grade = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 소득분위
                Row(
                  children: [
                    const Text(
                      '소득분위',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton<int>(
                      value: income,
                      items: List.generate(
                        10,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}분위'),
                        ),
                      ),
                      onChanged: (v) => set(() => income = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 직전 학기 수여 여부
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '직전 학기 수여 여부',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => set(() => awarded = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: awarded
                              ? Colors.teal.shade600
                              : Colors.grey.shade100,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(8),
                          ),
                          border: Border.all(
                            color: awarded
                                ? Colors.teal.shade600
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          '예',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: awarded
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => set(() => awarded = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: !awarded
                              ? Colors.teal.shade600
                              : Colors.grey.shade100,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                          border: Border.all(
                            color: !awarded
                                ? Colors.teal.shade600
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          '아니요',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: !awarded
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _gpa = gpa;
                  _grade = grade;
                  _incomeLevel = income;
                  _awardedLastSemester = awarded;
                });
                Navigator.pop(ctx);
                _load();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
              ),
              child: const Text('저장 및 재조회'),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 설정 페이지
// ══════════════════════════════════════════════════════════════
