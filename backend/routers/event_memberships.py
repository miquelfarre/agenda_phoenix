"""
Event Memberships Router

Handles all event membership endpoints.
"""

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user_id
from crud import event_membership
from dependencies import get_db
from schemas import EventMembershipBase, EventMembershipResponse, EventMembershipUpdate

router = APIRouter(prefix="/api/v1/event_memberships", tags=["event_memberships"])


def is_event_owner_or_admin(event_id: int, user_id: int, db: Session) -> bool:
    """
    Check if a user is the owner or admin of an event.

    Args:
        event_id: Event ID
        user_id: User ID to check
        db: Database session

    Returns:
        True if user is owner or admin, False otherwise
    """
    from crud import event

    # Get the event
    db_event = event.get(db, id=event_id)
    if not db_event:
        return False

    # Check if user is owner
    if db_event.owner_id == user_id:
        return True

    # Check if user is an admin membership
    membership = event_membership.get_by_event_and_user(db, event_id=event_id, user_id=user_id)
    if membership and membership.role == "admin" and membership.status == "accepted":
        return True

    return False


@router.patch("/{membership_id}", response_model=EventMembershipResponse)
async def patch_event_membership(
    membership_id: int,
    membership: EventMembershipUpdate,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Partially update an event membership (typically to change role or status).

    Requires JWT authentication - provide token in Authorization header.

    For role changes: Only event owners or admins can change roles (member <-> admin).
    For status changes: Only the user themselves can accept/reject invitations.
    """
    db_membership = event_membership.get(db, id=membership_id)
    if not db_membership:
        raise HTTPException(status_code=404, detail="Event membership not found")

    # Get update data
    update_data = membership.model_dump(exclude_unset=True)

    # Special validation for role changes
    if 'role' in update_data:
        # Check permissions (owner or admin)
        is_admin = is_event_owner_or_admin(
            db_membership.event_id,
            current_user_id,
            db
        )
        if not is_admin:
            raise HTTPException(
                status_code=403,
                detail="Only event owners or admins can change roles"
            )

        # Cannot change your own role
        if db_membership.user_id == current_user_id:
            raise HTTPException(
                status_code=403,
                detail="Cannot change your own role"
            )

        # Validate role
        new_role = update_data['role']
        if new_role not in ["member", "admin"]:
            raise HTTPException(
                status_code=400,
                detail="Role must be 'member' or 'admin'"
            )

    # For status changes, check if user is the membership user
    if 'status' in update_data and 'role' not in update_data:
        if db_membership.user_id != current_user_id:
            raise HTTPException(
                status_code=403,
                detail="You don't have permission to update this membership. Only the user themselves can accept/reject invitations."
            )

    # Update membership
    updated_membership = event_membership.update(
        db,
        db_obj=db_membership,
        obj_in=update_data
    )

    return updated_membership


@router.delete("/{membership_id}")
async def delete_event_membership(membership_id: int, current_user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """
    Remove a user from an event.

    Requires JWT authentication - provide token in Authorization header.
    Either the event owner/admin OR the user themselves can delete the membership.
    """
    db_membership = event_membership.get(db, id=membership_id)
    if not db_membership:
        raise HTTPException(status_code=404, detail="Event membership not found")

    # Check if user is event owner/admin OR the member themselves
    is_event_admin = is_event_owner_or_admin(db_membership.event_id, current_user_id, db)
    is_self = db_membership.user_id == current_user_id

    if not (is_event_admin or is_self):
        raise HTTPException(status_code=403, detail="You don't have permission to delete this membership. Only the event owner/admin or the member themselves can do this.")

    event_membership.delete(db, id=membership_id)
    return {"message": "Event membership deleted successfully", "id": membership_id}
