"""
Contacts Router

Handles all contact-related endpoints.
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from crud import contact
from dependencies import check_contact_permission, get_db
from schemas import ContactCreate, ContactResponse

router = APIRouter(prefix="/api/v1/contacts", tags=["contacts"])


@router.get("", response_model=List[ContactResponse])
async def get_contacts(
    limit: int = 50,
    offset: int = 0,
    order_by: str = "id",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """Get all contacts with pagination and ordering"""
    # Validate and limit pagination
    limit = max(1, min(200, limit))
    offset = max(0, offset)

    return contact.get_multi(
        db,
        skip=offset,
        limit=limit,
        order_by=order_by,
        order_dir=order_dir
    )


@router.get("/{contact_id}", response_model=ContactResponse)
async def get_contact(contact_id: int, db: Session = Depends(get_db)):
    """Get a single contact by ID"""
    db_contact = contact.get(db, id=contact_id)
    if not db_contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    return db_contact


@router.post("", response_model=ContactResponse, status_code=201)
async def create_contact(contact_in: ContactCreate, db: Session = Depends(get_db)):
    """Create a new contact"""
    # Check if phone already exists (optimized query)
    if contact.exists_phone(db, phone=contact_in.phone):
        raise HTTPException(status_code=400, detail="Phone number already exists")

    return contact.create(db, obj_in=contact_in)


@router.put("/{contact_id}", response_model=ContactResponse)
async def update_contact(contact_id: int, contact_in: ContactCreate, current_user_id: int, db: Session = Depends(get_db)):
    """
    Update an existing contact.

    Requires current_user_id to verify permissions.
    Only the contact owner can update contacts.
    """
    # Check permissions (owner only)
    check_contact_permission(contact_id, current_user_id, db)

    # Get existing contact
    db_contact = contact.get(db, id=contact_id)
    if not db_contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    # Check if new phone already exists for another contact of the same owner
    existing_contact = contact.get_by_phone(db, phone=contact_in.phone)
    if existing_contact and existing_contact.id != contact_id and existing_contact.owner_id == current_user_id:
        raise HTTPException(status_code=400, detail="Phone number already exists in your contacts")

    return contact.update(db, db_obj=db_contact, obj_in=contact_in)


@router.delete("/{contact_id}")
async def delete_contact(contact_id: int, current_user_id: int, db: Session = Depends(get_db)):
    """
    Delete a contact.

    Requires current_user_id to verify permissions.
    Only the contact owner can delete contacts.
    """
    # Check permissions (owner only)
    check_contact_permission(contact_id, current_user_id, db)

    deleted = contact.delete(db, id=contact_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Contact not found")

    return {"message": "Contact deleted successfully", "id": contact_id}
