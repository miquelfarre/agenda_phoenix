import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static const String _contactsPermissionAskedKey = 'contacts_permission_asked';
  static const String _contactsPermissionDeniedKey = 'contacts_permission_denied';

  static Future<bool> shouldShowContactsPermissionDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final wasAsked = prefs.getBool(_contactsPermissionAskedKey) ?? false;
      final wasDenied = prefs.getBool(_contactsPermissionDeniedKey) ?? false;

      final currentStatus = await Permission.contacts.status;

      bool canAccessContacts = currentStatus.isGranted;

      if (canAccessContacts) {
        await markContactsPermissionGranted();
        return false;
      }

      if (currentStatus.isGranted) {
        return false;
      }

      if (!wasAsked) {
        return true;
      }

      if (currentStatus.isPermanentlyDenied && !canAccessContacts) {
        return false;
      }

      if (wasDenied && !canAccessContacts) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> markContactsPermissionAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_contactsPermissionAskedKey, true);
    } catch (e) {
      // Ignore sync errors
    }
  }

  static Future<void> markContactsPermissionDenied() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_contactsPermissionDeniedKey, true);
    } catch (e) {
      // Ignore sync errors
    }
  }

  static Future<void> markContactsPermissionGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_contactsPermissionDeniedKey, false);
    } catch (e) {
      // Ignore sync errors
    }
  }

  static Future<void> resetContactsPermissionPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_contactsPermissionAskedKey);
      await prefs.remove(_contactsPermissionDeniedKey);
    } catch (e) {
      // Ignore sync errors
    }
  }
}
