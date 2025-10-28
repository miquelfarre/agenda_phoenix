import 'package:supabase_flutter/supabase_flutter.dart';

typedef Json = Map<String, dynamic>;

/// Shared realtime sync helper to standardize filtering across repositories.
class RealtimeSync {
  DateTime _serverSyncTs = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  /// Set sync timestamp directly from a server-provided time (UTC preferred).
  void setServerSyncTs(DateTime tsUtc) {
    _serverSyncTs = tsUtc.toUtc();
  }

  /// Initialize sync timestamp from either server time or rows' updated_at/inserted_at.
  void setServerSyncTsFromResponse({DateTime? serverTimeUtc, Iterable<Json>? rows}) {
    if (serverTimeUtc != null) {
      _serverSyncTs = serverTimeUtc.toUtc();
      return;
    }
    if (rows != null) {
      DateTime? maxTs;
      for (final r in rows) {
        final v = r['updated_at'] ?? r['inserted_at'];
        final ts = v is String ? DateTime.tryParse(v)?.toUtc() : null;
        if (ts != null && (maxTs == null || ts.isAfter(maxTs))) {
          maxTs = ts;
        }
      }
      if (maxTs != null) _serverSyncTs = maxTs;
    }
  }

  /// For INSERT/UPDATE, only process if commit_ts is after serverSyncTs + margin.
  bool shouldProcessInsertOrUpdate(DateTime? commitTsUtc, {Duration margin = const Duration(seconds: 1)}) {
    if (commitTsUtc == null) return true;
    return commitTsUtc.isAfter(_serverSyncTs.add(margin));
  }

  /// DELETE should always be processed (ignore time gate).
  bool shouldProcessDelete() => true;
}

class RealtimeUtils {
  static RealtimeChannel subscribeTable({required SupabaseClient client, required String schema, required String table, PostgresChangeEvent event = PostgresChangeEvent.all, PostgresChangeFilter? filter, required void Function(PostgresChangePayload payload) onChange}) {
    final channelName = 'postgres_changes:$schema:$table:${filter != null ? '${filter.column}=${filter.value}' : 'all'}';
    final chan = client.channel(channelName).onPostgresChanges(event: event, schema: schema, table: table, filter: filter, callback: onChange);
    chan.subscribe();
    return chan;
  }
}
