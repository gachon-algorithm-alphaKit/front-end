import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/model/topic_model.dart';

void main() async {
  final uri = Uri.parse('http://127.0.0.1:8000/api/topics/1/comments/list/?opinion=true');
  final response = await http.get(uri);
  print('Status code: ${response.statusCode}');
  try {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final Map<String, dynamic> data = decoded['data'] ?? {};
    final List commentsList = data['comments'] ?? [];
    
    final comments = commentsList.map((json) => TopicComment.fromJson(json)).toList();
    
    print('Found ${comments.length} comments');
    print('First comment: ${comments.first}');
    print('Parsing successful');
  } catch (e, stacktrace) {
    print('Error during parsing: $e');
    print(stacktrace);
  }
}
