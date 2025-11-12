import { Endpoint } from '../index';

export const getRecurringConfig: Endpoint = {
  id: 'get-recurring-config',
  name: 'Get Recurring Config',
  method: 'GET',
  path: '/api/v1/recurring-configs/:config_id',
  category: 'recurring',
  userType: 'both',
  description: 'Get recurring config details by ID',
  pathParams: [
    { name: 'config_id', type: 'number', required: true, description: 'Config ID', example: 1 },
  ],
};
