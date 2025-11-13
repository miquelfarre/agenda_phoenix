"""
Database initialization script v2 - Complete test dataset with 100 users
This script will:
1. Drop all tables
2. Create all tables from SQLAlchemy models
3. Insert sample data with 100 users and complex scenarios
4. Create test users in Supabase Auth (skipped by default here)

Pure SQLAlchemy for core schema. Realtime/auth setup is optional and stubbed.
"""

import logging
import sys
from pathlib import Path

# Add backend directory to path
sys.path.append(str(Path(__file__).parent))

from database import Base, engine, SessionLocal
from sqlalchemy import text
import logging

# --- Minimal local implementations to avoid dependency on init_db.py ---


def drop_all_tables():
    """Drop all SQLAlchemy-managed tables (does not touch external Supabase tables)."""
    logger = logging.getLogger(__name__)
    logger.info("🗑️  Dropping all SQLAlchemy tables...")

    # First drop legacy tables and views that may depend on our tables (to avoid dependency errors)
    try:
        with engine.connect() as conn:
            # Drop legacy tables (from old code) before dropping current tables
            conn.execute(text("DROP TABLE IF EXISTS recurring_event_configs CASCADE"))
            logger.info("  ✓ Dropped legacy table: recurring_event_configs")

            # Known app views that reference core tables
            conn.execute(text("DROP VIEW IF EXISTS user_subscriptions_with_stats CASCADE"))
            conn.commit()
            logger.info("  ✓ Dropped dependent views (if existed)")
    except Exception as e:
        logger.warning(f"  ⚠ Could not drop legacy objects (continuing): {e}")

    # Now drop tables managed by SQLAlchemy
    Base.metadata.drop_all(bind=engine)
    logger.info("✅ Tables dropped")


def create_all_tables():
    """Create all SQLAlchemy-managed tables."""
    logging.getLogger(__name__).info("🏗️  Creating tables from models...")
    Base.metadata.create_all(bind=engine)
    logging.getLogger(__name__).info("✅ Tables created")


def grant_supabase_permissions():
    """No-op placeholder for permissions handled elsewhere."""
    logging.getLogger(__name__).info("🔐 Skipping explicit Supabase permissions (handled by SQL scripts)")


def create_database_views():
    """Create database views used by the app (idempotent)."""
    logger = logging.getLogger(__name__)
    logger.info("👁️  Creating database views...")
    try:
        with engine.connect() as conn:
            conn.execute(
                text(
                    """
                CREATE OR REPLACE VIEW user_subscriptions_with_stats AS
                SELECT DISTINCT
                    ei.user_id AS subscriber_id,
                    u.id AS subscribed_to_id,
                    u.display_name,
                    u.phone,
                    u.instagram_username,
                    u.profile_picture_url,
                    u.auth_provider,
                    u.auth_id,
                    u.is_public,
                    u.is_admin,
                    u.last_login AS last_seen,
                    u.created_at,
                    u.updated_at,
                    0 AS new_events_count,
                    0 AS total_events_count,
                    0 AS subscribers_count
                FROM event_interactions ei
                JOIN events e ON e.id = ei.event_id
                JOIN users u ON u.id = e.owner_id
                WHERE ei.interaction_type = 'subscribed'
                AND u.is_public = TRUE
            """
                )
            )
            conn.commit()
        logger.info("✅ Database views created successfully")
    except Exception as e:
        logger.warning(f"⚠️  Could not create database views: {e}")


def setup_realtime():
    """Optional: Realtime setup is skipped in this simplified initializer."""
    logging.getLogger(__name__).info("🔄 Skipping Realtime setup in v2 initializer")


def setup_realtime_tenant():
    """Optional: Realtime tenant setup is skipped."""
    logging.getLogger(__name__).info("🔧 Skipping Realtime tenant setup in v2 initializer")


