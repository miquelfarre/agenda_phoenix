import { Endpoint } from '../index';

export const subscribeToUser: Endpoint = {
  id: 'subscribe-to-user',
  name: 'Subscribe to User',
  method: 'POST',
  path: '/api/v1/users/:target_user_id/subscribe',
  category: 'users',
  userType: 'private',
  description: 'Subscribe to a public user',
  pathParams: [
    { name: 'target_user_id', type: 'number', required: true, description: 'Public user ID to subscribe to', example: 86 },
  ],
};
