import { Endpoint } from '../index';

export const getUserSubscriptions: Endpoint = {
  id: 'get-user-subscriptions',
  name: 'Get User Subscriptions',
  method: 'GET',
  path: '/api/v1/users/:user_id/subscriptions',
  category: 'users',
  userType: 'private',
  description: 'Get list of public users that a user is subscribed to',
  pathParams: [
    { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 1 },
  ],
};
