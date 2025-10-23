import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/navigation_service.dart';
import '../../core/monitoring/performance_monitor.dart';

mixin BaseScreenState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  NavigationService get navigationService => NavigationService.instance;

  String get screenName => runtimeType.toString();

  late final DateTime _screenInitTime;

  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  PerformanceMonitor get performanceMonitor => _performanceMonitor;

  @override
  void initState() {
    super.initState();
    _screenInitTime = DateTime.now();
    _performanceMonitor.startTimer('screen_init_$screenName');
    _logScreenInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onScreenReady();
    });
  }

  @override
  void dispose() {
    _logScreenDispose();
    super.dispose();
  }

  void onScreenReady() {
    _performanceMonitor.endTimer(
      'screen_init_$screenName',
      metadata: {
        'screen_name': screenName,
        'init_duration_ms': DateTime.now()
            .difference(_screenInitTime)
            .inMilliseconds,
      },
    );
    _logScreenReady();
  }

  void setLoading(bool loading) {
    if (mounted && _isLoading != loading) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void setError(String? error) {
    if (mounted && _errorMessage != error) {
      setState(() {
        _errorMessage = error;
      });
    }
  }

  void clearError() {
    setError(null);
  }

  void showLoading() {
    setLoading(true);
  }

  void hideLoading() {
    setLoading(false);
  }

  Future<R?> handleAsyncOperation<R>(
    Future<R> Function() operation, {
    String? errorPrefix,
    bool showLoading = true,
    bool clearErrorFirst = true,
  }) async {
    if (clearErrorFirst) clearError();
    if (showLoading) this.showLoading();

    try {
      final result = await operation();
      if (showLoading) hideLoading();
      return result;
    } catch (e) {
      if (showLoading) hideLoading();
      final errorMsg = errorPrefix != null ? '$errorPrefix: $e' : e.toString();
      setError(errorMsg);
      return null;
    }
  }

  void showErrorDialog(String message, {String? title}) {
    navigationService.showAlert(message, title: title ?? 'Error');
  }

  void showSuccessMessage(String message) {
    navigationService.showAlert(message, title: 'Success');
  }

  Future<R?> navigateToScreen<R extends Object?>(
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) async {
    return await _performanceMonitor.trackPerformance(
      'navigation',
      () async {
        _logNavigation(routeName, replace);

        if (replace) {
          return navigationService.pushReplacementNamed<R, void>(
            routeName,
            arguments: arguments,
          );
        } else {
          return navigationService.pushNamed<R>(
            routeName,
            arguments: arguments,
          );
        }
      },
      metadata: {
        'from_screen': screenName,
        'to_screen': routeName,
        'replace': replace,
      },
    );
  }

  void goBack<R extends Object?>([R? result]) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop<R>(result);
    } else {}
  }

  bool canGoBack() {
    return Navigator.of(context).canPop();
  }

  Future<void> refreshScreen() async {
    await handleAsyncOperation(
      () => onRefresh(),
      errorPrefix: 'Failed to refresh screen',
    );
  }

  Future<void> onRefresh() async {}

  Future<void> onPullToRefresh() async {
    await refreshScreen();
  }

  Widget buildErrorWidget({
    String? message,
    VoidCallback? onRetry,
    bool showRetry = true,
  }) {
    final errorMsg = message ?? errorMessage ?? 'An error occurred';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildLoadingWidget({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 16),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildEmptyWidget({
    required String message,
    String? actionText,
    VoidCallback? onAction,
    IconData? icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? CupertinoIcons.square_stack_3d_up,
              size: 64,
              color: CupertinoColors.secondaryLabel,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: onAction,
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _logScreenInit() {}

  void _logScreenReady() {}

  void _logScreenDispose() {}

  void _logNavigation(String routeName, bool replace) {}

  void logCustomMetric(String metricName, dynamic value) {
    _performanceMonitor.recordMetric(
      PerformanceMetric(
        operationName: '${screenName}_$metricName',
        duration: Duration.zero,
        timestamp: DateTime.now(),
        metadata: {
          'screen_name': screenName,
          'metric_name': metricName,
          'value': value,
        },
      ),
    );
  }

  String getPerformanceReport() {
    return _performanceMonitor.generateReport();
  }

  Widget trackWidgetBuild(Widget Function() builder) {
    final stopwatch = Stopwatch()..start();
    final widget = builder();
    stopwatch.stop();

    _performanceMonitor.recordMetric(
      PerformanceMetric(
        operationName: 'widget_build',
        duration: stopwatch.elapsed,
        timestamp: DateTime.now(),
        metadata: {
          'screen_name': screenName,
          'widget_type': widget.runtimeType.toString(),
        },
      ),
    );

    return widget;
  }
}
