import { Endpoint } from '../index';

export const getCalendarMembership: Endpoint = {
  id: 'get-calendar-membership',
  name: 'Get Calendar Membership',
  method: 'GET',
  path: '/api/v1/calendar-memberships/:membership_id',
  category: 'calendars',
  userType: 'both',
  description: 'Get calendar membership details by ID',
  pathParams: [
    { name: 'membership_id', type: 'number', required: true, description: 'Membership ID', example: 1 },
  ],
};
