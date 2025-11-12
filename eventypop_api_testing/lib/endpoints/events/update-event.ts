import { Endpoint } from '../index';

export const updateEvent: Endpoint = {
  id: 'update-event',
  name: 'Update Event',
  method: 'PUT',
  path: '/api/v1/events/:event_id',
  category: 'events',
  userType: 'both',
  description: 'Update an existing event',
  pathParams: [
    { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
  ],
  bodyParams: [
    { name: 'name', type: 'string', required: false, description: 'Event name', default: null },
    { name: 'description', type: 'string', required: false, description: 'Event description', default: null },
    { name: 'start_date', type: 'date', required: false, description: 'Start date (ISO format)', default: null },
    { name: 'event_type', type: 'string', required: false, description: 'Event type', default: null },
    { name: 'calendar_id', type: 'number', required: false, description: 'Calendar ID', default: null },
  ],
};
