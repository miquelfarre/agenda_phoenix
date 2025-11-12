import { Endpoint } from '../index';

export const unsubscribeFromUser: Endpoint = {
  id: 'unsubscribe-from-user',
  name: 'Unsubscribe from User',
  method: 'DELETE',
  path: '/api/v1/users/:target_user_id/subscribe',
  category: 'users',
  userType: 'private',
  description: 'Unsubscribe from a public user',
  pathParams: [
    { name: 'target_user_id', type: 'number', required: true, description: 'Public user ID to unsubscribe from', example: 86 },
  ],
};
