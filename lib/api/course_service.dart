// 실행 환경: Flutter 3.x / Dart 3.x (Android / iOS / Web)
// 필요 라이브러리: http: ^1.6.0, flutter_riverpod: ^3.3.1
// Input 데이터 출처: 가천대학교 강의 정보 (직접 수집 → 서버 DB 저장)
//   - 엔드포인트: GET /api/courses/
//   - 파라미터: school_id, search_type, keyword, professor_name, page, limit

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/course_model.dart';
import 'package:alpha_kit/config/api_constants.dart';

class CourseService {
  static const String baseUrl = ApiConstants.baseUrl;

  // 알고리즘: Trie 탐색 (접두사 자동완성) — 서버 연동 예정, 현재 mock 기반 선형 탐색 fallback
  static Future<List<String>> autocomplete(
    String query,
    SearchType type,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (query.isEmpty) {
      return [];
    }

    // TODO: 서버 Trie 탐색 연동 (GET /api/courses/autocomplete?q=&type=)
    return _mockCourses
        .map(
          (c) => switch (type) {
            SearchType.professor => professorNameFor(c),
            SearchType.content => c.description,
            SearchType.name => c.courseName,
          },
        )
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .toSet()
        .take(5)
        .toList();
  }

  // 알고리즘: Trie 탐색(접두사) + Rabin-Karp(부분 일치) — search_type 파라미터로 서버에 전달
  // search_type=name      → 서버: Trie 탐색 + Rabin-Karp (강의명)
  // search_type=professor → 서버: Trie 탐색 + Rabin-Karp (교수명)
  // search_type=content   → 서버: Rabin-Karp 단독 (강의 설명)
  static Future<List<Course>> search(
    String query,
    SearchType type,
    bool isChoseong, {
    int page = 1,
    int limit = 20,
  }) async {
    if (query.isEmpty) {
      return [];
    }

    String searchTypeStr = 'name';
    if (type == SearchType.professor) {
      searchTypeStr = 'professor';
    } else if (type == SearchType.content) {
      searchTypeStr = 'content';
    }

    String url =
        '$baseUrl/api/courses/?school_id=1&search_type=$searchTypeStr&page=$page&limit=$limit';

    if (type == SearchType.professor) {
      url += '&professor_name=${Uri.encodeComponent(query)}';
    } else {
      url += '&keyword=${Uri.encodeComponent(query)}';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          final List data = decoded['data'] ?? [];
          return data.map((json) => Course.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('Error fetching courses: $e');
    }
    return [];
  }

  static String professorNameFor(Course course) {
    if (course.professorName.isNotEmpty) {
      return course.professorName;
    }
    return _mockProfessors
        .firstWhere(
          (p) => p.professorId == course.professorId,
          orElse: () =>
              const Professor(professorId: 0, schoolId: 1, name: '담당교수 미정'),
        )
        .name;
  }

  // 자료구조: List<Course> — Trie 자동완성 fallback용 mock 데이터
  static final _mockProfessors = <Professor>[
    const Professor(professorId: 1, schoolId: 1, name: '김민준'),
    const Professor(professorId: 2, schoolId: 1, name: '이지은'),
    const Professor(professorId: 3, schoolId: 1, name: '박현우'),
    const Professor(professorId: 4, schoolId: 1, name: '최서연'),
    const Professor(professorId: 5, schoolId: 1, name: '정다은'),
  ];

  static final _mockCourses = <Course>[
    const Course(
      courseId: 1, schoolId: 1, professorId: 1,
      courseCode: 'CS001', courseName: '자료구조',
      description: '스택, 큐, 트리, 그래프 등 핵심 자료구조의 원리와 구현을 학습합니다.',
      dayOfWeek: '월수', startTime: '10:00', endTime: '11:15',
      majorTerm: '컴퓨터공학과 2학년',
    ),
    const Course(
      courseId: 2, schoolId: 1, professorId: 2,
      courseCode: 'CS002', courseName: '알고리즘',
      description: '정렬, 탐색, 동적 프로그래밍, 그리디 알고리즘을 다룹니다.',
      dayOfWeek: '화목', startTime: '13:00', endTime: '14:15',
      majorTerm: '컴퓨터공학과 3학년',
    ),
    const Course(
      courseId: 3, schoolId: 1, professorId: 3,
      courseCode: 'CS003', courseName: '운영체제',
      description: '프로세스, 메모리 관리, 파일 시스템, 동기화를 학습합니다.',
      dayOfWeek: '월수금', startTime: '09:00', endTime: '09:50',
      majorTerm: '컴퓨터공학과 3학년',
    ),
    const Course(
      courseId: 4, schoolId: 1, professorId: 4,
      courseCode: 'CS004', courseName: '컴퓨터네트워크',
      description: 'TCP/IP, OSI 7계층, 라우팅 프로토콜을 학습합니다.',
      dayOfWeek: '화목', startTime: '10:30', endTime: '11:45',
      majorTerm: '컴퓨터공학과 3학년',
    ),
    const Course(
      courseId: 5, schoolId: 1, professorId: 1,
      courseCode: 'CS005', courseName: '데이터베이스',
      description: '관계형 데이터베이스, SQL, 정규화를 학습합니다.',
      dayOfWeek: '수금', startTime: '14:00', endTime: '15:15',
      majorTerm: '컴퓨터공학과 3학년',
    ),
    const Course(
      courseId: 6, schoolId: 1, professorId: 2,
      courseCode: 'CS006', courseName: '소프트웨어공학',
      description: '애자일, UML, 소프트웨어 설계 원칙을 학습합니다.',
      dayOfWeek: '월수', startTime: '14:00', endTime: '15:15',
      majorTerm: '소프트웨어학과 3학년',
    ),
    const Course(
      courseId: 7, schoolId: 1, professorId: 3,
      courseCode: 'CS007', courseName: '인공지능',
      description: '머신러닝, 딥러닝 기초, 신경망 구조를 다룹니다.',
      dayOfWeek: '화목', startTime: '15:00', endTime: '16:15',
      majorTerm: '컴퓨터공학과 4학년',
    ),
    const Course(
      courseId: 8, schoolId: 1, professorId: 5,
      courseCode: 'CS008', courseName: '컴파일러',
      description: '렉서, 파서, 코드 생성 등 컴파일러 구현 원리를 학습합니다.',
      dayOfWeek: '금', startTime: '10:00', endTime: '12:45',
      majorTerm: '컴퓨터공학과 4학년',
    ),
  ];

  static List<Course> get allCourses => _mockCourses;
}
