"""
Database initialization script.
This script will:
1. Drop all tables
2. Create all tables from SQLAlchemy models
3. Insert sample data
4. Create test users in Supabase Auth

Pure SQLAlchemy - NO RAW SQL!
"""

import logging
import os
from datetime import datetime, timedelta

from sqlalchemy import inspect, text
import json
from typing import Optional

# Crypto for AES-128-ECB (tenant jwt_secret encryption)
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import base64
from supabase import create_client, Client

from database import Base, SessionLocal, engine
from models import Calendar, CalendarMembership, Contact, Event, EventBan, EventCancellation, EventCancellationView, EventInteraction, RecurringEventConfig, User, UserBlock

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def drop_all_tables():
    """Drop all tables in the database"""
    logger.info("🗑️  Dropping all tables...")
    try:
        # Tables managed by Supabase Realtime - DO NOT DROP
        realtime_tables = {
            'tenants',
            'extensions',
            'schema_migrations',
            'messages',
            'broadcast_policies',
            'presence_policies',
            'channels'
        }

        # Use inspector to get all tables and drop them with CASCADE
        # This handles circular foreign key dependencies
        inspector = inspect(engine)
        tables = inspector.get_table_names()

        if tables:
            with engine.connect() as conn:
                # Drop all tables except Realtime-managed ones
                for table in tables:
                    if table not in realtime_tables:
                        conn.execute(text(f'DROP TABLE IF EXISTS "{table}" CASCADE'))
                        logger.info(f"  🗑️  Dropped table: {table}")
                    else:
                        logger.info(f"  ⏩ Skipped Realtime table: {table}")
                conn.commit()

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


def create_subscription_stats_triggers():
    """
    Create user_subscription_stats table and triggers for CDC architecture.
    These triggers maintain pre-calculated statistics automatically.
    """
    logger.info("⚙️  Creating user_subscription_stats table and triggers...")

    try:
        with engine.connect() as conn:
            # CREATE TABLE user_subscription_stats
            # This table maintains pre-calculated statistics updated by triggers
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS user_subscription_stats (
                    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
                    new_events_count INTEGER DEFAULT 0 NOT NULL,
                    total_events_count INTEGER DEFAULT 0 NOT NULL,
                    subscribers_count INTEGER DEFAULT 0 NOT NULL,
                    last_event_date TIMESTAMP WITH TIME ZONE,
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
                );
            """))
            logger.info("  ✓ Created user_subscription_stats table")

            # TRIGGER 1: Update stats when event is created
            conn.execute(text("""
                CREATE OR REPLACE FUNCTION update_stats_on_event_insert()
                RETURNS TRIGGER AS $$
                BEGIN
                    INSERT INTO user_subscription_stats (
                        user_id,
                        total_events_count,
                        new_events_count,
                        subscribers_count,
                        last_event_date,
                        updated_at
                    )
                    VALUES (
                        NEW.owner_id,
                        1,
                        CASE WHEN NEW.created_at > NOW() - INTERVAL '7 days' THEN 1 ELSE 0 END,
                        0,
                        NEW.created_at,
                        NOW()
                    )
                    ON CONFLICT (user_id) DO UPDATE SET
                        total_events_count = user_subscription_stats.total_events_count + 1,
                        new_events_count = CASE
                            WHEN NEW.created_at > NOW() - INTERVAL '7 days'
                            THEN user_subscription_stats.new_events_count + 1
                            ELSE user_subscription_stats.new_events_count
                        END,
                        last_event_date = GREATEST(user_subscription_stats.last_event_date, NEW.created_at),
                        updated_at = NOW();

                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER event_insert_stats_trigger
                AFTER INSERT ON events
                FOR EACH ROW
                EXECUTE FUNCTION update_stats_on_event_insert();
            """))

            # TRIGGER 2: Update stats when event is deleted
            conn.execute(text("""
                CREATE OR REPLACE FUNCTION update_stats_on_event_delete()
                RETURNS TRIGGER AS $$
                BEGIN
                    UPDATE user_subscription_stats
                    SET total_events_count = GREATEST(0, total_events_count - 1),
                        new_events_count = CASE
                            WHEN OLD.created_at > NOW() - INTERVAL '7 days'
                            THEN GREATEST(0, new_events_count - 1)
                            ELSE new_events_count
                        END,
                        updated_at = NOW()
                    WHERE user_id = OLD.owner_id;

                    RETURN OLD;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER event_delete_stats_trigger
                AFTER DELETE ON events
                FOR EACH ROW
                EXECUTE FUNCTION update_stats_on_event_delete();
            """))

            # TRIGGER 3: Update subscriber count on subscription
            conn.execute(text("""
                CREATE OR REPLACE FUNCTION update_stats_on_subscription()
                RETURNS TRIGGER AS $$
                DECLARE
                    event_owner_id INTEGER;
                BEGIN
                    SELECT owner_id INTO event_owner_id
                    FROM events
                    WHERE id = NEW.event_id;

                    IF event_owner_id IS NOT NULL AND NEW.interaction_type = 'subscribed' THEN
                        INSERT INTO user_subscription_stats (
                            user_id,
                            total_events_count,
                            new_events_count,
                            subscribers_count,
                            updated_at
                        )
                        VALUES (event_owner_id, 0, 0, 1, NOW())
                        ON CONFLICT (user_id) DO UPDATE SET
                            subscribers_count = user_subscription_stats.subscribers_count + 1,
                            updated_at = NOW();
                    END IF;

                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER subscription_insert_stats_trigger
                AFTER INSERT ON event_interactions
                FOR EACH ROW
                WHEN (NEW.interaction_type = 'subscribed')
                EXECUTE FUNCTION update_stats_on_subscription();
            """))

            # TRIGGER 4: Update subscriber count on unsubscription
            conn.execute(text("""
                CREATE OR REPLACE FUNCTION update_stats_on_unsubscription()
                RETURNS TRIGGER AS $$
                DECLARE
                    event_owner_id INTEGER;
                BEGIN
                    SELECT owner_id INTO event_owner_id
                    FROM events
                    WHERE id = OLD.event_id;

                    IF event_owner_id IS NOT NULL AND OLD.interaction_type = 'subscribed' THEN
                        UPDATE user_subscription_stats
                        SET subscribers_count = GREATEST(0, subscribers_count - 1),
                            updated_at = NOW()
                        WHERE user_id = event_owner_id;
                    END IF;

                    RETURN OLD;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER subscription_delete_stats_trigger
                AFTER DELETE ON event_interactions
                FOR EACH ROW
                WHEN (OLD.interaction_type = 'subscribed')
                EXECUTE FUNCTION update_stats_on_unsubscription();
            """))

            # Create indexes for performance
            conn.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_user_stats_updated ON user_subscription_stats(updated_at);
                CREATE INDEX IF NOT EXISTS idx_user_stats_user_id ON user_subscription_stats(user_id);
            """))

            # Set REPLICA IDENTITY for realtime CDC
            conn.execute(text("""
                ALTER TABLE user_subscription_stats REPLICA IDENTITY FULL;
                GRANT SELECT, INSERT, UPDATE, DELETE ON user_subscription_stats TO postgres;
                GRANT SELECT, INSERT, UPDATE, DELETE ON user_subscription_stats TO anon;
                GRANT SELECT, INSERT, UPDATE, DELETE ON user_subscription_stats TO authenticated;
            """))

            # Initialize stats from existing data
            conn.execute(text("""
                INSERT INTO user_subscription_stats (user_id, total_events_count, new_events_count, subscribers_count, last_event_date, updated_at)
                SELECT
                    u.id as user_id,
                    COALESCE(e.total_events, 0) as total_events_count,
                    COALESCE(e.new_events, 0) as new_events_count,
                    COALESCE(s.subscribers, 0) as subscribers_count,
                    e.last_event,
                    NOW()
                FROM users u
                LEFT JOIN (
                    SELECT owner_id,
                           COUNT(*) as total_events,
                           COUNT(CASE WHEN created_at > NOW() - INTERVAL '7 days' THEN 1 END) as new_events,
                           MAX(created_at) as last_event
                    FROM events
                    GROUP BY owner_id
                ) e ON u.id = e.owner_id
                LEFT JOIN (
                    SELECT e.owner_id, COUNT(DISTINCT ei.user_id) as subscribers
                    FROM events e
                    JOIN event_interactions ei ON e.id = ei.event_id
                    WHERE ei.interaction_type = 'subscribed'
                    GROUP BY e.owner_id
                ) s ON u.id = s.owner_id
                ON CONFLICT (user_id) DO NOTHING;
            """))

            conn.commit()

        logger.info("✅ user_subscription_stats table and triggers created successfully")

    except Exception as e:
        logger.error(f"❌ Error creating user_subscription_stats: {e}")
        raise


def grant_supabase_permissions():
    """
    Grant necessary permissions to postgres user on Supabase-managed schemas.
    This fixes permission errors when Supabase services try to run migrations.
    """
    logger.info("🔐 Granting permissions on Supabase schemas...")

    try:
        # This logic is now handled by /database/init/01_init.sql
        # which runs on DB startup before any services connect.
        pass
        logger.info("✅ Permissions handled by initial SQL scripts.")

    except Exception as e:
        logger.error(f"❌ Error granting permissions: {e}")
        # Don't raise - this is not critical for core functionality
        logger.warning("⚠️  Some Supabase services may have permission issues")


