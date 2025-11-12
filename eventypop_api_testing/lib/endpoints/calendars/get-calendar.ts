import { Endpoint } from '../index';

export const getCalendar: Endpoint = {
  id: 'get-calendar',
  name: 'Get Calendar',
  method: 'GET',
  path: '/api/v1/calendars/:calendar_id',
  category: 'calendars',
  userType: 'both',
  description: 'Get calendar details by ID',
  pathParams: [
    { name: 'calendar_id', type: 'number', required: true, description: 'Calendar ID', example: 1 },
  ],
};
