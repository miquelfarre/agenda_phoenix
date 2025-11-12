"""
Database initialization script v2 - Complete test dataset with 100 users
This script will:
1. Drop all tables
2. Create all tables from SQLAlchemy models
3. Insert sample data with 100 users and complex scenarios
4. Create test users in Supabase Auth

Pure SQLAlchemy - NO RAW SQL!
"""

import logging
import sys
from pathlib import Path

# Add backend directory to path
sys.path.append(str(Path(__file__).parent))

from init_db import (
    drop_all_tables,
    create_all_tables,
    create_calendar_subscription_triggers,
    grant_supabase_permissions,
    create_database_views,
    setup_realtime,
    setup_realtime_tenant,
    create_supabase_auth_users
)
from database import SessionLocal
from sqlalchemy import text
from init_db_2_data import (
    users_private,
    users_public,
    contacts,
    groups,
    calendars,
    events_private,
    events_public,
    events_recurring,
    interactions_invitations,
    interactions_subscriptions,
    blocks_bans
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def reset_sequences(db):
    """
    Reset all autoincrement sequences to max(id)+1 for each table.
    This is necessary after inserting data with explicit IDs.
    """
    logger.info("🔄 Resetting autoincrement sequences...")

    tables_with_sequences = [
        'users',
        'events',
        'event_interactions',
        'calendars',
        'calendar_memberships',
        'calendar_subscriptions',
        'groups',
        'group_memberships',
        'recurring_event_configs',
        'event_bans',
        'user_blocks',
        'event_cancellations',
        'event_cancellation_views',
        'user_contacts'
    ]

    for table in tables_with_sequences:
        try:
            # Get the current max ID
            result = db.execute(text(f"SELECT MAX(id) FROM {table}"))
            max_id = result.scalar()

            if max_id is not None:
                # Reset the sequence to max_id + 1
                db.execute(text(f"SELECT setval(pg_get_serial_sequence('{table}', 'id'), {max_id}, true)"))
                logger.info(f"  ✓ Reset {table} sequence to {max_id + 1}")
        except Exception as e:
            logger.warning(f"  ⚠ Could not reset sequence for {table}: {e}")

    db.commit()
    logger.info("✅ Sequences reset complete")


def insert_sample_data_v2():
    """Insert complete sample data with 100 users and complex scenarios"""
    logger.info("📊 Inserting sample data v2 (100 users, complex scenarios)...")

    db = SessionLocal()

    try:
        # 1. Create users
        logger.info("👥 Creating private users (ID 1-85)...")
        private_users_data = users_private.create_private_users(db)
        logger.info(f"  ✓ Created {len(private_users_data['all_users'])} private users")

        logger.info("🏢 Creating public users (ID 86-100)...")
        public_users_data = users_public.create_public_users(db)
        logger.info(f"  ✓ Created {len(public_users_data['all_public_users'])} public users")

        # 2. Create contacts
        logger.info("📇 Creating user contacts...")
        contacts_data = contacts.create_contacts(db, private_users_data, public_users_data)
        logger.info(f"  ✓ Created {len(contacts_data)} contacts")

        # 3. Create groups
        logger.info("👥 Creating groups...")
        groups_data = groups.create_groups(db, private_users_data)
        logger.info(f"  ✓ Created {len(groups_data['all_groups'])} groups")

        # 4. Create calendars
        logger.info("📅 Creating calendars (with share_hash)...")
        calendars_data = calendars.create_calendars(db, private_users_data, public_users_data)
        logger.info(f"  ✓ Created {len(calendars_data['all_calendars'])} calendars")

        # 5. Create private events
        logger.info("🎉 Creating private events...")
        private_events_data = events_private.create_private_events(db, private_users_data, groups_data)
        logger.info(f"  ✓ Created {len(private_events_data['all_private_events'])} private events")

        # 6. Create public events
        logger.info("📢 Creating public events...")
        public_events_data = events_public.create_public_events(db, public_users_data)
        logger.info(f"  ✓ Created {len(public_events_data['all_public_events'])} public events")

        # 7. Create recurring events
        logger.info("🔄 Creating recurring events...")
        recurring_events_data = events_recurring.create_recurring_events(db, private_users_data, public_users_data)
        logger.info(f"  ✓ Created {len(recurring_events_data['all_recurring_events'])} recurring events")

        # 8. Create invitations
        logger.info("✉️  Creating invitations...")
        invitations_data = interactions_invitations.create_invitations(
            db, private_users_data, private_events_data, public_events_data, recurring_events_data
        )
        logger.info(f"  ✓ Created {len(invitations_data)} invitations")

        # 9. Create subscriptions
        logger.info("🔔 Creating subscriptions...")
        subscriptions_data = interactions_subscriptions.create_subscriptions(
            db, private_users_data, public_events_data
        )
        logger.info(f"  ✓ Created {len(subscriptions_data)} subscriptions")

        # 10. Create blocks and bans
        logger.info("🚫 Creating blocks and bans...")
        blocks_data = blocks_bans.create_blocks_and_bans(db, private_users_data, private_events_data)
        logger.info(f"  ✓ Created {len(blocks_data['blocks'])} blocks and {len(blocks_data['bans'])} bans")

        db.commit()

        # Reset autoincrement sequences after inserting data with explicit IDs
        reset_sequences(db)

        logger.info("✅ Sample data v2 inserted successfully!")
        logger.info(f"""
        📊 Dataset Summary:
        - 100 users (85 private + 15 public)
        - {len(contacts_data)} contacts
        - {len(groups_data['all_groups'])} groups
        - {len(calendars_data['all_calendars'])} calendars
        - {len(private_events_data['all_private_events']) + len(public_events_data['all_public_events']) + len(recurring_events_data['all_recurring_events'])} events
        - {len(invitations_data) + len(subscriptions_data)} interactions
        - {len(blocks_data['blocks'])} blocks, {len(blocks_data['bans'])} bans

        🎯 Default user: USER_ID=1 (Sonia Martínez, +34600000001)
        """)

    except Exception as e:
        logger.error(f"❌ Error inserting sample data: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
        raise
    finally:
        db.close()


def init_database():
    """
    Main function to initialize the database v2.
    Called when the backend starts.
    """
    logger.info("=" * 60)
    logger.info("🚀 Starting database initialization v2 (100 users)...")
    logger.info("=" * 60)

    try:
        # 1. Drop all tables
        drop_all_tables()

        # 2. Create all tables
        create_all_tables()

        # 3. Grant permissions
        grant_supabase_permissions()

        # 4. Create database views
        create_database_views()

        # 5. Setup realtime
        setup_realtime()
        setup_realtime_tenant()

        # 6. Insert sample data v2 (100 users)
        insert_sample_data_v2()

        # 7. Create calendar subscription triggers
        create_calendar_subscription_triggers()

        # 8. Create Supabase auth users
        create_supabase_auth_users()

        logger.info("=" * 60)
        logger.info("✅ Database initialization v2 completed successfully!")
        logger.info("=" * 60)

    except Exception as e:
        logger.error("=" * 60)
        logger.error(f"❌ Database initialization v2 failed: {e}")
        logger.error("=" * 60)
        raise


if __name__ == "__main__":
    # Can be run standalone: python init_db_2.py
    init_database()
