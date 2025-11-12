import { Endpoint } from '../index';

// Import individual endpoints
import { getEventBans } from './get-event-bans';
import { getEventBan } from './get-event-ban';
import { createEventBan } from './create-event-ban';
import { deleteEventBan } from './delete-event-ban';

// Export all ban endpoints
export const BAN_ENDPOINTS: Endpoint[] = [
  getEventBans,
  getEventBan,
  createEventBan,
  deleteEventBan,
];
