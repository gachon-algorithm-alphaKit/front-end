import '../model/scholarship_model.dart';

class ScholarshipService {
  // ─────────────────────────────────────────────────────────
  // TODO: GET /api/scholarships?gpa=&grade=&income=
  //   Response: List<Scholarship> (점수순 정렬)
  //   서버: 크롤링 DB에서 조건 매칭 + 점수 계산
  // ─────────────────────────────────────────────────────────
  static Future<List<Scholarship>> fetch(
    double gpa,
    int grade,
    int incomeLevel,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // MOCK: 적합도 점수 계산 (실제: DB 쿼리 + 서버 스코어링)
    return _mockScholarships.map((s) {
      int score = 40;
      if (s.requiredGpa == null || gpa >= s.requiredGpa!) {
        score += 30;
      }
      if (s.requiredIncomeLevel == null ||
          incomeLevel <= s.requiredIncomeLevel!) {
        score += 20;
      }
      if (gpa >= 3.5) {
        score += 10;
      }
      return Scholarship(
        id: s.id,
        title: s.title,
        organization: s.organization,
        amount: s.amount,
        deadline: s.deadline,
        requiredGpa: s.requiredGpa,
        requiredIncomeLevel: s.requiredIncomeLevel,
        detail: s.detail,
        applyUrl: s.applyUrl,
        score: score.clamp(0, 100),
      );
    }).toList()..sort((a, b) => b.score.compareTo(a.score));
  }

  // ─────────────────────────────────────────────────────────
  // TODO: POST /api/scholarships/apply
  //   Body: { scholarshipId, userId }
  //   서버: 외부 신청 URL 반환 또는 내부 신청 처리
  // ─────────────────────────────────────────────────────────
  static Future<String?> getApplyUrl(String scholarshipId) async {
    final s = _mockScholarships.firstWhere(
      (x) => x.id == scholarshipId,
      orElse: () => _mockScholarships[0],
    );
    return s.applyUrl;
  }

  static int daysLeft(String deadline) {
    try {
      final parts = deadline.split('.');
      final d = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return d.difference(DateTime.now()).inDays;
    } catch (_) {
      return 0;
    }
  }

  static final _mockScholarships = <Scholarship>[
    const Scholarship(
      id: 'S001',
      title: '교내 성적우수 장학금',
      organization: '가천대학교',
      amount: '수업료 전액',
      deadline: '2026.06.15',
      requiredGpa: 3.5,
      requiredIncomeLevel: null,
      detail: '직전 학기 성적 3.5 이상인 학생 대상. 학과별 선발 인원 상이.',
      applyUrl: 'https://www.gachon.ac.kr',
    ),
    const Scholarship(
      id: 'S002',
      title: '국가장학금 I유형',
      organization: '한국장학재단',
      amount: '최대 520만원/학기',
      deadline: '2026.06.30',
      requiredGpa: null,
      requiredIncomeLevel: 8,
      detail: '소득분위 8분위 이하 학생 대상. 성적 유지 기준 C학점 이상.',
      applyUrl: 'https://www.kosaf.go.kr',
    ),
    const Scholarship(
      id: 'S003',
      title: '근로장학금',
      organization: '한국장학재단',
      amount: '시급 11,000원',
      deadline: '2026.06.20',
      requiredGpa: null,
      requiredIncomeLevel: 9,
      detail: '교내 근로 장학금. 주당 최대 20시간 근무 가능.',
      applyUrl: 'https://www.kosaf.go.kr',
    ),
    const Scholarship(
      id: 'S004',
      title: '[장학공지] SW인재 장학금',
      organization: '가천대 SW중심대학',
      amount: '100만원/학기',
      deadline: '2026.06.10',
      requiredGpa: 3.0,
      requiredIncomeLevel: null,
      detail: 'SW 관련 학과 재학생 중 성적 3.0 이상. 포트폴리오 제출 필요.',
      applyUrl: 'https://www.gachon.ac.kr',
    ),
    const Scholarship(
      id: 'S005',
      title: '가천나눔 장학금',
      organization: '가천대학교',
      amount: '수업료 50%',
      deadline: '2026.07.01',
      requiredGpa: null,
      requiredIncomeLevel: 4,
      detail: '소득분위 4분위 이하 가정 형편이 어려운 학생 우선 선발.',
      applyUrl: 'https://www.gachon.ac.kr',
    ),
    const Scholarship(
      id: 'S006',
      title: '글로벌 리더 장학금',
      organization: '가천대학교',
      amount: '200만원/학기',
      deadline: '2026.05.31',
      requiredGpa: 3.8,
      requiredIncomeLevel: null,
      detail: '어학 성적 우수자 및 해외 교환학생 파견 예정자 대상.',
      applyUrl: 'https://www.gachon.ac.kr',
    ),
  ];
}
