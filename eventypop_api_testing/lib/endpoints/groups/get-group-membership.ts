import { Endpoint } from '../index';

export const getGroupMembership: Endpoint = {
  id: 'get-group-membership',
  name: 'Get Group Membership',
  method: 'GET',
  path: '/api/v1/group-memberships/:membership_id',
  category: 'groups',
  userType: 'both',
  description: 'Get group membership details by ID',
  pathParams: [
    { name: 'membership_id', type: 'number', required: true, description: 'Membership ID', example: 1 },
  ],
};
