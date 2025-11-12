import { Endpoint } from '../index';

export const deleteRecurringConfig: Endpoint = {
  id: 'delete-recurring-config',
  name: 'Delete Recurring Config',
  method: 'DELETE',
  path: '/api/v1/recurring-configs/:config_id',
  category: 'recurring',
  userType: 'both',
  description: 'Delete a recurring event configuration',
  pathParams: [
    { name: 'config_id', type: 'number', required: true, description: 'Config ID', example: 1 },
  ],
};
