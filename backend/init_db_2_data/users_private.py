"""
Private Users (ID 1-85)
85 usuarios privados con diferentes perfiles y relaciones
"""

from models import User
from .helpers import (
    NOMBRES_HOMBRES, NOMBRES_MUJERES, APELLIDOS,
    generate_phone_number, generate_instagram_username
)
import random


def create_private_users(db):
    """Create all 85 private users"""
    users = []

    # ===== FAMILIA DE SONIA (ID 1-10) =====

    # ID 1: SONIA - Usuario principal (DEFAULT USER)
    sonia = User(
        id=1,
        display_name="Sonia Martínez",
        phone=generate_phone_number(1),
        instagram_username="sonia_martinez",
        auth_provider="supabase",
        auth_id="sonia_auth_001",
        is_public=False,
        is_admin=False
    )
    users.append(sonia)

    # ID 2: Miquel - Pareja de Sonia
    miquel = User(
        id=2,
        display_name="Miquel Farré",
        phone=generate_phone_number(2),
        instagram_username="miquel_farre",
        auth_provider="supabase",
        auth_id="miquel_auth_002",
        is_public=False,
        is_admin=False
    )
    users.append(miquel)

    # ID 3: Ada - Hermana de Sonia
    ada = User(
        id=3,
        display_name="Ada Martínez",
        phone=generate_phone_number(3),
        instagram_username="ada_martinez",
        auth_provider="supabase",
        auth_id="ada_auth_003",
        is_public=False,
        is_admin=False
    )
    users.append(ada)

    # ID 4: Sara - Prima de Sonia
    sara = User(
        id=4,
        display_name="Sara García",
        phone=generate_phone_number(4),
        instagram_username="sara_garcia",
        auth_provider="supabase",
        auth_id="sara_auth_004",
        is_public=False,
        is_admin=False
    )
    users.append(sara)

    # ID 5-10: Resto de familia (padres, tíos, primos)
    familia_nombres = [
        ("Pere Martínez", "padre"),
        ("Rosa López", "madre"),
        ("Jordi Martínez", "tio"),
        ("Carme Fernández", "tia"),
        ("Marc García", "primo"),
        ("Laura García", "prima")
    ]

    for idx, (nombre, relacion) in enumerate(familia_nombres, start=5):
        instagram = generate_instagram_username(nombre, idx)
        user = User(
            id=idx,
            display_name=nombre,
            phone=generate_phone_number(idx),
            instagram_username=instagram,
            auth_provider="supabase",
            auth_id=f"familia_{idx}_auth",
            is_public=False,
            is_admin=False
        )
        users.append(user)

    # ===== AMIGOS CERCANOS (ID 11-30) =====

    amigos_nombres = [
        "Carlos Ruiz", "Paula Sánchez", "David Torres", "Elena Romero",
        "Jorge Álvarez", "Marta Díaz", "Alberto Moreno", "Cristina Jiménez",
        "Sergio Hernández", "Ana Gómez", "Pablo Muñoz", "Raquel Martín",
        "Diego Suárez", "Patricia Castro", "Javier Ortiz", "Monica Silva",
        "Rafael Mendez", "Sandra Vazquez", "Luis Ramos", "Beatriz Reyes"
    ]

    for idx, nombre in enumerate(amigos_nombres, start=11):
        instagram = generate_instagram_username(nombre, idx)
        user = User(
            id=idx,
            display_name=nombre,
            phone=generate_phone_number(idx),
            instagram_username=instagram,
            auth_provider="supabase",
            auth_id=f"amigo_{idx}_auth",
            is_public=False,
            is_admin=False
        )
        users.append(user)

    # ===== CONOCIDOS Y CONTACTOS (ID 31-60) =====

    # Generar 30 conocidos con nombres aleatorios
    random.seed(42)  # Para reproducibilidad

    for idx in range(31, 61):
        es_hombre = idx % 2 == 0
        nombre = random.choice(NOMBRES_HOMBRES if es_hombre else NOMBRES_MUJERES)
        apellido1 = random.choice(APELLIDOS)
        apellido2 = random.choice(APELLIDOS)
        nombre_completo = f"{nombre} {apellido1}"

        instagram = generate_instagram_username(nombre_completo, idx)
        user = User(
            id=idx,
            display_name=nombre_completo,
            phone=generate_phone_number(idx),
            instagram_username=instagram,
            auth_provider="supabase",
            auth_id=f"conocido_{idx}_auth",
            is_public=False,
            is_admin=False
        )
        users.append(user)

    # ===== USUARIOS NUEVOS/INACTIVOS (ID 61-85) =====

    # Generar 25 usuarios con menos actividad
    for idx in range(61, 86):
        es_hombre = idx % 3 == 0
        nombre = random.choice(NOMBRES_HOMBRES if es_hombre else NOMBRES_MUJERES)
        apellido = random.choice(APELLIDOS)
        nombre_completo = f"{nombre} {apellido}"

        instagram = generate_instagram_username(nombre_completo, idx)
        user = User(
            id=idx,
            display_name=nombre_completo,
            phone=generate_phone_number(idx),
            instagram_username=instagram,
            auth_provider="supabase",
            auth_id=f"nuevo_{idx}_auth",
            is_public=False,
            is_admin=False
        )
        users.append(user)

    # Add all users to database
    db.add_all(users)
    db.flush()

    return {
        'sonia': sonia,
        'miquel': miquel,
        'ada': ada,
        'sara': sara,
        'all_users': users
    }
