"""
Public Users / Organizations (ID 86-100)
15 usuarios públicos que crean eventos y tienen suscriptores
"""

from models import User
from .helpers import ORGANIZACIONES, generate_phone_number


def create_public_users(db):
    """Create all 15 public users (organizations)"""
    users = []
    users_dict = {}

    for idx, org_data in enumerate(ORGANIZACIONES, start=86):
        user = User(
            id=idx, display_name=org_data["name"], phone=None, instagram_username=org_data["instagram"], auth_provider="instagram_login", auth_id=f"public_{org_data['instagram']}_auth", is_public=True, is_admin=False  # Public users don't have phone  # Public user  # Public users can't be admin
        )
        users.append(user)

        # Store with friendly names
        key = org_data["instagram"].replace("@", "")
        users_dict[key] = user

    # Add all to database
    db.add_all(users)
    db.flush()

    return {
        "fcbarcelona": users_dict["fcbarcelona"],
        "teatrebarcelona": users_dict["teatrebarcelona"],
        "fitzonegym": users_dict["fitzonegym"],
        "saborcatalunya": users_dict["saborcatalunya"],
        "museupicasso": users_dict["museupicasso"],
        "festivalmerce": users_dict["festivalmerce"],
        "greenpointbcn": users_dict["greenpointbcn"],
        "techbarcelona": users_dict["techbarcelona"],
        "cinemaverdi": users_dict["cinemaverdi"],
        "labirreria": users_dict["labirreria"],
        "casabatllo": users_dict["casabatllo"],
        "primaverasound": users_dict["primaverasound"],
        "marketgoticbcn": users_dict["marketgoticbcn"],
        "escaladabcn": users_dict["escaladabcn"],
        "librerialaie": users_dict["librerialaie"],
        "all_public_users": users,
    }
