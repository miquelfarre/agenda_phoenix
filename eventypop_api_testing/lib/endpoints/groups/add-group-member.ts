import { Endpoint } from '../index';

export const addGroupMember: Endpoint = {
  id: 'add-group-member',
  name: 'Add Group Member',
  method: 'POST',
  path: '/api/v1/groups/:group_id/members',
  category: 'groups',
  userType: 'both',
  description: 'Add a member to a group',
  pathParams: [
    { name: 'group_id', type: 'number', required: true, description: 'Group ID', example: 1 },
  ],
  bodyParams: [
    { name: 'user_id', type: 'number', required: true, description: 'User ID to add' },
    { name: 'role', type: 'string', required: false, description: 'Role: admin or member', default: 'member' },
  ],
};
