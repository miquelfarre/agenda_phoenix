"""
Private Events - Eventos privados de usuarios
"""

from models import Event
from .helpers import get_dates


def create_private_events(db, private_users, groups_data):
    """Create private events"""
    events = []
    dates = get_dates()

    sonia = private_users["sonia"]
    miquel = private_users["miquel"]
    ada = private_users["ada"]
    sara = private_users["sara"]
    all_users = private_users["all_users"]

    # Evento 1: Cena Cumpleaños Sonia
    event1 = Event(id=1, name="Cena Cumpleaños Sonia", description="Celebración cumpleaños de Sonia con familia y amigos", start_date=dates["in_14_days"].replace(hour=20, minute=0), event_type="regular", owner_id=sonia.id)
    events.append(event1)

    # Evento 2: Escapada Fin de Semana
    event2 = Event(id=2, name="Escapada Fin de Semana", description="Fin de semana en la montaña", start_date=dates["in_21_days"].replace(hour=10, minute=0), event_type="regular", owner_id=miquel.id)
    events.append(event2)

    # Evento 3: Comida Familia Navidad
    event3 = Event(id=3, name="Comida Familia Navidad", description="Comida navideña familiar", start_date=dates["in_30_days"].replace(hour=14, minute=0), event_type="regular", owner_id=all_users[4].id)  # Padre de Sonia
    events.append(event3)

    # Evento 4: Quedada Running Domingo
    event4 = Event(id=4, name="Quedada Running Domingo", description="Ruta running por Diagonal", start_date=dates["in_7_days"].replace(hour=9, minute=0), event_type="regular", owner_id=all_users[8].id)  # Marc
    events.append(event4)

    # Evento 5: Fiesta Casa Ada
    event5 = Event(id=5, name="Fiesta Casa Ada", description="Fiesta en casa de Ada", start_date=dates["in_10_days"].replace(hour=22, minute=0), event_type="regular", owner_id=ada.id)
    events.append(event5)

    # Evento 6: Cena Japonés
    event6 = Event(id=6, name="Cena Japonés", description="Cena en restaurante japonés", start_date=dates["in_5_days"].replace(hour=21, minute=0), event_type="regular", owner_id=miquel.id)
    events.append(event6)

    # Evento 7: BBQ Vecinos
    event7 = Event(id=7, name="BBQ Vecinos", description="Barbacoa en terraza comunitaria", start_date=dates["in_14_days"].replace(hour=13, minute=0), event_type="regular", owner_id=all_users[15].id)
    events.append(event7)

    # Evento 8: Tarde Juegos Mesa
    event8 = Event(id=8, name="Tarde Juegos Mesa", description="Tarde de juegos de mesa", start_date=dates["in_3_days"].replace(hour=18, minute=0), event_type="regular", owner_id=sonia.id)
    events.append(event8)

    # Evento 9: Excursión Montserrat
    event9 = Event(id=9, name="Excursión Montserrat", description="Excursión a Montserrat", start_date=dates["in_21_days"].replace(hour=8, minute=30), event_type="regular", owner_id=all_users[10].id)
    events.append(event9)

    # Evento 10: Cena Compis Trabajo
    event10 = Event(id=10, name="Cena Compis Trabajo", description="Cena equipo de trabajo", start_date=dates["in_7_days"].replace(hour=21, minute=30), event_type="regular", owner_id=sonia.id)
    events.append(event10)

    db.add_all(events)
    db.flush()

    return {
        "event_cumple_sonia": event1,
        "event_escapada": event2,
        "event_navidad": event3,
        "event_running": event4,
        "event_fiesta_ada": event5,
        "event_japones": event6,
        "event_bbq": event7,
        "event_juegos": event8,
        "event_montserrat": event9,
        "event_cena_trabajo": event10,
        "all_private_events": events,
    }
