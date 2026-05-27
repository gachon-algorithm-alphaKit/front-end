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
  final String status;

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
    this.status = '보관중',
  });

  factory LostItemPost.fromJson(Map<String, dynamic> json) {
    return LostItemPost(
      itemId: json['item_id'],
      schoolId: json['school_id'],
      placeId: json['place_id'],
      studentId: json['student_id'],
      title: json['title'],
      isAnonymous: _boolFromJson(json['is_anonymous'], fallback: true),
      category: json['category'],
      description: json['description'],
      imgFilePath: json['lost_item_img'] ?? '',
      createTime: json['create_time'],
      similarity: json['similarity'] ?? 100,
      status: json['status'] ?? '보관중',
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

  LostItemPost copyWith({
    String? itemName,
    String? description,
    String? location,
    bool? isAnonymous,
    String? imagePath,
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
      status: status,
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
      'create_time': createTime,
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
  final int lostItemId;
  final int studentId;
  final String comment;

  const Comment({
    required this.commentId,
    required this.lostItemId,
    required this.studentId,
    required this.comment,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['comment_id'],
      lostItemId: json['lost_item_id'],
      studentId: json['student_id'],
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'lost_item_id': lostItemId,
      'student_id': studentId,
      'comment': comment,
    };
  }

  @override
  String toString() {
    return 'Comment(commentId: $commentId, lostItemId: $lostItemId, studentId: $studentId, comment: $comment)';
  }
}
