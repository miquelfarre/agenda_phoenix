import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/monitoring/performance_monitor.dart';

enum ScreenLifecycleState {
  initializing,
  loading,
  ready,
  paused,
  resumed,
  disposing,
  disposed,
}

class ScreenLifecycleEvent {
  final ScreenLifecycleState state;
  final DateTime timestamp;
  final Duration? duration;
  final Map<String, dynamic> metadata;

  const ScreenLifecycleEvent({
    required this.state,
    required this.timestamp,
    this.duration,
    this.metadata = const {},
  });
}

mixin ScreenLifecycleMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, WidgetsBindingObserver {
  ScreenLifecycleState _lifecycleState = ScreenLifecycleState.initializing;
  ScreenLifecycleState get lifecycleState => _lifecycleState;

  final Map<ScreenLifecycleState, DateTime> _lifecycleTimestamps = {};

  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  final StreamController<ScreenLifecycleEvent> _lifecycleController =
      StreamController<ScreenLifecycleEvent>.broadcast();

  Stream<ScreenLifecycleEvent> get lifecycleEventStream =>
      _lifecycleController.stream;

  String get screenName => runtimeType.toString();

  @override
  void initState() {
    super.initState();
    _transitionToState(ScreenLifecycleState.initializing);

    WidgetsBinding.instance.addObserver(this);

    _performanceMonitor.startTimer('screen_lifecycle_$screenName');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transitionToState(ScreenLifecycleState.loading);
      onScreenInitialized();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onDependenciesChanged();
  }

  @override
  void dispose() {
    _transitionToState(ScreenLifecycleState.disposing);

    _performanceMonitor.endTimer(
      'screen_lifecycle_$screenName',
      metadata: {
        'screen_name': screenName,
        'total_lifetime_ms': _getTotalLifetime().inMilliseconds,
        'states_visited': _lifecycleTimestamps.keys.map((e) => e.name).toList(),
      },
    );

    WidgetsBinding.instance.removeObserver(this);
    onScreenDisposing();

    _lifecycleController.close();
    _transitionToState(ScreenLifecycleState.disposed);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        if (_lifecycleState != ScreenLifecycleState.disposing &&
            _lifecycleState != ScreenLifecycleState.disposed) {
          _transitionToState(ScreenLifecycleState.resumed);
          onScreenResumed();
        }
        break;
      case AppLifecycleState.paused:
        if (_lifecycleState != ScreenLifecycleState.disposing &&
            _lifecycleState != ScreenLifecycleState.disposed) {
          _transitionToState(ScreenLifecycleState.paused);
          onScreenPaused();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _transitionToState(ScreenLifecycleState newState) {
    if (_lifecycleState == newState) return;

    final previousState = _lifecycleState;
    final now = DateTime.now();
    final previousTimestamp = _lifecycleTimestamps[previousState];
    final duration = previousTimestamp != null
        ? now.difference(previousTimestamp)
        : null;

    _lifecycleState = newState;
    _lifecycleTimestamps[newState] = now;

    _lifecycleController.add(
      ScreenLifecycleEvent(
        state: newState,
        timestamp: now,
        duration: duration,
        metadata: {
          'screen_name': screenName,
          'previous_state': previousState.name,
        },
      ),
    );

    if (duration != null) {
      _performanceMonitor.recordMetric(
        PerformanceMetric(
          operationName:
              'screen_state_${previousState.name}_to_${newState.name}',
          duration: duration,
          timestamp: now,
          metadata: {
            'screen_name': screenName,
            'from_state': previousState.name,
            'to_state': newState.name,
          },
        ),
      );

      if (duration.inMilliseconds > 100) {}
    }
  }

  void setScreenReady() {
    if (_lifecycleState == ScreenLifecycleState.loading) {
      _transitionToState(ScreenLifecycleState.ready);
      onScreenReady();
    }
  }

  Duration _getTotalLifetime() {
    final initTime = _lifecycleTimestamps[ScreenLifecycleState.initializing];
    if (initTime == null) return Duration.zero;
    return DateTime.now().difference(initTime);
  }

  Duration getTimeInState(ScreenLifecycleState state) {
    final startTime = _lifecycleTimestamps[state];
    if (startTime == null) return Duration.zero;

    DateTime? endTime;
    final stateIndex = ScreenLifecycleState.values.indexOf(state);
    for (int i = stateIndex + 1; i < ScreenLifecycleState.values.length; i++) {
      final nextState = ScreenLifecycleState.values[i];
      final nextTime = _lifecycleTimestamps[nextState];
      if (nextTime != null) {
        endTime = nextTime;
        break;
      }
    }

    endTime ??= DateTime.now();
    return endTime.difference(startTime);
  }

  bool get isScreenActive {
    return _lifecycleState == ScreenLifecycleState.ready ||
        _lifecycleState == ScreenLifecycleState.resumed;
  }

  bool get isScreenLoading {
    return _lifecycleState == ScreenLifecycleState.loading;
  }

  bool get isScreenDisposed {
    return _lifecycleState == ScreenLifecycleState.disposed ||
        _lifecycleState == ScreenLifecycleState.disposing;
  }

  String generateLifecycleReport() {
    final buffer = StringBuffer();
    buffer.writeln('Screen Lifecycle Report: $screenName');
    buffer.writeln('Current State: ${_lifecycleState.name}');
    buffer.writeln('Total Lifetime: ${_getTotalLifetime().inMilliseconds}ms');
    buffer.writeln('States:');

    for (final state in ScreenLifecycleState.values) {
      final timestamp = _lifecycleTimestamps[state];
      if (timestamp != null) {
        final duration = getTimeInState(state);
        buffer.writeln(
          '  ${state.name}: ${duration.inMilliseconds}ms (at ${timestamp.toIso8601String()})',
        );
      }
    }

    return buffer.toString();
  }

  void onScreenInitialized() {}

  void onDependenciesChanged() {}

  void onScreenReady() {}

  void onScreenResumed() {}

  void onScreenPaused() {}

  void onScreenDisposing() {}

  void executeIfActive(VoidCallback operation) {
    if (isScreenActive && mounted) {
      operation();
    }
  }

  Future<R?> executeAsyncIfActive<R>(Future<R> Function() operation) async {
    if (isScreenActive && mounted) {
      return await operation();
    }
    return null;
  }

  void addCustomLifecycleEvent(
    String eventName, {
    Map<String, dynamic>? metadata,
  }) {
    _performanceMonitor.recordMetric(
      PerformanceMetric(
        operationName: 'screen_custom_$eventName',
        duration: Duration.zero,
        timestamp: DateTime.now(),
        metadata: {
          'screen_name': screenName,
          'event_name': eventName,
          'lifecycle_state': _lifecycleState.name,
          ...?metadata,
        },
      ),
    );
  }
}
