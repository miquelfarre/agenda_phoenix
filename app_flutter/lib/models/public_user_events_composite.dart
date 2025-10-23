library;

import 'event.dart';

class PublicUserEventsComposite {
  final List<Event> events;
  final bool isSubscribed;
  final String checksum;

  PublicUserEventsComposite({
    required this.events,
    required this.isSubscribed,
    required this.checksum,
  });

  factory PublicUserEventsComposite.fromJson(Map<String, dynamic> json) {
    return PublicUserEventsComposite(
      events: (json['events'] as List)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
      isSubscribed: json['is_subscribed'] as bool,
      checksum: json['checksum'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'events': events.map((e) => e.toJson()).toList(),
      'is_subscribed': isSubscribed,
      'checksum': checksum,
    };
  }

  bool hasChanged(String? cachedChecksum) {
    return cachedChecksum == null || cachedChecksum != checksum;
  }
}