def insert_sample_data():
    """Insert sample data based on DATOS.txt"""
    logger.info("📊 Inserting sample data...")

    db = SessionLocal()
    try:
        now = datetime.now()

        # Date references - all events will be in the future starting from tomorrow
        tomorrow = now + timedelta(days=1)
        in_2_days = now + timedelta(days=2)
        in_3_days = now + timedelta(days=3)
        in_5_days = now + timedelta(days=5)
        in_7_days = now + timedelta(days=7)
        in_10_days = now + timedelta(days=10)
        in_14_days = now + timedelta(days=14)
        in_21_days = now + timedelta(days=21)
        in_30_days = now + timedelta(days=30)
        in_45_days = now + timedelta(days=45)
        in_60_days = now + timedelta(days=60)
        in_90_days = now + timedelta(days=90)
        in_120_days = now + timedelta(days=120)

        # 1. Create contacts
        contact_sonia = Contact(name="Sonia", phone="+34606014680")
        contact_miquel = Contact(name="Miquel", phone="+34626034421")
        contact_ada = Contact(name="Ada", phone="+34623949193")
        contact_sara = Contact(name="Sara", phone="+34611223344")
        contact_tdb = Contact(name="TDB", phone="+34600000001")
        contact_polr = Contact(name="PolR", phone="+34600000002")

        db.add_all([contact_sonia, contact_miquel, contact_ada, contact_sara, contact_tdb, contact_polr])
        db.flush()
        logger.info(f"  ✓ Inserted 6 contacts")

        # 2. Create users
        sonia = User(
            contact_id=contact_sonia.id,
            auth_provider="phone",
            auth_id=contact_sonia.phone,
            is_public=False,
            last_login=now,
        )
        miquel = User(
            contact_id=contact_miquel.id,
            auth_provider="phone",
            auth_id=contact_miquel.phone,
            is_public=False,
            last_login=now,
        )
        ada = User(
            contact_id=contact_ada.id,
            auth_provider="phone",
            auth_id=contact_ada.phone,
            is_public=False,
            last_login=now,
        )
        sara = User(
            contact_id=contact_sara.id,
            auth_provider="phone",
            auth_id=contact_sara.phone,
            is_public=False,
            last_login=now,
        )
        tdb = User(
            contact_id=contact_tdb.id,
            auth_provider="phone",
            auth_id=contact_tdb.phone,
            is_public=False,
            last_login=now,
        )
        polr = User(
            contact_id=contact_polr.id,
            auth_provider="phone",
            auth_id=contact_polr.phone,
            is_public=False,
            last_login=now,
        )
        fcbarcelona = User(
            username="fcbarcelona",
            auth_provider="instagram",
            auth_id="ig_fcbarcelona",
            is_public=True,
            profile_picture_url="https://example.com/fcb-logo.png",
            last_login=now,
        )

        # Create public users for subscriptions
        contact_gym = Contact(
            name="Gimnasio FitZone",
            phone="+34900111222",
        )
        contact_restaurant = Contact(
            name="Restaurante El Buen Sabor",
            phone="+34900333444",
        )
        contact_cultural = Contact(
            name="Centro Cultural La Llotja",
            phone="+34900555666",
        )

        db.add_all([contact_gym, contact_restaurant, contact_cultural])
        db.flush()

        gym_fitzone = User(
            username="fitzone_bcn",
            auth_provider="instagram",
            auth_id="ig_fitzone",
            is_public=True,
            contact_id=contact_gym.id,
            profile_picture_url="https://example.com/gym-logo.png",
            last_login=now,
        )
        restaurant_sabor = User(
            username="elbuen_sabor",
            auth_provider="instagram",
            auth_id="ig_restaurant",
            is_public=True,
            contact_id=contact_restaurant.id,
            profile_picture_url="https://example.com/restaurant-logo.png",
            last_login=now,
        )
        cultural_llotja = User(
            username="llotja_cultural",
            auth_provider="instagram",
            auth_id="ig_cultural",
            is_public=True,
            contact_id=contact_cultural.id,
            profile_picture_url="https://example.com/cultural-logo.png",
            last_login=now,
        )

        db.add_all([sonia, miquel, ada, sara, tdb, polr, fcbarcelona, gym_fitzone, restaurant_sabor, cultural_llotja])
        db.flush()
        logger.info(f"  ✓ Inserted 10 users (3 public venues)")

        # 3. Create calendars
        cal_family = Calendar(owner_id=sonia.id, name="Family")
        cal_birthdays = Calendar(owner_id=sonia.id, name="Cumpleaños Family")
        cal_esqui_temporal = Calendar(owner_id=sonia.id, name="Temporada Esquí 2025-2026", start_date=in_30_days, end_date=in_120_days)

        db.add_all([cal_family, cal_birthdays, cal_esqui_temporal])
        db.flush()
        logger.info(f"  ✓ Inserted 3 calendars (2 permanent, 1 temporal)")

        # 4. Create calendar memberships
        membership_sonia_family = CalendarMembership(
            calendar_id=cal_family.id,
            user_id=sonia.id,
            role="owner",
            status="accepted",
        )
        membership_sonia_birthdays = CalendarMembership(
            calendar_id=cal_birthdays.id,
            user_id=sonia.id,
            role="owner",
            status="accepted",
        )
        membership_miquel_birthdays = CalendarMembership(
            calendar_id=cal_birthdays.id,
            user_id=miquel.id,
            role="admin",
            status="accepted",
            invited_by_user_id=sonia.id,
        )
        membership_miquel_family = CalendarMembership(
            calendar_id=cal_family.id,
            user_id=miquel.id,
            role="admin",
            status="accepted",
            invited_by_user_id=sonia.id,
        )

        db.add_all([membership_sonia_family, membership_sonia_birthdays, membership_miquel_birthdays, membership_miquel_family])
        db.flush()
        logger.info(f"  ✓ Inserted 4 calendar memberships")

        # 5. Create recurring event configs (base events)
        # These are the "template" events for recurring series
        recurring_sincro = Event(
            name="Sincro",
            description="Evento recurrente Sincro",
            start_date=in_10_days.replace(hour=17, minute=30),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )
        recurring_dj = Event(
            name="DJ",
            description="Evento recurrente DJ",
            start_date=in_10_days.replace(hour=17, minute=30),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )
        recurring_baile = Event(
            name="Baile KDN",
            description="Evento recurrente Baile KDN",
            start_date=in_10_days.replace(hour=17, minute=30),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )
        recurring_esqui = Event(
            name="Esquí temporada 2025-2026",
            description="Esquí semanal temporada 2025-2026",
            start_date=(in_30_days + timedelta(days=13)).replace(hour=8, minute=0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_esqui_temporal.id,  # Usar calendario temporal
        )

        db.add_all([recurring_sincro, recurring_dj, recurring_baile, recurring_esqui])
        db.flush()
        logger.info(f"  ✓ Inserted 4 base recurring events")

        # 6. Create recurring event configs
        config_sincro = RecurringEventConfig(
            event_id=recurring_sincro.id,
            recurrence_type="weekly",
            schedule=[
                {"day": 0, "day_name": "Lunes", "time": "17:30"},
                {"day": 2, "day_name": "Miércoles", "time": "17:30"},
            ],
            recurrence_end_date=datetime(2026, 6, 23),
        )
        config_dj = RecurringEventConfig(
            event_id=recurring_dj.id,
            recurrence_type="weekly",
            schedule=[
                {"day": 4, "day_name": "Viernes", "time": "17:30"},
            ],
            recurrence_end_date=datetime(2026, 6, 23),
        )
        config_baile = RecurringEventConfig(
            event_id=recurring_baile.id,
            recurrence_type="weekly",
            schedule=[
                {"day": 3, "day_name": "Jueves", "time": "17:30"},
            ],
            recurrence_end_date=datetime(2026, 6, 23),
        )
        config_esqui = RecurringEventConfig(
            event_id=recurring_esqui.id,
            recurrence_type="weekly",
            schedule=[
                {"day": 5, "day_name": "Sábado", "time": "08:00"},
            ],
            recurrence_end_date=datetime(2026, 3, 30),
        )

        db.add_all([config_sincro, config_dj, config_baile, config_esqui])
        db.flush()
        logger.info(f"  ✓ Inserted 4 recurring configs")

        # 7. Pre-generate recurring event instances
        def generate_instances(base_event, config):
            """Helper function to generate instances for a recurring event"""
            instances = []

            # Create a map of day -> time from schedule
            day_time_map = {}
            for schedule_item in config.schedule:
                day = schedule_item["day"]
                time = schedule_item["time"]
                day_time_map[day] = time

            current_date = base_event.start_date.date()  # Just the date part

            while current_date <= config.recurrence_end_date.date():
                weekday = current_date.weekday()
                if weekday in day_time_map:
                    # Parse the time for this weekday
                    time_str = day_time_map[weekday]
                    hour, minute = map(int, time_str.split(":"))

                    instance_datetime = datetime.combine(current_date, datetime.min.time())
                    instance_datetime = instance_datetime.replace(hour=hour, minute=minute)

                    instance = Event(
                        name=base_event.name,
                        description=base_event.description,
                        start_date=instance_datetime,
                        event_type="regular",
                        owner_id=base_event.owner_id,
                        calendar_id=base_event.calendar_id,
                        parent_recurring_event_id=config.id,
                    )
                    instances.append(instance)
                current_date += timedelta(days=1)

            return instances

        # Generate all recurring event instances
        sincro_instances = generate_instances(recurring_sincro, config_sincro)
        dj_instances = generate_instances(recurring_dj, config_dj)
        baile_instances = generate_instances(recurring_baile, config_baile)
        esqui_instances = generate_instances(recurring_esqui, config_esqui)

        all_instances = sincro_instances + dj_instances + baile_instances + esqui_instances
        db.add_all(all_instances)
        db.flush()
        logger.info(f"  ✓ Generated {len(all_instances)} recurring event instances")

        # 8. Create birthday events in "Cumpleaños Family" calendar
        # Estos son eventos recurrentes anuales perpetuos (sin fecha fin)
        bday_miquel = Event(
            name="Cumpleaños de Miquel",
            description="Cumpleaños de Miquel (30 de abril)",
            start_date=in_120_days.replace(hour=0, minute=0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_birthdays.id,
        )
        bday_ada = Event(
            name="Cumpleaños de Ada",
            description="Cumpleaños de Ada (6 de septiembre)",
            start_date=(in_120_days + timedelta(days=120)).replace(hour=0, minute=0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_birthdays.id,
        )
        bday_sonia = Event(
            name="Cumpleaños de Sonia",
            description="Cumpleaños de Sonia (31 de enero)",
            start_date=in_90_days.replace(hour=0, minute=0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_birthdays.id,
        )
        bday_sara = Event(
            name="Cumpleaños de Sara",
            description="Cumpleaños de Sara (2 de diciembre)",
            start_date=(in_120_days + timedelta(days=240)).replace(hour=0, minute=0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_birthdays.id,
        )

        db.add_all([bday_miquel, bday_ada, bday_sonia, bday_sara])
        db.flush()
        logger.info(f"  ✓ Inserted 4 birthday recurring events (yearly, perpetual)")

        # Create recurring configs for birthdays (yearly, perpetual = no end date)
        config_bday_miquel = RecurringEventConfig(
            event_id=bday_miquel.id,
            recurrence_type="yearly",
            schedule=[{"month": 4, "day_of_month": 30}],
            recurrence_end_date=None,  # Perpetuo
        )
        config_bday_ada = RecurringEventConfig(
            event_id=bday_ada.id,
            recurrence_type="yearly",
            schedule=[{"month": 9, "day_of_month": 6}],
            recurrence_end_date=None,  # Perpetuo
        )
        config_bday_sonia = RecurringEventConfig(
            event_id=bday_sonia.id,
            recurrence_type="yearly",
            schedule=[{"month": 1, "day_of_month": 31}],
            recurrence_end_date=None,  # Perpetuo
        )
        config_bday_sara = RecurringEventConfig(
            event_id=bday_sara.id,
            recurrence_type="yearly",
            schedule=[{"month": 12, "day_of_month": 2}],
            recurrence_end_date=None,  # Perpetuo
        )

        db.add_all([config_bday_miquel, config_bday_ada, config_bday_sonia, config_bday_sara])
        db.flush()
        logger.info(f"  ✓ Inserted 4 birthday recurring configs (yearly, perpetual)")

        # 8.5. Crear más eventos recurrentes para demostrar TODOS los tipos
        # DAILY: Medicación diaria
        recurring_medicacion = Event(
            name="Tomar medicación",
            description="Recordatorio diario de medicación",
            start_date=in_7_days.replace(hour=9, minute=0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )

        # MONTHLY: Pago de alquiler (día 1 de cada mes)
        recurring_alquiler = Event(
            name="Pago de alquiler",
            description="Pago mensual del alquiler",
            start_date=in_7_days.replace(hour=10, minute=0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )

        # MONTHLY: Reunión de equipo (días 5 y 20 de cada mes)
        recurring_reunion = Event(
            name="Reunión de equipo",
            description="Reuniones quincenales del equipo",
            start_date=in_14_days.replace(hour=15, minute=0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )

        # YEARLY: Navidad (perpetuo)
        recurring_navidad = Event(
            name="Navidad",
            description="Celebración de Navidad",
            start_date=(in_30_days + timedelta(days=25)).replace(hour=0, minute=0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )

        db.add_all([recurring_medicacion, recurring_alquiler, recurring_reunion, recurring_navidad])
        db.flush()
        logger.info(f"  ✓ Inserted 4 additional recurring events (daily, monthly, yearly)")

        # Configs para los nuevos eventos recurrentes
        config_medicacion = RecurringEventConfig(
            event_id=recurring_medicacion.id,
            recurrence_type="daily",
            schedule=[{"interval_days": 1}],  # Cada día
            recurrence_end_date=datetime(2026, 12, 31),  # Termina fin de 2026
        )

        config_alquiler = RecurringEventConfig(
            event_id=recurring_alquiler.id,
            recurrence_type="monthly",
            schedule=[{"day_of_month": 1}],  # Día 1 de cada mes
            recurrence_end_date=None,  # Perpetuo
        )

        config_reunion = RecurringEventConfig(
            event_id=recurring_reunion.id,
            recurrence_type="monthly",
            schedule=[{"day_of_month": 5}, {"day_of_month": 20}],  # Día 5 de cada mes  # Día 20 de cada mes
            recurrence_end_date=datetime(2026, 12, 31),
        )

        config_navidad = RecurringEventConfig(
            event_id=recurring_navidad.id,
            recurrence_type="yearly",
            schedule=[{"month": 12, "day_of_month": 25}],  # 25 de diciembre cada año
            recurrence_end_date=None,  # Perpetuo
        )

        db.add_all([config_medicacion, config_alquiler, config_reunion, config_navidad])
        db.flush()
        logger.info(f"  ✓ Inserted 4 additional recurring configs (daily, monthly, yearly)")

        # 9. Create regular events
        event_katy_perry = Event(
            name="Concierto de Katy Perry",
            description="Lugar: Palau Sant Jordi, Barcelona",
            start_date=in_21_days.replace(hour=20, minute=0),
            event_type="regular",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )
        event_festa_codony = Event(
            name="Festa del Codony",
            description="Lugar: Tremp",
            start_date=in_7_days.replace(hour=9, minute=0),
            event_type="regular",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )

        db.add_all([event_katy_perry, event_festa_codony])
        db.flush()
        logger.info(f"  ✓ Inserted 2 regular events")

        # 10. Create FC Barcelona match events with descriptions
        # El Clásico - saved as variable for later reference in invitations
        fcb_el_clasico = Event(
            name="Real Madrid vs FC Barcelona",
            description="🏟️ Santiago Bernabéu • LaLiga EA Sports • El Clásico",
            start_date=in_3_days.replace(hour=16, minute=15),
            event_type="regular",
            owner_id=fcbarcelona.id
        )

        fcb_matches = [
            Event(name="FC Barcelona vs Girona", description="🏟️ Spotify Camp Nou • LaLiga EA Sports", start_date=tomorrow.replace(hour=16, minute=15), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Olympiakos", description="🏟️ Spotify Camp Nou • UEFA Champions League", start_date=in_2_days.replace(hour=18, minute=45), event_type="regular", owner_id=fcbarcelona.id),
            fcb_el_clasico,
            Event(name="FC Barcelona vs Elche", description="🏟️ Spotify Camp Nou • Copa del Rey", start_date=in_5_days.replace(hour=18, minute=30), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Club Brugge vs FC Barcelona", description="🏟️ Jan Breydel Stadium • UEFA Champions League", start_date=in_7_days.replace(hour=21, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Celta de Vigo vs FC Barcelona", description="🏟️ Estadio de Balaídos • LaLiga EA Sports", start_date=in_10_days.replace(hour=21, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Athletic Club", description="🏟️ Spotify Camp Nou • LaLiga EA Sports", start_date=in_21_days.replace(hour=18, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Chelsea vs FC Barcelona", description="🏟️ Stamford Bridge • UEFA Champions League", start_date=(in_21_days + timedelta(days=2)).replace(hour=21, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Alavés", description="🏟️ Spotify Camp Nou • LaLiga EA Sports", start_date=in_30_days.replace(hour=18, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Real Betis vs FC Barcelona", description="🏟️ Benito Villamarín • LaLiga EA Sports", start_date=(in_30_days + timedelta(days=7)).replace(hour=18, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Eintracht Frankfurt", description="🏟️ Spotify Camp Nou • UEFA Champions League", start_date=(in_30_days + timedelta(days=9)).replace(hour=21, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Osasuna", description="🏟️ Spotify Camp Nou • LaLiga EA Sports", start_date=(in_30_days + timedelta(days=14)).replace(hour=18, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Villarreal vs FC Barcelona", description="🏟️ Estadio de la Cerámica • LaLiga EA Sports", start_date=(in_30_days + timedelta(days=21)).replace(hour=18, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Espanyol vs FC Barcelona", description="🏟️ RCDE Stadium • LaLiga EA Sports • Derby Barceloní", start_date=in_60_days.replace(hour=18, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Athletic Club", description="🏟️ Spotify Camp Nou • Copa del Rey", start_date=(in_60_days + timedelta(days=3)).replace(hour=20, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Atlético Madrid", description="🏟️ Spotify Camp Nou • LaLiga EA Sports", start_date=(in_60_days + timedelta(days=7)).replace(hour=18, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Real Sociedad vs FC Barcelona", description="🏟️ Reale Arena • LaLiga EA Sports", start_date=(in_60_days + timedelta(days=14)).replace(hour=18, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Real Oviedo", description="🏟️ Spotify Camp Nou • Copa del Rey", start_date=(in_60_days + timedelta(days=21)).replace(hour=18, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Slavia Prague vs FC Barcelona", description="🏟️ Fortuna Arena • UEFA Champions League", start_date=(in_60_days + timedelta(days=17)).replace(hour=18, minute=0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs FC København", description="🏟️ Spotify Camp Nou • UEFA Champions League", start_date=(in_60_days + timedelta(days=24)).replace(hour=18, minute=0), event_type="regular", owner_id=fcbarcelona.id),
        ]
        db.add_all(fcb_matches)
        db.flush()
        logger.info(f"  ✓ Inserted 20 FC Barcelona match events")

        # 11. Create Sonia's additional events
        event_cumple_sara_clase = Event(
            name="Cumpleaños clase Sara",
            description="Celebración del cumpleaños de la clase de Sara",
            start_date=datetime(2025, 11, 16, 17, 0),
            event_type="regular",
            owner_id=sonia.id,
        )

        recurring_promociona_madrid = Event(
            name="Promociona Madrid",
            description="Evento promocional diario",
            start_date=datetime(2025, 11, 16, 9, 0),
            event_type="recurring",
            owner_id=sonia.id,
        )

        event_compra_semanal = Event(
            name="Compra semanal sábado",
            description="Compra semanal en el supermercado",
            start_date=datetime(2025, 10, 25, 10, 0),
            event_type="regular",
            owner_id=sonia.id,
        )

        db.add_all([event_cumple_sara_clase, recurring_promociona_madrid, event_compra_semanal])
        db.flush()

        # Create recurring config for Promociona Madrid
        config_promociona = RecurringEventConfig(
            event_id=recurring_promociona_madrid.id,
            recurrence_type="weekly",
            schedule=[
                {"day": 0, "day_name": "Lunes", "time": "09:00"},
                {"day": 1, "day_name": "Martes", "time": "09:00"},
                {"day": 2, "day_name": "Miércoles", "time": "09:00"},
                {"day": 3, "day_name": "Jueves", "time": "09:00"},
                {"day": 4, "day_name": "Viernes", "time": "09:00"},
                {"day": 5, "day_name": "Sábado", "time": "09:00"},
                {"day": 6, "day_name": "Domingo", "time": "09:00"},
            ],
            recurrence_end_date=datetime(2025, 11, 21, 23, 59),
        )
        db.add(config_promociona)
        db.flush()

        # Generate instances for Promociona Madrid (Nov 16-21, 6 days)
        promociona_instances = generate_instances(recurring_promociona_madrid, config_promociona)
        db.add_all(promociona_instances)
        db.flush()
        logger.info(f"  ✓ Inserted 2 additional Sonia events (1 regular + 1 recurring with {len(promociona_instances)} instances)")

        # 12. Create events for Miquel (user 2)
        miquel_gym = Event(
            name="Gimnasio",
            description="Sesión de entrenamiento en el gimnasio",
            start_date=datetime(2025, 10, 28, 7, 0),
            event_type="regular",
            owner_id=miquel.id,
        )
        miquel_dentist = Event(
            name="Dentista",
            description="Revisión dental anual",
            start_date=datetime(2025, 11, 5, 10, 30),
            event_type="regular",
            owner_id=miquel.id,
        )
        miquel_dinner = Event(
            name="Cena con amigos",
            description="Cena en restaurante japonés",
            start_date=datetime(2025, 11, 8, 21, 0),
            event_type="regular",
            owner_id=miquel.id,
        )
        miquel_meeting = Event(
            name="Reunión de proyecto",
            description="Revisión trimestral del proyecto",
            start_date=datetime(2025, 11, 12, 16, 0),
            event_type="regular",
            owner_id=miquel.id,
        )
        miquel_weekend = Event(
            name="Escapada fin de semana",
            description="Viaje a la montaña",
            start_date=datetime(2025, 11, 15, 9, 0),
            event_type="regular",
            owner_id=miquel.id,
        )

        db.add_all([miquel_gym, miquel_dentist, miquel_dinner, miquel_meeting, miquel_weekend])
        db.flush()
        logger.info(f"  ✓ Inserted 5 events for Miquel")

        # 13. Create events for Ada (user 3)
        ada_school = Event(
            name="Presentación escolar",
            description="Presentación de ciencias naturales",
            start_date=datetime(2025, 10, 30, 10, 0),
            event_type="regular",
            owner_id=ada.id,
        )
        ada_ballet = Event(
            name="Clase de ballet",
            description="Clase de ballet clásico",
            start_date=in_7_days.replace(hour=17, minute=0),
            event_type="regular",
            owner_id=ada.id,
        )
        ada_party = Event(
            name="Fiesta de Halloween",
            description="Fiesta de disfraces con amigos",
            start_date=datetime(2025, 10, 31, 18, 0),
            event_type="regular",
            owner_id=ada.id,
        )
        ada_swimming = Event(
            name="Natación",
            description="Entrenamiento de natación",
            start_date=in_14_days.replace(hour=16, minute=30),
            event_type="regular",
            owner_id=ada.id,
        )
        ada_movie = Event(
            name="Cine con familia",
            description="Ver nueva película de animación",
            start_date=in_21_days.replace(hour=17, minute=30),
            event_type="regular",
            owner_id=ada.id,
        )

        db.add_all([ada_school, ada_ballet, ada_party, ada_swimming, ada_movie])
        db.flush()
        logger.info(f"  ✓ Inserted 5 events for Ada")

        # 14. Create events for Sara (user 4)
        sara_work = Event(
            name="Reunión de equipo",
            description="Planificación sprint Q4",
            start_date=datetime(2025, 10, 29, 9, 30),
            event_type="regular",
            owner_id=sara.id,
        )
        sara_lunch = Event(
            name="Almuerzo con cliente",
            description="Presentación de propuesta",
            start_date=datetime(2025, 11, 4, 13, 0),
            event_type="regular",
            owner_id=sara.id,
        )
        sara_yoga = Event(
            name="Yoga",
            description="Clase de yoga y meditación",
            start_date=datetime(2025, 11, 6, 19, 0),
            event_type="regular",
            owner_id=sara.id,
        )
        sara_conference = Event(
            name="Conferencia tech",
            description="Conferencia de desarrollo web",
            start_date=datetime(2025, 11, 13, 9, 0),
            event_type="regular",
            owner_id=sara.id,
        )
        sara_brunch = Event(
            name="Brunch dominical",
            description="Brunch con amigas en el centro",
            start_date=datetime(2025, 11, 17, 11, 0),
            event_type="regular",
            owner_id=sara.id,
        )

        db.add_all([sara_work, sara_lunch, sara_yoga, sara_conference, sara_brunch])
        db.flush()
        logger.info(f"  ✓ Inserted 5 events for Sara")

        # 15. Create events for public users
        # Gimnasio FitZone events
        gym_spinning = Event(
            name="Clase de Spinning",
            description="Clase intensiva de spinning - Nivel intermedio",
            start_date=datetime(2025, 10, 28, 18, 0),
            event_type="regular",
            owner_id=gym_fitzone.id,
        )
        gym_yoga_morning = Event(
            name="Yoga matinal",
            description="Sesión de yoga para comenzar el día con energía",
            start_date=datetime(2025, 11, 1, 7, 30),
            event_type="regular",
            owner_id=gym_fitzone.id,
        )
        gym_crossfit = Event(
            name="CrossFit Challenge",
            description="Desafío mensual de CrossFit - Todos los niveles",
            start_date=datetime(2025, 11, 8, 19, 0),
            event_type="regular",
            owner_id=gym_fitzone.id,
        )
        gym_pilates = Event(
            name="Pilates para principiantes",
            description="Introducción al método Pilates",
            start_date=in_30_days.replace(hour=10, minute=0),
            event_type="regular",
            owner_id=gym_fitzone.id,
        )
        gym_zumba = Event(
            name="Zumba Party - Edición Especial",
            description="Clase especial de Zumba con DJ en vivo. ¡Ven a bailar y sudar! Abierto a todos los niveles.",
            start_date=in_14_days.replace(hour=19, minute=30),
            event_type="regular",
            owner_id=gym_fitzone.id,
        )

        # Restaurante El Buen Sabor events
        restaurant_tasting = Event(
            name="Degustación de vinos",
            description="Cata de vinos de la Rioja con maridaje",
            start_date=datetime(2025, 10, 30, 20, 0),
            event_type="regular",
            owner_id=restaurant_sabor.id,
        )
        restaurant_cooking = Event(
            name="Taller de cocina mediterránea",
            description="Aprende a cocinar platos mediterráneos tradicionales",
            start_date=in_14_days.replace(hour=18, minute=30),
            event_type="regular",
            owner_id=restaurant_sabor.id,
        )
        restaurant_brunch = Event(
            name="Brunch especial domingo",
            description="Brunch buffet con opciones veganas y sin gluten",
            start_date=in_21_days.replace(hour=11, minute=0),
            event_type="regular",
            owner_id=restaurant_sabor.id,
        )

        # Centro Cultural La Llotja events
        cultural_concert = Event(
            name="Concierto de jazz",
            description="Trio de jazz en vivo - Entrada libre",
            start_date=in_7_days.replace(hour=20, minute=30),
            event_type="regular",
            owner_id=cultural_llotja.id,
        )
        cultural_expo = Event(
            name="Exposición de arte contemporáneo",
            description="Inauguración: Artistas emergentes de Barcelona",
            start_date=in_14_days.replace(hour=19, minute=0),
            event_type="regular",
            owner_id=cultural_llotja.id,
        )
        cultural_theater = Event(
            name="Obra de teatro: Hamlet",
            description="Adaptación moderna del clásico de Shakespeare",
            start_date=in_30_days.replace(hour=21, minute=0),
            event_type="regular",
            owner_id=cultural_llotja.id,
        )
        cultural_workshop = Event(
            name="Taller de fotografía",
            description="Técnicas básicas de fotografía urbana",
            start_date=in_45_days.replace(hour=17, minute=0),
            event_type="regular",
            owner_id=cultural_llotja.id,
        )

        db.add_all([
            gym_spinning, gym_yoga_morning, gym_crossfit, gym_pilates, gym_zumba,
            restaurant_tasting, restaurant_cooking, restaurant_brunch,
            cultural_concert, cultural_expo, cultural_theater, cultural_workshop
        ])
        db.flush()
        logger.info(f"  ✓ Inserted 12 events for public venues (5 gym, 3 restaurant, 4 cultural)")

        # 16. Create shared family events
        family_dinner = Event(
            name="Cena familiar",
            description="Cena mensual en casa de los abuelos",
            start_date=in_21_days.replace(hour=20, minute=0),
            event_type="regular",
            owner_id=sonia.id,
        )
        family_picnic = Event(
            name="Picnic familiar",
            description="Picnic en el parque",
            start_date=in_21_days.replace(hour=12, minute=0),
            event_type="regular",
            owner_id=miquel.id,
        )
        family_trip = Event(
            name="Viaje familiar a la playa",
            description="Fin de semana en la costa",
            start_date=in_60_days.replace(hour=10, minute=0),
            event_type="regular",
            owner_id=sonia.id,
        )

        db.add_all([family_dinner, family_picnic, family_trip])
        db.flush()
        logger.info(f"  ✓ Inserted 3 family events")

        # 16. Create event interactions
        interactions = []

        # Sonia owns all her recurring base events
        for event in [recurring_sincro, recurring_dj, recurring_baile, recurring_esqui]:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=sonia.id,
                    interaction_type="joined",
                    status="accepted",
                    role="owner",
                )
            )

        # Sonia owns all recurring instances
        for event in all_instances:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=sonia.id,
                    interaction_type="joined",
                    status="accepted",
                    role="owner",
                )
            )

        # Sonia owns all birthday events (recurring yearly perpetual)
        for event in [bday_miquel, bday_ada, bday_sonia, bday_sara]:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=sonia.id,
                    interaction_type="joined",
                    status="accepted",
                    role="owner",
                )
            )

        # Sonia owns all additional recurring events (daily, monthly, yearly)
        for event in [recurring_medicacion, recurring_alquiler, recurring_reunion, recurring_navidad]:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=sonia.id,
                    interaction_type="joined",
                    status="accepted",
                    role="owner",
                )
            )

        # Sonia owns regular events
        for event in [event_katy_perry, event_festa_codony]:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=sonia.id,
                    interaction_type="joined",
                    status="accepted",
                    role="owner",
                )
            )

        # FC Barcelona owns all their matches
        for event in fcb_matches:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=fcbarcelona.id,
                    interaction_type="joined",
                    status="accepted",
                    role="owner",
                )
            )

        # Miquel subscribed to all FC Barcelona matches (with notes on some)
        miquel_notes = {
            "FC Barcelona vs Girona": "Comprar entradas para Sector Gol Sud",
            "FC Barcelona vs Olympiakos": "Ir con Ada - Champions League 🏆",
            "Real Madrid vs FC Barcelona": "¡EL CLÁSICO! Reservar bar para verlo con amigos",
            "FC Barcelona vs Elche": None,
            "FC Barcelona vs Athletic Club": "Llevar bufanda del Barça",
        }

        for event in fcb_matches:
            note = miquel_notes.get(event.name)
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=miquel.id,
                    interaction_type="subscribed",
                    status="accepted",
                    note=note,
                )
            )

        # Sonia owns "Cumpleaños clase Sara"
        interactions.append(
            EventInteraction(
                event_id=event_cumple_sara_clase.id,
                user_id=sonia.id,
                interaction_type="joined",
                status="accepted",
                role="owner",
            )
        )

        # Miquel invited to "Cumpleaños clase Sara" (NEW - created recently)
        interactions.append(
            EventInteraction(
                event_id=event_cumple_sara_clase.id,
                user_id=miquel.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=sonia.id,
                created_at=datetime.now(),  # Makes this interaction "new" (is_new badge will show)
                read_at=None,  # Explicitly set as unread
            )
        )

        # Sonia owns "Compra semanal sábado"
        interactions.append(
            EventInteraction(
                event_id=event_compra_semanal.id,
                user_id=sonia.id,
                interaction_type="joined",
                status="accepted",
                role="owner",
            )
        )

        # Miquel is admin of "Compra semanal sábado"
        interactions.append(
            EventInteraction(
                event_id=event_compra_semanal.id,
                user_id=miquel.id,
                interaction_type="joined",
                status="accepted",
                role="admin",
                invited_by_user_id=sonia.id,
            )
        )

        # Sonia owns "Promociona Madrid" base event
        interactions.append(
            EventInteraction(
                event_id=recurring_promociona_madrid.id,
                user_id=sonia.id,
                interaction_type="joined",
                status="accepted",
                role="owner",
            )
        )

        # Sonia owns all "Promociona Madrid" instances
        for event in promociona_instances:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=sonia.id,
                    interaction_type="joined",
                    status="accepted",
                    role="owner",
                )
            )

        # Miquel invited to Esquí events (base + all instances)
        interactions.append(
            EventInteraction(
                event_id=recurring_esqui.id,
                user_id=miquel.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=sonia.id,
            )
        )
        for event in esqui_instances:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=miquel.id,
                    interaction_type="invited",
                    status="pending",
                    invited_by_user_id=sonia.id,
                )
            )

        # === INTERACTIONS FOR NEW USER EVENTS ===

        # Miquel owns his events
        for event in [miquel_gym, miquel_dentist, miquel_dinner, miquel_meeting, miquel_weekend]:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=miquel.id,
                    interaction_type="joined",
                    status="accepted",
                    role="owner",
                )
            )

        # Ada owns her events
        for event in [ada_school, ada_ballet, ada_party, ada_swimming, ada_movie]:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=ada.id,
                    interaction_type="joined",
                    status="accepted",
                    role="owner",
                )
            )

        # Sara owns her events
        for event in [sara_work, sara_lunch, sara_yoga, sara_conference, sara_brunch]:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=sara.id,
                    interaction_type="joined",
                    status="accepted",
                    role="owner",
                )
            )

        # === INVITATIONS TO MIQUEL'S EVENTS ===

        # Miquel's dinner - invites Sonia (accepted) and Sara (pending)
        interactions.extend([
            EventInteraction(
                event_id=miquel_dinner.id,
                user_id=sonia.id,
                interaction_type="invited",
                status="accepted",
                invited_by_user_id=miquel.id,
            ),
            EventInteraction(
                event_id=miquel_dinner.id,
                user_id=sara.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=miquel.id,
            ),
        ])

        # Miquel's meeting - invites Sara (accepted)
        interactions.append(
            EventInteraction(
                event_id=miquel_meeting.id,
                user_id=sara.id,
                interaction_type="invited",
                status="accepted",
                role="participant",
                invited_by_user_id=miquel.id,
            )
        )

        # === INVITATIONS TO ADA'S EVENTS ===

        # Ada's Halloween party - invites everyone
        interactions.extend([
            EventInteraction(
                event_id=ada_party.id,
                user_id=sonia.id,
                interaction_type="invited",
                status="accepted",
                invited_by_user_id=ada.id,
                note="Llevar disfraz de bruja 🧙‍♀️",
            ),
            EventInteraction(
                event_id=ada_party.id,
                user_id=miquel.id,
                interaction_type="invited",
                status="accepted",
                invited_by_user_id=ada.id,
            ),
            EventInteraction(
                event_id=ada_party.id,
                user_id=sara.id,
                interaction_type="invited",
                status="rejected",
                invited_by_user_id=ada.id,
                rejection_message="Lo siento, tengo otro compromiso ese día",
            ),
        ])

        # Ada's movie - invites family
        interactions.extend([
            EventInteraction(
                event_id=ada_movie.id,
                user_id=sonia.id,
                interaction_type="invited",
                status="accepted",
                invited_by_user_id=ada.id,
            ),
            EventInteraction(
                event_id=ada_movie.id,
                user_id=miquel.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=ada.id,
            ),
        ])

        # === INVITATIONS TO SARA'S EVENTS ===

        # Sara's brunch - invites Sonia (accepted)
        interactions.append(
            EventInteraction(
                event_id=sara_brunch.id,
                user_id=sonia.id,
                interaction_type="invited",
                status="accepted",
                invited_by_user_id=sara.id,
                note="¡Ganas de un brunch relajado! ☕",
            )
        )

        # Sara's yoga - invites Sonia (pending)
        interactions.append(
            EventInteraction(
                event_id=sara_yoga.id,
                user_id=sonia.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=sara.id,
            )
        )

        # Sara's work meeting - invites Sonia (pending)
        interactions.append(
            EventInteraction(
                event_id=sara_work.id,
                user_id=sonia.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=sara.id,
            )
        )

        # Sara's conference - invites Sonia (pending)
        interactions.append(
            EventInteraction(
                event_id=sara_conference.id,
                user_id=sonia.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=sara.id,
            )
        )

        # === PUBLIC VENUES INTERACTIONS ===

        # Gym FitZone owns their events
        for event in [gym_spinning, gym_yoga_morning, gym_crossfit, gym_pilates, gym_zumba]:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=gym_fitzone.id,
                    interaction_type="joined",
                    status="accepted",
                    role="owner",
                )
            )

        # Restaurant owns their events
        for event in [restaurant_tasting, restaurant_cooking, restaurant_brunch]:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=restaurant_sabor.id,
                    interaction_type="joined",
                    status="accepted",
                    role="owner",
                )
            )

        # Cultural center owns their events
        for event in [cultural_concert, cultural_expo, cultural_theater, cultural_workshop]:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=cultural_llotja.id,
                    interaction_type="joined",
                    status="accepted",
                    role="owner",
                )
            )

        # Sonia subscribed to Gym FitZone events
        for event in [gym_spinning, gym_yoga_morning, gym_crossfit, gym_pilates, gym_zumba]:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=sonia.id,
                    interaction_type="subscribed",
                    status="accepted",
                )
            )

        # Sonia subscribed to Restaurant events
        for event in [restaurant_tasting, restaurant_cooking, restaurant_brunch]:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=sonia.id,
                    interaction_type="subscribed",
                    status="accepted",
                )
            )

        # Sonia subscribed to Cultural center events
        for event in [cultural_concert, cultural_expo, cultural_theater, cultural_workshop]:
            interactions.append(
                EventInteraction(
                    event_id=event.id,
                    user_id=sonia.id,
                    interaction_type="subscribed",
                    status="accepted",
                )
            )

        # === MORE INVITATIONS FOR SONIA (PENDING) ===

        # Miquel's gym - invites Sonia (pending)
        interactions.append(
            EventInteraction(
                event_id=miquel_gym.id,
                user_id=sonia.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=miquel.id,
                note="¿Vienes al gym conmigo? 💪",
            )
        )

        # Miquel's weekend trip - invites Sonia (pending)
        interactions.append(
            EventInteraction(
                event_id=miquel_weekend.id,
                user_id=sonia.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=miquel.id,
            )
        )

        # Miquel invites Sonia to El Clásico (FC Barcelona event - public user event)
        # This tests "Attend Independently" button: Sonia can reject Miquel's invitation
        # but still attend the FC Barcelona event on her own
        interactions.append(
            EventInteraction(
                event_id=fcb_el_clasico.id,
                user_id=sonia.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=miquel.id,
                note="¡Vamos juntos al Clásico! Tengo entradas 🎫⚽",
            )
        )

        # Ada's ballet - invites Sonia (pending)
        interactions.append(
            EventInteraction(
                event_id=ada_ballet.id,
                user_id=sonia.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=ada.id,
                note="¡Mamá ven a ver mi clase de ballet! 🩰",
            )
        )

        # Ada's swimming - invites Sonia (pending)
        interactions.append(
            EventInteraction(
                event_id=ada_swimming.id,
                user_id=sonia.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=ada.id,
            )
        )

        # === FAMILY EVENTS INTERACTIONS ===

        # Family dinner - Sonia is owner, everyone else invited
        interactions.extend([
            EventInteraction(
                event_id=family_dinner.id,
                user_id=sonia.id,
                interaction_type="joined",
                status="accepted",
                role="owner",
            ),
            EventInteraction(
                event_id=family_dinner.id,
                user_id=miquel.id,
                interaction_type="invited",
                status="accepted",
                invited_by_user_id=sonia.id,
            ),
            EventInteraction(
                event_id=family_dinner.id,
                user_id=ada.id,
                interaction_type="invited",
                status="accepted",
                invited_by_user_id=sonia.id,
            ),
            EventInteraction(
                event_id=family_dinner.id,
                user_id=sara.id,
                interaction_type="invited",
                status="accepted",
                invited_by_user_id=sonia.id,
            ),
        ])

        # Family picnic - Miquel is owner, everyone else invited
        interactions.extend([
            EventInteraction(
                event_id=family_picnic.id,
                user_id=miquel.id,
                interaction_type="joined",
                status="accepted",
                role="owner",
            ),
            EventInteraction(
                event_id=family_picnic.id,
                user_id=sonia.id,
                interaction_type="invited",
                status="accepted",
                invited_by_user_id=miquel.id,
            ),
            EventInteraction(
                event_id=family_picnic.id,
                user_id=ada.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=miquel.id,
            ),
            EventInteraction(
                event_id=family_picnic.id,
                user_id=sara.id,
                interaction_type="invited",
                status="rejected",
                invited_by_user_id=miquel.id,
                rejection_message="Tengo la conferencia tech ese fin de semana",
            ),
        ])

        # Family trip - Sonia is owner, everyone else invited
        interactions.extend([
            EventInteraction(
                event_id=family_trip.id,
                user_id=sonia.id,
                interaction_type="joined",
                status="accepted",
                role="owner",
            ),
            EventInteraction(
                event_id=family_trip.id,
                user_id=miquel.id,
                interaction_type="invited",
                status="accepted",
                invited_by_user_id=sonia.id,
                note="¡Por fin vacaciones en familia! 🏖️",
            ),
            EventInteraction(
                event_id=family_trip.id,
                user_id=ada.id,
                interaction_type="invited",
                status="accepted",
                invited_by_user_id=sonia.id,
                note="¡Voy a nadar todos los días! 🏊‍♀️",
            ),
            EventInteraction(
                event_id=family_trip.id,
                user_id=sara.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=sonia.id,
            ),
        ])

        db.add_all(interactions)
        db.flush()
        logger.info(f"  ✓ Inserted {len(interactions)} event interactions")

        # 13. Create event ban for TDB user
        ban_tdb = EventBan(
            event_id=event_katy_perry.id,
            user_id=tdb.id,
            banned_by=sonia.id,
        )
        db.add(ban_tdb)
        db.flush()
        logger.info(f"  ✓ Inserted 1 event ban")

        # 14. Create user blocks for PolR (blocked by all main users)
        block_sonia_polr = UserBlock(blocker_user_id=sonia.id, blocked_user_id=polr.id)
        block_miquel_polr = UserBlock(blocker_user_id=miquel.id, blocked_user_id=polr.id)
        block_ada_polr = UserBlock(blocker_user_id=ada.id, blocked_user_id=polr.id)
        block_sara_polr = UserBlock(blocker_user_id=sara.id, blocked_user_id=polr.id)

        db.add_all([block_sonia_polr, block_miquel_polr, block_ada_polr, block_sara_polr])
        db.flush()
        logger.info(f"  ✓ Inserted 4 user blocks")

        db.commit()
        logger.info("✅ Sample data inserted successfully")

    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error inserting sample data: {e}")
        raise
    finally:
        db.close()


