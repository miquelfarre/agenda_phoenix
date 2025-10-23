import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 10),
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'SupabaseService not initialized. Call initialize() first.',
      );
    }
    return _client!;
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

  RealtimeChannel realtimeChannel(String channelName) {
    return client.channel(channelName);
  }
}
