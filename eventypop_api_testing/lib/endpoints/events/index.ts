import { Endpoint } from '../index';

// Import individual endpoints
import { getEvents } from './get-events';
import { createEvent } from './create-event';
import { updateEvent } from './update-event';
import { deleteEvent } from './delete-event';
import { getEventInteractions } from './get-event-interactions';
import { getEventInteractionsEnriched } from './get-event-interactions-enriched';
import { getAvailableInvitees } from './get-available-invitees';
import { getCurrentUserInteraction } from './get-current-user-interaction';
import { updateCurrentUserInteraction } from './update-current-user-interaction';
import { deleteCurrentUserInteraction } from './delete-current-user-interaction';
import { inviteUserToEvent } from './invite-user-to-event';

// Export all event endpoints
export const EVENT_ENDPOINTS: Endpoint[] = [
  getEvents,
  createEvent,
  updateEvent,
  deleteEvent,
  getEventInteractions,
  getEventInteractionsEnriched,
  getAvailableInvitees,
  getCurrentUserInteraction,
  updateCurrentUserInteraction,
  deleteCurrentUserInteraction,
  inviteUserToEvent,
];
