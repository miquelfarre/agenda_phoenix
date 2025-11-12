import { Endpoint } from '../index';

export const getGroups: Endpoint = {
  id: 'get-groups',
  name: 'Get Groups',
  method: 'GET',
  path: '/api/v1/groups',
  category: 'groups',
  userType: 'both',
  description: 'Get all groups for current user',
  queryParams: [
    { name: 'owner_id', type: 'number', required: false, description: 'Filter by owner ID', default: null },
    { name: 'limit', type: 'number', required: false, description: 'Max number of results', default: 50 },
    { name: 'offset', type: 'number', required: false, description: 'Pagination offset', default: 0 },
    { name: 'order_by', type: 'string', required: false, description: 'Order by field', default: 'id' },
    { name: 'order_dir', type: 'string', required: false, description: 'Order direction', default: 'asc' },
  ],
};
