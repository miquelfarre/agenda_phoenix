import { Endpoint } from '../index';

export const syncContacts: Endpoint = {
  id: 'sync-contacts',
  name: 'Sync Contacts',
  method: 'POST',
  path: '/api/v1/contacts/sync',
  category: 'contacts',
  userType: 'private',
  description: 'Sync user contacts with phone numbers',
  bodyParams: [
    { name: 'phone_numbers', type: 'array', required: true, description: 'Array of phone numbers to sync', example: ['+34600000001', '+34600000002'] },
  ],
};
