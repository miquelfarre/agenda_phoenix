"""
Event Interactions - Subscriptions to public events
"""

from models import EventInteraction


def create_subscriptions(db, private_users, public_events):
    """Create subscriptions to public events"""
    interactions = []

    sonia = private_users["sonia"]
    miquel = private_users["miquel"]
    ada = private_users["ada"]
    sara = private_users["sara"]
    all_users = private_users["all_users"]

    # Evento 20: El Clásico - muchos suscriptores
    event_clasico = public_events["event_clasico"]

    # Sonia suscrita (además de invitación rechazada)
    interactions.append(EventInteraction(event_id=event_clasico.id, user_id=sonia.id, interaction_type="subscribed", status="accepted"))

    # Miquel suscrito
    interactions.append(EventInteraction(event_id=event_clasico.id, user_id=miquel.id, interaction_type="subscribed", status="accepted"))

    # Muchos usuarios suscritos (ID 10-50)
    for user in all_users[9:50]:
        interactions.append(EventInteraction(event_id=event_clasico.id, user_id=user.id, interaction_type="subscribed", status="accepted"))

    # Evento 30: Clase Spinning
    event_spinning = public_events["event_spinning"]

    # Sonia suscrita (además de la invitación de Miquel)
    interactions.append(EventInteraction(event_id=event_spinning.id, user_id=sonia.id, interaction_type="subscribed", status="accepted"))

    # Otros suscritos a spinning
    for user in [miquel, ada] + all_users[10:25]:
        interactions.append(EventInteraction(event_id=event_spinning.id, user_id=user.id, interaction_type="subscribed", status="accepted"))

    # Evento 40: Yoga Matinal
    event_yoga = public_events["event_yoga_morning"]

    for user in [sonia, ada] + all_users[11:30]:
        interactions.append(EventInteraction(event_id=event_yoga.id, user_id=user.id, interaction_type="subscribed", status="accepted"))

    # Evento 50: Degustación de Vinos
    event_degustacion = public_events["event_degustacion"]

    for user in [sonia, miquel] + all_users[15:35]:
        interactions.append(EventInteraction(event_id=event_degustacion.id, user_id=user.id, interaction_type="subscribed", status="accepted"))

    # Evento 60: Teatro
    event_teatro = public_events["event_teatro1"]

    for user in [sonia, ada] + all_users[12:28]:
        interactions.append(EventInteraction(event_id=event_teatro.id, user_id=user.id, interaction_type="subscribed", status="accepted"))

    # Otros eventos públicos - más suscripciones
    all_public = public_events["all_public_events"]

    # Cada evento público tiene entre 10-30 suscriptores
    for event in all_public:
        if event.id in [20, 30, 40, 50, 60]:  # Ya procesados
            continue

        # Asignar suscriptores aleatorios
        num_subscribers = min(20, len(all_users) - 10)
        for i in range(num_subscribers):
            user = all_users[10 + (event.id % 30) + i]
            if user.id not in [interaction.user_id for interaction in interactions if interaction.event_id == event.id]:
                interactions.append(EventInteraction(event_id=event.id, user_id=user.id, interaction_type="subscribed", status="accepted"))

    db.add_all(interactions)
    db.flush()

    return interactions
