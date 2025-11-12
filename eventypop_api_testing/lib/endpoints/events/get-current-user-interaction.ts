import { Endpoint } from '../index';

export const getCurrentUserInteraction: Endpoint = {
  id: 'get-current-user-interaction',
  name: 'Get Current User Interaction',
  method: 'GET',
  path: '/api/v1/events/:event_id/interaction',
  category: 'events',
  userType: 'both',
  description: 'Get current user\'s interaction with an event',
  pathParams: [
    { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
  ],
};
