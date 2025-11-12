"""
Calendars - Calendarios privados y públicos con share_hash
"""

from models import Calendar, CalendarMembership
from .helpers import generate_share_hash
from datetime import datetime


def create_calendars(db, private_users, public_users):
    """Create calendars (private, public, shared)"""
    calendars = []
    memberships = []

    sonia = private_users['sonia']
    miquel = private_users['miquel']
    ada = private_users['ada']
    sara = private_users['sara']
    all_users = private_users['all_users']

    # === CALENDARIOS PRIVADOS DE SONIA ===

    # Calendar Personal (solo Sonia)
    cal_personal = Calendar(
        id=1,
        name="Personal",
        description="Eventos personales de Sonia",
        owner_id=sonia.id,
        is_public=False,
        share_hash=None
    )
    calendars.append(cal_personal)
    memberships.append(CalendarMembership(
        calendar_id=cal_personal.id,
        user_id=sonia.id,
        role="owner",
        status="accepted"
    ))

    # Calendar Familia (compartido con Miquel, Ada, Sara)
    cal_familia = Calendar(
        id=2,
        name="Familia",
        description="Eventos familiares",
        owner_id=sonia.id,
        is_public=False,
        share_hash=None
    )
    calendars.append(cal_familia)
    memberships.append(CalendarMembership(
        calendar_id=cal_familia.id,
        user_id=sonia.id,
        role="owner",
        status="accepted"
    ))
    memberships.append(CalendarMembership(
        calendar_id=cal_familia.id,
        user_id=miquel.id,
        role="admin",
        status="accepted"
    ))
    memberships.append(CalendarMembership(
        calendar_id=cal_familia.id,
        user_id=ada.id,
        role="member",
        status="accepted"
    ))
    memberships.append(CalendarMembership(
        calendar_id=cal_familia.id,
        user_id=sara.id,
        role="member",
        status="accepted"
    ))

    # Calendar Trabajo (compartido con equipo)
    cal_trabajo = Calendar(
        id=3,
        name="Trabajo",
        description="Reuniones y deadlines",
        owner_id=sonia.id,
        is_public=False,
        share_hash=None
    )
    calendars.append(cal_trabajo)
    memberships.append(CalendarMembership(
        calendar_id=cal_trabajo.id,
        user_id=sonia.id,
        role="owner",
        status="accepted"
    ))
    # Añadir compañeros de trabajo (ID 11-15)
    for user in all_users[10:15]:
        memberships.append(CalendarMembership(
            calendar_id=cal_trabajo.id,
            user_id=user.id,
            role="member",
            status="accepted"
        ))

    # === CALENDARIOS PÚBLICOS CON SHARE_HASH ===

    # ID 86: FC Barcelona
    fcbarcelona = public_users['fcbarcelona']
    cal_fcb = Calendar(
        id=10,
        name="FC Barcelona - Temporada 2025/26",
        description="Todos los partidos del Barça",
        owner_id=fcbarcelona.id,
        is_public=True,
        share_hash="fcb25_26",
        subscriber_count=10000
    )
    calendars.append(cal_fcb)
    memberships.append(CalendarMembership(
        calendar_id=cal_fcb.id,
        user_id=fcbarcelona.id,
        role="owner",
        status="accepted"
    ))

    # ID 97: Primavera Sound
    primaverasound = public_users['primaverasound']
    cal_ps = Calendar(
        id=11,
        name="Conciertos Primavera Sound 2025",
        description="Lineup completo del festival",
        owner_id=primaverasound.id,
        is_public=True,
        share_hash="ps2025xx",
        subscriber_count=2000
    )
    calendars.append(cal_ps)
    memberships.append(CalendarMembership(
        calendar_id=cal_ps.id,
        user_id=primaverasound.id,
        role="owner",
        status="accepted"
    ))

    # ID 91: Festival Mercè
    festivalmerce = public_users['festivalmerce']
    cal_merce = Calendar(
        id=12,
        name="Festivos Barcelona 2025-2026",
        description="Todos los festivos y celebraciones de Barcelona",
        owner_id=festivalmerce.id,
        is_public=True,
        share_hash="bcn2025f",
        subscriber_count=500
    )
    calendars.append(cal_merce)
    memberships.append(CalendarMembership(
        calendar_id=cal_merce.id,
        user_id=festivalmerce.id,
        role="owner",
        status="accepted"
    ))

    # ID 88: FitZone Gym
    fitzonegym = public_users['fitzonegym']
    cal_fitzone = Calendar(
        id=13,
        name="Clases FitZone",
        description="Todas las clases del gimnasio",
        owner_id=fitzonegym.id,
        is_public=True,
        share_hash="fitzone2",
        subscriber_count=300
    )
    calendars.append(cal_fitzone)
    memberships.append(CalendarMembership(
        calendar_id=cal_fitzone.id,
        user_id=fitzonegym.id,
        role="owner",
        status="accepted"
    ))

    # ID 92: Green Point Yoga
    greenpointbcn = public_users['greenpointbcn']
    cal_yoga = Calendar(
        id=14,
        name="Clases de Yoga",
        description="Horario de clases de yoga y meditación",
        owner_id=greenpointbcn.id,
        is_public=True,
        share_hash="yogabcn1",
        subscriber_count=200
    )
    calendars.append(cal_yoga)
    memberships.append(CalendarMembership(
        calendar_id=cal_yoga.id,
        user_id=greenpointbcn.id,
        role="owner",
        status="accepted"
    ))

    # === SUSCRIPCIONES DE USUARIOS A CALENDARIOS PÚBLICOS ===

    # Sonia suscrita a calendarios públicos
    for cal in [cal_fcb, cal_ps, cal_merce, cal_fitzone, cal_yoga]:
        memberships.append(CalendarMembership(
            calendar_id=cal.id,
            user_id=sonia.id,
            role="subscriber",
            status="active"
        ))

    # Miquel suscrito a algunos
    for cal in [cal_fcb, cal_fitzone]:
        memberships.append(CalendarMembership(
            calendar_id=cal.id,
            user_id=miquel.id,
            role="subscriber",
            status="active"
        ))

    # Ada suscrita a varios
    for cal in [cal_fcb, cal_ps, cal_yoga]:
        memberships.append(CalendarMembership(
            calendar_id=cal.id,
            user_id=ada.id,
            role="subscriber",
            status="active"
        ))

    # Otros usuarios suscritos a calendarios públicos
    # 30 usuarios (ID 11-40) suscritos a FC Barcelona
    for user in all_users[10:40]:
        memberships.append(CalendarMembership(
            calendar_id=cal_fcb.id,
            user_id=user.id,
            role="subscriber",
            status="active"
        ))

    # Add all to database
    db.add_all(calendars)
    db.add_all(memberships)
    db.flush()

    return {
        'cal_personal': cal_personal,
        'cal_familia': cal_familia,
        'cal_trabajo': cal_trabajo,
        'cal_fcb': cal_fcb,
        'cal_ps': cal_ps,
        'cal_merce': cal_merce,
        'cal_fitzone': cal_fitzone,
        'cal_yoga': cal_yoga,
        'all_calendars': calendars
    }
