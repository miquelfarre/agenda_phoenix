"""
Groups Router

Handles all group-related endpoints.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user_id
from crud import group
from dependencies import check_group_permission, get_db
from models import Group
from schemas import GroupBase, GroupCreate, GroupMembershipCreate, GroupResponse

router = APIRouter(prefix="/api/v1/groups", tags=["groups"])


def _enrich_group_with_members(db: Session, db_group: Group) -> GroupResponse:
    """Enrich a group with owner, members, and admins"""
    from crud.crud_group_membership import group_membership

    # Get all memberships
    memberships = group_membership.get_by_group(db, group_id=db_group.id)

    # Separate members and admins
    members_list = []
    admins_list = []

    for membership in memberships:
        if membership.user:
            if membership.role == "admin":
                admins_list.append(membership.user)
            else:
                members_list.append(membership.user)

    # Create response with all data
    return GroupResponse(
        id=db_group.id,
        name=db_group.name,
        description=db_group.description,
        owner_id=db_group.owner_id,
        owner=db_group.owner,
        members=members_list,
        admins=admins_list,
        created_at=db_group.created_at,
        updated_at=db_group.updated_at
    )


@router.get("", response_model=List[GroupResponse])
async def get_groups(
    current_user_id: int = Depends(get_current_user_id),
    owner_id: Optional[int] = None,
    limit: int = 50,
    offset: int = 0,
    order_by: str = "id",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """
    Get groups where the authenticated user is a member (owner, admin, or member).

    Requires JWT authentication - provide token in Authorization header.

    Optionally filter by owner_id to get only groups owned by a specific user.
    """
    from crud.crud_group_membership import group_membership

    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    # Get all groups where user is a member (owner, admin, or member)
    memberships = group_membership.get_by_user(db, user_id=current_user_id)
    group_ids = [m.group_id for m in memberships]

    # If no memberships, return empty list
    if not group_ids:
        return []

    # Get groups by IDs
    groups = []
    for group_id in group_ids:
        db_group = group.get(db, id=group_id)
        if db_group:
            # Apply owner filter if specified
            if owner_id is not None and db_group.owner_id != owner_id:
                continue
            groups.append(db_group)

    # Sort groups (simple sort by id for now)
    if order_by == "id":
        groups.sort(key=lambda g: g.id, reverse=(order_dir == "desc"))

    # Apply pagination
    groups = groups[offset:offset + limit]

    # Enrich each group with members and admins
    return [_enrich_group_with_members(db, g) for g in groups]


@router.get("/{group_id}", response_model=GroupResponse)
async def get_group(group_id: int, db: Session = Depends(get_db)):
    """Get a single group by ID"""
    db_group = group.get(db, id=group_id)
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")
    return _enrich_group_with_members(db, db_group)


@router.post("", response_model=GroupResponse, status_code=201)
async def create_group(
    group_data: GroupBase,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """Create a new group"""
    # Create GroupCreate with owner_id from authenticated user
    create_data = GroupCreate(
        name=group_data.name,
        description=group_data.description,
        owner_id=current_user_id
    )

    # Create with validation (all checks in CRUD layer)
    db_group, error = group.create_with_validation(db, obj_in=create_data)

    if error:
        raise HTTPException(status_code=404, detail=error)

    return _enrich_group_with_members(db, db_group)


@router.put("/{group_id}", response_model=GroupResponse)
async def update_group(
    group_id: int,
    group_data: GroupBase,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Update an existing group.

    Requires JWT authentication - provide token in Authorization header.
    Only the group creator can update groups.
    """
    # Check permissions (creator only)
    check_group_permission(group_id, current_user_id, db)

    db_group = group.get(db, id=group_id)
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")

    updated_group = group.update(db, db_obj=db_group, obj_in=group_data)
    return _enrich_group_with_members(db, updated_group)


@router.delete("/{group_id}")
async def delete_group(
    group_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Delete a group.

    Requires JWT authentication - provide token in Authorization header.
    Only the group creator can delete groups.
    """
    # Check permissions (creator only)
    check_group_permission(group_id, current_user_id, db)

    db_group = group.get(db, id=group_id)
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")

    group.delete(db, id=group_id)
    return {"message": "Group deleted successfully", "id": group_id}


@router.post("/{group_id}/members", response_model=GroupResponse, status_code=201)
async def add_group_member(
    group_id: int,
    member_data: dict,  # {"user_id": int, "role": "member" | "admin"}
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Add a member to a group.

    Requires JWT authentication - provide token in Authorization header.
    Only the group owner or admins can add members.

    Args:
        member_data: {"user_id": int, "role": "member" | "admin" (optional, defaults to "member")}
    """
    from crud.crud_group_membership import group_membership
    from crud.crud_user import user

    # Check permissions (owner or admin)
    check_group_permission(group_id, current_user_id, db)

    # Check group exists
    db_group = group.get(db, id=group_id)
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")

    # Get user_id and role from request
    user_id = member_data.get("user_id")
    role = member_data.get("role", "member")

    if not user_id:
        raise HTTPException(status_code=422, detail="user_id is required")

    # Validate role
    if role not in ["member", "admin"]:
        raise HTTPException(status_code=422, detail="role must be 'member' or 'admin'")

    # Check user exists
    db_user = user.get(db, id=user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if already a member
    existing = group_membership.get_multi(db, filters={"group_id": group_id, "user_id": user_id})
    if existing:
        raise HTTPException(status_code=400, detail="User is already a member of this group")

    # Create membership
    membership_data = GroupMembershipCreate(
        group_id=group_id,
        user_id=user_id,
        role=role
    )
    group_membership.create(db, obj_in=membership_data)

    # Return updated group with members
    return _enrich_group_with_members(db, db_group)


@router.delete("/{group_id}/members/{user_id}", response_model=GroupResponse)
async def remove_group_member(
    group_id: int,
    user_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Remove a member from a group.

    Requires JWT authentication - provide token in Authorization header.
    Only the group owner or admins can remove members.
    """
    from crud.crud_group_membership import group_membership

    # Check permissions (owner or admin)
    check_group_permission(group_id, current_user_id, db)

    # Check group exists
    db_group = group.get(db, id=group_id)
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")

    # Check if user is the owner (can't remove owner)
    if user_id == db_group.owner_id:
        raise HTTPException(status_code=400, detail="Cannot remove group owner")

    # Find and delete membership
    memberships = group_membership.get_multi(db, filters={"group_id": group_id, "user_id": user_id})
    if not memberships:
        raise HTTPException(status_code=404, detail="User is not a member of this group")

    # Delete the membership
    group_membership.delete(db, id=memberships[0].id)

    # Return updated group with members
    return _enrich_group_with_members(db, db_group)


@router.delete("/{group_id}/leave", response_model=dict)
async def leave_group(
    group_id: int,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Leave a group (remove yourself as a member).

    Requires JWT authentication - provide token in Authorization header.
    The group owner cannot leave their own group - they must delete it instead.
    """
    from crud.crud_group_membership import group_membership

    # Check group exists
    db_group = group.get(db, id=group_id)
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")

    # Check if user is the owner (can't leave own group)
    if current_user_id == db_group.owner_id:
        raise HTTPException(
            status_code=400,
            detail="Group owner cannot leave their own group. Delete the group instead."
        )

    # Find and delete membership
    memberships = group_membership.get_multi(db, filters={"group_id": group_id, "user_id": current_user_id})
    if not memberships:
        raise HTTPException(status_code=404, detail="You are not a member of this group")

    # Delete the membership
    group_membership.delete(db, id=memberships[0].id)

    return {"message": "Successfully left the group", "group_id": group_id}
