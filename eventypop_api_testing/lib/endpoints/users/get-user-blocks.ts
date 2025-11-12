import { Endpoint } from '../index';

export const getUserBlocks: Endpoint = {
  id: 'get-user-blocks',
  name: 'Get User Blocks',
  method: 'GET',
  path: '/api/v1/user_blocks',
  category: 'users',
  userType: 'both',
  description: 'Get all user blocks',
  queryParams: [
    { name: 'blocker_user_id', type: 'number', required: false, description: 'Filter by blocker user ID', default: null },
    { name: 'blocked_user_id', type: 'number', required: false, description: 'Filter by blocked user ID', default: null },
    { name: 'limit', type: 'number', required: false, description: 'Max number of results', default: 50 },
    { name: 'offset', type: 'number', required: false, description: 'Pagination offset', default: 0 },
  ],
};
