import { Endpoint } from '../index';

export const unsubscribeFromCalendar: Endpoint = {
  id: 'unsubscribe-from-calendar',
  name: 'Unsubscribe from Calendar',
  method: 'DELETE',
  path: '/api/v1/calendars/:share_hash/subscribe',
  category: 'calendars',
  userType: 'private',
  description: 'Unsubscribe from a public calendar',
  pathParams: [
    { name: 'share_hash', type: 'string', required: true, description: 'Calendar share hash', example: 'abc123' },
  ],
};
