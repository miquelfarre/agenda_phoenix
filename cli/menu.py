#!/usr/bin/env python3
"""
Agenda Phoenix - Interfaz interactiva con menús
Soporta dos modos: Usuario (simulación) y Backoffice (administración)

IMPORTANTE: Este CLI es un cliente de la API, no implementa lógica de negocio.
Ver DEVELOPMENT_RULES.md para las reglas de desarrollo.
"""
import questionary
from questionary import Style
import requests
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich import print as rprint
from datetime import datetime, timedelta
from dateutil import parser as date_parser
from config import API_BASE_URL
from utils import (
    format_datetime,
    truncate_text,
    create_events_table,
    create_invitations_table,
    create_calendars_table,
    create_conflicts_table,
    format_count_message,
    get_user_display_name,
    show_pagination_info
)

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

        # Obtener contador de invitaciones pendientes
        try:
            response = requests.get(f"{API_BASE_URL}/interactions?user_id={usuario_actual}&interaction_type=invited&status=pending", timeout=1)
            if response.status_code == 200:
                pending_invitations = len(response.json())
                if pending_invitations > 0:
                    header_text += f"\n[magenta]📨 {pending_invitations} invitación{'es' if pending_invitations != 1 else ''} pendiente{'s' if pending_invitations != 1 else ''}[/magenta]"
        except:
            pass  # Si falla, simplemente no mostramos el contador

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
                "📊 Dashboard / Estadísticas",
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

        if choice == "📊 Dashboard / Estadísticas":
            ver_dashboard()
        elif choice == "📋 Ver MIS eventos":
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
    """Muestra los eventos del usuario actual (Modo Usuario) con filtros"""
    clear_screen()
    show_header()

    # Ofrecer opciones de filtrado
    filter_choice = questionary.select(
        "¿Cómo deseas ver tus eventos?",
        choices=[
            "📅 Todos los eventos",
            "📆 Próximos 7 días",
            "📊 Este mes",
            "🔍 Buscar por nombre",
            "⬅️  Cancelar"
        ],
        style=custom_style
    ).ask()

    if filter_choice == "⬅️  Cancelar":
        return

    console.print(f"\n[cyan]Consultando tus eventos...[/cyan]\n")

    # Preparar parámetros para la API según el filtro seleccionado
    now = datetime.now()
    params = {}

    if filter_choice == "📆 Próximos 7 días":
        params["from_date"] = now.isoformat()
        params["to_date"] = (now + timedelta(days=7)).isoformat()
        title = "📆 Mis Eventos - Próximos 7 Días"
    elif filter_choice == "📊 Este mes":
        start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        if now.month == 12:
            end_of_month = start_of_month.replace(year=now.year + 1, month=1, day=1) - timedelta(seconds=1)
        else:
            end_of_month = start_of_month.replace(month=now.month + 1, day=1) - timedelta(seconds=1)
        params["from_date"] = start_of_month.isoformat()
        params["to_date"] = end_of_month.isoformat()
        title = f"📊 Mis Eventos - {now.strftime('%B %Y')}"
    elif filter_choice == "🔍 Buscar por nombre":
        search_term = questionary.text(
            "Ingresa el nombre o parte del nombre del evento:",
            validate=lambda text: len(text) > 0 or "Debe ingresar al menos un carácter"
        ).ask()

        if not search_term:
            return

        params["search"] = search_term
        title = f"🔍 Búsqueda: '{search_term}'"
    else:
        title = "📅 Mis Eventos"

    # Llamar a la API con los parámetros
    response = requests.get(f"{API_BASE_URL}/users/{usuario_actual}/events", params=params)
    events = handle_api_error(response)

    if not events:
        console.print(f"[yellow]No se encontraron eventos[/yellow]\n")
        pause()
        return

    # Usar función de utilidad para crear la tabla
    table = create_events_table(events, title=title, current_user_id=usuario_actual, max_rows=30)
    console.print(table)

    show_pagination_info(min(30, len(events)), len(events))

    console.print(f"\n[cyan]Total: {format_count_message(len(events), 'evento', 'eventos')}[/cyan]")
    console.print("[dim]Incluye tus eventos propios, invitaciones aceptadas y suscripciones[/dim]\n")
    pause()


