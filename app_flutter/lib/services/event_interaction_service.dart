import 'dart:async';
import 'dart:io';
import 'package:hive_ce/hive.dart';
import '../models/event_interaction.dart';
import '../models/event_interaction_hive.dart';
import '../models/user.dart';
import '../models/user_hive.dart';
import '../utils/app_exceptions.dart' as app_exceptions;
import 'api_client.dart';
import 'config_service.dart';

class EventInteractionService {
  static final EventInteractionService _instance =
      EventInteractionService._internal();
  factory EventInteractionService() => _instance;
  EventInteractionService._internal();

  String get serviceName => 'EventInteractionService';
  String get hiveBoxName => 'event_interactions';

  int get currentUserId => ConfigService.instance.currentUserId;

  EventInteraction? getInteraction(int eventId) {
    try {
      final box = Hive.box<EventInteractionHive>(hiveBoxName);
      final key = EventInteractionHive.createHiveKey(currentUserId, eventId);
      final hive = box.get(key);
      if (hive == null) return null;

      return _hiveToModel(hive);
    } catch (e) {
      return null;
    }
  }

  List<EventInteraction> getAllInteractions() {
    try {
      final box = Hive.box<EventInteractionHive>(hiveBoxName);
      final interactions = <EventInteraction>[];

      for (final hive in box.values) {
        if (hive.userId == currentUserId) {
          interactions.add(_hiveToModel(hive));
        }
      }

      return interactions;
    } catch (e) {
      return [];
    }
  }

  bool hasViewed(int eventId) {
    final interaction = getInteraction(eventId);
    return interaction?.viewed ?? false;
  }

  bool isFavorited(int eventId) {
    final interaction = getInteraction(eventId);
    return interaction?.favorited ?? false;
  }

  bool isHidden(int eventId) {
    final interaction = getInteraction(eventId);
    return interaction?.hidden ?? false;
  }

  String? getPersonalNote(int eventId) {
    final interaction = getInteraction(eventId);
    return interaction?.personalNote;
  }

  String? getParticipationStatus(int eventId) {
    final interaction = getInteraction(eventId);
    return interaction?.participationStatus;
  }

  Future<EventInteraction?> markAsViewed(int eventId) async {
    return null;
  }

  Future<EventInteraction> updateParticipationStatus(
    int eventId,
    String status, {
    String? decisionMessage,
    bool? isAttending,
  }) async {
    if (!['pending', 'accepted', 'rejected'].contains(status)) {
      throw ArgumentError(
        'Invalid status. Must be: pending, accepted, or rejected',
      );
    }

    try {
      final body = <String, dynamic>{'status': status};
      if (decisionMessage != null) {
        body['rejection_message'] = decisionMessage;
      }

      final response = await ApiClientFactory.instance.patch(
        '/api/v1/events/$eventId/interaction',
        body: body,
      );

      final interaction = EventInteraction.fromJson(response);

      return interaction;
    } on SocketException {
      throw app_exceptions.ApiException('Internet connection required');
    } catch (e) {
      throw app_exceptions.ApiException(
        'Failed to update participation status: $e',
      );
    }
  }

  Future<EventInteraction> setPersonalNote(int eventId, String note) async {
    try {
      final response = await ApiClientFactory.instance.patch(
        '/api/v1/events/$eventId/interaction',
        body: {'note': note},
      );

      final interaction = EventInteraction.fromJson(response);

      return interaction;
    } on SocketException {
      throw app_exceptions.ApiException('Internet connection required');
    } catch (e) {
      throw app_exceptions.ApiException('Failed to set personal note: $e');
    }
  }

  Future<EventInteraction> clearPersonalNote(int eventId) async {
    return setPersonalNote(eventId, '');
  }

  Future<void> toggleFavorite(int eventId) async {}

  Future<void> setFavorite(int eventId, bool favorited) async {}

  Future<void> toggleHidden(int eventId) async {}

  Future<void> setHidden(int eventId, bool hidden) async {}

  Future<EventInteraction> sendInvitation(
    int eventId,
    int invitedUserId, {
    String? invitationMessage,
  }) async {
    try {
      final body = <String, dynamic>{'invited_user_id': invitedUserId};
      if (invitationMessage != null) {
        body['invitation_message'] = invitationMessage;
      }

      final response = await ApiClientFactory.instance.post(
        '/api/v1/events/$eventId/interaction/invite',
        body: body,
      );

      final interaction = EventInteraction.fromJson(response);

      return interaction;
    } on SocketException {
      throw app_exceptions.ApiException('Internet connection required');
    } on app_exceptions.ApiException catch (e) {
      if (e.message.contains('409')) {
        throw app_exceptions.ApiException('User already invited');
      }
      rethrow;
    } catch (e) {
      throw app_exceptions.ApiException('Failed to send invitation: $e');
    }
  }

  Future<void> deleteInteraction(int eventId) async {
    try {
      await ApiClientFactory.instance.delete(
        '/api/v1/events/$eventId/interaction',
      );
    } on SocketException {
      throw app_exceptions.ApiException('Internet connection required');
    } on app_exceptions.ApiException catch (e) {
      if (e.statusCode == 404) {
        return;
      }
      rethrow;
    } catch (e) {
      throw app_exceptions.ApiException('Failed to delete interaction: $e');
    }
  }

  Future<EventInteraction?> fetchInteraction(int eventId) async {
    try {
      final response = await ApiClientFactory.instance.get(
        '/api/v1/events/$eventId/interaction',
      );

      return EventInteraction.fromJson(response);
    } on app_exceptions.ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    } on SocketException {
      throw app_exceptions.ApiException('Internet connection required');
    } catch (e) {
      throw app_exceptions.ApiException('Failed to fetch interaction: $e');
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final box = Hive.box<EventInteractionHive>(hiveBoxName);
      final totalEntries = box.length;

      final userCounts = <int, int>{};
      for (final hive in box.values) {
        userCounts[hive.userId] = (userCounts[hive.userId] ?? 0) + 1;
      }

      return {
        'total_entries': totalEntries,
        'users_with_data': userCounts.length,
        'user_counts': userCounts,
        'service_name': serviceName,
        'box_name': hiveBoxName,
      };
    } catch (e) {
      rethrow;
    }
  }

  EventInteraction _hiveToModel(EventInteractionHive hive) {
    User? inviter;
    if (hive.inviterId != null) {
      try {
        final usersBox = Hive.box<UserHive>('users');
        final inviterHive = usersBox.get(hive.inviterId);
        if (inviterHive != null) {
          inviter = inviterHive.toUser();
        }
      } catch (e) {
        // Ignore sync errors
      }
    }

    return EventInteraction(
      userId: hive.userId,
      eventId: hive.eventId,
      inviterId: hive.inviterId,
      inviter: inviter,
      invitationMessage: hive.invitationMessage,
      invitedAt: hive.invitedAt,
      participationStatus: hive.participationStatus,
      participationDecidedAt: hive.participationDecidedAt,
      decisionMessage: hive.decisionMessage,
      postponeUntil: hive.postponeUntil,
      isAttending: hive.isAttending,
      isEventAdmin: hive.isEventAdmin,
      viewed: hive.viewed,
      firstViewedAt: hive.firstViewedAt,
      lastViewedAt: hive.lastViewedAt,
      personalNote: hive.personalNote,
      noteUpdatedAt: hive.noteUpdatedAt,
      favorited: hive.favorited,
      favoritedAt: hive.favoritedAt,
      hidden: hive.hidden,
      hiddenAt: hive.hiddenAt,
      createdAt: hive.createdAt,
      updatedAt: hive.updatedAt,
    );
  }
}