def create_database_views():
    """
    Create database views for optimized queries.
    These views enable the Flutter app to query calculated fields directly from Supabase.
    """
    logger.info("👁️  Creating database views...")

    try:
        with engine.connect() as conn:
            # Create user_subscriptions_with_stats view
            # This view provides subscription statistics from the user_subscription_stats table:
            # 1. new_events_count: Events created in last 7 days (pre-calculated by triggers)
            # 2. total_events_count: Total events owned by user (pre-calculated by triggers)
            # 3. subscribers_count: Unique subscribers to user's events (pre-calculated by triggers)
            # Performance: Uses LEFT JOIN with user_subscription_stats instead of 3 subqueries
            conn.execute(text("""
                CREATE OR REPLACE VIEW user_subscriptions_with_stats AS
                SELECT DISTINCT
                    ei.user_id AS subscriber_id,
                    u.id AS subscribed_to_id,
                    u.contact_id,
                    u.username AS instagram_name,
                    u.auth_provider,
                    u.auth_id,
                    u.is_public,
                    u.is_admin,
                    u.profile_picture_url AS profile_picture,
                    u.last_login AS last_seen,
                    u.created_at,
                    u.updated_at,
                    -- Use pre-calculated stats from user_subscription_stats table (maintained by triggers)
                    COALESCE(uss.new_events_count, 0) AS new_events_count,
                    COALESCE(uss.total_events_count, 0) AS total_events_count,
                    COALESCE(uss.subscribers_count, 0) AS subscribers_count
                FROM event_interactions ei
                JOIN events e ON e.id = ei.event_id
                JOIN users u ON u.id = e.owner_id
                LEFT JOIN user_subscription_stats uss ON uss.user_id = u.id
                WHERE ei.interaction_type = 'subscribed'
                AND u.is_public = TRUE
            """))
            logger.info("  ✓ Created view: user_subscriptions_with_stats")

            conn.commit()

        logger.info("✅ Database views created successfully")

    except Exception as e:
        logger.error(f"❌ Error creating database views: {e}")
        raise


