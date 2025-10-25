import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';

class GroupRepository {
  final _supabaseService = SupabaseService.instance;

  final StreamController<List<Group>> _groupsController =
      StreamController<List<Group>>.broadcast();
  List<Group> _cachedGroups = [];
  DateTime? _initialSyncTime;
  RealtimeChannel? _realtimeChannel;

  Stream<List<Group>> get groupsStream => _groupsController.stream;

  Future<void> initialize() async {
    await _fetchAndSync();
    await _startRealtimeSubscription();
    _emitCurrentGroups();
  }

  Future<void> _fetchAndSync() async {
    try {
      _initialSyncTime = DateTime.now().toUtc();
      final userId = ConfigService.instance.currentUserId;

      // Fetch groups where user is a member
      final response = await _supabaseService.client
          .from('groups')
          .select('*')
          .contains('member_ids', [userId]);

      _cachedGroups = (response as List)
          .map((json) => Group.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching groups: $e');
    }
  }

  Future<void> _startRealtimeSubscription() async {
    // Listen to ALL group changes and filter client-side
    _realtimeChannel = _supabaseService.client
        .channel('groups_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'groups',
          callback: _handleGroupChange,
        )
        .subscribe();
  }

  void _handleGroupChange(PostgresChangePayload payload) {
    final eventTime = DateTime.tryParse(payload.commitTimestamp.toString());
    if (eventTime != null &&
        _initialSyncTime != null &&
        eventTime.isBefore(_initialSyncTime!)) {
      return;
    }

    final userId = ConfigService.instance.currentUserId;

    if (payload.eventType == PostgresChangeEvent.insert ||
        payload.eventType == PostgresChangeEvent.update) {
      final groupData = payload.newRecord;
      final memberIds = (groupData['member_ids'] as List?)?.cast<int>() ?? [];
      final isUserMember = memberIds.contains(userId);

      if (isUserMember) {
        final group = Group.fromJson(groupData);
        final existingIndex = _cachedGroups.indexWhere((g) => g.id == group.id);
        if (existingIndex != -1) {
          _cachedGroups[existingIndex] = group;
        } else {
          _cachedGroups.add(group);
        }
        _emitCurrentGroups();
      } else {
        // User removed from group
        final groupId = groupData['id'] as int?;
        if (groupId != null) {
          _cachedGroups.removeWhere((g) => g.id == groupId);
          _emitCurrentGroups();
        }
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      final groupId = payload.oldRecord['id'] as int?;
      if (groupId != null) {
        _cachedGroups.removeWhere((g) => g.id == groupId);
        _emitCurrentGroups();
      }
    }
  }

  void _emitCurrentGroups() {
    if (!_groupsController.isClosed) {
      _groupsController.add(List.from(_cachedGroups));
    }
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _groupsController.close();
  }
}
