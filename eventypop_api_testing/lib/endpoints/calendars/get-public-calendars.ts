import { Endpoint } from '../index';

export const getPublicCalendars: Endpoint = {
  id: 'get-public-calendars',
  name: 'Get Public Calendars',
  method: 'GET',
  path: '/api/v1/calendars/public',
  category: 'calendars',
  userType: 'both',
  description: 'Get all public calendars',
  queryParams: [
    { name: 'category', type: 'string', required: false, description: 'Filter by category', default: null },
    { name: 'search', type: 'string', required: false, description: 'Search by name', default: null },
    { name: 'limit', type: 'number', required: false, description: 'Max number of results', default: 50 },
    { name: 'offset', type: 'number', required: false, description: 'Pagination offset', default: 0 },
  ],
};
