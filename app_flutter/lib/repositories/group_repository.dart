import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';
import '../models/group_hive.dart';
import '../services/api_client.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../core/realtime_sync.dart';
import '../utils/app_exceptions.dart' as exceptions;

class GroupRepository {
  static const String _boxName = 'groups';
  final _supabaseService = SupabaseService.instance;
  final _apiClient = ApiClient();
  final RealtimeSync _rt = RealtimeSync();

  Box<GroupHive>? _box;
  final StreamController<List<Group>> _groupsController =
      StreamController<List<Group>>.broadcast();
  List<Group> _cachedGroups = [];
  RealtimeChannel? _realtimeChannel;

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  Stream<List<Group>> get groupsStream async* {
    // Wait for initialization to complete
    try {
      await initialized;
    } catch (e) {
      // If initialization failed, still emit empty list to avoid infinite loading
    }

    // Emit cached groups immediately
    if (_cachedGroups.isNotEmpty) {
      yield List.from(_cachedGroups);
    } else {
      // Emit empty list to avoid infinite loading state
      yield [];
    }

    // Then emit future updates
    yield* _groupsController.stream;
  }

  Future<void> initialize() async {
    if (_initCompleter.isCompleted) return;

    try {
      _box = await Hive.openBox<GroupHive>(_boxName);

      // Load groups from Hive cache first (if any)
      _loadGroupsFromHive();

      // Fetch and sync groups from API BEFORE subscribing to Realtime
      await _fetchAndSync();

      // Now subscribe to Realtime for future updates
      await _startRealtimeSubscription();

      _emitCurrentGroups();

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

  void _loadGroupsFromHive() {
    if (_box == null) return;

    try {
      _cachedGroups = _box!.values
          .map((groupHive) => groupHive.toGroup())
          .toList();
    } catch (e) {
      _cachedGroups = [];
    }
  }

  Future<void> _fetchAndSync() async {
    try {
      final userId = ConfigService.instance.currentUserId;
      final response = await _apiClient.fetchGroups(currentUserId: userId);
      _cachedGroups = response.map((data) => Group.fromJson(data)).toList();

      await _updateLocalCache(_cachedGroups);

      _rt.setServerSyncTsFromResponse(
        rows: _cachedGroups.map((g) => g.toJson()),
      );
      _emitCurrentGroups();
    } catch (e) {
      // Emit current cached groups even on error (offline support)
      _emitCurrentGroups();
      // Log error but don't throw to allow app to continue with cached data
    }
  }

  Future<void> _updateLocalCache(List<Group> groups) async {
    if (_box == null) return;

    await _box!.clear();

    for (final group in groups) {
      final groupHive = GroupHive.fromGroup(group);
      await _box!.put(group.id, groupHive);
    }
  }

  // --- Mutations ---

  Future<Group> createGroup({required String name, String? description}) async {
    try {
      final ownerId = ConfigService.instance.currentUserId;
      final newGroup = await _apiClient.createGroup({
        'name': name,
        'description': description,
        'owner_id': ownerId,
      });
      await _fetchAndSync();
      return Group.fromJson(newGroup);
    } catch (e, _) {
      rethrow;
    }
  }

  Future<Group> updateGroup({
    required int groupId,
    String? name,
    String? description,
  }) async {
    try {
      final userId = ConfigService.instance.currentUserId;
      _validateAdminPermissions(groupId, userId);

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;

      final updatedGroup = await _apiClient.updateGroup(groupId, updateData);
      await _fetchAndSync();
      return Group.fromJson(updatedGroup);
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> deleteGroup({required int groupId}) async {
    try {
      final userId = ConfigService.instance.currentUserId;
      final group = _getGroupFromCache(groupId);

      if (!group.isCreator(userId)) {
        throw const exceptions.PermissionDeniedException(
          message: 'Only group creator can delete the group',
        );
      }

      await _apiClient.deleteGroup(groupId);
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> addMemberToGroup({
    required int groupId,
    required int memberUserId,
  }) async {
    try {
      final adminUserId = ConfigService.instance.currentUserId;
      _validateMemberOperationPermissions(
        groupId,
        memberUserId,
        adminUserId,
        'add',
      );
      await _apiClient.createGroupMembership({
        'group_id': groupId,
        'user_id': memberUserId,
      });
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> removeMemberFromGroup({
    required int groupId,
    required int memberUserId,
  }) async {
    try {
      final adminUserId = ConfigService.instance.currentUserId;
      _validateMemberOperationPermissions(
        groupId,
        memberUserId,
        adminUserId,
        'remove',
      );
      final memberships = await _apiClient.fetchGroupMemberships(
        groupId: groupId,
        userId: memberUserId,
      );
      if (memberships.isEmpty) {
        throw exceptions.NotFoundException(
          message:
              'Membership not found for user $memberUserId in group $groupId',
        );
      }
      final membershipId = memberships[0]['id'];
      await _apiClient.deleteGroupMembership(membershipId);
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> leaveGroup(int groupId) async {
    try {
      final userId = ConfigService.instance.currentUserId;
      final group = _getGroupFromCache(groupId);

      if (group.isCreator(userId)) {
        throw const exceptions.ConflictException(
          message: 'Group creator cannot leave. Delete the group instead.',
        );
      }

      final memberships = await _apiClient.fetchGroupMemberships(
        groupId: groupId,
        userId: userId,
      );
      if (memberships.isEmpty) {
        throw exceptions.NotFoundException(
          message: 'Membership not found for user $userId in group $groupId',
        );
      }
      final membershipId = memberships[0]['id'];
      await _apiClient.deleteGroupMembership(membershipId);
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> grantAdminPermission({
    required int groupId,
    required int userId,
  }) async {
    try {
      final memberships = await _apiClient.fetchGroupMemberships(
        groupId: groupId,
        userId: userId,
      );
      if (memberships.isEmpty) {
        throw exceptions.NotFoundException(
          message: 'Membership not found for user $userId in group $groupId',
        );
      }
      final membershipId = memberships[0]['id'];
      await _apiClient.updateGroupMembership(membershipId, {'role': 'admin'});
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  Future<void> removeAdminPermission({
    required int groupId,
    required int userId,
  }) async {
    try {
      final memberships = await _apiClient.fetchGroupMemberships(
        groupId: groupId,
        userId: userId,
      );
      if (memberships.isEmpty) {
        throw exceptions.NotFoundException(
          message: 'Membership not found for user $userId in group $groupId',
        );
      }
      final membershipId = memberships[0]['id'];
      await _apiClient.updateGroupMembership(membershipId, {'role': 'member'});
      await _fetchAndSync();
    } catch (e, _) {
      rethrow;
    }
  }

  // --- Local cache and realtime ---

  Future<void> _startRealtimeSubscription() async {
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
    final ct = DateTime.tryParse(payload.commitTimestamp.toString());
    final userId = ConfigService.instance.currentUserId;

    if (payload.eventType == PostgresChangeEvent.insert ||
        payload.eventType == PostgresChangeEvent.update) {
      if (!_rt.shouldProcessInsertOrUpdate(ct)) {
        return;
      }

      final groupData = payload.newRecord;
      final group = Group.fromJson(groupData);
      final isUserMember = group.members.any((m) => m.id == userId);

      if (isUserMember) {
        final existingIndex = _cachedGroups.indexWhere((g) => g.id == group.id);
        if (existingIndex != -1) {
          _cachedGroups[existingIndex] = group;
        } else {
          _cachedGroups.add(group);
        }

        // Update Hive cache
        final groupHive = GroupHive.fromGroup(group);
        _box?.put(group.id, groupHive);

        _emitCurrentGroups();
      } else {
        final groupId = groupData['id'] as int?;
        if (groupId != null) {
          _cachedGroups.removeWhere((g) => g.id == groupId);
          _box?.delete(groupId);
          _emitCurrentGroups();
        }
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      if (!_rt.shouldProcessDelete()) return;

      final groupId = payload.oldRecord['id'] as int?;
      if (groupId != null) {
        _cachedGroups.removeWhere((g) => g.id == groupId);
        _box?.delete(groupId);
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
    _box?.close();
  }

  // --- Helpers ---

  Group _getGroupFromCache(int groupId) {
    return _cachedGroups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => throw exceptions.NotFoundException(
        message: 'Group not found in cache',
      ),
    );
  }

  void _validateAdminPermissions(int groupId, int userId) {
    final group = _getGroupFromCache(groupId);
    if (!group.isAdmin(userId)) {
      throw const exceptions.PermissionDeniedException(
        message: 'No permission to update group',
      );
    }
  }

  void _validateMemberOperationPermissions(
    int groupId,
    int memberUserId,
    int adminUserId,
    String operationType,
  ) {
    final group = _getGroupFromCache(groupId);
    if (operationType == 'add') {
      if (!group.isAdmin(adminUserId)) {
        throw const exceptions.PermissionDeniedException(
          message: 'No permission to add members to group',
        );
      }
      if (group.members.any((m) => m.id == memberUserId)) {
        throw const exceptions.ConflictException(
          message: 'User is already a member of this group',
        );
      }
    } else if (operationType == 'remove') {
      if (!group.isAdmin(adminUserId) && adminUserId != memberUserId) {
        throw const exceptions.PermissionDeniedException(
          message: 'No permission to remove member from group',
        );
      }
      if (memberUserId == group.ownerId) {
        throw const exceptions.ConflictException(
          message: 'Cannot remove group owner',
        );
      }
      if (!group.members.any((m) => m.id == memberUserId)) {
        throw const exceptions.NotFoundException(
          message: 'User is not a member of this group',
        );
      }
    }
  }
}
