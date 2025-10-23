library;

import 'package:hive_ce/hive.dart';
import '../models/event_list_composite.dart';
import '../models/event_detail_composite.dart';
import '../models/subscription_list_composite.dart';
import '../models/subscription_detail_composite.dart';
import '../models/invite_users_composite.dart';
import '../models/people_groups_composite.dart';
import '../models/public_user_events_composite.dart';
import '../models/contact_detail_composite.dart';
import 'api_client.dart';
import 'sync_service.dart';

class CompositeSyncService {
  static final CompositeSyncService _instance =
      CompositeSyncService._internal();
  static CompositeSyncService get instance => _instance;

  CompositeSyncService._internal();

  Box<String>? _checksumBox;
  Box<Map>? _compositeBox;

  Future<void> initialize() async {
    _checksumBox = await Hive.openBox<String>('composite_checksums');
    _compositeBox = await Hive.openBox<Map>('composite_cache');
  }

  Future<EventListComposite> smartSyncList({
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
    String? filterType,
    bool futureOnly = true,
  }) async {
    print(
      '🟢 [CompositeSyncService] smartSyncList START (futureOnly: $futureOnly)',
    );
    final stopwatch = Stopwatch()..start();

    try {
      print('🟢 [CompositeSyncService] Step 1: Getting checksum...');
      final serverChecksum = await _getListChecksum(
        fromDate: fromDate,
        toDate: toDate,
        search: search,
        filterType: filterType,
        futureOnly: futureOnly,
      );
      print('🟢 [CompositeSyncService] Step 1: Got checksum: $serverChecksum');

      final cachedChecksum = _checksumBox?.get('list_composite');
      print(
        '🟢 [CompositeSyncService] Step 2: Cached checksum: $cachedChecksum',
      );

      if (cachedChecksum == serverChecksum && cachedChecksum != null) {
        print('🟢 [CompositeSyncService] Cache HIT! Loading from Hive...');
        final cachedData = _compositeBox?.get('list_composite');
        if (cachedData != null) {
          final composite = EventListComposite.fromJson(
            Map<String, dynamic>.from(cachedData),
          );
          print(
            '🟢 [CompositeSyncService] Loaded from cache, events: ${composite.events.length}',
          );
          return composite;
        }

        print('🟡 [CompositeSyncService] Cache corrupted, fetching...');
      } else {
        print(
          '🟢 [CompositeSyncService] Cache MISS (server: $serverChecksum, cached: $cachedChecksum)',
        );
      }

      print('🟢 [CompositeSyncService] Step 3: Fetching composite data...');

      final compositeData = await SyncService.syncEventsComposite(
        fromDate: fromDate,
        toDate: toDate,
        search: search,
        filterType: filterType,
        futureOnly: futureOnly,
      );
      print('🟢 [CompositeSyncService] Step 3: Got composite data');
      print(
        '🟢 [CompositeSyncService] Composite data keys: ${compositeData.keys}',
      );
      print(
        '🟢 [CompositeSyncService] Events value: ${compositeData['events']}',
      );
      print(
        '🟢 [CompositeSyncService] Events type: ${compositeData['events'].runtimeType}',
      );

      final composite = EventListComposite.fromJson(compositeData);
      print(
        '🟢 [CompositeSyncService] Step 3: Parsed composite, events: ${composite.events.length}',
      );

      print('🟢 [CompositeSyncService] Step 4: Updating cache...');
      await _checksumBox?.put('list_composite', composite.checksum);
      await _compositeBox?.put('list_composite', composite.toJson());
      print('🟢 [CompositeSyncService] Step 4: Cache updated');

      stopwatch.stop();
      print(
        '🟢 [CompositeSyncService] smartSyncList COMPLETE (${stopwatch.elapsedMilliseconds}ms)',
      );

      return composite;
    } catch (e) {
      print('🔴 [CompositeSyncService] ERROR: $e');
      rethrow;
    }
  }

