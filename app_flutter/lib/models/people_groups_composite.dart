library;

import 'user.dart';
import 'group.dart';

class PeopleGroupsComposite {
  final List<User> contacts;
  final List<Group> groups;
  final String checksum;

  PeopleGroupsComposite({
    required this.contacts,
    required this.groups,
    required this.checksum,
  });

  factory PeopleGroupsComposite.fromJson(Map<String, dynamic> json) {
    return PeopleGroupsComposite(
      contacts: (json['contacts'] as List)
          .map((u) => User.fromJson(u as Map<String, dynamic>))
          .toList(),
      groups: (json['groups'] as List)
          .map((g) => Group.fromJson(g as Map<String, dynamic>))
          .toList(),
      checksum: json['checksum'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contacts': contacts.map((u) => u.toJson()).toList(),
      'groups': groups.map((g) => g.toJson()).toList(),
      'checksum': checksum,
    };
  }

  bool hasChanged(String? cachedChecksum) {
    return cachedChecksum == null || cachedChecksum != checksum;
  }
}
