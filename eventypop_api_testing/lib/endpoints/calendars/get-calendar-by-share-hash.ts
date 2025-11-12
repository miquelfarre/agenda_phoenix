import { Endpoint } from '../index';

export const getCalendarByShareHash: Endpoint = {
  id: 'get-calendar-by-share-hash',
  name: 'Get Calendar by Share Hash',
  method: 'GET',
  path: '/api/v1/calendars/share/:share_hash',
  category: 'calendars',
  userType: 'both',
  description: 'Get calendar details by share hash',
  pathParams: [
    { name: 'share_hash', type: 'string', required: true, description: 'Share hash', example: 'abc123' },
  ],
};