  Future<SubscriptionListComposite> smartSyncSubscriptions() async {
    print('🟢 [CompositeSyncService] smartSyncSubscriptions START');
    final stopwatch = Stopwatch()..start();

    try {
      print('🟢 [CompositeSyncService] Step 1: Getting checksum...');
      final serverChecksum = await _getSubscriptionsChecksum();
      print('🟢 [CompositeSyncService] Step 1: Got checksum: $serverChecksum');

      final cachedChecksum = _checksumBox?.get('subscriptions_composite');
      print(
        '🟢 [CompositeSyncService] Step 2: Cached checksum: $cachedChecksum',
      );

      if (cachedChecksum == serverChecksum && cachedChecksum != null) {
        print('🟢 [CompositeSyncService] Cache HIT! Loading from Hive...');
        final cachedData = _compositeBox?.get('subscriptions_composite');
        if (cachedData != null) {
          final composite = SubscriptionListComposite.fromJson(
            Map<String, dynamic>.from(cachedData),
          );
          print(
            '🟢 [CompositeSyncService] Loaded from cache, subscriptions: ${composite.subscriptions.length}',
          );
          return composite;
        }

        print('🟡 [CompositeSyncService] Cache corrupted, fetching...');
      } else {
        print(
          '🟢 [CompositeSyncService] Cache MISS (server: $serverChecksum, cached: $cachedChecksum)',
        );
      }

      print('🟢 [CompositeSyncService] Step 3: Fetching composite data...');

      final compositeData = await SyncService.syncSubscriptionsComposite();
      print('🟢 [CompositeSyncService] Step 3: Got composite data');
      print(
        '🟢 [CompositeSyncService] Composite data keys: ${compositeData.keys}',
      );

      final composite = SubscriptionListComposite.fromJson(compositeData);
      print(
        '🟢 [CompositeSyncService] Step 3: Parsed composite, subscriptions: ${composite.subscriptions.length}',
      );

      print('🟢 [CompositeSyncService] Step 4: Updating cache...');
      await _checksumBox?.put('subscriptions_composite', composite.checksum);
      await _compositeBox?.put('subscriptions_composite', composite.toJson());
      print('🟢 [CompositeSyncService] Step 4: Cache updated');

      stopwatch.stop();
      print(
        '🟢 [CompositeSyncService] smartSyncSubscriptions COMPLETE (${stopwatch.elapsedMilliseconds}ms)',
      );

      return composite;
    } catch (e) {
      print('🔴 [CompositeSyncService] ERROR: $e');
      rethrow;
    }
  }

