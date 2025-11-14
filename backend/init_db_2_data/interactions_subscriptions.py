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
    all_public = public_events["all_public_events"]

    # FC Barcelona (owner_id=86) - eventos 20-24
    # Sonia suscrita a FC Barcelona (TODOS los eventos 20-24)
    fcbarcelona_event_ids = [20, 21, 22, 23, 24]
    print(f'🎯 Creating {len(fcbarcelona_event_ids)} subscriptions for Sonia to FC Barcelona events: {fcbarcelona_event_ids}')
    for event_id in fcbarcelona_event_ids:
        print(f'   - Event {event_id}')
        interactions.append(EventInteraction(event_id=event_id, user_id=sonia.id, interaction_type="subscribed", status="accepted"))

    # Miquel también suscrito a FC Barcelona
    for event_id in fcbarcelona_event_ids:
        interactions.append(EventInteraction(event_id=event_id, user_id=miquel.id, interaction_type="subscribed", status="accepted"))

    # Muchos usuarios suscritos a FC Barcelona (ID 10-50)
    for user in all_users[9:50]:
        for event_id in fcbarcelona_event_ids:
            interactions.append(EventInteraction(event_id=event_id, user_id=user.id, interaction_type="subscribed", status="accepted"))

    # FitZone Gym (owner_id=88) - eventos 30-35
    fitzone_event_ids = [30, 31, 32, 33, 34, 35]
    for event_id in fitzone_event_ids:
        interactions.append(EventInteraction(event_id=event_id, user_id=sonia.id, interaction_type="subscribed", status="accepted"))

    # Otros suscritos a FitZone
    for user in [miquel, ada] + all_users[10:25]:
        for event_id in fitzone_event_ids:
            interactions.append(EventInteraction(event_id=event_id, user_id=user.id, interaction_type="subscribed", status="accepted"))

    # Green Point Yoga (owner_id=92) - eventos 40-44
    greenpoint_event_ids = [40, 41, 42, 43, 44]
    for user in [sonia, ada] + all_users[11:30]:
        for event_id in greenpoint_event_ids:
            interactions.append(EventInteraction(event_id=event_id, user_id=user.id, interaction_type="subscribed", status="accepted"))

    # Restaurante El Buen Sabor (owner_id=89) - eventos 50-53
    sabor_event_ids = [50, 51, 52, 53]
    for user in [sonia, miquel] + all_users[15:35]:
        for event_id in sabor_event_ids:
            interactions.append(EventInteraction(event_id=event_id, user_id=user.id, interaction_type="subscribed", status="accepted"))

    # Teatro Nacional Catalunya (owner_id=87) - eventos 60-64
    teatre_event_ids = [60, 61, 62, 63, 64]
    for user in [sonia, ada] + all_users[12:28]:
        for event_id in teatre_event_ids:
            interactions.append(EventInteraction(event_id=event_id, user_id=user.id, interaction_type="subscribed", status="accepted"))

    # Primavera Sound (owner_id=97) - eventos 70-71
    primavera_event_ids = [70, 71]
    for user in all_users[20:40]:
        for event_id in primavera_event_ids:
            interactions.append(EventInteraction(event_id=event_id, user_id=user.id, interaction_type="subscribed", status="accepted"))

    db.add_all(interactions)
    db.flush()

    return interactions
