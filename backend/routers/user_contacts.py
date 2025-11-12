"""
User Contacts Router

Handles phone contacts synchronization and retrieval.
"""

import logging
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user_id
from crud import user, user_contact
from dependencies import get_db
from schemas import (
    UserContactBase,
    UserContactResponse,
    UserContactSync,
    UserContactSyncResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/contacts", tags=["contacts"])


@router.post("/sync", response_model=UserContactSyncResponse)
async def sync_contacts(
    request: UserContactSync,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Sync phone contacts from device.

    For each contact:
    1. Check if phone_number exists in users table
    2. Create/update UserContact with owner_id=current_user_id
    3. Link registered_user_id if phone is registered
    """
    synced_count = 0
    registered_count = 0
    registered_contacts = []

    for contact_data in request.contacts:
        # Check if phone is registered
        registered_user = user.get_by_phone(db, phone=contact_data.phone_number)
        registered_user_id = registered_user.id if registered_user else None

        # Check if contact already exists for this owner
        existing_contact = user_contact.get_by_phone(db, owner_id=current_user_id, phone_number=contact_data.phone_number)

        if existing_contact:
            # Update existing contact
            existing_contact.contact_name = contact_data.contact_name
            existing_contact.registered_user_id = registered_user_id
            db.commit()
            db.refresh(existing_contact)
        else:
            # Create new contact
            from models import UserContact

            new_contact = UserContact(
                owner_id=current_user_id,
                contact_name=contact_data.contact_name,
                phone_number=contact_data.phone_number,
                registered_user_id=registered_user_id,
            )
            db.add(new_contact)
            db.commit()
            db.refresh(new_contact)

        synced_count += 1

        if registered_user_id:
            registered_count += 1
            registered_contacts.append(
                {
                    "id": registered_user.id,
                    "display_name": registered_user.display_name,
                    "phone": registered_user.phone,
                    "profile_picture_url": registered_user.profile_picture_url,
                }
            )

    return UserContactSyncResponse(
        synced_count=synced_count,
        registered_count=registered_count,
        registered_contacts=registered_contacts,
    )


@router.get("", response_model=List[UserContactResponse])
async def get_my_contacts(
    only_registered: bool = True,
    limit: int = 100,
    skip: int = 0,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get contacts for the current user.

    Args:
        only_registered: If True, only return contacts that are registered users
        limit: Maximum number of contacts to return
        skip: Number of contacts to skip
    """
    contacts = user_contact.get_by_owner(db, owner_id=current_user_id, only_registered=only_registered, skip=skip, limit=limit)

    result = []
    for contact in contacts:
        contact_dict = {
            "id": contact.id,
            "owner_id": contact.owner_id,
            "contact_name": contact.contact_name,
            "phone_number": contact.phone_number,
            "registered_user_id": contact.registered_user_id,
            "is_registered": contact.registered_user_id is not None,
            "last_synced_at": contact.last_synced_at,
            "created_at": contact.created_at,
            "updated_at": contact.updated_at,
            "registered_user": None,
        }

        # Enrich with registered user data
        if contact.registered_user_id:
            registered_user = user.get(db, id=contact.registered_user_id)
            if registered_user:
                contact_dict["registered_user"] = {
                    "id": registered_user.id,
                    "display_name": registered_user.display_name,
                    "phone": registered_user.phone,
                    "instagram_username": registered_user.instagram_username,
                    "profile_picture_url": registered_user.profile_picture_url,
                    "is_public": registered_user.is_public,
                }

        result.append(contact_dict)

    return result
