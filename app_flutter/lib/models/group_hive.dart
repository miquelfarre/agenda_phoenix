import 'package:hive_ce/hive.dart';
import 'group.dart';
import 'user.dart';
import '../utils/datetime_utils.dart';

part 'group_hive.g.dart';

@HiveType(typeId: 5)
class GroupHive extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final int ownerId;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final List<int> memberIds;

  @HiveField(6)
  final List<String?> memberNames;

  @HiveField(7)
  final List<String?> memberFullNames;

  @HiveField(8)
  final List<bool?> memberIsPublic;

  @HiveField(9)
  final List<int>? adminIds;

  @HiveField(10)
  final List<String>? pendingOperationIds;

  @HiveField(11)
  final bool? isOptimistic;

  @HiveField(13)
  final bool? needsSync;

  @HiveField(14)
  final String? clientTempId;

  String? get effectiveClientTempId => clientTempId;

  GroupHive({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.createdAt,
    this.memberIds = const [],
    this.memberNames = const [],
    this.memberFullNames = const [],
    this.memberIsPublic = const [],

    this.adminIds,
    this.pendingOperationIds,
    this.isOptimistic,
    this.needsSync,
    this.clientTempId,
  });

  Map<String, dynamic> toJson() {
    final members = <Map<String, dynamic>>[];
    for (int i = 0; i < memberIds.length; i++) {
      members.add({'id': memberIds[i], 'instagram_name': i < memberNames.length ? memberNames[i] : null, 'full_name': i < memberFullNames.length ? memberFullNames[i] : null, 'is_public': i < memberIsPublic.length ? memberIsPublic[i] : false});
    }

    return {'id': id, 'name': name, 'description': description, 'owner_id': ownerId, 'created_at': createdAt.toIso8601String(), 'members': members};
  }

  static GroupHive fromGroup(Group group) {
    final memberIds = group.members.map((member) => member.id).toList();
    final memberNames = group.members.map((member) => member.instagramName).toList();
    final memberFullNames = group.members.map((member) => member.fullName).toList();
    final memberIsPublic = group.members.map((member) => false).toList();

    final adminIds = group.admins.map((admin) => admin.id).toList();

    return GroupHive(id: group.id, name: group.name, description: group.description, ownerId: group.ownerId, createdAt: DateTime.now(), memberIds: memberIds, memberNames: memberNames.cast<String?>(), memberFullNames: memberFullNames, memberIsPublic: memberIsPublic, adminIds: adminIds);
  }

  static GroupHive fromJson(Map<String, dynamic> json) {
    final members = json['members'] as List<dynamic>? ?? [];

    final memberIds = <int>[];
    final memberNames = <String?>[];
    final memberFullNames = <String?>[];
    final memberIsPublic = <bool?>[];

    for (final member in members) {
      if (member is Map<String, dynamic>) {
        memberIds.add(member['id'] as int);
        memberNames.add(member['instagram_name'] as String?);
        memberFullNames.add(member['full_name'] as String?);
        memberIsPublic.add(member['is_public'] as bool? ?? false);
      }
    }

    return GroupHive(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: json['owner_id'] as int? ?? 0,
      createdAt: json['created_at'] != null ? (json['created_at'] is String ? DateTimeUtils.parseAndNormalize(json['created_at'] as String) : json['created_at']) : DateTime.now(),
      memberIds: memberIds,
      memberNames: memberNames,
      memberFullNames: memberFullNames,
      memberIsPublic: memberIsPublic,
    );
  }

  bool get isCreatedOffline => isOptimistic == true && effectiveClientTempId != null;

  bool get hasPendingOperations => pendingOperationIds?.isNotEmpty == true;

  bool get requiresSync => needsSync == true || hasPendingOperations;

  bool isAdmin(int userId) {
    if (ownerId == userId) return true;

    return adminIds?.contains(userId) == true;
  }

  bool isOwner(int userId) => ownerId == userId;

  // Deprecated: Use isOwner instead
  bool isCreator(int userId) => isOwner(userId);

  GroupHive addAdminToCache(int userId) {
    final newAdminIds = List<int>.from(adminIds ?? []);
    if (!newAdminIds.contains(userId)) {
      newAdminIds.add(userId);
    }

    return GroupHive(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      createdAt: createdAt,
      memberIds: memberIds,
      memberNames: memberNames,
      memberFullNames: memberFullNames,
      memberIsPublic: memberIsPublic,
      adminIds: newAdminIds,
      pendingOperationIds: pendingOperationIds,
      isOptimistic: isOptimistic,
      clientTempId: effectiveClientTempId,
      needsSync: needsSync,
    );
  }

  GroupHive removeAdminFromCache(int userId) {
    final newAdminIds = List<int>.from(adminIds ?? []);
    newAdminIds.remove(userId);

    return GroupHive(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      createdAt: createdAt,
      memberIds: memberIds,
      memberNames: memberNames,
      memberFullNames: memberFullNames,
      memberIsPublic: memberIsPublic,
      adminIds: newAdminIds,
      pendingOperationIds: pendingOperationIds,
      isOptimistic: isOptimistic,
      clientTempId: effectiveClientTempId,
      needsSync: needsSync,
    );
  }

  GroupHive addPendingOperation(String operationId) {
    final newPendingOps = List<String>.from(pendingOperationIds ?? []);
    if (!newPendingOps.contains(operationId)) {
      newPendingOps.add(operationId);
    }

    return GroupHive(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      createdAt: createdAt,
      memberIds: memberIds,
      memberNames: memberNames,
      memberFullNames: memberFullNames,
      memberIsPublic: memberIsPublic,
      adminIds: adminIds,
      pendingOperationIds: newPendingOps,
      isOptimistic: isOptimistic,
      clientTempId: effectiveClientTempId,
      needsSync: true,
    );
  }

  Group toGroup() {
    final members = <User>[];
    for (int i = 0; i < memberIds.length; i++) {
      members.add(User(id: memberIds[i], instagramName: i < memberNames.length ? (memberNames[i] ?? '') : '', fullName: i < memberFullNames.length ? (memberFullNames[i] ?? '') : '', isPublic: i < memberIsPublic.length ? (memberIsPublic[i] ?? false) : false));
    }

    final admins = <User>[];
    if (adminIds != null) {
      for (final adminId in adminIds!) {
        final adminIndex = memberIds.indexOf(adminId);
        if (adminIndex >= 0) {
          admins.add(
            User(
              id: adminId,
              instagramName: adminIndex < memberNames.length ? (memberNames[adminIndex] ?? '') : '',
              fullName: adminIndex < memberFullNames.length ? (memberFullNames[adminIndex] ?? '') : '',
              isPublic: adminIndex < memberIsPublic.length ? (memberIsPublic[adminIndex] ?? false) : false,
            ),
          );
        } else {
          admins.add(User(id: adminId, instagramName: '', fullName: '', isPublic: false));
        }
      }
    }

    return Group(id: id, name: name, description: description ?? '', ownerId: ownerId, createdAt: createdAt, members: members, admins: admins);
  }
}
