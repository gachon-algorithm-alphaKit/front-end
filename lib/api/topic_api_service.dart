import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/topic_model.dart';

class TopicApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> _getJsonAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── 활성 토픽 조회 ──────────────────────────────────────────
  static Future<Topic?> fetchActiveTopic() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/topics/active/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success' && decoded['data'] != null) {
          return Topic.fromJson(decoded['data']);
        }
      }
    } catch (e) {
      print('Error fetching active topic: $e');
    }
    return null;
  }

  // ── 토픽 목록 조회 (커서 기반 페이지네이션) ──────────────────
  static Future<Map<String, dynamic>> fetchTopicList({int? cursor}) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = cursor != null
          ? Uri.parse('$baseUrl/topics/?cursor=$cursor')
          : Uri.parse('$baseUrl/topics/');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          final data = decoded['data'] as Map<String, dynamic>? ?? {};
          final topicsList = data['topics'] as List<dynamic>? ?? [];
          final topics = topicsList.map((json) => Topic.fromJson(json as Map<String, dynamic>)).toList();
          return {
            'topics': topics,
            'next_cursor': data['next_cursor'],
          };
        }
      }
    } catch (e) {
      print('Error fetching topic list: $e');
    }
    return {'topics': <Topic>[], 'next_cursor': null};
  }

  // ── 투표 ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> vote(
    int topicId,
    bool opinion, {
    bool confirmDelete = false,
  }) async {
    try {
      final headers = await _getJsonAuthHeaders();
      final body = {
        'selectedOpinion': opinion,
        if (confirmDelete) 'confirmDelete': true,
      };
      final response = await http.post(
        Uri.parse('$baseUrl/topics/$topicId/vote/'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          return decoded['data'] as Map<String, dynamic>?;
        }
      } else if (response.statusCode == 409) {
        // 댓글이 있는 상태에서 투표 변경 시 확인 필요
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['code'] == 'COMMENT_EXISTS') {
          return {'confirm_required': true};
        }
      }
    } catch (e) {
      print('Error voting: $e');
    }
    return null;
  }

  // ── 투표 통계 조회 ──────────────────────────────────────────
  static Future<VoteStat?> fetchVoteStat(int topicId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/topics/$topicId/vote/stat/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success' && decoded['data'] != null) {
          return VoteStat.fromJson(decoded['data']);
        }
      }
    } catch (e) {
      print('Error fetching vote stat: $e');
    }
    return null;
  }

  // ── 댓글 작성 ──────────────────────────────────────────────
  static Future<TopicComment?> createComment(
    int topicId,
    String text,
  ) async {
    try {
      final headers = await _getJsonAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/topics/$topicId/comments/'),
        headers: headers,
        body: jsonEncode({'comment': text}),
      );

      if (response.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          return TopicComment.fromJson(decoded['data']);
        }
      }
    } catch (e) {
      print('Error creating comment: $e');
    }
    return null;
  }

  // ── 댓글 목록 조회 (의견별, 커서 기반 페이지네이션) ──────────
  static Future<Map<String, dynamic>> fetchComments(
    int topicId, {
    required bool opinion,
    String? cursor,
    String sort = 'latest',
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = {
        'opinion': opinion.toString(),
        'sort': sort,
        'cursor': ?cursor,
      };
      final uri = Uri.parse('$baseUrl/topics/$topicId/comments/list/')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          final data = decoded['data'] as Map<String, dynamic>? ?? {};
          final commentsList = data['comments'] as List<dynamic>? ?? [];
          final comments =
              commentsList.map((json) => TopicComment.fromJson(json as Map<String, dynamic>)).toList();
          return {
            'comments': comments,
            'next_cursor': data['next_cursor'],
            'has_more': data['has_more'] ?? false,
            'total_count': data['total_count'] ?? 0,
          };
        }
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
    return {'comments': <TopicComment>[], 'next_cursor': null};
  }

  // ── 댓글 수정 ──────────────────────────────────────────────
  static Future<bool> updateComment(int commentId, String text) async {
    try {
      final headers = await _getJsonAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/topics/comments/$commentId/'),
        headers: headers,
        body: jsonEncode({'comment': text}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return decoded['status'] == 'success';
      }
    } catch (e) {
      print('Error updating comment: $e');
    }
    return false;
  }

  // ── 댓글 삭제 ──────────────────────────────────────────────
  static Future<bool> deleteComment(int commentId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/topics/comments/$commentId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return decoded['status'] == 'success';
      }
    } catch (e) {
      print('Error deleting comment: $e');
    }
    return false;
  }

  // ── 좋아요 토글 ──────────────────────────────────────────
  static Future<Map<String, dynamic>?> toggleLike(int commentId) async {
    try {
      final headers = await _getJsonAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/topics/comments/$commentId/like/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          return decoded['data'] as Map<String, dynamic>?;
        }
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
    return null;
  }
}
