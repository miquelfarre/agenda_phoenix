import { Endpoint } from '../index';

// Import individual endpoints
import { getUsers } from './get-users';
import { getUser } from './get-user';
import { updateUser } from './update-user';
import { getUserEvents } from './get-user-events';
import { subscribeToUser } from './subscribe-to-user';
import { unsubscribeFromUser } from './unsubscribe-from-user';
import { getUserSubscriptions } from './get-user-subscriptions';
import { getUserBlocks } from './get-user-blocks';
import { createUserBlock } from './create-user-block';
import { deleteUserBlock } from './delete-user-block';

// Export all user endpoints
export const USER_ENDPOINTS: Endpoint[] = [
  getUsers,
  getUser,
  updateUser,
  getUserEvents,
  subscribeToUser,
  unsubscribeFromUser,
  getUserSubscriptions,
  getUserBlocks,
  createUserBlock,
  deleteUserBlock,
];
