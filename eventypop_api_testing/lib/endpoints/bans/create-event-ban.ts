import { Endpoint } from '../index';

export const createEventBan: Endpoint = {
  id: 'create-event-ban',
  name: 'Create Event Ban',
  method: 'POST',
  path: '/api/v1/event-bans',
  category: 'bans',
  userType: 'both',
  description: 'Ban a user from an event',
  bodyParams: [
    { name: 'event_id', type: 'number', required: true, description: 'Event ID' },
    { name: 'banned_user_id', type: 'number', required: true, description: 'User ID to ban' },
    { name: 'reason', type: 'string', required: false, description: 'Ban reason', default: null },
  ],
};