def setup_realtime():
    """
    Configure Supabase Realtime for all tables.
    This enables automatic sync from FastAPI writes to Flutter app.

    For each table:
    1. Set REPLICA IDENTITY FULL (required for realtime updates)
    2. Add table to supabase_realtime publication
    """
    logger.info("🔄 Setting up Supabase Realtime...")

    try:
        with engine.connect() as conn:
            # Ensure supabase_realtime publication exists
            # If using self-hosted Supabase, it should already exist
            # If not, create it
            pub_is_for_all_tables = False
            try:
                result = conn.execute(text(
                    "SELECT puballtables FROM pg_publication WHERE pubname = 'supabase_realtime'"
                ))
                row = result.fetchone()
                if row is None:
                    # Publication doesn't exist, create it without tables (we'll add them individually)
                    conn.execute(text(
                        "CREATE PUBLICATION supabase_realtime"
                    ))
                    logger.info("  ✓ Created supabase_realtime publication (empty)")
                    conn.commit()
                else:
                    pub_is_for_all_tables = row[0]
                    if pub_is_for_all_tables:
                        logger.info("  ✓ supabase_realtime publication exists (FOR ALL TABLES)")
                    else:
                        logger.info("  ✓ supabase_realtime publication already exists")
            except Exception as e:
                logger.warning(f"  ⚠️  Could not check/create publication: {e}")
                conn.rollback()  # Reset the transaction after error

            # List of tables to enable realtime sync
            realtime_tables = [
                'events',
                'event_interactions',
                'users',
                'calendars',
                'calendar_memberships',
                'groups',
                'contacts',
                'event_bans',
                'user_blocks',
                'recurring_event_configs',
                'event_cancellations',
                'user_subscription_stats'
            ]

            for table in realtime_tables:
                # Set REPLICA IDENTITY FULL (required for Supabase Realtime)
                conn.execute(text(f'ALTER TABLE {table} REPLICA IDENTITY FULL'))
                logger.info(f"  ✓ Set REPLICA IDENTITY FULL for '{table}'")

                # Add table to Supabase Realtime publication
                # This makes changes visible to subscribed clients
                # Skip if publication is FOR ALL TABLES (it already includes all tables)
                if pub_is_for_all_tables:
                    logger.info(f"  ℹ️  '{table}' already in FOR ALL TABLES publication (skipping)")
                else:
                    try:
                        conn.execute(text(f'ALTER PUBLICATION supabase_realtime ADD TABLE {table}'))
                        logger.info(f"  ✓ Added '{table}' to supabase_realtime publication")
                    except Exception as e:
                        # Table might already be in publication, that's ok
                        error_msg = str(e).lower()
                        if 'already a member' in error_msg or 'already exists' in error_msg:
                            logger.info(f"  ℹ️  '{table}' already in publication (skipping)")
                        else:
                            logger.warning(f"  ⚠️  Could not add '{table}' to publication: {e}")
                            conn.rollback()  # Reset transaction after error

            conn.commit()

        logger.info("✅ Realtime setup completed successfully")

    except Exception as e:
        logger.error(f"❌ Error setting up realtime: {e}")
        # Don't raise - realtime is optional, backend can work without it
        logger.warning("⚠️  Realtime sync may not work, but backend will continue")


