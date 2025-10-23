import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';
import '../config/debug_config.dart';
import 'supabase_service.dart';
import '../utils/app_exceptions.dart' as app_exceptions;
import 'contracts/api_client_contract.dart';

class ApiClient implements IApiClient {
  final http.Client _client = http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    // Get JWT token from Supabase session
    try {
      final session = SupabaseService.instance.client.auth.currentSession;
      if (session != null && session.accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${session.accessToken}';
        DebugConfig.info('Added JWT token to request headers', tag: 'API');
      } else {
        DebugConfig.info('No Supabase session found - request will be unauthenticated', tag: 'API');
      }
    } catch (e) {
      DebugConfig.error('Failed to get Supabase session: $e', tag: 'API');
    }

    return headers;
  }

  Uri _buildUri(String path, {Map<String, dynamic>? queryParams}) {
    final params = Map<String, dynamic>.from(queryParams ?? {});

    // Note: current_user_id is no longer sent as query param
    // User identity is now determined from JWT token in Authorization header

    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    if (params.isNotEmpty) {
      final nonNullParams = params.map(
        (key, value) => MapEntry(key, value?.toString()),
      )..removeWhere((key, value) => value == null);
      return uri.replace(queryParameters: nonNullParams);
    }
    return uri;
  }

  dynamic _handleResponse(http.Response response) {
    final rawBody = utf8.decode(response.bodyBytes);
    dynamic body;
    try {
      body = jsonDecode(rawBody);
    } catch (_) {
      body = rawBody;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String errorMessage = 'Unknown API error';
    if (body is Map<String, dynamic> && body.containsKey('detail')) {
      final detail = body['detail'];
      if (detail is String) {
        errorMessage = detail;
      } else if (detail is Map<String, dynamic>) {
        if (detail.containsKey('message')) {
          errorMessage = detail['message'];
        } else {
          errorMessage = detail.toString();
        }
      } else if (detail is List) {
        final messages = detail
            .map((e) {
              if (e is Map<String, dynamic>) {
                final loc = e['loc'] is List
                    ? (e['loc'] as List).join('.')
                    : '';
                final msg = e['msg'] ?? 'Validation error';
                return loc.isNotEmpty ? '$loc: $msg' : msg;
              }
              return e.toString();
            })
            .join(', ');
        errorMessage = messages.isNotEmpty ? messages : 'Validation error';
      } else {
        errorMessage = detail.toString();
      }
    } else if (body is String) {
      errorMessage = body;
    }

    DebugConfig.error(
      'API Error: $errorMessage (${response.statusCode})',
      tag: 'API',
    );

    throw app_exceptions.ApiException(
      errorMessage,
      statusCode: response.statusCode,
    );
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    final uri = _buildUri(path, queryParams: queryParams);
    final headers = await _getHeaders();

    DebugConfig.info('GET: $uri', tag: 'API');

    try {
      final response = await _client.get(uri, headers: headers);
      return _handleResponse(response);
    } on SocketException {
      throw const app_exceptions.NetworkException();
    } on HttpException {
      throw app_exceptions.ApiException('Could not find the server');
    } on FormatException {
      throw app_exceptions.ApiException('Bad response format');
    }
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = await _getHeaders();

    DebugConfig.info('POST: $uri', tag: 'API');

    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw const app_exceptions.NetworkException();
    } on HttpException {
      throw app_exceptions.ApiException('Could not find the server');
    } on FormatException {
      throw app_exceptions.ApiException('Bad response format');
    }
  }

  @override
  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = await _getHeaders();

    DebugConfig.info('PUT: $uri', tag: 'API');

    try {
      final response = await _client.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw const app_exceptions.NetworkException();
    } on HttpException {
      throw app_exceptions.ApiException('Could not find the server');
    } on FormatException {
      throw app_exceptions.ApiException('Bad response format');
    }
  }

  @override
  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams: queryParams);
    final headers = await _getHeaders();

    DebugConfig.info('DELETE: $uri', tag: 'API');

    try {
      final response = await _client.delete(uri, headers: headers);
      return _handleResponse(response);
    } on SocketException {
      throw const app_exceptions.NetworkException();
    } on HttpException {
      throw app_exceptions.ApiException('Could not find the server');
    } on FormatException {
      throw app_exceptions.ApiException('Bad response format');
    }
  }

  @override
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = await _getHeaders();

    DebugConfig.info('PATCH: $uri', tag: 'API');

    try {
      final response = await _client.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw const app_exceptions.NetworkException();
    } on HttpException {
      throw app_exceptions.ApiException('Could not find the server');
    } on FormatException {
      throw app_exceptions.ApiException('Bad response format');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUsers({
    bool? isPublic,
    bool? enriched,
    int? limit,
    int? offset,
  }) async {
    final result = await get(
      '/users',
      queryParams: {
        if (isPublic != null) 'public': isPublic,
        if (enriched != null) 'enriched': enriched,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> fetchUser(int userId, {bool? enriched}) async {
    final result = await get(
      '/users/$userId',
      queryParams: {if (enriched != null) 'enriched': enriched},
    );
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> fetchUserStats(int userId) async {
    final result = await get('/users/$userId/stats');
    return result as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserEvents(
    int userId, {
    int? currentUserId,
  }) async {
    final result = await get(
      '/users/$userId/events',
      queryParams: {
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final result = await post('/users', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateUser(
    int userId,
    Map<String, dynamic> data, {
    required int currentUserId,
  }) async {
    final result = await put('/users/$userId', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> deleteUser(int userId, {required int currentUserId}) async {
    await delete('/users/$userId');
  }

  @override
  Future<Map<String, dynamic>> subscribeToUser(
    int userId,
    int targetUserId,
  ) async {
    final result = await post('/users/$userId/subscribe/$targetUserId');
    return result as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchContacts({
    required int currentUserId,
  }) async {
    final result = await get('/contacts');
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> fetchContact(
    int contactId, {
    required int currentUserId,
  }) async {
    final result = await get('/contacts/$contactId');
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createContact(
    Map<String, dynamic> data, {
    required int currentUserId,
  }) async {
    final result = await post('/contacts', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateContact(
    int contactId,
    Map<String, dynamic> data, {
    required int currentUserId,
  }) async {
    final result = await put('/contacts/$contactId', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> deleteContact(
    int contactId, {
    required int currentUserId,
  }) async {
    await delete('/contacts/$contactId');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEvents({
    int? ownerId,
    int? calendarId,
    int? currentUserId,
  }) async {
    final result = await get(
      '/events',
      queryParams: {
        if (ownerId != null) 'owner_id': ownerId,
        if (calendarId != null) 'calendar_id': calendarId,
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> fetchEvent(
    int eventId, {
    int? currentUserId,
  }) async {
    final result = await get(
      '/events/$eventId',
      queryParams: {
      },
    );
    return result as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEventInteractions(
    int eventId, {
    int? currentUserId,
  }) async {
    final result = await get(
      '/api/v1/events/$eventId/interactions',
      queryParams: {
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEventInteractionsEnriched(
    int eventId, {
    int? currentUserId,
  }) async {
    final result = await get(
      '/api/v1/events/$eventId/interactions-enriched',
      queryParams: {
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAvailableInvitees(
    int eventId, {
    int? currentUserId,
  }) async {
    final result = await get(
      '/events/$eventId/available-invitees',
      queryParams: {
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEventCancellations({
    int? currentUserId,
  }) async {
    final result = await get(
      '/events/cancellations',
      queryParams: {
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> createEvent(
    Map<String, dynamic> data, {
    bool force = false,
  }) async {
    final result = await post('/events', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> markCancellationViewed(
    int cancellationId, {
    int? currentUserId,
  }) async {
    await post('/events/cancellations/$cancellationId/view');
  }

  @override
  Future<Map<String, dynamic>> updateEvent(
    int eventId,
    Map<String, dynamic> data, {
    int? currentUserId,
    bool force = false,
  }) async {
    final result = await put('/events/$eventId', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> deleteEvent(int eventId, {int? currentUserId}) async {
    await delete('/events/$eventId');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchInteractions({
    int? eventId,
    int? userId,
    String? interactionType,
    String? status,
    int? currentUserId,
  }) async {
    final result = await get(
      '/interactions',
      queryParams: {
        if (eventId != null) 'event_id': eventId,
        if (userId != null) 'user_id': userId,
        if (interactionType != null) 'interaction_type': interactionType,
        if (status != null) 'status': status,
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> fetchInteraction(
    int interactionId, {
    int? currentUserId,
  }) async {
    final result = await get(
      '/interactions/$interactionId',
      queryParams: {
      },
    );
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createInteraction(
    Map<String, dynamic> data, {
    bool force = false,
  }) async {
    final result = await post('/interactions', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateInteraction(
    int interactionId,
    Map<String, dynamic> data, {
    int? currentUserId,
  }) async {
    final result = await put('/interactions/$interactionId', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> patchInteraction(
    int interactionId,
    Map<String, dynamic> data, {
    bool force = false,
  }) async {
    final result = await patch('/interactions/$interactionId', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> deleteInteraction(
    int interactionId, {
    int? currentUserId,
  }) async {
    await delete('/interactions/$interactionId');
  }

  @override
  Future<void> markInteractionRead(
    int interactionId, {
    int? currentUserId,
  }) async {
    await post('/interactions/$interactionId/mark-read');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCalendars({
    int? ownerId,
    int? currentUserId,
  }) async {
    final result = await get(
      '/calendars',
      queryParams: {
        if (ownerId != null) 'owner_id': ownerId,
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> fetchCalendar(
    int calendarId, {
    int? currentUserId,
  }) async {
    final result = await get(
      '/calendars/$calendarId',
      queryParams: {
      },
    );
    return result as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCalendarMemberships(
    int calendarId, {
    int? currentUserId,
  }) async {
    final result = await get(
      '/calendars/$calendarId/memberships',
      queryParams: {
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> createCalendar(
    Map<String, dynamic> data, {
    int? currentUserId,
  }) async {
    final result = await post('/calendars', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> addCalendarMembership(
    int calendarId,
    Map<String, dynamic> data, {
    int? currentUserId,
  }) async {
    final result = await post('/calendars/$calendarId/memberships', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateCalendar(
    int calendarId,
    Map<String, dynamic> data, {
    int? currentUserId,
  }) async {
    final result = await put('/calendars/$calendarId', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> deleteCalendar(int calendarId, {int? currentUserId}) async {
    await delete('/calendars/$calendarId');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllCalendarMemberships({
    int? calendarId,
    int? userId,
    int? currentUserId,
  }) async {
    final result = await get(
      '/calendar_memberships',
      queryParams: {
        if (calendarId != null) 'calendar_id': calendarId,
        if (userId != null) 'user_id': userId,
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> fetchCalendarMembership(
    int membershipId, {
    int? currentUserId,
  }) async {
    final result = await get(
      '/calendar_memberships/$membershipId',
      queryParams: {
      },
    );
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createCalendarMembership(
    Map<String, dynamic> data, {
    int? currentUserId,
  }) async {
    final result = await post('/calendar_memberships', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateCalendarMembership(
    int membershipId,
    Map<String, dynamic> data, {
    int? currentUserId,
  }) async {
    final result = await put('/calendar_memberships/$membershipId', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> deleteCalendarMembership(
    int membershipId, {
    int? currentUserId,
  }) async {
    await delete('/calendar_memberships/$membershipId');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroups({
    int? createdBy,
    int? currentUserId,
  }) async {
    final result = await get(
      '/groups',
      queryParams: {
        if (createdBy != null) 'created_by': createdBy,
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> fetchGroup(
    int groupId, {
    int? currentUserId,
  }) async {
    final result = await get(
      '/groups/$groupId',
      queryParams: {
      },
    );
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createGroup(
    Map<String, dynamic> data, {
    int? currentUserId,
  }) async {
    final result = await post('/groups', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateGroup(
    int groupId,
    Map<String, dynamic> data, {
    int? currentUserId,
  }) async {
    final result = await put('/groups/$groupId', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> deleteGroup(int groupId, {int? currentUserId}) async {
    await delete('/groups/$groupId');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroupMemberships({
    int? groupId,
    int? userId,
  }) async {
    final result = await get(
      '/group_memberships',
      queryParams: {
        if (groupId != null) 'group_id': groupId,
        if (userId != null) 'user_id': userId,
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> fetchGroupMembership(int membershipId) async {
    final result = await get('/group_memberships/$membershipId');
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createGroupMembership(
    Map<String, dynamic> data,
  ) async {
    final result = await post('/group_memberships', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> deleteGroupMembership(int membershipId) async {
    await delete('/group_memberships/$membershipId');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecurringConfigs({
    int? eventId,
    int? currentUserId,
  }) async {
    final result = await get(
      '/recurring_configs',
      queryParams: {
        if (eventId != null) 'event_id': eventId,
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> fetchRecurringConfig(
    int configId, {
    int? currentUserId,
  }) async {
    final result = await get(
      '/recurring_configs/$configId',
      queryParams: {
      },
    );
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createRecurringConfig(
    Map<String, dynamic> data, {
    int? currentUserId,
  }) async {
    final result = await post('/recurring_configs', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateRecurringConfig(
    int configId,
    Map<String, dynamic> data, {
    int? currentUserId,
  }) async {
    final result = await put('/recurring_configs/$configId', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> deleteRecurringConfig(int configId, {int? currentUserId}) async {
    await delete('/recurring_configs/$configId');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserBlocks({
    int? blockerUserId,
    int? blockedUserId,
  }) async {
    final result = await get(
      '/user_blocks',
      queryParams: {
        if (blockerUserId != null) 'blocker_user_id': blockerUserId,
        if (blockedUserId != null) 'blocked_user_id': blockedUserId,
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> fetchUserBlock(int blockId) async {
    final result = await get('/user_blocks/$blockId');
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createUserBlock(
    Map<String, dynamic> data,
  ) async {
    final result = await post('/user_blocks', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> deleteUserBlock(
    int blockId, {
    required int currentUserId,
  }) async {
    await delete(
      '/user_blocks/$blockId',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEventBans({
    int? eventId,
    int? userId,
  }) async {
    final result = await get(
      '/event_bans',
      queryParams: {
        if (eventId != null) 'event_id': eventId,
        if (userId != null) 'user_id': userId,
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> fetchEventBan(int banId) async {
    final result = await get('/event_bans/$banId');
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createEventBan(Map<String, dynamic> data) async {
    final result = await post('/event_bans', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> deleteEventBan(int banId) async {
    await delete('/event_bans/$banId');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAppBans() async {
    final result = await get('/app_bans');
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> fetchAppBan(int banId) async {
    final result = await get('/app_bans/$banId');
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createAppBan(Map<String, dynamic> data) async {
    final result = await post('/app_bans', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> deleteAppBan(int banId) async {
    await delete('/app_bans/$banId');
  }

  static final ApiClient _instance = ApiClient._internal();
  ApiClient._internal();
  factory ApiClient() => _instance;

  static void initialize(ApiClient instance) {
    ApiClientFactory.initialize(instance);
  }
}

class ApiClientFactory {
  static IApiClient? _instance;

  static void initialize(IApiClient instance) {
    _instance = instance;
  }

  static IApiClient get instance {
    if (_instance == null) {
      throw Exception(
        'ApiClient not initialized. Call ApiClientFactory.initialize() first.',
      );
    }
    return _instance!;
  }
}
