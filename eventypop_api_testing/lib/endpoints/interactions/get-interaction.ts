import { Endpoint } from '../index';

export const getInteraction: Endpoint = {
  id: 'get-interaction',
  name: 'Get Interaction',
  method: 'GET',
  path: '/api/v1/interactions/:interaction_id',
  category: 'interactions',
  userType: 'both',
  description: 'Get interaction details by ID',
  pathParams: [
    { name: 'interaction_id', type: 'number', required: true, description: 'Interaction ID', example: 1 },
  ],
};
