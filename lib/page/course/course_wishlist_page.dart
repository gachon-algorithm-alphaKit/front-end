import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/course_service.dart';
import '../../api/wishlist_service.dart';
import '../../model/course_model.dart';
import '../../provider/wishlist_provider.dart';

class CourseWishlistPage extends ConsumerStatefulWidget {
  const CourseWishlistPage({super.key});
  @override
  ConsumerState<CourseWishlistPage> createState() => _CourseWishlistPageState();
}

class _CourseWishlistPageState extends ConsumerState<CourseWishlistPage> {
  List<Course> _wished = [];
  bool _isLoading = true;
  final Set<int> _removingIds = {};

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);
    try {
      final courses = await WishlistService.fetchWishlist();
      // provider state is updated by its own initialization or via toggle.
      // but we can also update it here if needed.
      if (mounted) {
        setState(() {
          _wished = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRemove(int courseId) async {
    if (_removingIds.contains(courseId)) return;

    setState(() {
      _removingIds.add(courseId);
    });

    await ref.read(wishlistProvider.notifier).toggle(courseId);

    if (mounted) {
      setState(() {
        _removingIds.remove(courseId);
        // Also remove from local list to reflect UI
        _wished.removeWhere((c) => c.courseId == courseId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          '찜한 강의 (${_wished.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.amber.shade800,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wished.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('찜한 강의가 없습니다', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                  const SizedBox(height: 6),
                  Text('강의 검색 후 ♥ 버튼을 눌러 찜하세요', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _wished.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = _wished[i];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.amber.shade200, width: 1.2),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: Text(
                        c.courseCode,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800, fontSize: 11),
                      ),
                    ),
                    title: Text(c.courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${CourseService.professorNameFor(c)} | ${c.majorTerm} | ${c.classTimeLabel}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    trailing: _removingIds.contains(c.courseId)
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : GestureDetector(
                            onTap: () => _handleRemove(c.courseId),
                            child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 22),
                          ),
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text(
                        '강의 계획 요약',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      Text(c.description, style: const TextStyle(fontSize: 13, height: 1.5)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
