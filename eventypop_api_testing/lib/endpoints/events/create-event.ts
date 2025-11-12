import { Endpoint } from '../index';

export const createEvent: Endpoint = {
  id: 'create-event',
  name: 'Create Event',
  method: 'POST',
  path: '/api/v1/events',
  category: 'events',
  userType: 'both',
  description: 'Create a new event',
  bodyParams: [
    { name: 'name', type: 'string', required: true, description: 'Event name' },
    { name: 'description', type: 'string', required: false, description: 'Event description', default: null },
    { name: 'start_date', type: 'date', required: true, description: 'Start date (ISO format)' },
    { name: 'event_type', type: 'string', required: false, description: 'Event type: regular or recurring', default: 'regular' },
    { name: 'calendar_id', type: 'number', required: false, description: 'Calendar ID', default: null },
  ],
};
