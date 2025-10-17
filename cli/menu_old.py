#!/usr/bin/env python3
"""
Agenda Phoenix - Interfaz interactiva con menús
"""
import questionary
from questionary import Style
import requests
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich import print as rprint
from datetime import datetime
from dateutil import parser as date_parser
from config import API_BASE_URL

console = Console()

# Estilo personalizado para los menús
custom_style = Style([
    ('qmark', 'fg:#673ab7 bold'),
    ('question', 'bold'),
    ('answer', 'fg:#f44336 bold'),
    ('pointer', 'fg:#673ab7 bold'),
    ('highlighted', 'fg:#673ab7 bold'),
    ('selected', 'fg:#cc5454'),
    ('separator', 'fg:#cc5454'),
    ('instruction', ''),
    ('text', ''),
])


def clear_screen():
    """Limpia la pantalla"""
    console.clear()


def show_header():
    """Muestra el encabezado de la aplicación"""
    console.print(Panel.fit(
        "[bold cyan]🗓️  Agenda Phoenix[/bold cyan]\n"
        "[dim]Sistema de gestión de calendarios y eventos[/dim]",
        border_style="cyan"
    ))
    console.print()


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


# ==================== MENÚ DE USUARIOS ====================

def menu_usuarios():
    """Menú de gestión de usuarios"""
    while True:
        clear_screen()
        show_header()

        choice = questionary.select(
            "👥 Gestión de Usuarios - ¿Qué deseas hacer?",
            choices=[
                "📋 Ver todos los usuarios",
                "🔍 Ver detalles de un usuario",
                "➕ Crear nuevo usuario",
                "⬅️  Volver al menú principal"
            ],
            style=custom_style
        ).ask()

        if choice == "📋 Ver todos los usuarios":
            listar_usuarios()
        elif choice == "🔍 Ver detalles de un usuario":
            ver_usuario()
        elif choice == "➕ Crear nuevo usuario":
            crear_usuario()
        elif choice == "⬅️  Volver al menú principal":
            break


def listar_usuarios():
    """Lista todos los usuarios"""
    clear_screen()
    show_header()

    console.print("[cyan]Consultando usuarios...[/cyan]\n")

    response = requests.get(f"{API_BASE_URL}/users")
    users = handle_api_error(response)

    if not users:
        pause()
        return

    # Obtener contactos
    contacts_response = requests.get(f"{API_BASE_URL}/contacts")
    contacts = {}
    if contacts_response.status_code == 200:
        for contact in contacts_response.json():
            contacts[contact['id']] = contact

    table = Table(title="👥 Usuarios Registrados", show_header=True, header_style="bold magenta")
    table.add_column("ID", style="cyan", justify="right", width=5)
    table.add_column("Username", style="yellow", width=15)
    table.add_column("Nombre (Contacto)", style="green", width=20)
    table.add_column("Teléfono", style="blue", width=15)
    table.add_column("Auth Provider", style="magenta", width=15)

    for user in users:
        contact_name = "-"
        phone = "-"
        if user.get('contact_id') and user['contact_id'] in contacts:
            contact_name = contacts[user['contact_id']]['name']
            phone = contacts[user['contact_id']].get('phone', '-')

        table.add_row(
            str(user['id']),
            user.get('username', '-'),
            contact_name,
            phone,
            user.get('auth_provider', '-')
        )

    console.print(table)
    console.print(f"\n[cyan]Total: {len(users)} usuarios[/cyan]\n")
    pause()


