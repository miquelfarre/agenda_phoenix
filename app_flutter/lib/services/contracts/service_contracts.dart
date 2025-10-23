import 'dart:async';

abstract class IRepository<T, ID> {
  Future<T?> getById(ID id);

  Future<List<T>> getAll();

  Future<List<T>> getWhere(Map<String, dynamic> filters);

  Future<T> create(Map<String, dynamic> data);

  Future<T> update(ID id, Map<String, dynamic> data);

  Future<void> delete(ID id);

  Future<bool> exists(ID id);

  Future<int> count();
}

abstract class IOfflineCapable {
  Future<OfflineOperation> enqueueOperation(OfflineOperationRequest request);

  bool get hasPendingOperations;

  Stream<OfflineOperationStatus> get operationStream;

  Future<void> retryFailedOperations();

  Future<void> clearCompletedOperations();

  Future<List<OfflineOperation>> getOperationHistory();
}

abstract class ICacheManager<T> {
  T? getCached(String key);

  void cache(String key, T item, {Duration? ttl});

  void invalidate(String key);

  void clearAll();

  bool isExpired(String key);

  CacheStatistics get statistics;

  void configure(CacheConfiguration config);
}

abstract class ISyncable {
  Future<SyncResult> syncToServer();

  Future<SyncResult> syncFromServer();

  Future<SyncResult> fullSync();

  DateTime? get lastSyncTime;

  bool get isSyncing;

  bool get hasPendingSync;

  Stream<SyncStatus> get syncStream;
}

abstract class IErrorHandler {
  Future<void> handleError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  });

  Future<void> reportError(ErrorReport report);

  bool shouldRetry(dynamic error);

  Duration getRetryDelay(dynamic error, int attemptNumber);

  String getUserMessage(dynamic error);
}

abstract class IValidator<T> {
  ValidationResult validate(T data);

  FieldValidationResult validateField(String fieldName, dynamic value);

  List<ValidationRule> get rules;

  void addRule(ValidationRule rule);

  void removeRule(String ruleName);
}

abstract class IDataTransformer<TSource, TTarget> {
  TTarget transform(TSource source);

  List<TTarget> transformList(List<TSource> sources);

  TSource? reverseTransform(TTarget target);

  bool canTransform(dynamic data);
}

abstract class IBaseService {
  String get serviceName;

  Future<void> initialize();

  Future<void> dispose();

  bool get isInitialized;

  bool get isDisposed;

  Future<HealthCheckResult> healthCheck();
}

abstract class IEventEmitter {
  void emit(String eventName, dynamic data);

  StreamSubscription<dynamic> on(
    String eventName,
    void Function(dynamic data) handler,
  );

  StreamSubscription<dynamic> once(
    String eventName,
    void Function(dynamic data) handler,
  );

  void removeAllListeners(String eventName);

  List<String> get eventNames;
}

abstract class IServiceLocator {
  void register<T>(T service, {String? name});

  void registerFactory<T>(T Function() factory, {String? name});

  void registerSingleton<T>(T service, {String? name});

  T get<T>({String? name});

  bool isRegistered<T>({String? name});

  void unregister<T>({String? name});

  void clear();
}

class OfflineOperation {
  final String id;
  final OfflineOperationType type;
  final String module;
  final Map<String, dynamic> data;
  final int priority;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final OfflineOperationStatus status;
  final int retryCount;
  final dynamic error;

  const OfflineOperation({
    required this.id,
    required this.type,
    required this.module,
    required this.data,
    required this.priority,
    required this.createdAt,
    this.scheduledAt,
    required this.status,
    this.retryCount = 0,
    this.error,
  });
}

class OfflineOperationRequest {
  final OfflineOperationType type;
  final String module;
  final Map<String, dynamic> data;
  final int priority;
  final DateTime? scheduledAt;
  final Map<String, dynamic>? metadata;

