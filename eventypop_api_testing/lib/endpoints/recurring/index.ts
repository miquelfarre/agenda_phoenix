import { Endpoint } from '../index';

// Import individual endpoints
import { getRecurringConfigs } from './get-recurring-configs';
import { getRecurringConfig } from './get-recurring-config';
import { createRecurringConfig } from './create-recurring-config';
import { updateRecurringConfig } from './update-recurring-config';
import { deleteRecurringConfig } from './delete-recurring-config';

// Export all recurring endpoints
export const RECURRING_ENDPOINTS: Endpoint[] = [
  getRecurringConfigs,
  getRecurringConfig,
  createRecurringConfig,
  updateRecurringConfig,
  deleteRecurringConfig,
];
