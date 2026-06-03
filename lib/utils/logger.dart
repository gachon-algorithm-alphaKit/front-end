import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';

class CustomLogger {
  static final Logger _consoleLogger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  static final List<String> _maskKeys = ['password', 'token', 'secret', 'authorization', 'refresh'];

  static dynamic _maskSensitiveData(dynamic data) {
    if (data is Map) {
      final masked = <String, dynamic>{};
      data.forEach((key, value) {
        if (key is String && _maskKeys.any((k) => key.toLowerCase().contains(k))) {
          masked[key] = '***MASKED***';
        } else {
          masked[key] = _maskSensitiveData(value);
        }
      });
      return masked;
    } else if (data is List) {
      return data.map((e) => _maskSensitiveData(e)).toList();
    }
    return data;
  }

  static Future<void> _writeToFile(String level, Map<String, dynamic> logData, {bool isUiError = false}) async {
    try {
      // In a real mobile app, this should use path_provider to get Application Documents Directory.
      // Since we need to write to the project's 'log' folder for git/development:
      final String basePath = Directory.current.path;
      final String fileName = '${DateTime.now().toIso8601String().split('T')[0]}.json';
      
      File file;
      if (isUiError) {
        file = File('$basePath/log/ui_error.log');
      } else {
        file = File('$basePath/log/$level/$fileName');
      }

      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }

      final jsonString = '${jsonEncode(logData)}\n';
      await file.writeAsString(jsonString, mode: FileMode.append);
    } catch (e) {
      // If writing to file fails (e.g. on real mobile device where project path is inaccessible),
      // we just skip it or log to console.
      _consoleLogger.e("Failed to write log to file", error: e);
    }
  }

  static Map<String, dynamic> _buildLogData(String level, String message, {Map<String, dynamic>? extra, String? apiName}) {
    final Map<String, dynamic> data = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level,
      'message': message,
    };

    if (apiName != null) {
      data['api_name'] = apiName;
    }

    if (extra != null) {
      data['extra'] = _maskSensitiveData(extra);
    }

    return data;
  }

  static void info(String message, {Map<String, dynamic>? extra, String? apiName}) {
    final logData = _buildLogData('INFO', message, extra: extra, apiName: apiName);
    _consoleLogger.i(message, error: extra != null ? _maskSensitiveData(extra) : null);
    _writeToFile('info', logData);
  }

  static void warn(String message, {Map<String, dynamic>? extra, String? apiName}) {
    final logData = _buildLogData('WARN', message, extra: extra, apiName: apiName);
    _consoleLogger.w(message, error: extra != null ? _maskSensitiveData(extra) : null);
    _writeToFile('warn', logData);
  }

  static void error(String message, {Map<String, dynamic>? extra, dynamic error, StackTrace? stackTrace, String? apiName}) {
    final logData = _buildLogData('ERROR', message, extra: extra, apiName: apiName);
    if (error != null) {
      logData['error'] = error.toString();
    }
    if (stackTrace != null) {
      logData['stackTrace'] = stackTrace.toString();
    }
    
    _consoleLogger.e(message, error: error, stackTrace: stackTrace);
    _writeToFile('error', logData);
  }

  static void uiError(String message, {Map<String, dynamic>? extra, dynamic error, StackTrace? stackTrace}) {
    final logData = _buildLogData('UI_ERROR', message, extra: extra);
    if (error != null) {
      logData['error'] = error.toString();
    }
    if (stackTrace != null) {
      logData['stackTrace'] = stackTrace.toString();
    }
    
    _consoleLogger.e("[UI Error] $message", error: error, stackTrace: stackTrace);
    _writeToFile('error', logData, isUiError: true);
  }
}
