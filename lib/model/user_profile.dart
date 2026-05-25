class Student {
  final int studentId;
  final int schoolId;
  final String loginId;
  final String passwordHash;
  final String name;
  final String major;
  final double gpa;
  final int incomeBracket;
  final String profileImg;

  const Student({
    required this.studentId,
    required this.schoolId,
    required this.loginId,
    required this.passwordHash,
    required this.name,
    required this.major,
    required this.gpa,
    required this.incomeBracket,
    required this.profileImg,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['student_id'],
      schoolId: json['school_id'],
      loginId: json['login_id'],
      passwordHash: json['password_hash'],
      name: json['name'],
      major: json['major'] ?? '',
      gpa: (json['gpa'] as num).toDouble(),
      incomeBracket: json['income_bracket'],
      profileImg: json['profile_img'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'school_id': schoolId,
      'login_id': loginId,
      'password_hash': passwordHash,
      'name': name,
      'major': major,
      'gpa': gpa,
      'income_bracket': incomeBracket,
      'profile_img': profileImg,
    };
  }

  @override
  String toString() {
    return 'Student(studentId: $studentId, schoolId: $schoolId, loginId: $loginId, passwordHash: $passwordHash, name: $name, major: $major, gpa: $gpa, incomeBracket: $incomeBracket, profileImg: $profileImg)';
  }
}

class UserProfile {
  String name, department, studentId, grade;
  double? gpa;           // 선택: 학점 (0.0 ~ 4.5)
  int? incomeBracket;    // 선택: 소득분위 (1 ~ 10)

  UserProfile({
    this.name = '홍길동',
    this.department = '컴퓨터공학과',
    this.studentId = '202220222',
    this.grade = '3학년',
    this.gpa,
    this.incomeBracket,
  });

  factory UserProfile.fromStudent(Student student) {
    return UserProfile(
      name: student.name,
      department: student.major,
      studentId: student.loginId,
      gpa: student.gpa != 0.0 ? student.gpa : null,
      incomeBracket: student.incomeBracket != 0 ? student.incomeBracket : null,
    );
  }

  UserProfile copyWith({
    String? name,
    String? department,
    String? studentId,
    String? grade,
    Object? gpa = _sentinel,
    Object? incomeBracket = _sentinel,
  }) => UserProfile(
    name: name ?? this.name,
    department: department ?? this.department,
    studentId: studentId ?? this.studentId,
    grade: grade ?? this.grade,
    gpa: identical(gpa, _sentinel) ? this.gpa : gpa as double?,
    incomeBracket: identical(incomeBracket, _sentinel)
        ? this.incomeBracket
        : incomeBracket as int?,
  );
}

// nullable 필드를 null로 명시적으로 지울 수 있게 하는 sentinel 값
const Object _sentinel = Object();
