import { Endpoint } from '../index';

export const updateCurrentUserInteraction: Endpoint = {
  id: 'update-current-user-interaction',
  name: 'Update Current User Interaction',
  method: 'PATCH',
  path: '/api/v1/events/:event_id/interaction',
  category: 'events',
  userType: 'both',
  description: 'Update current user\'s interaction with an event',
  pathParams: [
    { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
  ],
  bodyParams: [
    { name: 'status', type: 'string', required: false, description: 'Status: accepted, rejected, pending', default: null },
    { name: 'is_attending', type: 'boolean', required: false, description: 'Is attending', default: null },
    { name: 'personal_note', type: 'string', required: false, description: 'Personal note', default: null },
  ],
};
