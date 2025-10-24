import 'dart:io';
import 'dart:async';
import 'package:hive_ce/hive.dart';
import '../models/group.dart';
import '../models/group_hive.dart';
import '../models/user.dart';
import '../services/config_service.dart';
import 'api_client.dart';
import '../utils/app_exceptions.dart' as exceptions;
import 'sync_service.dart';

class GroupService {
  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;
  GroupService._internal();

  String get serviceName => 'GroupService';
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      if (!Hive.isBoxOpen('groups')) {
        await Hive.openBox<GroupHive>('groups');
      }
      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  List<Group> getLocalGroups({bool includeDeleted = false}) {
    try {
      final userId = ConfigService.instance.currentUserId;
      final box = Hive.box<GroupHive>('groups');
      final allGroups = _convertAllGroupsFromHive(box);

      final userGroups = allGroups.where((group) {
        if (!group.isMember(userId)) return false;

        if (!includeDeleted && DeletionMarkers.isDeleted(group.name)) {
          return false;
        }
        return true;
      }).toList();

      return userGroups;
    } catch (e) {
      return [];
    }
  }

  List<Group> getUserGroups(int userId, {bool includeDeleted = false}) {
    return getLocalGroups(
      includeDeleted: includeDeleted,
    ).where((group) => group.isMember(userId)).toList();
  }

  Group? getGroupById(int groupId) {
    final box = Hive.box<GroupHive>('groups');
    final groupHive = box.get(groupId);
    if (groupHive == null) return null;
    return _groupHiveToGroup(groupHive);
  }

  Future<Group> createGroup({
    required String name,
    String? description,
    required int creatorId,
  }) async {
    try {
      final response = await ApiClientFactory.instance.post(
        '/api/v1/groups',
        body: {
          'name': name,
          'description': description,
          'creator_id': creatorId,
        },
      );

      final createdGroup = Group.fromJson(response);

      try {
        await SyncService.syncGroups(creatorId);
      } catch (e) {
        // Ignore sync errors - not critical for group creation
      }

      return createdGroup;
    } on SocketException {
      throw exceptions.ApiException('Internet connection required');
    } on TimeoutException {
      throw exceptions.ApiException('Server timeout. Try again.');
    } on exceptions.PermissionDeniedException {
      rethrow;
    } on exceptions.ConflictException {
      rethrow;
    } catch (e) {
      throw exceptions.ApiException('Failed to create group: $e');
    }
  }

  Future<Group> updateGroup({
    required int groupId,
    String? name,
    String? description,
    required int userId,
  }) async {
    try {
      final box = Hive.box<GroupHive>('groups');
      final existingGroup = box.get(groupId);
      if (existingGroup == null) {
        throw exceptions.NotFoundException(
          message: 'Group not found: $groupId',
        );
      }

      _validateAdminPermissions(existingGroup, userId);

      final updateData = <String, dynamic>{'id': groupId};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;

      final response = await ApiClientFactory.instance.put(
        '/api/v1/groups/$groupId',
        body: updateData,
      );

      final updatedGroup = Group.fromJson(response);

      try {
        await SyncService.syncGroups(userId);
      } catch (e) {
        // Ignore sync errors
      }

      return updatedGroup;
    } on SocketException {
      throw exceptions.ApiException('Internet connection required');
    } on TimeoutException {
      throw exceptions.ApiException('Server timeout. Try again.');
    } on exceptions.NotFoundException {
      try {
        await SyncService.syncGroups(userId);
      } catch (e) {
        // Ignore sync errors
      }
      rethrow;
    } on exceptions.PermissionDeniedException {
      rethrow;
    } on exceptions.ConflictException {
      rethrow;
    } catch (e) {
      throw exceptions.ApiException('Failed to update group: $e');
    }
  }

  Future<void> deleteGroup({required int groupId, required int userId}) async {
    try {
      final box = Hive.box<GroupHive>('groups');
      final existingGroup = box.get(groupId);
      if (existingGroup == null) {
        throw exceptions.NotFoundException(
          message: 'Group not found: $groupId',
        );
      }

      if (!existingGroup.isCreator(userId)) {
        throw const exceptions.PermissionDeniedException(
          message: 'Only group creator can delete the group',
        );
      }

      await ApiClientFactory.instance.delete('/api/v1/groups/$groupId');

      await SyncService.clearGroupCache(groupId);
    } on SocketException {
      throw exceptions.ApiException('Internet connection required');
    } on TimeoutException {
      throw exceptions.ApiException('Server timeout. Try again.');
    } on exceptions.NotFoundException {
      try {
        await SyncService.clearGroupCache(groupId);
      } catch (e) {
        // Ignore sync errors
      }
      rethrow;
    } on exceptions.PermissionDeniedException {
      rethrow;
    } on exceptions.ConflictException {
      rethrow;
    } catch (e) {
      throw exceptions.ApiException('Failed to delete group: $e');
    }
  }

