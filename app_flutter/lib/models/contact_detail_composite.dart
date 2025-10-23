library;

import 'event.dart';

class ContactDetailComposite {
  final List<Event> myEvents;
  final String checksum;

  ContactDetailComposite({required this.myEvents, required this.checksum});

  factory ContactDetailComposite.fromJson(Map<String, dynamic> json) {
    return ContactDetailComposite(
      myEvents: (json['my_events'] as List)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
      checksum: json['checksum'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'my_events': myEvents.map((e) => e.toJson()).toList(),
      'checksum': checksum,
    };
  }

  bool hasChanged(String? cachedChecksum) {
    return cachedChecksum == null || cachedChecksum != checksum;
  }
}
