import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/lost_found_model.dart';
import '../../provider/my_lost_items_provider.dart';
import 'lost_found_post_detail_page.dart';

class LostFoundHistoryPage extends ConsumerStatefulWidget {
  const LostFoundHistoryPage({super.key});
  @override
  ConsumerState<LostFoundHistoryPage> createState() => _LostFoundHistoryPageState();
}

class _LostFoundHistoryPageState extends ConsumerState<LostFoundHistoryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 로드되었으므로 fetchInitialData 호출 안 해도 됨, 다만 원하면 ref.read(myLostItemsProvider.notifier).fetchInitialData(); 할 수도 있음
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(myLostItemsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openDetail(LostFoundPost post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LostFoundPostDetailPage(
          post: post,
          onEdit: (updated) {
            ref.read(myLostItemsProvider.notifier).updatePostOptimistic(updated);
          },
          onDelete: (id) {
            ref.read(myLostItemsProvider.notifier).removePostOptimistic(id);
            Navigator.pop(context); // 상세 페이지 닫기
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myLostItemsProvider);
    final posts = state.items;
    final totalCount = ref.watch(myLostItemsCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          '작성 내역 ($totalCount건)',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: state.isLoading && posts.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 72,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '작성한 신고 내역이 없습니다',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '분실물을 신고하면 여기에 표시됩니다',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length + (state.isFetchingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i == posts.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(color: Colors.redAccent),
                        ),
                      );
                    }
                    final post = posts[i]; 
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _openDetail(post),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      post.itemName,
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
                                      color: post.status ? Colors.grey.shade100 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      post.statusText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: post.status ? Colors.grey.shade600 : Colors.orange.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                post.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    post.location,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    Icons.access_time,
                                    size: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    post.date,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