  Future<void> addMemberToGroup({
    required int groupId,
    required int memberUserId,
    required int adminUserId,
  }) async {
    try {
      final box = Hive.box<GroupHive>('groups');
      final existingGroup = box.get(groupId);
      if (existingGroup == null) {
        throw exceptions.NotFoundException(
          message: 'Group not found: $groupId',
        );
      }

      _validateMemberOperationPermissions(
        existingGroup,
        memberUserId,
        adminUserId,
        'add',
      );

      await ApiClientFactory.instance.post(
        '/api/v1/group_memberships',
        body: {'group_id': groupId, 'user_id': memberUserId},
      );

      try {
        await SyncService.syncGroups(adminUserId);
      } catch (e) {
        // Ignore sync errors
      }
    } on SocketException {
      throw exceptions.ApiException('Internet connection required');
    } on TimeoutException {
      throw exceptions.ApiException('Server timeout. Try again.');
    } on exceptions.NotFoundException {
      rethrow;
    } on exceptions.PermissionDeniedException {
      rethrow;
    } on exceptions.ConflictException {
      rethrow;
    } catch (e) {
      throw exceptions.ApiException('Failed to add member to group: $e');
    }
  }

  Future<void> removeMemberFromGroup({
    required int groupId,
    required int memberUserId,
    required int adminUserId,
  }) async {
    try {
      final box = Hive.box<GroupHive>('groups');
      final existingGroup = box.get(groupId);
      if (existingGroup == null) {
        throw exceptions.NotFoundException(
          message: 'Group not found: $groupId',
        );
      }

      _validateMemberOperationPermissions(
        existingGroup,
        memberUserId,
        adminUserId,
        'remove',
      );

      // Get membership_id first
      final memberships = await ApiClientFactory.instance.get(
        '/api/v1/group_memberships',
        queryParams: {
          'group_id': groupId.toString(),
          'user_id': memberUserId.toString(),
        },
      );

      if (memberships is! List || memberships.isEmpty) {
        throw exceptions.NotFoundException(
          message:
              'Membership not found for user $memberUserId in group $groupId',
        );
      }

      final membershipId = memberships[0]['id'];
      await ApiClientFactory.instance.delete(
        '/api/v1/group_memberships/$membershipId',
      );

      try {
        await SyncService.syncGroups(adminUserId);
      } catch (e) {
        // Ignore sync errors
      }
    } on SocketException {
      throw exceptions.ApiException('Internet connection required');
    } on TimeoutException {
      throw exceptions.ApiException('Server timeout. Try again.');
    } on exceptions.NotFoundException {
      rethrow;
    } on exceptions.PermissionDeniedException {
      rethrow;
    } on exceptions.ConflictException {
      rethrow;
    } catch (e) {
      throw exceptions.ApiException('Failed to remove member from group: $e');
    }
  }

  Future<void> leaveGroup({required int groupId, required int userId}) async {
    try {
      final box = Hive.box<GroupHive>('groups');
      final existingGroup = box.get(groupId);
      if (existingGroup == null) {
        throw exceptions.NotFoundException(
          message: 'Group not found: $groupId',
        );
      }

      if (existingGroup.isCreator(userId)) {
        throw const exceptions.ConflictException(
          message: 'Group creator cannot leave. Delete the group instead.',
        );
      }

      // Get membership_id first
      final memberships = await ApiClientFactory.instance.get(
        '/api/v1/group_memberships',
        queryParams: {
          'group_id': groupId.toString(),
          'user_id': userId.toString(),
        },
      );

      if (memberships is! List || memberships.isEmpty) {
        throw exceptions.NotFoundException(
          message: 'Membership not found for user $userId in group $groupId',
        );
      }

      final membershipId = memberships[0]['id'];
      await ApiClientFactory.instance.delete(
        '/api/v1/group_memberships/$membershipId',
      );

      await SyncService.clearGroupCache(groupId);
    } on SocketException {
      throw exceptions.ApiException('Internet connection required');
    } on TimeoutException {
      throw exceptions.ApiException('Server timeout. Try again.');
    } on exceptions.NotFoundException {
      try {
        await SyncService.clearGroupCache(groupId);
      } catch (e) {
        // Ignore sync errors
      }
      rethrow;
    } on exceptions.PermissionDeniedException {
      rethrow;
    } on exceptions.ConflictException {
      rethrow;
    } catch (e) {
      throw exceptions.ApiException('Failed to leave group: $e');
    }
  }

  Future<void> grantAdminPermission({
    required int groupId,
    required int userId,
    required int grantedById,
  }) async {
    try {
      // TODO: Backend needs PUT /group_memberships/{id} endpoint to update role
      // For now, we need to delete and recreate the membership
      final memberships = await ApiClientFactory.instance.get(
        '/api/v1/group_memberships',
        queryParams: {
          'group_id': groupId.toString(),
          'user_id': userId.toString(),
        },
      );

      if (memberships is! List || memberships.isEmpty) {
        throw exceptions.NotFoundException(
          message: 'Membership not found for user $userId in group $groupId',
        );
      }

      final membershipId = memberships[0]['id'];

      // Delete current membership
      await ApiClientFactory.instance.delete(
        '/api/v1/group_memberships/$membershipId',
      );

      // Create new membership with admin role
      await ApiClientFactory.instance.post(
        '/api/v1/group_memberships',
        body: {'group_id': groupId, 'user_id': userId, 'role': 'admin'},
      );

      try {
        await SyncService.syncGroups(userId);
      } catch (e) {
        // Ignore sync errors
      }
    } on SocketException {
      throw exceptions.ApiException('Internet connection required');
    } on TimeoutException {
      throw exceptions.ApiException('Server timeout. Try again.');
    } on exceptions.NotFoundException {
      rethrow;
    } on exceptions.PermissionDeniedException {
      rethrow;
    } on exceptions.ConflictException {
      rethrow;
    } catch (e) {
      throw exceptions.ApiException('Failed to grant admin permission: $e');
    }
  }

