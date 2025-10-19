# -*- coding: utf-8 -*-
"""
Menus package for CLI
Modulos organizados por funcionalidad:
- contactos.py: Gestion de contactos (Backoffice)
- usuarios.py: Gestion de usuarios (Backoffice)
- interactions.py: Bloqueo/desbloqueo de usuarios
- calendarios.py: Gestion completa de calendarios
- eventos.py: Gestion de eventos (en proceso)
"""

from .contactos import menu_contactos_backoffice
from .usuarios import menu_usuarios_backoffice
from .interactions import menu_bloquear_usuarios
from .calendarios import menu_calendarios
from .eventos import menu_eventos

__all__ = [
    'menu_contactos_backoffice',
    'menu_usuarios_backoffice',
    'menu_bloquear_usuarios',
    'menu_calendarios',
    'menu_eventos',
]
