import { Endpoint } from '../index';

export const createGroup: Endpoint = {
  id: 'create-group',
  name: 'Create Group',
  method: 'POST',
  path: '/api/v1/groups',
  category: 'groups',
  userType: 'both',
  description: 'Create a new group',
  bodyParams: [
    { name: 'name', type: 'string', required: true, description: 'Group name' },
    { name: 'description', type: 'string', required: false, description: 'Group description', default: null },
  ],
};
