import { Endpoint } from '../index';

export const leaveGroup: Endpoint = {
  id: 'leave-group',
  name: 'Leave Group',
  method: 'DELETE',
  path: '/api/v1/groups/:group_id/leave',
  category: 'groups',
  userType: 'both',
  description: 'Leave a group (current user)',
  pathParams: [
    { name: 'group_id', type: 'number', required: true, description: 'Group ID', example: 1 },
  ],
};
