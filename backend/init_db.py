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
        contacts = [
            Contact(name="Sonia", phone="+34606014680"),
            Contact(name="Miquel", phone="+34626034421"),
            Contact(name="Ada", phone="+34623949193"),
            Contact(name="Sara", phone="+34611223344"),
            Contact(name="TDB", phone="+34600000001"),
            Contact(name="PolR", phone="+34600000002"),
        ]
        db.add_all(contacts)
        db.flush()
        logger.info(f"  ✓ Inserted {len(contacts)} contacts")

        # 2. Create users
        users = [
            # Private users (phone auth)
            User(
                contact_id=contacts[0].id,  # Sonia
                auth_provider="phone",
                auth_id=contacts[0].phone,
                last_login=now,
            ),
            User(
                contact_id=contacts[1].id,  # Miquel
                auth_provider="phone",
                auth_id=contacts[1].phone,
                last_login=now,
            ),
            User(
                contact_id=contacts[2].id,  # Ada
                auth_provider="phone",
                auth_id=contacts[2].phone,
                last_login=now,
            ),
            User(
                contact_id=contacts[3].id,  # Sara
                auth_provider="phone",
                auth_id=contacts[3].phone,
                last_login=now,
            ),
            User(
                contact_id=contacts[4].id,  # TDB (baneado)
                auth_provider="phone",
                auth_id=contacts[4].phone,
                last_login=now,
            ),
            User(
                contact_id=contacts[5].id,  # PolR (bloqueado por todos)
                auth_provider="phone",
                auth_id=contacts[5].phone,
                last_login=now,
            ),
            # Public user (instagram auth)
            User(
                username="fcbarcelona",
                auth_provider="instagram",
                auth_id="ig_fcbarcelona",
                profile_picture_url="https://example.com/fcb-logo.png",
                last_login=now,
            ),
        ]
        db.add_all(users)
        db.flush()
        logger.info(f"  ✓ Inserted {len(users)} users")

        # Indices for easy reference
        sonia_idx, miquel_idx, ada_idx, sara_idx, tdb_idx, polr_idx, fcb_idx = 0, 1, 2, 3, 4, 5, 6

        # 3. Create calendars
        calendars = [
            # Family calendar (owner: Sonia)
            Calendar(user_id=users[sonia_idx].id, name="Family", color="#e74c3c", is_default=False),
            # Birthday calendar (owner: Sonia)
            Calendar(user_id=users[sonia_idx].id, name="Cumpleaños Family", color="#f39c12", is_default=False),
        ]
        db.add_all(calendars)
        db.flush()
        logger.info(f"  ✓ Inserted {len(calendars)} calendars")

        # Calendar indices
        family_cal_idx = 0
        birthday_cal_idx = 1

        # 4. Create calendar memberships
        calendar_memberships = [
            # Sonia is owner of Family calendar
            CalendarMembership(
                calendar_id=calendars[family_cal_idx].id,
                user_id=users[sonia_idx].id,
                role='owner',
                status='accepted',
            ),
            # Sonia is owner of Birthday calendar
            CalendarMembership(
                calendar_id=calendars[birthday_cal_idx].id,
                user_id=users[sonia_idx].id,
                role='owner',
                status='accepted',
            ),
            # Miquel is admin of Birthday calendar
            CalendarMembership(
                calendar_id=calendars[birthday_cal_idx].id,
                user_id=users[miquel_idx].id,
                role='admin',
                status='accepted',
                invited_by_user_id=users[sonia_idx].id,
            ),
            # Miquel is admin of Family calendar
            CalendarMembership(
                calendar_id=calendars[family_cal_idx].id,
                user_id=users[miquel_idx].id,
                role='admin',
                status='accepted',
                invited_by_user_id=users[sonia_idx].id,
            ),
        ]
        db.add_all(calendar_memberships)
        db.flush()
        logger.info(f"  ✓ Inserted {len(calendar_memberships)} calendar memberships")

        # 5. Create recurring event configs (base events)
        # These are the "template" events for recurring series
        base_recurring_events = [
            # Sincro: Mondays and Wednesdays at 17:30
            Event(
                name="Sincro",
                description="Evento recurrente Sincro",
                start_date=datetime(2025, 11, 3, 17, 30),  # First Monday from Nov 1
                end_date=datetime(2025, 11, 3, 18, 30),
                event_type="recurring",
                owner_id=users[sonia_idx].id,
                calendar_id=calendars[family_cal_idx].id,
                parent_calendar_id=calendars[family_cal_idx].id,
            ),
            # DJ: Fridays at 17:30
            Event(
                name="DJ",
                description="Evento recurrente DJ",
                start_date=datetime(2025, 11, 3, 17, 30),  # First Monday from Nov 1
                end_date=datetime(2025, 11, 3, 18, 30),
                event_type="recurring",
                owner_id=users[sonia_idx].id,
                calendar_id=calendars[family_cal_idx].id,
                parent_calendar_id=calendars[family_cal_idx].id,
            ),
            # Baile KDN: Thursdays at 17:30
            Event(
                name="Baile KDN",
                description="Evento recurrente Baile KDN",
                start_date=datetime(2025, 11, 3, 17, 30),  # First Monday from Nov 1
                end_date=datetime(2025, 11, 3, 18, 30),
                event_type="recurring",
                owner_id=users[sonia_idx].id,
                calendar_id=calendars[family_cal_idx].id,
                parent_calendar_id=calendars[family_cal_idx].id,
            ),
            # Esquí temporada 2025-2026: Saturdays at 08:00
            Event(
                name="Esquí temporada 2025-2026",
                description="Esquí semanal temporada 2025-2026",
                start_date=datetime(2025, 12, 13, 8, 0),  # First Saturday from Dec 10
                end_date=datetime(2025, 12, 13, 18, 0),  # 10 hours
                event_type="recurring",
                owner_id=users[sonia_idx].id,
                calendar_id=calendars[family_cal_idx].id,
                parent_calendar_id=calendars[family_cal_idx].id,
            ),
        ]
        db.add_all(base_recurring_events)
        db.flush()
        logger.info(f"  ✓ Inserted {len(base_recurring_events)} base recurring events")

        # 6. Create recurring event configs
        end_date_recurring = datetime(2026, 6, 23)
        end_date_ski = datetime(2026, 3, 30)
        recurring_configs = [
            # Sincro config: Mondays (0) and Wednesdays (2)
            RecurringEventConfig(
                event_id=base_recurring_events[0].id,
                days_of_week=[0, 2],
                time_slots=[{"start": "17:30", "end": "18:30"}],
                recurrence_end_date=end_date_recurring,
            ),
            # DJ config: Fridays (4)
            RecurringEventConfig(
                event_id=base_recurring_events[1].id,
                days_of_week=[4],
                time_slots=[{"start": "17:30", "end": "18:30"}],
                recurrence_end_date=end_date_recurring,
            ),
            # Baile KDN config: Thursdays (3)
            RecurringEventConfig(
                event_id=base_recurring_events[2].id,
                days_of_week=[3],
                time_slots=[{"start": "17:30", "end": "18:30"}],
                recurrence_end_date=end_date_recurring,
            ),
            # Esquí config: Saturdays (5)
            RecurringEventConfig(
                event_id=base_recurring_events[3].id,
                days_of_week=[5],
                time_slots=[{"start": "08:00", "end": "18:00"}],
                recurrence_end_date=end_date_ski,
            ),
        ]
        db.add_all(recurring_configs)
        db.flush()
        logger.info(f"  ✓ Inserted {len(recurring_configs)} recurring configs")

        # 7. Pre-generate recurring event instances
        generated_events = []

        # Helper function to generate instances for a recurring event
        def generate_instances(base_event, config, event_name):
            instances = []
            current_date = base_event.start_date

            while current_date <= config.recurrence_end_date:
                # Check if current day is in the days_of_week
                if current_date.weekday() in config.days_of_week:
                    instance = Event(
                        name=event_name,
                        description=base_event.description,
                        start_date=current_date,
                        end_date=current_date + timedelta(hours=1),
                        event_type="regular",
                        owner_id=base_event.owner_id,
                        calendar_id=base_event.calendar_id,
                        parent_calendar_id=base_event.parent_calendar_id,
                        parent_recurring_event_id=config.id,
                    )
                    instances.append(instance)

                current_date += timedelta(days=1)

            return instances

        # Generate instances for Sincro (Mondays and Wednesdays)
        generated_events.extend(generate_instances(base_recurring_events[0], recurring_configs[0], "Sincro"))

        # Generate instances for DJ (Fridays)
        generated_events.extend(generate_instances(base_recurring_events[1], recurring_configs[1], "DJ"))

        # Generate instances for Baile KDN (Thursdays)
        generated_events.extend(generate_instances(base_recurring_events[2], recurring_configs[2], "Baile KDN"))

        # Generate instances for Esquí (Saturdays)
        ski_instances = []
        current_date = base_recurring_events[3].start_date
        while current_date <= recurring_configs[3].recurrence_end_date:
            if current_date.weekday() in recurring_configs[3].days_of_week:
                instance = Event(
                    name="Esquí temporada 2025-2026",
                    description=base_recurring_events[3].description,
                    start_date=current_date,
                    end_date=current_date.replace(hour=18, minute=0),  # 10 hours duration
                    event_type="regular",
                    owner_id=base_recurring_events[3].owner_id,
                    calendar_id=base_recurring_events[3].calendar_id,
                    parent_calendar_id=base_recurring_events[3].parent_calendar_id,
                    parent_recurring_event_id=recurring_configs[3].id,
                )
                ski_instances.append(instance)
            current_date += timedelta(days=1)
        generated_events.extend(ski_instances)

        db.add_all(generated_events)
        db.flush()
        logger.info(f"  ✓ Generated {len(generated_events)} recurring event instances")

        # 8. Create birthday events in "Cumpleaños Family" calendar
        birthday_events = [
            # Cumpleaños de Miquel - 30 de abril
            Event(
                name="Cumpleaños de Miquel",
                description="Cumpleaños de Miquel",
                start_date=datetime(2026, 4, 30, 0, 0),
                end_date=datetime(2026, 4, 30, 23, 59),
                event_type="regular",
                owner_id=users[sonia_idx].id,
                calendar_id=calendars[birthday_cal_idx].id,
                parent_calendar_id=calendars[birthday_cal_idx].id,
            ),
            # Cumpleaños de Ada - 6 de septiembre
            Event(
                name="Cumpleaños de Ada",
                description="Cumpleaños de Ada",
                start_date=datetime(2026, 9, 6, 0, 0),
                end_date=datetime(2026, 9, 6, 23, 59),
                event_type="regular",
                owner_id=users[sonia_idx].id,
                calendar_id=calendars[birthday_cal_idx].id,
                parent_calendar_id=calendars[birthday_cal_idx].id,
            ),
            # Cumpleaños de Sonia - 31 de enero
            Event(
                name="Cumpleaños de Sonia",
                description="Cumpleaños de Sonia",
                start_date=datetime(2026, 1, 31, 0, 0),
                end_date=datetime(2026, 1, 31, 23, 59),
                event_type="regular",
                owner_id=users[sonia_idx].id,
                calendar_id=calendars[birthday_cal_idx].id,
                parent_calendar_id=calendars[birthday_cal_idx].id,
            ),
            # Cumpleaños de Sara - 2 de diciembre
            Event(
                name="Cumpleaños de Sara",
                description="Cumpleaños de Sara",
                start_date=datetime(2026, 12, 2, 0, 0),
                end_date=datetime(2026, 12, 2, 23, 59),
                event_type="regular",
                owner_id=users[sonia_idx].id,
                calendar_id=calendars[birthday_cal_idx].id,
                parent_calendar_id=calendars[birthday_cal_idx].id,
            ),
        ]
        db.add_all(birthday_events)
        db.flush()
        logger.info(f"  ✓ Inserted {len(birthday_events)} birthday events")

        # 9. Create regular events
        regular_events = [
            # Concierto de Katy Perry
            Event(
                name="Concierto de Katy Perry",
                description="Lugar: Palau Sant Jordi, Barcelona",
                start_date=datetime(2025, 11, 9, 20, 0),
                end_date=datetime(2025, 11, 9, 23, 0),
                event_type="regular",
                owner_id=users[sonia_idx].id,
                calendar_id=calendars[family_cal_idx].id,
                parent_calendar_id=calendars[family_cal_idx].id,
            ),
            # Festa del Codony
            Event(
                name="Festa del Codony",
                description="Lugar: Tremp",
                start_date=datetime(2025, 11, 1, 9, 0),
                end_date=datetime(2025, 11, 1, 14, 0),
                event_type="regular",
                owner_id=users[sonia_idx].id,
                calendar_id=calendars[family_cal_idx].id,
                parent_calendar_id=calendars[family_cal_idx].id,
            ),
        ]
        db.add_all(regular_events)
        db.flush()
        logger.info(f"  ✓ Inserted {len(regular_events)} regular events")

        # 10. Create FC Barcelona match events
        fcb_matches = [
            Event(name="FC Barcelona vs Girona", start_date=datetime(2025, 10, 18, 16, 15), end_date=datetime(2025, 10, 18, 18, 15), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="FC Barcelona vs Olympiakos", start_date=datetime(2025, 10, 21, 18, 45), end_date=datetime(2025, 10, 21, 20, 45), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="Real Madrid vs FC Barcelona", start_date=datetime(2025, 10, 26, 16, 15), end_date=datetime(2025, 10, 26, 18, 15), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="FC Barcelona vs Elche", start_date=datetime(2025, 11, 2, 18, 30), end_date=datetime(2025, 11, 2, 20, 30), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="Club Brugge vs FC Barcelona", start_date=datetime(2025, 11, 5, 21, 0), end_date=datetime(2025, 11, 5, 23, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="Celta de Vigo vs FC Barcelona", start_date=datetime(2025, 11, 9, 21, 0), end_date=datetime(2025, 11, 9, 23, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="FC Barcelona vs Athletic Club", start_date=datetime(2025, 11, 23, 18, 0), end_date=datetime(2025, 11, 23, 20, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="Chelsea vs FC Barcelona", start_date=datetime(2025, 11, 25, 21, 0), end_date=datetime(2025, 11, 25, 23, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="FC Barcelona vs Alavés", start_date=datetime(2025, 11, 30, 18, 0), end_date=datetime(2025, 11, 30, 20, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="Real Betis vs FC Barcelona", start_date=datetime(2025, 12, 7, 18, 0), end_date=datetime(2025, 12, 7, 20, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="FC Barcelona vs Eintracht Frankfurt", start_date=datetime(2025, 12, 9, 21, 0), end_date=datetime(2025, 12, 9, 23, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="FC Barcelona vs Osasuna", start_date=datetime(2025, 12, 14, 18, 0), end_date=datetime(2025, 12, 14, 20, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="Villarreal vs FC Barcelona", start_date=datetime(2025, 12, 21, 18, 0), end_date=datetime(2025, 12, 21, 20, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="Espanyol vs FC Barcelona", start_date=datetime(2026, 1, 4, 18, 0), end_date=datetime(2026, 1, 4, 20, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="FC Barcelona vs Athletic Club", start_date=datetime(2026, 1, 7, 20, 0), end_date=datetime(2026, 1, 7, 22, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="FC Barcelona vs Atlético Madrid", start_date=datetime(2026, 1, 11, 18, 0), end_date=datetime(2026, 1, 11, 20, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="Real Sociedad vs FC Barcelona", start_date=datetime(2026, 1, 18, 18, 0), end_date=datetime(2026, 1, 18, 20, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="FC Barcelona vs Real Oviedo", start_date=datetime(2026, 1, 25, 18, 0), end_date=datetime(2026, 1, 25, 20, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="Slavia Prague vs FC Barcelona", start_date=datetime(2026, 1, 21, 18, 0), end_date=datetime(2026, 1, 21, 20, 0), event_type="regular", owner_id=users[fcb_idx].id),
            Event(name="FC Barcelona vs FC København", start_date=datetime(2026, 1, 28, 18, 0), end_date=datetime(2026, 1, 28, 20, 0), event_type="regular", owner_id=users[fcb_idx].id),
        ]
        db.add_all(fcb_matches)
        db.flush()
        logger.info(f"  ✓ Inserted {len(fcb_matches)} FC Barcelona match events")

        # 11. Create Sonia's additional events
        # Event 1: "Cumpleaños clase Sara" - Regular event on Nov 16 where Sonia invites Miquel
        cumple_sara_event = Event(
            name="Cumpleaños clase Sara",
            description="Celebración del cumpleaños de la clase de Sara",
            start_date=datetime(2025, 11, 16, 17, 0),
            end_date=datetime(2025, 11, 16, 19, 0),
            event_type="regular",
            owner_id=users[sonia_idx].id,
        )
        db.add(cumple_sara_event)
        db.flush()

        # Event 2: "Promociona Madrid" - Recurring event from Nov 16-21, daily at 9am
        promociona_madrid_base = Event(
            name="Promociona Madrid",
            description="Evento promocional diario",
            start_date=datetime(2025, 11, 16, 9, 0),
            end_date=datetime(2025, 11, 16, 10, 0),
            event_type="recurring",
            owner_id=users[sonia_idx].id,
        )
        db.add(promociona_madrid_base)
        db.flush()

        # Create recurring config for Promociona Madrid (daily from Nov 16-21)
        promociona_config = RecurringEventConfig(
            event_id=promociona_madrid_base.id,
            days_of_week=[0, 1, 2, 3, 4, 5, 6],  # All days
            time_slots=[{"start": "09:00", "end": "10:00"}],
            recurrence_end_date=datetime(2025, 11, 21, 23, 59),
        )
        db.add(promociona_config)
        db.flush()

        # Generate instances for Promociona Madrid (Nov 16-21, 6 days)
        promociona_instances = []
        for day_offset in range(6):  # 16, 17, 18, 19, 20, 21
            instance_date = datetime(2025, 11, 16, 9, 0) + timedelta(days=day_offset)
            promociona_instances.append(Event(
                name="Promociona Madrid",
                description=promociona_madrid_base.description,
                start_date=instance_date,
                end_date=instance_date + timedelta(hours=1),
                event_type="regular",
                owner_id=users[sonia_idx].id,
                parent_recurring_event_id=promociona_config.id,
            ))
        db.add_all(promociona_instances)
        db.flush()
        logger.info(f"  ✓ Inserted 2 additional Sonia events (1 regular + 1 recurring with {len(promociona_instances)} instances)")

        # 12. Create event interactions
        interactions = []

        # Owner interactions for base recurring events
        for base_event in base_recurring_events:
            interactions.append(EventInteraction(
                event_id=base_event.id,
                user_id=users[sonia_idx].id,
                interaction_type="joined",
                status="accepted",
                role="owner",
            ))

        # Owner interactions for generated recurring instances
        for gen_event in generated_events:
            interactions.append(EventInteraction(
                event_id=gen_event.id,
                user_id=users[sonia_idx].id,
                interaction_type="joined",
                status="accepted",
                role="owner",
            ))

        # Owner interactions for birthday events
        for bday_event in birthday_events:
            interactions.append(EventInteraction(
                event_id=bday_event.id,
                user_id=users[sonia_idx].id,
                interaction_type="joined",
                status="accepted",
                role="owner",
            ))

        # Owner interactions for regular events
        for reg_event in regular_events:
            interactions.append(EventInteraction(
                event_id=reg_event.id,
                user_id=users[sonia_idx].id,
                interaction_type="joined",
                status="accepted",
                role="owner",
            ))

        # Owner interactions for FC Barcelona matches
        for fcb_event in fcb_matches:
            interactions.append(EventInteraction(
                event_id=fcb_event.id,
                user_id=users[fcb_idx].id,
                interaction_type="joined",
                status="accepted",
                role="owner",
            ))

        # Miquel subscribed to fcbarcelona (subscribed to all their events)
        for fcb_event in fcb_matches:
            interactions.append(EventInteraction(
                event_id=fcb_event.id,
                user_id=users[miquel_idx].id,
                interaction_type="subscribed",
                status="accepted",
            ))

        # Owner interactions for Sonia's additional events
        # Owner of "Cumpleaños clase Sara"
        interactions.append(EventInteraction(
            event_id=cumple_sara_event.id,
            user_id=users[sonia_idx].id,
            interaction_type="joined",
            status="accepted",
            role="owner",
        ))

        # Miquel invited to "Cumpleaños clase Sara" by Sonia
        interactions.append(EventInteraction(
            event_id=cumple_sara_event.id,
            user_id=users[miquel_idx].id,
            interaction_type="invited",
            status="pending",
            invited_by_user_id=users[sonia_idx].id,
        ))

        # Owner of "Promociona Madrid" base event
        interactions.append(EventInteraction(
            event_id=promociona_madrid_base.id,
            user_id=users[sonia_idx].id,
            interaction_type="joined",
            status="accepted",
            role="owner",
        ))

        # Owner interactions for all "Promociona Madrid" instances
        for promociona_instance in promociona_instances:
            interactions.append(EventInteraction(
                event_id=promociona_instance.id,
                user_id=users[sonia_idx].id,
                interaction_type="joined",
                status="accepted",
                role="owner",
            ))

        # Miquel invited to Esquí events by Sonia (base event + all instances)
        # Invitation to base recurring event
        interactions.append(EventInteraction(
            event_id=base_recurring_events[3].id,  # Esquí base event
            user_id=users[miquel_idx].id,
            interaction_type="invited",
            status="pending",
            invited_by_user_id=users[sonia_idx].id,
        ))

        # Invitations to all Esquí instances
        for ski_event in ski_instances:
            interactions.append(EventInteraction(
                event_id=ski_event.id,
                user_id=users[miquel_idx].id,
                interaction_type="invited",
                status="pending",
                invited_by_user_id=users[sonia_idx].id,
            ))

        db.add_all(interactions)
        db.flush()
        logger.info(f"  ✓ Inserted {len(interactions)} event interactions")

        # 12. Create event ban for TDB user
        # Ban TDB from the first regular event (Concierto de Katy Perry)
        event_bans = [
            EventBan(
                event_id=regular_events[0].id,
                user_id=users[tdb_idx].id,
                banned_by=users[sonia_idx].id,
            ),
        ]
        db.add_all(event_bans)
        db.flush()
        logger.info(f"  ✓ Inserted {len(event_bans)} event bans")

        # 13. Create user blocks for PolR (blocked by all main users)
        user_blocks = [
            UserBlock(blocker_user_id=users[sonia_idx].id, blocked_user_id=users[polr_idx].id),
            UserBlock(blocker_user_id=users[miquel_idx].id, blocked_user_id=users[polr_idx].id),
            UserBlock(blocker_user_id=users[ada_idx].id, blocked_user_id=users[polr_idx].id),
            UserBlock(blocker_user_id=users[sara_idx].id, blocked_user_id=users[polr_idx].id),
        ]
        db.add_all(user_blocks)
        db.flush()
        logger.info(f"  ✓ Inserted {len(user_blocks)} user blocks")

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
