import { Endpoint } from '../index';

export const addCalendarMember: Endpoint = {
  id: 'add-calendar-member',
  name: 'Add Calendar Member',
  method: 'POST',
  path: '/api/v1/calendars/:calendar_id/memberships',
  category: 'calendars',
  userType: 'both',
  description: 'Add a member to a calendar',
  pathParams: [
    { name: 'calendar_id', type: 'number', required: true, description: 'Calendar ID', example: 1 },
  ],
  bodyParams: [
    { name: 'user_id', type: 'number', required: true, description: 'User ID to add' },
    { name: 'role', type: 'string', required: false, description: 'Role: owner, admin, or member', default: 'member' },
  ],
};
