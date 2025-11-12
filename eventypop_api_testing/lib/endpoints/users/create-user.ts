import { Endpoint } from '../index';

export const createUser: Endpoint = {
  id: 'create-user',
  name: 'Create User',
  method: 'POST',
  path: '/api/v1/users',
  category: 'users',
  userType: 'both',
  description: 'Create a new user',
  bodyParams: [
    { name: 'display_name', type: 'string', required: true, description: 'Display name' },
    { name: 'phone', type: 'string', required: false, description: 'Phone number', default: null },
    { name: 'instagram_username', type: 'string', required: false, description: 'Instagram username', default: null },
    { name: 'profile_picture_url', type: 'string', required: false, description: 'Profile picture URL', default: null },
    { name: 'auth_provider', type: 'string', required: true, description: 'Auth provider (supabase, etc.)' },
    { name: 'auth_id', type: 'string', required: true, description: 'Auth ID from provider' },
    { name: 'is_public', type: 'boolean', required: false, description: 'Is public user', default: false },
    { name: 'is_admin', type: 'boolean', required: false, description: 'Is admin', default: false },
  ],
};
