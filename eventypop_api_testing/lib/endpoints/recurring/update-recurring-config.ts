import { Endpoint } from '../index';

export const updateRecurringConfig: Endpoint = {
  id: 'update-recurring-config',
  name: 'Update Recurring Config',
  method: 'PUT',
  path: '/api/v1/recurring-configs/:config_id',
  category: 'recurring',
  userType: 'both',
  description: 'Update a recurring event configuration',
  pathParams: [
    { name: 'config_id', type: 'number', required: true, description: 'Config ID', example: 1 },
  ],
  bodyParams: [
    { name: 'frequency', type: 'string', required: true, description: 'Frequency: daily, weekly, monthly, yearly' },
    { name: 'interval', type: 'number', required: false, description: 'Interval between occurrences', default: 1 },
    { name: 'until_date', type: 'date', required: false, description: 'End date (ISO format)', default: null },
    { name: 'count', type: 'number', required: false, description: 'Number of occurrences', default: null },
  ],
};
