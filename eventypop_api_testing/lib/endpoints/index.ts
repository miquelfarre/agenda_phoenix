// Shared types
export interface EndpointParam {
  name: string;
  type: 'string' | 'number' | 'boolean' | 'date' | 'array';
  required: boolean;
  description?: string;
  example?: any;
  default?: any;
}

export interface Endpoint {
  id: string;
  name: string;
  method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  path: string;
  category: string;
  userType: 'private' | 'public' | 'both';
  description: string;
  pathParams?: EndpointParam[];
  queryParams?: EndpointParam[];
  bodyParams?: EndpointParam[];
}

export const ENDPOINT_CATEGORIES = [
  { id: 'users', name: 'Users', icon: '👤' },
  { id: 'events', name: 'Events', icon: '📅' },
  { id: 'calendars', name: 'Calendars', icon: '🗓️' },
  { id: 'groups', name: 'Groups', icon: '👥' },
  { id: 'contacts', name: 'Contacts', icon: '📇' },
  { id: 'interactions', name: 'Interactions', icon: '🔔' },
];

// Import all endpoints from category modules
import { USER_ENDPOINTS } from './users';
import { EVENT_ENDPOINTS } from './events';
import { CALENDAR_ENDPOINTS } from './calendars';
import { GROUP_ENDPOINTS } from './groups';
import { CONTACT_ENDPOINTS } from './contacts';
import { INTERACTION_ENDPOINTS } from './interactions';

// Combine all endpoints
export const ENDPOINTS: Endpoint[] = [
  ...USER_ENDPOINTS,
  ...EVENT_ENDPOINTS,
  ...CALENDAR_ENDPOINTS,
  ...GROUP_ENDPOINTS,
  ...CONTACT_ENDPOINTS,
  ...INTERACTION_ENDPOINTS,
];
