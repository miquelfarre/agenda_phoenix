mixin ErrorHandlingMixin {
  String get serviceName => runtimeType.toString();

  Future<T> withErrorHandling<T>(String operationName, Future<T> Function() operation, {String? customMessage, bool shouldRethrow = true, T? defaultValue}) async {
    try {
      return await operation();
    } catch (e) {
      if (shouldRethrow) {
        rethrow;
      }

      if (defaultValue != null) {
        return defaultValue;
      }

      rethrow;
    }
  }

  T withErrorHandlingSync<T>(String operationName, T Function() operation, {String? customMessage, bool shouldRethrow = true, T? defaultValue}) {
    try {
      return operation();
    } catch (e) {
      if (shouldRethrow) {
        rethrow;
      }

      if (defaultValue != null) {
        return defaultValue;
      }

      rethrow;
    }
  }

  Never logAndRethrow(String context, Object error, [StackTrace? stackTrace]) {
    throw error;
  }
}
