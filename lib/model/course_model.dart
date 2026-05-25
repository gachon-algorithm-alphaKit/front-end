enum SearchType { name, professor, content }

class Course {
  final String id, name, professor, department, credit, classTime;
  final String? syllabusUrl, planSummary;
  const Course({
    required this.id,
    required this.name,
    required this.professor,
    required this.department,
    required this.credit,
    required this.classTime,
    this.syllabusUrl,
    this.planSummary,
  });
}

// 스터디룸
