import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'sync_service.dart';
import '../models/subscription.dart';
import '../models/subscription_hive.dart';
import '../models/user.dart';
import '../utils/app_exceptions.dart';
import 'config_service.dart';
import 'api_client.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  String get serviceName => 'SubscriptionService';
  int get currentUserId => ConfigService.instance.currentUserId;

  List<Subscription> getLocalSubscriptions() {
    try {
      final box = Hive.box<SubscriptionHive>('subscriptions');

      final subscriptions = <Subscription>[];
      for (final key in box.keys) {
        try {
          final subscriptionHive = box.get(key);
          if (subscriptionHive is SubscriptionHive && subscriptionHive.userId == currentUserId) {
            subscriptions.add(_subscriptionHiveToSubscription(subscriptionHive));
          }
        } catch (e) {
          // Ignore sync errors
        }
      }

      return subscriptions;
    } catch (e) {
      return [];
    }
  }

  Future<Subscription> createSubscription({required int targetUserId, User? targetUser}) async {
    try {
      await ApiClientFactory.instance.post('/api/v1/users/$targetUserId/subscribe');

      // Response is a bulk operation result, need to sync to get actual subscription data
      await SyncService.syncSubscriptions(currentUserId);

      // Return a temporary subscription object (will be updated by sync)
      final subscription = Subscription(
        id: 0, // Temporary ID
        userId: currentUserId,
        subscribedToId: targetUserId,
        subscribed: targetUser,
      );

      return subscription;
    } on SocketException {
      throw ApiException('Internet connection required');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSubscription({required int subscriptionId}) async {
    try {
      // subscriptionId is now an interaction_id
      await ApiClientFactory.instance.delete('/api/v1/interactions/$subscriptionId');

      await SyncService.syncSubscriptions(currentUserId);
    } on SocketException {
      throw ApiException('Internet connection required');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<User>> searchPublicUsers({required String query}) async {
    try {
      final usersData = await ApiClientFactory.instance.fetchUsers(isPublic: true);

      final users = usersData.map((data) => User.fromJson(data)).where((user) => (user.fullName?.toLowerCase().contains(query.toLowerCase()) ?? false) || (user.email?.toLowerCase().contains(query.toLowerCase()) ?? false)).toList();

      return users;
    } on SocketException {
      throw ApiException('Internet connection required');
    } catch (e) {
      rethrow;
    }
  }

  Subscription? getSubscriptionById(int subscriptionId) {
    try {
      final box = Hive.box<SubscriptionHive>('subscriptions');
      final subscriptionHive = box.get(subscriptionId);
      if (subscriptionHive == null) return null;

      return _subscriptionHiveToSubscription(subscriptionHive);
    } catch (e) {
      return null;
    }
  }

  Subscription _subscriptionHiveToSubscription(SubscriptionHive subscriptionHive) {
    User? subscribed;

    if (subscriptionHive.subscribedUserName != null || subscriptionHive.subscribedUserFullName != null) {
      subscribed = User(id: subscriptionHive.subscribedToId, instagramName: subscriptionHive.subscribedUserName, fullName: subscriptionHive.subscribedUserFullName, isPublic: subscriptionHive.subscribedUserIsPublic ?? false);
    }

    return Subscription(id: subscriptionHive.id, userId: subscriptionHive.userId, subscribedToId: subscriptionHive.subscribedToId, subscribed: subscribed);
  }
}
