import { Endpoint } from '../index';

// Import individual endpoints
import { getGroups } from './get-groups';
import { createGroup } from './create-group';
import { updateGroup } from './update-group';
import { deleteGroup } from './delete-group';
import { getGroupMemberships } from './get-group-memberships';
import { createGroupMembership } from './create-group-membership';
import { updateGroupMembership } from './update-group-membership';
import { deleteGroupMembership } from './delete-group-membership';

// Export all group endpoints
export const GROUP_ENDPOINTS: Endpoint[] = [
  getGroups,
  createGroup,
  updateGroup,
  deleteGroup,
  getGroupMemberships,
  createGroupMembership,
  updateGroupMembership,
  deleteGroupMembership,
];
