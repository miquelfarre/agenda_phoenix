library;

import 'subscription.dart';
import 'event.dart';

class SubscriptionDetailComposite {
  final Subscription subscription;
  final List<Event> publicEvents;
  final String checksum;

  SubscriptionDetailComposite({
    required this.subscription,
    required this.publicEvents,
    required this.checksum,
  });

  factory SubscriptionDetailComposite.fromJson(Map<String, dynamic> json) {
    return SubscriptionDetailComposite(
      subscription: Subscription.fromJson(
        json['subscription'] as Map<String, dynamic>,
      ),
      publicEvents: (json['public_events'] as List)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
      checksum: json['checksum'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscription': subscription.toJson(),
      'public_events': publicEvents.map((e) => e.toJson()).toList(),
      'checksum': checksum,
    };
  }

  bool hasChanged(String? cachedChecksum) {
    return cachedChecksum == null || cachedChecksum != checksum;
  }
}
