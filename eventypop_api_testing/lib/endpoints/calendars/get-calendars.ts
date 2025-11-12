import { Endpoint } from '../index';

export const getCalendars: Endpoint = {
  id: 'get-calendars',
  name: 'Get Calendars',
  method: 'GET',
  path: '/api/v1/calendars',
  category: 'calendars',
  userType: 'both',
  description: 'Get all calendars for current user',
  queryParams: [
    { name: 'limit', type: 'number', required: false, description: 'Max number of results', default: 50 },
    { name: 'offset', type: 'number', required: false, description: 'Pagination offset', default: 0 },
  ],
};
