"""
Contacts Router

Handles all contact-related endpoints.
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List

from models import Contact
from schemas import ContactCreate, ContactResponse
from dependencies import get_db


router = APIRouter(
    prefix="/contacts",
    tags=["contacts"]
)


@router.get("", response_model=List[ContactResponse])
async def get_contacts(
    limit: int = 50,
    offset: int = 0,
    order_by: str = "id",
    order_dir: str = "asc",
    db: Session = Depends(get_db)
):
    """Get all contacts with pagination and ordering"""
    query = db.query(Contact)
    order_col = getattr(Contact, order_by) if order_by and hasattr(Contact, str(order_by)) else Contact.id
    if order_dir and order_dir.lower() == "desc":
        query = query.order_by(order_col.desc())
    else:
        query = query.order_by(order_col.asc())
    query = query.offset(max(0, offset)).limit(max(1, min(200, limit)))
    contacts = query.all()
    return contacts


@router.get("/{contact_id}", response_model=ContactResponse)
async def get_contact(contact_id: int, db: Session = Depends(get_db)):
    """Get a single contact by ID"""
    contact = db.query(Contact).filter(Contact.id == contact_id).first()
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    return contact


@router.post("", response_model=ContactResponse, status_code=201)
async def create_contact(contact: ContactCreate, db: Session = Depends(get_db)):
    """Create a new contact"""
    # Check if phone already exists
    existing = db.query(Contact).filter(Contact.phone == contact.phone).first()
    if existing:
        raise HTTPException(status_code=400, detail="Phone number already exists")

    db_contact = Contact(**contact.dict())
    db.add(db_contact)
    db.commit()
    db.refresh(db_contact)
    return db_contact


@router.put("/{contact_id}", response_model=ContactResponse)
async def update_contact(contact_id: int, contact: ContactCreate, db: Session = Depends(get_db)):
    """Update an existing contact"""
    db_contact = db.query(Contact).filter(Contact.id == contact_id).first()
    if not db_contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    # Check if phone already exists for another contact
    existing = db.query(Contact).filter(
        Contact.phone == contact.phone,
        Contact.id != contact_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Phone number already exists")

    for key, value in contact.dict().items():
        setattr(db_contact, key, value)

    db.commit()
    db.refresh(db_contact)
    return db_contact


@router.delete("/{contact_id}")
async def delete_contact(contact_id: int, db: Session = Depends(get_db)):
    """Delete a contact"""
    db_contact = db.query(Contact).filter(Contact.id == contact_id).first()
    if not db_contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    db.delete(db_contact)
    db.commit()
    return {"message": "Contact deleted successfully", "id": contact_id}
