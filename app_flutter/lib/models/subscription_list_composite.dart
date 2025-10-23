library;

import 'subscription.dart';
import 'user.dart';

class SubscriptionListComposite {
  final List<SubscriptionListItem> subscriptions;
  final String checksum;

  SubscriptionListComposite({
    required this.subscriptions,
    required this.checksum,
  });

  factory SubscriptionListComposite.fromJson(Map<String, dynamic> json) {
    return SubscriptionListComposite(
      subscriptions: (json['subscriptions'] as List)
          .map((e) => SubscriptionListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      checksum: json['checksum'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptions': subscriptions.map((e) => e.toJson()).toList(),
      'checksum': checksum,
    };
  }

  bool hasChanged(String? cachedChecksum) {
    return cachedChecksum == null || cachedChecksum != checksum;
  }
}

class SubscriptionListItem {
  final int id;
  final int userId;
  final int subscribedToId;
  final dynamic subscribedTo;
  final int futureEventCount;

  SubscriptionListItem({
    required this.id,
    required this.userId,
    required this.subscribedToId,
    required this.subscribedTo,
    this.futureEventCount = 0,
  });

  factory SubscriptionListItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionListItem(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      subscribedToId: json['subscribed_to_id'] as int,
      subscribedTo: json['subscribed_to'],
      futureEventCount: json['future_event_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subscribed_to_id': subscribedToId,
      'subscribed_to': subscribedTo,
      'future_event_count': futureEventCount,
    };
  }

  Subscription toSubscription() {
    final User? subscribedUser = subscribedTo != null
        ? User.fromJson(subscribedTo as Map<String, dynamic>)
        : null;

    return Subscription(
      id: id,
      userId: userId,
      subscribedToId: subscribedToId,
      subscribed: subscribedUser,
    );
  }
}
