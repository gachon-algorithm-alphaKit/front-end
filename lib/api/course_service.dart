import '../model/course_model.dart';

class CourseService {
  // ─────────────────────────────────────────────────────────
  // TODO: GET /api/courses/autocomplete?q=&type=name|professor|content
  //   Response: List<String> (자동완성 후보)
  // ─────────────────────────────────────────────────────────
  static Future<List<String>> autocomplete(
    String query,
    SearchType type,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (query.isEmpty) return [];
    return _mockCourses
        .map((c) => type == SearchType.professor ? c.professor : c.name)
        .where((s) => s.contains(query))
        .toSet()
        .take(5)
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // TODO: GET /api/courses/search?q=&type=name|professor|content&choseong=true
  //   Response: List<Course>
  //   서버에서 Trie + Rabin-Karp + 초성검색 처리
  // ─────────────────────────────────────────────────────────
  static Future<List<Course>> search(
    String query,
    SearchType type,
    bool isChoseong,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (query.isEmpty) return [];
    return _mockCourses
        .where((c) {
          switch (type) {
            case SearchType.name:
              return c.name.contains(query);
            case SearchType.professor:
              return c.professor.contains(query);
            case SearchType.content:
              return (c.planSummary ?? '').contains(query);
          }
        })
        .take(10)
        .toList();
  }

  static final _mockCourses = <Course>[
    const Course(
      id: 'CS001',
      name: '자료구조',
      professor: '김민준',
      department: '컴퓨터공학과',
      credit: '3',
      classTime: '월수 10:00',
      planSummary: '스택, 큐, 트리, 그래프 등 핵심 자료구조의 원리와 구현을 학습합니다.',
    ),
    const Course(
      id: 'CS002',
      name: '알고리즘',
      professor: '이지은',
      department: '컴퓨터공학과',
      credit: '3',
      classTime: '화목 13:00',
      planSummary: '정렬, 탐색, 동적 프로그래밍, 그리디 알고리즘을 다룹니다.',
    ),
    const Course(
      id: 'CS003',
      name: '운영체제',
      professor: '박현우',
      department: '컴퓨터공학과',
      credit: '3',
      classTime: '월수금 09:00',
      planSummary: '프로세스, 메모리 관리, 파일 시스템, 동기화를 학습합니다.',
    ),
    const Course(
      id: 'CS004',
      name: '컴퓨터네트워크',
      professor: '최서연',
      department: '컴퓨터공학과',
      credit: '3',
      classTime: '화목 10:30',
      planSummary: 'TCP/IP, OSI 7계층, 라우팅 프로토콜을 학습합니다.',
    ),
    const Course(
      id: 'CS005',
      name: '데이터베이스',
      professor: '김민준',
      department: '컴퓨터공학과',
      credit: '3',
      classTime: '수금 14:00',
      planSummary: '관계형 데이터베이스, SQL, 정규화를 학습합니다.',
    ),
    const Course(
      id: 'CS006',
      name: '소프트웨어공학',
      professor: '이지은',
      department: '소프트웨어학과',
      credit: '3',
      classTime: '월수 14:00',
      planSummary: '애자일, UML, 소프트웨어 설계 원칙을 학습합니다.',
    ),
    const Course(
      id: 'CS007',
      name: '인공지능',
      professor: '박현우',
      department: '컴퓨터공학과',
      credit: '3',
      classTime: '화목 15:00',
      planSummary: '머신러닝, 딥러닝 기초, 신경망 구조를 다룹니다.',
    ),
    const Course(
      id: 'CS008',
      name: '컴파일러',
      professor: '정다은',
      department: '컴퓨터공학과',
      credit: '3',
      classTime: '금 10:00',
      planSummary: '렉서, 파서, 코드 생성 등 컴파일러 구현 원리를 학습합니다.',
    ),
  ];

  // 외부 접근용 getter (찜목록 페이지에서 사용)
  static List<Course> get allCourses => _mockCourses;
}
