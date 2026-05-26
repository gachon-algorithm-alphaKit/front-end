import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthApi {
  // Android Emulator에서는 localhost 대신 10.0.2.2를 사용합니다. 
  // 실제 기기나 웹 테스트 시 서버 IP에 맞게 변경하세요.
  static const String baseUrl = 'http://10.0.2.2:8000/api/students';

  static Future<Map<String, dynamic>> login(String username, String password, int schoolId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'school_id': schoolId,
      }),
    );
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> submitAdditionalInfo(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/info'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
}
