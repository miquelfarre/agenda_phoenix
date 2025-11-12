import { Endpoint } from '../index';

// Import individual endpoints
import { getGroups } from './get-groups';
import { getGroup } from './get-group';
import { createGroup } from './create-group';
import { updateGroup } from './update-group';
import { deleteGroup } from './delete-group';
import { addGroupMember } from './add-group-member';
import { removeGroupMember } from './remove-group-member';
import { leaveGroup } from './leave-group';
import { getGroupMemberships } from './get-group-memberships';
import { getGroupMembership } from './get-group-membership';
import { createGroupMembership } from './create-group-membership';
import { updateGroupMembership } from './update-group-membership';
import { deleteGroupMembership } from './delete-group-membership';

// Export all group endpoints
export const GROUP_ENDPOINTS: Endpoint[] = [
  getGroups,
  getGroup,
  createGroup,
  updateGroup,
  deleteGroup,
  addGroupMember,
  removeGroupMember,
  leaveGroup,
  getGroupMemberships,
  getGroupMembership,
  createGroupMembership,
  updateGroupMembership,
  deleteGroupMembership,
];
