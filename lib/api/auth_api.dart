import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alpha_kit/config/api_constants.dart';

class AuthApi {
  // Android Emulator에서는 localhost 대신 10.0.2.2를 사용합니다.
  static const String baseUrl = '${ApiConstants.baseUrl}/api/students';

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

  static Future<Map<String, dynamic>> submitAdditionalInfo(Map<String, dynamic> data, {String? imagePath}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/info'));
    
    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('profile_img', imagePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> updateUserInfo(Map<String, dynamic> data, {String? imagePath}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/info'));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('profile_img', imagePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
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

  static Future<dynamic> fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/info'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['status'] == 'success') {
          return body['data']; // We will parse this to UserProfile in UI layer
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
