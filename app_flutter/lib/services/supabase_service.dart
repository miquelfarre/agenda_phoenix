import 'package:supabase_flutter/supabase_flutter.dart';
import 'config_service.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  static Future<void> initialize({required String supabaseUrl, required String supabaseAnonKey}) async {
    print('🔵 [SupabaseService] Initializing Supabase client...');
    print('🔵 [SupabaseService] URL: $supabaseUrl');

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 10, logLevel: RealtimeLogLevel.info),
    );
    _client = Supabase.instance.client;

    // Listen to auth state changes to debug token issues
    _client!.auth.onAuthStateChange.listen((data) {
      print('🔵 [SupabaseService] Auth state changed: ${data.event}');
      if (data.session != null) {
        print('🔵 [SupabaseService] Session active, token (first 50): ${data.session!.accessToken.substring(0, 50)}...');
      }
    });

    print('✅ [SupabaseService] Supabase client initialized');
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// In debug/test mode, apply a generated test JWT as the current auth token
  /// so Realtime connections and HTTP requests use a user token (required for RLS).
  Future<void> applyTestAuthIfNeeded() async {
    final config = ConfigService.instance;
    if (!config.isTestMode) return;

    final token = config.testToken;
    if (token == null || token.isEmpty) return;

    try {
      // Update Realtime auth token so socket uses a user JWT (RLS-compatible)
      client.realtime.setAuth(token);

      // Also update the token for HTTP requests
      client.auth.headers['Authorization'] = 'Bearer $token';

      print('🔐 [SupabaseService] Applied test auth token to Realtime and HTTP clients');
    } catch (e) {
      print('❌ [SupabaseService] Failed to apply auth tokens: $e');
    }
  }

  SupabaseQueryBuilder get events => client.from('events');

  /// Fetch events for the current user with all relationships
  Future<List<Map<String, dynamic>>> fetchEventsForUser(int userId) async {
    try {
      // Fetch events owned by the user
      final ownedEvents = await client
          .from('events')
          .select('''
            *,
            owner:users!events_owner_id_fkey(*),
            calendar:calendars(*),
            interactions:event_interactions!event_interactions_event_id_fkey(
              *,
              user:users!event_interactions_user_id_fkey(*)
            )
          ''')
          .eq('owner_id', userId)
          .order('start_date', ascending: true);

      // Fetch events where user has interactions
      final invitedEvents = await client
          .from('event_interactions')
          .select('''
            event:events!event_interactions_event_id_fkey(
              *,
              owner:users!events_owner_id_fkey(*),
              calendar:calendars(*),
              interactions:event_interactions!event_interactions_event_id_fkey(
                *,
                user:users!event_interactions_user_id_fkey(*)
              )
            )
          ''')
          .eq('user_id', userId);

      // Extract events from the nested structure and combine with owned events
      final List<Map<String, dynamic>> allEvents = List<Map<String, dynamic>>.from(ownedEvents as List);

      for (final interaction in (invitedEvents as List)) {
        final event = interaction['event'] as Map<String, dynamic>?;
        if (event != null && !allEvents.any((e) => e['id'] == event['id'])) {
          allEvents.add(event);
        }
      }

      // Sort by start_date
      allEvents.sort((a, b) {
        final aDate = a['start_date'] as String?;
        final bDate = b['start_date'] as String?;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });

      return allEvents;
    } catch (e) {
      print('Error fetching events: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchEventDetail(int eventId, int userId) async {
    try {
      final events = await client
          .from('events')
          .select('''
            *,
            owner:users!events_owner_id_fkey(*),
            calendar:calendars(*),
            interactions:event_interactions!event_interactions_event_id_fkey(
              *,
              user:users!event_interactions_user_id_fkey(*)
            )
          ''')
          .eq('id', eventId)
          .single();
      return events;
    } catch (e) {
      print('Error fetching event detail: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSubscriptions(int userId) async {
    try {
      final subscriptions = await client
          .from('event_interactions')
          .select('''
            *,
            event:events!event_interactions_event_id_fkey(
              *,
              owner:users!events_owner_id_fkey(*)
            )
          ''')
          .eq('user_id', userId)
          .eq('interaction_type', 'subscribed');
      final Map<int, Map<String, dynamic>> ownerMap = {};
      for (final sub in (subscriptions as List)) {
        final event = sub['event'] as Map<String, dynamic>?;
        if (event != null) {
          final owner = event['owner'] as Map<String, dynamic>?;
          if (owner != null && owner['is_public'] == true) {
            final ownerId = owner['id'] as int;
            if (!ownerMap.containsKey(ownerId)) {
              ownerMap[ownerId] = owner;
            }
          }
        }
      }
      return ownerMap.values.toList();
    } catch (e) {
      print('Error fetching subscriptions: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPublicUserEvents(int publicUserId) async {
    try {
      final events = await client
          .from('events')
          .select('''
            *,
            owner:users!events_owner_id_fkey(*),
            interactions:event_interactions!event_interactions_event_id_fkey(
              *,
              user:users!event_interactions_user_id_fkey(*)
            )
          ''')
          .eq('owner_id', publicUserId)
          .order('start_date', ascending: true);
      return List<Map<String, dynamic>>.from(events as List);
    } catch (e) {
      print('Error fetching public user events: $e');
      rethrow;
    }
  }

  Future<bool> isSubscribedToUser(int currentUserId, int publicUserId) async {
    try {
      final subscriptions = await client.from('event_interactions').select('id').eq('user_id', currentUserId).eq('interaction_type', 'subscribed').limit(1);
      if ((subscriptions as List).isEmpty) return false;
      final eventOwnerId = await client.from('events').select('owner_id').eq('id', subscriptions[0]['id']).single();
      return eventOwnerId['owner_id'] == publicUserId;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchPeopleAndGroups(int userId) async {
    try {
      final users = await client.from('users').select('*').neq('id', userId);
      return {'contacts': users as List, 'groups': []};
    } catch (e) {
      print('Error fetching people and groups: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAvailableInvitees(int eventId, int currentUserId) async {
    try {
      final allUsers = await client.from('users').select('*').neq('id', currentUserId);
      final invitedUserIds = await client.from('event_interactions').select('user_id').eq('event_id', eventId).then((data) => (data as List).map((row) => row['user_id'] as int).toSet());
      final availableUsers = (allUsers as List).where((userData) => !invitedUserIds.contains(userData['id'])).toList();
      return availableUsers.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching available invitees: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchContactDetail(int contactId) async {
    try {
      final user = await client.from('users').select('*').eq('id', contactId).single();
      return user;
    } catch (e) {
      print('Error fetching contact detail: $e');
      rethrow;
    }
  }

  RealtimeChannel realtimeChannel(String channelName) {
    return client.channel(channelName);
  }
}
