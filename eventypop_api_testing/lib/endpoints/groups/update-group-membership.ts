import { Endpoint } from '../index';

export const updateGroupMembership: Endpoint = {
  id: 'update-group-membership',
  name: 'Update Group Membership',
  method: 'PUT',
  path: '/api/v1/group_memberships/:membership_id',
  category: 'groups',
  userType: 'both',
  description: 'Update a group membership role',
  pathParams: [
    { name: 'membership_id', type: 'number', required: true, description: 'Membership ID', example: 1 },
  ],
  bodyParams: [
    { name: 'role', type: 'string', required: true, description: 'Role: admin or member' },
  ],
};
