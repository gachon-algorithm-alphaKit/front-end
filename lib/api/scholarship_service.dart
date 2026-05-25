import '../model/scholarship_model.dart';

class ScholarshipService {
  // TODO: GET /api/scholarships?gpa=&grade=&income=
  static Future<List<Scholarship>> fetch(
    double gpa,
    int grade,
    int incomeLevel,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));

    return _mockScholarships.map((s) {
      int score = 40;
      if (gpa >= s.requiredGpa) {
        score += 30;
      }
      if (incomeLevel <= s.requiredIncomeBracket) {
        score += 20;
      }
      if (gpa >= 3.5) {
        score += 10;
      }
      return s.copyWith(score: score.clamp(0, 100));
    }).toList()..sort((a, b) => b.score.compareTo(a.score));
  }

  // TODO: POST /api/scholarships/apply
  static Future<String?> getApplyUrl(int scholarshipId) async {
    final s = _mockScholarships.firstWhere(
      (x) => x.scholarshipId == scholarshipId,
      orElse: () => _mockScholarships[0],
    );
    return s.applyUrl;
  }

  static int daysLeft(String? deadline) {
    if (deadline == null || deadline.isEmpty) {
      return 0;
    }
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

  static const _mockScholarships = <Scholarship>[
    Scholarship(
      scholarshipId: 1,
      schoolId: 1,
      name: '교내 성적우수 장학금',
      amount: 4000000,
      requiredGpa: 3.5,
      requiredIncomeBracket: 10,
      duplicateAllowed: false,
      organization: '가천대학교',
      deadline: '2026.06.15',
      detail: '직전 학기 성적 3.5 이상인 학생 대상. 학과별 선발 인원 상이.',
      applyUrl: 'https://www.gachon.ac.kr',
    ),
    Scholarship(
      scholarshipId: 2,
      schoolId: 1,
      name: '국가장학금 I유형',
      amount: 5200000,
      requiredGpa: 0,
      requiredIncomeBracket: 8,
      duplicateAllowed: true,
      organization: '한국장학재단',
      deadline: '2026.06.30',
      detail: '소득분위 8분위 이하 학생 대상. 성적 유지 기준 C학점 이상.',
      applyUrl: 'https://www.kosaf.go.kr',
    ),
    Scholarship(
      scholarshipId: 3,
      schoolId: 1,
      name: '근로장학금',
      amount: 11000,
      requiredGpa: 0,
      requiredIncomeBracket: 9,
      duplicateAllowed: true,
      organization: '한국장학재단',
      deadline: '2026.06.20',
      detail: '교내 근로 장학금. 주당 최대 20시간 근무 가능.',
      applyUrl: 'https://www.kosaf.go.kr',
    ),
    Scholarship(
      scholarshipId: 4,
      schoolId: 1,
      name: '[장학공지] SW인재 장학금',
      amount: 1000000,
      requiredGpa: 3.0,
      requiredIncomeBracket: 10,
      duplicateAllowed: true,
      organization: '가천대 SW중심대학',
      deadline: '2026.06.10',
      detail: 'SW 관련 학과 재학생 중 성적 3.0 이상. 포트폴리오 제출 필요.',
      applyUrl: 'https://www.gachon.ac.kr',
    ),
    Scholarship(
      scholarshipId: 5,
      schoolId: 1,
      name: '가천나눔 장학금',
      amount: 2000000,
      requiredGpa: 0,
      requiredIncomeBracket: 4,
      duplicateAllowed: true,
      organization: '가천대학교',
      deadline: '2026.07.01',
      detail: '소득분위 4분위 이하 가정 형편이 어려운 학생 우선 선발.',
      applyUrl: 'https://www.gachon.ac.kr',
    ),
    Scholarship(
      scholarshipId: 6,
      schoolId: 1,
      name: '글로벌 리더 장학금',
      amount: 2000000,
      requiredGpa: 3.8,
      requiredIncomeBracket: 10,
      duplicateAllowed: false,
      organization: '가천대학교',
      deadline: '2026.05.31',
      detail: '어학 성적 우수자 및 해외 교환학생 파견 예정자 대상.',
      applyUrl: 'https://www.gachon.ac.kr',
    ),
  ];
}
