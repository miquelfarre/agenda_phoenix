import { Endpoint } from '../index';

export const markInteractionAsRead: Endpoint = {
  id: 'mark-interaction-as-read',
  name: 'Mark Interaction as Read',
  method: 'POST',
  path: '/api/v1/interactions/:interaction_id/mark-read',
  category: 'interactions',
  userType: 'both',
  description: 'Mark an interaction as read',
  pathParams: [
    { name: 'interaction_id', type: 'number', required: true, description: 'Interaction ID', example: 1 },
  ],
};
