abstract class IApiClient {
  // ============================================================================
  // HTTP Methods (Base)
  // ============================================================================
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams});
  Future<dynamic> post(String path, {Map<String, dynamic>? body});
  Future<dynamic> put(String path, {Map<String, dynamic>? body});
  Future<dynamic> delete(String path, {Map<String, dynamic>? queryParams});
  Future<dynamic> patch(String path, {Map<String, dynamic>? body});

  // ============================================================================
  // Users
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchUsers({
    bool? isPublic,
    int? limit,
    int? offset,
    String? search,
  });

  Future<Map<String, dynamic>> fetchUser(int userId, {bool? enriched});

  Future<List<Map<String, dynamic>>> fetchUserEvents(
    int userId, {
    int? currentUserId,
  });

  Future<Map<String, dynamic>> updateUser(
    int userId,
    Map<String, dynamic> data, {
    required int currentUserId,
  });

  // ============================================================================
  // User Subscriptions
  // ============================================================================
  Future<Map<String, dynamic>> subscribeToUser(int targetUserId);

  Future<Map<String, dynamic>> unsubscribeFromUser(
    int userId,
    int targetUserId,
  );

  Future<List<Map<String, dynamic>>> fetchUserSubscriptions(
    int userId, {
    int? currentUserId,
  });

  // ============================================================================
  // UserContacts
  // ============================================================================
  Future<Map<String, dynamic>> syncContacts({
    required List<Map<String, String>> contacts,
  });

  Future<List<dynamic>> getMyContacts({
    bool onlyRegistered = true,
    int limit = 100,
    int skip = 0,
  });

  // ============================================================================
  // Events
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchEvents({
    int? ownerId,
    int? calendarId,
    int? currentUserId,
  });

  Future<Map<String, dynamic>> fetchEvent(int eventId, {int? currentUserId});

  Future<List<Map<String, dynamic>>> fetchAvailableInvitees(
    int eventId, {
    int? currentUserId,
  });

  Future<Map<String, dynamic>> createEvent(
    Map<String, dynamic> data, {
    bool force = false,
  });

  Future<Map<String, dynamic>> updateEvent(
    int eventId,
    Map<String, dynamic> data, {
    int? currentUserId,
    bool force = false,
  });

  Future<void> deleteEvent(int eventId, {int? currentUserId});

  // ============================================================================
  // Event Interactions
  // ============================================================================

  Future<List<Map<String, dynamic>>> fetchInteractions({
    int? eventId,
    int? userId,
    String? interactionType,
    String? status,
    bool? enriched,
    int? currentUserId,
  });

  Future<Map<String, dynamic>> createInteraction(
    Map<String, dynamic> data, {
    bool force = false,
  });

  Future<Map<String, dynamic>> patchInteraction(
    int interactionId,
    Map<String, dynamic> data, {
    bool force = false,
  });

  Future<void> markInteractionRead(int interactionId, {int? currentUserId});

  // ============================================================================
  // Recurring Event Configurations
  // ============================================================================
  // (removed unused methods)

  // ============================================================================
  // Calendars
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchCalendars({
    int? ownerId,
    int? currentUserId,
  });

  Future<Map<String, dynamic>> createCalendar(
    Map<String, dynamic> data, {
    int? currentUserId,
  });

  Future<Map<String, dynamic>> updateCalendar(
    int calendarId,
    Map<String, dynamic> data, {
    int? currentUserId,
  });

  Future<void> deleteCalendar(int calendarId, {int? currentUserId});

  // Public calendar sharing helpers
  Future<Map<String, dynamic>?> searchCalendarByHash(String shareHash);
  Future<Map<String, dynamic>> subscribeByShareHash(String shareHash);
  Future<void> unsubscribeByShareHash(String shareHash);

  // ============================================================================
  // Calendar Memberships
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchCalendarMemberships(
    int calendarId, {
    int? currentUserId,
  });

  Future<Map<String, dynamic>> addCalendarMembership(
    int calendarId,
    Map<String, dynamic> data, {
    int? currentUserId,
  });

  Future<void> deleteCalendarMembership(int membershipId, {int? currentUserId});

  // ============================================================================
  // Groups
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchGroups({
    int? ownerId,
    int? currentUserId,
  });

  Future<Map<String, dynamic>> createGroup(
    Map<String, dynamic> data, {
    int? currentUserId,
  });

  Future<Map<String, dynamic>> updateGroup(
    int groupId,
    Map<String, dynamic> data, {
    int? currentUserId,
  });

  Future<void> deleteGroup(int groupId, {int? currentUserId});

  // ============================================================================
  // Group Memberships
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchGroupMemberships({
    int? groupId,
    int? userId,
  });

  Future<Map<String, dynamic>> createGroupMembership(Map<String, dynamic> data);

  Future<Map<String, dynamic>> updateGroupMembership(
    int membershipId,
    Map<String, dynamic> data,
  );

  Future<void> deleteGroupMembership(int membershipId);

  // ============================================================================
  // User Blocks
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchUserBlocks({
    int? blockerUserId,
    int? blockedUserId,
  });

  Future<Map<String, dynamic>> createUserBlock(Map<String, dynamic> data);

  Future<void> deleteUserBlock(int blockId, {required int currentUserId});

}
