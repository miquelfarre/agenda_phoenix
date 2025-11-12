import { Endpoint } from '../index';

export const deleteInteraction: Endpoint = {
  id: 'delete-interaction',
  name: 'Delete Interaction',
  method: 'DELETE',
  path: '/api/v1/interactions/:interaction_id',
  category: 'interactions',
  userType: 'both',
  description: 'Delete an interaction',
  pathParams: [
    { name: 'interaction_id', type: 'number', required: true, description: 'Interaction ID', example: 1 },
  ],
};
