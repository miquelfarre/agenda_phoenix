import { Endpoint } from '../index';

export const getEventCancellations: Endpoint = {
  id: 'get-event-cancellations',
  name: 'Get Event Cancellations',
  method: 'GET',
  path: '/api/v1/events/cancellations',
  category: 'events',
  userType: 'both',
  description: 'Get event cancellations for current user',
};