  Future<EventDetailComposite> smartSyncDetail(int eventId) async {
    final stopwatch = Stopwatch()..start();

    try {
      final serverChecksum = await _getDetailChecksum(eventId);

      final cacheKey = 'detail_composite_$eventId';
      final checksumKey = 'detail_checksum_$eventId';
      final cachedChecksum = _checksumBox?.get(checksumKey);

      if (cachedChecksum == serverChecksum && cachedChecksum != null) {
        final cachedData = _compositeBox?.get(cacheKey);
        if (cachedData != null) {
          return EventDetailComposite.fromJson(
            Map<String, dynamic>.from(cachedData),
          );
        }
      }

      await SyncService.syncEvents();

      final composite = await _fetchDetailComposite(eventId);

      await _checksumBox?.put(checksumKey, composite.checksum);
      await _compositeBox?.put(cacheKey, composite.toJson());

      stopwatch.stop();

      return composite;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _getListChecksum({
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
    String? filterType,
    bool futureOnly = true,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fromDate != null) {
      queryParams['from_date'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      queryParams['to_date'] = toDate.toIso8601String();
    }
    if (search != null && search.isNotEmpty) {
      queryParams['q'] = search;
    }
    if (filterType != null && filterType.isNotEmpty) {
      queryParams['filter'] = filterType;
    }

    if (!futureOnly) queryParams['future_only'] = 'false';

    final response = await ApiClientFactory.instance.get(
      '/api/v1/events/list-composite/checksum',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    return response['checksum'] as String;
  }

  Future<String> _getDetailChecksum(int eventId) async {
    final response = await ApiClientFactory.instance.get(
      '/api/v1/events/$eventId/detail-composite/checksum',
    );

    return response['checksum'] as String;
  }

  Future<String> _getSubscriptionsChecksum() async {
    final response = await ApiClientFactory.instance.get(
      '/api/v1/subscriptions/list-composite/checksum',
    );

    return response['checksum'] as String;
  }

  Future<SubscriptionDetailComposite> smartSyncSubscriptionDetail(
    int subscriptionId,
  ) async {
    print(
      '🟢 [CompositeSyncService] smartSyncSubscriptionDetail START (subscriptionId: $subscriptionId)',
    );
    final stopwatch = Stopwatch()..start();

    try {
      print('🟢 [CompositeSyncService] Step 1: Getting checksum...');
      final serverChecksum = await _getSubscriptionDetailChecksum(
        subscriptionId,
      );
      print('🟢 [CompositeSyncService] Step 1: Got checksum: $serverChecksum');

      final cacheKey = 'subscription_detail_composite_$subscriptionId';
      final checksumKey = 'subscription_detail_checksum_$subscriptionId';
      final cachedChecksum = _checksumBox?.get(checksumKey);
      print(
        '🟢 [CompositeSyncService] Step 2: Cached checksum: $cachedChecksum',
      );

      if (cachedChecksum == serverChecksum && cachedChecksum != null) {
        print('🟢 [CompositeSyncService] Cache HIT! Loading from Hive...');
        final cachedData = _compositeBox?.get(cacheKey);
        if (cachedData != null) {
          final composite = SubscriptionDetailComposite.fromJson(
            Map<String, dynamic>.from(cachedData),
          );
          print(
            '🟢 [CompositeSyncService] Loaded from cache, events: ${composite.publicEvents.length}',
          );
          return composite;
        }

        print('🟡 [CompositeSyncService] Cache corrupted, fetching...');
      } else {
        print(
          '🟢 [CompositeSyncService] Cache MISS (server: $serverChecksum, cached: $cachedChecksum)',
        );
      }

      print('🟢 [CompositeSyncService] Step 3: Fetching composite data...');
      final composite = await _fetchSubscriptionDetailComposite(subscriptionId);
      print(
        '🟢 [CompositeSyncService] Step 3: Got composite data, events: ${composite.publicEvents.length}',
      );

      print('🟢 [CompositeSyncService] Step 4: Updating cache...');
      await _checksumBox?.put(checksumKey, composite.checksum);
      await _compositeBox?.put(cacheKey, composite.toJson());
      print('🟢 [CompositeSyncService] Step 4: Cache updated');

      stopwatch.stop();
      print(
        '🟢 [CompositeSyncService] smartSyncSubscriptionDetail COMPLETE (${stopwatch.elapsedMilliseconds}ms)',
      );

      return composite;
    } catch (e) {
      print('🔴 [CompositeSyncService] ERROR: $e');
      rethrow;
    }
  }

  Future<String> _getSubscriptionDetailChecksum(int subscriptionId) async {
    final response = await ApiClientFactory.instance.get(
      '/api/v1/subscriptions/$subscriptionId/detail-composite/checksum',
    );

    return response['checksum'] as String;
  }

  Future<EventDetailComposite> _fetchDetailComposite(int eventId) async {
    final response = await ApiClientFactory.instance.get(
      '/api/v1/events/$eventId/detail-composite',
    );

    return EventDetailComposite.fromJson(response as Map<String, dynamic>);
  }

  Future<SubscriptionDetailComposite> _fetchSubscriptionDetailComposite(
    int subscriptionId,
  ) async {
    final response = await ApiClientFactory.instance.get(
      '/api/v1/subscriptions/$subscriptionId/detail-composite',
    );

    return SubscriptionDetailComposite.fromJson(
      response as Map<String, dynamic>,
    );
  }

  Future<void> clearCache() async {
    await _checksumBox?.clear();
    await _compositeBox?.clear();
  }

  Future<void> clearDetailCache(int eventId) async {
    await _checksumBox?.delete('detail_checksum_$eventId');
    await _compositeBox?.delete('detail_composite_$eventId');
  }

  Future<void> clearListCache() async {
    await _checksumBox?.delete('list_composite');
    await _compositeBox?.delete('list_composite');
  }

  Future<InviteUsersComposite> smartSyncInviteUsers(int eventId) async {
    print(
      '🟢 [CompositeSyncService] smartSyncInviteUsers START (eventId: $eventId)',
    );
    final stopwatch = Stopwatch()..start();

    try {
      print('🟢 [CompositeSyncService] Step 1: Getting checksum...');
      final serverChecksum = await _getInviteUsersChecksum(eventId);
      print('🟢 [CompositeSyncService] Step 1: Got checksum: $serverChecksum');

      final cacheKey = 'invite_users_composite_$eventId';
      final checksumKey = 'invite_users_checksum_$eventId';
      final cachedChecksum = _checksumBox?.get(checksumKey);
      print(
        '🟢 [CompositeSyncService] Step 2: Cached checksum: $cachedChecksum',
      );

      if (cachedChecksum == serverChecksum && cachedChecksum != null) {
        print('🟢 [CompositeSyncService] Cache HIT! Loading from Hive...');
        final cachedData = _compositeBox?.get(cacheKey);
        if (cachedData != null) {
          final composite = InviteUsersComposite.fromJson(
            Map<String, dynamic>.from(cachedData),
          );
          print(
            '🟢 [CompositeSyncService] Loaded from cache, available users: ${composite.availableUsers.length}',
          );
          return composite;
        }

        print('🟡 [CompositeSyncService] Cache corrupted, fetching...');
      } else {
        print(
          '🟢 [CompositeSyncService] Cache MISS (server: $serverChecksum, cached: $cachedChecksum)',
        );
      }

      print('🟢 [CompositeSyncService] Step 3: Fetching composite data...');
      final composite = await _fetchInviteUsersComposite(eventId);
      print(
        '🟢 [CompositeSyncService] Step 3: Got composite data, available users: ${composite.availableUsers.length}',
      );

      print('🟢 [CompositeSyncService] Step 4: Updating cache...');
      await _checksumBox?.put(checksumKey, composite.checksum);
      await _compositeBox?.put(cacheKey, composite.toJson());
      print('🟢 [CompositeSyncService] Step 4: Cache updated');

      stopwatch.stop();
      print(
        '🟢 [CompositeSyncService] smartSyncInviteUsers COMPLETE (${stopwatch.elapsedMilliseconds}ms)',
      );

      return composite;
    } catch (e) {
      print('🔴 [CompositeSyncService] ERROR: $e');
      rethrow;
    }
  }

  Future<String> _getInviteUsersChecksum(int eventId) async {
    final response = await ApiClientFactory.instance.get(
      '/api/v1/events/$eventId/invite-composite/checksum',
    );

    return response['checksum'] as String;
  }

  Future<InviteUsersComposite> _fetchInviteUsersComposite(int eventId) async {
    final response = await ApiClientFactory.instance.get(
      '/api/v1/events/$eventId/invite-composite',
    );

    return InviteUsersComposite.fromJson(response as Map<String, dynamic>);
  }

  Future<void> clearInviteUsersCache(int eventId) async {
    await _checksumBox?.delete('invite_users_checksum_$eventId');
    await _compositeBox?.delete('invite_users_composite_$eventId');
  }

  Future<PeopleGroupsComposite> smartSyncPeopleGroups() async {
    print('🟢 [CompositeSyncService] smartSyncPeopleGroups START');
    final stopwatch = Stopwatch()..start();

    try {
      print('🟢 [CompositeSyncService] Step 1: Getting checksum...');
      final serverChecksum = await _getPeopleGroupsChecksum();
      print('🟢 [CompositeSyncService] Step 1: Got checksum: $serverChecksum');

      final cacheKey = 'people_groups_composite';
      final checksumKey = 'people_groups_checksum';
      final cachedChecksum = _checksumBox?.get(checksumKey);
      print(
        '🟢 [CompositeSyncService] Step 2: Cached checksum: $cachedChecksum',
      );

      if (cachedChecksum == serverChecksum && cachedChecksum != null) {
        print('🟢 [CompositeSyncService] Cache HIT! Loading from Hive...');
        final cachedData = _compositeBox?.get(cacheKey);
        if (cachedData != null) {
          final composite = PeopleGroupsComposite.fromJson(
            Map<String, dynamic>.from(cachedData),
          );
          print(
            '🟢 [CompositeSyncService] Loaded from cache, contacts: ${composite.contacts.length}, groups: ${composite.groups.length}',
          );
          return composite;
        }

        print('🟡 [CompositeSyncService] Cache corrupted, fetching...');
      } else {
        print(
          '🟢 [CompositeSyncService] Cache MISS (server: $serverChecksum, cached: $cachedChecksum)',
        );
      }

      print('🟢 [CompositeSyncService] Step 3: Fetching composite data...');
      final composite = await _fetchPeopleGroupsComposite();
      print(
        '🟢 [CompositeSyncService] Step 3: Got composite data, contacts: ${composite.contacts.length}, groups: ${composite.groups.length}',
      );

      print('🟢 [CompositeSyncService] Step 4: Updating cache...');
      await _checksumBox?.put(checksumKey, composite.checksum);
      await _compositeBox?.put(cacheKey, composite.toJson());
      print('🟢 [CompositeSyncService] Step 4: Cache updated');

      stopwatch.stop();
      print(
        '🟢 [CompositeSyncService] smartSyncPeopleGroups COMPLETE (${stopwatch.elapsedMilliseconds}ms)',
      );

      return composite;
    } catch (e) {
      print('🔴 [CompositeSyncService] ERROR: $e');
      rethrow;
    }
  }

  Future<String> _getPeopleGroupsChecksum() async {
    final response = await ApiClientFactory.instance.get(
      '/api/v1/users/people-groups-composite/checksum',
    );

    return response['checksum'] as String;
  }

  Future<PeopleGroupsComposite> _fetchPeopleGroupsComposite() async {
    final response = await ApiClientFactory.instance.get(
      '/api/v1/users/people-groups-composite',
    );

    return PeopleGroupsComposite.fromJson(response as Map<String, dynamic>);
  }

  Future<void> clearPeopleGroupsCache() async {
    await _checksumBox?.delete('people_groups_checksum');
    await _compositeBox?.delete('people_groups_composite');
  }

  Future<PublicUserEventsComposite> smartSyncPublicUserEvents(
    int userId,
  ) async {
    print(
      '🟢 [CompositeSyncService] smartSyncPublicUserEvents START (userId: $userId)',
    );
    final stopwatch = Stopwatch()..start();

    try {
      print('🟢 [CompositeSyncService] Step 1: Getting checksum...');
      final serverChecksum = await _getPublicUserEventsChecksum(userId);
      print('🟢 [CompositeSyncService] Step 1: Got checksum: $serverChecksum');

      final cacheKey = 'public_user_events_composite_$userId';
      final checksumKey = 'public_user_events_checksum_$userId';
      final cachedChecksum = _checksumBox?.get(checksumKey);
      print(
        '🟢 [CompositeSyncService] Step 2: Cached checksum: $cachedChecksum',
      );

      if (cachedChecksum == serverChecksum && cachedChecksum != null) {
        print('🟢 [CompositeSyncService] Cache HIT! Loading from Hive...');
        final cachedData = _compositeBox?.get(cacheKey);
        if (cachedData != null) {
          final composite = PublicUserEventsComposite.fromJson(
            Map<String, dynamic>.from(cachedData),
          );
          print(
            '🟢 [CompositeSyncService] Loaded from cache, events: ${composite.events.length}',
          );
          return composite;
        }

        print('🟡 [CompositeSyncService] Cache corrupted, fetching...');
      } else {
        print(
          '🟢 [CompositeSyncService] Cache MISS (server: $serverChecksum, cached: $cachedChecksum)',
        );
      }

      print('🟢 [CompositeSyncService] Step 3: Fetching composite data...');
      final composite = await _fetchPublicUserEventsComposite(userId);
      print(
        '🟢 [CompositeSyncService] Step 3: Got composite data, events: ${composite.events.length}',
      );

      print('🟢 [CompositeSyncService] Step 4: Updating cache...');
      await _checksumBox?.put(checksumKey, composite.checksum);
      await _compositeBox?.put(cacheKey, composite.toJson());
      print('🟢 [CompositeSyncService] Step 4: Cache updated');

      stopwatch.stop();
      print(
        '🟢 [CompositeSyncService] smartSyncPublicUserEvents COMPLETE (${stopwatch.elapsedMilliseconds}ms)',
      );

      return composite;
    } catch (e) {
      print('🔴 [CompositeSyncService] ERROR: $e');
      rethrow;
    }
  }

  Future<String> _getPublicUserEventsChecksum(int userId) async {
    final response = await ApiClientFactory.instance.get(
      '/api/v1/users/$userId/public-events-composite/checksum',
    );

    return response['checksum'] as String;
  }

  Future<PublicUserEventsComposite> _fetchPublicUserEventsComposite(
    int userId,
  ) async {
    final response = await ApiClientFactory.instance.get(
      '/api/v1/users/$userId/public-events-composite',
    );

    return PublicUserEventsComposite.fromJson(response as Map<String, dynamic>);
  }

  Future<void> clearPublicUserEventsCache(int userId) async {
    await _checksumBox?.delete('public_user_events_checksum_$userId');
    await _compositeBox?.delete('public_user_events_composite_$userId');
  }

  Future<ContactDetailComposite> smartSyncContactDetail(int contactId) async {
    print(
      '🟢 [CompositeSyncService] smartSyncContactDetail START (contactId: $contactId)',
    );
    final stopwatch = Stopwatch()..start();

    try {
      final serverChecksum = await _getContactDetailChecksum(contactId);

      final cacheKey = 'contact_detail_composite_$contactId';
      final checksumKey = 'contact_detail_checksum_$contactId';
      final cachedChecksum = _checksumBox?.get(checksumKey);

      if (cachedChecksum == serverChecksum && cachedChecksum != null) {
        final cachedData = _compositeBox?.get(cacheKey);
        if (cachedData != null) {
          final composite = ContactDetailComposite.fromJson(
            Map<String, dynamic>.from(cachedData),
          );
          return composite;
        }
      }

      final composite = await _fetchContactDetailComposite(contactId);

      await _checksumBox?.put(checksumKey, composite.checksum);
      await _compositeBox?.put(cacheKey, composite.toJson());

      stopwatch.stop();
      return composite;
    } catch (e) {
      print('🔴 [CompositeSyncService] ERROR: $e');
      rethrow;
    }
  }

  Future<String> _getContactDetailChecksum(int contactId) async {
    final response = await ApiClientFactory.instance.get(
      '/api/v1/users/$contactId/contact-detail-composite/checksum',
    );
    return response['checksum'] as String;
  }

  Future<ContactDetailComposite> _fetchContactDetailComposite(
    int contactId,
  ) async {
    final response = await ApiClientFactory.instance.get(
      '/api/v1/users/$contactId/contact-detail-composite',
    );
    return ContactDetailComposite.fromJson(response as Map<String, dynamic>);
  }

  Future<void> clearContactDetailCache(int contactId) async {
    await _checksumBox?.delete('contact_detail_checksum_$contactId');
    await _compositeBox?.delete('contact_detail_composite_$contactId');
  }
}
