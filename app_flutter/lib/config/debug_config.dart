import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../services/config_service.dart';

class DebugConfig {
  DebugConfig._();

  static bool enabled = true;

  static bool navigation = true;
  static bool http = true;
  static bool screenLifecycle = true;
  static bool performance = true;
  static bool sync = true;
  static bool offlineOps = true;
  static bool invitations = true;

  static bool samplingEnabled = false;

  static Duration samplingWindow = const Duration(seconds: 5);

  static bool httpOnlySlow = false;

  static int syncFastModuleSkipMs = 40;

  static int maxLogEntries = 1000;

  static final Map<String, DateTime> _lastEmitted = <String, DateTime>{};

  static bool shouldEmit(String category, String key) {
    if (!enabled) return false;
    if (!samplingEnabled) return true;

    final composite = '$category::$key';
    final now = DateTime.now();
    final last = _lastEmitted[composite];

    if (last == null || now.difference(last) > samplingWindow) {
      _lastEmitted[composite] = now;

      if (_lastEmitted.length > maxLogEntries) {
        _cleanupOldEntries(now);
      }

      return true;
    }
    return false;
  }

  static void _cleanupOldEntries(DateTime now) {
    final cutoffTime = now.subtract(samplingWindow * 2);
    _lastEmitted.removeWhere((key, lastTime) => lastTime.isBefore(cutoffTime));
  }

  static int slowHttpThresholdMs = 1200;
  static int slowBuildThresholdMs = 32;

  static const String _appName = 'EventyPop';

  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!DebugConfig.enabled) return;
    if (kDebugMode) {
      final formattedMessage = _formatMessage(message, tag ?? 'DEBUG');
      developer.log(formattedMessage, name: _appName, level: 500, error: error, stackTrace: stackTrace);
    }
  }

  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!DebugConfig.enabled) return;
    final formattedMessage = _formatMessage(message, tag ?? 'INFO');

    developer.log(formattedMessage, name: _appName, level: 800, error: error, stackTrace: stackTrace);
  }

  static void warn(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!DebugConfig.enabled) return;
    final formattedMessage = _formatMessage(message, tag ?? 'WARNING');

    developer.log(formattedMessage, name: _appName, level: 900, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!DebugConfig.enabled) return;
    final formattedMessage = _formatMessage(message, tag ?? 'ERROR');

    developer.log(formattedMessage, name: _appName, level: 1000, error: error, stackTrace: stackTrace);
  }

  static void network(String message, {Object? error, StackTrace? stackTrace}) {
    if (DebugConfig.httpOnlySlow && !message.contains('SLOW') && !message.contains('slow')) {
      return;
    }
    if (!DebugConfig.samplingEnabled || DebugConfig.shouldEmit('network', _deriveKey(message))) {
      debug(message, tag: 'NETWORK', error: error, stackTrace: stackTrace);
    }
  }

  static void syncLog(String message, {Object? error, StackTrace? stackTrace}) {
    if (!DebugConfig.samplingEnabled || DebugConfig.shouldEmit('sync', _deriveKey(message))) {
      debug(message, tag: 'SYNC', error: error, stackTrace: stackTrace);
    }
  }

  static void database(String message, {Object? error, StackTrace? stackTrace}) {
    debug(message, tag: 'DATABASE', error: error, stackTrace: stackTrace);
  }

  static void ui(String message, {Object? error, StackTrace? stackTrace}) {
    debug(message, tag: 'UI', error: error, stackTrace: stackTrace);
  }

  static void auth(String message, {Object? error, StackTrace? stackTrace}) {
    info(message, tag: 'AUTH', error: error, stackTrace: stackTrace);
  }

  static void track(String event, [Map<String, dynamic>? payload]) {
    if (!DebugConfig.enabled) return;
    final meta = payload == null ? '' : ' ${payload.toString()}';
    info('TRACK $event$meta');
  }

  static void trackSuccess(String event, [Map<String, dynamic>? payload]) {
    if (!DebugConfig.enabled) return;
    final meta = payload == null ? '' : ' ${payload.toString()}';
    info('TRACK SUCCESS $event$meta');
  }

  static void trackFailure(String event, Object error, [Map<String, dynamic>? payload]) {
    if (!DebugConfig.enabled) return;
    final meta = payload == null ? '' : ' ${payload.toString()}';

    final errorString = error.toString();
    if (errorString.contains('Authentication token required') || errorString.contains('401') || errorString.contains('Unauthorized')) {
    } else {
      if (error is Exception) {
        DebugConfig.error('TRACK FAILURE $event$meta', error: error);
      } else {
        DebugConfig.error('TRACK FAILURE $event$meta');
      }
    }
  }

  static String _formatMessage(String message, String tag) {
    final now = DateTime.now();
    final timestamp = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final emoji = _getEmojiForTag(tag);

    final testModeIndicator = _getTestModeIndicator();

    return '$emoji [$tag] [$timestamp]$testModeIndicator $message';
  }

  static String _getTestModeIndicator() {
    try {
      final configService = ConfigService.instance;
      if (configService.isTestMode) {
        return ' [TEST-MODE]';
      } else {
        return ' [PROD-MODE]';
      }
    } catch (e) {
      return '';
    }
  }

  static String _getEmojiForTag(String tag) {
    switch (tag.toLowerCase()) {
      case 'debug':
        return '🐛';
      case 'info':
        return 'ℹ️';
      case 'warning':
        return '⚠️';
      case 'error':
        return '❌';
      case 'network':
        return '🌐';
      case 'sync':
        return '🔄';
      case 'database':
        return '🗄️';
      case 'ui':
        return '📱';
      case 'auth':
        return '🔐';
      default:
        return '📝';
    }
  }

  static String _deriveKey(String message) {
    final normalized = message.replaceAll(RegExp('[0-9]+'), '#');
    return normalized.length <= 40 ? normalized : normalized.substring(0, 40);
  }
}

extension LoggerExtension on Object {
  void logDebug(String message, {Object? error, StackTrace? stackTrace}) {}
  void logInfo(String message, {Object? error, StackTrace? stackTrace}) {}
  void logWarning(String message, {Object? error, StackTrace? stackTrace}) {
    DebugConfig.warn(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }

  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    DebugConfig.error(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }
}
