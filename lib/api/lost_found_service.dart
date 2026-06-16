import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/lost_found_model.dart';
import 'package:alpha_kit/config/api_constants.dart';

class LostFoundService {
  static const String baseUrl = ApiConstants.baseUrl;

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

  static Future<LostItemPost?> createPost({
    required int schoolId,
    int? placeId,
    required String title,
    required bool isAnonymous,
    required String category,
    required String place,
    required String description,
    String? imagePath,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/lost-items'));
      
      final headers = await _getAuthHeaders();
      request.headers.addAll(headers);
      
      request.fields['school_id'] = schoolId.toString();
      if (placeId != null) {
        request.fields['place_id'] = placeId.toString();
      }
      request.fields['title'] = title;
      request.fields['is_anonymous'] = isAnonymous.toString();
      request.fields['category'] = category;
      request.fields['place'] = place;
      request.fields['description'] = description;
      
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('lost_item_img', imagePath));
      }
      
      var response = await request.send();
      if (response.statusCode == 201) {
        var responseBytes = await response.stream.toBytes();
        var decoded = jsonDecode(utf8.decode(responseBytes));
        if (decoded['status'] == 'success') {
          return LostItemPost.fromJson(decoded['data']);
        }
      } else {
        var responseData = await response.stream.bytesToString();
        print('Error response: ${response.statusCode} $responseData');
      }
    } catch (e) {
      print('Error creating lost item: $e');
    }
    return null;
  }

  static Future<LostItemPost?> editItem({
    required int itemId,
    required String title,
    required bool isAnonymous,
    required String category,
    required String place,
    required String description,
    required bool status,
    String? imagePath,
  }) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/api/students/me/lost-items/$itemId'));
      
      final headers = await _getAuthHeaders();
      request.headers.addAll(headers);
      
      final data = {
        'title': title,
        'is_anonymous': isAnonymous,
        'category': category,
        'place': place,
        'description': description,
        'status': status,
      };
      
      request.fields['data'] = jsonEncode(data);
      
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('lost_item_img', imagePath));
      }
      
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBytes = await response.stream.toBytes();
        var decoded = jsonDecode(utf8.decode(responseBytes));
        if (decoded['status'] == 'success') {
          return LostItemPost.fromJson(decoded['data']);
        }
      } else {
        var responseData = await response.stream.bytesToString();
        print('Error response: ${response.statusCode} $responseData');
      }
    } catch (e) {
      print('Error updating lost item: $e');
    }
    return null;
  }

  static Future<List<LostItemPost>> search(String query, bool isFuzzy, {int page = 1, int limit = 10}) async {
    try {
      final headers = await _getJsonAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/lost-items/search/'),
        headers: headers,
        body: jsonEncode({
          'school_id': 1,
          'keyword': query,
          'page': page,
          'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          final List data = decoded['data'] ?? [];
          return data.map((json) => LostItemPost.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('Error searching lost items: $e');
    }
    return [];
  }

  static Future<bool> claimItem(int itemId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/lost-items/$itemId/claim/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return decoded['status'] == 'success';
      }
    } catch (e) {
      print('Error claiming item: $e');
    }
    return false;
  }

  /// 게시글 삭제
  static Future<bool> deletePost(int itemId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/students/me/lost-items/$itemId'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── 댓글 API ──────────────────────────────────────────────

  /// 댓글 목록 조회
  static Future<List<Comment>> getComments(int itemId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/lost-items/$itemId/comments/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          final List data = decoded['data'] ?? [];
          return data.map((json) => Comment.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
    return [];
  }

  /// 댓글 작성
  static Future<Comment?> createComment({
    required int itemId,
    required String comment,
    required bool isAnonymous,
  }) async {
    try {
      final headers = await _getJsonAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/lost-items/$itemId/comments/'),
        headers: headers,
        body: jsonEncode({
          'comment': comment,
          'is_anonymous': isAnonymous,
        }),
      );

      if (response.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          final data = decoded['data'];
          // 서버에서 format_comment를 통해 완성된 데이터를 반환하므로 바로 변환
          return Comment.fromJson(data);
        }
      } else {
        final body = utf8.decode(response.bodyBytes);
        print('Error creating comment: ${response.statusCode} $body');
      }
    } catch (e) {
      // 에러 처리
    }
    return null;
  }

  /// 댓글 수정
  static Future<bool> updateComment({
    required int commentId,
    required String comment,
  }) async {
    try {
      final headers = await _getJsonAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/comments/$commentId/'),
        headers: headers,
        body: jsonEncode({'comment': comment}),
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

  /// 댓글 삭제
  static Future<bool> deleteComment(int commentId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/comments/$commentId/'),
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

  static int _levenshtein(String s, String t) {
    final m = s.length, n = t.length;
    final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        dp[i][j] = s[i - 1] == t[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(min);
      }
    }
    return dp[m][n];
  }


}
