"""
Global CLI state and mode constants.

Holds current mode and selected user information, accessible across menus/UI.
"""

from dataclasses import dataclass
from typing import Optional, Dict, Any


MODO_USUARIO = "usuario"
MODO_BACKOFFICE = "backoffice"


@dataclass
class AppState:
    modo_actual: Optional[str] = None
    usuario_actual: Optional[int] = None
    usuario_actual_info: Optional[Dict[str, Any]] = None


# Singleton state used by CLI modules
state = AppState()
