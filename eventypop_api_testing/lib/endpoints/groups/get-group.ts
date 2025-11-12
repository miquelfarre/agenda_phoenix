import { Endpoint } from '../index';

export const getGroup: Endpoint = {
  id: 'get-group',
  name: 'Get Group',
  method: 'GET',
  path: '/api/v1/groups/:group_id',
  category: 'groups',
  userType: 'both',
  description: 'Get group details by ID',
  pathParams: [
    { name: 'group_id', type: 'number', required: true, description: 'Group ID', example: 1 },
  ],
};
