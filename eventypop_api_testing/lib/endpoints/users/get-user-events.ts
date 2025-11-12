import { Endpoint } from '../index';

export const getUserEvents: Endpoint = {
  id: 'get-user-events',
  name: 'Get User Events',
  method: 'GET',
  path: '/api/v1/users/:user_id/events',
  category: 'users',
  userType: 'both',
  description: 'Get events for a user',
  pathParams: [
    { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 1 },
  ],
  queryParams: [
    { name: 'include_past', type: 'boolean', required: false, description: 'Include past events', default: false },
    { name: 'from_date', type: 'date', required: false, description: 'Start date (ISO format)', default: null },
    { name: 'to_date', type: 'date', required: false, description: 'End date (ISO format)', default: null },
    { name: 'search', type: 'string', required: false, description: 'Search by event name', default: null },
    { name: 'filter', type: 'string', required: false, description: 'Predefined filter: today, next_7_days, this_month', default: null },
    { name: 'limit', type: 'number', required: false, description: 'Max number of events', default: null },
    { name: 'offset', type: 'number', required: false, description: 'Pagination offset', default: 0 },
  ],
};
