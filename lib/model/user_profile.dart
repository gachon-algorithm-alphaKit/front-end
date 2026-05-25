class UserProfile {
  String name, department, studentId, grade;
  UserProfile({
    this.name = '홍길동',
    this.department = '컴퓨터공학과',
    this.studentId = '202220222',
    this.grade = '3학년',
  });
  UserProfile copyWith({
    String? name,
    String? department,
    String? studentId,
    String? grade,
  }) => UserProfile(
    name: name ?? this.name,
    department: department ?? this.department,
    studentId: studentId ?? this.studentId,
    grade: grade ?? this.grade,
  );
}

// 캠퍼스 길찾기
