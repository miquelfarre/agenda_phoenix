import { Endpoint } from '../index';

export const getAccessibleCalendarIds: Endpoint = {
  id: 'get-accessible-calendar-ids',
  name: 'Get Accessible Calendar IDs',
  method: 'GET',
  path: '/api/v1/users/:user_id/accessible-calendar-ids',
  category: 'users',
  userType: 'both',
  description: 'Get IDs of calendars accessible to a user',
  pathParams: [
    { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 1 },
  ],
};
