import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/lost_found_service.dart';
import '../../model/lost_found_model.dart';
import '../../provider/my_lost_items_provider.dart';
import 'lost_found_history_page.dart';
import 'lost_found_post_detail_page.dart';
import 'lost_found_write_page.dart';

class LostFoundPage extends ConsumerStatefulWidget {
  const LostFoundPage({super.key});
  @override
  ConsumerState<LostFoundPage> createState() => _LostFoundPageState();
}

class _LostFoundPageState extends ConsumerState<LostFoundPage> {
  final _ctrl = TextEditingController();
  final bool _isFuzzy = false;
  List<LostItem> _results = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 10;
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  List<String> _suggestions = []; // Holds name suggestion results

  @override
  void initState() {
    super.initState();
    _loadAll();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _page = 1;
      _hasMore = true;
    });
    final r = await LostFoundService.search('', false, page: _page, limit: _limit);
    setState(() {
      _results = r;
      _isLoading = false;
      if (r.length < _limit) _hasMore = false;
    });
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _page = 1;
      _hasMore = true;
    });
    try {
      final r = await LostFoundService.search(_ctrl.text.trim(), _isFuzzy, page: _page, limit: _limit);
      setState(() {
        _results = r;
        if (r.length < _limit) _hasMore = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore || _isLoading) return;
    setState(() => _isFetchingMore = true);

    _page++;
    final r = await LostFoundService.search(
      _ctrl.text.trim(), 
      _isFuzzy, 
      page: _page, 
      limit: _limit
    );

    setState(() {
      if (r.isEmpty || r.length < _limit) {
        _hasMore = false;
      }
      _results.addAll(r);
      _isFetchingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 진입하자마자 내 신고 내역 조회를 트리거하여 Count를 가져오도록 함
    ref.watch(myLostItemsProvider);
    final myPostsCount = ref.watch(myLostItemsCountProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '분실물 통합 센터',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            label: Text(
              '신고 내역($myPostsCount)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LostFoundHistoryPage(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LostFoundWritePage(
                onSubmit: (post) {
                  ref.read(myLostItemsProvider.notifier).addPostOptimistic(post);
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          // 검색 영역
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: _ctrl,
                            decoration: InputDecoration(
                              hintText: '물건 이름이나 특징을 입력하세요 (예: 검정 지갑)',
                              prefixIcon: const Icon(Icons.search),
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
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
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
                                        _loadAll();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) => _search(),
                            onChanged: (val) async {
                              // Cancel previous debounce
                              if (_debounce?.isActive ?? false) _debounce!.cancel();
                              // Fetch suggestions after short delay
                              _debounce = Timer(const Duration(milliseconds: 300), () async {
                                try {
                                  final suggestions = await LostFoundService.nameSuggestions(_ctrl.text.trim());
                                  setState(() {
                                    _suggestions = suggestions.take(5).toList();
                                  });
                                } catch (e) {
                                  // ignore errors
                                }
                                _search();
                              });
                            },
                          ),
                          if (_suggestions.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _suggestions.length,
                                itemBuilder: (context, idx) {
                                  final sug = _suggestions[idx];
                                  return ListTile(
                                    dense: true,
                                    title: Text(sug),
                                    onTap: () {
                                      _ctrl.text = sug;
                                      setState(() => _suggestions = []);
                                      _search();
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _search,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size(52, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.search),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 결과
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
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
                          _ctrl.text.isEmpty
                              ? '검색 결과가 없습니다'
                              : "'${_ctrl.text}'에 대한 검색 결과가 없습니다\n단어 철자가 정확한지 확인해보세요",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500, height: 1.5),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length + (_isFetchingMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == _results.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: Colors.redAccent),
                          ),
                        );
                      }
                      return _lostItemCard(_results[i]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _lostItemCard(LostItem item) {
    final isAvailable = !item.status; // false = 보관중(isAvailable true), true = 주인 찾음(isAvailable false)
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LostFoundPostDetailPage(
              post: item,
              onEdit: (updated) {
                if (mounted) {
                  setState(() {
                    final idx = _results.indexWhere((e) => e.itemId == updated.itemId);
                    if (idx != -1) _results[idx] = updated;
                  });
                }
              },
              onDelete: (id) {
                if (mounted) {
                  setState(() {
                    _results.removeWhere((e) => e.id == id);
                  });
                }
              },
            ),
          ),
        );
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? Colors.blue.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: isAvailable
                          ? Colors.blue.shade700
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            if (item.imagePath != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  '${LostFoundService.baseUrl}${item.imagePath}',
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  item.location,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  item.foundDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                if (isAvailable)
                  TextButton(
                    onPressed: () async {
                      // TODO: LostFoundService.claimItem → 분실물 수령 신청
                      await LostFoundService.claimItem(item.itemId);
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.itemName} 수령 신청이 완료되었습니다.'),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    child: const Text(
                      '수령 신청',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
