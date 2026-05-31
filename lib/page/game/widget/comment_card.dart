import 'package:flutter/material.dart';
import '../../../model/topic_model.dart';

class CommentCard extends StatelessWidget {
  final TopicComment comment;
  final bool isActive;
  final VoidCallback? onLike;
  final void Function(String newText)? onEdit;
  final VoidCallback? onDelete;

  const CommentCard({
    super.key,
    required this.comment,
    this.isActive = true,
    this.onLike,
    this.onEdit,
    this.onDelete,
  });

  // 번호 기반 아바타 색상
  static final _avatarColors = [
    Colors.deepPurple.shade300,
    Colors.indigo.shade300,
    Colors.blue.shade300,
    Colors.teal.shade300,
    Colors.green.shade300,
    Colors.amber.shade400,
    Colors.orange.shade300,
    Colors.pink.shade300,
  ];

  Color _getAvatarColor() {
    // writer에서 숫자 추출하여 색상 결정
    final numMatch = RegExp(r'\d+').firstMatch(comment.writer);
    if (numMatch != null) {
      final num = int.tryParse(numMatch.group(0)!) ?? 0;
      return _avatarColors[num % _avatarColors.length];
    }
    return _avatarColors[comment.commentId % _avatarColors.length];
  }

  String _getAvatarText() {
    final numMatch = RegExp(r'\d+').firstMatch(comment.writer);
    if (numMatch != null) {
      return numMatch.group(0)!;
    }
    return comment.writer.isNotEmpty ? comment.writer[0] : '?';
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아바타
          CircleAvatar(
            radius: 16,
            backgroundColor: avatarColor,
            child: Text(
              _getAvatarText(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 본문
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 작성자 + 시간
                Row(
                  children: [
                    Text(
                      comment.writer,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: comment.isWriter
                            ? Colors.deepPurple.shade700
                            : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 댓글 텍스트
                Text(
                  comment.comment,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                // 하단 액션 행
                Row(
                  children: [
                    // 좋아요 버튼
                    InkWell(
                      onTap: onLike,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              comment.isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: comment.isLiked
                                  ? Colors.red.shade400
                                  : Colors.grey.shade400,
                            ),
                            if (comment.likeCount > 0) ...[
                              const SizedBox(width: 2),
                              Text(
                                '${comment.likeCount}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: comment.isLiked
                                      ? Colors.red.shade400
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 본인 댓글: 수정/삭제
                    if (comment.isWriter && isActive) ...[
                      _actionButton(
                        Icons.edit_rounded,
                        '수정',
                        () => _showEditDialog(context),
                      ),
                      const SizedBox(width: 8),
                      _actionButton(
                        Icons.delete_outline_rounded,
                        '삭제',
                        () => _showDeleteDialog(context),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: comment.comment);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('댓글 수정', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '댓글을 수정하세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onEdit?.call(controller.text);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('댓글 삭제', style: TextStyle(fontSize: 16)),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