  Future<void> removeAdminPermission({
    required int groupId,
    required int userId,
    required int revokedById,
  }) async {
    try {
      // TODO: Backend needs PUT /group_memberships/{id} endpoint to update role
      // For now, we need to delete and recreate the membership
      final memberships = await ApiClientFactory.instance.get(
        '/api/v1/group_memberships',
        queryParams: {
          'group_id': groupId.toString(),
          'user_id': userId.toString(),
        },
      );

      if (memberships is! List || memberships.isEmpty) {
        throw exceptions.NotFoundException(
          message: 'Membership not found for user $userId in group $groupId',
        );
      }

      final membershipId = memberships[0]['id'];

      // Delete current membership
      await ApiClientFactory.instance.delete(
        '/api/v1/group_memberships/$membershipId',
      );

      // Create new membership with member role
      await ApiClientFactory.instance.post(
        '/api/v1/group_memberships',
        body: {'group_id': groupId, 'user_id': userId, 'role': 'member'},
      );

      try {
        await SyncService.syncGroups(userId);
      } catch (e) {
        // Ignore sync errors
      }
    } on SocketException {
      throw exceptions.ApiException('Internet connection required');
    } on TimeoutException {
      throw exceptions.ApiException('Server timeout. Try again.');
    } on exceptions.NotFoundException {
      rethrow;
    } on exceptions.PermissionDeniedException {
      rethrow;
    } on exceptions.ConflictException {
      rethrow;
    } catch (e) {
      throw exceptions.ApiException('Failed to revoke admin permission: $e');
    }
  }

  Future<void> syncGroups(int userId) async {
    try {
      await SyncService.syncGroups(userId);
    } catch (e) {
      rethrow;
    }
  }

  void _validateAdminPermissions(GroupHive group, int userId) {
    if (!group.isAdmin(userId)) {
      throw const exceptions.PermissionDeniedException(
        message: 'No permission to update group',
      );
    }
  }

  void _validateMemberOperationPermissions(
    GroupHive group,
    int memberUserId,
    int adminUserId,
    String operationType,
  ) {
    if (operationType == 'add') {
      if (!group.isAdmin(adminUserId)) {
        throw const exceptions.PermissionDeniedException(
          message: 'No permission to add members to group',
        );
      }
      if (group.memberIds.contains(memberUserId)) {
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
      if (!group.memberIds.contains(memberUserId)) {
        throw const exceptions.NotFoundException(
          message: 'User is not a member of this group',
        );
      }
    }
  }

  List<Group> _convertAllGroupsFromHive(Box<GroupHive> box) {
    final allGroups = <Group>[];
    for (final groupHive in box.values) {
      try {
        final group = _groupHiveToGroup(groupHive);
        allGroups.add(group);
      } catch (e) {
        // Ignore sync errors
      }
    }
    return allGroups;
  }

  Group _groupHiveToGroup(GroupHive groupHive) {
    final members = <User>[];
    for (int i = 0; i < groupHive.memberIds.length; i++) {
      final memberId = groupHive.memberIds[i];
      final memberName = i < groupHive.memberNames.length
          ? groupHive.memberNames[i]
          : null;
      final memberFullName = i < groupHive.memberFullNames.length
          ? groupHive.memberFullNames[i]
          : null;
      final isPublic = i < groupHive.memberIsPublic.length
          ? groupHive.memberIsPublic[i] ?? false
          : false;

      members.add(
        User(
          id: memberId,
          instagramName: memberName,
          fullName: memberFullName,
          isPublic: isPublic,
        ),
      );
    }

    final admins = <User>[];
    final adminIds = groupHive.adminIds ?? [];
    for (final adminId in adminIds) {
      final adminMember = members.firstWhere(
        (member) => member.id == adminId,
        orElse: () => User(id: adminId, isPublic: false),
      );
      admins.add(adminMember);
    }

    return Group(
      id: groupHive.id,
      name: groupHive.name,
      description: groupHive.description ?? '',
      creatorId: groupHive.creatorId,
      createdAt: groupHive.createdAt,
      members: members,
      admins: admins,
    );
  }
}

class DeletionMarkers {
  static const String removedFromGroup = '[DELETED]';

  static bool isDeleted(String name) {
    return name.contains(removedFromGroup);
  }

  static String markAsDeleted(String name, String marker) {
    return '$marker $name';
  }
}
