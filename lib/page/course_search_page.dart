import 'package:flutter/material.dart';

import '../api/course_service.dart';
import '../model/course_model.dart';
import '../state/app_state.dart';
import 'course_wishlist_page.dart';

class CourseSearchPage extends StatefulWidget {
  const CourseSearchPage({super.key});
  @override
  State<CourseSearchPage> createState() => _CourseSearchPageState();
}

class _CourseSearchPageState extends State<CourseSearchPage> {
  SearchType _type = SearchType.name;
  final bool _isChoseong = false;
  final _ctrl = TextEditingController();
  List<Course> _results = [];
  bool _isLoading = false, _searched = false;

  Future<void> _search() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _searched = true;
    });
    try {
      // TODO: CourseService.search → 백엔드 Trie + Rabin-Karp + 초성 검색
      final r = await CourseService.search(
        _ctrl.text.trim(),
        _type,
        _isChoseong,
      );
      setState(() => _results = r);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '강의 계획서 검색',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.amber.shade800,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                tooltip: '찜 목록',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseWishlistPage(
                        wishlistIds: wishlistCourseIds,
                        onToggle: (id) => setState(() {
                          if (wishlistCourseIds.contains(id)) {
                            wishlistCourseIds.remove(id);
                          } else {
                            wishlistCourseIds.add(id);
                          }
                        }),
                      ),
                    ),
                  );
                  setState(() {});
                },
              ),
              if (wishlistCourseIds.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${wishlistCourseIds.length}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 영역
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // 검색 타입 탭
                SegmentedButton<SearchType>(
                  segments: const [
                    ButtonSegment(
                      value: SearchType.name,
                      label: Text('강의명'),
                      icon: Icon(Icons.book_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: SearchType.professor,
                      label: Text('교수명'),
                      icon: Icon(Icons.person_outline, size: 16),
                    ),
                    ButtonSegment(
                      value: SearchType.content,
                      label: Text('강의내용'),
                      icon: Icon(Icons.description_outlined, size: 16),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() {
                    _type = s.first;
                    _results = [];
                    _searched = false;
                  }),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? Colors.amber.shade800
                          : null,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? Colors.white
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: InputDecoration(
                          hintText: _type == SearchType.name
                              ? '강의명 또는 초성 입력 (예: ㅈㄹㄱㅈ)'
                              : _type == SearchType.professor
                              ? '교수명 입력'
                              : '강의 내용 키워드 입력',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.amber.shade800,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          suffixIcon: _ctrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _ctrl.clear();
                                    setState(() {
                                      _results = [];
                                      _searched = false;
                                    });
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _search(),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _search,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        minimumSize: const Size(52, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.search),
                    ),
                  ],
                ), // Row 닫기
              ],
            ), // Column 닫기
          ), // Container 닫기
          // 결과
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_searched
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '강의명, 교수명, 또는 강의내용을 검색하세요',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '검색 결과가 없습니다',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _courseCard(_results[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _courseCard(Course c) {
    final isWished = wishlistCourseIds.contains(c.id);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            c.credit,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade800,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          c.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${c.professor} | ${c.department} | ${c.classTime}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: GestureDetector(
          onTap: () => setState(() {
            if (isWished) {
              wishlistCourseIds.remove(c.id);
            } else {
              wishlistCourseIds.add(c.id);
            }
          }),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isWished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(isWished),
              color: isWished ? Colors.redAccent : Colors.grey.shade400,
              size: 22,
            ),
          ),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (c.planSummary != null) ...[
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
              c.planSummary!,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
          // TODO: c.syllabusUrl → 강의계획서 PDF 열기
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 2-B. 강의 계획서 찜 목록 페이지
// ══════════════════════════════════════════════════════════════
