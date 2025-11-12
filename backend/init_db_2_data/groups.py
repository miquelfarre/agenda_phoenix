"""
Groups and Group Memberships
"""

from models import Group, GroupMembership


def create_groups(db, private_users):
    """Create groups with memberships"""
    groups = []
    memberships = []

    sonia = private_users["sonia"]
    miquel = private_users["miquel"]
    ada = private_users["ada"]
    sara = private_users["sara"]
    all_users = private_users["all_users"]

    # Group 1: Familia Martínez
    group_familia = Group(id=1, name="Familia Martínez", description="Grupo familiar", owner_id=sonia.id)
    groups.append(group_familia)

    # Memberships familia
    memberships.append(GroupMembership(group_id=1, user_id=sonia.id, role="owner"))
    memberships.append(GroupMembership(group_id=1, user_id=miquel.id, role="admin"))
    for user in [ada, sara] + all_users[4:10]:
        memberships.append(GroupMembership(group_id=1, user_id=user.id, role="member"))

    # Group 2: Primos
    group_primos = Group(id=2, name="Primos", description="Primos jóvenes", owner_id=ada.id)
    groups.append(group_primos)
    memberships.append(GroupMembership(group_id=2, user_id=ada.id, role="owner"))
    for user in [sonia, sara] + all_users[7:13]:
        memberships.append(GroupMembership(group_id=2, user_id=user.id, role="member"))

    # Group 3: Compis Trabajo
    group_trabajo = Group(id=3, name="Compis Trabajo", description="Equipo de trabajo", owner_id=sonia.id)
    groups.append(group_trabajo)
    memberships.append(GroupMembership(group_id=3, user_id=sonia.id, role="owner"))
    memberships.append(GroupMembership(group_id=3, user_id=all_users[10].id, role="admin"))
    for user in all_users[11:25]:
        memberships.append(GroupMembership(group_id=3, user_id=user.id, role="member"))

    # Group 4: Universidad UPC
    group_uni = Group(id=4, name="Universidad UPC", description="Antiguos compañeros universidad", owner_id=miquel.id)
    groups.append(group_uni)
    memberships.append(GroupMembership(group_id=4, user_id=miquel.id, role="owner"))
    for user in [sonia] + all_users[10:35]:
        memberships.append(GroupMembership(group_id=4, user_id=user.id, role="member"))

    # Group 5: Vecinos Gràcia
    group_vecinos = Group(id=5, name="Vecinos Gràcia", description="Vecinos del barrio", owner_id=all_users[15].id)
    groups.append(group_vecinos)
    memberships.append(GroupMembership(group_id=5, user_id=all_users[15].id, role="owner"))
    for user in [sonia, miquel] + all_users[16:35]:
        memberships.append(GroupMembership(group_id=5, user_id=user.id, role="member"))

    # Group 6: Running Diagonal
    group_running = Group(id=6, name="Running Diagonal", description="Grupo de running", owner_id=all_users[8].id)
    groups.append(group_running)
    memberships.append(GroupMembership(group_id=6, user_id=all_users[8].id, role="owner"))
    for user in [sonia] + all_users[10:40]:
        memberships.append(GroupMembership(group_id=6, user_id=user.id, role="member"))

    # Group 7: Yoga Matinal
    group_yoga = Group(id=7, name="Yoga Matinal", description="Grupo de yoga", owner_id=all_users[11].id)
    groups.append(group_yoga)
    memberships.append(GroupMembership(group_id=7, user_id=all_users[11].id, role="owner"))
    for user in [sonia, ada] + all_users[12:24]:
        memberships.append(GroupMembership(group_id=7, user_id=user.id, role="member"))

    db.add_all(groups)
    db.add_all(memberships)
    db.flush()

    return {"group_familia": group_familia, "group_primos": group_primos, "group_trabajo": group_trabajo, "group_uni": group_uni, "group_vecinos": group_vecinos, "group_running": group_running, "group_yoga": group_yoga, "all_groups": groups}