def ver_mis_invitaciones():
    """Muestra las invitaciones pendientes del usuario actual y permite gestionarlas"""
    clear_screen()
    show_header()

    console.print(f"[cyan]Consultando tus invitaciones pendientes...[/cyan]\n")

    # Obtener invitaciones pendientes del usuario
    response = requests.get(f"{API_BASE_URL}/interactions?user_id={usuario_actual}&interaction_type=invited&status=pending")
    invitations = handle_api_error(response)

    if not invitations:
        console.print("[yellow]No tienes invitaciones pendientes[/yellow]\n")
        pause()
        return

    # Obtener detalles de los eventos invitados
    events_map = {}
    for inv in invitations:
        event_response = requests.get(f"{API_BASE_URL}/events/{inv['event_id']}")
        if event_response.status_code == 200:
            events_map[inv['event_id']] = event_response.json()

    # Usar función de utilidad para crear la tabla
    table = create_invitations_table(invitations, events_map, title="📨 Invitaciones Pendientes")
    console.print(table)
    console.print(f"\n[cyan]Total: {format_count_message(len(invitations), 'invitación pendiente', 'invitaciones pendientes')}[/cyan]\n")

    # Preguntar si desea gestionar alguna invitación
    gestionar = questionary.confirm(
        "¿Deseas aceptar o rechazar alguna invitación?",
        default=False
    ).ask()

    if not gestionar:
        return

    # Seleccionar invitación a gestionar
    inv_choices = []
    for inv in invitations:
        event = events_map.get(inv['event_id'])
        if event:
            inv_choices.append(f"ID {inv['id']} - {event['name'][:40]}")

    inv_choices.append("⬅️  Cancelar")

    inv_choice = questionary.select(
        "Selecciona la invitación a gestionar:",
        choices=inv_choices,
        style=custom_style
    ).ask()

    if inv_choice == "⬅️  Cancelar":
        return

    inv_id = int(inv_choice.split(" - ")[0].split()[1])
    selected_inv = next((inv for inv in invitations if inv['id'] == inv_id), None)

    if not selected_inv:
        console.print("[red]Error: invitación no encontrada[/red]")
        pause()
        return

    # Preguntar acción
    action = questionary.select(
        "¿Qué deseas hacer con esta invitación?",
        choices=[
            "✅ Aceptar invitación",
            "❌ Rechazar invitación",
            "⬅️  Cancelar"
        ],
        style=custom_style
    ).ask()

    if action == "⬅️  Cancelar":
        return

    new_status = "accepted" if action == "✅ Aceptar invitación" else "rejected"

    # Si está aceptando, verificar conflictos
    if new_status == "accepted":
        event = events_map.get(selected_inv['event_id'])
        if event:
            console.print(f"\n[cyan]Verificando conflictos de horario...[/cyan]\n")

            # Llamar a la API para detectar conflictos
            params = {
                "user_id": usuario_actual,
                "start_date": event['start_date'],
                "exclude_event_id": event['id']
            }
            if event.get('end_date'):
                params["end_date"] = event['end_date']

            conflicts_response = requests.get(f"{API_BASE_URL}/events/check-conflicts", params=params, timeout=5)
            conflicts = handle_api_error(conflicts_response) if conflicts_response.status_code == 200 else []

            if conflicts:
                console.print(f"[bold yellow]⚠️  ADVERTENCIA: Conflicto de horario detectado[/bold yellow]\n")
                console.print(f"Este evento se solapa con {format_count_message(len(conflicts), 'evento existente', 'eventos existentes')}:\n")

                # Usar función de utilidad para mostrar conflictos
                conflict_table = create_conflicts_table(conflicts)
                console.print(conflict_table)
                console.print()

                # Preguntar si desea continuar
                continuar = questionary.confirm(
                    "¿Deseas aceptar la invitación de todos modos?",
                    default=False
                ).ask()

                if not continuar:
                    console.print("[yellow]Operación cancelada[/yellow]\n")
                    pause()
                    return

    console.print(f"\n[cyan]Actualizando invitación...[/cyan]\n")

    # Actualizar el estado de la invitación
    update_data = {
        "status": new_status
    }

    response = requests.patch(f"{API_BASE_URL}/interactions/{inv_id}", json=update_data)

    if response.status_code in [200, 204]:
        status_text = "aceptada" if new_status == "accepted" else "rechazada"
        console.print(f"[bold green]✅ Invitación {status_text} exitosamente[/bold green]\n")
    else:
        handle_api_error(response)

    pause()


