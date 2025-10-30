import 'package:hive_ce/hive.dart';
import '../../utils/app_exceptions.dart';

class HiveMigration {
  static const String _migrationBoxName = 'migration_metadata';
  static const int _currentSchemaVersion = 1;

  static final Map<int, Migration> _migrations = {1: Migration(version: 1, description: 'Initial schema with new features (Calendar, Birthday, Collections)', migrate: _migrateToV1)};

  static Future<void> initialize() async {
    try {
      final migrationBox = Hive.isBoxOpen(_migrationBoxName) ? Hive.box<int>(_migrationBoxName) : await Hive.openBox<int>(_migrationBoxName);
      final currentVersion = migrationBox.get('schema_version') ?? 0;

      if (currentVersion < _currentSchemaVersion) {
        await _runMigrations(currentVersion, _currentSchemaVersion, migrationBox);
      } else {}
    } catch (e) {
      throw DatabaseException(message: 'Migration initialization failed: ${e.toString()}');
    }
  }

  static Future<void> _runMigrations(int fromVersion, int toVersion, Box<int> migrationBox) async {
    for (int version = fromVersion + 1; version <= toVersion; version++) {
      final migration = _migrations[version];
      if (migration == null) {
        throw DatabaseException(message: 'Migration for version $version not found');
      }

      try {
        await migration.migrate();
        await migrationBox.put('schema_version', version);
        final dateBox = Hive.isBoxOpen('migration_dates') ? Hive.box<String>('migration_dates') : await Hive.openBox<String>('migration_dates');
        await dateBox.put('migration_${version}_date', DateTime.now().toIso8601String());
      } catch (e) {
        throw DatabaseException(message: 'Migration v$version failed: ${e.toString()}');
      }
    }
  }

  static Future<void> _migrateToV1() async {
    await _validateAndCreateBox('calendars');
    await _validateAndCreateBox('calendar_shares');
    await _validateAndCreateBox('birthday_events');
    await _validateAndCreateBox('event_collections');

    await _cleanupCorruptedData();

    await _validateDataIntegrity();
  }

  static Future<void> _validateAndCreateBox(String boxName) async {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      } else {}
    } catch (e) {
      if (e.toString().contains('already open')) {
        return;
      }
      rethrow;
    }
  }

  static Future<void> _cleanupCorruptedData() async {
    final boxNames = ['events', 'notifications', 'subscriptions', 'invitations', 'groups', 'event_notes'];

    for (final boxName in boxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
        } else {}
      } catch (e) {
        // Ignore errors
      }
    }
  }

  static Future<void> _validateDataIntegrity() async {
    try {
      await _validateEventsIntegrity();

      await _validateRelationshipIntegrity();
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _validateEventsIntegrity() async {
    if (!Hive.isBoxOpen('events')) {
      return;
    }

    try {} catch (e) {
      // Ignore errors
    }
  }

  static Future<void> _validateRelationshipIntegrity() async {}

  static Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      final migrationBox = Hive.isBoxOpen(_migrationBoxName) ? Hive.box<int>(_migrationBoxName) : await Hive.openBox<int>(_migrationBoxName);
      final currentVersion = migrationBox.get('schema_version') ?? 0;

      final migrations = <Map<String, dynamic>>[];
      for (final entry in _migrations.entries) {
        final version = entry.key;
        final migration = entry.value;
        final isApplied = version <= currentVersion;
        final dateBox = Hive.isBoxOpen('migration_dates') ? Hive.box<String>('migration_dates') : await Hive.openBox<String>('migration_dates');
        final appliedDate = dateBox.get('migration_${version}_date');

        migrations.add({'version': version, 'description': migration.description, 'is_applied': isApplied, 'applied_date': appliedDate});
      }

      return {'current_version': currentVersion, 'target_version': _currentSchemaVersion, 'is_up_to_date': currentVersion >= _currentSchemaVersion, 'migrations': migrations};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<void> resetMigrations() async {
    try {
      final migrationBox = Hive.isBoxOpen(_migrationBoxName) ? Hive.box<int>(_migrationBoxName) : await Hive.openBox<int>(_migrationBoxName);
      await migrationBox.clear();
    } catch (e) {
      rethrow;
    }
  }
}

class Migration {
  final int version;
  final String description;
  final Future<void> Function() migrate;

  const Migration({required this.version, required this.description, required this.migrate});
}
