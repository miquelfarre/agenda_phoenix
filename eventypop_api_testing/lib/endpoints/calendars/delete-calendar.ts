import { Endpoint } from '../index';

export const deleteCalendar: Endpoint = {
  id: 'delete-calendar',
  name: 'Delete Calendar',
  method: 'DELETE',
  path: '/api/v1/calendars/:calendar_id',
  category: 'calendars',
  userType: 'both',
  description: 'Delete a calendar',
  pathParams: [
    { name: 'calendar_id', type: 'number', required: true, description: 'Calendar ID', example: 1 },
  ],
  queryParams: [
    { name: 'delete_events', type: 'boolean', required: false, description: 'Also delete all events in calendar', default: false },
  ],
};
