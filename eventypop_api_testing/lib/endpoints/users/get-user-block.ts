import { Endpoint } from '../index';

export const getUserBlock: Endpoint = {
  id: 'get-user-block',
  name: 'Get User Block',
  method: 'GET',
  path: '/api/v1/user-blocks/:block_id',
  category: 'users',
  userType: 'both',
  description: 'Get user block details by ID',
  pathParams: [
    { name: 'block_id', type: 'number', required: true, description: 'Block ID', example: 1 },
  ],
};
