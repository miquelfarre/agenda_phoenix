import { Endpoint } from '../index';

export const getEventBan: Endpoint = {
  id: 'get-event-ban',
  name: 'Get Event Ban',
  method: 'GET',
  path: '/api/v1/event-bans/:ban_id',
  category: 'bans',
  userType: 'both',
  description: 'Get event ban details by ID',
  pathParams: [
    { name: 'ban_id', type: 'number', required: true, description: 'Ban ID', example: 1 },
  ],
};
