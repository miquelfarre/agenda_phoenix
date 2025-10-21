"""
Contacts Router (REFACTORED VERSION)

Handles all contact-related endpoints using CRUD classes.
This version is cleaner, more maintainable, and reuses database logic.

Compare with original contacts.py to see improvements:
- Less code duplication
- Reusable CRUD operations
- Better separation of concerns
- Optimized queries through CRUD layer
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from crud import contact
from dependencies import get_db
from schemas import ContactCreate, ContactResponse

router = APIRouter(prefix="/contacts", tags=["contacts"])


@router.get("", response_model=List[ContactResponse])
async def get_contacts(limit: int = 50, offset: int = 0, order_by: str = "id", order_dir: str = "asc", db: Session = Depends(get_db)):
    """
    Get all contacts with pagination and ordering.

    Using CRUD: Simplified from 9 lines to 1 line!
    """
    return contact.get_multi(db, skip=offset, limit=min(200, max(1, limit)), order_by=order_by, order_dir=order_dir)


@router.get("/{contact_id}", response_model=ContactResponse)
async def get_contact(contact_id: int, db: Session = Depends(get_db)):
    """
    Get a single contact by ID.

    Using CRUD: Cleaner error handling
    """
    db_contact = contact.get(db, id=contact_id)
    if not db_contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    return db_contact


@router.post("", response_model=ContactResponse, status_code=201)
async def create_contact(contact_in: ContactCreate, db: Session = Depends(get_db)):
    """
    Create a new contact.

    Using CRUD: exists_phone() is more efficient than querying full object
    """
    # Check if phone already exists (optimized query)
    if contact.exists_phone(db, phone=contact_in.phone):
        raise HTTPException(status_code=400, detail="Phone number already exists")

    return contact.create(db, obj_in=contact_in)


@router.put("/{contact_id}", response_model=ContactResponse)
async def update_contact(contact_id: int, contact_in: ContactCreate, db: Session = Depends(get_db)):
    """
    Update an existing contact.

    Using CRUD: Simplified logic and better phone validation
    """
    # Get existing contact
    db_contact = contact.get(db, id=contact_id)
    if not db_contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    # Check if new phone already exists for another contact
    existing_contact = contact.get_by_phone(db, phone=contact_in.phone)
    if existing_contact and existing_contact.id != contact_id:
        raise HTTPException(status_code=400, detail="Phone number already exists")

    return contact.update(db, db_obj=db_contact, obj_in=contact_in)


@router.delete("/{contact_id}")
async def delete_contact(contact_id: int, db: Session = Depends(get_db)):
    """
    Delete a contact.

    Using CRUD: Simplified to 1 line + error handling
    """
    deleted = contact.delete(db, id=contact_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Contact not found")

    return {"message": "Contact deleted successfully", "id": contact_id}
