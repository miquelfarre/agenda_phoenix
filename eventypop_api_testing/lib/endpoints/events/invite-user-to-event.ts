import { Endpoint } from '../index';

export const inviteUserToEvent: Endpoint = {
  id: 'invite-user-to-event',
  name: 'Invite User to Event',
  method: 'POST',
  path: '/api/v1/events/:event_id/interaction/invite',
  category: 'events',
  userType: 'both',
  description: 'Invite a user to an event',
  pathParams: [
    { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
  ],
  bodyParams: [
    { name: 'user_id', type: 'number', required: true, description: 'User ID to invite' },
    { name: 'role', type: 'string', required: false, description: 'Role: admin or member', default: 'member' },
  ],
};
