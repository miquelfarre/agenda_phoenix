import { Endpoint } from '../index';

export const getAvailableInvitees: Endpoint = {
  id: 'get-available-invitees',
  name: 'Get Available Invitees',
  method: 'GET',
  path: '/api/v1/events/:event_id/available-invitees',
  category: 'events',
  userType: 'both',
  description: 'Get list of users available to invite to an event',
  pathParams: [
    { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
  ],
};
