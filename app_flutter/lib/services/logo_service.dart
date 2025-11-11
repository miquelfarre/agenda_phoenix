import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoService {
  static const _prefsKey = 'user_logo_paths';

  LogoService._();
  static final LogoService instance = LogoService._();

  Future<Directory> _ensureBucket() async {
    final dir = await getApplicationDocumentsDirectory();
    final logosDir = Directory('${dir.path}/logos');
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }
    return logosDir;
  }

  Future<String?> getLogoPath(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = Map<String, String>.from(
      (prefs
              .getStringList(_prefsKey)
              ?.asMap()
              .map((k, v) => MapEntry(v.split('|')[0], v.split('|')[1])) ??
          {}),
    );
    final path = map[userId.toString()];
    if (path == null) return null;
    final exists = await File(path).exists();
    return exists ? path : null;
  }

  Future<String> setLogoFromFile(int userId, File file) async {
    final bucket = await _ensureBucket();
    final dest = File('${bucket.path}/$userId.png');
    await file.copy(dest.path);
    await _index(userId, dest.path);
    return dest.path;
  }

  Future<String> setLogoFromBytes(int userId, List<int> bytes) async {
    final bucket = await _ensureBucket();
    final dest = File('${bucket.path}/$userId.png');
    await dest.writeAsBytes(bytes, flush: true);
    await _index(userId, dest.path);
    return dest.path;
  }

  Future<void> deleteLogo(int userId) async {
    final path = await getLogoPath(userId);
    if (path != null) {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    }
    await _unindex(userId);
  }

  Future<void> _index(int userId, String path) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? <String>[];
    final map = {
      for (final entry in raw) entry.split('|')[0]: entry.split('|')[1],
    };
    map[userId.toString()] = path;
    final serialized = [for (final e in map.entries) '${e.key}|${e.value}'];
    await prefs.setStringList(_prefsKey, serialized);
  }

  Future<void> _unindex(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? <String>[];
    final map = {
      for (final entry in raw) entry.split('|')[0]: entry.split('|')[1],
    };
    map.remove(userId.toString());
    final serialized = [for (final e in map.entries) '${e.key}|${e.value}'];
    await prefs.setStringList(_prefsKey, serialized);
  }
}
