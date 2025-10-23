import 'dart:math';

class TestCredentials {
  TestCredentials._();

  static const String avatarServiceUrl =
      'https://api.dicebear.com/7.x/avataaars/png';

  static const List<String> testEmailDomains = [
    'example.com',
    'test.dev',
    'demo.org',
  ];

  static const String defaultTestEmail = 'test@example.com';

  static Map<String, dynamic> generateTestUser({
    int? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? instagramName,
    bool isPublic = true,
  }) {
    final random = Random();
    final generatedUserId = userId ?? _generateUserId();

    final generatedFullName = fullName ?? _generateFullName();
    final generatedEmail = email ?? _generateEmailFromName(generatedFullName);
    final generatedPhone = phoneNumber ?? _generatePhoneNumber();
    final generatedInstagram =
        instagramName ?? _generateInstagramName(generatedFullName);

    final testUser = {
      'id': generatedUserId,
      'fullName': generatedFullName,
      'email': generatedEmail,
      'phoneNumber': generatedPhone,
      'instagramName': generatedInstagram,
      'isPublic': isPublic,
      'profilePictureUrl': _generateProfilePictureUrl(generatedUserId),
      'bio': _generateBio(),
      'locationPreferences': _generateLocationPreferences(),
      'notificationSettings': _generateNotificationSettings(),
      'privacySettings': _generatePrivacySettings(),
      'createdAt': DateTime.now()
          .subtract(Duration(days: random.nextInt(365)))
          .toIso8601String(),
      'lastSeenAt': DateTime.now()
          .subtract(Duration(hours: random.nextInt(24)))
          .toIso8601String(),
      'isTestUser': true,
    };

    return testUser;
  }

