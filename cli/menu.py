#!/usr/bin/env python3
"""
Agenda Phoenix - Interfaz interactiva con menús
Soporta dos modos: Usuario (simulación) y Backoffice (administración)
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

# Variables globales para el modo y usuario actual
MODO_USUARIO = "usuario"
MODO_BACKOFFICE = "backoffice"
modo_actual = None
usuario_actual = None
usuario_actual_info = None

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
    """Muestra el encabezado de la aplicación con información de modo/usuario"""
    header_text = "[bold cyan]🗓️  Agenda Phoenix[/bold cyan]\n"
    header_text += "[dim]Sistema de gestión de calendarios y eventos[/dim]"

    if modo_actual == MODO_USUARIO and usuario_actual_info:
        header_text += f"\n\n[yellow]👤 Modo Usuario:[/yellow] {usuario_actual_info.get('username', usuario_actual_info.get('contact_name', f'Usuario #{usuario_actual}'))}"
    elif modo_actual == MODO_BACKOFFICE:
        header_text += "\n\n[green]🔧 Modo Backoffice[/green]"

    console.print(Panel.fit(header_text, border_style="cyan"))
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


def seleccionar_modo():
    """Pantalla inicial para seleccionar el modo de uso"""
    global modo_actual, usuario_actual, usuario_actual_info

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
        console.print("[red]Asegúrate de que el backend esté corriendo (docker compose up -d)[/red]\n")
        pause()
        return False

    choice = questionary.select(
        "¿Cómo deseas acceder a Agenda Phoenix?",
        choices=[
            "👤 Como Usuario (simular experiencia de usuario)",
            "🔧 Modo Backoffice (administración completa)",
            "❌ Salir"
        ],
        style=custom_style
    ).ask()

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
    console.print(Panel.fit(
        "[bold cyan]👤 Selección de Usuario[/bold cyan]\n"
        "[dim]Elige el usuario cuya experiencia deseas simular[/dim]",
        border_style="cyan"
    ))
    console.print()

    console.print("[cyan]Cargando usuarios disponibles...[/cyan]\n")

    # Obtener usuarios
    users_response = requests.get(f"{API_BASE_URL}/users")
    if users_response.status_code != 200:
        console.print("[red]Error al obtener usuarios[/red]")
        pause()
        return False

    users = users_response.json()

    # Obtener contactos para mostrar nombres
    contacts_response = requests.get(f"{API_BASE_URL}/contacts")
    contacts = {}
    if contacts_response.status_code == 200:
        for contact in contacts_response.json():
            contacts[contact['id']] = contact

    # Crear opciones de usuarios
    user_choices = []
    user_mapping = {}

    for user in users:
        contact_name = ""
        if user.get('contact_id') and user['contact_id'] in contacts:
            contact_name = contacts[user['contact_id']]['name']

        username = user.get('username', '')
        if username and contact_name:
            display = f"{user['id']} - {username} ({contact_name})"
        elif username:
            display = f"{user['id']} - {username}"
        elif contact_name:
            display = f"{user['id']} - {contact_name}"
        else:
            display = f"{user['id']} - Usuario sin nombre"

        user_choices.append(display)
        user_mapping[display] = {
            'id': user['id'],
            'username': username,
            'contact_name': contact_name
        }

    user_choices.append("⬅️  Volver")

    user_choice = questionary.select(
        "Selecciona un usuario:",
        choices=user_choices,
        style=custom_style
    ).ask()

    if user_choice == "⬅️  Volver":
        return seleccionar_modo()

    usuario_actual = user_mapping[user_choice]['id']
    usuario_actual_info = user_mapping[user_choice]

    return True


# ==================== MENÚ DE EVENTOS (ADAPTADO) ====================

def menu_eventos():
    """Menú de gestión de eventos (adaptado según el modo)"""
    while True:
        clear_screen()
        show_header()

        if modo_actual == MODO_USUARIO:
            choices = [
                "📋 Ver MIS eventos",
                "🔍 Ver detalles de un evento",
                "➕ Crear nuevo evento",
                "📨 Ver MIS invitaciones pendientes",
                "🔔 Suscribirme a usuario público",
                "⬅️  Volver al menú principal"
            ]
        else:  # MODO_BACKOFFICE
            choices = [
                "📋 Ver eventos de un usuario",
                "🔍 Ver detalles de un evento",
                "➕ Crear nuevo evento",
                "🗑️  Eliminar un evento",
                "⬅️  Volver al menú principal"
            ]

        choice = questionary.select(
            "📅 Gestión de Eventos - ¿Qué deseas hacer?",
            choices=choices,
            style=custom_style
        ).ask()

        if choice == "📋 Ver MIS eventos":
            ver_mis_eventos()
        elif choice == "📋 Ver eventos de un usuario":
            listar_eventos_usuario()
        elif choice == "🔍 Ver detalles de un evento":
            ver_evento()
        elif choice == "➕ Crear nuevo evento":
            crear_evento()
        elif choice == "📨 Ver MIS invitaciones pendientes":
            ver_mis_invitaciones()
        elif choice == "🔔 Suscribirme a usuario público":
            suscribirse_a_usuario_publico()
        elif choice == "🗑️  Eliminar un evento":
            eliminar_evento()
        elif choice == "⬅️  Volver al menú principal":
            break


def ver_mis_eventos():
    """Muestra los eventos del usuario actual (Modo Usuario)"""
    clear_screen()
    show_header()

    console.print(f"[cyan]Consultando tus eventos...[/cyan]\n")

    response = requests.get(f"{API_BASE_URL}/users/{usuario_actual}/events")
    events = handle_api_error(response)

    if not events:
        console.print("[yellow]No tienes eventos[/yellow]\n")
        pause()
        return

    table = Table(title="📅 Mis Eventos", show_header=True, header_style="bold magenta")
    table.add_column("ID", style="cyan", justify="right", width=5)
    table.add_column("Nombre", style="green", width=35)
    table.add_column("Fecha Inicio", style="yellow", width=18)
    table.add_column("Tipo", style="blue", width=10)
    table.add_column("Propietario", style="magenta", width=12)

    for event in events[:30]:
        start = datetime.fromisoformat(event['start_date'].replace('Z', '+00:00'))

        # Determinar si es propio o ajeno
        es_propio = event['owner_id'] == usuario_actual
        propietario = "Yo" if es_propio else f"Usuario #{event['owner_id']}"

        table.add_row(
            str(event['id']),
            event['name'][:33] + "..." if len(event['name']) > 33 else event['name'],
            start.strftime("%Y-%m-%d %H:%M"),
            event['event_type'],
            propietario
        )

    console.print(table)

    if len(events) > 30:
        console.print(f"\n[dim]Mostrando 30 de {len(events)} eventos[/dim]")

    console.print(f"\n[cyan]Total: {len(events)} eventos[/cyan]")
    console.print("[dim]Incluye tus eventos propios, invitaciones aceptadas y suscripciones[/dim]\n")
    pause()


def ver_mis_invitaciones():
    """Muestra las invitaciones pendientes del usuario actual"""
    clear_screen()
    show_header()

    console.print(f"[cyan]Consultando tus invitaciones pendientes...[/cyan]\n")

    # Por ahora simulamos que no hay endpoint específico, habría que agregarlo a la API
    console.print("[yellow]Esta funcionalidad requiere un endpoint específico en la API[/yellow]")
    console.print("[dim]Endpoint sugerido: GET /users/{user_id}/invitations/pending[/dim]\n")
    pause()


def suscribirse_a_usuario_publico():
    """Permite suscribirse a un usuario público"""
    clear_screen()
    show_header()

    console.print("[bold cyan]🔔 Suscripción a Usuario Público[/bold cyan]\n")

    # Obtener usuarios públicos (Instagram, etc)
    response = requests.get(f"{API_BASE_URL}/users")
    if response.status_code != 200:
        console.print("[red]Error al obtener usuarios[/red]")
        pause()
        return

    users = response.json()
    public_users = [u for u in users if u.get('username')]  # Usuarios con username son públicos

    if not public_users:
        console.print("[yellow]No hay usuarios públicos disponibles[/yellow]\n")
        pause()
        return

    user_choices = [f"{u['id']} - {u['username']}" for u in public_users]
    user_choices.append("⬅️  Cancelar")

    user_choice = questionary.select(
        "Selecciona un usuario público para suscribirte:",
        choices=user_choices,
        style=custom_style
    ).ask()

    if user_choice == "⬅️  Cancelar":
        return

    public_user_id = int(user_choice.split(" - ")[0])

    # Obtener eventos del usuario público
    response = requests.get(f"{API_BASE_URL}/users/{public_user_id}/events")
    events = handle_api_error(response)

    if not events:
        console.print("[yellow]Este usuario no tiene eventos públicos[/yellow]\n")
        pause()
        return

    console.print(f"\n[cyan]Suscribiéndote a {len(events)} eventos...[/cyan]\n")

    # Crear interacciones de tipo 'subscribed'
    subscribed_count = 0
    for event in events:
        data = {
            "event_id": event['id'],
            "user_id": usuario_actual,
            "interaction_type": "subscribed"
        }
        try:
            response = requests.post(f"{API_BASE_URL}/event-interactions", json=data)
            if response.status_code in [200, 201]:
                subscribed_count += 1
        except:
            pass

    console.print(f"[bold green]✅ Suscrito exitosamente a {subscribed_count} eventos[/bold green]\n")
    pause()


def listar_eventos_usuario():
    """Lista eventos de un usuario (Modo Backoffice)"""
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

    for event in events[:20]:
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

    # Mostrar si es propio o ajeno en modo usuario
    if modo_actual == MODO_USUARIO:
        es_propio = event['owner_id'] == usuario_actual
        propietario = "Yo" if es_propio else f"Usuario #{event['owner_id']}"
        info += f"[yellow]Propietario:[/yellow] {propietario}\n"
    else:
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

    # En modo usuario, el owner es el usuario actual
    if modo_actual == MODO_USUARIO:
        owner_id = usuario_actual
        console.print(f"[dim]El evento será creado como tuyo (Usuario #{owner_id})[/dim]\n")
    else:
        # En modo backoffice, seleccionar owner
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
    """Elimina un evento (solo Modo Backoffice)"""
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


# ==================== MENÚ DE CALENDARIOS (ADAPTADO) ====================

def menu_calendarios():
    """Menú de gestión de calendarios (adaptado según el modo)"""
    while True:
        clear_screen()
        show_header()

        if modo_actual == MODO_USUARIO:
            choices = [
                "📋 Ver MIS calendarios",
                "🔍 Ver detalles de un calendario",
                "➕ Crear nuevo calendario",
                "⬅️  Volver al menú principal"
            ]
        else:  # MODO_BACKOFFICE
            choices = [
                "📋 Ver todos los calendarios",
                "🔍 Ver detalles de un calendario",
                "👥 Ver miembros de un calendario",
                "➕ Crear nuevo calendario",
                "⬅️  Volver al menú principal"
            ]

        choice = questionary.select(
            "📆 Gestión de Calendarios - ¿Qué deseas hacer?",
            choices=choices,
            style=custom_style
        ).ask()

        if choice == "📋 Ver MIS calendarios":
            ver_mis_calendarios()
        elif choice == "📋 Ver todos los calendarios":
            listar_todos_calendarios()
        elif choice == "🔍 Ver detalles de un calendario":
            ver_calendario()
        elif choice == "👥 Ver miembros de un calendario":
            ver_miembros_calendario()
        elif choice == "➕ Crear nuevo calendario":
            crear_calendario()
        elif choice == "⬅️  Volver al menú principal":
            break


def ver_mis_calendarios():
    """Muestra los calendarios del usuario actual (Modo Usuario)"""
    clear_screen()
    show_header()

    console.print(f"[cyan]Consultando tus calendarios...[/cyan]\n")

    # Obtener todos los calendarios y filtrar los del usuario
    response = requests.get(f"{API_BASE_URL}/calendars")
    all_calendars = handle_api_error(response)

    if not all_calendars:
        pause()
        return

    # Filtrar calendarios donde el usuario es owner
    my_calendars = [cal for cal in all_calendars if cal.get('user_id') == usuario_actual]

    # TODO: También debería incluir calendarios compartidos con el usuario
    # Eso requeriría un endpoint específico o consultar memberships

    if not my_calendars:
        console.print("[yellow]No tienes calendarios propios[/yellow]\n")
        pause()
        return

    table = Table(title="📆 Mis Calendarios", show_header=True, header_style="bold magenta")
    table.add_column("ID", style="cyan", justify="right", width=5)
    table.add_column("Nombre", style="green", width=25)
    table.add_column("Descripción", style="yellow", width=35)
    table.add_column("Tipo", style="magenta", width=12)

    for cal in my_calendars:
        tipo = "Cumpleaños" if cal.get('is_private_birthdays') else "Normal"
        table.add_row(
            str(cal['id']),
            cal['name'],
            cal.get('description', '-')[:33] + "..." if cal.get('description') and len(cal.get('description', '')) > 33 else cal.get('description', '-'),
            tipo
        )

    console.print(table)
    console.print(f"\n[cyan]Total: {len(my_calendars)} calendarios propios[/cyan]\n")
    pause()


def listar_todos_calendarios():
    """Lista todos los calendarios (Modo Backoffice)"""
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

    # En modo usuario, mostrar si es propio
    if modo_actual == MODO_USUARIO:
        es_propio = calendar.get('user_id') == usuario_actual
        propietario = "Yo" if es_propio else f"Usuario #{calendar.get('user_id', '-')}"
        info += f"[yellow]Propietario:[/yellow] {propietario}\n"
    else:
        info += f"[yellow]User ID:[/yellow] {calendar.get('user_id', '-')}\n"

    info += f"[yellow]Calendario de Cumpleaños:[/yellow] {'Sí' if calendar.get('is_private_birthdays') else 'No'}\n"
    info += f"[yellow]Color:[/yellow] {calendar.get('color', '-')}\n"
    info += f"[yellow]Por Defecto:[/yellow] {'Sí' if calendar.get('is_default') else 'No'}"

    console.print(Panel(info, title=f"[bold cyan]Calendario #{calendar['id']}[/bold cyan]", border_style="cyan"))
    console.print()
    pause()


def ver_miembros_calendario():
    """Muestra los miembros de un calendario (Modo Backoffice)"""
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

    # En modo usuario, el owner es el usuario actual
    if modo_actual == MODO_USUARIO:
        owner_id = usuario_actual
        console.print(f"[dim]El calendario será creado como tuyo (Usuario #{owner_id})[/dim]\n")
    else:
        # En modo backoffice, seleccionar owner
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


# ==================== MENÚ DE CONTACTOS Y USUARIOS (SOLO BACKOFFICE) ====================

def menu_usuarios_backoffice():
    """Menú de gestión de usuarios (solo Backoffice)"""
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
            listar_usuarios_backoffice()
        elif choice == "🔍 Ver detalles de un usuario":
            ver_usuario_backoffice()
        elif choice == "➕ Crear nuevo usuario":
            crear_usuario_backoffice()
        elif choice == "⬅️  Volver al menú principal":
            break


def listar_usuarios_backoffice():
    """Lista todos los usuarios (Backoffice)"""
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


def ver_usuario_backoffice():
    """Muestra detalles de un usuario (Backoffice)"""
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

    info = f"[yellow]ID:[/yellow] {user['id']}\n"
    info += f"[yellow]Username:[/yellow] {user.get('username', '-')}\n"
    info += f"[yellow]Auth Provider:[/yellow] {user.get('auth_provider', '-')}\n"
    info += f"[yellow]Auth ID:[/yellow] {user.get('auth_id', '-')}\n"

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


def crear_usuario_backoffice():
    """Crea un nuevo usuario (Backoffice)"""
    clear_screen()
    show_header()

    console.print("[bold cyan]➕ Crear Nuevo Usuario[/bold cyan]\n")

    # Implementación simplificada
    console.print("[yellow]Funcionalidad de creación de usuarios (ver menu.py original)[/yellow]\n")
    pause()


def menu_contactos_backoffice():
    """Menú de gestión de contactos (solo Backoffice)"""
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
            listar_contactos_backoffice()
        elif choice == "🔍 Ver detalles de un contacto":
            ver_contacto_backoffice()
        elif choice == "➕ Crear nuevo contacto":
            crear_contacto_backoffice()
        elif choice == "⬅️  Volver al menú principal":
            break


def listar_contactos_backoffice():
    """Lista todos los contactos (Backoffice)"""
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


def ver_contacto_backoffice():
    """Muestra detalles de un contacto (Backoffice)"""
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


def crear_contacto_backoffice():
    """Crea un nuevo contacto (Backoffice)"""
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


# ==================== MENÚ PRINCIPAL ====================

def menu_principal():
    """Menú principal de la aplicación (adaptado según el modo)"""
    while True:
        clear_screen()
        show_header()

        if modo_actual == MODO_USUARIO:
            choices = [
                "📅 MIS Eventos",
                "📆 MIS Calendarios",
                "👤 Cambiar Usuario",
                "❌ Salir"
            ]
        else:  # MODO_BACKOFFICE
            choices = [
                "👥 Gestionar Usuarios",
                "📞 Gestionar Contactos",
                "📅 Gestionar Eventos",
                "📆 Gestionar Calendarios",
                "🔄 Cambiar Modo",
                "❌ Salir"
            ]

        choice = questionary.select(
            "¿Qué deseas hacer?",
            choices=choices,
            style=custom_style
        ).ask()

        if choice == "📅 MIS Eventos" or choice == "📅 Gestionar Eventos":
            menu_eventos()
        elif choice == "📆 MIS Calendarios" or choice == "📆 Gestionar Calendarios":
            menu_calendarios()
        elif choice == "👥 Gestionar Usuarios":
            menu_usuarios_backoffice()
        elif choice == "📞 Gestionar Contactos":
            menu_contactos_backoffice()
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
