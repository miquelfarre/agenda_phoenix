import { Endpoint } from '../index';

export const markCancellationAsViewed: Endpoint = {
  id: 'mark-cancellation-as-viewed',
  name: 'Mark Cancellation as Viewed',
  method: 'POST',
  path: '/api/v1/events/cancellations/:cancellation_id/view',
  category: 'events',
  userType: 'both',
  description: 'Mark an event cancellation as viewed',
  pathParams: [
    { name: 'cancellation_id', type: 'number', required: true, description: 'Cancellation ID', example: 1 },
  ],
};
