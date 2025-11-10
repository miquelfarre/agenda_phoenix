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
    bool? enriched,
    int? limit,
    int? offset,
    String? search,
  });

  Future<Map<String, dynamic>> fetchUser(int userId, {bool? enriched});

  Future<Map<String, dynamic>> fetchUserStats(int userId);

  Future<List<Map<String, dynamic>>> fetchUserEvents(
    int userId, {
    int? currentUserId,
  });

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data);

  Future<Map<String, dynamic>> updateUser(
    int userId,
    Map<String, dynamic> data, {
    required int currentUserId,
  });

  Future<void> deleteUser(int userId, {required int currentUserId});

  // ============================================================================
  // User Subscriptions
  // ============================================================================
  Future<Map<String, dynamic>> subscribeToUser(int userId, int targetUserId);

  Future<List<Map<String, dynamic>>> fetchUserSubscriptions(
    int userId, {
    int? currentUserId,
  });

  // ============================================================================
  // Contacts (Legacy - deprecated, usar UserContacts)
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchContacts({
    required int currentUserId,
  });

  Future<Map<String, dynamic>> fetchContact(
    int contactId, {
    required int currentUserId,
  });

  Future<Map<String, dynamic>> createContact(
    Map<String, dynamic> data, {
    required int currentUserId,
  });

  Future<Map<String, dynamic>> updateContact(
    int contactId,
    Map<String, dynamic> data, {
    required int currentUserId,
  });

  Future<void> deleteContact(int contactId, {required int currentUserId});

  // ============================================================================
  // UserContacts (New system)
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

  Future<List<Map<String, dynamic>>> fetchEventCancellations({
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

  Future<void> markCancellationViewed(int cancellationId, {int? currentUserId});

  // ============================================================================
  // Event Interactions
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchEventInteractions(
    int eventId, {
    int? currentUserId,
  });

  Future<List<Map<String, dynamic>>> fetchEventInteractionsEnriched(
    int eventId, {
    int? currentUserId,
  });

  Future<List<Map<String, dynamic>>> fetchUserInteractions({
    int? currentUserId,
  });

  Future<List<Map<String, dynamic>>> fetchInteractions({
    int? eventId,
    int? userId,
    String? interactionType,
    String? status,
    bool? enriched,
    int? currentUserId,
  });

  Future<Map<String, dynamic>> fetchInteraction(
    int interactionId, {
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

  Future<void> deleteInteraction(int interactionId, {int? currentUserId});

  Future<void> markInteractionRead(int interactionId, {int? currentUserId});

  // ============================================================================
  // Recurring Event Configurations
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchRecurringConfigs({
    int? eventId,
    int? currentUserId,
  });

  Future<Map<String, dynamic>> fetchRecurringConfig(
    int configId, {
    int? currentUserId,
  });

  Future<Map<String, dynamic>> createRecurringConfig(
    Map<String, dynamic> data, {
    int? currentUserId,
  });

  Future<Map<String, dynamic>> updateRecurringConfig(
    int configId,
    Map<String, dynamic> data, {
    int? currentUserId,
  });

  Future<void> deleteRecurringConfig(int configId, {int? currentUserId});

  // ============================================================================
  // Calendars
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchCalendars({
    int? ownerId,
    int? currentUserId,
  });

  Future<Map<String, dynamic>> fetchCalendar(
    int calendarId, {
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

  // ============================================================================
  // Calendar Memberships
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchCalendarMemberships(
    int calendarId, {
    int? currentUserId,
  });

  Future<List<Map<String, dynamic>>> fetchAllCalendarMemberships({
    int? calendarId,
    int? userId,
    int? currentUserId,
  });

  Future<Map<String, dynamic>> fetchCalendarMembership(
    int membershipId, {
    int? currentUserId,
  });

  Future<Map<String, dynamic>> createCalendarMembership(
    Map<String, dynamic> data, {
    int? currentUserId,
  });

  Future<Map<String, dynamic>> addCalendarMembership(
    int calendarId,
    Map<String, dynamic> data, {
    int? currentUserId,
  });

  Future<Map<String, dynamic>> updateCalendarMembership(
    int membershipId,
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

  Future<Map<String, dynamic>> fetchGroup(int groupId, {int? currentUserId});

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

  Future<Map<String, dynamic>> fetchGroupMembership(int membershipId);

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

  Future<Map<String, dynamic>> fetchUserBlock(int blockId);

  Future<Map<String, dynamic>> createUserBlock(Map<String, dynamic> data);

  Future<void> deleteUserBlock(int blockId, {required int currentUserId});

  // ============================================================================
  // Event Bans
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchEventBans({
    int? eventId,
    int? userId,
  });

  Future<Map<String, dynamic>> fetchEventBan(int banId);

  Future<Map<String, dynamic>> createEventBan(Map<String, dynamic> data);

  Future<void> deleteEventBan(int banId);

  // ============================================================================
  // App Bans
  // ============================================================================
  Future<List<Map<String, dynamic>>> fetchAppBans();

  Future<Map<String, dynamic>> fetchAppBan(int banId);

  Future<Map<String, dynamic>> createAppBan(Map<String, dynamic> data);

  Future<void> deleteAppBan(int banId);
}
