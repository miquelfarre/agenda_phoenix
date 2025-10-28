import '../mixins/error_handling_mixin.dart';

abstract class BaseService with ErrorHandlingMixin {
  bool _isInitialized = false;

  static dynamic testApiService;

  @override
  String get serviceName;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await onInitialize();
      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> onInitialize();

  void requireInitialized() {
    if (!_isInitialized) {
      throw StateError('$serviceName must be initialized before use');
    }
  }

  void reset() {
    _isInitialized = false;
    onReset();
  }

  void onReset() {}

  dynamic get apiService => testApiService ?? getDefaultApiService();

  dynamic getDefaultApiService();

  Future<T> executeWhenInitialized<T>(String operationName, Future<T> Function() operation) async {
    requireInitialized();
    return await withErrorHandling(operationName, operation);
  }

  T executeSyncWhenInitialized<T>(String operationName, T Function() operation) {
    requireInitialized();
    return withErrorHandlingSync(operationName, operation);
  }
}
