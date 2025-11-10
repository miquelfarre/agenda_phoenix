import 'package:flutter_contacts/flutter_contacts.dart';
import 'api_client.dart';

class ContactsSyncService {
  final ApiClient _apiClient = ApiClient();

  /// Request permission to access phone contacts
  Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission();
  }

  /// Check if permission is granted
  Future<bool> checkPermission() async {
    final permission = await FlutterContacts.requestPermission(readonly: true);
    return permission;
  }

  /// Sync phone contacts with backend
  Future<Map<String, dynamic>> syncPhoneContacts() async {
    // Check permission first
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      throw Exception('Contacts permission not granted');
    }

    // Read contacts from phone
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    // Prepare contacts data for sync
    final contactsData = <Map<String, String>>[];
    for (final contact in contacts) {
      // Get primary phone number
      if (contact.phones.isNotEmpty) {
        final phone = _normalizePhone(contact.phones.first.number);
        if (phone.isNotEmpty) {
          contactsData.add({
            'contact_name': contact.displayName,
            'phone_number': phone,
          });
        }
      }
    }

    // Sync with backend
    if (contactsData.isEmpty) {
      return {'synced': 0, 'matched': 0};
    }

    final response = await _apiClient.syncContacts(contacts: contactsData);
    return response;
  }

  /// Get contacts that are registered in the app
  Future<List<dynamic>> getRegisteredContacts({
    int limit = 100,
    int skip = 0,
  }) async {
    return await _apiClient.getMyContacts(
      onlyRegistered: true,
      limit: limit,
      skip: skip,
    );
  }

  /// Get all synced contacts (registered and non-registered)
  Future<List<dynamic>> getAllSyncedContacts({
    int limit = 100,
    int skip = 0,
  }) async {
    return await _apiClient.getMyContacts(
      onlyRegistered: false,
      limit: limit,
      skip: skip,
    );
  }

  /// Normalize phone number to international format
  /// Simple normalization - can be improved with libphonenumber
  String _normalizePhone(String phone) {
    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // If starts with 00, replace with +
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }

    // If doesn't start with +, assume it's a local Spanish number
    if (!cleaned.startsWith('+')) {
      // Remove leading 0 if present
      if (cleaned.startsWith('0')) {
        cleaned = cleaned.substring(1);
      }
      // Add Spanish country code
      cleaned = '+34$cleaned';
    }

    return cleaned;
  }
}
