import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/debug_config.dart';

/// API Logger - Logs all HTTP requests and responses to a file for debugging
///
/// This logger is enabled/disabled via the API_LOGGING environment variable.
/// When enabled, it writes detailed logs of all API calls to api_calls.log
///
/// Log format includes:
/// - Timestamp
/// - HTTP method and URL
/// - Caller information (file:line → method)
/// - Request headers and body
/// - Response status, duration, and body
class ApiLogger {
  static final ApiLogger _instance = ApiLogger._internal();
  static ApiLogger get instance => _instance;

  bool _enabled = false;
  File? _logFile;
  final int _maxLogSizeBytes = 10 * 1024 * 1024; // 10MB

  ApiLogger._internal();

  /// Enable or disable API logging
  set enabled(bool value) {
    _enabled = value;
    if (_enabled) {
      _initLogFile();
    }
  }

  bool get enabled => _enabled;

  /// Initialize log file path
  Future<void> _initLogFile() async {
    try {
      // Save log file in project directory for easy access
      final logPath = '/Users/miquelfarre/development/agenda_phoenix/app_flutter/api_calls.log';
      _logFile = File(logPath);

      // Check if log file is too large and rotate it
      if (await _logFile!.exists()) {
        final fileSize = await _logFile!.length();
        if (fileSize > _maxLogSizeBytes) {
          await _rotateLogFile();
        }
      }

      DebugConfig.info(
        'API logging initialized - logs at: $logPath',
        tag: 'ApiLogger',
      );
    } catch (e) {
      DebugConfig.error(
        'Failed to initialize API log file: $e',
        tag: 'ApiLogger',
      );
    }
  }

  /// Rotate log file when it gets too large
  Future<void> _rotateLogFile() async {
    try {
      final oldLogPath = '${_logFile!.path}.old';
      final oldLogFile = File(oldLogPath);

      // Delete old backup if exists
      if (await oldLogFile.exists()) {
        await oldLogFile.delete();
      }

      // Rename current log to .old
      await _logFile!.rename(oldLogPath);

      // Recreate log file
      _logFile = File(_logFile!.path);

      DebugConfig.info(
        'Log file rotated - old logs saved to: $oldLogPath',
        tag: 'ApiLogger',
      );
    } catch (e) {
      DebugConfig.error(
        'Failed to rotate log file: $e',
        tag: 'ApiLogger',
      );
    }
  }

  /// Log an HTTP request before sending it
  void logRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    dynamic body,
    String callerInfo,
  ) {
    if (!_enabled || _logFile == null) return;

    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer();

    buffer.writeln('========================================');
    buffer.writeln('[$timestamp] $method $uri');
    buffer.writeln('Caller: $callerInfo');

    // Log headers
    buffer.writeln('Headers: {');
    headers.forEach((key, value) {
      // Mask sensitive headers
      if (key.toLowerCase() == 'authorization') {
        buffer.writeln('  "$key": "Bearer ***MASKED***"');
      } else {
        buffer.writeln('  "$key": "$value"');
      }
    });
    buffer.writeln('}');

    // Log query parameters if present
    if (uri.queryParameters.isNotEmpty) {
      buffer.writeln('Query Params: {');
      uri.queryParameters.forEach((key, value) {
        buffer.writeln('  "$key": "$value"');
      });
      buffer.writeln('}');
    }

    // Log request body if present
    if (body != null) {
      buffer.writeln('Request Body:');
      try {
        final prettyBody = _prettyPrintJson(body);
        buffer.writeln(prettyBody);
      } catch (e) {
        buffer.writeln(body.toString());
      }
    }

    _writeToFile(buffer.toString());
  }

  /// Log an HTTP response after receiving it
  void logResponse(http.Response response, int durationMs) {
    if (!_enabled || _logFile == null) return;

    final buffer = StringBuffer();

    buffer.writeln('----------------------------------------');
    buffer.writeln('Response: ${response.statusCode} ${response.reasonPhrase} (${durationMs}ms)');

    // Log response headers
    if (response.headers.isNotEmpty) {
      buffer.writeln('Response Headers: {');
      response.headers.forEach((key, value) {
        buffer.writeln('  "$key": "$value"');
      });
      buffer.writeln('}');
    }

    // Log response body
    buffer.writeln('Response Body:');
    try {
      final rawBody = utf8.decode(response.bodyBytes);
      final prettyBody = _prettyPrintJson(rawBody);
      buffer.writeln(prettyBody);
    } catch (e) {
      buffer.writeln(response.body);
    }

    buffer.writeln('========================================\n');

    _writeToFile(buffer.toString());
  }

  /// Log an HTTP error
  void logError(dynamic error, int durationMs) {
    if (!_enabled || _logFile == null) return;

    final buffer = StringBuffer();

    buffer.writeln('----------------------------------------');
    buffer.writeln('ERROR after ${durationMs}ms:');
    buffer.writeln(error.toString());
    buffer.writeln('========================================\n');

    _writeToFile(buffer.toString());
  }

  /// Pretty print JSON for better readability
  String _prettyPrintJson(dynamic json) {
    try {
      dynamic jsonObject;
      if (json is String) {
        jsonObject = jsonDecode(json);
      } else {
        jsonObject = json;
      }

      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonObject);
    } catch (e) {
      return json.toString();
    }
  }

  /// Write log content to file
  Future<void> _writeToFile(String content) async {
    if (_logFile == null) return;

    try {
      await _logFile!.writeAsString(
        content,
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      DebugConfig.error(
        'Failed to write to log file: $e',
        tag: 'ApiLogger',
      );
    }
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    if (_logFile == null) return;

    try {
      if (await _logFile!.exists()) {
        await _logFile!.delete();
        _logFile = File(_logFile!.path);
        DebugConfig.info('API logs cleared', tag: 'ApiLogger');
      }
    } catch (e) {
      DebugConfig.error(
        'Failed to clear logs: $e',
        tag: 'ApiLogger',
      );
    }
  }
}
