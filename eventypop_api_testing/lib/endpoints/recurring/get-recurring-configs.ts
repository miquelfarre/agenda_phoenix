import { Endpoint } from '../index';

export const getRecurringConfigs: Endpoint = {
  id: 'get-recurring-configs',
  name: 'Get Recurring Configs',
  method: 'GET',
  path: '/api/v1/recurring-configs',
  category: 'recurring',
  userType: 'both',
  description: 'Get all recurring event configurations',
  queryParams: [
    { name: 'event_id', type: 'number', required: false, description: 'Filter by event ID', default: null },
    { name: 'limit', type: 'number', required: false, description: 'Max number of results', default: 50 },
    { name: 'offset', type: 'number', required: false, description: 'Pagination offset', default: 0 },
    { name: 'order_by', type: 'string', required: false, description: 'Order by field', default: 'id' },
    { name: 'order_dir', type: 'string', required: false, description: 'Order direction', default: 'asc' },
  ],
};
