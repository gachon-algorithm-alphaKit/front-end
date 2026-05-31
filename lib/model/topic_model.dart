class Topic {
  final int topicId;
  final String title;
  final String opinion1;
  final String opinion2;
  final String publishDate;
  final bool isActive;
  final int totalVoteCount;
  final bool? myVote; // null=not voted, true=opinion1, false=opinion2
  final String createdAt;

  const Topic({
    required this.topicId,
    required this.title,
    required this.opinion1,
    required this.opinion2,
    required this.publishDate,
    this.isActive = false,
    this.totalVoteCount = 0,
    this.myVote,
    this.createdAt = '',
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      topicId: json['topic_id'] ?? 0,
      title: json['title'] ?? '',
      opinion1: json['opinion_1'] ?? '',
      opinion2: json['opinion_2'] ?? '',
      publishDate: json['publish_date'] ?? '',
      isActive: json['is_active'] ?? false,
      totalVoteCount: json['total_vote_count'] ?? 0,
      myVote: json['my_vote'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Topic copyWith({bool? myVote, int? totalVoteCount, bool? isActive}) {
    return Topic(
      topicId: topicId,
      title: title,
      opinion1: opinion1,
      opinion2: opinion2,
      publishDate: publishDate,
      isActive: isActive ?? this.isActive,
      totalVoteCount: totalVoteCount ?? this.totalVoteCount,
      myVote: myVote ?? this.myVote,
      createdAt: createdAt,
    );
  }

  bool get hasVoted => myVote != null;

  String get formattedDate {
    if (publishDate.isEmpty) return '';
    final normalized =
        publishDate.contains('T') ? publishDate.split('T').first : publishDate;
    return normalized.replaceAll('-', '.');
  }

  @override
  String toString() {
    return 'Topic(topicId: $topicId, title: $title, isActive: $isActive)';
  }
}

class TopicComment {
  final int commentId;
  final String writer; // "학생1", "학생3 (나)"
  final bool isWriter;
  final String comment;
  final bool selectOpinion;
  final String createTime;
  final int likeCount;
  final bool isLiked;

  const TopicComment({
    required this.commentId,
    required this.writer,
    this.isWriter = false,
    required this.comment,
    required this.selectOpinion,
    required this.createTime,
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory TopicComment.fromJson(Map<String, dynamic> json) {
    return TopicComment(
      commentId: json['comment_id'] ?? 0,
      writer: json['writer'] ?? '익명',
      isWriter: json['is_writer'] ?? false,
      comment: json['comment'] ?? '',
      selectOpinion: json['select_opinion'] ?? true,
      createTime: json['created_at'] ?? json['create_time'] ?? '',
      likeCount: json['like_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }

  TopicComment copyWith({String? comment, int? likeCount, bool? isLiked}) {
    return TopicComment(
      commentId: commentId,
      writer: writer,
      isWriter: isWriter,
      comment: comment ?? this.comment,
      selectOpinion: selectOpinion,
      createTime: createTime,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  String get timeAgo {
    if (createTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(createTime).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return createTime;
    }
  }

  @override
  String toString() {
    return 'TopicComment(commentId: $commentId, writer: $writer, comment: $comment)';
  }
}

class VoteStat {
  final int opinion1Count;
  final int opinion2Count;
  final int totalCount;

  const VoteStat({
    this.opinion1Count = 0,
    this.opinion2Count = 0,
    this.totalCount = 0,
  });

  factory VoteStat.fromJson(Map<String, dynamic> json) {
    return VoteStat(
      opinion1Count: json['opinion_1_count'] ?? 0,
      opinion2Count: json['opinion_2_count'] ?? 0,
      totalCount: json['total_count'] ?? 0,
    );
  }

  double get opinion1Ratio =>
      totalCount == 0 ? 0.5 : opinion1Count / totalCount;
  double get opinion2Ratio =>
      totalCount == 0 ? 0.5 : opinion2Count / totalCount;
  int get opinion1Percent => (opinion1Ratio * 100).round();
  int get opinion2Percent => (opinion2Ratio * 100).round();

  @override
  String toString() {
    return 'VoteStat(opinion1: $opinion1Count, opinion2: $opinion2Count, total: $totalCount)';
  }
}
