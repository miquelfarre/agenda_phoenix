import { Endpoint } from '../index';

export const getEvents: Endpoint = {
  id: 'get-events',
  name: 'Get Events',
  method: 'GET',
  path: '/api/v1/events',
  category: 'events',
  userType: 'both',
  description: 'Get all events with optional filters',
  queryParams: [
    { name: 'owner_id', type: 'number', required: false, description: 'Filter by owner user ID', default: null },
    { name: 'calendar_id', type: 'number', required: false, description: 'Filter by calendar ID', default: null },
    { name: 'limit', type: 'number', required: false, description: 'Max number of results', default: 50 },
    { name: 'offset', type: 'number', required: false, description: 'Pagination offset', default: 0 },
    { name: 'order_by', type: 'string', required: false, description: 'Order by field', default: 'start_date' },
    { name: 'order_dir', type: 'string', required: false, description: 'Order direction: asc or desc', default: 'asc' },
  ],
};
