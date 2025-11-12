"""
User Blocks and Event Bans
"""

from models import UserBlock, EventBan


def create_blocks_and_bans(db, private_users, private_events):
    """Create user blocks and event bans"""
    blocks = []
    bans = []

    sonia = private_users['sonia']
    all_users = private_users['all_users']

    # === USER BLOCKS ===

    # Sonia bloquea a usuario 50 (ex-pareja)
    blocks.append(UserBlock(
        blocker_user_id=sonia.id,
        blocked_user_id=all_users[49].id  # ID 50
    ))

    # Sonia bloquea a usuario 75 (spam)
    blocks.append(UserBlock(
        blocker_user_id=sonia.id,
        blocked_user_id=all_users[74].id  # ID 75
    ))

    # Usuario 63 bloquea a Sonia
    blocks.append(UserBlock(
        blocker_user_id=all_users[62].id,  # ID 63
        blocked_user_id=sonia.id
    ))

    # Algunos bloqueos entre otros usuarios
    blocks.append(UserBlock(
        blocker_user_id=all_users[10].id,
        blocked_user_id=all_users[45].id
    ))

    blocks.append(UserBlock(
        blocker_user_id=all_users[20].id,
        blocked_user_id=all_users[55].id
    ))

    # === EVENT BANS ===

    # Evento fiesta Ada: ban a usuario problemático
    event_fiesta = private_events['event_fiesta_ada']

    bans.append(EventBan(
        event_id=event_fiesta.id,
        user_id=all_users[81].id,  # ID 82
        banned_by=private_users['ada'].id,
        reason="Comportamiento inapropiado en evento anterior"
    ))

    # Evento running: ban a usuario
    event_running = private_events['event_running']

    bans.append(EventBan(
        event_id=event_running.id,
        user_id=all_users[70].id,  # ID 71
        banned_by=all_users[8].id,  # Owner
        reason="No respeta las normas del grupo"
    ))

    db.add_all(blocks)
    db.add_all(bans)
    db.flush()

    return {
        'blocks': blocks,
        'bans': bans
    }
