import { Endpoint } from '../index';

export const createGroupMembership: Endpoint = {
  id: 'create-group-membership',
  name: 'Create Group Membership',
  method: 'POST',
  path: '/api/v1/group-memberships',
  category: 'groups',
  userType: 'both',
  description: 'Create a new group membership',
  bodyParams: [
    { name: 'group_id', type: 'number', required: true, description: 'Group ID' },
    { name: 'user_id', type: 'number', required: true, description: 'User ID' },
    { name: 'role', type: 'string', required: false, description: 'Role: admin or member', default: 'member' },
  ],
};
