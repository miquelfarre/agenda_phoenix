import { Endpoint } from '../index';

export const getEventInteractionsEnriched: Endpoint = {
  id: 'get-event-interactions-enriched',
  name: 'Get Event Interactions (Enriched)',
  method: 'GET',
  path: '/api/v1/events/:event_id/interactions-enriched',
  category: 'events',
  userType: 'both',
  description: 'Get all interactions for an event with user information',
  pathParams: [
    { name: 'event_id', type: 'number', required: true, description: 'Event ID', example: 1 },
  ],
};
