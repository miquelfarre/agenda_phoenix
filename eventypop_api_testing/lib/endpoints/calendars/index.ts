import { Endpoint } from '../index';

// Import individual endpoints
import { getCalendars } from './get-calendars';
import { getPublicCalendars } from './get-public-calendars';
import { getCalendarByShareHash } from './get-calendar-by-share-hash';
import { getCalendar } from './get-calendar';
import { createCalendar } from './create-calendar';
import { updateCalendar } from './update-calendar';
import { deleteCalendar } from './delete-calendar';
import { getCalendarMembers } from './get-calendar-members';
import { addCalendarMember } from './add-calendar-member';
import { subscribeToCalendar } from './subscribe-to-calendar';
import { unsubscribeFromCalendar } from './unsubscribe-from-calendar';
import { getCalendarMemberships } from './get-calendar-memberships';
import { getCalendarMembership } from './get-calendar-membership';
import { createCalendarMembership } from './create-calendar-membership';
import { updateCalendarMembership } from './update-calendar-membership';
import { deleteCalendarMembership } from './delete-calendar-membership';

// Export all calendar endpoints
export const CALENDAR_ENDPOINTS: Endpoint[] = [
  getCalendars,
  getPublicCalendars,
  getCalendarByShareHash,
  getCalendar,
  createCalendar,
  updateCalendar,
  deleteCalendar,
  getCalendarMembers,
  addCalendarMember,
  subscribeToCalendar,
  unsubscribeFromCalendar,
  getCalendarMemberships,
  getCalendarMembership,
  createCalendarMembership,
  updateCalendarMembership,
  deleteCalendarMembership,
];
