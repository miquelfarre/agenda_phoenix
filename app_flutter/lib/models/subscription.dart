import 'user.dart';

class Subscription {
  final int id;
  final int userId;
  final int subscribedToId;
  final User? subscribed;

  Subscription({
    required this.id,
    required this.userId,
    required this.subscribedToId,
    this.subscribed,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      userId: json['user_id'],
      subscribedToId: json['subscribed_to_id'],
      subscribed: json['followed'] != null
          ? User.fromJson(json['followed'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subscribed_to_id': subscribedToId,
      'followed': subscribed?.toJson(),
    };
  }
}
