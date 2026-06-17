// 실행 환경: Flutter 3.x / Dart 3.x
// 필요 라이브러리: 없음 (순수 Dart 모델 클래스)
// Input 데이터 출처: 가천대학교 강의 정보 (직접 수집 → 서버 DB 저장)
//   - 서버 응답 JSON 필드: course_id, course_name, professor_name, description,
//                          day_of_week, start_time, end_time, major_term

// 검색 타입 분기 (서버 search_type 파라미터에 대응)
// name      → 알고리즘: Trie 탐색 + Rabin-Karp (강의명)
// professor → 알고리즘: Trie 탐색 + Rabin-Karp (교수명)
// content   → 알고리즘: Rabin-Karp 단독 (강의 설명)
enum SearchType { name, professor, content }

class Professor {
  final int professorId;
  final int schoolId;
  final String name;

  const Professor({
    required this.professorId,
    required this.schoolId,
    required this.name,
  });

  factory Professor.fromJson(Map<String, dynamic> json) {
    return Professor(
      professorId: json['professor_id'],
      schoolId: json['school_id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'professor_id': professorId, 'school_id': schoolId, 'name': name};
  }

  @override
  String toString() {
    return 'Professor(professorId: $professorId, schoolId: $schoolId, name: $name)';
  }
}

// 자료구조: Course 모델 (자료구조·알고리즘 연결 필드)
// - courseId    : 자료구조 HashTable의 키 (course_id → 강의 정보 O(1) 조회)
// - courseName  : 자료구조 Trie에 삽입되는 단어 (강의명 접두사 탐색)
// - professorName: 자료구조 Trie에 삽입되는 단어 (교수명 접두사 탐색)
// - description : 알고리즘 Rabin-Karp 탐색 대상 텍스트 (강의 내용 검색)
class Course {
  final int courseId;         // 자료구조: HashTable 키
  final int schoolId;
  final int professorId;
  final String courseCode;
  final String courseName;    // 자료구조: Trie 삽입 키 (강의명)
  final String description;   // 알고리즘: Rabin-Karp 탐색 대상
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String majorTerm;
  final String professorName; // 자료구조: Trie 삽입 키 (교수명)

  const Course({
    required this.courseId,
    required this.schoolId,
    required this.professorId,
    required this.courseCode,
    required this.courseName,
    required this.description,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.majorTerm,
    this.professorName = '',
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseId: json['course_id'] ?? 0,
      schoolId: json['school_id'] ?? 1,
      professorId: json['professor_id'] ?? 0,
      courseCode: json['course_code'] ?? '',
      courseName: json['course_name'] ?? '',
      description: json['description'] ?? '',
      dayOfWeek: json['day_of_week'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      majorTerm: json['major_term'] ?? '',
      professorName: json['professor_name'] ?? '',
    );
  }

  String get classTimeLabel => '$dayOfWeek $startTime-$endTime';

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'school_id': schoolId,
      'professor_id': professorId,
      'course_code': courseCode,
      'course_name': courseName,
      'description': description,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'major_term': majorTerm,
      'professor_name': professorName,
    };
  }

  @override
  String toString() {
    return 'Course(courseId: $courseId, courseName: $courseName)';
  }
}

class StudentCourse {
  final int studentCourseId;
  final int studentId;
  final int courseId;

  const StudentCourse({
    required this.studentCourseId,
    required this.studentId,
    required this.courseId,
  });

  factory StudentCourse.fromJson(Map<String, dynamic> json) {
    return StudentCourse(
      studentCourseId: json['student_course_id'],
      studentId: json['student_id'],
      courseId: json['course_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_course_id': studentCourseId,
      'student_id': studentId,
      'course_id': courseId,
    };
  }

  @override
  String toString() {
    return 'StudentCourse(studentCourseId: $studentCourseId, studentId: $studentId, courseId: $courseId)';
  }
}
