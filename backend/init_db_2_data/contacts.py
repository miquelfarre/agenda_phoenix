"""
User Contacts - Relaciones entre usuarios
Gestiona quién tiene a quién en su agenda de contactos
"""

from models import UserContact


def create_contacts(db, private_users, public_users):
    """
    Create user contact relationships

    Sonia tiene 50 contactos registrados + 30 no registrados
    Otros usuarios también tienen sus propios contactos
    """
    contacts = []

    sonia = private_users["sonia"]
    miquel = private_users["miquel"]
    ada = private_users["ada"]
    sara = private_users["sara"]
    all_users = private_users["all_users"]

    # ==== CONTACTOS DE SONIA (50 registrados) ====

    # Familia inmediata
    for user in [miquel, ada, sara]:
        contacts.append(UserContact(owner_id=sonia.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # Familia extendida (ID 5-10)
    for user in all_users[4:10]:  # ID 5-10
        contacts.append(UserContact(owner_id=sonia.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # Amigos cercanos (ID 11-30) - todos en contactos
    for user in all_users[10:30]:  # ID 11-30
        contacts.append(UserContact(owner_id=sonia.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # Conocidos seleccionados (ID 31-50) - 20 de 30
    for user in all_users[30:50]:  # ID 31-50
        contacts.append(UserContact(owner_id=sonia.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # Algunos usuarios nuevos (ID 61-65) - 5 usuarios
    for user in all_users[60:65]:  # ID 61-65
        contacts.append(UserContact(owner_id=sonia.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # 30 contactos NO registrados (solo teléfono, sin user_id)
    non_registered_contacts = [
        ("Marta Rius", "+34611111001"),
        ("Pol Carreras", "+34611111002"),
        ("Neus Vila", "+34611111003"),
        ("Oriol Camps", "+34611111004"),
        ("Gemma Pujol", "+34611111005"),
        ("Xavier Font", "+34611111006"),
        ("Montse Rovira", "+34611111007"),
        ("Francesc Serra", "+34611111008"),
        ("Núria Masip", "+34611111009"),
        ("Toni Bosch", "+34611111010"),
        ("Àngels Puig", "+34611111011"),
        ("Lluís Soler", "+34611111012"),
        ("Mercè Vidal", "+34611111013"),
        ("Enric Sala", "+34611111014"),
        ("Pilar Comas", "+34611111015"),
        ("Ramon Climent", "+34611111016"),
        ("Teresa Mir", "+34611111017"),
        ("Vicenç Tomàs", "+34611111018"),
        ("Glòria Pla", "+34611111019"),
        ("Benet Ros", "+34611111020"),
        ("Carla Mas", "+34611111021"),
        ("Èric Badia", "+34611111022"),
        ("Sílvia Munté", "+34611111023"),
        ("Gerard Fabre", "+34611111024"),
        ("Joana Pons", "+34611111025"),
        ("Albert Roca", "+34611111026"),
        ("Laia Marí", "+34611111027"),
        ("Martí Codina", "+34611111028"),
        ("Elisabet Mora", "+34611111029"),
        ("Quim Ayats", "+34611111030"),
    ]

    for name, phone in non_registered_contacts:
        contacts.append(UserContact(owner_id=sonia.id, registered_user_id=None, contact_name=name, phone_number=phone))  # No registrado

    # ==== CONTACTOS DE MIQUEL ====

    # Miquel tiene a Sonia, Ada, Sara + familia + sus propios amigos
    for user in [sonia, ada, sara]:
        contacts.append(UserContact(owner_id=miquel.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # Familia (ID 5-10)
    for user in all_users[4:10]:
        contacts.append(UserContact(owner_id=miquel.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # Amigos comunes (ID 11-25) - 15 amigos
    for user in all_users[10:25]:
        contacts.append(UserContact(owner_id=miquel.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # ==== CONTACTOS DE ADA ====

    # Ada tiene a Sonia, Miquel, Sara + familia + muchos amigos
    for user in [sonia, miquel, sara]:
        contacts.append(UserContact(owner_id=ada.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # Familia
    for user in all_users[4:10]:
        contacts.append(UserContact(owner_id=ada.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # Muchos amigos (ID 11-40) - 30 amigos
    for user in all_users[10:40]:
        contacts.append(UserContact(owner_id=ada.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # ==== CONTACTOS DE SARA ====

    # Sara tiene menos contactos
    for user in [sonia, miquel, ada]:
        contacts.append(UserContact(owner_id=sara.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # Familia
    for user in all_users[4:10]:
        contacts.append(UserContact(owner_id=sara.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # Algunos amigos (ID 11-20)
    for user in all_users[10:20]:
        contacts.append(UserContact(owner_id=sara.id, registered_user_id=user.id, contact_name=user.display_name, phone_number=user.phone))

    # ==== OTROS USUARIOS TIENEN CONTACTOS ENTRE SÍ ====

    # Amigos cercanos se tienen entre sí (ID 11-20)
    for i in range(11, 21):
        for j in range(11, 21):
            if i != j and i < j:  # Evitar duplicados y self-contact
                user_i = all_users[i - 1]
                user_j = all_users[j - 1]
                contacts.append(UserContact(owner_id=user_i.id, registered_user_id=user_j.id, contact_name=user_j.display_name, phone_number=user_j.phone))

    # Add all contacts to database
    db.add_all(contacts)
    db.flush()

    return contacts
