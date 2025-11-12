import { Endpoint } from '../index';

export const createCalendarMembership: Endpoint = {
  id: 'create-calendar-membership',
  name: 'Create Calendar Membership',
  method: 'POST',
  path: '/api/v1/calendar-memberships',
  category: 'calendars',
  userType: 'both',
  description: 'Create a new calendar membership',
  bodyParams: [
    { name: 'calendar_id', type: 'number', required: true, description: 'Calendar ID' },
    { name: 'user_id', type: 'number', required: true, description: 'User ID' },
    { name: 'role', type: 'string', required: false, description: 'Role: owner, admin, or member', default: 'member' },
  ],
};
