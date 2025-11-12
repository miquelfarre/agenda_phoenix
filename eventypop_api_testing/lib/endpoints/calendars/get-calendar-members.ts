import { Endpoint } from '../index';

export const getCalendarMembers: Endpoint = {
  id: 'get-calendar-members',
  name: 'Get Calendar Members',
  method: 'GET',
  path: '/api/v1/calendars/:calendar_id/memberships',
  category: 'calendars',
  userType: 'both',
  description: 'Get all members of a calendar',
  pathParams: [
    { name: 'calendar_id', type: 'number', required: true, description: 'Calendar ID', example: 1 },
  ],
};
