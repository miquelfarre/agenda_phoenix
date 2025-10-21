#!/usr/bin/env python3
"""
Agenda Phoenix - Interfaz interactiva con menús
Soporta dos modos: Usuario (simulación) y Backoffice (administración)

IMPORTANTE: Este CLI es un cliente de la API, no implementa lógica de negocio.
Ver DEVELOPMENT_RULES.md para las reglas de desarrollo.
"""
import questionary
import api_client
from datetime import datetime, timedelta
from rich.table import Table
from rich.panel import Panel
from ui.console import console, custom_style, clear_screen
from ui.tables import (
    truncate_text,
    format_count_message,
    create_events_table,
    show_pagination_info,
)
from dateutil import parser as date_parser
from config import (
    API_BASE_URL,
    url_root,
    url_contacts,
    url_contact,
    url_users,
    url_user,
    url_user_events,
    url_user_subscribe,
    url_events,
    url_event,
    url_event_interactions_enriched,
    url_event_available_invitees,
    url_interactions,
    url_interaction,
    url_calendars,
    url_calendar,
    url_calendar_memberships_nested,
    url_calendar_memberships,
    url_calendar_membership,
    url_recurring_configs,
)
from ui.header import show_header

# Importar modulos de menus
from menus.contactos import menu_contactos_backoffice
from menus.usuarios import menu_usuarios_backoffice
from menus.interactions import menu_bloquear_usuarios
from menus.calendarios import menu_calendarios
from menus.eventos import menu_eventos

# Variables globales para el modo y usuario actual
MODO_USUARIO = "usuario"
MODO_BACKOFFICE = "backoffice"
modo_actual = None
usuario_actual = None
usuario_actual_info = None


def _show_header_wrapper():
    # Wrapper to call shared header with current state
    show_header(modo_actual=modo_actual, usuario_actual=usuario_actual, usuario_actual_info=usuario_actual_info)


def handle_api_error(response):
    """Maneja errores de la API"""
    if response.status_code >= 200 and response.status_code < 300:
        return response.json() if response.content else None
    else:
        console.print(f"\n[bold red]❌ Error {response.status_code}[/bold red]")
        try:
            error_detail = response.json()
            console.print(error_detail)
        except:
            console.print(response.text)
        return None


def pause():
    """Pausa y espera a que el usuario presione Enter"""
    questionary.press_any_key_to_continue().ask()


def seleccionar_modo():
    """Pantalla inicial para seleccionar el modo de uso"""
    global modo_actual, usuario_actual, usuario_actual_info

    clear_screen()
    _show_header_wrapper()

    # Verificar conexión con la API
    try:
        response = api_client.get(url_root(), timeout=2)
        if response.status_code == 200:
            console.print(f"[dim green]✓ Conectado a {API_BASE_URL}[/dim green]\n")
        else:
            console.print(f"[dim yellow]⚠ API respondió con código {response.status_code}[/dim yellow]\n")
    except:
        console.print(f"[dim red]✗ No se pudo conectar a {API_BASE_URL}[/dim red]\n")
        console.print("[red]Asegúrate de que el backend esté corriendo (docker compose up -d)[/red]\n")
        pause()
        return False

    choice = questionary.select("¿Cómo deseas acceder a Agenda Phoenix?", choices=["👤 Como Usuario (simular experiencia de usuario)", "🔧 Modo Backoffice (administración completa)", "❌ Salir"], style=custom_style).ask()

    if choice == "❌ Salir":
        return False
    elif choice == "👤 Como Usuario (simular experiencia de usuario)":
        modo_actual = MODO_USUARIO
        return seleccionar_usuario()
    elif choice == "🔧 Modo Backoffice (administración completa)":
        modo_actual = MODO_BACKOFFICE
        usuario_actual = None
        usuario_actual_info = None
        return True


