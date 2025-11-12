import { Endpoint } from '../index';

export const createUserBlock: Endpoint = {
  id: 'create-user-block',
  name: 'Block User',
  method: 'POST',
  path: '/api/v1/user_blocks',
  category: 'users',
  userType: 'both',
  description: 'Block a user',
  bodyParams: [
    { name: 'blocked_user_id', type: 'number', required: true, description: 'User ID to block' },
    { name: 'reason', type: 'string', required: false, description: 'Block reason', default: null },
  ],
};
