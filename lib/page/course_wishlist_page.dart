import 'package:flutter/material.dart';

import '../api/course_service.dart';
import '../model/course_model.dart';

class CourseWishlistPage extends StatefulWidget {
  final Set<int> wishlistIds;
  final ValueChanged<int> onToggle;
  const CourseWishlistPage({
    super.key,
    required this.wishlistIds,
    required this.onToggle,
  });
  @override
  State<CourseWishlistPage> createState() => _CourseWishlistPageState();
}

class _CourseWishlistPageState extends State<CourseWishlistPage> {
  // 모든 강의 목록에서 찜한 것만 필터
  List<Course> get _wished => CourseService.allCourses
      .where((c) => widget.wishlistIds.contains(c.courseId))
      .toList();

  void _toggle(int id) {
    widget.onToggle(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final wished = _wished;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          '찜한 강의 (${wished.length})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.amber.shade800,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: wished.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '찜한 강의가 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '강의 검색 후 ♥ 버튼을 눌러 찜하세요',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: wished.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = wished[i];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.amber.shade200, width: 1.2),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        c.courseCode,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    title: Text(
                      c.courseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${CourseService.professorNameFor(c)} | ${c.majorTerm} | ${c.classTimeLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: () => _toggle(c.courseId),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                    ),
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text(
                        '강의 계획 요약',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.description,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 3. 스터디룸 예약 페이지
// ══════════════════════════════════════════════════════════════
