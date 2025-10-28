abstract class IApiClient {
  Future<List<Map<String, dynamic>>> fetchMyEvents({int? userId, String? status, DateTime? fromDate, DateTime? toDate});

  Future<List<Map<String, dynamic>>> fetchPublicEvents({int? userId, int? limit, int? offset});

  Future<List<Map<String, dynamic>>> fetchEvents();

  Future<String> fetchEventsHash(int userId);

  Future<List<Map<String, dynamic>>> searchPublicUsers(String query);

  Future<List<Map<String, dynamic>>> fetchUserContacts(int userId);

  Future<String> fetchContactsHash(int userId);

  Future<void> grantGroupAdminPermission(int groupId, int userId);

  Future<void> revokeGroupAdminPermission(int groupId, int userId);

  Future<List<Map<String, dynamic>>> fetchUserGroups(int userId);

  Future<List<Map<String, dynamic>>> fetchGroups();

  Future<String> fetchGroupsHash(int userId);

  Future<List<Map<String, dynamic>>> fetchInvitations(int userId);

  Future<List<Map<String, dynamic>>> fetchEventInvitations(int eventId);

  Future<void> cancelInvitation(int invitationId);

  Future<String> fetchInvitationsHash(int userId);

  Future<List<Map<String, dynamic>>> fetchUserSubscriptions(int userId);

  Future<List<Map<String, dynamic>>> fetchSubscriptions(int userId);

  Future<String> fetchSubscriptionsHash(int userId);

  Future<List<Map<String, dynamic>>> fetchNotifications(int userId);

  Future<String> fetchNotificationsHash(int userId);

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams});

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body});

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body});

  Future<dynamic> delete(String endpoint);

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body});

  bool get isOnline;

  void setBaseUrl(String baseUrl);

  void setAuthToken(String token);

  String? get authToken;
}

abstract class ApiClientFactory {
  static IApiClient? _instance;

  static IApiClient get instance {
    if (_instance == null) {
      throw StateError('ApiClient not initialized. Call ApiClientFactory.initialize() first.');
    }
    return _instance!;
  }

  static void initialize(IApiClient implementation) {
    _instance = implementation;
  }

  static void reset() {
    _instance = null;
  }
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final int statusCode;
  final bool isSuccess;

  const ApiResponse._({this.data, this.error, required this.statusCode, required this.isSuccess});

  factory ApiResponse.success(T data, int statusCode) {
    return ApiResponse._(data: data, statusCode: statusCode, isSuccess: true);
  }

  factory ApiResponse.error(String error, int statusCode) {
    return ApiResponse._(error: error, statusCode: statusCode, isSuccess: false);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;
  final Map<String, dynamic>? context;

  const ApiException({required this.message, this.statusCode, this.endpoint, this.context});

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');

    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }

    if (endpoint != null) {
      buffer.write(' (Endpoint: $endpoint)');
    }

    if (context != null && context!.isNotEmpty) {
      buffer.write(' (Context: $context)');
    }

    return buffer.toString();
  }
}
