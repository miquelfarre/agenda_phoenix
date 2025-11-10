import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/realtime_sync.dart';
import '../models/domain/user_contact.dart';
import '../models/persistence/user_contact_hive.dart';
import '../services/api_client.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../utils/realtime_filter.dart';
import 'contracts/user_contact_repository_contract.dart';

class UserContactRepository implements IUserContactRepository {
  static const String _boxName = 'user_contacts';
  final SupabaseService _supabaseService = SupabaseService.instance;
  final _apiClient = ApiClient();
  final RealtimeSync _rt = RealtimeSync();

  Box<UserContactHive>? _box;
  RealtimeChannel? _realtimeChannel;
  final StreamController<List<UserContact>> _contactsStreamController =
      StreamController<List<UserContact>>.broadcast();

  List<UserContact> _cachedContacts = [];

  final Completer<void> _initCompleter = Completer<void>();

  @override
  Future<void> get initialized => _initCompleter.future;

  @override
  Stream<List<UserContact>> get dataStream => contactsStream;

  @override
  Stream<List<UserContact>> get contactsStream async* {
    if (_cachedContacts.isNotEmpty) {
      yield List.from(_cachedContacts);
    }
    yield* _contactsStreamController.stream;
  }

  @override
  Future<void> initialize() async {
    if (_initCompleter.isCompleted) return;

    try {
      _box = await Hive.openBox<UserContactHive>(_boxName);

      _loadContactsFromHive();

      await _fetchAndSync();

      await _startRealtimeSubscription();

      _emitCurrentContacts();

      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
      rethrow;
    }
  }

  void _loadContactsFromHive() {
    if (_box == null) return;

    try {
      _cachedContacts = _box!.values
          .map((hive) => hive.toUserContact())
          .toList();
    } catch (e) {
      _cachedContacts = [];
    }
  }

  Future<void> _fetchAndSync() async {
    try {
      final apiData = await _apiClient.getMyContacts(
        onlyRegistered: true,
        limit: 200,
      );

      _cachedContacts = apiData
          .map((json) => UserContact.fromJson(json as Map<String, dynamic>))
          .toList();

      await _updateLocalCache(_cachedContacts);

      _rt.setServerSyncTs(DateTime.now().toUtc());
      _emitCurrentContacts();
    } catch (e) {
      // If API fails, keep cached data
    }
  }

  Future<void> _updateLocalCache(List<UserContact> contacts) async {
    if (_box == null) return;

    try {
      await _box!.clear();
      for (final contact in contacts) {
        final contactHive = UserContactHive.fromUserContact(contact);
        await _box!.put(contact.id, contactHive);
      }
    } catch (e) {
      // Ignore cache update errors
    }
  }

  @override
  Future<ContactSyncResponse> syncContacts(List<ContactInfo> contacts) async {
    final contactsData = contacts
        .map(
          (c) => {'contact_name': c.contactName, 'phone_number': c.phoneNumber},
        )
        .toList();

    final result = await _apiClient.syncContacts(contacts: contactsData);

    // After sync, refresh contacts list
    await _fetchAndSync();

    return ContactSyncResponse.fromJson(result);
  }

  @override
  Future<List<UserContact>> fetchContacts({
    bool onlyRegistered = true,
    int limit = 100,
    int skip = 0,
  }) async {
    final apiData = await _apiClient.getMyContacts(
      onlyRegistered: onlyRegistered,
      limit: limit,
      skip: skip,
    );

    return apiData
        .map((json) => UserContact.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> refresh() async {
    await _fetchAndSync();
  }

  @override
  Future<void> startRealtimeSubscription() async {
    await _startRealtimeSubscription();
  }

  @override
  Future<void> stopRealtimeSubscription() async {
    await _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  @override
  bool get isRealtimeConnected => _realtimeChannel != null;

  @override
  Future<void> loadFromCache() async {
    _loadContactsFromHive();
  }

  @override
  Future<void> saveToCache() async {
    await _updateLocalCache(_cachedContacts);
  }

  @override
  Future<void> clearCache() async {
    _cachedContacts = [];
    await _box?.clear();
    _emitCurrentContacts();
  }

  @override
  List<UserContact> getLocalData() => getLocalContacts();

  @override
  List<UserContact> getLocalContacts() {
    return List.from(_cachedContacts);
  }

  @override
  UserContact? getContactById(int id) {
    try {
      return _cachedContacts.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  UserContact? getContactByPhone(String phoneNumber) {
    try {
      return _cachedContacts.firstWhere((c) => c.phoneNumber == phoneNumber);
    } catch (e) {
      return null;
    }
  }

  Future<void> _startRealtimeSubscription() async {
    final configService = ConfigService.instance;
    if (!configService.hasUser) return;

    final userId = configService.currentUserId;

    _realtimeChannel = _supabaseService.client
        .channel('user_contacts_${userId}_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_contacts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'owner_id',
            value: userId.toString(),
          ),
          callback: _handleContactChange,
        )
        .subscribe();
  }

  void _handleContactChange(PostgresChangePayload payload) {
    if (!RealtimeFilter.shouldProcessEvent(payload, 'user_contact', _rt)) {
      return;
    }

    try {
      // Refresh the full list when any contact changes
      _fetchAndSync();
    } catch (e) {
      // Ignore realtime handler errors
    }
  }

  void _emitCurrentContacts() {
    if (!_contactsStreamController.isClosed) {
      _contactsStreamController.add(List.from(_cachedContacts));
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _contactsStreamController.close();
    _box?.close();
  }
}
