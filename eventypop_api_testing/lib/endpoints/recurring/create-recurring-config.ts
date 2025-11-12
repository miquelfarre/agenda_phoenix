import { Endpoint } from '../index';

export const createRecurringConfig: Endpoint = {
  id: 'create-recurring-config',
  name: 'Create Recurring Config',
  method: 'POST',
  path: '/api/v1/recurring-configs',
  category: 'recurring',
  userType: 'both',
  description: 'Create a recurring event configuration',
  bodyParams: [
    { name: 'parent_event_id', type: 'number', required: true, description: 'Parent recurring event ID' },
    { name: 'frequency', type: 'string', required: true, description: 'Frequency: daily, weekly, monthly, yearly' },
    { name: 'interval', type: 'number', required: false, description: 'Interval between occurrences', default: 1 },
    { name: 'until_date', type: 'date', required: false, description: 'End date (ISO format)', default: null },
    { name: 'count', type: 'number', required: false, description: 'Number of occurrences', default: null },
  ],
};
