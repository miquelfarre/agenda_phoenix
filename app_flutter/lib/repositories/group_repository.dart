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

  Stream<List<Group>> get groupsStream async* {
    if (_cachedGroups.isNotEmpty) {
      yield List.from(_cachedGroups);
    }
    yield* _groupsController.stream;
  }

  Future<void> initialize() async {
    print('🚀 [GroupRepository] Initializing...');
    _box = await Hive.openBox<GroupHive>(_boxName);

    // Load groups from Hive cache first (if any)
    _loadGroupsFromHive();

    // Fetch and sync groups from API BEFORE subscribing to Realtime
    await _fetchAndSync();

    // Now subscribe to Realtime for future updates
    await _startRealtimeSubscription();

    _emitCurrentGroups();
    print('✅ [GroupRepository] Initialization complete');
  }

  void _loadGroupsFromHive() {
    if (_box == null) return;

    try {
      _cachedGroups = _box!.values
          .map((groupHive) => groupHive.toGroup())
          .toList();

      print('✅ [GroupRepository] Loaded ${_cachedGroups.length} groups from Hive cache');
    } catch (e) {
      print('❌ [GroupRepository] Error loading from Hive: $e');
      _cachedGroups = [];
    }
  }

  Future<void> _fetchAndSync() async {
    try {
      print('📡 [GroupRepository] Fetching groups from API...');
      final userId = ConfigService.instance.currentUserId;
      final response = await _apiClient.fetchGroups(currentUserId: userId);
      _cachedGroups = response.map((data) => Group.fromJson(data)).toList();

      await _updateLocalCache(_cachedGroups);

      _rt.setServerSyncTsFromResponse(
        rows: _cachedGroups.map((g) => g.toJson()),
      );
      _emitCurrentGroups();
      print('✅ [GroupRepository] Fetched ${_cachedGroups.length} groups');
    } catch (e) {
      print('❌ [GroupRepository] Error fetching groups: $e');
    }
  }

  Future<void> _updateLocalCache(List<Group> groups) async {
    if (_box == null) return;

    print('💾 [GroupRepository] Updating Hive cache with ${groups.length} groups...');
    await _box!.clear();

    for (final group in groups) {
      final groupHive = GroupHive.fromGroup(group);
      await _box!.put(group.id, groupHive);
    }
    print('✅ [GroupRepository] Hive cache updated');
  }

  // --- Mutations ---

  Future<Group> createGroup({
    required String name,
    String? description,
  }) async {
    print('➕ [GroupRepository] Creating group: "$name"');
    final creatorId = ConfigService.instance.currentUserId;
    final newGroup = await _apiClient.createGroup({
      'name': name,
      'description': description,
      'creator_id': creatorId,
    });
    await _fetchAndSync();
    print('✅ [GroupRepository] Group created: "${newGroup['name']}"');
    return Group.fromJson(newGroup);
  }

  Future<Group> updateGroup({
    required int groupId,
    String? name,
    String? description,
  }) async {
    print('🔄 [GroupRepository] Updating group ID $groupId');
    final userId = ConfigService.instance.currentUserId;
    _validateAdminPermissions(groupId, userId);

    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;

    final updatedGroup = await _apiClient.updateGroup(groupId, updateData);
    await _fetchAndSync();
    print('✅ [GroupRepository] Group updated: ID $groupId');
    return Group.fromJson(updatedGroup);
  }

  Future<void> deleteGroup({required int groupId}) async {
    print('🗑️ [GroupRepository] deleteGroup START - groupId: $groupId');
    final userId = ConfigService.instance.currentUserId;
    final group = _getGroupFromCache(groupId);

    print('🗑️ [GroupRepository] Group in cache: "${group.name}"');
    print('🗑️ [GroupRepository] Cache size before: ${_cachedGroups.length}');

    if (!group.isCreator(userId)) {
      print('❌ [GroupRepository] Permission denied: Only creator can delete');
      throw const exceptions.PermissionDeniedException(
        message: 'Only group creator can delete the group',
      );
    }

    await _apiClient.deleteGroup(groupId);
    await _fetchAndSync();

    print('🗑️ [GroupRepository] Cache size after: ${_cachedGroups.length}');
    print('✅ [GroupRepository] Group deleted: ID $groupId');
  }

  Future<void> addMemberToGroup({
    required int groupId,
    required int memberUserId,
  }) async {
    print('👥 [GroupRepository] Adding user $memberUserId to group $groupId');
    final adminUserId = ConfigService.instance.currentUserId;
    _validateMemberOperationPermissions(groupId, memberUserId, adminUserId, 'add');
    await _apiClient.createGroupMembership({
      'group_id': groupId,
      'user_id': memberUserId,
    });
    await _fetchAndSync();
    print('✅ [GroupRepository] Member $memberUserId added to group $groupId');
  }

  Future<void> removeMemberFromGroup({
    required int groupId,
    required int memberUserId,
  }) async {
    print('👥 [GroupRepository] Removing user $memberUserId from group $groupId');
    final adminUserId = ConfigService.instance.currentUserId;
    _validateMemberOperationPermissions(groupId, memberUserId, adminUserId, 'remove');
    final memberships = await _apiClient.fetchGroupMemberships(groupId: groupId, userId: memberUserId);
    if (memberships.isEmpty) {
      print('❌ [GroupRepository] Membership not found');
      throw exceptions.NotFoundException(
        message: 'Membership not found for user $memberUserId in group $groupId',
      );
    }
    final membershipId = memberships[0]['id'];
    await _apiClient.deleteGroupMembership(membershipId);
    await _fetchAndSync();
    print('✅ [GroupRepository] Member $memberUserId removed from group $groupId');
  }

  Future<void> leaveGroup(int groupId) async {
    print('🚪 [GroupRepository] User leaving group $groupId');
    final userId = ConfigService.instance.currentUserId;
    final group = _getGroupFromCache(groupId);

    if (group.isCreator(userId)) {
      print('❌ [GroupRepository] Creator cannot leave group');
      throw const exceptions.ConflictException(
        message: 'Group creator cannot leave. Delete the group instead.',
      );
    }

    final memberships = await _apiClient.fetchGroupMemberships(groupId: groupId, userId: userId);
    if (memberships.isEmpty) {
      print('❌ [GroupRepository] Membership not found');
      throw exceptions.NotFoundException(
        message: 'Membership not found for user $userId in group $groupId',
      );
    }
    final membershipId = memberships[0]['id'];
    await _apiClient.deleteGroupMembership(membershipId);
    // No full sync, just remove locally for faster UI update
    removeGroupFromCache(groupId);
    print('✅ [GroupRepository] User left group $groupId');
  }

  Future<void> grantAdminPermission({
    required int groupId,
    required int userId,
  }) async {
    print('👑 [GroupRepository] Granting admin permission to user $userId in group $groupId');
    final memberships = await _apiClient.fetchGroupMemberships(groupId: groupId, userId: userId);
    if (memberships.isEmpty) {
      print('❌ [GroupRepository] Membership not found');
      throw exceptions.NotFoundException(
        message: 'Membership not found for user $userId in group $groupId',
      );
    }
    final membershipId = memberships[0]['id'];
    await _apiClient.updateGroupMembership(membershipId, {'role': 'admin'});
    await _fetchAndSync();
    print('✅ [GroupRepository] Admin permission granted to user $userId');
  }

  Future<void> removeAdminPermission({
    required int groupId,
    required int userId,
  }) async {
    print('👑 [GroupRepository] Removing admin permission from user $userId in group $groupId');
    final memberships = await _apiClient.fetchGroupMemberships(groupId: groupId, userId: userId);
    if (memberships.isEmpty) {
      print('❌ [GroupRepository] Membership not found');
      throw exceptions.NotFoundException(
        message: 'Membership not found for user $userId in group $groupId',
      );
    }
    final membershipId = memberships[0]['id'];
    await _apiClient.updateGroupMembership(membershipId, {'role': 'member'});
    await _fetchAndSync();
    print('✅ [GroupRepository] Admin permission removed from user $userId');
  }

  // --- Local cache and realtime ---

  void removeGroupFromCache(int groupId) {
    print('🗑️ [GroupRepository] removeGroupFromCache START - groupId: $groupId');

    final groupBefore = _cachedGroups.where((g) => g.id == groupId).firstOrNull;
    print('🗑️ [GroupRepository] Group in cache: ${groupBefore != null ? '"${groupBefore.name}"' : 'NOT FOUND'}');

    final initialCount = _cachedGroups.length;
    print('🗑️ [GroupRepository] Cache size before: $initialCount');

    _cachedGroups.removeWhere((group) => group.id == groupId);
    print('🗑️ [GroupRepository] Cache size after: ${_cachedGroups.length}');

    _box?.delete(groupId);
    print('🗑️ [GroupRepository] Deleted from Hive box');

    if (_cachedGroups.length < initialCount) {
      print('🗑️ [GroupRepository] Emitting updated groups to stream...');
      _emitCurrentGroups();
      print('✅ [GroupRepository] Group manually removed and stream emitted - ID $groupId');
    } else {
      print('⚠️ [GroupRepository] Group $groupId not found in cache. No update emitted.');
    }
  }

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

    print('✅ [GroupRepository] Realtime subscription started for groups table');
  }

  void _handleGroupChange(PostgresChangePayload payload) {
    final ct = DateTime.tryParse(payload.commitTimestamp.toString());
    final userId = ConfigService.instance.currentUserId;

    if (payload.eventType == PostgresChangeEvent.insert ||
        payload.eventType == PostgresChangeEvent.update) {
      if (!_rt.shouldProcessInsertOrUpdate(ct)) {
        print('⏸️ [GroupRepository] Event skipped by time gate');
        return;
      }
      print('🔄 [GroupRepository] ${payload.eventType == PostgresChangeEvent.insert ? 'INSERT' : 'UPDATE'} detected');

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
        print('✅ [GroupRepository] Cache updated for group ${group.id}');
      } else {
        final groupId = groupData['id'] as int?;
        if (groupId != null) {
          _cachedGroups.removeWhere((g) => g.id == groupId);
          _box?.delete(groupId);
          _emitCurrentGroups();
          print('✅ [GroupRepository] Group $groupId removed (user no longer member)');
        }
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      if (!_rt.shouldProcessDelete()) return;
      print('🔄 [GroupRepository] DELETE detected');

      final groupId = payload.oldRecord['id'] as int?;
      if (groupId != null) {
        _cachedGroups.removeWhere((g) => g.id == groupId);
        _box?.delete(groupId);
        _emitCurrentGroups();
        print('✅ [GroupRepository] Group $groupId deleted');
      }
    }
  }

  void _emitCurrentGroups() {
    if (!_groupsController.isClosed) {
      _groupsController.add(List.from(_cachedGroups));
    }
  }

  void dispose() {
    print('👋 [GroupRepository] Disposing...');
    _realtimeChannel?.unsubscribe();
    _groupsController.close();
  }

  // --- Helpers ---

  Group _getGroupFromCache(int groupId) {
    return _cachedGroups.firstWhere((g) => g.id == groupId, orElse: () => throw exceptions.NotFoundException(message: 'Group not found in cache'));
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
      if (memberUserId == group.creatorId) {
        throw const exceptions.ConflictException(
          message: 'Cannot remove group creator',
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
