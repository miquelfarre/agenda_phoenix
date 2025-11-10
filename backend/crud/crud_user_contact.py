"""
CRUD operations for UserContact model
"""

from datetime import datetime
from typing import List, Optional

from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import UserContact, User
from schemas import UserContactBase, UserContactCreate


class CRUDUserContact(CRUDBase[UserContact, UserContactCreate, UserContactBase]):
    """CRUD operations for UserContact model with specific methods"""

    def get_by_owner(self, db: Session, owner_id: int, only_registered: bool = False, skip: int = 0, limit: int = 100) -> List[UserContact]:
        """
        Get all contacts for a specific owner.

        Args:
            db: Database session
            owner_id: ID of the owner user
            only_registered: If True, only return contacts that are registered users
            skip: Number of records to skip
            limit: Maximum number of records to return

        Returns:
            List of UserContact instances
        """
        query = db.query(UserContact).filter(UserContact.owner_id == owner_id)

        if only_registered:
            query = query.filter(UserContact.registered_user_id.isnot(None))

        return query.offset(skip).limit(limit).all()

    def get_by_phone(self, db: Session, owner_id: int, phone_number: str) -> Optional[UserContact]:
        """
        Get a specific contact by owner and phone number.

        Args:
            db: Database session
            owner_id: ID of the owner user
            phone_number: Phone number to search

        Returns:
            UserContact instance or None
        """
        return db.query(UserContact).filter(UserContact.owner_id == owner_id, UserContact.phone_number == phone_number).first()

    def sync_contacts(self, db: Session, owner_id: int, contacts: List[UserContactBase]) -> dict:
        """
        Sync contacts from device.

        This method:
        1. For each contact, checks if it already exists (same owner_id + phone)
        2. If exists, updates name and timestamp
        3. If not exists, creates new UserContact
        4. Finds which phones are registered users
        5. Updates registered_user_id for registered contacts
        6. Returns list of registered contacts

        Args:
            db: Database session
            owner_id: ID of the owner user
            contacts: List of contact data from device

        Returns:
            Dict with sync results
        """
        synced_contacts = []
        registered_contacts = []

        # Extract list of phone numbers
        phone_numbers = [c.phone_number for c in contacts]

        # Find registered users with those phones (1 query)
        registered_users = db.query(User).filter(User.phone.in_(phone_numbers), User.is_public == False).all()  # Only private users (phone auth)

        # Create map phone -> user
        phone_to_user = {u.phone: u for u in registered_users}

        # Sync each contact
        for contact_data in contacts:
            phone = contact_data.phone_number
            name = contact_data.contact_name

            # Check if already exists
            existing = self.get_by_phone(db, owner_id, phone)

            registered_user = phone_to_user.get(phone)
            registered_user_id = registered_user.id if registered_user else None

            if existing:
                # Update
                existing.contact_name = name
                existing.registered_user_id = registered_user_id
                existing.last_synced_at = datetime.now()
                synced_contacts.append(existing)
            else:
                # Create new
                new_contact = UserContact(owner_id=owner_id, contact_name=name, phone_number=phone, registered_user_id=registered_user_id)
                db.add(new_contact)
                synced_contacts.append(new_contact)

            # If registered, add to return list
            if registered_user:
                registered_contacts.append({"user_id": registered_user.id, "display_name": registered_user.display_name, "phone": registered_user.phone, "profile_picture_url": registered_user.profile_picture_url, "contact_name": name})  # Name that owner uses

        db.commit()

        return {"synced_count": len(synced_contacts), "registered_count": len(registered_contacts), "registered_contacts": registered_contacts}

    def update_registered_user_for_phone(self, db: Session, phone_number: str, user_id: int) -> int:
        """
        Update all contacts with a specific phone number to link to a registered user.

        This is called when a new user registers with a phone number.

        Args:
            db: Database session
            phone_number: Phone number that was registered
            user_id: ID of the newly registered user

        Returns:
            Number of contacts updated
        """
        updated_count = db.query(UserContact).filter(UserContact.phone_number == phone_number, UserContact.registered_user_id.is_(None)).update({"registered_user_id": user_id, "updated_at": datetime.now()})  # Only update unlinked contacts

        db.commit()
        return updated_count


# Singleton instance
user_contact = CRUDUserContact(UserContact)
