import 'package:hive_ce/hive.dart';
import 'subscription.dart';
import 'user.dart';

part 'subscription_hive.g.dart';

@HiveType(typeId: 3)
class SubscriptionHive extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int userId;

  @HiveField(2)
  final int subscribedToId;

  @HiveField(3)
  final String? subscribedUserName;

  @HiveField(4)
  final String? subscribedUserFullName;

  @HiveField(5)
  final bool? subscribedUserIsPublic;

  SubscriptionHive({
    required this.id,
    required this.userId,
    required this.subscribedToId,
    this.subscribedUserName,
    this.subscribedUserFullName,
    this.subscribedUserIsPublic,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subscribed_to_id': subscribedToId,
      'followed': subscribedUserName != null
          ? {
              'instagram_name': subscribedUserName,
              'full_name': subscribedUserFullName,
              'is_public': subscribedUserIsPublic,
            }
          : null,
    };
  }

  static SubscriptionHive fromSubscription(Subscription subscription) {
    return SubscriptionHive(
      id: subscription.id,
      userId: subscription.userId,
      subscribedToId: subscription.subscribedToId,
      subscribedUserName: subscription.subscribed?.instagramName,
      subscribedUserFullName: subscription.subscribed?.fullName,
      subscribedUserIsPublic: subscription.subscribed?.isPublic,
    );
  }

  static SubscriptionHive fromJson(Map<String, dynamic> json) {
    final followed = json['followed'] as Map<String, dynamic>?;

    final id = json['id'];
    final userId = json['user_id'];
    final subscribedToId = json['subscribed_to_id'];

    if (id == null) {
      throw Exception('SubscriptionHive.fromJson: id cannot be null');
    }
    if (userId == null) {
      throw Exception('SubscriptionHive.fromJson: userId cannot be null');
    }
    if (subscribedToId == null) {
      throw Exception(
        'SubscriptionHive.fromJson: subscribedToId cannot be null',
      );
    }

    return SubscriptionHive(
      id: id as int,
      userId: userId as int,
      subscribedToId: subscribedToId as int,
      subscribedUserName: followed?['instagram_name'],
      subscribedUserFullName: followed?['full_name'],
      subscribedUserIsPublic: followed?['is_public'],
    );
  }

  Subscription toSubscription() {
    return Subscription(
      id: id,
      userId: userId,
      subscribedToId: subscribedToId,
      subscribed: subscribedUserName != null
          ? User(
              id: subscribedToId,
              instagramName: subscribedUserName!,
              fullName: subscribedUserFullName ?? '',
              isPublic: subscribedUserIsPublic ?? false,
            )
          : null,
    );
  }
}
