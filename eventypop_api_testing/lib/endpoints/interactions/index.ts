import { Endpoint } from '../index';

// Import individual endpoints
import { getInteractions } from './get-interactions';
import { getInteraction } from './get-interaction';
import { createInteraction } from './create-interaction';
import { patchInteraction } from './patch-interaction';
import { deleteInteraction } from './delete-interaction';
import { markInteractionAsRead } from './mark-interaction-as-read';

// Export all interaction endpoints
export const INTERACTION_ENDPOINTS: Endpoint[] = [
  getInteractions,
  getInteraction,
  createInteraction,
  patchInteraction,
  deleteInteraction,
  markInteractionAsRead,
];
