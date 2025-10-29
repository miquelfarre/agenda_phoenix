import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_interaction.dart';
import '../models/event_interaction_hive.dart';
import '../services/api_client.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../core/realtime_sync.dart';
import '../utils/app_exceptions.dart' as exceptions;

class EventInteractionRepository {
  static const String _boxName = 'event_interactions';
  final _supabaseService = SupabaseService.instance;
  final _apiClient = ApiClient();
  final RealtimeSync _rt = RealtimeSync();

  Box<EventInteractionHive>? _box;
  final StreamController<List<EventInteraction>> _interactionsController =
      StreamController<List<EventInteraction>>.broadcast();
  List<EventInteraction> _cachedInteractions = [];
  RealtimeChannel? _realtimeChannel;

  Stream<List<EventInteraction>> get interactionsStream async* {
    if (_cachedInteractions.isNotEmpty) {
      yield List.from(_cachedInteractions);
    }
    yield* _interactionsController.stream;
  }

  Future<void> initialize() async {
    print('🚀 [EventInteractionRepository] Initializing...');
    _box = await Hive.openBox<EventInteractionHive>(_boxName);

    // Load interactions from Hive cache first (if any)
    _loadInteractionsFromHive();

    // Fetch and sync interactions from API BEFORE subscribing to Realtime
    await _fetchAndSync();

    // Now subscribe to Realtime for future updates
    await _startRealtimeSubscription();

    _emitCurrentInteractions();
    print('✅ [EventInteractionRepository] Initialization complete');
  }

  void _loadInteractionsFromHive() {
    if (_box == null) return;

    try {
      _cachedInteractions = _box!.values
          .map((interactionHive) => EventInteraction.fromJson(interactionHive.toJson()))
          .toList();

      print('✅ [EventInteractionRepository] Loaded ${_cachedInteractions.length} interactions from Hive cache');
    } catch (e) {
      print('❌ [EventInteractionRepository] Error loading from Hive: $e');
      _cachedInteractions = [];
    }
  }

  Future<void> _fetchAndSync() async {
    try {
      print('📡 [EventInteractionRepository] Fetching interactions from API...');
      final userId = ConfigService.instance.currentUserId;
      final response = await _apiClient.fetchUserInteractions(currentUserId: userId);
      _cachedInteractions = response.map((data) => EventInteraction.fromJson(data)).toList();

      await _updateLocalCache(_cachedInteractions);

      _rt.setServerSyncTsFromResponse(
        rows: _cachedInteractions.map((i) => i.toJson()),
      );
      _emitCurrentInteractions();
      print('✅ [EventInteractionRepository] Fetched ${_cachedInteractions.length} interactions');
    } catch (e) {
      print('❌ [EventInteractionRepository] Error fetching event interactions: $e');
    }
  }

  Future<void> _updateLocalCache(List<EventInteraction> interactions) async {
    if (_box == null) return;

    print('💾 [EventInteractionRepository] Updating Hive cache with ${interactions.length} interactions...');
    await _box!.clear();

    for (final interaction in interactions) {
      final interactionHive = EventInteractionHive.fromJson(interaction.toJson());
      await _box!.put(interactionHive.hiveKey, interactionHive);
    }
    print('✅ [EventInteractionRepository] Hive cache updated');
  }

  // --- Mutations ---

  Future<EventInteraction> updateParticipationStatus(
    int eventId,
    String status, {
    String? decisionMessage,
    bool? isAttending,
  }) async {
    print('🔄 [EventInteractionRepository] Updating participation status for event $eventId: $status');
    final currentUserId = ConfigService.instance.currentUserId;
    final interaction = _cachedInteractions.firstWhere(
      (i) => i.eventId == eventId && i.userId == currentUserId,
      orElse: () => throw exceptions.NotFoundException(message: 'Interaction not found'),
    );

    final updateData = <String, dynamic>{'status': status};
    if (decisionMessage != null) updateData['rejection_message'] = decisionMessage;
    if (isAttending != null) updateData['is_attending'] = isAttending;

    final updatedInteraction = await _apiClient.patchInteraction(interaction.id!, updateData);
    await _fetchAndSync();
    print('✅ [EventInteractionRepository] Participation status updated for event $eventId');
    return EventInteraction.fromJson(updatedInteraction);
  }

  Future<void> markAsViewed(int eventId) async {
    print('👁️ [EventInteractionRepository] Marking event $eventId as viewed');
    final currentUserId = ConfigService.instance.currentUserId;
    final interaction = _cachedInteractions.firstWhere(
      (i) => i.eventId == eventId && i.userId == currentUserId,
      orElse: () => throw exceptions.NotFoundException(message: 'Interaction not found'),
    );
    await _apiClient.markInteractionRead(interaction.id!); // Assuming this marks as viewed
    await _fetchAndSync();
    print('✅ [EventInteractionRepository] Event $eventId marked as viewed');
  }

