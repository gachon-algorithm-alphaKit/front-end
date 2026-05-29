class LostItemPost {
  final int itemId;
  final int schoolId;
  final int? placeId;
  final int studentId;
  final String title;
  final bool isAnonymous;
  final String category;
  final String description;
  final String imgFilePath;
  final String createTime;
  final int similarity;
  final bool status;
  final bool isMine;

  const LostItemPost({
    required this.itemId,
    required this.schoolId,
    this.placeId,
    required this.studentId,
    required this.title,
    required this.isAnonymous,
    required this.category,
    required this.description,
    required this.imgFilePath,
    required this.createTime,
    this.similarity = 100,
    this.status = false,
    this.isMine = false,
  });

  factory LostItemPost.fromJson(Map<String, dynamic> json) {
    int sim = 100;
    if (json.containsKey('match_score')) {
      final score = json['match_score'];
      if (score['is_exact_match'] == true) {
        sim = 100;
      } else {
        int dist = score['levenshtein_distance'] ?? 0;
        if (dist == 0) sim = 100;
        else if (dist == 1) sim = 95;
        else if (dist == 2) sim = 90;
        else sim = 80;
      }
    } else {
      sim = json['similarity'] ?? 100;
    }

    String createTimeStr = json['create_time'] ?? '';
    try {
      if (createTimeStr.isNotEmpty) {
        final utcTime = DateTime.parse(createTimeStr).toUtc();
        final localTime = utcTime.toLocal();
        createTimeStr = localTime.toIso8601String();
      }
    } catch (e) {
      // parse failed, fallback to original
    }

    return LostItemPost(
      itemId: json['item_id'],
      schoolId: json['school_id'],
      placeId: json['place_id'],
      studentId: json['student_id'] ?? 0,
      title: json['title'] ?? '',
      isAnonymous: _boolFromJson(json['is_anonymous'], fallback: true),
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      imgFilePath: json['lost_item_img'] ?? '',
      createTime: createTimeStr,
      similarity: sim,
      status: _boolFromJson(json['status'], fallback: false),
      isMine: _boolFromJson(json['is_mine'], fallback: false),
    );
  }

  String get id => itemId.toString();
  String get itemName => title;
  String get location => category.isNotEmpty
      ? category
      : placeId != null
      ? '장소 #$placeId'
      : '미지정';
  String get date => _formatDate(createTime);
  String get foundDate => date;
  String? get imagePath => imgFilePath.isEmpty ? null : imgFilePath;
  String get statusText => status ? '주인 찾음' : '보관중';

  LostItemPost copyWith({
    String? itemName,
    String? description,
    String? location,
    bool? isAnonymous,
    String? imagePath,
    bool? status,
    bool clearImage = false,
  }) {
    return LostItemPost(
      itemId: itemId,
      schoolId: schoolId,
      placeId: placeId,
      studentId: studentId,
      title: itemName ?? title,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      category: location ?? category,
      description: description ?? this.description,
      imgFilePath: clearImage ? '' : (imagePath ?? imgFilePath),
      createTime: createTime,
      similarity: similarity,
      status: status ?? this.status,
      isMine: isMine,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'school_id': schoolId,
      'place_id': placeId,
      'student_id': studentId,
      'title': title,
      'is_anonymous': isAnonymous,
      'category': category,
      'description': description,
      'lost_item_img': imgFilePath,
      'status': status,
      'create_time': createTime,
      'is_mine': isMine,
    };
  }

  @override
  String toString() {
    return 'LostItemPost(itemId: $itemId, schoolId: $schoolId, placeId: $placeId, studentId: $studentId, title: $title, isAnonymous: $isAnonymous, category: $category, description: $description, imgFilePath: $imgFilePath, createTime: $createTime)';
  }

  static bool _boolFromJson(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value == 1;
    }
    return fallback;
  }

  static String _formatDate(String value) {
    final normalized = value.contains('T') ? value.split('T').first : value;
    return normalized.replaceAll('-', '.');
  }
}

typedef LostFoundPost = LostItemPost;
typedef LostItem = LostItemPost;

class Comment {
  final int commentId;
  final String writer;
  final bool isWriter;
  final bool isPostOwner;
  final String comment;
  final bool isAnonymous;
  final String createTime;

  const Comment({
    required this.commentId,
    required this.writer,
    this.isWriter = false,
    this.isPostOwner = false,
    required this.comment,
    this.isAnonymous = true,
    required this.createTime,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['comment_id'] ?? 0,
      writer: json['writer'] ?? '익명',
      isWriter: json['is_writer'] ?? false,
      isPostOwner: json['is_post_owner'] ?? false,
      comment: json['comment'] ?? '',
      isAnonymous: json['is_anonymous'] ?? true,
      createTime: json['create_time'] ?? '',
    );
  }

  Comment copyWith({
    String? comment,
  }) {
    return Comment(
      commentId: commentId,
      writer: writer,
      isWriter: isWriter,
      isPostOwner: isPostOwner,
      comment: comment ?? this.comment,
      isAnonymous: isAnonymous,
      createTime: createTime,
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
    return 'Comment(commentId: $commentId, writer: $writer, comment: $comment)';
  }
}
