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
    path: '/api/v1/calendars/:calendar_id/subscribe',
    category: 'calendars',
    userType: 'both',
    description: 'Subscribe to a public calendar',
    pathParams: [
      { name: 'calendar_id', type: 'number', required: true, description: 'Calendar ID', example: 10 },
    ],
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

  // ============================================================================
  // CONTACTS
  // ============================================================================
  {
    id: 'list-contacts',
    name: 'List My Contacts',
    method: 'GET',
    path: '/api/v1/contacts',
    category: 'contacts',
    userType: 'private',
    description: 'List all contacts',
  },
  {
    id: 'add-contact',
    name: 'Add Contact',
    method: 'POST',
    path: '/api/v1/contacts',
    category: 'contacts',
    userType: 'private',
    description: 'Add a new contact',
    bodyParams: [
      { name: 'phone_number', type: 'string', required: true, description: 'Phone number', example: '+34612345678' },
      { name: 'display_name', type: 'string', required: false, description: 'Contact name' },
    ],
  },

  // ============================================================================
  // INTERACTIONS
  // ============================================================================
  {
    id: 'invite-to-event',
    name: 'Invite to Event',
    method: 'POST',
    path: '/api/v1/interactions/invite',
    category: 'interactions',
    userType: 'private',
    description: 'Invite users to an event',
    bodyParams: [
      { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
      { name: 'user_ids', type: 'array', required: true, description: 'User IDs to invite', example: [2, 3, 4] },
    ],
  },
  {
    id: 'respond-invitation',
    name: 'Respond to Invitation',
    method: 'PATCH',
    path: '/api/v1/interactions/:interaction_id',
    category: 'interactions',
    userType: 'both',
    description: 'Accept/reject event invitation',
    pathParams: [
      { name: 'interaction_id', type: 'number', required: true, description: 'Interaction ID', example: 1 },
    ],
    bodyParams: [
      { name: 'status', type: 'string', required: true, description: 'Status', example: 'accepted' },
    ],
  },
  {
    id: 'list-invitations',
    name: 'List My Invitations',
    method: 'GET',
    path: '/api/v1/interactions/invitations',
    category: 'interactions',
    userType: 'both',
    description: 'List pending invitations',
  },
];