def ver_usuario():
    """Muestra detalles de un usuario específico"""
    clear_screen()
    show_header()

    user_id = questionary.text(
        "Ingresa el ID del usuario:",
        validate=lambda text: text.isdigit() or "Debe ser un número"
    ).ask()

    if not user_id:
        return

    console.print(f"\n[cyan]Consultando usuario #{user_id}...[/cyan]\n")

    response = requests.get(f"{API_BASE_URL}/users/{user_id}")
    user = handle_api_error(response)

    if not user:
        pause()
        return

    # Crear panel con información del usuario
    info = f"[yellow]ID:[/yellow] {user['id']}\n"
    info += f"[yellow]Username:[/yellow] {user.get('username', '-')}\n"
    info += f"[yellow]Auth Provider:[/yellow] {user.get('auth_provider', '-')}\n"
    info += f"[yellow]Auth ID:[/yellow] {user.get('auth_id', '-')}\n"

    # Obtener información del contacto si existe
    if user.get('contact_id'):
        contact_response = requests.get(f"{API_BASE_URL}/contacts/{user['contact_id']}")
        if contact_response.status_code == 200:
            contact = contact_response.json()
            info += f"[yellow]Nombre (Contacto):[/yellow] {contact.get('name', '-')}\n"
            info += f"[yellow]Teléfono (Contacto):[/yellow] {contact.get('phone', '-')}\n"

    info += f"[yellow]Profile Picture:[/yellow] {user.get('profile_picture_url', '-')}\n"
    info += f"[yellow]Creado:[/yellow] {user.get('created_at', '-')}"

    console.print(Panel(info, title=f"[bold cyan]Usuario #{user['id']}[/bold cyan]", border_style="cyan"))
    console.print()
    pause()


def crear_usuario():
    """Crea un nuevo usuario"""
    clear_screen()
    show_header()

    console.print("[bold cyan]➕ Crear Nuevo Usuario[/bold cyan]\n")

    # Primero, decidir si tiene contacto o no
    tiene_contacto = questionary.confirm(
        "¿Este usuario está asociado a un contacto existente?",
        default=False
    ).ask()

    contact_id = None
    if tiene_contacto:
        # Mostrar lista de contactos
        contacts_response = requests.get(f"{API_BASE_URL}/contacts")
        if contacts_response.status_code == 200:
            contacts = contacts_response.json()
            contact_choices = [f"{c['id']} - {c['name']} ({c['phone']})" for c in contacts]
            contact_choices.append("Cancelar")

            contact_choice = questionary.select(
                "Selecciona un contacto:",
                choices=contact_choices
            ).ask()

            if contact_choice == "Cancelar":
                return

            contact_id = int(contact_choice.split(" - ")[0])

    # Seleccionar proveedor de autenticación
    auth_provider = questionary.select(
        "Proveedor de autenticación:",
        choices=["phone", "instagram", "twitter", "facebook", "google", "email"]
    ).ask()

    auth_id = questionary.text(
        f"ID de autenticación ({auth_provider}):",
        validate=lambda text: len(text) > 0 or "No puede estar vacío"
    ).ask()

    username = questionary.text(
        "Username (opcional, presiona Enter para omitir):"
    ).ask()

    profile_pic = questionary.text(
        "URL de foto de perfil (opcional, presiona Enter para omitir):"
    ).ask()

    # Crear usuario
    data = {
        "auth_provider": auth_provider,
        "auth_id": auth_id,
        "username": username if username else None,
        "contact_id": contact_id,
        "profile_picture_url": profile_pic if profile_pic else None
    }

    console.print("\n[cyan]Creando usuario...[/cyan]\n")
    response = requests.post(f"{API_BASE_URL}/users", json=data)
    user = handle_api_error(response)

    if user:
        console.print(f"[bold green]✅ Usuario creado exitosamente con ID: {user['id']}[/bold green]\n")

    pause()


# ==================== MENÚ DE CONTACTOS ====================

def menu_contactos():
    """Menú de gestión de contactos"""
    while True:
        clear_screen()
        show_header()

        choice = questionary.select(
            "📞 Gestión de Contactos - ¿Qué deseas hacer?",
            choices=[
                "📋 Ver todos los contactos",
                "🔍 Ver detalles de un contacto",
                "➕ Crear nuevo contacto",
                "⬅️  Volver al menú principal"
            ],
            style=custom_style
        ).ask()

        if choice == "📋 Ver todos los contactos":
            listar_contactos()
        elif choice == "🔍 Ver detalles de un contacto":
            ver_contacto()
        elif choice == "➕ Crear nuevo contacto":
            crear_contacto()
        elif choice == "⬅️  Volver al menú principal":
            break


