import 'dart:convert';
import 'package:http/http.dart' as http;
import 'logger.dart';

class LoggingClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();
    final requestId = '${request.url.pathSegments.lastOrNull ?? "root"}-${DateTime.now().millisecondsSinceEpoch}';

    // 1. API 요청 로그 (info)
    CustomLogger.info(
      'API Request: ${request.method} ${request.url}',
      apiName: requestId,
      extra: {
        'method': request.method,
        'url': request.url.toString(),
        'headers': request.headers,
      },
    );

    try {
      final response = await _inner.send(request);
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      // 응답 본문 읽기를 위해 바이트 스트림 복사
      final responseBytes = await response.stream.toBytes();
      final responseBody = utf8.decode(responseBytes);
      
      dynamic parsedBody;
      try {
        parsedBody = jsonDecode(responseBody);
      } catch (_) {
        parsedBody = responseBody;
      }

      final extraData = {
        'statusCode': response.statusCode,
        'duration_ms': duration,
        'response': parsedBody,
      };

      if (response.statusCode >= 400) {
        // 400 이상 에러 발생
        CustomLogger.error(
          'API Error: ${response.statusCode} - ${request.method} ${request.url}',
          apiName: requestId,
          extra: extraData,
        );
      } else {
        // 2. API 응답 로그 (info)
        CustomLogger.info(
          'API Response: ${response.statusCode} - ${request.method} ${request.url}',
          apiName: requestId,
          extra: extraData,
        );
      }

      // 새 스트림으로 응답 반환
      return http.StreamedResponse(
        Stream.fromIterable([responseBytes]),
        response.statusCode,
        contentLength: response.contentLength,
        request: request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      CustomLogger.error(
        'API Request Failed: ${request.method} ${request.url}',
        apiName: requestId,
        error: e,
        stackTrace: stackTrace,
        extra: {
          'method': request.method,
          'url': request.url.toString(),
          'duration_ms': duration,
        },
      );
      rethrow;
    }
  }
}
