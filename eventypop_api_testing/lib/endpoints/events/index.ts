import { Endpoint } from '../index';

// Import individual endpoints
import { getEvents } from './get-events';
import { getEvent } from './get-event';
import { createEvent } from './create-event';
import { updateEvent } from './update-event';
import { deleteEvent } from './delete-event';
// removed event interactions listing endpoints (not exposed)
import { getAvailableInvitees } from './get-available-invitees';
import { getCurrentUserInteraction } from './get-current-user-interaction';
import { updateCurrentUserInteraction } from './update-current-user-interaction';
import { deleteCurrentUserInteraction } from './delete-current-user-interaction';
import { inviteUserToEvent } from './invite-user-to-event';

// Export all event endpoints
export const EVENT_ENDPOINTS: Endpoint[] = [
  getEvents,
  getEvent,
  createEvent,
  updateEvent,
  deleteEvent,
  getAvailableInvitees,
  getCurrentUserInteraction,
  updateCurrentUserInteraction,
  deleteCurrentUserInteraction,
  inviteUserToEvent,
];
