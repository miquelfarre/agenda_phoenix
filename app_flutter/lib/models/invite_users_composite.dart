library;

import 'user.dart';
import 'group.dart';

class InviteUsersComposite {
  final List<User> availableUsers;
  final List<Group> groups;
  final List<int> existingInvitations;
  final List<GroupInviteState> groupStates;
  final String checksum;

  InviteUsersComposite({
    required this.availableUsers,
    required this.groups,
    required this.existingInvitations,
    required this.groupStates,
    required this.checksum,
  });

  factory InviteUsersComposite.fromJson(Map<String, dynamic> json) {
    return InviteUsersComposite(
      availableUsers: (json['available_users'] as List)
          .map((u) => User.fromJson(u as Map<String, dynamic>))
          .toList(),
      groups: (json['groups'] as List)
          .map((g) => Group.fromJson(g as Map<String, dynamic>))
          .toList(),
      existingInvitations: (json['existing_invitations'] as List)
          .map((id) => id as int)
          .toList(),
      groupStates: (json['group_states'] as List)
          .map((gs) => GroupInviteState.fromJson(gs as Map<String, dynamic>))
          .toList(),
      checksum: json['checksum'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'available_users': availableUsers.map((u) => u.toJson()).toList(),
      'groups': groups.map((g) => g.toJson()).toList(),
      'existing_invitations': existingInvitations,
      'group_states': groupStates.map((gs) => gs.toJson()).toList(),
      'checksum': checksum,
    };
  }

  bool hasChanged(String? cachedChecksum) {
    return cachedChecksum == null || cachedChecksum != checksum;
  }
}

class GroupInviteState {
  final int groupId;
  final int totalMembers;
  final int invitedMembers;
  final String state;

  GroupInviteState({
    required this.groupId,
    required this.totalMembers,
    required this.invitedMembers,
    required this.state,
  });

  factory GroupInviteState.fromJson(Map<String, dynamic> json) {
    return GroupInviteState(
      groupId: json['group_id'] as int,
      totalMembers: json['total_members'] as int,
      invitedMembers: json['invited_members'] as int,
      state: json['state'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'total_members': totalMembers,
      'invited_members': invitedMembers,
      'state': state,
    };
  }

  bool get isFullyInvited => state == 'fully_invited';

  bool get isPartiallyInvited => state == 'partially_invited';

  bool get isAvailable => state == 'available';

  bool get isEmpty => state == 'empty';
}
