"""
Event Interactions - Invitations
"""

from models import EventInteraction
from datetime import datetime


def create_invitations(db, private_users, private_events, public_events, recurring_events):
    """Create invitations to events"""
    interactions = []

    sonia = private_users["sonia"]
    miquel = private_users["miquel"]
    ada = private_users["ada"]
    sara = private_users["sara"]
    all_users = private_users["all_users"]

    # Evento 1: Cena Cumpleaños Sonia (25 invitados)
    event_cumple = private_events["event_cumple_sonia"]

    # Sonia is owner (joined)
    interactions.append(EventInteraction(event_id=event_cumple.id, user_id=sonia.id, interaction_type="joined", status="accepted", role="owner"))

    # Miquel y Ada como admins
    interactions.append(EventInteraction(event_id=event_cumple.id, user_id=miquel.id, interaction_type="invited", status="accepted", role="admin", invited_by_user_id=sonia.id))

    interactions.append(EventInteraction(event_id=event_cumple.id, user_id=ada.id, interaction_type="invited", status="accepted", role="admin", invited_by_user_id=sonia.id))

    # Familia invitada - todos aceptan
    for user in [sara] + all_users[4:10]:
        interactions.append(EventInteraction(event_id=event_cumple.id, user_id=user.id, interaction_type="invited", status="accepted", invited_by_user_id=sonia.id))

    # Amigos invitados - mayoría acepta
    for i, user in enumerate(all_users[10:25]):
        status = "accepted" if i < 12 else ("pending" if i < 14 else "rejected")
        interactions.append(EventInteraction(event_id=event_cumple.id, user_id=user.id, interaction_type="invited", status=status, invited_by_user_id=sonia.id, cancellation_note="No puedo ir, lo siento" if status == "rejected" else None))

    # Evento 2: Escapada Fin de Semana
    event_escapada = private_events["event_escapada"]

    interactions.append(EventInteraction(event_id=event_escapada.id, user_id=miquel.id, interaction_type="joined", status="accepted", role="owner"))

    interactions.append(EventInteraction(event_id=event_escapada.id, user_id=sonia.id, interaction_type="invited", status="pending", invited_by_user_id=miquel.id, personal_note="Ver si puedo librar el viernes"))

    interactions.append(EventInteraction(event_id=event_escapada.id, user_id=ada.id, interaction_type="invited", status="accepted", invited_by_user_id=miquel.id))

    interactions.append(EventInteraction(event_id=event_escapada.id, user_id=sara.id, interaction_type="invited", status="rejected", invited_by_user_id=miquel.id, cancellation_note="Tengo otro plan ese fin de semana"))

    # Evento 5: Fiesta Casa Ada - Invitaciones en cadena
    event_fiesta = private_events["event_fiesta_ada"]

    interactions.append(EventInteraction(event_id=event_fiesta.id, user_id=ada.id, interaction_type="joined", status="accepted", role="owner"))

    # Ada invita a Sonia, Miquel, y amigos
    interactions.append(EventInteraction(event_id=event_fiesta.id, user_id=sonia.id, interaction_type="invited", status="accepted", invited_by_user_id=ada.id))

    interactions.append(EventInteraction(event_id=event_fiesta.id, user_id=miquel.id, interaction_type="invited", status="accepted", invited_by_user_id=ada.id))

    # Amigos de Ada
    for user in all_users[10:15]:
        interactions.append(EventInteraction(event_id=event_fiesta.id, user_id=user.id, interaction_type="invited", status="accepted" if user.id % 2 == 0 else "pending", invited_by_user_id=ada.id))

    # Sonia invita a más gente (invitaciones en cadena)
    interactions.append(EventInteraction(event_id=event_fiesta.id, user_id=all_users[20].id, interaction_type="invited", status="accepted", invited_by_user_id=sonia.id))

    interactions.append(EventInteraction(event_id=event_fiesta.id, user_id=all_users[21].id, interaction_type="invited", status="pending", invited_by_user_id=sonia.id))

    # Evento 20: El Clásico (evento público)
    # CASO ESPECIAL: Sonia tiene doble interaction
    event_clasico = public_events["event_clasico"]

    # Miquel invita a Sonia, Ada, Sara
    interactions.append(EventInteraction(event_id=event_clasico.id, user_id=sonia.id, interaction_type="invited", status="rejected", is_attending=True, invited_by_user_id=miquel.id, cancellation_note="Prefiero ir por mi cuenta, gracias"))  # Rechaza invitación pero va sola

    interactions.append(EventInteraction(event_id=event_clasico.id, user_id=ada.id, interaction_type="invited", status="accepted", invited_by_user_id=miquel.id))

    interactions.append(EventInteraction(event_id=event_clasico.id, user_id=sara.id, interaction_type="invited", status="pending", invited_by_user_id=miquel.id))

    # Evento 30: Clase Spinning (evento público)
    # CASO DOBLE INTERACTION: Sonia suscrita + invitada por Miquel
    event_spinning = public_events["event_spinning"]

    interactions.append(EventInteraction(event_id=event_spinning.id, user_id=sonia.id, interaction_type="invited", status="pending", invited_by_user_id=miquel.id, personal_note="¿Vienes a spinning el martes? Vamos juntos 🚴‍♂️", read_at=None))  # Unread

    # Running event
    event_running = private_events["event_running"]
    owner_running = all_users[8]

    interactions.append(EventInteraction(event_id=event_running.id, user_id=owner_running.id, interaction_type="joined", status="accepted", role="owner"))

    # 25 invitados vía grupo
    for i, user in enumerate([sonia, miquel, ada] + all_users[10:32]):
        status = "accepted" if i < 18 else ("pending" if i < 23 else "rejected")
        interactions.append(EventInteraction(event_id=event_running.id, user_id=user.id, interaction_type="invited", status=status, invited_by_user_id=owner_running.id))

    db.add_all(interactions)
    db.flush()

    return interactions
