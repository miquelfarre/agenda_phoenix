import { Endpoint } from '../index';

export const getGroupMemberships: Endpoint = {
  id: 'get-group-memberships',
  name: 'Get Group Memberships',
  method: 'GET',
  path: '/api/v1/group-memberships',
  category: 'groups',
  userType: 'both',
  description: 'Get all group memberships',
  queryParams: [
    { name: 'group_id', type: 'number', required: false, description: 'Filter by group ID', default: null },
    { name: 'user_id', type: 'number', required: false, description: 'Filter by user ID', default: null },
    { name: 'limit', type: 'number', required: false, description: 'Max number of results', default: 50 },
    { name: 'offset', type: 'number', required: false, description: 'Pagination offset', default: 0 },
  ],
};
