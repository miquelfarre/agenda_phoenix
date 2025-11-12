import { Endpoint } from '../index';

// Import individual endpoints
import { syncContacts } from './sync-contacts';
import { getMyContacts } from './get-my-contacts';

// Export all contact endpoints
export const CONTACT_ENDPOINTS: Endpoint[] = [
  syncContacts,
  getMyContacts,
];
