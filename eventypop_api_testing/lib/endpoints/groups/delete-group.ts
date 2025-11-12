import { Endpoint } from '../index';

export const deleteGroup: Endpoint = {
  id: 'delete-group',
  name: 'Delete Group',
  method: 'DELETE',
  path: '/api/v1/groups/:group_id',
  category: 'groups',
  userType: 'both',
  description: 'Delete a group',
  pathParams: [
    { name: 'group_id', type: 'number', required: true, description: 'Group ID', example: 1 },
  ],
};
