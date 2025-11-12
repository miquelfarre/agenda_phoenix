import { Endpoint } from '../index';

export const deleteCurrentUserInteraction: Endpoint = {
  id: 'delete-current-user-interaction',
  name: 'Delete Current User Interaction',
  method: 'DELETE',
  path: '/api/v1/events/:event_id/interaction',
  category: 'events',
  userType: 'both',
  description: 'Delete current user\'s interaction with an event',
  pathParams: [
    { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
  ],
};
