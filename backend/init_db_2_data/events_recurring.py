"""
Recurring Events - Eventos recurrentes con configuración
"""

from models import Event, RecurringEventConfig
from .helpers import get_dates
from datetime import datetime


def create_recurring_events(db, private_users, public_users):
    """Create recurring events with configurations"""
    events = []
    configs = []
    dates = get_dates()

    sonia = private_users['sonia']
    miquel = private_users['miquel']
    all_users = private_users['all_users']
    greenpointbcn = public_users['greenpointbcn']

    # Evento Base 1: Sincro Lunes-Miércoles
    event_sincro = Event(
        id=100,
        name="Sincro Lunes-Miércoles",
        description="Clase de natación sincronizada",
        start_date=dates['in_2_days'].replace(hour=17, minute=30),
        event_type="recurring",
        owner_id=sonia.id
    )
    events.append(event_sincro)

    config_sincro = RecurringEventConfig(
        event_id=100,
        recurrence_type="weekly",
        schedule={"interval": 1, "days_of_week": "1,3"},  # Lunes y Miércoles
        recurrence_end_date=datetime(2026, 6, 23, 17, 30, 0)
    )
    configs.append(config_sincro)

    # Evento Base 2: Comida Semanal Viernes
    event_comida = Event(
        id=101,
        name="Comida Semanal Viernes",
        description="Comida familiar todos los viernes",
        start_date=dates['in_4_days'].replace(hour=14, minute=0),
        event_type="recurring",
        owner_id=all_users[4].id  # Padre
    )
    events.append(event_comida)

    config_comida = RecurringEventConfig(
        event_id=101,
        recurrence_type="weekly",
        schedule={"interval": 1, "days_of_week": "5"},  # Viernes
        recurrence_end_date=None  # Perpetual
    )
    configs.append(config_comida)

    # Evento Base 3: Yoga Matinal (público)
    event_yoga_rec = Event(
        id=102,
        name="Yoga Matinal Recurrente",
        description="Clase de yoga lunes, miércoles y viernes",
        start_date=dates['tomorrow'].replace(hour=7, minute=0),
        event_type="recurring",
        owner_id=greenpointbcn.id
    )
    events.append(event_yoga_rec)

    config_yoga = RecurringEventConfig(
        event_id=102,
        recurrence_type="weekly",
        schedule={"interval": 1, "days_of_week": "1,3,5"},  # Lun, Mie, Vie
        recurrence_end_date=None
    )
    configs.append(config_yoga)

    # Cumpleaños (recurring yearly perpetual)
    # Miquel: 30 abril
    event_b_miquel = Event(
        id=110,
        name="Cumpleaños Miquel",
        description="Cumpleaños de Miquel",
        start_date=datetime(2026, 4, 30, 0, 0, 0),
        event_type="recurring",
        owner_id=miquel.id
    )
    events.append(event_b_miquel)

    config_b_miquel = RecurringEventConfig(
        event_id=110,
        recurrence_type="yearly",
        schedule={"interval": 1},
        recurrence_end_date=None  # Perpetual
    )
    configs.append(config_b_miquel)

    # Ada: 6 septiembre
    event_b_ada = Event(
        id=111,
        name="Cumpleaños Ada",
        description="Cumpleaños de Ada",
        start_date=datetime(2026, 9, 6, 0, 0, 0),
        event_type="recurring",
        owner_id=private_users['ada'].id
    )
    events.append(event_b_ada)

    config_b_ada = RecurringEventConfig(
        event_id=111,
        recurrence_type="yearly",
        schedule={"interval": 1},
        recurrence_end_date=None
    )
    configs.append(config_b_ada)

    # Sonia: 31 enero
    event_b_sonia = Event(
        id=112,
        name="Cumpleaños Sonia",
        description="Cumpleaños de Sonia",
        start_date=datetime(2026, 1, 31, 0, 0, 0),
        event_type="recurring",
        owner_id=sonia.id
    )
    events.append(event_b_sonia)

    config_b_sonia = RecurringEventConfig(
        event_id=112,
        recurrence_type="yearly",
        schedule={"interval": 1},
        recurrence_end_date=None
    )
    configs.append(config_b_sonia)

    # Sara: 2 diciembre
    event_b_sara = Event(
        id=113,
        name="Cumpleaños Sara",
        description="Cumpleaños de Sara",
        start_date=datetime(2026, 12, 2, 0, 0, 0),
        event_type="recurring",
        owner_id=private_users['sara'].id
    )
    events.append(event_b_sara)

    config_b_sara = RecurringEventConfig(
        event_id=113,
        recurrence_type="yearly",
        schedule={"interval": 1},
        recurrence_end_date=None
    )
    configs.append(config_b_sara)

    db.add_all(events)
    db.add_all(configs)
    db.flush()

    return {
        'event_sincro': event_sincro,
        'event_comida': event_comida,
        'event_yoga_rec': event_yoga_rec,
        'all_recurring_events': events
    }
