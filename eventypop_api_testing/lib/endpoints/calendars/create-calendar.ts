import { Endpoint } from '../index';

export const createCalendar: Endpoint = {
  id: 'create-calendar',
  name: 'Create Calendar',
  method: 'POST',
  path: '/api/v1/calendars',
  category: 'calendars',
  userType: 'both',
  description: 'Create a new calendar',
  bodyParams: [
    { name: 'name', type: 'string', required: true, description: 'Calendar name' },
    { name: 'description', type: 'string', required: false, description: 'Calendar description', default: null },
    { name: 'is_public', type: 'boolean', required: false, description: 'Is public calendar', default: false },
    { name: 'is_discoverable', type: 'boolean', required: false, description: 'Is discoverable in public calendars', default: null },
    { name: 'share_hash', type: 'string', required: false, description: 'Custom share hash', default: null },
  ],
};
