import 'package:flutter_riverpod/legacy.dart';
import '../model/lost_found_model.dart';
import '../api/lost_found_service.dart';

// ── 댓글 리스트 상태 ──────────────────────────────────────────
class CommentListState {
  final List<Comment> comments;
  final bool isLoading;
  final bool isSubmitting;

  const CommentListState({
    this.comments = const [],
    this.isLoading = false,
    this.isSubmitting = false,
  });

  CommentListState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    bool? isSubmitting,
  }) {
    return CommentListState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

// ── Family Notifier — 게시글(itemId)별 독립적인 댓글 상태 관리 ──
class CommentListNotifier extends StateNotifier<CommentListState> {
  final int arg;

  CommentListNotifier(this.arg) : super(const CommentListState(isLoading: true)) {
    // Provider가 처음 읽힐 때 자동으로 댓글을 불러옴
    Future.microtask(() => fetchComments());
  }

  /// 서버에서 댓글 목록 조회
  Future<void> fetchComments() async {
    state = state.copyWith(isLoading: true);
    try {
      final comments = await LostFoundService.getComments(arg);
      state = state.copyWith(comments: comments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 댓글 작성 — 성공 시 리스트 맨 아래에 추가 (서버 정렬: 오래된 순)
  Future<bool> addComment(String text, bool isAnonymous) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final newComment = await LostFoundService.createComment(
        itemId: arg,
        comment: text,
        isAnonymous: isAnonymous,
      );
      if (newComment != null) {
        state = state.copyWith(
          comments: [...state.comments, newComment],
          isSubmitting: false,
        );
        return true;
      }
    } catch (e) {
      // 실패 시 아무것도 하지 않음
    }
    state = state.copyWith(isSubmitting: false);
    return false;
  }

  /// 댓글 수정 — 성공 시 로컬에서 해당 댓글 텍스트만 교체
  Future<bool> editComment(int commentId, String newText) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final success = await LostFoundService.updateComment(
        commentId: commentId,
        comment: newText,
      );
      if (success) {
        final updated = state.comments.map((c) {
          return c.commentId == commentId ? c.copyWith(comment: newText) : c;
        }).toList();
        state = state.copyWith(comments: updated, isSubmitting: false);
        return true;
      }
    } catch (e) {
      // 실패 시 아무것도 하지 않음
    }
    state = state.copyWith(isSubmitting: false);
    return false;
  }

  /// 댓글 삭제 — 성공 시 로컬에서 해당 댓글 제거
  Future<bool> removeComment(int commentId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final success = await LostFoundService.deleteComment(commentId);
      if (success) {
        final updated = state.comments
            .where((c) => c.commentId != commentId)
            .toList();
        state = state.copyWith(comments: updated, isSubmitting: false);
        return true;
      }
    } catch (e) {
      // 실패 시 아무것도 하지 않음
    }
    state = state.copyWith(isSubmitting: false);
    return false;
  }
}

final commentListProvider =
    StateNotifierProvider.family<CommentListNotifier, CommentListState, int>(
  (ref, arg) => CommentListNotifier(arg),
);
