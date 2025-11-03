import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/realtime_sync.dart';

/// Utility class for filtering Supabase realtime events
///
/// Centralizes the logic for determining if a realtime event should be processed
/// or ignored (e.g., historical events from initial subscription payload)
class RealtimeFilter {
  /// Check if a realtime event should be processed
  ///
  /// DELETE events are always processed immediately.
  /// INSERT/UPDATE events are checked against the commit timestamp to filter
  /// historical events that were part of the initial subscription payload.
  ///
  /// Returns true if the event should be processed, false otherwise.
  static bool shouldProcessEvent(
    PostgresChangePayload payload,
    String eventType,
    RealtimeSync realtimeSync,
  ) {
    print('🔍 [FILTER] Checking $eventType event (type=${payload.eventType})');

    if (payload.eventType == PostgresChangeEvent.delete) {
      print('✅ [FILTER] DELETE event - processing immediately (skip timestamp check)');
      return realtimeSync.shouldProcessDelete();
    }

    final commitTimestamp = DateTime.tryParse(payload.commitTimestamp.toString());
    final shouldProcess = realtimeSync.shouldProcessInsertOrUpdate(commitTimestamp);

    if (!shouldProcess) {
      print('🚫 [FILTER] Ignoring historical $eventType by commit_timestamp gate');
    }

    return shouldProcess;
  }
}