def listar_contactos():
    """Lista todos los contactos"""
    clear_screen()
    show_header()

    console.print("[cyan]Consultando contactos...[/cyan]\n")

    response = requests.get(f"{API_BASE_URL}/contacts")
    contacts = handle_api_error(response)

    if not contacts:
        pause()
        return

    table = Table(title="📞 Contactos", show_header=True, header_style="bold magenta")
    table.add_column("ID", style="cyan", justify="right", width=5)
    table.add_column("Nombre", style="green", width=25)
    table.add_column("Teléfono", style="blue", width=20)

    for contact in contacts:
        table.add_row(
            str(contact['id']),
            contact['name'],
            contact.get('phone', '-')
        )

    console.print(table)
    console.print(f"\n[cyan]Total: {len(contacts)} contactos[/cyan]\n")
    pause()


def ver_contacto():
    """Muestra detalles de un contacto específico"""
    clear_screen()
    show_header()

    contact_id = questionary.text(
        "Ingresa el ID del contacto:",
        validate=lambda text: text.isdigit() or "Debe ser un número"
    ).ask()

    if not contact_id:
        return

    console.print(f"\n[cyan]Consultando contacto #{contact_id}...[/cyan]\n")

    response = requests.get(f"{API_BASE_URL}/contacts/{contact_id}")
    contact = handle_api_error(response)

    if not contact:
        pause()
        return

    info = f"[yellow]ID:[/yellow] {contact['id']}\n"
    info += f"[yellow]Nombre:[/yellow] {contact['name']}\n"
    info += f"[yellow]Teléfono:[/yellow] {contact.get('phone', '-')}\n"
    info += f"[yellow]Creado:[/yellow] {contact.get('created_at', '-')}"

    console.print(Panel(info, title=f"[bold cyan]Contacto #{contact['id']}[/bold cyan]", border_style="cyan"))
    console.print()
    pause()


def crear_contacto():
    """Crea un nuevo contacto"""
    clear_screen()
    show_header()

    console.print("[bold cyan]➕ Crear Nuevo Contacto[/bold cyan]\n")

    name = questionary.text(
        "Nombre del contacto:",
        validate=lambda text: len(text) > 0 or "No puede estar vacío"
    ).ask()

    if not name:
        return

    phone = questionary.text(
        "Teléfono (formato: +34XXXXXXXXX):",
        validate=lambda text: len(text) > 0 or "No puede estar vacío"
    ).ask()

    if not phone:
        return

    data = {
        "name": name,
        "phone": phone
    }

    console.print("\n[cyan]Creando contacto...[/cyan]\n")
    response = requests.post(f"{API_BASE_URL}/contacts", json=data)
    contact = handle_api_error(response)

    if contact:
        console.print(f"[bold green]✅ Contacto '{name}' creado exitosamente con ID: {contact['id']}[/bold green]\n")

    pause()


# ==================== MENÚ DE EVENTOS ====================

def menu_eventos():
    """Menú de gestión de eventos"""
    while True:
        clear_screen()
        show_header()

        choice = questionary.select(
            "📅 Gestión de Eventos - ¿Qué deseas hacer?",
            choices=[
                "📋 Ver eventos de un usuario",
                "🔍 Ver detalles de un evento",
                "➕ Crear nuevo evento",
                "🗑️  Eliminar un evento",
                "⬅️  Volver al menú principal"
            ],
            style=custom_style
        ).ask()

        if choice == "📋 Ver eventos de un usuario":
            listar_eventos_usuario()
        elif choice == "🔍 Ver detalles de un evento":
            ver_evento()
        elif choice == "➕ Crear nuevo evento":
            crear_evento()
        elif choice == "🗑️  Eliminar un evento":
            eliminar_evento()
        elif choice == "⬅️  Volver al menú principal":
            break


