import { Endpoint } from '../index';

export const removeGroupMember: Endpoint = {
  id: 'remove-group-member',
  name: 'Remove Group Member',
  method: 'DELETE',
  path: '/api/v1/groups/:group_id/members/:user_id',
  category: 'groups',
  userType: 'both',
  description: 'Remove a member from a group',
  pathParams: [
    { name: 'group_id', type: 'number', required: true, description: 'Group ID', example: 1 },
    { name: 'user_id', type: 'number', required: true, description: 'User ID to remove', example: 2 },
  ],
};
