import { Endpoint } from '../index';

// Import individual endpoints
import { getEvents } from './get-events';
import { getEvent } from './get-event';
import { createEvent } from './create-event';
import { updateEvent } from './update-event';
import { deleteEvent } from './delete-event';
// removed event interactions listing endpoints (not exposed)
import { getAvailableInvitees } from './get-available-invitees';

// Export all event endpoints
export const EVENT_ENDPOINTS: Endpoint[] = [
  getEvents,
  getEvent,
  createEvent,
  updateEvent,
  deleteEvent,
  getAvailableInvitees,
];
