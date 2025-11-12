import { Endpoint } from '../index';

export const createInteraction: Endpoint = {
  id: 'create-interaction',
  name: 'Create Interaction',
  method: 'POST',
  path: '/api/v1/interactions',
  category: 'interactions',
  userType: 'both',
  description: 'Create a new interaction',
  bodyParams: [
    { name: 'event_id', type: 'number', required: true, description: 'Event ID' },
    { name: 'user_id', type: 'number', required: true, description: 'User ID' },
    { name: 'interaction_type', type: 'string', required: true, description: 'Type: invited, joined, requested, subscribed' },
    { name: 'status', type: 'string', required: false, description: 'Status: pending, accepted, rejected', default: 'pending' },
    { name: 'role', type: 'string', required: false, description: 'Role: admin, member', default: null },
    { name: 'invited_by_user_id', type: 'number', required: false, description: 'User ID who invited', default: null },
  ],
};