def listar_eventos_usuario():
    """Lista eventos de un usuario"""
    clear_screen()
    show_header()

    # Mostrar usuarios para seleccionar
    users_response = requests.get(f"{API_BASE_URL}/users")
    if users_response.status_code != 200:
        console.print("[red]Error al obtener usuarios[/red]")
        pause()
        return

    users = users_response.json()
    contacts_response = requests.get(f"{API_BASE_URL}/contacts")
    contacts = {}
    if contacts_response.status_code == 200:
        for contact in contacts_response.json():
            contacts[contact['id']] = contact

    # Crear opciones de usuarios
    user_choices = []
    for user in users:
        contact_name = ""
        if user.get('contact_id') and user['contact_id'] in contacts:
            contact_name = f" - {contacts[user['contact_id']]['name']}"
        username = user.get('username', '')
        if username:
            user_choices.append(f"{user['id']} - {username}{contact_name}")
        else:
            user_choices.append(f"{user['id']}{contact_name}")

    user_choices.append("⬅️  Cancelar")

    user_choice = questionary.select(
        "Selecciona un usuario:",
        choices=user_choices,
        style=custom_style
    ).ask()

    if user_choice == "⬅️  Cancelar":
        return

    user_id = int(user_choice.split(" - ")[0].split()[0])

    console.print(f"\n[cyan]Consultando eventos del usuario #{user_id}...[/cyan]\n")

    response = requests.get(f"{API_BASE_URL}/users/{user_id}/events")
    events = handle_api_error(response)

    if not events:
        console.print("[yellow]Este usuario no tiene eventos[/yellow]\n")
        pause()
        return

    table = Table(title=f"📅 Eventos del Usuario #{user_id}", show_header=True, header_style="bold magenta")
    table.add_column("ID", style="cyan", justify="right", width=5)
    table.add_column("Nombre", style="green", width=30)
    table.add_column("Fecha Inicio", style="yellow", width=18)
    table.add_column("Tipo", style="blue", width=10)
    table.add_column("Owner", style="magenta", justify="right", width=7)

    for event in events[:20]:  # Limitar a 20 para no saturar la pantalla
        start = datetime.fromisoformat(event['start_date'].replace('Z', '+00:00'))

        table.add_row(
            str(event['id']),
            event['name'][:28] + "..." if len(event['name']) > 28 else event['name'],
            start.strftime("%Y-%m-%d %H:%M"),
            event['event_type'],
            str(event['owner_id'])
        )

    console.print(table)

    if len(events) > 20:
        console.print(f"\n[dim]Mostrando 20 de {len(events)} eventos[/dim]")

    console.print(f"\n[cyan]Total: {len(events)} eventos[/cyan]\n")
    pause()


def ver_evento():
    """Muestra detalles de un evento específico"""
    clear_screen()
    show_header()

    event_id = questionary.text(
        "Ingresa el ID del evento:",
        validate=lambda text: text.isdigit() or "Debe ser un número"
    ).ask()

    if not event_id:
        return

    console.print(f"\n[cyan]Consultando evento #{event_id}...[/cyan]\n")

    response = requests.get(f"{API_BASE_URL}/events/{event_id}")
    event = handle_api_error(response)

    if not event:
        pause()
        return

    start = datetime.fromisoformat(event['start_date'].replace('Z', '+00:00'))

    info = f"[yellow]ID:[/yellow] {event['id']}\n"
    info += f"[yellow]Nombre:[/yellow] {event['name']}\n"
    info += f"[yellow]Descripción:[/yellow] {event.get('description', '-')}\n"
    info += f"[yellow]Fecha Inicio:[/yellow] {start.strftime('%Y-%m-%d %H:%M')}\n"

    if event.get('end_date'):
        end = datetime.fromisoformat(event['end_date'].replace('Z', '+00:00'))
        info += f"[yellow]Fecha Fin:[/yellow] {end.strftime('%Y-%m-%d %H:%M')}\n"

    info += f"[yellow]Tipo:[/yellow] {event['event_type']}\n"
    info += f"[yellow]Owner ID:[/yellow] {event['owner_id']}\n"

    if event.get('calendar_id'):
        info += f"[yellow]Calendario ID:[/yellow] {event['calendar_id']}\n"

    if event.get('parent_recurring_event_id'):
        info += f"[yellow]Evento Recurrente Padre:[/yellow] {event['parent_recurring_event_id']}\n"

    console.print(Panel(info, title=f"[bold cyan]Evento #{event['id']}[/bold cyan]", border_style="cyan"))
    console.print()
    pause()


