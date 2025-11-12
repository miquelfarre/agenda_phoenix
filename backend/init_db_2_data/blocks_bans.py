"""
User Blocks (Event bans removed)
"""

from models import UserBlock


def create_blocks_and_bans(db, private_users, private_events):
    """Create user blocks"""
    blocks = []

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

    db.add_all(blocks)
    db.flush()

    return {
        'blocks': blocks
    }
