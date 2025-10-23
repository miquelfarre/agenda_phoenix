import '../config/debug_config.dart';

class MassiveLoggingHelper {
  static bool get _isEnabled => DebugConfig.enabled;

  static void logMethodEntry({
    required String className,
    required String methodName,
    Map<String, dynamic>? parameters,
    String? additionalInfo,
  }) {
    if (!_isEnabled) return;
  }

  static void logMethodExit({
    required String className,
    required String methodName,
    dynamic result,
    String? additionalInfo,
  }) {
    if (!_isEnabled) return;
  }

  static void logStateChange({
    required String className,
    required String property,
    dynamic oldValue,
    dynamic newValue,
    String? additionalInfo,
  }) {
    if (!_isEnabled) return;
  }

  static void logListOperation({
    required String className,
    required String operation,
    required String listName,
    int? oldCount,
    int? newCount,
    List<dynamic>? addedItems,
    List<dynamic>? removedItems,
    String? additionalInfo,
  }) {
    if (!_isEnabled) return;
  }

  static void logProviderNotification({
    required String className,
    required String reason,
    String? additionalInfo,
  }) {
    if (!_isEnabled) return;
  }

  static void logAsyncStart({
    required String className,
    required String operationName,
    Map<String, dynamic>? parameters,
  }) {
    if (!_isEnabled) return;
  }

  static void logAsyncComplete({
    required String className,
    required String operationName,
    bool success = true,
    String? error,
    dynamic result,
    String? additionalInfo,
  }) {
    if (!_isEnabled) return;
  }

  static void logSync({
    required String className,
    required String syncType,
    required String dataType,
    int? localCount,
    int? serverCount,
    int? mergedCount,
    String? additionalInfo,
  }) {
    if (!_isEnabled) return;
  }

  static void logScreenLifecycle({
    required String screenName,
    required String event,
    Map<String, dynamic>? parameters,
  }) {
    if (!_isEnabled) return;
  }

  static void logCrossProvider({
    required String fromProvider,
    required String toProvider,
    required String message,
    String? additionalInfo,
  }) {
    if (!_isEnabled) return;
  }
}