def crear_evento():
    """Crea un nuevo evento"""
    clear_screen()
    show_header()

    console.print("[bold cyan]➕ Crear Nuevo Evento[/bold cyan]\n")

    name = questionary.text(
        "Nombre del evento:",
        validate=lambda text: len(text) > 0 or "No puede estar vacío"
    ).ask()

    if not name:
        return

    # Seleccionar owner
    users_response = requests.get(f"{API_BASE_URL}/users")
    if users_response.status_code != 200:
        console.print("[red]Error al obtener usuarios[/red]")
        pause()
        return

    users = users_response.json()
    user_choices = [f"{u['id']} - {u.get('username', 'Usuario sin nombre')}" for u in users]

    owner_choice = questionary.select(
        "Selecciona el propietario del evento:",
        choices=user_choices
    ).ask()

    owner_id = int(owner_choice.split(" - ")[0])

    start_date = questionary.text(
        "Fecha y hora de inicio (YYYY-MM-DD HH:MM):",
        validate=lambda text: len(text) > 0 or "No puede estar vacío"
    ).ask()

    if not start_date:
        return

    try:
        parsed_start = date_parser.parse(start_date)
    except:
        console.print("[red]Formato de fecha inválido[/red]")
        pause()
        return

    tiene_fin = questionary.confirm(
        "¿Tiene fecha de fin?",
        default=True
    ).ask()

    end_date = None
    if tiene_fin:
        end_date = questionary.text(
            "Fecha y hora de fin (YYYY-MM-DD HH:MM):"
        ).ask()

        if end_date:
            try:
                parsed_end = date_parser.parse(end_date)
                end_date = parsed_end.isoformat()
            except:
                console.print("[red]Formato de fecha inválido, se omitirá fecha de fin[/red]")
                end_date = None

    description = questionary.text(
        "Descripción (opcional):"
    ).ask()

    data = {
        "name": name,
        "owner_id": owner_id,
        "start_date": parsed_start.isoformat(),
        "end_date": end_date,
        "description": description if description else None,
        "event_type": "regular"
    }

    console.print("\n[cyan]Creando evento...[/cyan]\n")
    response = requests.post(f"{API_BASE_URL}/events", json=data)
    event = handle_api_error(response)

    if event:
        console.print(f"[bold green]✅ Evento '{name}' creado exitosamente con ID: {event['id']}[/bold green]\n")

    pause()


def eliminar_evento():
    """Elimina un evento"""
    clear_screen()
    show_header()

    event_id = questionary.text(
        "Ingresa el ID del evento a eliminar:",
        validate=lambda text: text.isdigit() or "Debe ser un número"
    ).ask()

    if not event_id:
        return

    confirmar = questionary.confirm(
        f"¿Estás seguro de eliminar el evento #{event_id}?",
        default=False
    ).ask()

    if not confirmar:
        console.print("[yellow]Operación cancelada[/yellow]")
        pause()
        return

    console.print(f"\n[cyan]Eliminando evento #{event_id}...[/cyan]\n")

    response = requests.delete(f"{API_BASE_URL}/events/{event_id}")

    if response.status_code in [200, 204]:
        console.print(f"[bold green]✅ Evento #{event_id} eliminado exitosamente[/bold green]\n")
    else:
        handle_api_error(response)

    pause()


# ==================== MENÚ DE CALENDARIOS ====================

