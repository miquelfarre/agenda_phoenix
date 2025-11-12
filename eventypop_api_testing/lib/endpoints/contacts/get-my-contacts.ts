import { Endpoint } from '../index';

export const getMyContacts: Endpoint = {
  id: 'get-my-contacts',
  name: 'Get My Contacts',
  method: 'GET',
  path: '/api/v1/contacts',
  category: 'contacts',
  userType: 'private',
  description: 'Get current user\'s contacts',
};