  Future<void> toggleFavorite(int eventId) async {
    final currentUserId = ConfigService.instance.currentUserId;
    final interaction = _cachedInteractions.firstWhere(
      (i) => i.eventId == eventId && i.userId == currentUserId,
      orElse: () => throw exceptions.NotFoundException(message: 'Interaction not found'),
    );
    final newFavoriteStatus = !interaction.favorited;
    print('⭐ [EventInteractionRepository] ${newFavoriteStatus ? 'Adding' : 'Removing'} favorite for event $eventId');
    await _apiClient.patchInteraction(interaction.id!, {'favorited': newFavoriteStatus});
    await _fetchAndSync();
    print('✅ [EventInteractionRepository] Favorite toggled for event $eventId');
  }

  Future<void> setPersonalNote(int eventId, String note) async {
    print('📝 [EventInteractionRepository] Setting personal note for event $eventId');
    final currentUserId = ConfigService.instance.currentUserId;
    final interaction = _cachedInteractions.firstWhere(
      (i) => i.eventId == eventId && i.userId == currentUserId,
      orElse: () => throw exceptions.NotFoundException(message: 'Interaction not found'),
    );
    await _apiClient.patchInteraction(interaction.id!, {'personal_note': note});
    await _fetchAndSync();
    print('✅ [EventInteractionRepository] Personal note set for event $eventId');
  }

  Future<void> sendInvitation(
    int eventId,
    int invitedUserId,
    String? invitationMessage,
  ) async {
    print('✉️ [EventInteractionRepository] Sending invitation to user $invitedUserId for event $eventId');
    await _apiClient.createInteraction({
      'event_id': eventId,
      'user_id': invitedUserId,
      'interaction_type': 'invited',
      'status': 'pending',
      if (invitationMessage != null) 'note': invitationMessage,
    });
    await _fetchAndSync();
    print('✅ [EventInteractionRepository] Invitation sent to user $invitedUserId');
  }

  // --- Realtime ---

  Future<void> _startRealtimeSubscription() async {
    final userId = ConfigService.instance.currentUserId;
    _realtimeChannel = _supabaseService.client
        .channel('interactions_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_interactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId.toString(),
          ),
          callback: _handleInteractionChange,
        )
        .subscribe();

    print('✅ [EventInteractionRepository] Realtime subscription started for event_interactions table');
  }

  void _handleInteractionChange(PostgresChangePayload payload) {
    final ct = DateTime.tryParse(payload.commitTimestamp.toString());

    if (payload.eventType == PostgresChangeEvent.insert ||
        payload.eventType == PostgresChangeEvent.update) {
      if (!_rt.shouldProcessInsertOrUpdate(ct)) {
        print('⏸️ [EventInteractionRepository] Event skipped by time gate');
        return;
      }
      print('🔄 [EventInteractionRepository] ${payload.eventType == PostgresChangeEvent.insert ? 'INSERT' : 'UPDATE'} detected, updating cache');

      final interaction = EventInteraction.fromJson(payload.newRecord);
      final existingIndex = _cachedInteractions.indexWhere(
        (i) => i.id == interaction.id,
      );
      if (existingIndex != -1) {
        _cachedInteractions[existingIndex] = interaction;
      } else {
        _cachedInteractions.add(interaction);
      }

      // Update Hive cache
      final interactionHive = EventInteractionHive.fromJson(interaction.toJson());
      _box?.put(interactionHive.hiveKey, interactionHive);

      _emitCurrentInteractions();
      print('✅ [EventInteractionRepository] Cache updated for event ${interaction.eventId}');
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      if (!_rt.shouldProcessDelete()) return;
      print('🔄 [EventInteractionRepository] DELETE detected');

      final userId = payload.oldRecord['user_id'] as int?;
      final eventId = payload.oldRecord['event_id'] as int?;
      if (userId != null && eventId != null) {
        _cachedInteractions.removeWhere((i) => i.userId == userId && i.eventId == eventId);

        // Delete from Hive cache
        final hiveKey = EventInteractionHive.createHiveKey(userId, eventId);
        _box?.delete(hiveKey);

        _emitCurrentInteractions();
        print('✅ [EventInteractionRepository] Interaction deleted for event $eventId');
      }
    }
  }

  void _emitCurrentInteractions() {
    if (!_interactionsController.isClosed) {
      _interactionsController.add(List.from(_cachedInteractions));
    }
  }

  void dispose() {
    print('👋 [EventInteractionRepository] Disposing...');
    _realtimeChannel?.unsubscribe();
    _interactionsController.close();
  }
}
