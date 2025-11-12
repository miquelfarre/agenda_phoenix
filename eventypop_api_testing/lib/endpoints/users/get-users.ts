import { Endpoint } from '../index';

export const getUsers: Endpoint = {
  id: 'get-users',
  name: 'Get Users',
  method: 'GET',
  path: '/api/v1/users',
  category: 'users',
  userType: 'both',
  description: 'Get all users with optional filters',
  queryParams: [
    { name: 'public', type: 'boolean', required: false, description: 'Filter by public/private users', default: null },
    { name: 'search', type: 'string', required: false, description: 'Search by display_name or instagram_username', default: null },
    { name: 'exclude_user_id', type: 'number', required: false, description: 'Exclude specific user ID', default: null },
    { name: 'limit', type: 'number', required: false, description: 'Max number of results', default: 50 },
    { name: 'offset', type: 'number', required: false, description: 'Pagination offset', default: 0 },
    { name: 'order_by', type: 'string', required: false, description: 'Order by field', default: 'id' },
    { name: 'order_dir', type: 'string', required: false, description: 'Order direction: asc or desc', default: 'asc' },
  ],
};
