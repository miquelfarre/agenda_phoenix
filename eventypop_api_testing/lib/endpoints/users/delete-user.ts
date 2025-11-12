import { Endpoint } from '../index';

export const deleteUser: Endpoint = {
  id: 'delete-user',
  name: 'Delete User',
  method: 'DELETE',
  path: '/api/v1/users/:user_id',
  category: 'users',
  userType: 'both',
  description: 'Delete user account',
  pathParams: [
    { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 1 },
  ],
};
