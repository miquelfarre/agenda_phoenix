import { Endpoint } from '../index';

export const getEvent: Endpoint = {
  id: 'get-event',
  name: 'Get Event',
  method: 'GET',
  path: '/api/v1/events/:event_id',
  category: 'events',
  userType: 'both',
  description: 'Get event details by ID',
  pathParams: [
    { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
  ],
};
