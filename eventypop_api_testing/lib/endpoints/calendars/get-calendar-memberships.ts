import { Endpoint } from '../index';

export const getCalendarMemberships: Endpoint = {
  id: 'get-calendar-memberships',
  name: 'Get Calendar Memberships',
  method: 'GET',
  path: '/api/v1/calendar-memberships',
  category: 'calendars',
  userType: 'both',
  description: 'Get all calendar memberships',
  queryParams: [
    { name: 'calendar_id', type: 'number', required: false, description: 'Filter by calendar ID', default: null },
    { name: 'user_id', type: 'number', required: false, description: 'Filter by user ID', default: null },
    { name: 'enriched', type: 'boolean', required: false, description: 'Include user/calendar info', default: false },
    { name: 'limit', type: 'number', required: false, description: 'Max number of results', default: 50 },
    { name: 'offset', type: 'number', required: false, description: 'Pagination offset', default: 0 },
  ],
};