  static String generateTestToken({
    int? userId,
    String? email,
    Duration? validity,
  }) {
    final validUntil = DateTime.now().add(
      validity ?? const Duration(hours: 24),
    );

    final header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
    final payload = _encodeTestPayload({
      'sub': (userId ?? _generateUserId()).toString(),
      'email': email ?? defaultTestEmail,
      'iat': (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
      'exp': (validUntil.millisecondsSinceEpoch / 1000).floor(),
      'test_mode': true,
      'aud': 'eventypop-test',
      'iss': 'eventypop-test-auth',
    });
    final signature = _generateRandomBase64String(43);

    final token = '$header.$payload.$signature';

    return token;
  }

  static Map<String, String> generateTestApiHeaders({
    int? userId,
    String? token,
    Map<String, String>? additionalHeaders,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Test-Mode': 'true',
      'X-Test-User-ID': (userId ?? _generateUserId()).toString(),
      'X-Test-Environment': 'development',
      'X-Test-Session-ID': _generateSessionId(),
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  static List<Map<String, dynamic>> generateTestUserGroup({
    int count = 5,
    bool includePrivateUsers = true,
  }) {
    final users = <Map<String, dynamic>>[];
    final random = Random();

    for (int i = 0; i < count; i++) {
      final isPublic = includePrivateUsers ? random.nextBool() : true;
      users.add(generateTestUser(isPublic: isPublic));
    }

    return users;
  }

  static bool validateTestCredentials(Map<String, dynamic> credentials) {
    final requiredFields = ['id', 'fullName', 'email', 'phoneNumber'];

    for (final field in requiredFields) {
      if (!credentials.containsKey(field) || credentials[field] == null) {
        return false;
      }
    }

    final email = credentials['email'] as String;
    if (!_isValidEmail(email)) {
      return false;
    }

    return true;
  }

  static int _generateUserId() {
    final random = Random();

    return 90000 + random.nextInt(9999);
  }

  static String _generateFullName() {
    final random = Random();
    final firstNames = [
      'Alex',
      'Sam',
      'Jordan',
      'Casey',
      'Taylor',
      'Morgan',
      'Riley',
      'Avery',
      'Quinn',
      'Blake',
      'Cameron',
      'Drew',
      'Emery',
      'Finley',
      'Hayden',
      'Jamie',
      'Kendall',
      'Lane',
      'Max',
      'Noah',
      'Parker',
      'Reese',
      'Sage',
    ];
    final lastNames = [
      'Anderson',
      'Brown',
      'Davis',
      'Garcia',
      'Johnson',
      'Jones',
      'Miller',
      'Moore',
      'Rodriguez',
      'Smith',
      'Taylor',
      'Thomas',
      'White',
      'Williams',
      'Wilson',
      'Lopez',
      'Lee',
      'Clark',
      'Lewis',
      'Walker',
      'Hall',
      'Allen',
    ];

    return '${firstNames[random.nextInt(firstNames.length)]} ${lastNames[random.nextInt(lastNames.length)]}';
  }

  static String _generateEmailFromName(String fullName) {
    final nameParts = fullName.toLowerCase().split(' ');
    final random = Random();

    final username = '${nameParts[0]}.${nameParts[1]}${random.nextInt(999)}';
    final domain = testEmailDomains[random.nextInt(testEmailDomains.length)];

    return '$username@$domain';
  }

  static String _generatePhoneNumber() {
    final random = Random();

    final areaCode = 200 + random.nextInt(800);
    final exchange = 200 + random.nextInt(800);
    final number = random.nextInt(10000).toString().padLeft(4, '0');

    return '+1$areaCode$exchange$number';
  }

  static String _generateInstagramName(String fullName) {
    final nameParts = fullName.toLowerCase().split(' ');
    final random = Random();
    final suffixes = [
      '',
      '_official',
      '_dev',
      '_test',
      '${random.nextInt(999)}',
    ];

    return '${nameParts[0]}_${nameParts[1]}${suffixes[random.nextInt(suffixes.length)]}';
  }

  static String _generateProfilePictureUrl(int userId) {
    return '$avatarServiceUrl?seed=$userId';
  }

  static String _generateBio() {
    final random = Random();
    final bios = [
      'Software developer passionate about creating amazing experiences',
      'Designer who loves to build beautiful and functional interfaces',
      'Event organizer bringing people together through memorable experiences',
      'Tech enthusiast exploring the intersection of creativity and code',
      'Community builder focused on connecting like-minded individuals',
      'Digital nomad working remotely while traveling the world',
      'Startup founder building the next big thing',
      'Test user for EventyPop development and quality assurance',
    ];

    return bios[random.nextInt(bios.length)];
  }

  static Map<String, dynamic> _generateLocationPreferences() {
    final random = Random();
    final cities = ['San Francisco', 'New York', 'London', 'Tokyo', 'Sydney'];

    return {
      'preferredCity': cities[random.nextInt(cities.length)],
      'radiusKm': [5, 10, 25, 50][random.nextInt(4)],
      'allowLocationSharing': random.nextBool(),
    };
  }

  static Map<String, dynamic> _generateNotificationSettings() {
    final random = Random();

    return {
      'pushNotifications': random.nextBool(),
      'emailNotifications': random.nextBool(),
      'eventReminders': random.nextBool(),
      'invitationAlerts': random.nextBool(),
      'marketingEmails': false,
    };
  }

  static Map<String, dynamic> _generatePrivacySettings() {
    final random = Random();

    return {
      'profileVisibility': random.nextBool() ? 'public' : 'friends',
      'showEmail': random.nextBool(),
      'showPhone': random.nextBool(),
      'allowInvitations': random.nextBool(),
    };
  }

  static String _encodeTestPayload(Map<String, dynamic> payload) {
    final payloadString = payload.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    return _generateRandomBase64String(payloadString.length ~/ 2);
  }

  static String _generateRandomBase64String(int length) {
    final random = Random();
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  static String _generateSessionId() {
    return 'test_session_${DateTime.now().millisecondsSinceEpoch}';
  }

  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
