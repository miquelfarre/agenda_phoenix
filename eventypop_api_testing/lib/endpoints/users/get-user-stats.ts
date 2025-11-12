import { Endpoint } from '../index';

export const getUserStats: Endpoint = {
  id: 'get-user-stats',
  name: 'Get User Stats',
  method: 'GET',
  path: '/api/v1/users/:user_id/stats',
  category: 'users',
  userType: 'both',
  description: 'Get user statistics (events, subscriptions, groups)',
  pathParams: [
    { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 1 },
  ],
};
