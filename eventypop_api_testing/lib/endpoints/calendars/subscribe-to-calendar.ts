import { Endpoint } from '../index';

export const subscribeToCalendar: Endpoint = {
  id: 'subscribe-to-calendar',
  name: 'Subscribe to Calendar',
  method: 'POST',
  path: '/api/v1/calendars/:share_hash/subscribe',
  category: 'calendars',
  userType: 'private',
  description: 'Subscribe to a public calendar by share hash',
  pathParams: [
    { name: 'share_hash', type: 'string', required: true, description: 'Calendar share hash', example: 'abc123' },
  ],
};
