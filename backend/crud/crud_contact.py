"""
CRUD operations for Contact model
"""

from typing import Optional

from sqlalchemy.orm import Session

from crud.base import CRUDBase
from models import Contact
from schemas import ContactBase, ContactCreate


class CRUDContact(CRUDBase[Contact, ContactCreate, ContactBase]):
    """CRUD operations for Contact model with specific methods"""

    def get_by_phone(self, db: Session, phone: str) -> Optional[Contact]:
        """
        Get contact by phone number.

        Args:
            db: Database session
            phone: Phone number

        Returns:
            Contact instance or None
        """
        return db.query(Contact).filter(Contact.phone == phone).first()

    def exists_phone(self, db: Session, phone: str) -> bool:
        """
        Check if phone number already exists (optimized).

        Args:
            db: Database session
            phone: Phone number

        Returns:
            True if exists, False otherwise
        """
        return db.query(Contact.id).filter(Contact.phone == phone).first() is not None


# Singleton instance
contact = CRUDContact(Contact)