def menu_calendarios():
    """Menú de gestión de calendarios"""
    while True:
        clear_screen()
        show_header()

        choice = questionary.select(
            "📆 Gestión de Calendarios - ¿Qué deseas hacer?",
            choices=[
                "📋 Ver todos los calendarios",
                "🔍 Ver detalles de un calendario",
                "👥 Ver miembros de un calendario",
                "➕ Crear nuevo calendario",
                "⬅️  Volver al menú principal"
            ],
            style=custom_style
        ).ask()

        if choice == "📋 Ver todos los calendarios":
            listar_calendarios()
        elif choice == "🔍 Ver detalles de un calendario":
            ver_calendario()
        elif choice == "👥 Ver miembros de un calendario":
            ver_miembros_calendario()
        elif choice == "➕ Crear nuevo calendario":
            crear_calendario()
        elif choice == "⬅️  Volver al menú principal":
            break


def listar_calendarios():
    """Lista todos los calendarios"""
    clear_screen()
    show_header()

    console.print("[cyan]Consultando calendarios...[/cyan]\n")

    response = requests.get(f"{API_BASE_URL}/calendars")
    calendars = handle_api_error(response)

    if not calendars:
        pause()
        return

    table = Table(title="📆 Calendarios", show_header=True, header_style="bold magenta")
    table.add_column("ID", style="cyan", justify="right", width=5)
    table.add_column("Nombre", style="green", width=20)
    table.add_column("Descripción", style="yellow", width=30)
    table.add_column("User ID", style="blue", justify="right", width=8)
    table.add_column("Cumpleaños", style="magenta", width=10)

    for cal in calendars:
        table.add_row(
            str(cal['id']),
            cal['name'],
            cal.get('description', '-')[:28] + "..." if cal.get('description') and len(cal.get('description', '')) > 28 else cal.get('description', '-'),
            str(cal.get('user_id', '-')),
            "Sí" if cal.get('is_private_birthdays') else "No"
        )

    console.print(table)
    console.print(f"\n[cyan]Total: {len(calendars)} calendarios[/cyan]\n")
    pause()


def ver_calendario():
    """Muestra detalles de un calendario específico"""
    clear_screen()
    show_header()

    calendar_id = questionary.text(
        "Ingresa el ID del calendario:",
        validate=lambda text: text.isdigit() or "Debe ser un número"
    ).ask()

    if not calendar_id:
        return

    console.print(f"\n[cyan]Consultando calendario #{calendar_id}...[/cyan]\n")

    response = requests.get(f"{API_BASE_URL}/calendars/{calendar_id}")
    calendar = handle_api_error(response)

    if not calendar:
        pause()
        return

    info = f"[yellow]ID:[/yellow] {calendar['id']}\n"
    info += f"[yellow]Nombre:[/yellow] {calendar['name']}\n"
    info += f"[yellow]Descripción:[/yellow] {calendar.get('description', '-')}\n"
    info += f"[yellow]User ID:[/yellow] {calendar.get('user_id', '-')}\n"
    info += f"[yellow]Calendario de Cumpleaños:[/yellow] {'Sí' if calendar.get('is_private_birthdays') else 'No'}\n"
    info += f"[yellow]Color:[/yellow] {calendar.get('color', '-')}\n"
    info += f"[yellow]Por Defecto:[/yellow] {'Sí' if calendar.get('is_default') else 'No'}"

    console.print(Panel(info, title=f"[bold cyan]Calendario #{calendar['id']}[/bold cyan]", border_style="cyan"))
    console.print()
    pause()