def ver_dashboard():
    """Muestra un panel de estadísticas y resumen para el usuario actual (Modo Usuario)"""
    clear_screen()
    show_header()

    console.print("[bold cyan]📊 Dashboard / Estadísticas[/bold cyan]\n")
    console.print("[cyan]Recopilando información...[/cyan]\n")

    # Llamar a la API para obtener el dashboard
    response = requests.get(f"{API_BASE_URL}/users/{usuario_actual}/dashboard")
    dashboard = handle_api_error(response)

    if not dashboard:
        pause()
        return

    now = datetime.now()

    # Construir panel de estadísticas usando los datos de la API
    stats = f"[bold green]📈 Resumen General[/bold green]\n\n"
    stats += f"  [yellow]Total de eventos:[/yellow] {dashboard['total_events']}\n"
    stats += f"  [yellow]Eventos propios:[/yellow] {dashboard['owned_events']}\n"
    stats += f"  [yellow]Eventos suscritos:[/yellow] {dashboard['subscribed_events']}\n"
    stats += f"  [yellow]Calendarios propios:[/yellow] {dashboard['calendars_count']}\n\n"

    stats += f"[bold magenta]📅 Eventos Próximos[/bold magenta]\n\n"
    stats += f"  [yellow]Próximos 7 días:[/yellow] {dashboard['upcoming_7_days']} evento(s)\n"
    stats += f"  [yellow]Este mes ({now.strftime('%B %Y')}):[/yellow] {dashboard['this_month_count']} evento(s)\n\n"

    stats += f"[bold cyan]📨 Invitaciones[/bold cyan]\n\n"
    stats += f"  [yellow]Pendientes:[/yellow] {dashboard['pending_invitations']} invitación(es)\n\n"

    if dashboard['next_event']:
        next_event = dashboard['next_event']
        next_start = datetime.fromisoformat(next_event['start_date'].replace('Z', '+00:00'))
        days_until = next_event['days_until']

        stats += f"[bold blue]🔔 Próximo Evento[/bold blue]\n\n"
        stats += f"  [yellow]Nombre:[/yellow] {next_event['name']}\n"
        stats += f"  [yellow]Fecha:[/yellow] {next_start.strftime('%Y-%m-%d %H:%M')}\n"

        if days_until == 0:
            stats += f"  [yellow]Tiempo:[/yellow] [bold red]¡Hoy![/bold red]\n"
        elif days_until == 1:
            stats += f"  [yellow]Tiempo:[/yellow] Mañana\n"
        else:
            stats += f"  [yellow]Tiempo:[/yellow] En {days_until} días\n"
    else:
        stats += f"[bold blue]🔔 Próximo Evento[/bold blue]\n\n"
        stats += f"  [dim]No hay eventos próximos programados[/dim]\n"

    console.print(Panel(stats, title="[bold cyan]📊 Dashboard[/bold cyan]", border_style="cyan", padding=(1, 2)))
    console.print()

    # Mostrar tabla de próximos eventos si existen
    if dashboard['upcoming_7_days_events']:
        console.print("\n[bold magenta]📆 Eventos en los Próximos 7 Días[/bold magenta]\n")

        table = Table(show_header=True, header_style="bold cyan")
        table.add_column("Fecha", style="yellow", width=18)
        table.add_column("Nombre", style="green", width=40)
        table.add_column("Tipo", style="blue", width=10)

        for event in dashboard['upcoming_7_days_events']:
            start = datetime.fromisoformat(event['start_date'].replace('Z', '+00:00'))
            table.add_row(
                start.strftime("%Y-%m-%d %H:%M"),
                event['name'][:38] + "..." if len(event['name']) > 38 else event['name'],
                event['event_type']
            )

        console.print(table)

        if dashboard['upcoming_7_days'] > 10:
            console.print(f"\n[dim]Mostrando 10 de {dashboard['upcoming_7_days']} eventos próximos[/dim]")

        console.print()

    pause()


