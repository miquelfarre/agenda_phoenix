import 'package:hive_ce/hive.dart';
import '../models/user_event_note_hive.dart';
import '../services/config_service.dart';

class UserEventNoteService {
  static final UserEventNoteService _instance =
      UserEventNoteService._internal();
  factory UserEventNoteService() => _instance;
  UserEventNoteService._internal();

  static const String boxName = 'user_event_note';

  int get currentUserId => ConfigService.instance.currentUserId;

  String? getPersonalNote(int eventId, {int? userId}) {
    try {
      final box = Hive.box<UserEventNoteHive>(boxName);
      final key = UserEventNoteHive.createHiveKey(
        userId ?? currentUserId,
        eventId,
      );
      final note = box.get(key);

      return note?.note;
    } catch (e) {
      return null;
    }
  }
}