def setup_realtime_tenant():
    """
    Configure Supabase Realtime tenant.
    This inserts the tenant record into the table created by Realtime's migrations.

    NOTE: The tenants table is owned by Supabase Realtime service.
    We don't create it - Realtime's migrations create it.
    We only insert our tenant configuration into the existing table.

    This function includes retry logic to wait for Realtime migrations to complete.
    """
    logger.info("🔧 Setting up Realtime tenant and extension (idempotent)...")

    import time
    max_retries = 10
    retry_delay = 2  # seconds

    for attempt in range(max_retries):
        try:
            with engine.connect() as conn:
                # Check if tenants table exists (created by Realtime migrations)
                result = conn.execute(text("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables
                        WHERE table_schema = 'public'
                        AND table_name = 'tenants'
                    )
                """))
                table_exists = result.scalar()

                if not table_exists:
                    if attempt < max_retries - 1:
                        logger.warning(f"  ⏳ Tenants table not found, waiting for Realtime migrations... (attempt {attempt + 1}/{max_retries})")
                        time.sleep(retry_delay)
                        continue
                    else:
                        logger.warning("  ⚠️  Tenants table doesn't exist after max retries - Realtime migrations haven't run")
                        logger.info("  ℹ️  Realtime service will create this table on first startup")
                        return

                # Helper: AES-128-ECB encrypt + base64 (PKCS7 padding)
                def _pkcs7_pad(data: bytes, block_size: int = 16) -> bytes:
                    pad_len = block_size - (len(data) % block_size)
                    return data + bytes([pad_len] * pad_len)

                def _aes128_ecb_encrypt_b64(plaintext: str, key16: str) -> str:
                    key_bytes = key16.encode("utf-8")
                    pt = _pkcs7_pad(plaintext.encode("utf-8"), 16)
                    cipher = Cipher(algorithms.AES(key_bytes), modes.ECB(), backend=default_backend())
                    encryptor = cipher.encryptor()
                    ct = encryptor.update(pt) + encryptor.finalize()
                    return base64.b64encode(ct).decode("utf-8")

                # Read unified JWT secret and DB_ENC_KEY
                unified_jwt_secret = os.getenv(
                    "JWT_SECRET",
                    "super-secret-jwt-token-with-at-least-32-characters-long",
                )
                db_enc_key = os.getenv("DB_ENC_KEY", "0123456789abcdef")

                # Decide storage mode for tenants.jwt_secret to avoid flip-flopping across restarts.
                # Accepted values: 'encrypted' (AES-128-ECB+base64) or 'plaintext'.
                # Default to 'plaintext' which matches current Realtime image expectations in this stack.
                secret_mode = os.getenv("REALTIME_TENANT_SECRET_MODE", "plaintext").lower()
                if secret_mode not in ("encrypted", "plaintext"):
                    logger.warning(
                        f"  ⚠️  Unknown REALTIME_TENANT_SECRET_MODE='{secret_mode}', falling back to 'plaintext'"
                    )
                    secret_mode = "plaintext"

                # Determine tenants schema shape (some Realtime versions have external_id, others don't)
                tenants_has_external_id = False
                try:
                    res = conn.execute(text(
                        """
                        SELECT 1
                        FROM information_schema.columns
                        WHERE table_schema = 'public' AND table_name = 'tenants' AND column_name = 'external_id'
                        """
                    ))
                    tenants_has_external_id = res.fetchone() is not None
                except Exception:
                    tenants_has_external_id = False

                encrypted_jwt = _aes128_ecb_encrypt_b64(unified_jwt_secret, db_enc_key)
                desired_secret = encrypted_jwt if secret_mode == "encrypted" else unified_jwt_secret
                alt_secret = unified_jwt_secret if secret_mode == "encrypted" else encrypted_jwt

                if tenants_has_external_id:
                    tenant_external_id = os.getenv("REALTIME_TENANT_EXTERNAL_ID", "supabase")
                    # Read current value first to avoid unnecessary writes and flip-flops
                    current = conn.execute(text(
                        """
                        SELECT jwt_secret FROM tenants WHERE external_id = :external_id LIMIT 1
                        """
                    ), {"external_id": tenant_external_id}).fetchone()

                    if current is None:
                        # Ensure row exists with desired value
                        conn.execute(text(
                            """
                            INSERT INTO tenants (id, external_id, jwt_secret, inserted_at, updated_at)
                            VALUES (gen_random_uuid(), :external_id, :jwt_secret, NOW(), NOW())
                            """
                        ), {"external_id": tenant_external_id, "jwt_secret": desired_secret})
                        logger.info(
                            f"  ✓ Inserted tenants row (external_id='{tenant_external_id}') in {secret_mode} mode"
                        )
                    else:
                        current_secret = current[0]
                        if current_secret == desired_secret:
                            logger.info(
                                f"  ✓ Tenants jwt_secret already in desired {secret_mode} format (no change)"
                            )
                        elif current_secret == alt_secret:
                            # Normalize to desired format
                            conn.execute(text(
                                """
                                UPDATE tenants
                                SET jwt_secret = :jwt_secret, updated_at = NOW()
                                WHERE external_id = :external_id
                                """
                            ), {"external_id": tenant_external_id, "jwt_secret": desired_secret})
                            logger.info(
                                f"  ✓ Normalized tenants jwt_secret to {secret_mode} format"
                            )
                        else:
                            # Unknown value; set to desired
                            conn.execute(text(
                                """
                                UPDATE tenants
                                SET jwt_secret = :jwt_secret, updated_at = NOW()
                                WHERE external_id = :external_id
                                """
                            ), {"external_id": tenant_external_id, "jwt_secret": desired_secret})
                            logger.info(
                                f"  ✓ Updated tenants jwt_secret to desired {secret_mode} format"
                            )
                    logger.info(f"  ✓ Ensured tenants row (external_id='{tenant_external_id}') with correct jwt_secret")
                else:
                    # Schema without external_id: assume single-tenant. Update first row, or insert if empty.
                    existing = conn.execute(text(
                        """
                        SELECT id, jwt_secret FROM tenants LIMIT 1
                        """
                    )).fetchone()
                    if existing is None:
                        conn.execute(text(
                            """
                            INSERT INTO tenants (id, jwt_secret, inserted_at, updated_at)
                            VALUES (gen_random_uuid(), :jwt_secret, NOW(), NOW())
                            """
                        ), {"jwt_secret": desired_secret})
                        logger.info("  ✓ Inserted tenants row (no external_id) with desired jwt_secret")
                    else:
                        current_secret = existing[1]
                        if current_secret == desired_secret:
                            logger.info(
                                f"  ✓ Tenants jwt_secret already in desired {secret_mode} format (no change)"
                            )
                        elif current_secret == alt_secret:
                            conn.execute(text(
                                """
                                UPDATE tenants SET jwt_secret = :jwt_secret, updated_at = NOW()
                                """
                            ), {"jwt_secret": desired_secret})
                            logger.info(
                                f"  ✓ Normalized tenants jwt_secret to {secret_mode} format"
                            )
                        else:
                            conn.execute(text(
                                """
                                UPDATE tenants SET jwt_secret = :jwt_secret, updated_at = NOW()
                                """
                            ), {"jwt_secret": desired_secret})
                            logger.info(
                                f"  ✓ Updated tenants jwt_secret to desired {secret_mode} format"
                            )
                    logger.info("  ✓ Ensured tenants row (no external_id) with correct jwt_secret")

                # Check if extensions table exists
                result = conn.execute(text("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables
                        WHERE table_schema = 'public'
                        AND table_name = 'extensions'
                    )
                """))
                extensions_table_exists = result.scalar()

                if extensions_table_exists:
                    # Realtime decrypts db_host, db_port, db_name, db_user, and db_password
                    # Encrypt these fields if secret_mode is 'encrypted', else keep plaintext
                    db_host = os.getenv("DB_HOST", "db")
                    db_name = os.getenv("POSTGRES_DB", "postgres")
                    db_user = os.getenv("POSTGRES_USER", "postgres")
                    db_password = os.getenv("POSTGRES_PASSWORD", "your-super-secret-and-long-postgres-password")
                    db_port = int(os.getenv("DB_PORT", "5432"))

                    if secret_mode == "encrypted":
                        db_host = _aes128_ecb_encrypt_b64(db_host, db_enc_key)
                        db_name = _aes128_ecb_encrypt_b64(db_name, db_enc_key)
                        db_user = _aes128_ecb_encrypt_b64(db_user, db_enc_key)
                        db_password = _aes128_ecb_encrypt_b64(db_password, db_enc_key)
                        # db_port as string for encryption
                        db_port = _aes128_ecb_encrypt_b64(str(db_port), db_enc_key)

                    settings = {
                        "db_host": db_host,
                        "db_ip": os.getenv("DB_HOST", "db"),  # db_ip is not decrypted by Realtime
                        "db_name": db_name,
                        "db_user": db_user,
                        "db_password": db_password,
                        "db_port": db_port,
                        "db_ssl": False,
                        "ssl_enforced": False,
                        "ip_version": "IPv4",
                        "region": os.getenv("REGION", "local"),
                        "slot_name": os.getenv("SLOT_NAME", "supabase_realtime_rls"),
                        "temporary_slot": True,
                    }

                    # Some versions may not have tenant_external_id; handle both
                    ext_has_tenant_external_id = False
                    try:
                        res = conn.execute(text(
                            """
                            SELECT 1
                            FROM information_schema.columns
                            WHERE table_schema = 'public' AND table_name = 'extensions' AND column_name = 'tenant_external_id'
                            """
                        ))
                        ext_has_tenant_external_id = res.fetchone() is not None
                    except Exception:
                        ext_has_tenant_external_id = False

                    if ext_has_tenant_external_id:
                        # Update if changed, else ensure exists
                        updated = conn.execute(text(
                            """
                            UPDATE extensions
                            SET settings = CAST(:settings AS jsonb), updated_at = NOW()
                            WHERE type = :type AND tenant_external_id = :tenant
                            """
                        ), {"settings": json.dumps(settings), "type": "postgres_cdc_rls", "tenant": os.getenv("REALTIME_TENANT_EXTERNAL_ID", "supabase")}).rowcount
                        if updated == 0:
                            conn.execute(text(
                                """
                                INSERT INTO extensions (id, type, settings, tenant_external_id, inserted_at, updated_at)
                                VALUES (gen_random_uuid(), :type, CAST(:settings AS jsonb), :tenant, NOW(), NOW())
                                """
                            ), {"type": "postgres_cdc_rls", "tenant": os.getenv("REALTIME_TENANT_EXTERNAL_ID", "supabase"), "settings": json.dumps(settings)})
                    else:
                        # No tenant_external_id: assume single-tenant and single row per type
                        updated = conn.execute(text(
                            """
                            UPDATE extensions
                            SET settings = CAST(:settings AS jsonb), updated_at = NOW()
                            WHERE type = :type
                            """
                        ), {"settings": json.dumps(settings), "type": "postgres_cdc_rls"}).rowcount
                        if updated == 0:
                            conn.execute(text(
                                """
                                INSERT INTO extensions (id, type, settings, inserted_at, updated_at)
                                VALUES (gen_random_uuid(), :type, CAST(:settings AS jsonb), NOW(), NOW())
                                """
                            ), {"type": "postgres_cdc_rls", "settings": json.dumps(settings)})
                    logger.info(f"  ✓ Ensured extension 'postgres_cdc_rls' settings (password: {secret_mode})")
                else:
                    logger.info("  ℹ️  Extensions table doesn't exist yet - will be created by Realtime migrations")

                # Mark ONLY the CreateTenants migration as complete
                # Other migrations need to run to create their tables (extensions, channels, etc.)
                # Do not touch Realtime's internal migration markers; keep ownership with Realtime

                conn.commit()

            logger.info("✅ Realtime tenant/extension setup completed successfully")
            break  # Success, exit retry loop

        except Exception as e:
            if attempt < max_retries - 1:
                logger.warning(f"  ⚠️  Error on attempt {attempt + 1}/{max_retries}: {e}")
                logger.info(f"  ⏳ Retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)
                continue
            else:
                logger.error(f"❌ Error setting up realtime tenant after {max_retries} attempts: {e}")
                # Don't raise - realtime is optional, backend can work without it
                logger.warning("⚠️  Realtime may not work, but backend will continue")


def create_supabase_auth_users():
    """
    Create test users in Supabase Auth.
    This allows users to log in with their phone numbers.
    """
    logger.info("👤 Creating Supabase Auth users...")

    # Supabase configuration
    SUPABASE_URL = os.getenv('SUPABASE_URL', 'http://localhost:8000')
    SUPABASE_SERVICE_ROLE_KEY = os.getenv(
        'SUPABASE_SERVICE_ROLE_KEY',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU'
    )

    try:
        # Create Supabase admin client (using service_role key to bypass RLS)
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

        # Test users to create
        test_users = [
            {'phone': '+34606014680', 'password': 'testpass123', 'name': 'Sonia'},
            {'phone': '+34626034421', 'password': 'testpass123', 'name': 'Miquel'},
            {'phone': '+34623949193', 'password': 'testpass123', 'name': 'Ada'},
            {'phone': '+34611223344', 'password': 'testpass123', 'name': 'Sara'},
            {'phone': '+34600000001', 'password': 'testpass123', 'name': 'TDB'},
            {'phone': '+34600000002', 'password': 'testpass123', 'name': 'PolR'},
        ]

        created_count = 0
        skipped_count = 0

        for user_data in test_users:
            try:
                # Try to create user with phone authentication
                result = supabase.auth.admin.create_user({
                    'phone': user_data['phone'],
                    'password': user_data['password'],
                    'phone_confirm': True,  # Auto-confirm phone
                    'user_metadata': {
                        'name': user_data['name']
                    }
                })

                if result:
                    logger.info(f"  ✓ Created user: {user_data['name']} ({user_data['phone']})")
                    created_count += 1

            except Exception as e:
                error_msg = str(e).lower()
                # Skip if user already exists
                if 'already registered' in error_msg or 'already exists' in error_msg or 'duplicate' in error_msg:
                    logger.info(f"  ℹ️  User already exists: {user_data['name']} ({user_data['phone']})")
                    skipped_count += 1
                else:
                    logger.warning(f"  ⚠️  Could not create user {user_data['name']}: {e}")

        logger.info(f"✅ Supabase Auth setup completed: {created_count} created, {skipped_count} skipped")
        logger.info("📱 Test users can now log in with:")
        logger.info("   Phone: +34606014680, Password: testpass123 (Sonia)")
        logger.info("   Phone: +34626034421, Password: testpass123 (Miquel)")

    except Exception as e:
        logger.error(f"❌ Error creating Supabase Auth users: {e}")
        logger.warning("⚠️  Users may need to be created manually in Supabase Dashboard")
        # Don't raise - this is optional, backend can work without it


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

        # Step 3: Create triggers for user_subscription_stats (CDC architecture)
        create_subscription_stats_triggers()

        # Step 4: Grant permissions on Supabase schemas
        grant_supabase_permissions()

        # Step 5: Create database views
        create_database_views()

        # Step 6: Setup Supabase Realtime
        setup_realtime()
        setup_realtime_tenant()

        # Step 7: Insert sample data
        insert_sample_data()

        # Step 8: Create Supabase Auth users
        create_supabase_auth_users()

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
