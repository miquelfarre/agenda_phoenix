import 'dart:async';
import 'dart:io';
import 'package:hive_ce/hive.dart';
import '../models/event.dart';
import '../models/subscription.dart';
import '../models/group.dart';
import '../models/event_hive.dart';
import '../models/user_hive.dart';
import '../models/user.dart';
import '../models/subscription_hive.dart';
import '../models/group_hive.dart';
import '../models/event_interaction.dart';
import '../models/event_interaction_hive.dart';
import '../utils/temp_id_generator.dart';
import 'api_client.dart';
import '../models/user_event_note_hive.dart';
import 'supabase_auth_service.dart';
import 'config_service.dart';

class SyncService {
  static Future<void> init() async {}

  static bool get _isAuthenticated {
    final configService = ConfigService.instance;
    if (configService.isTestMode) {
      return true;
    }
    return SupabaseAuthService.isLoggedIn;
  }

  static Future<List<Event>> syncEvents() async {
    if (!_isAuthenticated) {
      return getLocalEvents();
    }

    try {
      final userId = ConfigService.instance.currentUserId;
      final compositeData = await ApiClientFactory.instance.get(
        '/api/v1/users/$userId/events',
      );

      await _storeCompositeData(compositeData);

      return getLocalEvents();
    } on SocketException {
      return getLocalEvents();
    } catch (e) {
      return getLocalEvents();
    }
  }

