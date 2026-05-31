import 'package:flutter_riverpod/legacy.dart';
import '../model/topic_model.dart';
import '../api/topic_api_service.dart';
import '../api/topic_cache_service.dart';

// ══════════════════════════════════════════════════════════════
// 1. 활성 토픽 상태
// ══════════════════════════════════════════════════════════════

class ActiveTopicState {
  final Topic? topic;
  final VoteStat? voteStat;
  final bool isLoading;
  final String? error;

  const ActiveTopicState({
    this.topic,
    this.voteStat,
    this.isLoading = false,
    this.error,
  });

  ActiveTopicState copyWith({
    Topic? topic,
    VoteStat? voteStat,
    bool? isLoading,
    String? error,
    bool clearTopic = false,
    bool clearError = false,
  }) {
    return ActiveTopicState(
      topic: clearTopic ? null : (topic ?? this.topic),
      voteStat: voteStat ?? this.voteStat,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ActiveTopicNotifier extends StateNotifier<ActiveTopicState> {
  ActiveTopicNotifier() : super(const ActiveTopicState(isLoading: true)) {
    Future.microtask(() => fetch());
  }

  /// 활성 토픽 + 투표 통계 조회
  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final topic = await TopicApiService.fetchActiveTopic();
      if (topic != null) {
        final stat = await TopicApiService.fetchVoteStat(topic.topicId);
        state = state.copyWith(
          topic: topic,
          voteStat: stat,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, clearTopic: true);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 투표
  Future<bool> vote(bool opinion, {bool confirmDelete = false}) async {
    final topic = state.topic;
    if (topic == null) return false;

    final result = await TopicApiService.vote(
      topic.topicId,
      opinion,
      confirmDelete: confirmDelete,
    );
    if (result == null) return false;

    if (result['confirm_required'] == true) {
      return false; // UI에서 확인 다이얼로그 표시 필요
    }

    // 투표 성공 → 상태 갱신
    final newTopic = topic.copyWith(
      myVote: opinion,
      totalVoteCount: topic.totalVoteCount + (topic.hasVoted ? 0 : 1),
    );
    final stat = await TopicApiService.fetchVoteStat(topic.topicId);
    state = state.copyWith(topic: newTopic, voteStat: stat);
    return true;
  }

  /// 투표 통계만 갱신 (폴링용)
  Future<void> refreshStat() async {
    final topic = state.topic;
    if (topic == null) return;
    final stat = await TopicApiService.fetchVoteStat(topic.topicId);
    if (stat != null) {
      state = state.copyWith(voteStat: stat);
    }
  }
}

final activeTopicProvider =
    StateNotifierProvider<ActiveTopicNotifier, ActiveTopicState>(
  (ref) => ActiveTopicNotifier(),
);

// ══════════════════════════════════════════════════════════════
// 2. 토픽 리스트 상태 (지난 토픽)
// ══════════════════════════════════════════════════════════════

class TopicListState {
  final List<Topic> topics;
  final bool isLoading;
  final bool hasMore;
  final int? nextCursor;

  const TopicListState({
    this.topics = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.nextCursor,
  });

  TopicListState copyWith({
    List<Topic>? topics,
    bool? isLoading,
    bool? hasMore,
    int? nextCursor,
    bool clearCursor = false,
  }) {
    return TopicListState(
      topics: topics ?? this.topics,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    );
  }
}

class TopicListNotifier extends StateNotifier<TopicListState> {
  TopicListNotifier() : super(const TopicListState(isLoading: true)) {
    Future.microtask(() => fetch());
  }

  /// 첫 페이지 조회
  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, clearCursor: true);
    try {
      // 캐시에서 먼저 로드
      final cached = await TopicCacheService.getCachedTopics();
      if (cached.isNotEmpty) {
        state = state.copyWith(topics: cached);
      }

      final result = await TopicApiService.fetchTopicList();
      final topics = result['topics'] as List<Topic>;
      final nextCursor = result['next_cursor'] as int?;

      await TopicCacheService.cacheTopics(topics);

      state = state.copyWith(
        topics: topics,
        isLoading: false,
        hasMore: nextCursor != null,
        nextCursor: nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 다음 페이지 로드 (무한 스크롤)
  Future<void> fetchMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await TopicApiService.fetchTopicList(
        cursor: state.nextCursor,
      );
      final newTopics = result['topics'] as List<Topic>;
      final nextCursor = result['next_cursor'] as int?;

      state = state.copyWith(
        topics: [...state.topics, ...newTopics],
        isLoading: false,
        hasMore: nextCursor != null,
        nextCursor: nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final topicListProvider =
    StateNotifierProvider<TopicListNotifier, TopicListState>(
  (ref) => TopicListNotifier(),
);

// ══════════════════════════════════════════════════════════════
// 3. 토픽 댓글 상태 (family: "topicId_opinion")
// ══════════════════════════════════════════════════════════════

class TopicCommentState {
  final List<TopicComment> comments;
  final bool isLoading;
  final bool isSubmitting;
  final bool hasMore;
  final String? nextCursor;
  final String sort; // 'latest' or 'popular'

  const TopicCommentState({
    this.comments = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.hasMore = true,
    this.nextCursor,
    this.sort = 'latest',
  });

  TopicCommentState copyWith({
    List<TopicComment>? comments,
    bool? isLoading,
    bool? isSubmitting,
    bool? hasMore,
    String? nextCursor,
    String? sort,
    bool clearCursor = false,
  }) {
    return TopicCommentState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      sort: sort ?? this.sort,
    );
  }
}

class TopicCommentNotifier extends StateNotifier<TopicCommentState> {
  final String arg; // "topicId_opinion" e.g. "5_true"

  TopicCommentNotifier(this.arg)
      : super(const TopicCommentState(isLoading: true)) {
    Future.microtask(() => fetchComments());
  }

  int get _topicId => int.parse(arg.split('_')[0]);
  bool get _opinion => arg.split('_')[1] == 'true';

  /// 댓글 목록 조회
  Future<void> fetchComments() async {
    state = state.copyWith(isLoading: true, clearCursor: true);
    try {
      // 캐시에서 먼저 로드
      final cached = await TopicCacheService.getCachedComments(arg);
      if (cached.isNotEmpty) {
        state = state.copyWith(comments: cached);
      }

      final result = await TopicApiService.fetchComments(
        _topicId,
        opinion: _opinion,
        sort: state.sort,
      );
      final comments = result['comments'] as List<TopicComment>;
      final nextCursor = result['next_cursor'] as String?;

      await TopicCacheService.cacheComments(arg, comments);

      state = state.copyWith(
        comments: comments,
        isLoading: false,
        hasMore: nextCursor != null,
        nextCursor: nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 다음 페이지 로드
  Future<void> fetchMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await TopicApiService.fetchComments(
        _topicId,
        opinion: _opinion,
        cursor: state.nextCursor,
        sort: state.sort,
      );
      final newComments = result['comments'] as List<TopicComment>;
      final nextCursor = result['next_cursor'] as String?;

      state = state.copyWith(
        comments: [...state.comments, ...newComments],
        isLoading: false,
        hasMore: nextCursor != null,
        nextCursor: nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 정렬 변경
  Future<void> changeSort(String sort) async {
    state = state.copyWith(sort: sort);
    await fetchComments();
  }

  /// 댓글 작성
  Future<bool> addComment(String text) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final newComment = await TopicApiService.createComment(_topicId, text);
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

  /// 댓글 수정
  Future<bool> editComment(int commentId, String newText) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final success = await TopicApiService.updateComment(commentId, newText);
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

  /// 댓글 삭제
  Future<bool> removeComment(int commentId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final success = await TopicApiService.deleteComment(commentId);
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

  /// 좋아요 토글 (낙관적 업데이트)
  Future<void> toggleLike(int commentId) async {
    // 낙관적 업데이트
    final optimistic = state.comments.map((c) {
      if (c.commentId == commentId) {
        return c.copyWith(
          isLiked: !c.isLiked,
          likeCount: c.isLiked ? c.likeCount - 1 : c.likeCount + 1,
        );
      }
      return c;
    }).toList();
    state = state.copyWith(comments: optimistic);

    // 서버 요청
    final result = await TopicApiService.toggleLike(commentId);
    if (result == null) {
      // 실패(또는 연타 방지 등) 시 서버 상태로 다시 롤백
      await fetchComments();
    } else {
      // 성공 시 실제 서버의 정확한 좋아요 수로 보정
      final actualLikeCount = result['like_count'] as int?;
      final actualAction = result['action'] as String?;
      if (actualLikeCount != null && actualAction != null) {
        final synced = state.comments.map((c) {
          if (c.commentId == commentId) {
            return c.copyWith(
              isLiked: actualAction == 'liked',
              likeCount: actualLikeCount,
            );
          }
          return c;
        }).toList();
        state = state.copyWith(comments: synced);
      }
    }
  }
}

final topicCommentProvider = StateNotifierProvider.family<
    TopicCommentNotifier, TopicCommentState, String>(
  (ref, arg) => TopicCommentNotifier(arg),
);
