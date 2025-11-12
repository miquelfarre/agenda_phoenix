import { Endpoint } from '../index';

export const updateGroup: Endpoint = {
  id: 'update-group',
  name: 'Update Group',
  method: 'PUT',
  path: '/api/v1/groups/:group_id',
  category: 'groups',
  userType: 'both',
  description: 'Update an existing group',
  pathParams: [
    { name: 'group_id', type: 'number', required: true, description: 'Group ID', example: 1 },
  ],
  bodyParams: [
    { name: 'name', type: 'string', required: true, description: 'Group name' },
    { name: 'description', type: 'string', required: false, description: 'Group description', default: null },
  ],
};
