import { Endpoint } from '../index';

export const deleteCalendarMembership: Endpoint = {
  id: 'delete-calendar-membership',
  name: 'Delete Calendar Membership',
  method: 'DELETE',
  path: '/api/v1/calendar-memberships/:membership_id',
  category: 'calendars',
  userType: 'both',
  description: 'Remove a calendar membership',
  pathParams: [
    { name: 'membership_id', type: 'number', required: true, description: 'Membership ID', example: 1 },
  ],
};
