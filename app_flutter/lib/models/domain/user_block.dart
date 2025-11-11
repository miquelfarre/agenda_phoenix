import 'package:flutter/foundation.dart';
import '../../utils/datetime_utils.dart';

@immutable
class UserBlock {
  final int id;
  final int blockerUserId;
  final int blockedUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserBlock({
    required this.id,
    required this.blockerUserId,
    required this.blockedUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserBlock.fromJson(Map<String, dynamic> json) {
    return UserBlock(
      id: json['id'] as int,
      blockerUserId: json['blocker_user_id'] as int,
      blockedUserId: json['blocked_user_id'] as int,
      createdAt: json['created_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTimeUtils.parseAndNormalize(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blocker_user_id': blockerUserId,
      'blocked_user_id': blockedUserId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserBlock &&
        other.id == id &&
        other.blockerUserId == blockerUserId &&
        other.blockedUserId == blockedUserId;
  }

  @override
  int get hashCode => Object.hash(id, blockerUserId, blockedUserId);

  @override
  String toString() {
    return 'UserBlock(id: $id, blocker: $blockerUserId, blocked: $blockedUserId)';
  }
}
