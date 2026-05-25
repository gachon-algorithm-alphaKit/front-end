import '../model/course_model.dart';

class CourseService {
  // TODO: GET /api/courses/autocomplete?q=&type=name|professor|content
  static Future<List<String>> autocomplete(
    String query,
    SearchType type,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (query.isEmpty) {
      return [];
    }

    return _mockCourses
        .map(
          (c) => switch (type) {
            SearchType.professor => professorNameFor(c),
            SearchType.content => c.description,
            SearchType.name => c.courseName,
          },
        )
        .where((s) => s.contains(query))
        .toSet()
        .take(5)
        .toList();
  }

  // TODO: GET /api/courses/search?q=&type=name|professor|content&choseong=true
  static Future<List<Course>> search(
    String query,
    SearchType type,
    bool isChoseong,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (query.isEmpty) {
      return [];
    }

    return _mockCourses
        .where((c) {
          switch (type) {
            case SearchType.name:
              return c.courseName.contains(query);
            case SearchType.professor:
              return professorNameFor(c).contains(query);
            case SearchType.content:
              return c.description.contains(query);
          }
        })
        .take(10)
        .toList();
  }

  static String professorNameFor(Course course) {
    return _mockProfessors
        .firstWhere(
          (p) => p.professorId == course.professorId,
          orElse: () =>
              const Professor(professorId: 0, schoolId: 1, name: '담당교수 미정'),
        )
        .name;
  }

  static final _mockProfessors = <Professor>[
    const Professor(professorId: 1, schoolId: 1, name: '김민준'),
    const Professor(professorId: 2, schoolId: 1, name: '이지은'),
    const Professor(professorId: 3, schoolId: 1, name: '박현우'),
    const Professor(professorId: 4, schoolId: 1, name: '최서연'),
    const Professor(professorId: 5, schoolId: 1, name: '정다은'),
  ];

  static final _mockCourses = <Course>[
    const Course(
      courseId: 1,
      schoolId: 1,
      professorId: 1,
      courseCode: 'CS001',
      courseName: '자료구조',
      description: '스택, 큐, 트리, 그래프 등 핵심 자료구조의 원리와 구현을 학습합니다.',
      dayOfWeek: '월수',
      startTime: '10:00',
      endTime: '11:15',
      majorTerm: '컴퓨터공학과 2학년',
    ),
    const Course(
      courseId: 2,
      schoolId: 1,
      professorId: 2,
      courseCode: 'CS002',
      courseName: '알고리즘',
      description: '정렬, 탐색, 동적 프로그래밍, 그리디 알고리즘을 다룹니다.',
      dayOfWeek: '화목',
      startTime: '13:00',
      endTime: '14:15',
      majorTerm: '컴퓨터공학과 3학년',
    ),
    const Course(
      courseId: 3,
      schoolId: 1,
      professorId: 3,
      courseCode: 'CS003',
      courseName: '운영체제',
      description: '프로세스, 메모리 관리, 파일 시스템, 동기화를 학습합니다.',
      dayOfWeek: '월수금',
      startTime: '09:00',
      endTime: '09:50',
      majorTerm: '컴퓨터공학과 3학년',
    ),
    const Course(
      courseId: 4,
      schoolId: 1,
      professorId: 4,
      courseCode: 'CS004',
      courseName: '컴퓨터네트워크',
      description: 'TCP/IP, OSI 7계층, 라우팅 프로토콜을 학습합니다.',
      dayOfWeek: '화목',
      startTime: '10:30',
      endTime: '11:45',
      majorTerm: '컴퓨터공학과 3학년',
    ),
    const Course(
      courseId: 5,
      schoolId: 1,
      professorId: 1,
      courseCode: 'CS005',
      courseName: '데이터베이스',
      description: '관계형 데이터베이스, SQL, 정규화를 학습합니다.',
      dayOfWeek: '수금',
      startTime: '14:00',
      endTime: '15:15',
      majorTerm: '컴퓨터공학과 3학년',
    ),
    const Course(
      courseId: 6,
      schoolId: 1,
      professorId: 2,
      courseCode: 'CS006',
      courseName: '소프트웨어공학',
      description: '애자일, UML, 소프트웨어 설계 원칙을 학습합니다.',
      dayOfWeek: '월수',
      startTime: '14:00',
      endTime: '15:15',
      majorTerm: '소프트웨어학과 3학년',
    ),
    const Course(
      courseId: 7,
      schoolId: 1,
      professorId: 3,
      courseCode: 'CS007',
      courseName: '인공지능',
      description: '머신러닝, 딥러닝 기초, 신경망 구조를 다룹니다.',
      dayOfWeek: '화목',
      startTime: '15:00',
      endTime: '16:15',
      majorTerm: '컴퓨터공학과 4학년',
    ),
    const Course(
      courseId: 8,
      schoolId: 1,
      professorId: 5,
      courseCode: 'CS008',
      courseName: '컴파일러',
      description: '렉서, 파서, 코드 생성 등 컴파일러 구현 원리를 학습합니다.',
      dayOfWeek: '금',
      startTime: '10:00',
      endTime: '12:45',
      majorTerm: '컴퓨터공학과 4학년',
    ),
  ];

  static List<Course> get allCourses => _mockCourses;
}
