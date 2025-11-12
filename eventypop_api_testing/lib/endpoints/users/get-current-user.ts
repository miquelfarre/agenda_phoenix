import { Endpoint } from '../index';

export const getCurrentUser: Endpoint = {
  id: 'get-current-user',
  name: 'Get Current User',
  method: 'GET',
  path: '/api/v1/users/me',
  category: 'users',
  userType: 'both',
  description: 'Get current authenticated user',
  queryParams: [
    { name: 'enriched', type: 'boolean', required: false, description: 'Include contact information', default: false },
  ],
};
