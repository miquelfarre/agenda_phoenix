import { Endpoint } from '../index';

export const getUser: Endpoint = {
  id: 'get-user',
  name: 'Get User',
  method: 'GET',
  path: '/api/v1/users/:user_id',
  category: 'users',
  userType: 'both',
  description: 'Get user details by ID',
  pathParams: [
    { name: 'user_id', type: 'number', required: true, description: 'User ID', example: 1 },
  ],
  queryParams: [
    { name: 'enriched', type: 'boolean', required: false, description: 'Include contact information', default: false },
  ],
};
