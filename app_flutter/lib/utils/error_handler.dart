import '../config/debug_config.dart';
import '../utils/app_exceptions.dart';

class ErrorHandler {
  static final Map<String, int> _errorCounts = <String, int>{};

  static AppException handleServiceError(
    Object error, {
    required String operation,
    required String tag,
    int defaultCode = 2000,
  }) {
    final errorMessage = error.toString();
    final errorKey = '$tag:$operation';

    _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;

    if (error is AppException) {
      return error;
    }

    if (error is InitializationException) {
      return AppException(code: 1001, message: error.message, tag: tag);
    }

    if (error is NotFoundException) {
      return AppException(code: 1002, message: error.message, tag: tag);
    }

    if (error is ValidationException) {
      return AppException(code: 1003, message: error.message, tag: tag);
    }

    return AppException(code: defaultCode, message: errorMessage, tag: tag);
  }

  static void handleProviderError(
    Object error, {
    required String operation,
    required String tag,
    required Function(String) setErrorCallback,
    String? fallbackMessage,
  }) {
    final appException = handleServiceError(
      error,
      operation: operation,
      tag: tag,
    );

    final userMessage = fallbackMessage ?? appException.message;
    setErrorCallback(userMessage);
  }

  static String getUserFriendlyMessage(AppException exception) {
    switch (exception.code) {
      case 1001:
        return 'Service not initialized. Please restart the app.';
      case 1002:
        return 'Item not found. It may have been deleted.';
      case 1003:
        return 'Invalid input. Please check your data.';
      case 2000:
        return 'An error occurred. Please try again.';
      default:
        return exception.message;
    }
  }

  static void logDebugInfo(
    String operation, {
    required String tag,
    Map<String, dynamic>? context,
  }) {
    if (!DebugConfig.enabled) return;

    context != null
        ? context.entries.map((e) => '${e.key}: ${e.value}').join(', ')
        : 'no context';
  }

  static Map<String, int> getErrorStatistics() {
    return Map<String, int>.from(_errorCounts);
  }

  static void clearErrorStatistics() {
    _errorCounts.clear();
  }

  static bool isFailingFrequently(String tag, String operation) {
    final errorKey = '$tag:$operation';
    final count = _errorCounts[errorKey] ?? 0;
    return count >= 3;
  }
}
