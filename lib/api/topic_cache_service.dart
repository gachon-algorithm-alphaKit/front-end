import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/topic_model.dart';

class TopicCacheService {
  static const String _topicsKey = 'cached_topics';
  static const String _commentsKeyPrefix = 'cached_topic_comments_';

  // ── 토픽 리스트 캐시 ────────────────────────────────────────
  static Future<void> cacheTopics(List<Topic> topics) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = topics.map((t) => {
      'topic_id': t.topicId,
      'title': t.title,
      'opinion_1': t.opinion1,
      'opinion_2': t.opinion2,
      'publish_date': t.publishDate,
      'is_active': t.isActive,
      'total_vote_count': t.totalVoteCount,
      'my_vote': t.myVote,
      'created_at': t.createdAt,
    }).toList();
    await prefs.setString(_topicsKey, jsonEncode(jsonList));
  }

  static Future<List<Topic>> getCachedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_topicsKey);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((json) => Topic.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── 댓글 캐시 ──────────────────────────────────────────────
  static Future<void> cacheComments(
    String key,
    List<TopicComment> comments,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = comments.map((c) => {
      'comment_id': c.commentId,
      'writer': c.writer,
      'is_writer': c.isWriter,
      'comment': c.comment,
      'select_opinion': c.selectOpinion,
      'create_time': c.createTime,
      'like_count': c.likeCount,
      'is_liked': c.isLiked,
    }).toList();
    await prefs.setString('$_commentsKeyPrefix$key', jsonEncode(jsonList));
  }

  static Future<List<TopicComment>> getCachedComments(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_commentsKeyPrefix$key');
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((json) => TopicComment.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── 전체 캐시 삭제 ──────────────────────────────────────────
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_topicsKey);
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_commentsKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
