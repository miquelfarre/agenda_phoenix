import { Endpoint } from '../index';

export const patchInteraction: Endpoint = {
  id: 'patch-interaction',
  name: 'Patch Interaction',
  method: 'PATCH',
  path: '/api/v1/interactions/:interaction_id',
  category: 'interactions',
  userType: 'both',
  description: 'Update an interaction',
  pathParams: [
    { name: 'interaction_id', type: 'number', required: true, description: 'Interaction ID', example: 1 },
  ],
  bodyParams: [
    { name: 'status', type: 'string', required: false, description: 'Status: pending, accepted, rejected', default: null },
    { name: 'is_attending', type: 'boolean', required: false, description: 'Is attending', default: null },
    { name: 'personal_note', type: 'string', required: false, description: 'Personal note', default: null },
  ],
};
