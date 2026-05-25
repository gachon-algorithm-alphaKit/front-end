class Scholarship {
  final int scholarshipId;
  final int schoolId;
  final String name;
  final int amount;
  final double requiredGpa;
  final int requiredIncomeBracket;
  final bool duplicateAllowed;
  final int score;
  final String? organization;
  final String? deadline;
  final String? detail;
  final String? applyUrl;
  final String? targetGrade;
  final String? targetDepartment;

  const Scholarship({
    required this.scholarshipId,
    required this.schoolId,
    required this.name,
    required this.amount,
    required this.requiredGpa,
    required this.requiredIncomeBracket,
    required this.duplicateAllowed,
    this.score = 0,
    this.organization,
    this.deadline,
    this.detail,
    this.applyUrl,
    this.targetGrade,
    this.targetDepartment,
  });

  factory Scholarship.fromJson(Map<String, dynamic> json) {
    return Scholarship(
      scholarshipId: json['scholarship_id'],
      schoolId: json['school_id'],
      name: json['name'],
      amount: json['amount'],
      requiredGpa: (json['required_gpa'] as num).toDouble(),
      requiredIncomeBracket: json['required_income_bracket'],
      duplicateAllowed: _boolFromJson(json['duplicate_allowed']),
      score: json['score'] ?? 0,
      organization: json['organization'],
      deadline: json['deadline'],
      detail: json['detail'],
      applyUrl: json['apply_url'],
      targetGrade: json['target_grade'],
      targetDepartment: json['target_department'],
    );
  }

  String get id => scholarshipId.toString();
  String get title => name;
  String get amountLabel {
    if (amount >= 10000) {
      final tenThousandWon = amount ~/ 10000;
      return '$tenThousandWon만원';
    }
    return '$amount원';
  }

  Scholarship copyWith({int? score}) {
    return Scholarship(
      scholarshipId: scholarshipId,
      schoolId: schoolId,
      name: name,
      amount: amount,
      requiredGpa: requiredGpa,
      requiredIncomeBracket: requiredIncomeBracket,
      duplicateAllowed: duplicateAllowed,
      score: score ?? this.score,
      organization: organization,
      deadline: deadline,
      detail: detail,
      applyUrl: applyUrl,
      targetGrade: targetGrade,
      targetDepartment: targetDepartment,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scholarship_id': scholarshipId,
      'school_id': schoolId,
      'name': name,
      'amount': amount,
      'required_gpa': requiredGpa,
      'required_income_bracket': requiredIncomeBracket,
      'duplicate_allowed': duplicateAllowed,
    };
  }

  @override
  String toString() {
    return 'Scholarship(scholarshipId: $scholarshipId, schoolId: $schoolId, name: $name, amount: $amount, requiredGpa: $requiredGpa, requiredIncomeBracket: $requiredIncomeBracket, duplicateAllowed: $duplicateAllowed)';
  }

  static bool _boolFromJson(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value == 1;
    }
    return false;
  }
}

class ScholarshipHistory {
  final int historyId;
  final int studentId;
  final int scholarshipId;
  final String semester;

  const ScholarshipHistory({
    required this.historyId,
    required this.studentId,
    required this.scholarshipId,
    required this.semester,
  });

  factory ScholarshipHistory.fromJson(Map<String, dynamic> json) {
    return ScholarshipHistory(
      historyId: json['history_id'],
      studentId: json['student_id'],
      scholarshipId: json['scholarship_id'],
      semester: json['semester'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'history_id': historyId,
      'student_id': studentId,
      'scholarship_id': scholarshipId,
      'semester': semester,
    };
  }

  @override
  String toString() {
    return 'ScholarshipHistory(historyId: $historyId, studentId: $studentId, scholarshipId: $scholarshipId, semester: $semester)';
  }
}

class ScholarshipFilter {
  final String? targetGrade;
  final String? targetDepartment;
  final bool hideExpired;

  const ScholarshipFilter({
    this.targetGrade,
    this.targetDepartment,
    required this.hideExpired,
  });
}

List<Scholarship> applyFilter(
  List<Scholarship> allScholarships,
  ScholarshipFilter filter,
) {
  return allScholarships.where((scholarship) {
    if (filter.hideExpired && scholarship.deadline != null) {
      final deadlineDate = DateTime.tryParse(scholarship.deadline!);
      if (deadlineDate != null && deadlineDate.isBefore(DateTime.now())) {
        return false;
      }
    }

    if (filter.targetGrade != null && scholarship.targetGrade != null) {
      if (scholarship.targetGrade != filter.targetGrade) {
        return false;
      }
    }

    if (filter.targetDepartment != null &&
        scholarship.targetDepartment != null) {
      if (!scholarship.targetDepartment!.contains(filter.targetDepartment!)) {
        return false;
      }
    }

    return true;
  }).toList();
}
