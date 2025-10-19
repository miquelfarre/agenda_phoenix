# -*- coding: utf-8 -*-
"""
Menu de bloqueo y desbloqueo de usuarios
"""
import questionary
import api_client
from rich.table import Table

from ui.console import console, custom_style, clear_screen


def menu_bloquear_usuarios(_show_header_wrapper, handle_api_error, pause, usuario_actual, url_users, url_user_blocks, url_user_block):
    """Menu para bloquear y desbloquear usuarios"""
    while True:
        clear_screen()
        _show_header_wrapper()

        choices = [
            "Bloquear un usuario",
            "Desbloquear un usuario",
            "Ver mis bloqueos",
            "Volver al menu principal"
        ]

        choice = questionary.select(
            "Gestion de Bloqueos - Que deseas hacer?",
            choices=choices,
            style=custom_style
        ).ask()

        if choice == "Bloquear un usuario":
            bloquear_usuario(_show_header_wrapper, handle_api_error, pause, usuario_actual, url_users, url_user_blocks)
        elif choice == "Desbloquear un usuario":
            desbloquear_usuario(_show_header_wrapper, handle_api_error, pause, usuario_actual, url_users, url_user_blocks, url_user_block)
        elif choice == "Ver mis bloqueos":
            ver_mis_bloqueos(_show_header_wrapper, handle_api_error, pause, usuario_actual, url_users, url_user_blocks)
        elif choice == "Volver al menu principal":
            break


def bloquear_usuario(_show_header_wrapper, handle_api_error, pause, usuario_actual, url_users, url_user_blocks):
    """Permite al usuario actual bloquear a otro usuario"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]Bloquear Usuario[/bold cyan]\n")
    console.print("[cyan]Cargando usuarios disponibles...[/cyan]\n")

    # Obtener todos los usuarios
    response = api_client.get(url_users(), params={"enriched": "true"})
    users = handle_api_error(response)

    if not users:
        console.print("[yellow]No hay usuarios disponibles[/yellow]\n")
        pause()
        return

    # Filtrar: excluir el usuario actual y usuarios ya bloqueados
    blocks_response = api_client.get(url_user_blocks(), params={"blocker_user_id": usuario_actual})
    my_blocks = handle_api_error(blocks_response) or []
    blocked_ids = {block["blocked_user_id"] for block in my_blocks}

    available_users = [u for u in users if u["id"] != usuario_actual and u["id"] not in blocked_ids]

    if not available_users:
        console.print("[yellow]No hay usuarios disponibles para bloquear[/yellow]\n")
        console.print("[dim]Ya has bloqueado a todos los usuarios o no hay otros usuarios en el sistema[/dim]\n")
        pause()
        return

    # Crear opciones
    user_choices = [f"{user['id']} - {user['display_name']}" for user in available_users]
    user_choices.append("Cancelar")

    user_choice = questionary.select(
        "Selecciona el usuario que deseas bloquear:",
        choices=user_choices,
        style=custom_style
    ).ask()

    if user_choice == "Cancelar":
        return

    # Parsear ID
    blocked_user_id = int(user_choice.split(" - ")[0])
    user_name = user_choice.split(" - ")[1]

    # Confirmar
    confirm = questionary.confirm(
        f"Estas seguro de que deseas bloquear a {user_name}?",
        default=False
    ).ask()

    if not confirm:
        return

    console.print(f"\n[cyan]Bloqueando usuario...[/cyan]\n")

    # Crear el bloqueo
    block_data = {
        "blocker_user_id": usuario_actual,
        "blocked_user_id": blocked_user_id
    }

    response = api_client.post(url_user_blocks(), json=block_data)
    block = handle_api_error(response)

    if block:
        console.print(f"[bold green]Usuario {user_name} bloqueado exitosamente[/bold green]\n")
        console.print("[dim]Este usuario ya no podra interactuar contigo de ninguna forma[/dim]\n")
    else:
        console.print("[red]No se pudo bloquear al usuario[/red]\n")

    pause()


def desbloquear_usuario(_show_header_wrapper, handle_api_error, pause, usuario_actual, url_users, url_user_blocks, url_user_block):
    """Permite al usuario actual desbloquear a otro usuario"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]Desbloquear Usuario[/bold cyan]\n")
    console.print("[cyan]Consultando tus bloqueos...[/cyan]\n")

    # Obtener bloqueos del usuario actual
    response = api_client.get(url_user_blocks(), params={"blocker_user_id": usuario_actual})
    my_blocks = handle_api_error(response)

    if not my_blocks:
        console.print("[yellow]No tienes usuarios bloqueados[/yellow]\n")
        pause()
        return

    # Obtener informacion de los usuarios bloqueados
    blocked_ids = [block["blocked_user_id"] for block in my_blocks]
    users_response = api_client.get(url_users(), params={"enriched": "true"})
    all_users = handle_api_error(users_response) or []
    users_map = {u["id"]: u["display_name"] for u in all_users}

    # Crear opciones
    block_choices = []
    for block in my_blocks:
        user_name = users_map.get(block["blocked_user_id"], f"Usuario #{block['blocked_user_id']}")
        block_choices.append(f"{block['id']} - {user_name}")

    block_choices.append("Cancelar")

    block_choice = questionary.select(
        "Selecciona el usuario que deseas desbloquear:",
        choices=block_choices,
        style=custom_style
    ).ask()

    if block_choice == "Cancelar":
        return

    # Parsear ID del bloqueo
    block_id = int(block_choice.split(" - ")[0])
    user_name = block_choice.split(" - ")[1]

    # Confirmar
    confirm = questionary.confirm(
        f"Estas seguro de que deseas desbloquear a {user_name}?",
        default=False
    ).ask()

    if not confirm:
        return

    console.print(f"\n[cyan]Desbloqueando usuario...[/cyan]\n")

    # Eliminar el bloqueo
    response = api_client.delete(url_user_block(block_id))
    result = handle_api_error(response)

    if result:
        console.print(f"[bold green]Usuario {user_name} desbloqueado exitosamente[/bold green]\n")
        console.print("[dim]Este usuario podra volver a interactuar contigo normalmente[/dim]\n")
    else:
        console.print("[red]No se pudo desbloquear al usuario[/red]\n")

    pause()


