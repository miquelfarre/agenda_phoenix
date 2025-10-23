import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/navigation_service.dart';
import '../../ui/helpers/l10n/l10n_helpers.dart';

mixin BaseScreenState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  NavigationService get navigationService => NavigationService.instance;

  String get screenName => runtimeType.toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onScreenReady();
    });
  }

  void onScreenReady() {}

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
    navigationService.showAlert(message, title: title ?? context.l10n.error);
  }

  void showSuccessMessage(String message) {
    navigationService.showAlert(message, title: context.l10n.success);
  }

  Future<R?> navigateToScreen<R extends Object?>(
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) async {
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
      errorPrefix: context.l10n.failedToRefresh,
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
    final errorMsg = message ?? errorMessage ?? context.l10n.anErrorOccurred;

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
                child: Text(context.l10n.retry),
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
}
