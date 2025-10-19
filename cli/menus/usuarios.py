# -*- coding: utf-8 -*-
"""
Menu de gestion de usuarios (Backoffice)
"""
import questionary
import api_client
from rich.panel import Panel
from rich.table import Table

from ui.console import console, custom_style, clear_screen
from config import url_users, url_user


def menu_usuarios_backoffice(_show_header_wrapper, handle_api_error, pause):
    """Menu de gestion de usuarios (solo Backoffice)"""
    while True:
        clear_screen()
        _show_header_wrapper()

        choice = questionary.select(
            "Gestion de Usuarios - Que deseas hacer?",
            choices=[
                "Ver todos los usuarios",
                "Ver detalles de un usuario",
                "Crear nuevo usuario",
                "Volver al menu principal",
            ],
            style=custom_style,
        ).ask()

        if choice == "Ver todos los usuarios":
            listar_usuarios_backoffice(_show_header_wrapper, handle_api_error, pause)
        elif choice == "Ver detalles de un usuario":
            ver_usuario_backoffice(_show_header_wrapper, handle_api_error, pause)
        elif choice == "Crear nuevo usuario":
            crear_usuario_backoffice(_show_header_wrapper, handle_api_error, pause)
        elif choice == "Volver al menu principal":
            break


def listar_usuarios_backoffice(_show_header_wrapper, handle_api_error, pause):
    """Lista todos los usuarios (Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    console.print("[cyan]Consultando usuarios...[/cyan]\n")

    # Obtener users enriched desde el backend (con contact info)
    response = api_client.get(url_users(), params={"enriched": "true"})
    users = handle_api_error(response)

    if not users:
        pause()
        return

    table = Table(title="Usuarios Registrados", show_header=True, header_style="bold magenta")
    table.add_column("ID", style="cyan", justify="right", width=5)
    table.add_column("Username", style="yellow", width=15)
    table.add_column("Nombre (Contacto)", style="green", width=20)
    table.add_column("Telefono", style="blue", width=15)
    table.add_column("Auth Provider", style="magenta", width=15)

    for user in users:
        table.add_row(str(user["id"]), user.get("username", "-"), user.get("contact_name", "-"), user.get("contact_phone", "-"), user.get("auth_provider", "-"))

    console.print(table)
    console.print(f"\n[cyan]Total: {len(users)} usuarios[/cyan]\n")
    pause()


def ver_usuario_backoffice(_show_header_wrapper, handle_api_error, pause):
    """Muestra detalles de un usuario (Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    user_id = questionary.text("Ingresa el ID del usuario:", validate=lambda text: text.isdigit() or "Debe ser un numero").ask()

    if not user_id:
        return

    console.print(f"\n[cyan]Consultando usuario #{user_id}...[/cyan]\n")

    # Obtener usuario enriched con info de contacto
    response = api_client.get(url_user(user_id), params={"enriched": "true"})
    user = handle_api_error(response)

    if not user:
        pause()
        return

    info = f"[yellow]ID:[/yellow] {user['id']}\n"
    info += f"[yellow]Username:[/yellow] {user.get('username', '-')}\n"
    info += f"[yellow]Auth Provider:[/yellow] {user.get('auth_provider', '-')}\n"
    info += f"[yellow]Auth ID:[/yellow] {user.get('auth_id', '-')}\n"
    info += f"[yellow]Nombre (Contacto):[/yellow] {user.get('contact_name', '-')}\n"
    info += f"[yellow]Telefono (Contacto):[/yellow] {user.get('contact_phone', '-')}\n"
    info += f"[yellow]Profile Picture:[/yellow] {user.get('profile_picture_url', '-')}\n"
    info += f"[yellow]Creado:[/yellow] {user.get('created_at', '-')}"

    console.print(Panel(info, title=f"[bold cyan]Usuario #{user['id']}[/bold cyan]", border_style="cyan"))
    console.print()
    pause()


def crear_usuario_backoffice(_show_header_wrapper, handle_api_error, pause):
    """Crea un nuevo usuario (Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]Crear Nuevo Usuario[/bold cyan]\n")

    # Implementacion simplificada
    console.print("[yellow]Funcionalidad de creacion de usuarios (ver menu.py original)[/yellow]\n")
    pause()
