library;

class AuthenticationException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AuthenticationException(this.message, {this.code, this.details});

  @override
  String toString() {
    if (code != null) {
      return 'AuthenticationException [$code]: $message';
    }
    return 'AuthenticationException: $message';
  }
}

class AuthenticationRequiredException extends AuthenticationException {
  AuthenticationRequiredException([String? message]) : super(message ?? 'Authentication required for this operation', code: 'AUTH_REQUIRED');
}

class TestModeException extends AuthenticationException {
  TestModeException(super.message, {String? reason}) : super(code: 'TEST_MODE_ERROR', details: reason);
}

class TestModeNotAllowedException extends TestModeException {
  TestModeNotAllowedException(String reason) : super('Test mode not allowed', reason: reason);
}

class TestCredentialsException extends TestModeException {
  TestCredentialsException(String reason) : super('Test credentials error', reason: reason);
}
