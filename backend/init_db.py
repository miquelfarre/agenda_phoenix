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
from models import (
    Contact, User, Calendar, CalendarMembership,
    Event, EventInteraction, RecurringEventConfig,
    EventBan, UserBlock
)
from datetime import datetime, timedelta

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def drop_all_tables():
    """Drop all tables in the database"""
    logger.info("🗑️  Dropping all tables...")
    try:
        # Use inspector to get all tables and drop them with CASCADE
        # This handles circular foreign key dependencies
        from sqlalchemy import inspect, text
        inspector = inspect(engine)
        tables = inspector.get_table_names()

        if tables:
            with engine.connect() as conn:
                # Drop all tables with CASCADE
                for table in tables:
                    conn.execute(text(f'DROP TABLE IF EXISTS "{table}" CASCADE'))
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
            last_login=now,
        )
        miquel = User(
            contact_id=contact_miquel.id,
            auth_provider="phone",
            auth_id=contact_miquel.phone,
            last_login=now,
        )
        ada = User(
            contact_id=contact_ada.id,
            auth_provider="phone",
            auth_id=contact_ada.phone,
            last_login=now,
        )
        sara = User(
            contact_id=contact_sara.id,
            auth_provider="phone",
            auth_id=contact_sara.phone,
            last_login=now,
        )
        tdb = User(
            contact_id=contact_tdb.id,
            auth_provider="phone",
            auth_id=contact_tdb.phone,
            last_login=now,
        )
        polr = User(
            contact_id=contact_polr.id,
            auth_provider="phone",
            auth_id=contact_polr.phone,
            last_login=now,
        )
        fcbarcelona = User(
            username="fcbarcelona",
            auth_provider="instagram",
            auth_id="ig_fcbarcelona",
            profile_picture_url="https://example.com/fcb-logo.png",
            last_login=now,
        )

        db.add_all([sonia, miquel, ada, sara, tdb, polr, fcbarcelona])
        db.flush()
        logger.info(f"  ✓ Inserted 7 users")

        # 3. Create calendars
        cal_family = Calendar(owner_id=sonia.id, name="Family")
        cal_birthdays = Calendar(owner_id=sonia.id, name="Cumpleaños Family")
        cal_esqui_temporal = Calendar(
            owner_id=sonia.id,
            name="Temporada Esquí 2025-2026",
            start_date=datetime(2025, 12, 1),
            end_date=datetime(2026, 3, 31)
        )

        db.add_all([cal_family, cal_birthdays, cal_esqui_temporal])
        db.flush()
        logger.info(f"  ✓ Inserted 3 calendars (2 permanent, 1 temporal)")

        # 4. Create calendar memberships
        membership_sonia_family = CalendarMembership(
            calendar_id=cal_family.id,
            user_id=sonia.id,
            role='owner',
            status='accepted',
        )
        membership_sonia_birthdays = CalendarMembership(
            calendar_id=cal_birthdays.id,
            user_id=sonia.id,
            role='owner',
            status='accepted',
        )
        membership_miquel_birthdays = CalendarMembership(
            calendar_id=cal_birthdays.id,
            user_id=miquel.id,
            role='admin',
            status='accepted',
            invited_by_user_id=sonia.id,
        )
        membership_miquel_family = CalendarMembership(
            calendar_id=cal_family.id,
            user_id=miquel.id,
            role='admin',
            status='accepted',
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
            recurrence_type='weekly',
            schedule=[
                {"day": 0, "day_name": "Lunes", "time": "17:30"},
                {"day": 2, "day_name": "Miércoles", "time": "17:30"},
            ],
            recurrence_end_date=datetime(2026, 6, 23),
        )
        config_dj = RecurringEventConfig(
            event_id=recurring_dj.id,
            recurrence_type='weekly',
            schedule=[
                {"day": 4, "day_name": "Viernes", "time": "17:30"},
            ],
            recurrence_end_date=datetime(2026, 6, 23),
        )
        config_baile = RecurringEventConfig(
            event_id=recurring_baile.id,
            recurrence_type='weekly',
            schedule=[
                {"day": 3, "day_name": "Jueves", "time": "17:30"},
            ],
            recurrence_end_date=datetime(2026, 6, 23),
        )
        config_esqui = RecurringEventConfig(
            event_id=recurring_esqui.id,
            recurrence_type='weekly',
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
            recurrence_type='yearly',
            schedule=[{"month": 4, "day_of_month": 30}],
            recurrence_end_date=None,  # Perpetuo
        )
        config_bday_ada = RecurringEventConfig(
            event_id=bday_ada.id,
            recurrence_type='yearly',
            schedule=[{"month": 9, "day_of_month": 6}],
            recurrence_end_date=None,  # Perpetuo
        )
        config_bday_sonia = RecurringEventConfig(
            event_id=bday_sonia.id,
            recurrence_type='yearly',
            schedule=[{"month": 1, "day_of_month": 31}],
            recurrence_end_date=None,  # Perpetuo
        )
        config_bday_sara = RecurringEventConfig(
            event_id=bday_sara.id,
            recurrence_type='yearly',
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
            recurrence_type='daily',
            schedule=[{"interval_days": 1}],  # Cada día
            recurrence_end_date=datetime(2026, 12, 31),  # Termina fin de 2026
        )

        config_alquiler = RecurringEventConfig(
            event_id=recurring_alquiler.id,
            recurrence_type='monthly',
            schedule=[{"day_of_month": 1}],  # Día 1 de cada mes
            recurrence_end_date=None,  # Perpetuo
        )

        config_reunion = RecurringEventConfig(
            event_id=recurring_reunion.id,
            recurrence_type='monthly',
            schedule=[
                {"day_of_month": 5},   # Día 5 de cada mes
                {"day_of_month": 20}   # Día 20 de cada mes
            ],
            recurrence_end_date=datetime(2026, 12, 31),
        )

        config_navidad = RecurringEventConfig(
            event_id=recurring_navidad.id,
            recurrence_type='yearly',
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

        # 10. Create FC Barcelona match events
        fcb_matches = [
            Event(name="FC Barcelona vs Girona", start_date=datetime(2025, 10, 18, 16, 15), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Olympiakos", start_date=datetime(2025, 10, 21, 18, 45), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Real Madrid vs FC Barcelona", start_date=datetime(2025, 10, 26, 16, 15), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Elche", start_date=datetime(2025, 11, 2, 18, 30), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Club Brugge vs FC Barcelona", start_date=datetime(2025, 11, 5, 21, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Celta de Vigo vs FC Barcelona", start_date=datetime(2025, 11, 9, 21, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Athletic Club", start_date=datetime(2025, 11, 23, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Chelsea vs FC Barcelona", start_date=datetime(2025, 11, 25, 21, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Alavés", start_date=datetime(2025, 11, 30, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Real Betis vs FC Barcelona", start_date=datetime(2025, 12, 7, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Eintracht Frankfurt", start_date=datetime(2025, 12, 9, 21, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Osasuna", start_date=datetime(2025, 12, 14, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Villarreal vs FC Barcelona", start_date=datetime(2025, 12, 21, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Espanyol vs FC Barcelona", start_date=datetime(2026, 1, 4, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Athletic Club", start_date=datetime(2026, 1, 7, 20, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Atlético Madrid", start_date=datetime(2026, 1, 11, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Real Sociedad vs FC Barcelona", start_date=datetime(2026, 1, 18, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs Real Oviedo", start_date=datetime(2026, 1, 25, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="Slavia Prague vs FC Barcelona", start_date=datetime(2026, 1, 21, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
            Event(name="FC Barcelona vs FC København", start_date=datetime(2026, 1, 28, 18, 0), event_type="regular", owner_id=fcbarcelona.id),
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
            recurrence_type='weekly',
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

        # 12. Create event interactions
        interactions = []

        # Sonia owns all her recurring base events
        for event in [recurring_sincro, recurring_dj, recurring_baile, recurring_esqui]:
            interactions.append(EventInteraction(
                event_id=event.id, user_id=sonia.id,
                interaction_type="joined", status="accepted", role="owner",
            ))

        # Sonia owns all recurring instances
        for event in all_instances:
            interactions.append(EventInteraction(
                event_id=event.id, user_id=sonia.id,
                interaction_type="joined", status="accepted", role="owner",
            ))

        # Sonia owns all birthday events (recurring yearly perpetual)
        for event in [bday_miquel, bday_ada, bday_sonia, bday_sara]:
            interactions.append(EventInteraction(
                event_id=event.id, user_id=sonia.id,
                interaction_type="joined", status="accepted", role="owner",
            ))

        # Sonia owns all additional recurring events (daily, monthly, yearly)
        for event in [recurring_medicacion, recurring_alquiler, recurring_reunion, recurring_navidad]:
            interactions.append(EventInteraction(
                event_id=event.id, user_id=sonia.id,
                interaction_type="joined", status="accepted", role="owner",
            ))

        # Sonia owns regular events
        for event in [event_katy_perry, event_festa_codony]:
            interactions.append(EventInteraction(
                event_id=event.id, user_id=sonia.id,
                interaction_type="joined", status="accepted", role="owner",
            ))

        # FC Barcelona owns all their matches
        for event in fcb_matches:
            interactions.append(EventInteraction(
                event_id=event.id, user_id=fcbarcelona.id,
                interaction_type="joined", status="accepted", role="owner",
            ))

        # Miquel subscribed to all FC Barcelona matches
        for event in fcb_matches:
            interactions.append(EventInteraction(
                event_id=event.id, user_id=miquel.id,
                interaction_type="subscribed", status="accepted",
            ))

        # Sonia owns "Cumpleaños clase Sara"
        interactions.append(EventInteraction(
            event_id=event_cumple_sara_clase.id, user_id=sonia.id,
            interaction_type="joined", status="accepted", role="owner",
        ))

        # Miquel invited to "Cumpleaños clase Sara"
        interactions.append(EventInteraction(
            event_id=event_cumple_sara_clase.id, user_id=miquel.id,
            interaction_type="invited", status="pending",
            invited_by_user_id=sonia.id,
        ))

        # Sonia owns "Compra semanal sábado"
        interactions.append(EventInteraction(
            event_id=event_compra_semanal.id, user_id=sonia.id,
            interaction_type="joined", status="accepted", role="owner",
        ))

        # Miquel is admin of "Compra semanal sábado"
        interactions.append(EventInteraction(
            event_id=event_compra_semanal.id, user_id=miquel.id,
            interaction_type="joined", status="accepted", role="admin",
            invited_by_user_id=sonia.id,
        ))

        # Sonia owns "Promociona Madrid" base event
        interactions.append(EventInteraction(
            event_id=recurring_promociona_madrid.id, user_id=sonia.id,
            interaction_type="joined", status="accepted", role="owner",
        ))

        # Sonia owns all "Promociona Madrid" instances
        for event in promociona_instances:
            interactions.append(EventInteraction(
                event_id=event.id, user_id=sonia.id,
                interaction_type="joined", status="accepted", role="owner",
            ))

        # Miquel invited to Esquí events (base + all instances)
        interactions.append(EventInteraction(
            event_id=recurring_esqui.id, user_id=miquel.id,
            interaction_type="invited", status="pending",
            invited_by_user_id=sonia.id,
        ))
        for event in esqui_instances:
            interactions.append(EventInteraction(
                event_id=event.id, user_id=miquel.id,
                interaction_type="invited", status="pending",
                invited_by_user_id=sonia.id,
            ))

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
