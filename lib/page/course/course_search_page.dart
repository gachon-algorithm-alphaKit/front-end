import 'dart:async';
import 'package:flutter/material.dart';

import '../../api/auth_api.dart';
import '../../api/course_service.dart';
import '../../api/wishlist_service.dart';
import '../../model/course_model.dart';
import '../../state/app_state.dart';
import '../login/login_page.dart';
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
  Timer? _debounce;
  final Set<int> _togglingIds = {}; // 현재 토글 요청 중인 강의 ID (중복 클릭 방지)

  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initWishlist();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _initWishlist() async {
    await WishlistService.fetchWishlistIds();
    if (mounted) setState(() {});
  }

  /// 낙관적 업데이트 기반 찜 토글
  Future<void> _handleToggle(int courseId) async {
    if (_togglingIds.contains(courseId)) return; // 이미 처리 중

    final wasWished = wishlistCourseIds.contains(courseId);

    // 1) 낙관적 업데이트: UI 즉시 변경
    setState(() {
      _togglingIds.add(courseId);
      if (wasWished) {
        wishlistCourseIds.remove(courseId);
      } else {
        wishlistCourseIds.add(courseId);
      }
    });

    // 2) 서버 요청
    final result = await WishlistService.toggleWishlist(courseId);

    // 3) 결과 처리
    setState(() {
      _togglingIds.remove(courseId);
    });

    if (!result.success) {
      // 롤백
      setState(() {
        if (wasWished) {
          wishlistCourseIds.add(courseId);
        } else {
          wishlistCourseIds.remove(courseId);
        }
      });

      if (!mounted) return;

      if (result.unauthorized) {
        await AuthApi.logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage(sessionExpired: true)),
          (route) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red.shade400),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.amber.shade800,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search({bool isLoadMore = false}) async {
    if (_ctrl.text.trim().isEmpty) return;
    
    if (isLoadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _searched = true;
        _currentPage = 1;
        _hasMore = true;
        _results = [];
      });
    }

    try {
      final pageToLoad = isLoadMore ? _currentPage + 1 : 1;
      final r = await CourseService.search(
        _ctrl.text.trim(),
        _type,
        _isChoseong,
        page: pageToLoad,
        limit: 20,
      );
      
      setState(() {
        if (isLoadMore) {
          _currentPage = pageToLoad;
          _results.addAll(r);
          _hasMore = r.length == 20;
        } else {
          _results = r;
          _hasMore = r.length == 20;
        }
      });
    } finally {
      setState(() {
        if (isLoadMore) {
          _isLoadingMore = false;
        } else {
          _isLoading = false;
        }
      });
    }
  }

  void _loadMore() {
    _search(isLoadMore: true);
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
          TextButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CourseWishlistPage(),
                ),
              );
              setState(() {});
            },
            icon: Icon(
              wishlistCourseIds.isNotEmpty
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              '찜 목록${wishlistCourseIds.isNotEmpty ? ' (${wishlistCourseIds.length})' : ''}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
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
                    _ctrl.clear();
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
                        onChanged: (_) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 300), () {
                            _search();
                          });
                          setState(() {});
                        },
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
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length + (_isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == _results.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _courseCard(_results[i]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _courseCard(Course c) {
    final isWished = wishlistCourseIds.contains(c.courseId);
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${CourseService.professorNameFor(c)} | ${c.majorTerm} | ${c.classTimeLabel}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: _togglingIds.contains(c.courseId)
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : GestureDetector(
                onTap: () => _handleToggle(c.courseId),
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
  }
}
