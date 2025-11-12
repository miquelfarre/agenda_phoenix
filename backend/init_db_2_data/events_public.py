"""
Public Events - Eventos de usuarios públicos/organizaciones
"""

from datetime import timedelta
from models import Event
from .helpers import get_dates


def create_public_events(db, public_users):
    """Create public events from organizations"""
    events = []
    dates = get_dates()

    fcbarcelona = public_users['fcbarcelona']
    fitzonegym = public_users['fitzonegym']
    greenpointbcn = public_users['greenpointbcn']
    saborcatalunya = public_users['saborcatalunya']
    teatrebarcelona = public_users['teatrebarcelona']
    primaverasound = public_users['primaverasound']

    # FC Barcelona Events
    event_clasico = Event(
        id=20,
        name="Barça vs Madrid - El Clásico",
        description="El partido más esperado del año",
        start_date=dates['in_30_days'].replace(hour=21, minute=0),
        event_type="regular",
        owner_id=fcbarcelona.id
    )
    events.append(event_clasico)

    event_liga = Event(
        id=21,
        name="Barça vs Atletico - Liga",
        description="Partido de Liga",
        start_date=dates['in_14_days'].replace(hour=18, minute=30),
        event_type="regular",
        owner_id=fcbarcelona.id
    )
    events.append(event_liga)

    # FitZone Gym Events
    event_spinning = Event(
        id=30,
        name="Clase Spinning",
        description="Clase intensiva de spinning",
        start_date=dates['in_2_days'].replace(hour=19, minute=0),
        event_type="regular",
        owner_id=fitzonegym.id
    )
    events.append(event_spinning)

    event_crossfit = Event(
        id=31,
        name="CrossFit Avanzado",
        description="Sesión de CrossFit nivel avanzado",
        start_date=dates['in_3_days'].replace(hour=18, minute=0),
        event_type="regular",
        owner_id=fitzonegym.id
    )
    events.append(event_crossfit)

    event_yoga_gym = Event(
        id=32,
        name="Yoga en FitZone",
        description="Clase de yoga para relajación",
        start_date=dates['in_5_days'].replace(hour=10, minute=0),
        event_type="regular",
        owner_id=fitzonegym.id
    )
    events.append(event_yoga_gym)

    # Green Point Yoga Events
    event_yoga_morning = Event(
        id=40,
        name="Yoga Matinal",
        description="Sesión de yoga matinal",
        start_date=dates['tomorrow'].replace(hour=7, minute=0),
        event_type="regular",
        owner_id=greenpointbcn.id
    )
    events.append(event_yoga_morning)

    event_meditation = Event(
        id=41,
        name="Meditación Guiada",
        description="Sesión de meditación guiada",
        start_date=dates['in_3_days'].replace(hour=19, minute=30),
        event_type="regular",
        owner_id=greenpointbcn.id
    )
    events.append(event_meditation)

    # Restaurante Events
    event_degustacion = Event(
        id=50,
        name="Degustación de Vinos",
        description="Cata de vinos de la Rioja con maridaje",
        start_date=dates['in_7_days'].replace(hour=20, minute=0),
        event_type="regular",
        owner_id=saborcatalunya.id
    )
    events.append(event_degustacion)

    event_taller_cocina = Event(
        id=51,
        name="Taller de Cocina Mediterránea",
        description="Aprende a cocinar platos tradicionales",
        start_date=dates['in_14_days'].replace(hour=18, minute=30),
        event_type="regular",
        owner_id=saborcatalunya.id
    )
    events.append(event_taller_cocina)

    # Teatro Events
    event_teatro1 = Event(
        id=60,
        name="Hamlet - Shakespeare",
        description="Representación de Hamlet en catalán",
        start_date=dates['in_10_days'].replace(hour=20, minute=30),
        event_type="regular",
        owner_id=teatrebarcelona.id
    )
    events.append(event_teatro1)

    event_teatro2 = Event(
        id=61,
        name="La Casa de Bernarda Alba",
        description="Obra de Federico García Lorca",
        start_date=dates['in_21_days'].replace(hour=19, minute=0),
        event_type="regular",
        owner_id=teatrebarcelona.id
    )
    events.append(event_teatro2)

    # Primavera Sound Events
    event_concert1 = Event(
        id=70,
        name="Primavera Sound 2025 - Día 1",
        description="Primera jornada del festival",
        start_date=dates['in_120_days'].replace(hour=16, minute=0),
        event_type="regular",
        owner_id=primaverasound.id
    )
    events.append(event_concert1)

    event_concert2 = Event(
        id=71,
        name="Primavera Sound 2025 - Día 2",
        description="Segunda jornada del festival",
        start_date=(dates['in_120_days'] + timedelta(days=1)).replace(hour=16, minute=0),
        event_type="regular",
        owner_id=primaverasound.id
    )
    events.append(event_concert2)

    db.add_all(events)
    db.flush()

    return {
        'event_clasico': event_clasico,
        'event_spinning': event_spinning,
        'event_yoga_morning': event_yoga_morning,
        'event_degustacion': event_degustacion,
        'event_teatro1': event_teatro1,
        'all_public_events': events
    }
