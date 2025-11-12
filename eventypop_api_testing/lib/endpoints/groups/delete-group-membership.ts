import { Endpoint } from '../index';

export const deleteGroupMembership: Endpoint = {
  id: 'delete-group-membership',
  name: 'Delete Group Membership',
  method: 'DELETE',
  path: '/api/v1/group_memberships/:membership_id',
  category: 'groups',
  userType: 'both',
  description: 'Remove a group membership',
  pathParams: [
    { name: 'membership_id', type: 'number', required: true, description: 'Membership ID', example: 1 },
  ],
};
