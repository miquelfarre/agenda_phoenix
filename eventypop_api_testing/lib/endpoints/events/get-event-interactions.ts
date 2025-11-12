import { Endpoint } from '../index';

export const getEventInteractions: Endpoint = {
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
};
