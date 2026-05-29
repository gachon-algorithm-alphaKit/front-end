import 'package:alpha_kit/api/lost_found_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/lost_found_model.dart';
import '../../provider/comment_provider.dart';
import 'lost_found_write_page.dart';

class LostFoundPostDetailPage extends ConsumerStatefulWidget {
  final LostFoundPost post;
  final ValueChanged<LostFoundPost> onEdit;
  final ValueChanged<String> onDelete;
  const LostFoundPostDetailPage({super.key, required this.post, required this.onEdit, required this.onDelete});
  @override
  ConsumerState<LostFoundPostDetailPage> createState() => _LostFoundPostDetailPageState();
}

class _LostFoundPostDetailPageState extends ConsumerState<LostFoundPostDetailPage> {
  late LostFoundPost _post;
  final _commentCtrl = TextEditingController();
  bool _isAnonymousComment = true;

  // 인라인 수정 상태
  int? _editingCommentId;
  final _editCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  void _goEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LostFoundWritePage(
          initialPost: _post,
          onSubmit: (updated) {
            setState(() => _post = updated);
            widget.onEdit(updated);
          },
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('신고 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('이 신고 내역을 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소', style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx); // 다이얼로그 닫기
              widget.onDelete(_post.id); // 목록에서 제거 + 상세 페이지 닫기
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.redAccent),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
      ],
    ),
  );

  // ── 댓글 작성 ──────────────────────────────────────────────
  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final notifier = ref.read(commentListProvider(_post.itemId).notifier);
    final success = await notifier.addComment(text, _isAnonymousComment);
    if (success && mounted) {
      _commentCtrl.clear();
    }
  }

  // ── 댓글 수정 시작 ─────────────────────────────────────────
  void _startEditComment(Comment c) {
    setState(() {
      _editingCommentId = c.commentId;
      _editCtrl.text = c.comment;
    });
  }

  // ── 댓글 수정 제출 ─────────────────────────────────────────
  Future<void> _submitEditComment(int commentId) async {
    final text = _editCtrl.text.trim();
    if (text.isEmpty) return;

    final notifier = ref.read(commentListProvider(_post.itemId).notifier);
    final success = await notifier.editComment(commentId, text);
    if (success && mounted) {
      setState(() => _editingCommentId = null);
    }
  }

  // ── 댓글 삭제 확인 ─────────────────────────────────────────
  void _confirmDeleteComment(int commentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('댓글 삭제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소', style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(commentListProvider(_post.itemId).notifier).removeComment(commentId);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // ── 댓글 카드 위젯 ─────────────────────────────────────────
  Widget _buildCommentCard(Comment c) {
    final isEditing = _editingCommentId == c.commentId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더: 작성자 + 뱃지 + 시간 + 메뉴 ──
          Row(
            children: [
              // 작성자 아이콘
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: c.isPostOwner ? Colors.red.shade50 : Colors.blue.shade50, shape: BoxShape.circle),
                child: Icon(c.isAnonymous ? Icons.person_outline : Icons.person, size: 16, color: c.isPostOwner ? Colors.redAccent : Colors.blue.shade400),
              ),
              const SizedBox(width: 8),
              // 작성자 이름
              Text(
                c.writer,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              // 글쓴이 뱃지
              if (c.isPostOwner) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text(
                    '글쓴이',
                    style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const Spacer(),
              // 시간
              Text(c.timeAgo, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              // ⋮ 메뉴 (내가 쓴 댓글에만)
              if (c.isWriter) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (value) {
                      if (value == 'edit') _startEditComment(c);
                      if (value == 'delete') _confirmDeleteComment(c.commentId);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('수정', style: TextStyle(fontSize: 13)),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('삭제', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // ── 본문 or 수정 입력창 ──
          if (isEditing)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _editCtrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: () => _submitEditComment(c.commentId),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('저장', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  height: 36,
                  child: TextButton(
                    onPressed: () => setState(() => _editingCommentId = null),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: Text('취소', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ),
                ),
              ],
            )
          else
            Text(c.comment, style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMine = _post.isMine;
    final commentState = ref.watch(commentListProvider(_post.itemId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '신고 상세',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: isMine
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: '수정',
                  onPressed: _goEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  tooltip: '삭제',
                  onPressed: _confirmDelete,
                ),
              ]
            : [],
      ),
      body: Column(
        children: [
          // ── 스크롤 가능 영역: 게시글 정보 + 댓글 목록 ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 상태 배지 + 제목 카드
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _post.status ? Colors.grey.shade100 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _post.status ? Colors.grey.shade300 : Colors.orange.shade200),
                                    ),
                                    child: Text(
                                      _post.statusText,
                                      style: TextStyle(fontSize: 12, color: _post.status ? Colors.grey.shade600 : Colors.orange.shade700, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (_post.isAnonymous) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.visibility_off_outlined, size: 12, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            '익명',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(_post.date, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: const Icon(Icons.inventory_2_rounded, color: Colors.redAccent, size: 36),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _post.itemName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 첨부 이미지
                  if (_post.imagePath != null) ...[
                    const SizedBox(height: 0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        '${LostFoundService.baseUrl}${_post.imagePath}',
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 80,
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                          child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 36)),
                        ),
                      ),
                    ),
                  ],
                  // 세부 정보 카드
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        children: [
                          _detailRow(Icons.description_outlined, '특징', _post.description),
                          _detailRow(Icons.location_on_outlined, '분실 장소', _post.location),
                          if (_post.isAnonymous) _detailRow(Icons.visibility_off_outlined, '공개 여부', '익명 게시글'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 💬 댓글 섹션
                  // ══════════════════════════════════════════
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Text(
                        '댓글 (${commentState.comments.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 댓글 목록
                  if (commentState.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(color: Colors.redAccent),
                    )
                  else if (commentState.comments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 36, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('아직 댓글이 없습니다', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Text('첫 번째 댓글을 남겨보세요!', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                        ],
                      ),
                    )
                  else
                    ...commentState.comments.map(_buildCommentCard),

                  const SizedBox(height: 80), // 하단 입력창 공간 확보
                ],
              ),
            ),
          ),

          // ── 하단 고정 댓글 입력창 ───────────────────────────
          Container(
            padding: EdgeInsets.only(left: 12, right: 12, top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                // 익명 체크박스
                GestureDetector(
                  onTap: () => setState(() => _isAnonymousComment = !_isAnonymousComment),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(color: _isAnonymousComment ? Colors.redAccent.withValues(alpha: 0.1) : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isAnonymousComment ? Icons.check_box : Icons.check_box_outline_blank, size: 16, color: _isAnonymousComment ? Colors.redAccent : Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '익명',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _isAnonymousComment ? Colors.redAccent : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 입력 필드
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: '댓글을 입력하세요...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    onChanged: (_) => setState(() {}), // 전송 버튼 활성화/비활성화 반영
                  ),
                ),
                const SizedBox(width: 8),
                // 전송 버튼
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _commentCtrl,
                  builder: (_, value, _) {
                    final canSend = value.text.trim().isNotEmpty && !commentState.isSubmitting;
                    return SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        onPressed: canSend ? _submitComment : null,
                        icon: commentState.isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
                            : Icon(Icons.send_rounded, size: 20, color: canSend ? Colors.redAccent : Colors.grey.shade400),
                        padding: EdgeInsets.zero,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
