import { Endpoint } from '../index';

export const deleteEvent: Endpoint = {
  id: 'delete-event',
  name: 'Delete Event',
  method: 'DELETE',
  path: '/api/v1/events/:event_id',
  category: 'events',
  userType: 'both',
  description: 'Delete an event',
  pathParams: [
    { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
  ],
  bodyParams: [
    { name: 'delete_series', type: 'boolean', required: false, description: 'For recurring events: delete entire series', default: false },
  ],
};