  const OfflineOperationRequest({
    required this.type,
    required this.module,
    required this.data,
    this.priority = 0,
    this.scheduledAt,
    this.metadata,
  });
}

enum OfflineOperationType { create, update, delete, sync, custom }

enum OfflineOperationStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
  retrying,
}

class CacheStatistics {
  final int totalItems;
  final int expiredItems;
  final double hitRate;
  final double missRate;
  final int totalSize;
  final DateTime lastAccess;

  const CacheStatistics({
    required this.totalItems,
    required this.expiredItems,
    required this.hitRate,
    required this.missRate,
    required this.totalSize,
    required this.lastAccess,
  });
}

class CacheConfiguration {
  final Duration defaultTtl;
  final int maxItems;
  final int maxSize;
  final bool autoCleanup;
  final Duration cleanupInterval;

  const CacheConfiguration({
    required this.defaultTtl,
    required this.maxItems,
    required this.maxSize,
    required this.autoCleanup,
    required this.cleanupInterval,
  });
}

class SyncResult {
  final bool success;
  final int itemsSynced;
  final int conflicts;
  final Duration duration;
  final List<SyncError> errors;
  final DateTime timestamp;

  const SyncResult({
    required this.success,
    required this.itemsSynced,
    required this.conflicts,
    required this.duration,
    required this.errors,
    required this.timestamp,
  });
}

enum SyncStatus { idle, syncing, completed, failed, conflict }

class SyncError {
  final String entityType;
  final String entityId;
  final String message;
  final SyncErrorType type;

  const SyncError({
    required this.entityType,
    required this.entityId,
    required this.message,
    required this.type,
  });
}

enum SyncErrorType {
  networkError,
  serverError,
  conflictError,
  validationError,
  unknownError,
}

class ErrorReport {
  final dynamic error;
  final StackTrace? stackTrace;
  final String? context;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final ErrorSeverity severity;

  const ErrorReport({
    required this.error,
    this.stackTrace,
    this.context,
    this.metadata,
    required this.timestamp,
    required this.severity,
  });
}

enum ErrorSeverity { low, medium, high, critical }

class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;
  final Map<String, FieldValidationResult> fieldResults;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.fieldResults,
  });

  factory ValidationResult.valid() =>
      const ValidationResult(isValid: true, errors: [], fieldResults: {});

  factory ValidationResult.invalid(List<ValidationError> errors) =>
      ValidationResult(isValid: false, errors: errors, fieldResults: {});
}

class FieldValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String fieldName;

  const FieldValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.fieldName,
  });

  factory FieldValidationResult.valid(String fieldName) =>
      FieldValidationResult(isValid: true, fieldName: fieldName);

  factory FieldValidationResult.invalid(
    String fieldName,
    String errorMessage,
  ) => FieldValidationResult(
    isValid: false,
    errorMessage: errorMessage,
    fieldName: fieldName,
  );
}

class ValidationError {
  final String message;
  final String? fieldName;
  final dynamic value;
  final String ruleName;

  const ValidationError({
    required this.message,
    this.fieldName,
    this.value,
    required this.ruleName,
  });
}

abstract class ValidationRule {
  String get name;
  String get description;
  bool apply(dynamic value);
  String getErrorMessage(dynamic value);
}

class HealthCheckResult {
  final String serviceName;
  final HealthStatus status;
  final List<HealthCheckDetail> details;
  final DateTime timestamp;
  final Duration checkDuration;

  const HealthCheckResult({
    required this.serviceName,
    required this.status,
    required this.details,
    required this.timestamp,
    required this.checkDuration,
  });
}

enum HealthStatus { healthy, degraded, unhealthy, unknown }

class HealthCheckDetail {
  final String component;
  final HealthStatus status;
  final String? message;
  final Map<String, dynamic>? metadata;

  const HealthCheckDetail({
    required this.component,
    required this.status,
    this.message,
    this.metadata,
  });
}
