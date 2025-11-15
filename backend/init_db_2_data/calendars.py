"""
Calendars - Calendarios privados y públicos con share_hash
"""

from models import Calendar, CalendarMembership, CalendarSubscription
from .helpers import generate_share_hash
from datetime import datetime


def create_calendars(db, private_users, public_users):
    """Create calendars (private, public, shared)"""
    calendars = []
    memberships = []
    subscriptions = []

    sonia = private_users["sonia"]
    miquel = private_users["miquel"]
    ada = private_users["ada"]
    sara = private_users["sara"]
    all_users = private_users["all_users"]

    # === CALENDARIOS PRIVADOS DE SONIA ===

    # Calendar Personal (solo Sonia)
    cal_personal = Calendar(id=1, name="Personal", description="Eventos personales de Sonia", owner_id=sonia.id, is_public=False, share_hash=None)
    calendars.append(cal_personal)
    memberships.append(CalendarMembership(calendar_id=cal_personal.id, user_id=sonia.id, role="owner", status="accepted"))

    # Calendar Familia (compartido con Miquel, Ada, Sara)
    cal_familia = Calendar(id=2, name="Familia", description="Eventos familiares", owner_id=sonia.id, is_public=False, share_hash=None)
    calendars.append(cal_familia)
    memberships.append(CalendarMembership(calendar_id=cal_familia.id, user_id=sonia.id, role="owner", status="accepted"))
    memberships.append(CalendarMembership(calendar_id=cal_familia.id, user_id=miquel.id, role="admin", status="accepted"))
    memberships.append(CalendarMembership(calendar_id=cal_familia.id, user_id=ada.id, role="member", status="accepted"))
    memberships.append(CalendarMembership(calendar_id=cal_familia.id, user_id=sara.id, role="member", status="accepted"))

    # Calendar Trabajo (compartido con equipo)
    cal_trabajo = Calendar(id=3, name="Trabajo", description="Reuniones y deadlines", owner_id=sonia.id, is_public=False, share_hash=None)
    calendars.append(cal_trabajo)
    memberships.append(CalendarMembership(calendar_id=cal_trabajo.id, user_id=sonia.id, role="owner", status="accepted"))
    # Añadir compañeros de trabajo (ID 11-15)
    for user in all_users[10:15]:
        memberships.append(CalendarMembership(calendar_id=cal_trabajo.id, user_id=user.id, role="member", status="accepted"))

    # Calendar Cumpleaños (público, de Sonia)
    cal_cumpleanos = Calendar(id=4, name="Cumpleaños", description="Calendario para cumpleaños", owner_id=sonia.id, is_public=True, share_hash="cumple24", subscriber_count=50)
    calendars.append(cal_cumpleanos)
    memberships.append(CalendarMembership(calendar_id=cal_cumpleanos.id, user_id=sonia.id, role="owner", status="accepted"))

    # === CALENDARIOS PÚBLICOS CON SHARE_HASH (de usuarios PRIVADOS) ===
    # Los usuarios PRIVADOS pueden crear calendarios públicos con share_hash para compartirlos
    # Los usuarios PÚBLICOS no necesitan calendarios con share_hash (la gente se suscribe directamente al usuario)

    # Calendar de Sara (usuario privado) - Curador de eventos de Barça
    cal_fcb = Calendar(id=10, name="FC Barcelona - Temporada 2025/26", description="Todos los partidos del Barça curados por fan", owner_id=sara.id, is_public=True, share_hash="fcb25_26", subscriber_count=10000)  # Sara (usuario privado ID 4)
    calendars.append(cal_fcb)
    memberships.append(CalendarMembership(calendar_id=cal_fcb.id, user_id=sara.id, role="owner", status="accepted"))

    # Calendar de Miquel (usuario privado) - Fan de música
    cal_ps = Calendar(id=11, name="Conciertos Primavera Sound 2025", description="Lineup completo del festival", owner_id=miquel.id, is_public=True, share_hash="ps2025xx", subscriber_count=2000)  # Miquel (usuario privado ID 2)
    calendars.append(cal_ps)
    memberships.append(CalendarMembership(calendar_id=cal_ps.id, user_id=miquel.id, role="owner", status="accepted"))

    # Calendar de Ada (usuario privado) - Festivos de Barcelona
    cal_merce = Calendar(id=12, name="Festivos Barcelona 2025-2026", description="Todos los festivos y celebraciones de Barcelona", owner_id=ada.id, is_public=True, share_hash="bcn2025f", subscriber_count=500)  # Ada (usuario privado ID 3)
    calendars.append(cal_merce)
    memberships.append(CalendarMembership(calendar_id=cal_merce.id, user_id=ada.id, role="owner", status="accepted"))

    # Calendar de usuario privado ID 11 (primer amigo cercano) - Clases gym
    user_11 = all_users[10]  # ID 11
    cal_fitzone = Calendar(id=13, name="Clases FitZone", description="Todas las clases del gimnasio", owner_id=user_11.id, is_public=True, share_hash="fitzone2", subscriber_count=300)  # Usuario privado ID 11
    calendars.append(cal_fitzone)
    memberships.append(CalendarMembership(calendar_id=cal_fitzone.id, user_id=user_11.id, role="owner", status="accepted"))

    # Calendar de usuario privado ID 12 - Clases de yoga
    user_12 = all_users[11]  # ID 12
    cal_yoga = Calendar(id=14, name="Clases de Yoga", description="Horario de clases de yoga y meditación", owner_id=user_12.id, is_public=True, share_hash="yogabcn1", subscriber_count=200)  # Usuario privado ID 12
    calendars.append(cal_yoga)
    memberships.append(CalendarMembership(calendar_id=cal_yoga.id, user_id=user_12.id, role="owner", status="accepted"))

    # === SUSCRIPCIONES DE USUARIOS A CALENDARIOS PÚBLICOS ===
    # Usar CalendarSubscription (no CalendarMembership) para calendarios públicos

    # Sonia suscrita a calendarios públicos
    for cal in [cal_fcb, cal_ps, cal_merce, cal_fitzone, cal_yoga]:
        subscriptions.append(CalendarSubscription(calendar_id=cal.id, user_id=sonia.id, status="active"))

    # Miquel suscrito a algunos
    for cal in [cal_fcb, cal_fitzone]:
        subscriptions.append(CalendarSubscription(calendar_id=cal.id, user_id=miquel.id, status="active"))

    # Ada suscrita a varios
    for cal in [cal_fcb, cal_ps, cal_yoga]:
        subscriptions.append(CalendarSubscription(calendar_id=cal.id, user_id=ada.id, status="active"))

    # Otros usuarios suscritos a calendarios públicos
    # 30 usuarios (ID 11-40) suscritos a FC Barcelona
    for user in all_users[10:40]:
        subscriptions.append(CalendarSubscription(calendar_id=cal_fcb.id, user_id=user.id, status="active"))

    # Add all to database
    db.add_all(calendars)
    db.add_all(memberships)
    db.add_all(subscriptions)
    db.flush()

    return {"cal_personal": cal_personal, "cal_familia": cal_familia, "cal_trabajo": cal_trabajo, "cal_cumpleanos": cal_cumpleanos, "cal_fcb": cal_fcb, "cal_ps": cal_ps, "cal_merce": cal_merce, "cal_fitzone": cal_fitzone, "cal_yoga": cal_yoga, "all_calendars": calendars, "all_subscriptions": subscriptions}
