export interface EndpointParam {
  name: string;
  type: 'string' | 'number' | 'boolean' | 'date' | 'array';
  required: boolean;
  description?: string;
  example?: any;
}

export interface Endpoint {
  id: string;
  name: string;
  method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  path: string;
  category: string;
  userType: 'private' | 'public' | 'both';
  description: string;
  pathParams?: EndpointParam[];
  queryParams?: EndpointParam[];
  bodyParams?: EndpointParam[];
}

export const ENDPOINT_CATEGORIES = [
  { id: 'users', name: 'Users', icon: '👤' },
  { id: 'events', name: 'Events', icon: '📅' },
  { id: 'calendars', name: 'Calendars', icon: '🗓️' },
  { id: 'groups', name: 'Groups', icon: '👥' },
  { id: 'contacts', name: 'Contacts', icon: '📇' },
  { id: 'interactions', name: 'Interactions', icon: '🔔' },
  { id: 'bans', name: 'Event Bans', icon: '🚫' },
  { id: 'recurring', name: 'Recurring Configs', icon: '🔁' },
];

export const ENDPOINTS: Endpoint[] = [
  // ============================================================================
  // USERS
  // ============================================================================
  {
    id: 'get-user',
    name: 'Get User',
    method: 'GET',
    path: '/api/v1/users/:user_id',
    category: 'users',
    userType: 'both',
    description: 'Get user details by ID',
    pathParams: [
      { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 1 },
    ],
  },
  {
    id: 'get-current-user',
    name: 'Get Current User',
    method: 'GET',
    path: '/api/v1/users/me',
    category: 'users',
    userType: 'both',
    description: 'Get current authenticated user',
  },
  {
    id: 'update-user',
    name: 'Update User',
    method: 'PUT',
    path: '/api/v1/users/:user_id',
    category: 'users',
    userType: 'both',
    description: 'Update user information',
    pathParams: [
      { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 1 },
    ],
    bodyParams: [
      { name: 'display_name', type: 'string', required: true, description: 'Display name' },
      { name: 'phone', type: 'string', required: false, description: 'Phone number' },
      { name: 'instagram_username', type: 'string', required: false, description: 'Instagram username' },
      { name: 'profile_picture_url', type: 'string', required: false, description: 'Profile picture URL' },
      { name: 'auth_provider', type: 'string', required: true, description: 'Auth provider' },
      { name: 'auth_id', type: 'string', required: true, description: 'Auth ID' },
      { name: 'is_public', type: 'boolean', required: true, description: 'Is public user' },
      { name: 'is_admin', type: 'boolean', required: false, description: 'Is admin' },
    ],
  },
  {
    id: 'delete-user',
    name: 'Delete User',
    method: 'DELETE',
    path: '/api/v1/users/:user_id',
    category: 'users',
    userType: 'both',
    description: 'Delete user account',
    pathParams: [
      { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 1 },
    ],
  },
  {
    id: 'get-user-events',
    name: 'Get User Events',
    method: 'GET',
    path: '/api/v1/users/:user_id/events',
    category: 'users',
    userType: 'both',
    description: 'Get events for a user',
    pathParams: [
      { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 1 },
    ],
  },
  {
    id: 'get-user-stats',
    name: 'Get User Stats',
    method: 'GET',
    path: '/api/v1/users/:user_id/stats',
    category: 'users',
    userType: 'both',
    description: 'Get user statistics',
    pathParams: [
      { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 1 },
    ],
  },
  {
    id: 'get-user-subscriptions',
    name: 'Get User Subscriptions',
    method: 'GET',
    path: '/api/v1/users/:user_id/subscriptions',
    category: 'users',
    userType: 'both',
    description: 'Get user subscriptions',
    pathParams: [
      { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 1 },
    ],
  },
  {
    id: 'subscribe-to-user',
    name: 'Subscribe to User',
    method: 'POST',
    path: '/api/v1/users/:target_user_id/subscribe',
    category: 'users',
    userType: 'both',
    description: 'Subscribe to a public user',
    pathParams: [
      { name: 'target_user_id', type: 'number', required: true, description: 'Target user ID', example: 86 },
    ],
  },
  {
    id: 'unsubscribe-from-user',
    name: 'Unsubscribe from User',
    method: 'DELETE',
    path: '/api/v1/users/:target_user_id/subscribe',
    category: 'users',
    userType: 'both',
    description: 'Unsubscribe from a public user',
    pathParams: [
      { name: 'target_user_id', type: 'number', required: true, description: 'Target user ID', example: 86 },
    ],
  },
  {
    id: 'list-public-users',
    name: 'List Public Users',
    method: 'GET',
    path: '/api/v1/users/public',
    category: 'users',
    userType: 'both',
    description: 'List all public users',
  },
  {
    id: 'sync-contacts',
    name: 'Sync Contacts',
    method: 'POST',
    path: '/api/v1/contacts/sync',
    category: 'contacts',
    userType: 'private',
    description: 'Sync device contacts',
    bodyParams: [
      { name: 'contacts', type: 'array', required: true, description: 'Contact list' },
    ],
  },
  {
    id: 'list-user-contacts',
    name: 'List User Contacts',
    method: 'GET',
    path: '/api/v1/contacts',
    category: 'contacts',
    userType: 'private',
    description: 'List user contacts',
  },
  {
    id: 'block-user',
    name: 'Block User',
    method: 'POST',
    path: '/api/v1/blocks',
    category: 'users',
    userType: 'both',
    description: 'Block a user',
    bodyParams: [
      { name: 'blocked_user_id', type: 'number', required: true, description: 'User ID to block' },
    ],
  },
  {
    id: 'list-blocked-users',
    name: 'List Blocked Users',
    method: 'GET',
    path: '/api/v1/blocks',
    category: 'users',
    userType: 'both',
    description: 'List blocked users',
  },
  {
    id: 'unblock-user',
    name: 'Unblock User',
    method: 'DELETE',
    path: '/api/v1/blocks/:block_id',
    category: 'users',
    userType: 'both',
    description: 'Unblock a user',
    pathParams: [
      { name: 'block_id', type: 'number', required: true, description: 'Block ID', example: 1 },
    ],
  },

  // ============================================================================
  // EVENTS - PRIVATE
  // ============================================================================
  {
    id: 'list-my-events',
    name: 'List My Events',
    method: 'GET',
    path: '/api/v1/events',
    category: 'events',
    userType: 'private',
    description: 'List all events for current user (invited, created, etc.)',
  },
  {
    id: 'create-event',
    name: 'Create Event',
    method: 'POST',
    path: '/api/v1/events',
    category: 'events',
    userType: 'private',
    description: 'Create a new private event',
    bodyParams: [
      { name: 'name', type: 'string', required: true, description: 'Event name', example: 'Cena con amigos' },
      { name: 'description', type: 'string', required: false, description: 'Event description' },
      { name: 'start_date', type: 'date', required: true, description: 'Start date', example: '2025-12-25T20:00:00' },
      { name: 'end_date', type: 'date', required: false, description: 'End date' },
      { name: 'location', type: 'string', required: false, description: 'Event location' },
    ],
  },
  {
    id: 'get-event',
    name: 'Get Event',
    method: 'GET',
    path: '/api/v1/events/:event_id',
    category: 'events',
    userType: 'both',
    description: 'Get event details',
    pathParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
    ],
  },
  {
    id: 'update-event',
    name: 'Update Event',
    method: 'PUT',
    path: '/api/v1/events/:event_id',
    category: 'events',
    userType: 'private',
    description: 'Update event details (owner only)',
    pathParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
    ],
    bodyParams: [
      { name: 'name', type: 'string', required: false, description: 'Event name' },
      { name: 'description', type: 'string', required: false, description: 'Event description' },
      { name: 'start_date', type: 'date', required: false, description: 'Start date' },
    ],
  },
  {
    id: 'delete-event',
    name: 'Delete Event',
    method: 'DELETE',
    path: '/api/v1/events/:event_id',
    category: 'events',
    userType: 'private',
    description: 'Delete event (owner only)',
    pathParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
    ],
  },
  {
    id: 'get-event-interactions',
    name: 'Get Event Interactions',
    method: 'GET',
    path: '/api/v1/events/:event_id/interactions',
    category: 'events',
    userType: 'both',
    description: 'Get all interactions for an event',
    pathParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
    ],
  },
  {
    id: 'get-event-interactions-enriched',
    name: 'Get Event Interactions Enriched',
    method: 'GET',
    path: '/api/v1/events/:event_id/interactions-enriched',
    category: 'events',
    userType: 'both',
    description: 'Get enriched interactions for an event',
    pathParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
    ],
  },
  {
    id: 'get-available-invitees',
    name: 'Get Available Invitees',
    method: 'GET',
    path: '/api/v1/events/:event_id/available-invitees',
    category: 'events',
    userType: 'private',
    description: 'Get users that can be invited to event',
    pathParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
    ],
  },
  {
    id: 'get-current-user-interaction',
    name: 'Get My Event Interaction',
    method: 'GET',
    path: '/api/v1/events/:event_id/interaction',
    category: 'events',
    userType: 'both',
    description: 'Get current user interaction with event',
    pathParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
    ],
  },
  {
    id: 'update-event-interaction',
    name: 'Update Event Interaction',
    method: 'PATCH',
    path: '/api/v1/events/:event_id/interaction',
    category: 'events',
    userType: 'both',
    description: 'Update event interaction (accept/reject)',
    pathParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
    ],
    bodyParams: [
      { name: 'status', type: 'string', required: true, description: 'Status', example: 'accepted' },
    ],
  },
  {
    id: 'delete-event-interaction',
    name: 'Delete Event Interaction',
    method: 'DELETE',
    path: '/api/v1/events/:event_id/interaction',
    category: 'events',
    userType: 'both',
    description: 'Delete event interaction',
    pathParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
    ],
  },
  {
    id: 'invite-user-to-event',
    name: 'Invite User to Event',
    method: 'POST',
    path: '/api/v1/events/:event_id/interaction/invite',
    category: 'events',
    userType: 'private',
    description: 'Invite user to event',
    pathParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
    ],
    bodyParams: [
      { name: 'invited_user_id', type: 'number', required: true, description: 'User to invite', example: 2 },
    ],
  },
  {
    id: 'get-event-cancellations',
    name: 'Get Event Cancellations',
    method: 'GET',
    path: '/api/v1/events/cancellations',
    category: 'events',
    userType: 'both',
    description: 'Get event cancellations',
  },
  {
    id: 'mark-cancellation-viewed',
    name: 'Mark Cancellation as Viewed',
    method: 'POST',
    path: '/api/v1/events/cancellations/:cancellation_id/view',
    category: 'events',
    userType: 'both',
    description: 'Mark cancellation as viewed',
    pathParams: [
      { name: 'cancellation_id', type: 'number', required: true, description: 'Cancellation ID', example: 1 },
    ],
  },

  // ============================================================================
  // EVENTS - PUBLIC
  // ============================================================================
  {
    id: 'create-public-event',
    name: 'Create Public Event',
    method: 'POST',
    path: '/api/v1/events/public',
    category: 'events',
    userType: 'public',
    description: 'Create a new public event (public users only)',
    bodyParams: [
      { name: 'name', type: 'string', required: true, description: 'Event name', example: 'Concierto Jazz' },
      { name: 'description', type: 'string', required: false, description: 'Event description' },
      { name: 'start_date', type: 'date', required: true, description: 'Start date', example: '2025-12-25T20:00:00' },
      { name: 'max_attendees', type: 'number', required: false, description: 'Maximum attendees' },
    ],
  },
  {
    id: 'list-public-events',
    name: 'Discover Public Events',
    method: 'GET',
    path: '/api/v1/events/public',
    category: 'events',
    userType: 'both',
    description: 'Browse all public events',
    queryParams: [
      { name: 'limit', type: 'number', required: false, description: 'Limit results', example: 20 },
      { name: 'offset', type: 'number', required: false, description: 'Offset for pagination', example: 0 },
    ],
  },

  // ============================================================================
  // CALENDARS
  // ============================================================================
  {
    id: 'list-calendars',
    name: 'List My Calendars',
    method: 'GET',
    path: '/api/v1/calendars',
    category: 'calendars',
    userType: 'both',
    description: 'List all calendars user has access to',
  },
  {
    id: 'create-calendar',
    name: 'Create Calendar',
    method: 'POST',
    path: '/api/v1/calendars',
    category: 'calendars',
    userType: 'both',
    description: 'Create a new calendar',
    bodyParams: [
      { name: 'name', type: 'string', required: true, description: 'Calendar name', example: 'Work' },
      { name: 'description', type: 'string', required: false, description: 'Calendar description' },
      { name: 'is_public', type: 'boolean', required: false, description: 'Is public calendar?', example: false },
    ],
  },
  {
    id: 'discover-calendar',
    name: 'Discover Calendar by Hash',
    method: 'GET',
    path: '/api/v1/calendars/discover/:share_hash',
    category: 'calendars',
    userType: 'both',
    description: 'Find a public calendar by its share hash',
    pathParams: [
      { name: 'share_hash', type: 'string', required: true, description: 'Calendar share hash', example: 'fcb25_26' },
    ],
  },
  {
    id: 'subscribe-calendar',
    name: 'Subscribe to Calendar',
    method: 'POST',
    path: '/api/v1/calendars/share/:share_hash/subscribe',
    category: 'calendars',
    userType: 'both',
    description: 'Subscribe to a public calendar by share hash',
    pathParams: [
      { name: 'share_hash', type: 'string', required: true, description: 'Share hash', example: 'fcb25_26' },
    ],
  },
  {
    id: 'unsubscribe-calendar',
    name: 'Unsubscribe from Calendar',
    method: 'DELETE',
    path: '/api/v1/calendars/share/:share_hash/subscribe',
    category: 'calendars',
    userType: 'both',
    description: 'Unsubscribe from a calendar',
    pathParams: [
      { name: 'share_hash', type: 'string', required: true, description: 'Share hash', example: 'fcb25_26' },
    ],
  },
  {
    id: 'get-calendar',
    name: 'Get Calendar',
    method: 'GET',
    path: '/api/v1/calendars/:calendar_id',
    category: 'calendars',
    userType: 'both',
    description: 'Get calendar details',
    pathParams: [
      { name: 'calendar_id', type: 'number', required: true, description: 'Calendar ID', example: 1 },
    ],
  },
  {
    id: 'update-calendar',
    name: 'Update Calendar',
    method: 'PUT',
    path: '/api/v1/calendars/:calendar_id',
    category: 'calendars',
    userType: 'both',
    description: 'Update calendar',
    pathParams: [
      { name: 'calendar_id', type: 'number', required: true, description: 'Calendar ID', example: 1 },
    ],
    bodyParams: [
      { name: 'name', type: 'string', required: false, description: 'Calendar name' },
      { name: 'description', type: 'string', required: false, description: 'Description' },
    ],
  },
  {
    id: 'delete-calendar',
    name: 'Delete Calendar',
    method: 'DELETE',
    path: '/api/v1/calendars/:calendar_id',
    category: 'calendars',
    userType: 'both',
    description: 'Delete calendar',
    pathParams: [
      { name: 'calendar_id', type: 'number', required: true, description: 'Calendar ID', example: 1 },
    ],
  },
  {
    id: 'get-calendar-memberships',
    name: 'Get Calendar Memberships',
    method: 'GET',
    path: '/api/v1/calendars/:calendar_id/memberships',
    category: 'calendars',
    userType: 'both',
    description: 'Get calendar memberships',
    pathParams: [
      { name: 'calendar_id', type: 'number', required: true, description: 'Calendar ID', example: 1 },
    ],
  },
  {
    id: 'add-calendar-member',
    name: 'Add Calendar Member',
    method: 'POST',
    path: '/api/v1/calendars/:calendar_id/memberships',
    category: 'calendars',
    userType: 'both',
    description: 'Add member to calendar',
    pathParams: [
      { name: 'calendar_id', type: 'number', required: true, description: 'Calendar ID', example: 1 },
    ],
    bodyParams: [
      { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 2 },
      { name: 'role', type: 'string', required: false, description: 'Role', example: 'member' },
    ],
  },
  {
    id: 'update-calendar-membership',
    name: 'Update Calendar Membership',
    method: 'PUT',
    path: '/api/v1/calendars/memberships/:membership_id',
    category: 'calendars',
    userType: 'both',
    description: 'Update calendar membership',
    pathParams: [
      { name: 'membership_id', type: 'number', required: true, description: 'Membership ID', example: 1 },
    ],
    bodyParams: [
      { name: 'role', type: 'string', required: false, description: 'Role' },
      { name: 'status', type: 'string', required: false, description: 'Status' },
    ],
  },
  {
    id: 'delete-calendar-membership',
    name: 'Delete Calendar Membership',
    method: 'DELETE',
    path: '/api/v1/calendars/memberships/:membership_id',
    category: 'calendars',
    userType: 'both',
    description: 'Remove member from calendar',
    pathParams: [
      { name: 'membership_id', type: 'number', required: true, description: 'Membership ID', example: 1 },
    ],
  },
  {
    id: 'list-calendar-memberships',
    name: 'List My Calendar Memberships',
    method: 'GET',
    path: '/api/v1/calendars/memberships',
    category: 'calendars',
    userType: 'both',
    description: 'List all calendar memberships',
  },

  // ============================================================================
  // GROUPS
  // ============================================================================
  {
    id: 'list-groups',
    name: 'List My Groups',
    method: 'GET',
    path: '/api/v1/groups',
    category: 'groups',
    userType: 'private',
    description: 'List all groups user is member of',
  },
  {
    id: 'create-group',
    name: 'Create Group',
    method: 'POST',
    path: '/api/v1/groups',
    category: 'groups',
    userType: 'private',
    description: 'Create a new group',
    bodyParams: [
      { name: 'name', type: 'string', required: true, description: 'Group name', example: 'Familia' },
      { name: 'description', type: 'string', required: false, description: 'Group description' },
    ],
  },
  {
    id: 'get-group',
    name: 'Get Group',
    method: 'GET',
    path: '/api/v1/groups/:group_id',
    category: 'groups',
    userType: 'private',
    description: 'Get group details',
    pathParams: [
      { name: 'group_id', type: 'number', required: true, description: 'Group ID', example: 1 },
    ],
  },
  {
    id: 'update-group',
    name: 'Update Group',
    method: 'PUT',
    path: '/api/v1/groups/:group_id',
    category: 'groups',
    userType: 'private',
    description: 'Update group details',
    pathParams: [
      { name: 'group_id', type: 'number', required: true, description: 'Group ID', example: 1 },
    ],
    bodyParams: [
      { name: 'name', type: 'string', required: false, description: 'Group name' },
      { name: 'description', type: 'string', required: false, description: 'Description' },
    ],
  },
  {
    id: 'delete-group',
    name: 'Delete Group',
    method: 'DELETE',
    path: '/api/v1/groups/:group_id',
    category: 'groups',
    userType: 'private',
    description: 'Delete group',
    pathParams: [
      { name: 'group_id', type: 'number', required: true, description: 'Group ID', example: 1 },
    ],
  },
  {
    id: 'list-group-members',
    name: 'List Group Members',
    method: 'GET',
    path: '/api/v1/groups/:group_id/members',
    category: 'groups',
    userType: 'private',
    description: 'List all group members',
    pathParams: [
      { name: 'group_id', type: 'number', required: true, description: 'Group ID', example: 1 },
    ],
  },
  {
    id: 'add-group-member',
    name: 'Add Group Member',
    method: 'POST',
    path: '/api/v1/groups/:group_id/members',
    category: 'groups',
    userType: 'private',
    description: 'Add a member to group (admin/owner only)',
    pathParams: [
      { name: 'group_id', type: 'number', required: true, description: 'Group ID', example: 1 },
    ],
    bodyParams: [
      { name: 'user_id', type: 'number', required: true, description: 'User ID to add', example: 5 },
      { name: 'role', type: 'string', required: false, description: 'Member role', example: 'member' },
    ],
  },
  {
    id: 'remove-group-member',
    name: 'Remove Group Member',
    method: 'DELETE',
    path: '/api/v1/groups/:group_id/members/:user_id',
    category: 'groups',
    userType: 'private',
    description: 'Remove member from group',
    pathParams: [
      { name: 'group_id', type: 'number', required: true, description: 'Group ID', example: 1 },
      { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 5 },
    ],
  },
  {
    id: 'leave-group',
    name: 'Leave Group',
    method: 'DELETE',
    path: '/api/v1/groups/:group_id/leave',
    category: 'groups',
    userType: 'private',
    description: 'Leave a group',
    pathParams: [
      { name: 'group_id', type: 'number', required: true, description: 'Group ID', example: 1 },
    ],
  },

  // ============================================================================
  // INTERACTIONS
  // ============================================================================
  {
    id: 'list-interactions',
    name: 'List My Interactions',
    method: 'GET',
    path: '/api/v1/interactions',
    category: 'interactions',
    userType: 'both',
    description: 'List all event interactions',
  },
  {
    id: 'get-interaction',
    name: 'Get Interaction',
    method: 'GET',
    path: '/api/v1/interactions/:interaction_id',
    category: 'interactions',
    userType: 'both',
    description: 'Get interaction details',
    pathParams: [
      { name: 'interaction_id', type: 'number', required: true, description: 'Interaction ID', example: 1 },
    ],
  },
  {
    id: 'update-interaction',
    name: 'Update Interaction',
    method: 'PATCH',
    path: '/api/v1/interactions/:interaction_id',
    category: 'interactions',
    userType: 'both',
    description: 'Update interaction status',
    pathParams: [
      { name: 'interaction_id', type: 'number', required: true, description: 'Interaction ID', example: 1 },
    ],
    bodyParams: [
      { name: 'status', type: 'string', required: true, description: 'Status', example: 'accepted' },
    ],
  },
  {
    id: 'delete-interaction',
    name: 'Delete Interaction',
    method: 'DELETE',
    path: '/api/v1/interactions/:interaction_id',
    category: 'interactions',
    userType: 'both',
    description: 'Delete interaction',
    pathParams: [
      { name: 'interaction_id', type: 'number', required: true, description: 'Interaction ID', example: 1 },
    ],
  },
  {
    id: 'mark-interaction-read',
    name: 'Mark Interaction as Read',
    method: 'POST',
    path: '/api/v1/interactions/:interaction_id/mark-read',
    category: 'interactions',
    userType: 'both',
    description: 'Mark interaction as read',
    pathParams: [
      { name: 'interaction_id', type: 'number', required: true, description: 'Interaction ID', example: 1 },
    ],
  },
  {
    id: 'create-interaction',
    name: 'Create Interaction',
    method: 'POST',
    path: '/api/v1/interactions',
    category: 'interactions',
    userType: 'both',
    description: 'Create new interaction',
    bodyParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
      { name: 'interaction_type', type: 'string', required: true, description: 'Type', example: 'subscribed' },
    ],
  },

  // ============================================================================
  // EVENT BANS
  // ============================================================================
  {
    id: 'list-event-bans',
    name: 'List Event Bans',
    method: 'GET',
    path: '/api/v1/bans',
    category: 'bans',
    userType: 'both',
    description: 'List event bans',
    queryParams: [
      { name: 'event_id', type: 'number', required: false, description: 'Filter by event', example: 1 },
      { name: 'user_id', type: 'number', required: false, description: 'Filter by user', example: 2 },
    ],
  },
  {
    id: 'get-event-ban',
    name: 'Get Event Ban',
    method: 'GET',
    path: '/api/v1/bans/:ban_id',
    category: 'bans',
    userType: 'both',
    description: 'Get ban details',
    pathParams: [
      { name: 'ban_id', type: 'number', required: true, description: 'Ban ID', example: 1 },
    ],
  },
  {
    id: 'create-event-ban',
    name: 'Create Event Ban',
    method: 'POST',
    path: '/api/v1/bans',
    category: 'bans',
    userType: 'both',
    description: 'Ban user from event',
    bodyParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
      { name: 'banned_user_id', type: 'number', required: true, description: 'User to ban', example: 5 },
      { name: 'reason', type: 'string', required: false, description: 'Ban reason' },
    ],
  },
  {
    id: 'delete-event-ban',
    name: 'Delete Event Ban',
    method: 'DELETE',
    path: '/api/v1/bans/:ban_id',
    category: 'bans',
    userType: 'both',
    description: 'Remove ban',
    pathParams: [
      { name: 'ban_id', type: 'number', required: true, description: 'Ban ID', example: 1 },
    ],
  },

  // ============================================================================
  // RECURRING CONFIGS
  // ============================================================================
  {
    id: 'list-recurring-configs',
    name: 'List Recurring Configs',
    method: 'GET',
    path: '/api/v1/recurring-configs',
    category: 'recurring',
    userType: 'both',
    description: 'List recurring event configurations',
    queryParams: [
      { name: 'event_id', type: 'number', required: false, description: 'Filter by event', example: 100 },
    ],
  },
  {
    id: 'get-recurring-config',
    name: 'Get Recurring Config',
    method: 'GET',
    path: '/api/v1/recurring-configs/:config_id',
    category: 'recurring',
    userType: 'both',
    description: 'Get recurring config details',
    pathParams: [
      { name: 'config_id', type: 'number', required: true, description: 'Config ID', example: 1 },
    ],
  },
  {
    id: 'create-recurring-config',
    name: 'Create Recurring Config',
    method: 'POST',
    path: '/api/v1/recurring-configs',
    category: 'recurring',
    userType: 'both',
    description: 'Create recurring event configuration',
    bodyParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 100 },
      { name: 'recurrence_type', type: 'string', required: true, description: 'Type', example: 'weekly' },
      { name: 'schedule', type: 'string', required: true, description: 'Schedule JSON', example: '{"interval": 1, "days_of_week": "1,3,5"}' },
    ],
  },
  {
    id: 'update-recurring-config',
    name: 'Update Recurring Config',
    method: 'PUT',
    path: '/api/v1/recurring-configs/:config_id',
    category: 'recurring',
    userType: 'both',
    description: 'Update recurring config',
    pathParams: [
      { name: 'config_id', type: 'number', required: true, description: 'Config ID', example: 1 },
    ],
    bodyParams: [
      { name: 'recurrence_type', type: 'string', required: false, description: 'Type' },
      { name: 'schedule', type: 'string', required: false, description: 'Schedule JSON' },
    ],
  },
  {
    id: 'delete-recurring-config',
    name: 'Delete Recurring Config',
    method: 'DELETE',
    path: '/api/v1/recurring-configs/:config_id',
    category: 'recurring',
    userType: 'both',
    description: 'Delete recurring config',
    pathParams: [
      { name: 'config_id', type: 'number', required: true, description: 'Config ID', example: 1 },
    ],
  },
];
