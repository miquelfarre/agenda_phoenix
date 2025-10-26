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


def grant_supabase_permissions():
    """
    Grant necessary permissions to postgres user on Supabase-managed schemas.
    This fixes permission errors when Supabase services try to run migrations.
    """
    logger.info("🔐 Granting permissions on Supabase schemas...")

    try:
        # This logic is now handled by /database/init/00-initial-roles.sql
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
        cal_esqui_temporal = Calendar(owner_id=sonia.id, name="Temporada Esquí 2025-2026", start_date=datetime(2025, 12, 1), end_date=datetime(2026, 3, 31))

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
            start_date=datetime(2025, 11, 3, 17, 30),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )
        recurring_dj = Event(
            name="DJ",
            description="Evento recurrente DJ",
            start_date=datetime(2025, 11, 3, 17, 30),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )
        recurring_baile = Event(
            name="Baile KDN",
            description="Evento recurrente Baile KDN",
            start_date=datetime(2025, 11, 3, 17, 30),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )
        recurring_esqui = Event(
            name="Esquí temporada 2025-2026",
            description="Esquí semanal temporada 2025-2026",
            start_date=datetime(2025, 12, 13, 8, 0),
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
            start_date=datetime(2026, 4, 30, 0, 0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_birthdays.id,
        )
        bday_ada = Event(
            name="Cumpleaños de Ada",
            description="Cumpleaños de Ada (6 de septiembre)",
            start_date=datetime(2026, 9, 6, 0, 0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_birthdays.id,
        )
        bday_sonia = Event(
            name="Cumpleaños de Sonia",
            description="Cumpleaños de Sonia (31 de enero)",
            start_date=datetime(2026, 1, 31, 0, 0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_birthdays.id,
        )
        bday_sara = Event(
            name="Cumpleaños de Sara",
            description="Cumpleaños de Sara (2 de diciembre)",
            start_date=datetime(2026, 12, 2, 0, 0),
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
            start_date=datetime(2025, 11, 1, 9, 0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )

        # MONTHLY: Pago de alquiler (día 1 de cada mes)
        recurring_alquiler = Event(
            name="Pago de alquiler",
            description="Pago mensual del alquiler",
            start_date=datetime(2025, 11, 1, 10, 0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )

        # MONTHLY: Reunión de equipo (días 5 y 20 de cada mes)
        recurring_reunion = Event(
            name="Reunión de equipo",
            description="Reuniones quincenales del equipo",
            start_date=datetime(2025, 11, 5, 15, 0),
            event_type="recurring",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )

        # YEARLY: Navidad (perpetuo)
        recurring_navidad = Event(
            name="Navidad",
            description="Celebración de Navidad",
            start_date=datetime(2025, 12, 25, 0, 0),
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
            start_date=datetime(2025, 11, 9, 20, 0),
            event_type="regular",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )
        event_festa_codony = Event(
            name="Festa del Codony",
            description="Lugar: Tremp",
            start_date=datetime(2025, 11, 1, 9, 0),
            event_type="regular",
            owner_id=sonia.id,
            calendar_id=cal_family.id,
        )

        db.add_all([event_katy_perry, event_festa_codony])
        db.flush()
        logger.info(f"  ✓ Inserted 2 regular events")

        # 10. Create FC Barcelona match events with descriptions
        fcb_matches = [
            Event(name="FC Barcelona vs Girona", description="🏟️ Spotify Camp Nou • LaLiga EA Sports", start_date=datetime(2025, 10, 18, 16, 15), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Olympiakos", description="🏟️ Spotify Camp Nou • UEFA Champions League", start_date=datetime(2025, 10, 21, 18, 45), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Real Madrid vs FC Barcelona", description="🏟️ Santiago Bernabéu • LaLiga EA Sports • El Clásico", start_date=datetime(2025, 10, 26, 16, 15), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Elche", description="🏟️ Spotify Camp Nou • Copa del Rey", start_date=datetime(2025, 11, 2, 18, 30), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Club Brugge vs FC Barcelona", description="🏟️ Jan Breydel Stadium • UEFA Champions League", start_date=datetime(2025, 11, 5, 21, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Celta de Vigo vs FC Barcelona", description="🏟️ Estadio de Balaídos • LaLiga EA Sports", start_date=datetime(2025, 11, 9, 21, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Athletic Club", description="🏟️ Spotify Camp Nou • LaLiga EA Sports", start_date=datetime(2025, 11, 23, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Chelsea vs FC Barcelona", description="🏟️ Stamford Bridge • UEFA Champions League", start_date=datetime(2025, 11, 25, 21, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Alavés", description="🏟️ Spotify Camp Nou • LaLiga EA Sports", start_date=datetime(2025, 11, 30, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Real Betis vs FC Barcelona", description="🏟️ Benito Villamarín • LaLiga EA Sports", start_date=datetime(2025, 12, 7, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Eintracht Frankfurt", description="🏟️ Spotify Camp Nou • UEFA Champions League", start_date=datetime(2025, 12, 9, 21, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Osasuna", description="🏟️ Spotify Camp Nou • LaLiga EA Sports", start_date=datetime(2025, 12, 14, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Villarreal vs FC Barcelona", description="🏟️ Estadio de la Cerámica • LaLiga EA Sports", start_date=datetime(2025, 12, 21, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Espanyol vs FC Barcelona", description="🏟️ RCDE Stadium • LaLiga EA Sports • Derby Barceloní", start_date=datetime(2026, 1, 4, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Athletic Club", description="🏟️ Spotify Camp Nou • Copa del Rey", start_date=datetime(2026, 1, 7, 20, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Atlético Madrid", description="🏟️ Spotify Camp Nou • LaLiga EA Sports", start_date=datetime(2026, 1, 11, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Real Sociedad vs FC Barcelona", description="🏟️ Reale Arena • LaLiga EA Sports", start_date=datetime(2026, 1, 18, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Real Oviedo", description="🏟️ Spotify Camp Nou • Copa del Rey", start_date=datetime(2026, 1, 25, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Slavia Prague vs FC Barcelona", description="🏟️ Fortuna Arena • UEFA Champions League", start_date=datetime(2026, 1, 21, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs FC København", description="🏟️ Spotify Camp Nou • UEFA Champions League", start_date=datetime(2026, 1, 28, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
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
            start_date=datetime(2025, 11, 2, 17, 0),
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
            start_date=datetime(2025, 11, 7, 16, 30),
            event_type="regular",
            owner_id=ada.id,
        )
        ada_movie = Event(
            name="Cine con familia",
            description="Ver nueva película de animación",
            start_date=datetime(2025, 11, 10, 17, 30),
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
            start_date=datetime(2025, 11, 14, 10, 0),
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
            start_date=datetime(2025, 11, 6, 18, 30),
            event_type="regular",
            owner_id=restaurant_sabor.id,
        )
        restaurant_brunch = Event(
            name="Brunch especial domingo",
            description="Brunch buffet con opciones veganas y sin gluten",
            start_date=datetime(2025, 11, 10, 11, 0),
            event_type="regular",
            owner_id=restaurant_sabor.id,
        )

        # Centro Cultural La Llotja events
        cultural_concert = Event(
            name="Concierto de jazz",
            description="Trio de jazz en vivo - Entrada libre",
            start_date=datetime(2025, 11, 1, 20, 30),
            event_type="regular",
            owner_id=cultural_llotja.id,
        )
        cultural_expo = Event(
            name="Exposición de arte contemporáneo",
            description="Inauguración: Artistas emergentes de Barcelona",
            start_date=datetime(2025, 11, 7, 19, 0),
            event_type="regular",
            owner_id=cultural_llotja.id,
        )
        cultural_theater = Event(
            name="Obra de teatro: Hamlet",
            description="Adaptación moderna del clásico de Shakespeare",
            start_date=datetime(2025, 11, 15, 21, 0),
            event_type="regular",
            owner_id=cultural_llotja.id,
        )
        cultural_workshop = Event(
            name="Taller de fotografía",
            description="Técnicas básicas de fotografía urbana",
            start_date=datetime(2025, 11, 20, 17, 0),
            event_type="regular",
            owner_id=cultural_llotja.id,
        )

        db.add_all([
            gym_spinning, gym_yoga_morning, gym_crossfit, gym_pilates,
            restaurant_tasting, restaurant_cooking, restaurant_brunch,
            cultural_concert, cultural_expo, cultural_theater, cultural_workshop
        ])
        db.flush()
        logger.info(f"  ✓ Inserted 11 events for public venues (4 gym, 3 restaurant, 4 cultural)")

        # 16. Create shared family events
        family_dinner = Event(
            name="Cena familiar",
            description="Cena mensual en casa de los abuelos",
            start_date=datetime(2025, 11, 9, 20, 0),
            event_type="regular",
            owner_id=sonia.id,
        )
        family_picnic = Event(
            name="Picnic familiar",
            description="Picnic en el parque",
            start_date=datetime(2025, 11, 11, 12, 0),
            event_type="regular",
            owner_id=miquel.id,
        )
        family_trip = Event(
            name="Viaje familiar a la playa",
            description="Fin de semana en la costa",
            start_date=datetime(2025, 11, 22, 10, 0),
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

        # Miquel invited to "Cumpleaños clase Sara"
        interactions.append(
            EventInteraction(
                event_id=event_cumple_sara_clase.id,
                user_id=miquel.id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=sonia.id,
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
        for event in [gym_spinning, gym_yoga_morning, gym_crossfit, gym_pilates]:
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
        for event in [gym_spinning, gym_yoga_morning, gym_crossfit, gym_pilates]:
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
            # This view provides subscription statistics with 3 calculated fields:
            # 1. new_events_count: Events created in last 7 days
            # 2. total_events_count: Total events owned by user
            # 3. subscribers_count: Unique subscribers to user's events
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
                    -- Calculate new events count (last 7 days)
                    (
                        SELECT COUNT(*)
                        FROM events e
                        WHERE e.owner_id = u.id
                        AND e.created_at >= NOW() - INTERVAL '7 days'
                    ) AS new_events_count,
                    -- Calculate total events count
                    (
                        SELECT COUNT(*)
                        FROM events e
                        WHERE e.owner_id = u.id
                    ) AS total_events_count,
                    -- Calculate subscribers count (distinct users subscribed to any event owned by this user)
                    (
                        SELECT COUNT(DISTINCT ei2.user_id)
                        FROM event_interactions ei2
                        JOIN events e2 ON e2.id = ei2.event_id
                        WHERE e2.owner_id = u.id
                        AND ei2.interaction_type = 'subscribed'
                    ) AS subscribers_count
                FROM event_interactions ei
                JOIN events e ON e.id = ei.event_id
                JOIN users u ON u.id = e.owner_id
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
            try:
                result = conn.execute(text(
                    "SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'"
                ))
                if result.fetchone() is None:
                    # Publication doesn't exist, create it
                    conn.execute(text(
                        "CREATE PUBLICATION supabase_realtime FOR ALL TABLES"
                    ))
                    logger.info("  ✓ Created supabase_realtime publication")
                    conn.commit()
                else:
                    logger.info("  ✓ supabase_realtime publication already exists")
            except Exception as e:
                logger.warning(f"  ⚠️  Could not check/create publication: {e}")

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
                'event_cancellations'
            ]

            for table in realtime_tables:
                # Set REPLICA IDENTITY FULL (required for Supabase Realtime)
                conn.execute(text(f'ALTER TABLE {table} REPLICA IDENTITY FULL'))
                logger.info(f"  ✓ Set REPLICA IDENTITY FULL for '{table}'")

                # Add table to Supabase Realtime publication
                # This makes changes visible to subscribed clients
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
    """
    logger.info("🔧 Setting up Realtime tenant...")

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
                logger.warning("  ⚠️  Tenants table doesn't exist yet - Realtime migrations haven't run")
                logger.info("  ℹ️  Realtime service will create this table on first startup")
                return

            # Check if tenant already exists
            result = conn.execute(text(
                "SELECT id FROM tenants WHERE external_id = 'realtime'"
            ))
            existing_tenant = result.fetchone()

            if existing_tenant:
                logger.info("  ℹ️  Realtime tenant already exists")
            else:
                # Insert tenant with correct configuration
                # Use raw SQL because this table is owned by Realtime
                conn.execute(text("""
                    INSERT INTO tenants (
                        id, name, external_id, jwt_secret,
                        max_concurrent_users, inserted_at, updated_at,
                        max_events_per_second, max_bytes_per_second,
                        max_channels_per_client, max_joins_per_second
                    ) VALUES (
                        gen_random_uuid(), 'realtime', 'realtime',
                        'super-secret-jwt-token-with-at-least-32-characters-long',
                        200, NOW(), NOW(),
                        100, 100000,
                        100, 500
                    )
                """))
                logger.info("  ✓ Created Realtime tenant")

            # Mark ONLY the CreateTenants migration as complete
            # Other migrations need to run to create their tables (extensions, channels, etc.)
            logger.info("  📝 Marking CreateTenants migration as complete...")
            conn.execute(text("""
                INSERT INTO schema_migrations (version, inserted_at)
                VALUES (20210706140551, NOW())
                ON CONFLICT DO NOTHING
            """))
            logger.info("  ✓ Marked CreateTenants migration as complete")

            conn.commit()

        logger.info("✅ Realtime tenant setup completed successfully")

    except Exception as e:
        logger.error(f"❌ Error setting up realtime tenant: {e}")
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

        # Step 3: Grant permissions on Supabase schemas
        grant_supabase_permissions()

        # Step 4: Create database views
        create_database_views()

        # Step 5: Setup Supabase Realtime
        setup_realtime()
        # setup_realtime_tenant()

        # Step 6: Insert sample data
        insert_sample_data()

        # Step 7: Create Supabase Auth users
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
