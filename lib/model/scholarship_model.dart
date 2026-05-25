class Scholarship {
  final String id, title, organization, amount, deadline;
  final double? requiredGpa;
  final int? requiredIncomeLevel; // 1~10 분위
  final int score; // 0~100
  final String? detail, applyUrl;
  const Scholarship({
    required this.id,
    required this.title,
    required this.organization,
    required this.amount,
    required this.deadline,
    this.score = 0,
    this.requiredGpa,
    this.requiredIncomeLevel,
    this.detail,
    this.applyUrl,
  });
}

// ══════════════════════════════════════════════════════════════
// 서비스 클래스 (백엔드 연결 포인트)
// ══════════════════════════════════════════════════════════════