def ver_miembros_calendario():
    """Muestra los miembros de un calendario"""
    clear_screen()
    show_header()

    calendar_id = questionary.text(
        "Ingresa el ID del calendario:",
        validate=lambda text: text.isdigit() or "Debe ser un número"
    ).ask()

    if not calendar_id:
        return

    console.print(f"\n[cyan]Consultando miembros del calendario #{calendar_id}...[/cyan]\n")

    response = requests.get(f"{API_BASE_URL}/calendars/{calendar_id}/memberships")
    memberships = handle_api_error(response)

    if not memberships:
        console.print("[yellow]Este calendario no tiene miembros adicionales[/yellow]\n")
        pause()
        return

    table = Table(title=f"👥 Miembros del Calendario #{calendar_id}", show_header=True, header_style="bold magenta")
    table.add_column("User ID", style="cyan", justify="right", width=10)
    table.add_column("Rol", style="green", width=15)
    table.add_column("Estado", style="yellow", width=15)
    table.add_column("Invitado Por", style="blue", justify="right", width=15)

    for member in memberships:
        table.add_row(
            str(member['user_id']),
            member['role'],
            member['status'],
            str(member.get('invited_by_user_id', '-'))
        )

    console.print(table)
    console.print(f"\n[cyan]Total: {len(memberships)} miembros[/cyan]\n")
    pause()


def crear_calendario():
    """Crea un nuevo calendario"""
    clear_screen()
    show_header()

    console.print("[bold cyan]➕ Crear Nuevo Calendario[/bold cyan]\n")

    name = questionary.text(
        "Nombre del calendario:",
        validate=lambda text: len(text) > 0 or "No puede estar vacío"
    ).ask()

    if not name:
        return

    # Seleccionar owner
    users_response = requests.get(f"{API_BASE_URL}/users")
    if users_response.status_code != 200:
        console.print("[red]Error al obtener usuarios[/red]")
        pause()
        return

    users = users_response.json()
    user_choices = [f"{u['id']} - {u.get('username', 'Usuario sin nombre')}" for u in users]

    owner_choice = questionary.select(
        "Selecciona el propietario del calendario:",
        choices=user_choices
    ).ask()

    owner_id = int(owner_choice.split(" - ")[0])

    description = questionary.text(
        "Descripción (opcional):"
    ).ask()

    is_birthdays = questionary.confirm(
        "¿Es un calendario de cumpleaños?",
        default=False
    ).ask()

    data = {
        "name": name,
        "user_id": owner_id,
        "description": description if description else None,
        "is_private_birthdays": is_birthdays
    }

    console.print("\n[cyan]Creando calendario...[/cyan]\n")
    response = requests.post(f"{API_BASE_URL}/calendars", json=data)
    calendar = handle_api_error(response)

    if calendar:
        console.print(f"[bold green]✅ Calendario '{name}' creado exitosamente con ID: {calendar['id']}[/bold green]\n")

    pause()


# ==================== MENÚ PRINCIPAL ====================

def menu_principal():
    """Menú principal de la aplicación"""
    while True:
        clear_screen()
        show_header()

        # Verificar conexión con la API
        try:
            response = requests.get(f"{API_BASE_URL}/", timeout=2)
            if response.status_code == 200:
                console.print(f"[dim green]✓ Conectado a {API_BASE_URL}[/dim green]\n")
            else:
                console.print(f"[dim yellow]⚠ API respondió con código {response.status_code}[/dim yellow]\n")
        except:
            console.print(f"[dim red]✗ No se pudo conectar a {API_BASE_URL}[/dim red]\n")

        choice = questionary.select(
            "¿Qué deseas hacer?",
            choices=[
                "👥 Gestionar Usuarios",
                "📞 Gestionar Contactos",
                "📅 Gestionar Eventos",
                "📆 Gestionar Calendarios",
                "❌ Salir"
            ],
            style=custom_style
        ).ask()

        if choice == "👥 Gestionar Usuarios":
            menu_usuarios()
        elif choice == "📞 Gestionar Contactos":
            menu_contactos()
        elif choice == "📅 Gestionar Eventos":
            menu_eventos()
        elif choice == "📆 Gestionar Calendarios":
            menu_calendarios()
        elif choice == "❌ Salir":
            clear_screen()
            console.print("\n[cyan]👋 ¡Hasta luego![/cyan]\n")
            break


if __name__ == "__main__":
    try:
        menu_principal()
    except KeyboardInterrupt:
        clear_screen()
        console.print("\n[cyan]👋 ¡Hasta luego![/cyan]\n")
