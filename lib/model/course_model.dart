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

class Course {
  final int courseId;
  final int schoolId;
  final int professorId;
  final String courseCode;
  final String courseName;
  final String description;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String majorTerm;
  final String professorName;

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