def suscribirse_a_usuario_publico():
    """Permite suscribirse a un usuario público usando endpoint bulk"""
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

    console.print(f"\n[cyan]Suscribiéndote a eventos del usuario...[/cyan]\n")

    # Llamar al endpoint bulk de suscripción
    response = requests.post(f"{API_BASE_URL}/users/{usuario_actual}/subscribe/{public_user_id}")
    result = handle_api_error(response)

    if result:
        console.print(f"[bold green]✅ {result['message']}[/bold green]")
        if result.get('already_subscribed_count', 0) > 0:
            console.print(f"[yellow]ℹ️  Ya estabas suscrito a {result['already_subscribed_count']} eventos[/yellow]")
        if result.get('error_count', 0) > 0:
            console.print(f"[red]⚠️  {result['error_count']} errores durante la suscripción[/red]")

    console.print()
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

    # Usar función de utilidad para crear la tabla
    table = create_events_table(events, title=f"📅 Eventos del Usuario #{user_id}", max_rows=20)
    console.print(table)

    show_pagination_info(min(20, len(events)), len(events))

    console.print(f"\n[cyan]Total: {format_count_message(len(events), 'evento', 'eventos')}[/cyan]\n")
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

    info = f"[yellow]ID:[/yellow] {event['id']}\n"
    info += f"[yellow]Nombre:[/yellow] {event['name']}\n"
    info += f"[yellow]Descripción:[/yellow] {event.get('description', '-')}\n"
    info += f"[yellow]Fecha Inicio:[/yellow] {format_datetime(event['start_date'])}\n"

    if event.get('end_date'):
        info += f"[yellow]Fecha Fin:[/yellow] {format_datetime(event['end_date'])}\n"

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

    # En modo usuario, verificar conflictos antes de crear
    if modo_actual == MODO_USUARIO:
        console.print(f"\n[cyan]Verificando conflictos de horario...[/cyan]\n")

        # Llamar a la API para detectar conflictos
        params = {
            "user_id": owner_id,
            "start_date": parsed_start.isoformat()
        }
        if end_date:
            params["end_date"] = end_date

        conflicts_response = requests.get(f"{API_BASE_URL}/events/check-conflicts", params=params, timeout=5)
        conflicts = handle_api_error(conflicts_response) if conflicts_response.status_code == 200 else []

        if conflicts:
            console.print(f"[bold yellow]⚠️  ADVERTENCIA: Conflicto de horario detectado[/bold yellow]\n")
            console.print(f"Este evento se solapa con {format_count_message(len(conflicts), 'evento existente', 'eventos existentes')}:\n")

            # Usar función de utilidad para mostrar conflictos
            conflict_table = create_conflicts_table(conflicts)
            console.print(conflict_table)
            console.print()

            # Preguntar si desea continuar
            continuar = questionary.confirm(
                "¿Deseas crear el evento de todos modos?",
                default=False
            ).ask()

            if not continuar:
                console.print("[yellow]Operación cancelada[/yellow]\n")
                pause()
                return

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
    """Muestra los calendarios del usuario actual (Modo Usuario) - propios y compartidos"""
    clear_screen()
    show_header()

    console.print(f"[cyan]Consultando tus calendarios...[/cyan]\n")

    # Obtener todos los calendarios
    calendars_response = requests.get(f"{API_BASE_URL}/calendars")
    all_calendars = handle_api_error(calendars_response)

    if not all_calendars:
        pause()
        return

    # Filtrar calendarios donde el usuario es owner
    my_calendars = [cal for cal in all_calendars if cal.get('user_id') == usuario_actual]

    # Obtener calendarios compartidos (memberships)
    memberships_response = requests.get(f"{API_BASE_URL}/calendar_memberships?user_id={usuario_actual}")
    memberships = handle_api_error(memberships_response)

    shared_calendars = []
    if memberships:
        # Obtener detalles de los calendarios compartidos
        calendars_map = {cal['id']: cal for cal in all_calendars}

        for membership in memberships:
            cal_id = membership['calendar_id']
            if cal_id in calendars_map and calendars_map[cal_id]['user_id'] != usuario_actual:
                # Solo incluir si no somos el owner (para evitar duplicados)
                cal = calendars_map[cal_id]
                cal['membership_status'] = membership['status']
                cal['membership_role'] = membership['role']
                cal['membership_id'] = membership['id']
                shared_calendars.append(cal)

    total_calendars = len(my_calendars) + len(shared_calendars)

    if total_calendars == 0:
        console.print("[yellow]No tienes calendarios[/yellow]\n")
        pause()
        return

    # Tabla de calendarios propios
    if my_calendars:
        table_own = Table(title="📆 Mis Calendarios Propios", show_header=True, header_style="bold magenta")
        table_own.add_column("ID", style="cyan", justify="right", width=5)
        table_own.add_column("Nombre", style="green", width=25)
        table_own.add_column("Descripción", style="yellow", width=30)
        table_own.add_column("Tipo", style="magenta", width=12)

        for cal in my_calendars:
            tipo = "Cumpleaños" if cal.get('is_private_birthdays') else "Normal"
            table_own.add_row(
                str(cal['id']),
                cal['name'],
                cal.get('description', '-')[:28] + "..." if cal.get('description') and len(cal.get('description', '')) > 28 else cal.get('description', '-'),
                tipo
            )

        console.print(table_own)
        console.print(f"\n[cyan]{len(my_calendars)} calendario(s) propio(s)[/cyan]\n")

    # Tabla de calendarios compartidos
    if shared_calendars:
        table_shared = Table(title="🤝 Calendarios Compartidos Conmigo", show_header=True, header_style="bold cyan")
        table_shared.add_column("ID", style="cyan", justify="right", width=5)
        table_shared.add_column("Nombre", style="green", width=20)
        table_shared.add_column("Rol", style="blue", width=10)
        table_shared.add_column("Estado", style="yellow", width=12)
        table_shared.add_column("Propietario", style="magenta", justify="right", width=12)

        for cal in shared_calendars:
            status_color = "green" if cal['membership_status'] == 'accepted' else "yellow"
            table_shared.add_row(
                str(cal['id']),
                cal['name'][:18] + "..." if len(cal['name']) > 18 else cal['name'],
                cal['membership_role'],
                f"[{status_color}]{cal['membership_status']}[/{status_color}]",
                f"Usuario #{cal['user_id']}"
            )

        console.print(table_shared)
        console.print(f"\n[cyan]{len(shared_calendars)} calendario(s) compartido(s)[/cyan]\n")

        # Mostrar opciones para gestionar invitaciones pendientes
        pending_memberships = [cal for cal in shared_calendars if cal['membership_status'] == 'pending']

        if pending_memberships:
            console.print(f"[magenta]Tienes {len(pending_memberships)} invitación(es) pendiente(s) a calendarios[/magenta]\n")

            gestionar = questionary.confirm(
                "¿Deseas aceptar o rechazar alguna invitación a calendario?",
                default=False
            ).ask()

            if gestionar:
                gestionar_invitaciones_calendarios(pending_memberships)
                return  # Volver a mostrar después de gestionar

    pause()


