import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/course_model.dart';

/// 위시리스트 API 응답 래퍼
class WishlistResult {
  final bool success;
  final String message;
  final String? action; // 'added' | 'removed'
  final bool unauthorized;

  const WishlistResult({
    required this.success,
    required this.message,
    this.action,
    this.unauthorized = false,
  });
}

class WishlistService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// SharedPreferences에서 access_token을 읽어 Authorization 헤더 생성
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// POST /api/wishlist/toggle/ — 찜 토글 (추가/삭제)
  static Future<WishlistResult> toggleWishlist(int courseId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/wishlist/toggle/'),
        headers: headers,
        body: jsonEncode({'course_id': courseId}),
      );

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 401) {
        return WishlistResult(
          success: false,
          message: decoded['message'] ?? '인증이 만료되었습니다.',
          unauthorized: true,
        );
      }

      return WishlistResult(
        success: decoded['status'] == 'success',
        message: decoded['message'] ?? '',
        action: decoded['data']?['action'],
      );
    } catch (e) {
      return WishlistResult(
        success: false,
        message: '서버와 통신할 수 없습니다: $e',
      );
    }
  }

  /// GET /api/wishlist/ — 찜 목록 조회
  static Future<List<Course>> fetchWishlist({int page = 1, int limit = 20}) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/wishlist/?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          final List data = decoded['data'] ?? [];
          return data.map((json) => Course.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('Error fetching wishlist: $e');
    }
    return [];
  }

  /// GET /api/wishlist/ — 찜한 강의 ID Set만 가져오기 (앱 시작 시 동기화용)
  static Future<Set<int>> fetchWishlistIds() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/wishlist/?limit=1000'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['status'] == 'success') {
          final List data = decoded['data'] ?? [];
          return data.map<int>((json) => json['course_id'] as int).toSet();
        }
      }
    } catch (e) {
      print('Error fetching wishlist IDs: $e');
    }
    return {};
  }

  /// DELETE /api/wishlist/remove/<courseId>/ — 찜 삭제
  static Future<WishlistResult> removeFromWishlist(int courseId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/wishlist/remove/$courseId/'),
        headers: headers,
      );

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 401) {
        return WishlistResult(
          success: false,
          message: decoded['message'] ?? '인증이 만료되었습니다.',
          unauthorized: true,
        );
      }

      return WishlistResult(
        success: decoded['status'] == 'success',
        message: decoded['message'] ?? '',
      );
    } catch (e) {
      return WishlistResult(
        success: false,
        message: '서버와 통신할 수 없습니다: $e',
      );
    }
  }
}
