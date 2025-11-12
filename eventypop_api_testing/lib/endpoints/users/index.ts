import { Endpoint } from '../index';

// Import individual endpoints
import { getUsers } from './get-users';
import { getCurrentUser } from './get-current-user';
import { getUser } from './get-user';
import { getUserStats } from './get-user-stats';
import { createUser } from './create-user';
import { updateUser } from './update-user';
import { deleteUser } from './delete-user';
import { getUserEvents } from './get-user-events';
import { subscribeToUser } from './subscribe-to-user';
import { unsubscribeFromUser } from './unsubscribe-from-user';
import { getUserSubscriptions } from './get-user-subscriptions';
import { getAccessibleCalendarIds } from './get-accessible-calendar-ids';
import { getUserBlocks } from './get-user-blocks';
import { getUserBlock } from './get-user-block';
import { createUserBlock } from './create-user-block';
import { deleteUserBlock } from './delete-user-block';

// Export all user endpoints
export const USER_ENDPOINTS: Endpoint[] = [
  getUsers,
  getCurrentUser,
  getUser,
  getUserStats,
  createUser,
  updateUser,
  deleteUser,
  getUserEvents,
  subscribeToUser,
  unsubscribeFromUser,
  getUserSubscriptions,
  getAccessibleCalendarIds,
  getUserBlocks,
  getUserBlock,
  createUserBlock,
  deleteUserBlock,
];
