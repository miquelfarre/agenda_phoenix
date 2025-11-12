import { Endpoint } from '../index';

// Import individual endpoints
import { getRecurringConfigs } from './get-recurring-configs';

// Export all recurring endpoints
export const RECURRING_ENDPOINTS: Endpoint[] = [
  getRecurringConfigs,
];
