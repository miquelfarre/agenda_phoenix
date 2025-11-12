import { Endpoint } from '../index';

export const updateCalendarMembership: Endpoint = {
  id: 'update-calendar-membership',
  name: 'Update Calendar Membership',
  method: 'PUT',
  path: '/api/v1/calendar-memberships/:membership_id',
  category: 'calendars',
  userType: 'both',
  description: 'Update a calendar membership role',
  pathParams: [
    { name: 'membership_id', type: 'number', required: true, description: 'Membership ID', example: 1 },
  ],
  bodyParams: [
    { name: 'role', type: 'string', required: true, description: 'Role: owner, admin, or member' },
  ],
};
