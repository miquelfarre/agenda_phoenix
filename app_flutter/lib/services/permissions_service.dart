import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

/// Service to handle app permissions
class PermissionsService {
  PermissionsService._();
  static final PermissionsService instance = PermissionsService._();

  /// Request all critical permissions for the app to function
  /// Returns true if all permissions are granted, false otherwise
  Future<bool> requestAllCriticalPermissions() async {
    // Request contacts permission using flutter_contacts
    final contactsGranted = await FlutterContacts.requestPermission();

    // Request microphone and speech permissions using permission_handler
    final microphoneStatus = await Permission.microphone.request();
    final speechStatus = await Permission.speech.request();

    return contactsGranted &&
        microphoneStatus.isGranted &&
        speechStatus.isGranted;
  }

  /// Check if all critical permissions are granted
  Future<bool> hasAllCriticalPermissions() async {
    final contactsStatus = await FlutterContacts.requestPermission(
      readonly: true,
    );
    final microphoneStatus = await Permission.microphone.status;
    final speechStatus = await Permission.speech.status;

    return contactsStatus &&
        microphoneStatus.isGranted &&
        speechStatus.isGranted;
  }

  /// Request contacts permission
  Future<bool> requestContactsPermission() async {
    return await FlutterContacts.requestPermission();
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Request speech recognition permission
  Future<bool> requestSpeechPermission() async {
    final status = await Permission.speech.request();
    return status.isGranted;
  }

  /// Check if contacts permission is granted
  Future<bool> hasContactsPermission() async {
    return await FlutterContacts.requestPermission(readonly: true);
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Check if speech recognition permission is granted
  Future<bool> hasSpeechPermission() async {
    final status = await Permission.speech.status;
    return status.isGranted;
  }

  /// Open app settings if user needs to manually enable permissions
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
