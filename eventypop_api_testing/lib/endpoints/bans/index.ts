import { Endpoint } from '../index';

// Import individual endpoints
import { getEventBans } from './get-event-bans';

// Export all ban endpoints
export const BAN_ENDPOINTS: Endpoint[] = [
  getEventBans,
];
