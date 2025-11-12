import { Endpoint } from '../index';

export const updateCalendar: Endpoint = {
  id: 'update-calendar',
  name: 'Update Calendar',
  method: 'PUT',
  path: '/api/v1/calendars/:calendar_id',
  category: 'calendars',
  userType: 'both',
  description: 'Update an existing calendar',
  pathParams: [
    { name: 'calendar_id', type: 'number', required: true, description: 'Calendar ID', example: 1 },
  ],
  bodyParams: [
    { name: 'name', type: 'string', required: true, description: 'Calendar name' },
    { name: 'description', type: 'string', required: false, description: 'Calendar description', default: null },
    { name: 'is_public', type: 'boolean', required: false, description: 'Is public calendar', default: false },
    { name: 'is_discoverable', type: 'boolean', required: false, description: 'Is discoverable', default: null },
    { name: 'share_hash', type: 'string', required: false, description: 'Share hash', default: null },
  ],
};
