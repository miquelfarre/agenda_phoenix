import { Endpoint } from '../index';

// Import individual endpoints
import { getCalendars } from './get-calendars';
import { getCalendarByShareHash } from './get-calendar-by-share-hash';
import { createCalendar } from './create-calendar';
import { updateCalendar } from './update-calendar';
import { deleteCalendar } from './delete-calendar';
import { getCalendarMembers } from './get-calendar-members';
import { addCalendarMember } from './add-calendar-member';
import { subscribeToCalendar } from './subscribe-to-calendar';
import { unsubscribeFromCalendar } from './unsubscribe-from-calendar';
import { deleteCalendarMembership } from './delete-calendar-membership';

// Export all calendar endpoints
export const CALENDAR_ENDPOINTS: Endpoint[] = [
  getCalendars,
  getCalendarByShareHash,
  createCalendar,
  updateCalendar,
  deleteCalendar,
  getCalendarMembers,
  addCalendarMember,
  subscribeToCalendar,
  unsubscribeFromCalendar,
  deleteCalendarMembership,
];
