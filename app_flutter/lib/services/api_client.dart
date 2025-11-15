import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';
import '../config/debug_config.dart';
import 'supabase_service.dart';
import 'config_service.dart';
import '../utils/app_exceptions.dart' as app_exceptions;
import 'contracts/api_client_contract.dart';
import 'api_logger.dart';

class ApiClient implements IApiClient {
  final http.Client _client = http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    // In test mode, use X-Test-User-Id header instead of JWT
    final configService = ConfigService.instance;
    if (configService.isTestMode && configService.currentUserId != 0) {
      headers['X-Test-User-Id'] = configService.currentUserId.toString();
      DebugConfig.info(
        'Added test user ID to request headers: ${configService.currentUserId}',
        tag: 'API',
      );
      return headers;
    }

    // Get JWT token from Supabase session
    try {
      final session = SupabaseService.instance.client.auth.currentSession;
      if (session != null && session.accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${session.accessToken}';
        DebugConfig.info('Added JWT token to request headers', tag: 'API');
      } else {
        DebugConfig.info(
          'No Supabase session found - request will be unauthenticated',
          tag: 'API',
        );
      }
    } catch (e) {
      DebugConfig.error('Failed to get Supabase session: $e', tag: 'API');
    }

    return headers;
  }

  Uri _buildUri(String path, {Map<String, dynamic>? queryParams}) {
    final params = Map<String, dynamic>.from(queryParams ?? {});

    // Add /api/v1 prefix if not already present
    final normalizedPath = path.startsWith('/api/v1') ? path : '/api/v1$path';

    final uri = Uri.parse('${AppConfig.apiBaseUrl}$normalizedPath');
    if (params.isNotEmpty) {
      final nonNullParams = params.map(
        (key, value) => MapEntry(key, value?.toString()),
      )..removeWhere((key, value) => value == null);
      return uri.replace(queryParameters: nonNullParams);
    }
    return uri;
  }

  /// Extract caller information from stack trace for logging
  String _getCallerInfo() {
    try {
      final stackTrace = StackTrace.current.toString();
      final lines = stackTrace.split('\n');

      // Skip the first lines (this method, get/post/put/delete/patch methods)
      // and find the first external caller
      for (var i = 3; i < lines.length && i < 8; i++) {
        final line = lines[i].trim();

        // Look for file path in the stack frame
        final match = RegExp(
          r'package:eventypop/(.+?\.dart):(\d+)',
        ).firstMatch(line);
        if (match != null) {
          final filePath = match.group(1)!;
          final lineNumber = match.group(2)!;

          // Extract file name without path
          final fileName = filePath.split('/').last;

          // Try to extract method/function name
          final methodMatch = RegExp(
            r'([a-zA-Z_][a-zA-Z0-9_]*)\s*\(',
          ).firstMatch(line);
          final methodName = methodMatch?.group(1) ?? '?';

          return '[$fileName:$lineNumber → $methodName()]';
        }
      }

      return '[unknown caller]';
    } catch (e) {
      return '[trace error]';
    }
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

    final caller = _getCallerInfo();
    DebugConfig.info('GET: $uri $caller', tag: 'API');

    // Log request if API logging is enabled
    final stopwatch = Stopwatch()..start();
    ApiLogger.instance.logRequest('GET', uri, headers, null, caller);

    try {
      final response = await _client.get(uri, headers: headers);
      stopwatch.stop();

      // Log response
      ApiLogger.instance.logResponse(response, stopwatch.elapsedMilliseconds);

      return _handleResponse(response);
    } on SocketException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw const app_exceptions.NetworkException();
    } on HttpException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw app_exceptions.ApiException('Could not find the server');
    } on FormatException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw app_exceptions.ApiException('Bad response format');
    }
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = await _getHeaders();

    final caller = _getCallerInfo();
    DebugConfig.info('POST: $uri $caller', tag: 'API');

    // Log request if API logging is enabled
    final stopwatch = Stopwatch()..start();
    ApiLogger.instance.logRequest('POST', uri, headers, body, caller);

    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      stopwatch.stop();

      // Log response
      ApiLogger.instance.logResponse(response, stopwatch.elapsedMilliseconds);

      return _handleResponse(response);
    } on SocketException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw const app_exceptions.NetworkException();
    } on HttpException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw app_exceptions.ApiException('Could not find the server');
    } on FormatException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw app_exceptions.ApiException('Bad response format');
    }
  }

  @override
  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = await _getHeaders();

    final caller = _getCallerInfo();
    DebugConfig.info('PUT: $uri $caller', tag: 'API');

    // Log request if API logging is enabled
    final stopwatch = Stopwatch()..start();
    ApiLogger.instance.logRequest('PUT', uri, headers, body, caller);

    try {
      final response = await _client.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      stopwatch.stop();

      // Log response
      ApiLogger.instance.logResponse(response, stopwatch.elapsedMilliseconds);

      return _handleResponse(response);
    } on SocketException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw const app_exceptions.NetworkException();
    } on HttpException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw app_exceptions.ApiException('Could not find the server');
    } on FormatException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
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

    final caller = _getCallerInfo();
    DebugConfig.info('DELETE: $uri $caller', tag: 'API');

    // Log request if API logging is enabled
    final stopwatch = Stopwatch()..start();
    ApiLogger.instance.logRequest('DELETE', uri, headers, null, caller);

    try {
      final response = await _client.delete(uri, headers: headers);
      stopwatch.stop();

      // Log response
      ApiLogger.instance.logResponse(response, stopwatch.elapsedMilliseconds);

      return _handleResponse(response);
    } on SocketException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw const app_exceptions.NetworkException();
    } on HttpException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw app_exceptions.ApiException('Could not find the server');
    } on FormatException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw app_exceptions.ApiException('Bad response format');
    }
  }

  @override
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final headers = await _getHeaders();

    final caller = _getCallerInfo();
    DebugConfig.info('PATCH: $uri $caller', tag: 'API');

    // Log request if API logging is enabled
    final stopwatch = Stopwatch()..start();
    ApiLogger.instance.logRequest('PATCH', uri, headers, body, caller);

    try {
      final response = await _client.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      stopwatch.stop();

      // Log response
      ApiLogger.instance.logResponse(response, stopwatch.elapsedMilliseconds);

      return _handleResponse(response);
    } on SocketException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw const app_exceptions.NetworkException();
    } on HttpException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw app_exceptions.ApiException('Could not find the server');
    } on FormatException catch (e) {
      stopwatch.stop();
      ApiLogger.instance.logError(e, stopwatch.elapsedMilliseconds);
      throw app_exceptions.ApiException('Bad response format');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUsers({
    bool? isPublic,
    int? limit,
    int? offset,
    String? search,
  }) async {
    final result = await get(
      '/users',
      queryParams: {
        if (isPublic != null) 'public': isPublic,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        if (search != null) 'search': search,
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
  Future<List<Map<String, dynamic>>> fetchUserEvents(
    int userId, {
    int? currentUserId,
  }) async {
    final result = await get('/users/$userId/events', queryParams: {});
    return List<Map<String, dynamic>>.from(result);
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
  Future<Map<String, dynamic>> subscribeToUser(int targetUserId) async {
    final result = await post('/users/$targetUserId/subscribe');
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> unsubscribeFromUser(
    int userId,
    int targetUserId,
  ) async {
    final result = await delete('/users/$targetUserId/subscribe');
    return result as Map<String, dynamic>;
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
    final result = await get('/events/$eventId', queryParams: {});
    return result as Map<String, dynamic>;
  }

  @override
  // (removed unused interaction list helpers)
  @override
  Future<List<Map<String, dynamic>>> fetchAvailableInvitees(
    int eventId, {
    int? currentUserId,
  }) async {
    final result = await get(
      '/events/$eventId/available-invitees',
      queryParams: {},
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
    bool? enriched,
    int? currentUserId,
  }) async {
    final result = await get(
      '/interactions',
      queryParams: {
        if (eventId != null) 'event_id': eventId,
        if (userId != null) 'user_id': userId,
        if (interactionType != null) 'interaction_type': interactionType,
        if (status != null) 'status': status,
        if (enriched != null) 'enriched': enriched,
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserSubscriptions(
    int userId, {
    int? currentUserId,
  }) async {
    final result = await get('/users/$userId/subscriptions');
    return List<Map<String, dynamic>>.from(result);
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
  Future<Map<String, dynamic>> patchInteraction(
    int interactionId,
    Map<String, dynamic> data, {
    bool force = false,
  }) async {
    final result = await patch('/interactions/$interactionId', body: data);
    return result as Map<String, dynamic>;
  }

  Future<void> deleteInteraction(int interactionId) async {
    await delete('/interactions/$interactionId');
  }

  Future<Map<String, dynamic>> addEventParticipantsBulk({
    required int eventId,
    List<int> userIds = const [],
    List<int> groupIds = const [],
    String role = 'attendee',
  }) async {
    final result = await post(
      '/interactions/bulk',
      body: {
        'event_id': eventId,
        'user_ids': userIds,
        'group_ids': groupIds,
        'role': role,
      },
    );
    return result as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCalendars({
    int? ownerId,
    int? currentUserId,
  }) async {
    final result = await get(
      '/calendars',
      queryParams: {if (ownerId != null) 'owner_id': ownerId},
    );
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCalendarMemberships(
    int calendarId, {
    int? currentUserId,
  }) async {
    final result = await get(
      '/calendars/$calendarId/memberships',
      queryParams: {},
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
  Future<void> deleteCalendar(
    int calendarId, {
    bool deleteEvents = false,
    int? currentUserId,
  }) async {
    await delete('/calendars/$calendarId?delete_events=$deleteEvents');
  }

  // Search public calendar by share_hash (direct lookup)
  @override
  Future<Map<String, dynamic>?> searchCalendarByHash(String shareHash) async {
    try {
      final result = await get('/calendars/share/$shareHash');
      return result as Map<String, dynamic>;
    } catch (e) {
      // Calendar not found or not public
      return null;
    }
  }

  // Subscribe to a public calendar using share_hash
  @override
  Future<Map<String, dynamic>> subscribeByShareHash(String shareHash) async {
    final result = await post('/calendars/$shareHash/subscribe', body: {});
    return result as Map<String, dynamic>;
  }

  // Unsubscribe from a public calendar using share_hash
  @override
  Future<void> unsubscribeByShareHash(String shareHash) async {
    await delete('/calendars/$shareHash/subscribe');
  }

  // (removed unused calendar memberships aggregator)

  @override
  Future<void> deleteCalendarMembership(
    int membershipId, {
    int? currentUserId,
  }) async {
    await delete('/calendar_memberships/$membershipId');
  }

  Future<void> patchCalendarMembership(
    int membershipId,
    Map<String, dynamic> updates,
  ) async {
    await patch('/calendar_memberships/$membershipId', body: updates);
  }

  Future<Map<String, dynamic>> addCalendarMembersBulk({
    required int calendarId,
    List<int> userIds = const [],
    List<int> groupIds = const [],
    String role = 'member',
  }) async {
    final result = await post(
      '/calendars/$calendarId/memberships/bulk',
      body: {
        'user_ids': userIds,
        'group_ids': groupIds,
        'role': role,
      },
    );
    return result as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroups({
    int? ownerId,
    int? currentUserId,
  }) async {
    final result = await get(
      '/groups',
      queryParams: {if (ownerId != null) 'owner_id': ownerId},
    );
    return List<Map<String, dynamic>>.from(result);
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
  Future<Map<String, dynamic>> createGroupMembership(
    Map<String, dynamic> data,
  ) async {
    final result = await post('/group_memberships', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateGroupMembership(
    int membershipId,
    Map<String, dynamic> data,
  ) async {
    final result = await put('/group_memberships/$membershipId', body: data);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void> deleteGroupMembership(int membershipId) async {
    await delete('/group_memberships/$membershipId');
  }

  // (removed unused recurring configs fetcher)

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
    await delete('/user_blocks/$blockId');
  }

  // ============================================================================
  // UserContacts API
  // ============================================================================

  @override
  Future<Map<String, dynamic>> syncContacts({
    required List<Map<String, String>> contacts,
  }) async {
    final result = await post('/contacts/sync', body: {'contacts': contacts});
    return result as Map<String, dynamic>;
  }

  @override
  Future<List<dynamic>> getMyContacts({
    bool onlyRegistered = true,
    int limit = 100,
    int skip = 0,
  }) async {
    final result = await get(
      '/contacts',
      queryParams: {
        'only_registered': onlyRegistered,
        'limit': limit,
        'skip': skip,
      },
    );
    return result as List<dynamic>;
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
