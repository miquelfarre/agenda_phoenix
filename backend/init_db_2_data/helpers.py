"""
Helper functions for init_db_2 data generation
"""

import secrets
import string
from datetime import datetime, timedelta


def generate_share_hash(length: int = 8) -> str:
    """Generate a random share hash for public calendars"""
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def get_reference_date():
    """Get reference date for all sample data"""
    return datetime(2025, 12, 15, 12, 0, 0)


def get_dates():
    """Get dictionary of useful dates for sample data"""
    now = get_reference_date()
    return {
        'now': now,
        'yesterday': now - timedelta(days=1),
        'tomorrow': now + timedelta(days=1),
        'in_2_days': now + timedelta(days=2),
        'in_3_days': now + timedelta(days=3),
        'in_4_days': now + timedelta(days=4),
        'in_5_days': now + timedelta(days=5),
        'in_7_days': now + timedelta(days=7),
        'in_10_days': now + timedelta(days=10),
        'in_14_days': now + timedelta(days=14),
        'in_21_days': now + timedelta(days=21),
        'in_30_days': now + timedelta(days=30),
        'in_45_days': now + timedelta(days=45),
        'in_60_days': now + timedelta(days=60),
        'in_90_days': now + timedelta(days=90),
        'in_120_days': now + timedelta(days=120),
        'in_6_months': now + timedelta(days=180),
        'in_1_year': now + timedelta(days=365),
    }


# Nombres españoles para usuarios privados
NOMBRES_HOMBRES = [
    "Miguel", "Carlos", "David", "Jose", "Antonio", "Juan", "Manuel", "Francisco",
    "Daniel", "Javier", "Rafael", "Pedro", "Angel", "Luis", "Sergio", "Pablo",
    "Fernando", "Jorge", "Alberto", "Diego", "Alejandro", "Adrian", "Raul", "Ivan",
    "Oscar", "Victor", "Ruben", "Mario", "Enrique", "Marcos"
]

NOMBRES_MUJERES = [
    "Maria", "Carmen", "Ana", "Laura", "Isabel", "Pilar", "Rosa", "Marta",
    "Sara", "Lucia", "Paula", "Elena", "Cristina", "Raquel", "Monica", "Patricia",
    "Angela", "Sandra", "Beatriz", "Natalia", "Teresa", "Silvia", "Eva", "Nuria",
    "Alicia", "Clara", "Julia", "Irene", "Victoria", "Adriana"
]

APELLIDOS = [
    "Garcia", "Rodriguez", "Martinez", "Fernandez", "Lopez", "Gonzalez", "Perez", "Sanchez",
    "Romero", "Sosa", "Torres", "Alvarez", "Ruiz", "Diaz", "Moreno", "Jimenez",
    "Hernandez", "Gomez", "Munoz", "Martin", "Suarez", "Castro", "Ortiz", "Silva",
    "Mendez", "Vazquez", "Ramos", "Reyes", "Cruz", "Flores"
]

# Nombres de usuarios públicos/organizaciones
ORGANIZACIONES = [
    {"name": "FC Barcelona", "instagram": "fcbarcelona", "category": "deportes"},
    {"name": "Teatro Nacional Catalunya", "instagram": "teatrebarcelona", "category": "cultura"},
    {"name": "Gimnasio FitZone", "instagram": "fitzonegym", "category": "fitness"},
    {"name": "Restaurante El Buen Sabor", "instagram": "saborcatalunya", "category": "gastronomia"},
    {"name": "Museo Picasso Barcelona", "instagram": "museupicasso", "category": "cultura"},
    {"name": "Festes de la Mercè", "instagram": "festivalmerce", "category": "eventos"},
    {"name": "Green Point Yoga", "instagram": "greenpointbcn", "category": "wellness"},
    {"name": "Barcelona Tech Hub", "instagram": "techbarcelona", "category": "tecnologia"},
    {"name": "Cines Verdi", "instagram": "cinemaverdi", "category": "entretenimiento"},
    {"name": "La Birreria Craft Beer", "instagram": "labirreria", "category": "ocio"},
    {"name": "Casa Batlló", "instagram": "casabatllo", "category": "turismo"},
    {"name": "Primavera Sound", "instagram": "primaverasound", "category": "musica"},
    {"name": "Mercat Gòtic", "instagram": "marketgoticbcn", "category": "gastronomia"},
    {"name": "Climbat Escalada", "instagram": "escaladabcn", "category": "deportes"},
    {"name": "Libreria Laie", "instagram": "librerialaie", "category": "cultura"},
]


def generate_phone_number(user_id: int) -> str:
    """Generate a unique phone number for a user"""
    return f"+346000000{user_id:02d}" if user_id < 100 else f"+346{user_id:08d}"


def generate_instagram_username(name: str, user_id: int) -> str:
    """Generate Instagram username from name"""
    clean_name = name.lower().replace(" ", "_").replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u")
    return f"{clean_name}_{user_id}"
