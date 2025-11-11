import 'package:flutter_contacts/flutter_contacts.dart';

/// Helper service to add test contacts for development
class TestContactsHelper {
  /// Add test contacts that match backend users
  static Future<void> addTestContacts() async {
    // Check permission first
    if (!await FlutterContacts.requestPermission()) {
      print('❌ Contacts permission not granted');
      return;
    }

    final testContacts = [
      {'name': 'Sonia', 'phone': '+34606014680'},
      {'name': 'Miquel', 'phone': '+34626034421'},
      {'name': 'Ada', 'phone': '+34623949193'},
      {'name': 'Sara', 'phone': '+34611223344'},
      {'name': 'TDB', 'phone': '+34600000001'},
      {'name': 'PolR', 'phone': '+34600000002'},
    ];

    int added = 0;
    int skipped = 0;

    for (final contactData in testContacts) {
      try {
        // Check if contact already exists
        final existingContacts = await FlutterContacts.getContacts(
          withProperties: true,
        );

        final exists = existingContacts.any(
          (c) =>
              c.phones.any((p) => p.number == contactData['phone']) ||
              c.displayName == contactData['name'],
        );

        if (exists) {
          print('⏩ Contact already exists: ${contactData['name']}');
          skipped++;
          continue;
        }

        // Create new contact
        final newContact = Contact()
          ..name.first = contactData['name']!
          ..phones = [Phone(contactData['phone']!)];

        await newContact.insert();
        print('✅ Added contact: ${contactData['name']} (${contactData['phone']})');
        added++;
      } catch (e) {
        print('❌ Error adding contact ${contactData['name']}: $e');
      }
    }

    print('');
    print('📱 Test contacts summary:');
    print('   Added: $added');
    print('   Skipped: $skipped');
    print('   Total: ${testContacts.length}');
  }

  /// Remove all test contacts
  static Future<void> removeTestContacts() async {
    if (!await FlutterContacts.requestPermission()) {
      print('❌ Contacts permission not granted');
      return;
    }

    final testNames = ['Sonia', 'Miquel', 'Ada', 'Sara', 'TDB', 'PolR'];

    final contacts = await FlutterContacts.getContacts();
    int removed = 0;

    for (final contact in contacts) {
      if (testNames.contains(contact.displayName)) {
        try {
          await contact.delete();
          print('🗑️  Removed contact: ${contact.displayName}');
          removed++;
        } catch (e) {
          print('❌ Error removing contact ${contact.displayName}: $e');
        }
      }
    }

    print('');
    print('📱 Removed $removed test contacts');
  }
}
