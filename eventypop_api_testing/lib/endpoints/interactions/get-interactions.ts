import { Endpoint } from '../index';

export const getInteractions: Endpoint = {
  id: 'get-interactions',
  name: 'Get Interactions',
  method: 'GET',
  path: '/api/v1/interactions',
  category: 'interactions',
  userType: 'both',
  description: 'Get all interactions',
  queryParams: [
    { name: 'enriched', type: 'boolean', required: false, description: 'Include event information', default: false },
  ],
};
