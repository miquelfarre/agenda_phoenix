"""
Database initialization script.
This script will:
1. Drop all tables
2. Create all tables from SQLAlchemy models
3. Insert sample data

Pure SQLAlchemy - NO RAW SQL!
"""

import logging
from database import engine, Base, SessionLocal
from models import Event

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def drop_all_tables():
    """Drop all tables in the database"""
    logger.info("🗑️  Dropping all tables...")
    try:
        Base.metadata.drop_all(bind=engine)
        logger.info("✅ All tables dropped successfully")
    except Exception as e:
        logger.error(f"❌ Error dropping tables: {e}")
        raise


def create_all_tables():
    """Create all tables from SQLAlchemy models"""
    logger.info("🏗️  Creating tables from models...")
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("✅ All tables created successfully")
    except Exception as e:
        logger.error(f"❌ Error creating tables: {e}")
        raise


def insert_sample_data():
    """Insert sample data into the database"""
    logger.info("📊 Inserting sample data...")

    db = SessionLocal()
    try:
        sample_events = [
            Event(name="Welcome to Agenda Phoenix"),
            Event(name="First Event"),
            Event(name="Sample Event"),
            Event(name="Meeting with Team"),
            Event(name="Project Deadline"),
        ]

        db.add_all(sample_events)
        db.commit()

        logger.info(f"✅ Inserted {len(sample_events)} sample events")

    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error inserting sample data: {e}")
        raise
    finally:
        db.close()


def init_database():
    """
    Main function to initialize the database.
    Called when the backend starts.
    """
    logger.info("=" * 60)
    logger.info("🚀 Starting database initialization...")
    logger.info("=" * 60)

    try:
        # Step 1: Drop all tables
        drop_all_tables()

        # Step 2: Create all tables
        create_all_tables()

        # Step 3: Insert sample data
        insert_sample_data()

        logger.info("=" * 60)
        logger.info("✅ Database initialization completed successfully!")
        logger.info("=" * 60)

    except Exception as e:
        logger.error("=" * 60)
        logger.error(f"❌ Database initialization failed: {e}")
        logger.error("=" * 60)
        raise


if __name__ == "__main__":
    # Can be run standalone: python init_db.py
    init_database()
