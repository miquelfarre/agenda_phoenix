"""
Base CRUD class for database operations

Provides generic CRUD operations that can be reused across all models.
Uses SQLAlchemy ORM for database access with optimized queries.
"""

from typing import Any, Dict, Generic, List, Optional, Type, TypeVar, Union

from pydantic import BaseModel
from sqlalchemy import func
from sqlalchemy.orm import Session

from database import Base

ModelType = TypeVar("ModelType", bound=Base)
CreateSchemaType = TypeVar("CreateSchemaType", bound=BaseModel)
UpdateSchemaType = TypeVar("UpdateSchemaType", bound=BaseModel)


class CRUDBase(Generic[ModelType, CreateSchemaType, UpdateSchemaType]):
    """
    Base CRUD class with generic database operations.

    Type Parameters:
        ModelType: SQLAlchemy model class
        CreateSchemaType: Pydantic schema for creation
        UpdateSchemaType: Pydantic schema for updates
    """

    def __init__(self, model: Type[ModelType]):
        """
        Initialize CRUD object with model class.

        Args:
            model: SQLAlchemy model class
        """
        self.model = model

    def get(self, db: Session, id: Any) -> Optional[ModelType]:
        """
        Get a single record by ID.

        Args:
            db: Database session
            id: Primary key value

        Returns:
            Model instance or None if not found
        """
        return db.query(self.model).filter(self.model.id == id).first()

    def get_multi(self, db: Session, *, skip: int = 0, limit: int = 100, order_by: Optional[str] = None, order_dir: str = "asc", filters: Optional[Dict[str, Any]] = None) -> List[ModelType]:
        """
        Get multiple records with pagination and filtering.

        Args:
            db: Database session
            skip: Number of records to skip (offset)
            limit: Maximum number of records to return
            order_by: Column name to order by (default: id)
            order_dir: Order direction ('asc' or 'desc')
            filters: Dictionary of column-value pairs to filter by

        Returns:
            List of model instances
        """
        query = db.query(self.model)

        # Apply filters
        if filters:
            for key, value in filters.items():
                if hasattr(self.model, key):
                    query = query.filter(getattr(self.model, key) == value)

        # Apply ordering
        if order_by and hasattr(self.model, order_by):
            order_col = getattr(self.model, order_by)
        else:
            order_col = self.model.id

        if order_dir.lower() == "desc":
            query = query.order_by(order_col.desc())
        else:
            query = query.order_by(order_col.asc())

        # Apply pagination
        return query.offset(skip).limit(limit).all()

    def get_multi_by_ids(self, db: Session, ids: List[Any]) -> List[ModelType]:
        """
        Get multiple records by list of IDs (batch query).

        This is more efficient than multiple get() calls.

        Args:
            db: Database session
            ids: List of primary key values

        Returns:
            List of model instances
        """
        return db.query(self.model).filter(self.model.id.in_(ids)).all()

    def create(self, db: Session, *, obj_in: CreateSchemaType) -> ModelType:
        """
        Create a new record.

        Args:
            db: Database session
            obj_in: Pydantic schema with data to create

        Returns:
            Created model instance
        """
        obj_in_data = obj_in.model_dump()
        db_obj = self.model(**obj_in_data)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def update(self, db: Session, *, db_obj: ModelType, obj_in: Union[UpdateSchemaType, Dict[str, Any]]) -> ModelType:
        """
        Update an existing record.

        Args:
            db: Database session
            db_obj: Existing model instance to update
            obj_in: Pydantic schema or dict with update data

        Returns:
            Updated model instance
        """
        if isinstance(obj_in, dict):
            update_data = obj_in
        else:
            update_data = obj_in.model_dump(exclude_unset=True)

        for field, value in update_data.items():
            if hasattr(db_obj, field):
                setattr(db_obj, field, value)

        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def delete(self, db: Session, *, id: Any) -> Optional[ModelType]:
        """
        Delete a record by ID.

        Args:
            db: Database session
            id: Primary key value

        Returns:
            Deleted model instance or None if not found
        """
        # Use db.get() instead of query().get() for SQLAlchemy 2.0+ compatibility
        obj = db.get(self.model, id)
        if obj:
            db.delete(obj)
            db.commit()
        return obj

    def exists(self, db: Session, id: Any) -> bool:
        """
        Check if a record exists by ID.

        More efficient than get() when you only need to check existence.

        Args:
            db: Database session
            id: Primary key value

        Returns:
            True if exists, False otherwise
        """
        return db.query(self.model.id).filter(self.model.id == id).first() is not None

    def count(self, db: Session, filters: Optional[Dict[str, Any]] = None) -> int:
        """
        Count records with optional filtering.

        Args:
            db: Database session
            filters: Dictionary of column-value pairs to filter by

        Returns:
            Number of records matching filters
        """
        query = db.query(func.count(self.model.id))

        if filters:
            for key, value in filters.items():
                if hasattr(self.model, key):
                    query = query.filter(getattr(self.model, key) == value)

        return query.scalar()
