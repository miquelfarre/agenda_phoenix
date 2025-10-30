class AppException implements Exception {
  final int code;

  final String tag;

  final String message;

  final Object? payload;

  const AppException({required this.code, required this.tag, required this.message, this.payload});

  factory AppException.unknown(Object? error, {String? tag, int code = 1000}) {
    return AppException(code: code, tag: tag ?? 'UNKNOWN', message: error?.toString() ?? 'ERR_UNKNOWN', payload: error);
  }

  @override
  String toString() => 'AppException[$code][$tag]: $message';

  String toLogString() => '[$tag]#${code.toString().padLeft(4, '0')}: $message';

  void log({StackTrace? stackTrace}) {
    '$tag#$code';
  }
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException({super.code = 1401, super.message = 'ERR_PERMISSION_DENIED'}) : super(tag: 'AUTH');
}

class NetworkException extends AppException {
  const NetworkException({super.code = 1200, super.message = 'ERR_NETWORK'}) : super(tag: 'NETWORK');
}

class ApiException extends AppException {
  final int? statusCode;

  ApiException(String message, {this.statusCode, super.code = 1300}) : super(tag: 'API', message: '$message (http:${statusCode ?? 'n/a'})');
}

class DatabaseException extends AppException {
  const DatabaseException({super.code = 1500, super.message = 'ERR_DATABASE'}) : super(tag: 'DATABASE');
}

class ValidationException extends AppException {
  const ValidationException({required super.message, super.code = 1100}) : super(tag: 'VALIDATION');
}

class NotFoundException extends AppException {
  const NotFoundException({super.code = 1404, super.message = 'ERR_NOT_FOUND'}) : super(tag: 'NOT_FOUND');
}

class OfflineException extends AppException {
  const OfflineException({super.code = 1201, super.message = 'ERR_OFFLINE'}) : super(tag: 'OFFLINE');
}

class InitializationException extends AppException {
  const InitializationException({super.code = 1600, super.message = 'ERR_NOT_INITIALIZED'}) : super(tag: 'INIT');
}

class ConflictException extends AppException {
  const ConflictException({super.code = 1700, super.message = 'ERR_CONFLICT'}) : super(tag: 'CONFLICT');
}

class EventCreationException extends AppException {
  const EventCreationException({super.code = 1800, super.message = 'ERR_EVENT_CREATION_FAILED'}) : super(tag: 'EVENT_CREATE');
}

AppException toAppException(Object? e, {String? tag}) {
  if (e == null) return AppException.unknown(null, tag: tag);
  if (e is AppException) return e;
  if (e is PermissionDeniedException) return e;
  if (e is ApiException) return e;

  final type = e.runtimeType.toString().toLowerCase();
  if (type.contains('socket') || type.contains('http') || type.contains('network')) {
    return NetworkException(message: e.toString());
  }

  return AppException.unknown(e, tag: tag);
}