def seleccionar_usuario():
    """Permite seleccionar el usuario para el modo usuario"""
    global usuario_actual, usuario_actual_info

    clear_screen()
    console.print(Panel.fit("[bold cyan]👤 Selección de Usuario[/bold cyan]\n" "[dim]Elige el usuario cuya experiencia deseas simular[/dim]", border_style="cyan"))
    console.print()

    console.print("[cyan]Cargando usuarios disponibles...[/cyan]\n")

    # Obtener usuarios CON display_name (enriquecidos desde el backend)
    users_response = api_client.get(url_users(), params={"enriched": "true"})
    users = handle_api_error(users_response)

    if not users:
        console.print("[red]Error al obtener usuarios[/red]")
        pause()
        return False

    # Crear opciones de usuarios (solo formateo)
    user_choices = [f"{user['id']} - {user['display_name']}" for user in users]
    user_choices.append("⬅️  Volver")

    user_choice = questionary.select("Selecciona un usuario:", choices=user_choices, style=custom_style).ask()

    if user_choice == "⬅️  Volver":
        return seleccionar_modo()

    # Parsear ID directamente del string seleccionado
    usuario_actual = int(user_choice.split(" - ")[0])

    return True


# ==================== FUNCIONES DE EVENTOS, CALENDARIOS, USUARIOS, CONTACTOS E INTERACTIONS ====================
# TODAS LAS FUNCIONES HAN SIDO MOVIDAS A LOS MODULOS EN menus/
# Ver: menus/eventos.py, menus/calendarios.py, menus/usuarios.py, menus/contactos.py, menus/interactions.py


# ==================== MENÚ PRINCIPAL ====================


def menu_principal():
    """Menú principal de la aplicación (adaptado según el modo)"""
    while True:
        clear_screen()
        _show_header_wrapper()

        if modo_actual == MODO_USUARIO:
            choices = ["📅 MIS Eventos", "📆 MIS Calendarios", "🚫 Bloquear/Desbloquear Usuarios", "👤 Cambiar Usuario", "❌ Salir"]
        else:  # MODO_BACKOFFICE
            choices = ["👥 Gestionar Usuarios", "📞 Gestionar Contactos", "📅 Gestionar Eventos", "📆 Gestionar Calendarios", "🔄 Cambiar Modo", "❌ Salir"]

        choice = questionary.select("¿Qué deseas hacer?", choices=choices, style=custom_style).ask()

        if choice == "📅 MIS Eventos" or choice == "📅 Gestionar Eventos":
            # Llamar al modulo de eventos con los parametros necesarios
            menu_eventos(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO, MODO_BACKOFFICE)
        elif choice == "📆 MIS Calendarios" or choice == "📆 Gestionar Calendarios":
            # Llamar al modulo de calendarios con los parametros necesarios
            menu_calendarios(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO, MODO_BACKOFFICE)
        elif choice == "👥 Gestionar Usuarios":
            # Llamar al modulo de usuarios con los parametros necesarios
            menu_usuarios_backoffice(_show_header_wrapper, handle_api_error, pause)
        elif choice == "📞 Gestionar Contactos":
            # Llamar al modulo de contactos con los parametros necesarios
            menu_contactos_backoffice(_show_header_wrapper, handle_api_error, pause)
        elif choice == "🚫 Bloquear/Desbloquear Usuarios":
            # Importar funciones URL necesarias para el modulo de interactions
            from config import url_user_blocks, url_user_block
            # Llamar al modulo de interactions con los parametros necesarios
            menu_bloquear_usuarios(_show_header_wrapper, handle_api_error, pause, usuario_actual, url_users, url_user_blocks, url_user_block)
        elif choice == "👤 Cambiar Usuario":
            if not seleccionar_usuario():
                break
        elif choice == "🔄 Cambiar Modo":
            if not seleccionar_modo():
                break
        elif choice == "❌ Salir":
            clear_screen()
            console.print("\n[cyan]👋 ¡Hasta luego![/cyan]\n")
            break


# ==================== MAIN ====================

if __name__ == "__main__":
    try:
        if seleccionar_modo():
            menu_principal()
    except KeyboardInterrupt:
        clear_screen()
        console.print("\n[cyan]👋 ¡Hasta luego![/cyan]\n")
