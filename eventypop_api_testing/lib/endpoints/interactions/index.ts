import { Endpoint } from '../index';

// Import individual endpoints
import { getInteractions } from './get-interactions';
import { createInteraction } from './create-interaction';
import { patchInteraction } from './patch-interaction';
import { markInteractionAsRead } from './mark-interaction-as-read';

// Export all interaction endpoints
export const INTERACTION_ENDPOINTS: Endpoint[] = [
  getInteractions,
  createInteraction,
  patchInteraction,
  markInteractionAsRead,
];
