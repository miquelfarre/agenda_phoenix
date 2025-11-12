import { Endpoint } from '../index';

export const deleteUserBlock: Endpoint = {
  id: 'delete-user-block',
  name: 'Unblock User',
  method: 'DELETE',
  path: '/api/v1/user_blocks/:block_id',
  category: 'users',
  userType: 'both',
  description: 'Unblock a user',
  pathParams: [
    { name: 'block_id', type: 'number', required: true, description: 'Block ID', example: 1 },
  ],
};