def gestionar_invitaciones_calendarios(pending_calendars):
    """Permite aceptar o rechazar invitaciones a calendarios"""
    clear_screen()
    show_header()

    console.print("[bold cyan]📨 Gestionar Invitaciones a Calendarios[/bold cyan]\n")

    # Crear opciones para seleccionar
    cal_choices = []
    for cal in pending_calendars:
        cal_choices.append(f"ID {cal['id']} - {cal['name']}")

    cal_choices.append("⬅️  Cancelar")

    cal_choice = questionary.select(
        "Selecciona la invitación a gestionar:",
        choices=cal_choices,
        style=custom_style
    ).ask()

    if cal_choice == "⬅️  Cancelar":
        return

    # Extraer ID del calendario seleccionado
    cal_id = int(cal_choice.split(" - ")[0].split()[1])
    selected_cal = next((cal for cal in pending_calendars if cal['id'] == cal_id), None)

    if not selected_cal:
        console.print("[red]Error: calendario no encontrado[/red]")
        pause()
        return

    # Preguntar acción
    action = questionary.select(
        f"¿Qué deseas hacer con la invitación a '{selected_cal['name']}'?",
        choices=[
            "✅ Aceptar invitación",
            "❌ Rechazar invitación",
            "⬅️  Cancelar"
        ],
        style=custom_style
    ).ask()

    if action == "⬅️  Cancelar":
        return

    new_status = "accepted" if action == "✅ Aceptar invitación" else "rejected"

    console.print(f"\n[cyan]Actualizando invitación...[/cyan]\n")

    # Actualizar el estado de la membresía
    update_data = {
        "status": new_status,
        "role": selected_cal['membership_role']  # Mantener el rol actual
    }

    response = requests.put(f"{API_BASE_URL}/calendar_memberships/{selected_cal['membership_id']}", json=update_data)

    if response.status_code in [200, 204]:
        status_text = "aceptada" if new_status == "accepted" else "rechazada"
        console.print(f"[bold green]✅ Invitación {status_text} exitosamente[/bold green]\n")
    else:
        handle_api_error(response)

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
