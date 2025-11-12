import { Endpoint } from '../index';

export const deleteEventBan: Endpoint = {
  id: 'delete-event-ban',
  name: 'Delete Event Ban',
  method: 'DELETE',
  path: '/api/v1/event-bans/:ban_id',
  category: 'bans',
  userType: 'both',
  description: 'Remove an event ban',
  pathParams: [
    { name: 'ban_id', type: 'number', required: true, description: 'Ban ID', example: 1 },
  ],
};
