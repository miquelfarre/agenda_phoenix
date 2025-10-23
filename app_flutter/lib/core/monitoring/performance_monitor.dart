import 'dart:async';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  static PerformanceMonitor get instance => _instance;

  final Map<String, List<PerformanceMetric>> _metrics = {};
  final Map<String, DateTime> _activeTimers = {};

  void startTimer(String operationName) {
    _activeTimers[operationName] = DateTime.now();
  }

  void endTimer(String operationName, {Map<String, dynamic>? metadata}) {
    final startTime = _activeTimers.remove(operationName);
    if (startTime == null) {
      return;
    }

    final duration = DateTime.now().difference(startTime);
    recordMetric(
      PerformanceMetric(
        operationName: operationName,
        duration: duration,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
      ),
    );
  }

  void recordMetric(PerformanceMetric metric) {
    _metrics.putIfAbsent(metric.operationName, () => []).add(metric);

    _checkThresholds(metric);
  }

  List<PerformanceMetric> getMetrics(String operationName) {
    return _metrics[operationName] ?? [];
  }

  Map<String, List<PerformanceMetric>> getAllMetrics() {
    return Map.from(_metrics);
  }

  void clearMetrics([String? operationName]) {
    if (operationName != null) {
      _metrics.remove(operationName);
    } else {
      _metrics.clear();
    }
  }

  Future<T> trackPerformance<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    final startTime = DateTime.now();
    try {
      final result = await operation();
      final duration = DateTime.now().difference(startTime);
      recordMetric(
        PerformanceMetric(
          operationName: operationName,
          duration: duration,
          timestamp: DateTime.now(),
          metadata: metadata ?? {},
        ),
      );
      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      recordMetric(
        PerformanceMetric(
          operationName: operationName,
          duration: duration,
          timestamp: DateTime.now(),
          metadata: {...?metadata, 'error': e.toString(), 'failed': true},
        ),
      );
      rethrow;
    }
  }

  void _checkThresholds(PerformanceMetric metric) {
    switch (metric.operationName) {
      case 'widget_build':
        if (metric.duration > PerformanceThresholds.maxWidgetBuildTime) {
          _logSlowOperation(metric, PerformanceThresholds.maxWidgetBuildTime);
        }
        break;
      case 'navigation':
        if (metric.duration > PerformanceThresholds.maxNavigationTime) {
          _logSlowOperation(metric, PerformanceThresholds.maxNavigationTime);
        }
        break;
      case 'api_call':
        if (metric.duration > PerformanceThresholds.maxApiCallTime) {
          _logSlowOperation(metric, PerformanceThresholds.maxApiCallTime);
        }
        break;
      case 'database_operation':
        if (metric.duration > PerformanceThresholds.maxDatabaseOperationTime) {
          _logSlowOperation(
            metric,
            PerformanceThresholds.maxDatabaseOperationTime,
          );
        }
        break;
    }
  }

  void _logSlowOperation(PerformanceMetric metric, Duration threshold) {
    if (metric.metadata.isNotEmpty) {}
  }

  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('Performance Report - Generated: ${DateTime.now()}');
    buffer.writeln('=' * 50);

    for (final entry in _metrics.entries) {
      final metrics = entry.value;
      if (metrics.isEmpty) continue;

      final operationName = entry.key;
      final avgDuration =
          metrics
              .map((m) => m.duration.inMilliseconds)
              .reduce((a, b) => a + b) /
          metrics.length;
      final maxDuration = metrics
          .map((m) => m.duration.inMilliseconds)
          .reduce((a, b) => a > b ? a : b);
      final minDuration = metrics
          .map((m) => m.duration.inMilliseconds)
          .reduce((a, b) => a < b ? a : b);

      buffer.writeln('Operation: $operationName');
      buffer.writeln('  Calls: ${metrics.length}');
      buffer.writeln('  Avg: ${avgDuration.toStringAsFixed(2)}ms');
      buffer.writeln('  Min: ${minDuration}ms');
      buffer.writeln('  Max: ${maxDuration}ms');
      buffer.writeln();
    }

    return buffer.toString();
  }
}

class PerformanceMetric {
  final String operationName;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
    required this.metadata,
  });

  @override
  String toString() {
    return 'PerformanceMetric(operation: $operationName, duration: ${duration.inMilliseconds}ms, timestamp: $timestamp)';
  }
}

class PerformanceThresholds {
  const PerformanceThresholds();

  static const Duration maxWidgetBuildTime = Duration(milliseconds: 16);

  static const Duration maxNavigationTime = Duration(milliseconds: 100);

  static const Duration maxApiCallTime = Duration(seconds: 5);

  static const Duration maxDatabaseOperationTime = Duration(milliseconds: 100);

  static const double maxFrameDuration = 16.67;

  static const int maxMemoryUsage = 50 * 1024 * 1024;
}

extension PerformanceTracking on Object {
  Future<T> trackPerformance<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    final monitor = PerformanceMonitor();
    monitor.startTimer(operationName);

    try {
      final result = await operation();
      monitor.endTimer(operationName, metadata: metadata);
      return result;
    } catch (e) {
      monitor.endTimer(
        operationName,
        metadata: {...?metadata, 'error': e.toString()},
      );
      rethrow;
    }
  }
}
