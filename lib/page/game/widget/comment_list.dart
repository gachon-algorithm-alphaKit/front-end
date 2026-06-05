import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/topic_provider.dart';
import 'comment_card.dart';

class CommentList extends ConsumerStatefulWidget {
  final int topicId;
  final bool opinion;
  final bool isActive;
  final bool isMyOpinion;

  const CommentList({super.key, required this.topicId, required this.opinion, required this.isActive, required this.isMyOpinion});

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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

    if (state.isLoading && state.comments.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
    }

    if (state.comments.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
            final currentState = ref.read(topicCommentProvider(_providerKey));
            if (!currentState.isLoading && currentState.hasMore) {
              Future.microtask(() => ref.read(topicCommentProvider(_providerKey).notifier).fetchComments());
            }
          }
        }
        return false;
      },
      child: Builder(
        builder: (context) {
          return CustomScrollView(
            slivers: [
              SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
              SliverPadding(
                padding: EdgeInsets.zero,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index >= state.comments.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple)),
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
                            ref.read(topicCommentProvider(_providerKey).notifier).toggleLike(comment.commentId);
                          },
                          onEdit: (newText) {
                            if (!_checkActiveAndWarn()) return;
                            ref.read(topicCommentProvider(_providerKey).notifier).editComment(comment.commentId, newText);
                          },
                          onDelete: () {
                            if (!_checkActiveAndWarn()) return;
                            ref.read(topicCommentProvider(_providerKey).notifier).removeComment(comment.commentId);
                          },
                        ),
                        if (index < state.comments.length - 1) Divider(height: 1, color: Colors.grey.shade100),
                      ],
                    );
                  }, childCount: state.comments.length + (state.hasMore ? 1 : 0)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text('아직 댓글이 없습니다', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
          if (widget.isMyOpinion && widget.isActive)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('첫 번째 댓글을 남겨보세요', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ),
        ],
      ),
    );
  }
}
