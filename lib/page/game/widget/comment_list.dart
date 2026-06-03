import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/topic_provider.dart';
import 'comment_card.dart';

class CommentList extends ConsumerStatefulWidget {
  final int topicId;
  final bool opinion;
  final bool isActive;
  final bool isMyOpinion;

  const CommentList({
    super.key,
    required this.topicId,
    required this.opinion,
    required this.isActive,
    required this.isMyOpinion,
  });

  @override
  ConsumerState<CommentList> createState() => _CommentListState();
}

class _CommentListState extends ConsumerState<CommentList> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();

  String get _providerKey => '${widget.topicId}_${widget.opinion}';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(topicCommentProvider(_providerKey).notifier).fetchMore();
    }
  }

  bool _checkActiveAndWarn() {
    if (!widget.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('이전 밸런스 게임에는 참여하실 수 없습니다.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(topicCommentProvider(_providerKey));

    return Column(
      children: [
        // 정렬 토글
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '총 ${state.totalCount}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              _buildSortChip('최신순', 'latest', state.sort),
              const SizedBox(width: 6),
              _buildSortChip('추천순', 'like', state.sort),
            ],
          ),
        ),
        // 댓글 리스트
        Expanded(
          child: state.isLoading && state.comments.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.deepPurple),
                )
              : state.comments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemCount:
                          state.comments.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.comments.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          );
                        }

                        final comment = state.comments[index];
                        return Column(
                          children: [
                            CommentCard(
                              comment: comment,
                              isActive: widget.isActive,
                              onLike: () {
                                if (!_checkActiveAndWarn()) return;
                                ref
                                    .read(topicCommentProvider(_providerKey).notifier)
                                    .toggleLike(comment.commentId);
                              },
                              onEdit: (newText) {
                                if (!_checkActiveAndWarn()) return;
                                ref
                                    .read(topicCommentProvider(_providerKey).notifier)
                                    .editComment(comment.commentId, newText);
                              },
                              onDelete: () {
                                if (!_checkActiveAndWarn()) return;
                                ref
                                    .read(topicCommentProvider(_providerKey).notifier)
                                    .removeComment(comment.commentId);
                              },
                            ),
                            if (index < state.comments.length - 1)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: Colors.grey.shade100,
                              ),
                          ],
                        );
                      },
                    ),
        ),
        // 댓글 입력
        if (widget.isActive && widget.isMyOpinion) _buildCommentInput(state),
      ],
    );
  }

  Widget _buildSortChip(String label, String sortValue, String currentSort) {
    final selected = currentSort == sortValue;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : Colors.grey.shade600,
        ),
      ),
      selected: selected,
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      onSelected: (v) {
        if (v && currentSort != sortValue) {
          ref
              .read(topicCommentProvider(_providerKey).notifier)
              .changeSort(sortValue);
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 40,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            '아직 댓글이 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          if (widget.isMyOpinion && widget.isActive)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '첫 번째 댓글을 남겨보세요!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(TopicCommentState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: '댓글을 입력하세요',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide:
                        BorderSide(color: Colors.deepPurple.shade200),
                  ),
                ),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: state.isSubmitting ? null : _submitComment,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final success = await ref
        .read(topicCommentProvider(_providerKey).notifier)
        .addComment(text);

    if (success) {
      _textController.clear();
      // 스크롤을 맨 위로 (새 댓글이 상단에 추가되므로)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
}
