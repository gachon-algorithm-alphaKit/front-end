import 'package:flutter/material.dart';

import '../model/lost_found_model.dart';
import 'lost_found_post_detail_page.dart';

class LostFoundHistoryPage extends StatefulWidget {
  final List<LostFoundPost> posts;
  const LostFoundHistoryPage({super.key, required this.posts});
  @override
  State<LostFoundHistoryPage> createState() => _LostFoundHistoryPageState();
}

class _LostFoundHistoryPageState extends State<LostFoundHistoryPage> {
  // 전역 myPosts 와 동기화: widget.posts 는 동일 참조이므로 setState만으로 갱신됨

  void _openDetail(LostFoundPost post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LostFoundPostDetailPage(
          post: post,
          onEdit: (updated) {
            final idx = widget.posts.indexWhere((p) => p.id == updated.id);
            if (idx != -1) setState(() => widget.posts[idx] = updated);
          },
          onDelete: (id) {
            setState(() => widget.posts.removeWhere((p) => p.id == id));
            Navigator.pop(context); // 상세 페이지 닫기
          },
        ),
      ),
    );
    // 상세에서 돌아올 때 목록 갱신
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          '작성 내역 (${posts.length}건)',
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
      body: posts.isEmpty
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
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final post = posts[posts.length - 1 - i]; // 최신순
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
                                child: Icon(
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
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '접수완료',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
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
                              if (post.contact.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.phone_outlined,
                                  size: 13,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  post.contact,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
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

// ══════════════════════════════════════════════════════════════
// 4-D. 분실물 신고 상세 페이지 (수정 / 삭제)
// ══════════════════════════════════════════════════════════════