  static Future<Map<String, dynamic>> syncEventsComposite({
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
    String? filterType,
    bool futureOnly = true,
  }) async {
    print('🔵 [SyncService] syncEventsComposite START');
    if (!_isAuthenticated) {
      print('🔴 [SyncService] Not authenticated, returning empty map');
      return {};
    }

    try {
      final userId = ConfigService.instance.currentUserId;
      final queryParams = <String, dynamic>{};
      if (fromDate != null) {
        queryParams['from_date'] = fromDate.toIso8601String();
      }
      if (toDate != null) {
        queryParams['to_date'] = toDate.toIso8601String();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search; // Changed from 'q' to 'search'
      }
      if (filterType != null && filterType.isNotEmpty) {
        queryParams['filter'] = filterType;
      }

      if (!futureOnly) {
        queryParams['include_past'] =
            'true'; // Changed from 'future_only' to 'include_past'
      }

      print('🔵 [SyncService] Fetching from API...');

      final compositeData = await ApiClientFactory.instance.get(
        '/api/v1/users/$userId/events',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      print(
        '🔵 [SyncService] Got compositeData type: ${compositeData.runtimeType}',
      );
      print(
        '🔵 [SyncService] compositeData keys: ${compositeData is Map ? compositeData.keys : 'NOT A MAP'}',
      );

      print('🔵 [SyncService] Storing composite data in Hive...');

      await _storeCompositeData(compositeData);
      print('🔵 [SyncService] Successfully stored composite data');

      print('🔵 [SyncService] Returning compositeData');
      return compositeData;
    } on SocketException {
      print('🔴 [SyncService] SocketException, returning empty map');
      return {};
    } catch (e, stackTrace) {
      print('🔴 [SyncService] ERROR in syncEventsComposite: $e');
      print('🔴 [SyncService] StackTrace: $stackTrace');
      return {};
    }
  }

  static Future<void> _storeCompositeData(
    Map<String, dynamic> compositeData,
  ) async {
    final eventItems = (compositeData['events'] as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();

    final eventsBox = Hive.box<EventHive>('events');
    await eventsBox.clear();

    final notesBox = Hive.box<UserEventNoteHive>('user_event_note');
    await notesBox.clear();

    final interactionsBox = Hive.box<EventInteractionHive>(
      'event_interactions',
    );
    final usersBox = Hive.box<UserHive>('users');
    final userId = ConfigService.instance.currentUserId;

    final keysToDelete = interactionsBox.keys.where((k) {
      final interaction = interactionsBox.get(k);
      return interaction != null && interaction.userId == userId;
    }).toList();
    for (final key in keysToDelete) {
      await interactionsBox.delete(key);
    }

    for (final item in eventItems) {
      final eventId = item['id'] as int;

      final eventJson = {
        'id': item['id'],
        'title': item['title'],
        'description': item['description'],
        'start_date': item['date'],
        'date': item['date'],
        'is_published': item['is_published'],
        'is_birthday': item['is_birthday'],
        'is_recurring': item['is_recurring'],
        'owner_id': item['owner_id'],
        'owner': item['owner'],
        'attendees': [],
        'can_invite_users': item['can_invite_users'],
      };

      final hiveKey = TempIdGenerator.toHiveId(eventId);
      final event = Event.fromJson(eventJson);
      await eventsBox.put(hiveKey, EventHive.fromEvent(event));

      final personalNote = item['personal_note'] as String?;
      if (personalNote != null && personalNote.isNotEmpty) {
        final noteHiveKey = UserEventNoteHive.createHiveKey(userId, eventId);
        final noteHive = UserEventNoteHive(
          userId: userId,
          eventId: eventId,
          note: personalNote,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await notesBox.put(noteHiveKey, noteHive);
      }

      final invitationStatus = item['invitation_status'] as String?;
      if (invitationStatus != null) {
        final inviterId = item['inviter_id'] as int?;
        final inviterData = item['inviter'] as Map<String, dynamic>?;

        if (inviterId != null && inviterData != null) {
          final inviterUser = User.fromJson(inviterData);
          await usersBox.put(inviterId, inviterUser.toUserHive());
        }

        final interactionHive = EventInteractionHive(
          userId: userId,
          eventId: eventId,
          inviterId: inviterId,
          participationStatus: invitationStatus,
          viewed: false,
          favorited: false,
          hidden: false,
          isAttending: false,
          isEventAdmin: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final interactionKey = EventInteractionHive.createHiveKey(
          userId,
          eventId,
        );
        await interactionsBox.put(interactionKey, interactionHive);
      }
    }
  }

  static Future<void> syncUserProfile(int userId) async {
    try {
      final response = await ApiClientFactory.instance.get(
        '/api/v1/users/$userId',
      );
      final user = User.fromJson(response);
      final box = Hive.box<UserHive>('users');
      await box.put(user.id, user.toUserHive());
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> clearUserCache(int userId) async {
    try {
      final box = Hive.box<UserHive>('users');
      if (box.containsKey(userId)) {
        await box.delete(userId);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> clearAllUsersCache() async {
    try {
      final box = Hive.box<UserHive>('users');
      await box.clear();
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Subscription>> syncSubscriptions(int userId) async {
    if (!_isAuthenticated) {
      return getLocalSubscriptions(userId);
    }

    try {
      final subscriptions = <Subscription>[];

      final box = Hive.box<SubscriptionHive>('subscriptions');

      final keysToDelete = box.keys.where((k) {
        final sub = box.get(k);
        return sub != null && sub.userId == userId;
      }).toList();

      for (final key in keysToDelete) {
        await box.delete(key);
      }

      for (final subscription in subscriptions) {
        await box.put(
          subscription.id,
          SubscriptionHive.fromSubscription(subscription),
        );
      }

      return subscriptions;
    } on SocketException {
      return getLocalSubscriptions(userId);
    } catch (e) {
      return getLocalSubscriptions(userId);
    }
  }

  static Future<Map<String, dynamic>> syncSubscriptionsComposite() async {
    print('🔵 [SyncService] syncSubscriptionsComposite START');
    if (!_isAuthenticated) {
      print('🔴 [SyncService] Not authenticated, returning empty map');
      return {};
    }

    try {
      print('🔵 [SyncService] Fetching from API...');
      final userId = ConfigService.instance.currentUserId;

      // Subscriptions are now EventInteractions with type='subscribed'
      final interactions = await ApiClientFactory.instance.get(
        '/api/v1/interactions',
        queryParams: {
          'user_id': userId.toString(),
          'interaction_type': 'subscribed',
          'enriched': 'true',
        },
      );

      print(
        '🔵 [SyncService] Got interactions type: ${interactions.runtimeType}',
      );

      // Transform interactions to subscription format
      final subscriptionItems = (interactions as List).map((interaction) {
        return {
          'id': interaction['id'],
          'user_id': interaction['user_id'],
          'subscribed_to_id': interaction['event']['owner_id'],
          'subscribed_to': interaction['event']['owner'],
        };
      }).toList();

      final compositeData = {'subscriptions': subscriptionItems};

      print('🔵 [SyncService] Storing subscriptions composite data in Hive...');

      await _storeSubscriptionsCompositeData(compositeData);
      print(
        '🔵 [SyncService] Successfully stored subscriptions composite data',
      );

      print('🔵 [SyncService] Returning compositeData');
      return compositeData;
    } on SocketException {
      print('🔴 [SyncService] SocketException, returning empty map');
      return {};
    } catch (e, stackTrace) {
      print('🔴 [SyncService] ERROR in syncSubscriptionsComposite: $e');
      print('🔴 [SyncService] StackTrace: $stackTrace');
      return {};
    }
  }

  static Future<void> _storeSubscriptionsCompositeData(
    Map<String, dynamic> compositeData,
  ) async {
    final subscriptionItems = (compositeData['subscriptions'] as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();

    final subscriptionsBox = Hive.box<SubscriptionHive>('subscriptions');
    await subscriptionsBox.clear();

    for (final item in subscriptionItems) {
      final subscriptionJson = {
        'id': item['id'],
        'user_id': item['user_id'],
        'subscribed_to_id': item['subscribed_to_id'],
        'subscribed': item['subscribed_to'],
      };

      final subscription = Subscription.fromJson(subscriptionJson);
      await subscriptionsBox.put(
        subscription.id,
        SubscriptionHive.fromSubscription(subscription),
      );
    }
  }

  static Future<List<EventInteraction>> syncEventInteractions(
    int userId,
  ) async {
    if (!_isAuthenticated) {
      return getLocalEventInteractions(userId);
    }

    try {
      final interactionsData = await ApiClientFactory.instance
          .fetchEventInteractions(userId);

      final interactions = interactionsData
          .map((data) => EventInteraction.fromJson(data))
          .toList();

      final box = Hive.box<EventInteractionHive>('event_interactions');
      final usersBox = Hive.box<UserHive>('users');

      final keysToDelete = box.keys.where((k) {
        final interaction = box.get(k);
        return interaction != null && interaction.userId == userId;
      }).toList();

      for (final key in keysToDelete) {
        await box.delete(key);
      }

      for (final interaction in interactions) {
        if (interaction.inviterId != null && interaction.inviter != null) {
          await usersBox.put(
            interaction.inviterId!,
            interaction.inviter!.toUserHive(),
          );
        }

        final hiveKey = EventInteractionHive.createHiveKey(
          interaction.userId,
          interaction.eventId,
        );
        await box.put(hiveKey, EventInteractionHive.fromDomain(interaction));
      }

      return interactions;
    } on SocketException {
      return getLocalEventInteractions(userId);
    } catch (e) {
      return getLocalEventInteractions(userId);
    }
  }

  static Future<List<Group>> syncGroups(int userId) async {
    if (!_isAuthenticated) {
      return getLocalGroups(userId);
    }

    try {
      final groupsData = await ApiClientFactory.instance.fetchGroups();

      final groups = groupsData.map((data) => Group.fromJson(data)).toList();

      final box = Hive.box<GroupHive>('groups');

      final keysToDelete = box.keys.where((k) {
        final group = box.get(k);
        return group != null && group.memberIds.contains(userId);
      }).toList();

      for (final key in keysToDelete) {
        await box.delete(key);
      }

      for (final group in groups) {
        await box.put(group.id, GroupHive.fromGroup(group));
      }

      return groups;
    } on SocketException {
      return getLocalGroups(userId);
    } catch (e) {
      return getLocalGroups(userId);
    }
  }


  static Future<void> clearGroupCache(int groupId) async {
    try {
      final box = Hive.box<GroupHive>('groups');
      if (box.containsKey(groupId)) {
        await box.delete(groupId);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> syncAll(int userId) async {
    await Future.wait([
      syncEvents(),

      syncGroups(userId),
      syncSubscriptions(userId),
      syncEventInteractions(userId),
    ]);
  }

  static Future<Map<String, dynamic>> syncAllUserData(
    int userId, {
    bool force = false,
    List<String>? resources,
  }) async {
    await syncAll(userId);
    return {
      'success': true,
      'synced_resources':
          resources ??
          [
            'events',
            'notifications',
            'groups',
            'subscriptions',
            'event_interactions',
          ],
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static List<Event> getLocalEvents() {
    try {
      if (!Hive.isBoxOpen('events')) {
        return [];
      }

      final eventsBox = Hive.box<EventHive>('events');

      return eventsBox.values.map((eventHive) {
        return eventHive.toEvent();
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Event? getLocalEvent(int eventId) {
    try {
      final eventsBox = Hive.box<EventHive>('events');
      final hiveKey = TempIdGenerator.toHiveId(eventId);
      final eventHive = eventsBox.get(hiveKey);
      if (eventHive == null) return null;

      return eventHive.toEvent();
    } catch (e) {
      return null;
    }
  }

  static List<Subscription> getLocalSubscriptions(int userId) {
    try {
      if (!Hive.isBoxOpen('subscriptions')) {
        return [];
      }

      final subscriptionsBox = Hive.box<SubscriptionHive>('subscriptions');
      return subscriptionsBox.values
          .where((subscriptionHive) => subscriptionHive.userId == userId)
          .map((subscriptionHive) => subscriptionHive.toSubscription())
          .toList();
    } catch (e) {
      return [];
    }
  }

  static List<Group> getLocalGroups(int userId) {
    try {
      final groupsBox = Hive.box<GroupHive>('groups');
      return groupsBox.values
          .where((groupHive) => groupHive.memberIds.contains(userId))
          .map((groupHive) => groupHive.toGroup())
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Group? getLocalGroup(int groupId) {
    try {
      final box = Hive.box<GroupHive>('groups');
      final groupHive = box.get(groupId);
      return groupHive?.toGroup();
    } catch (e) {
      return null;
    }
  }

  static List<EventInteraction> getLocalEventInteractions(int userId) {
    try {
      if (!Hive.isBoxOpen('event_interactions')) {
        return [];
      }

      final box = Hive.box<EventInteractionHive>('event_interactions');
      final usersBox = Hive.box<UserHive>('users');
      final interactions = <EventInteraction>[];

      for (final hive in box.values) {
        if (hive.userId == userId) {
          User? inviter;
          if (hive.inviterId != null) {
            final inviterHive = usersBox.get(hive.inviterId);
            if (inviterHive != null) {
              inviter = inviterHive.toUser();
            }
          }

          interactions.add(
            EventInteraction(
              userId: hive.userId,
              eventId: hive.eventId,
              inviterId: hive.inviterId,
              inviter: inviter,
              invitationMessage: hive.invitationMessage,
              invitedAt: hive.invitedAt,
              participationStatus: hive.participationStatus,
              participationDecidedAt: hive.participationDecidedAt,
              decisionMessage: hive.decisionMessage,
              postponeUntil: hive.postponeUntil,
              isAttending: hive.isAttending,
              isEventAdmin: hive.isEventAdmin,
              viewed: hive.viewed,
              firstViewedAt: hive.firstViewedAt,
              lastViewedAt: hive.lastViewedAt,
              personalNote: hive.personalNote,
              noteUpdatedAt: hive.noteUpdatedAt,
              favorited: hive.favorited,
              favoritedAt: hive.favoritedAt,
              hidden: hive.hidden,
              hiddenAt: hive.hiddenAt,
              createdAt: hive.createdAt,
              updatedAt: hive.updatedAt,
            ),
          );
        }
      }

      return interactions;
    } catch (e) {
      return [];
    }
  }

  static EventInteraction? getLocalEventInteraction(int userId, int eventId) {
    try {
      final box = Hive.box<EventInteractionHive>('event_interactions');
      final usersBox = Hive.box<UserHive>('users');
      final key = EventInteractionHive.createHiveKey(userId, eventId);
      final hive = box.get(key);
      if (hive == null) return null;

      User? inviter;
      if (hive.inviterId != null) {
        final inviterHive = usersBox.get(hive.inviterId);
        if (inviterHive != null) {
          inviter = inviterHive.toUser();
        }
      }

      return EventInteraction(
        userId: hive.userId,
        eventId: hive.eventId,
        inviterId: hive.inviterId,
        inviter: inviter,
        invitationMessage: hive.invitationMessage,
        invitedAt: hive.invitedAt,
        participationStatus: hive.participationStatus,
        participationDecidedAt: hive.participationDecidedAt,
        decisionMessage: hive.decisionMessage,
        postponeUntil: hive.postponeUntil,
        isAttending: hive.isAttending,
        isEventAdmin: hive.isEventAdmin,
        viewed: hive.viewed,
        firstViewedAt: hive.firstViewedAt,
        lastViewedAt: hive.lastViewedAt,
        personalNote: hive.personalNote,
        noteUpdatedAt: hive.noteUpdatedAt,
        favorited: hive.favorited,
        favoritedAt: hive.favoritedAt,
        hidden: hive.hidden,
        hiddenAt: hive.hiddenAt,
        createdAt: hive.createdAt,
        updatedAt: hive.updatedAt,
      );
    } catch (e) {
      return null;
    }
  }
}