def ver_mis_bloqueos(_show_header_wrapper, handle_api_error, pause, usuario_actual, url_users, url_user_blocks):
    """Muestra la lista de usuarios bloqueados por el usuario actual"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]Mis Bloqueos[/bold cyan]\n")
    console.print("[cyan]Consultando tus bloqueos...[/cyan]\n")

    # Obtener bloqueos del usuario actual
    response = api_client.get(url_user_blocks(), params={"blocker_user_id": usuario_actual})
    my_blocks = handle_api_error(response)

    if not my_blocks:
        console.print("[yellow]No tienes usuarios bloqueados[/yellow]\n")
        pause()
        return

    # Obtener informacion de los usuarios bloqueados
    users_response = api_client.get(url_users(), params={"enriched": "true"})
    all_users = handle_api_error(users_response) or []
    users_map = {u["id"]: u["display_name"] for u in all_users}

    # Mostrar tabla
    table = Table(title="Usuarios Bloqueados", show_header=True, header_style="bold red")
    table.add_column("ID Bloqueo", style="cyan", justify="right", width=10)
    table.add_column("Usuario", style="yellow", width=30)
    table.add_column("Fecha Bloqueo", style="dim", width=20)

    for block in my_blocks:
        user_name = users_map.get(block["blocked_user_id"], f"Usuario #{block['blocked_user_id']}")
        created_at = block.get("created_at", "")
        if created_at:
            # Format date
            from dateutil import parser as date_parser
            dt = date_parser.parse(created_at)
            created_at = dt.strftime("%Y-%m-%d %H:%M")

        table.add_row(
            str(block["id"]),
            user_name,
            created_at
        )

    console.print(table)
    console.print(f"\n[cyan]Total: {len(my_blocks)} usuario(s) bloqueado(s)[/cyan]\n")
    pause()