def create_calendar_subscription_triggers():
    """Optional: Create triggers for calendar subscription counts (idempotent)."""
    logger = logging.getLogger(__name__)
    logger.info("⚙️  Creating calendar subscription triggers...")
    try:
        with engine.connect() as conn:
            conn.execute(
                text(
                    """
                CREATE OR REPLACE FUNCTION update_calendar_subscriber_count()
                RETURNS TRIGGER AS $$
                BEGIN
                    IF TG_OP = 'INSERT' THEN
                        UPDATE calendars
                        SET subscriber_count = subscriber_count + 1
                        WHERE id = NEW.calendar_id;
                        RETURN NEW;
                    ELSIF TG_OP = 'DELETE' THEN
                        UPDATE calendars
                        SET subscriber_count = GREATEST(subscriber_count - 1, 0)
                        WHERE id = OLD.calendar_id;
                        RETURN OLD;
                    ELSIF TG_OP = 'UPDATE' THEN
                        IF OLD.calendar_id != NEW.calendar_id THEN
                            UPDATE calendars
                            SET subscriber_count = GREATEST(subscriber_count - 1, 0)
                            WHERE id = OLD.calendar_id;
                            UPDATE calendars
                            SET subscriber_count = subscriber_count + 1
                            WHERE id = NEW.calendar_id;
                        END IF;
                        RETURN NEW;
                    END IF;
                    RETURN NULL;
                END;
                $$ LANGUAGE plpgsql;

                DROP TRIGGER IF EXISTS calendar_subscription_count_trigger ON calendar_subscriptions;
                CREATE TRIGGER calendar_subscription_count_trigger
                AFTER INSERT OR DELETE OR UPDATE ON calendar_subscriptions
                FOR EACH ROW
                EXECUTE FUNCTION update_calendar_subscriber_count();
            """
                )
            )
            conn.execute(text("ALTER TABLE calendar_subscriptions REPLICA IDENTITY FULL;"))
            conn.commit()
        logger.info("✅ Calendar subscription triggers ready")
    except Exception as e:
        logger.warning(f"⚠️  Could not create calendar subscription triggers: {e}")


def create_supabase_auth_users():
    """Optional: Skip creating Supabase Auth users here (handled elsewhere)."""
    logging.getLogger(__name__).info("👤 Skipping Supabase Auth user creation in v2 initializer")


from init_db_2_data import users_private, users_public, contacts, groups, calendars, events_private, events_public, interactions_invitations, interactions_subscriptions, blocks_bans

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def reset_sequences(db):
    """
    Reset all autoincrement sequences to max(id)+1 for each table.
    This is necessary after inserting data with explicit IDs.
    """
    logger.info("🔄 Resetting autoincrement sequences...")

    tables_with_sequences = ["users", "events", "event_interactions", "calendars", "calendar_memberships", "calendar_subscriptions", "groups", "group_memberships", "user_blocks", "event_cancellations", "event_cancellation_views", "user_contacts"]

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

        # 7. Create invitations
        logger.info("✉️  Creating invitations...")
        invitations_data = interactions_invitations.create_invitations(db, private_users_data, private_events_data, public_events_data, {})
        logger.info(f"  ✓ Created {len(invitations_data)} invitations")

        # 9. Create subscriptions
        logger.info("🔔 Creating subscriptions...")
        subscriptions_data = interactions_subscriptions.create_subscriptions(db, private_users_data, public_events_data)
        logger.info(f"  ✓ Created {len(subscriptions_data)} subscriptions")

        # 10. Create blocks (bans removed)
        logger.info("🚫 Creating user blocks...")
        blocks_data = blocks_bans.create_blocks_and_bans(db, private_users_data, private_events_data)
        logger.info(f"  ✓ Created {len(blocks_data['blocks'])} blocks")

        db.commit()

        # Reset autoincrement sequences after inserting data with explicit IDs
        reset_sequences(db)

        logger.info("✅ Sample data v2 inserted successfully!")
        logger.info(
            f"""
        📊 Dataset Summary:
        - 100 users (85 private + 15 public)
        - {len(contacts_data)} contacts
        - {len(groups_data['all_groups'])} groups
        - {len(calendars_data['all_calendars'])} calendars
        - {len(private_events_data['all_private_events']) + len(public_events_data['all_public_events'])} events
        - {len(invitations_data) + len(subscriptions_data)} interactions
        - {len(blocks_data['blocks'])} blocks

        🎯 Default user: USER_ID=1 (Sonia Martínez, +34600000001)
        """
        )

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
