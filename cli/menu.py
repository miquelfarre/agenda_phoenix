#!/usr/bin/env python3
"""
Agenda Phoenix - Interfaz interactiva con menús
Soporta dos modos: Usuario (simulación) y Backoffice (administración)

IMPORTANTE: Este CLI es un cliente de la API, no implementa lógica de negocio.
Ver DEVELOPMENT_RULES.md para las reglas de desarrollo.
"""
import questionary
import api_client
from rich.table import Table
from rich.panel import Panel
from ui.console import console, custom_style, clear_screen
from ui.tables import (
    truncate_text,
    format_count_message,
    create_events_table,
    create_conflicts_table,
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
)
from ui.header import show_header

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


# ==================== MENÚ DE EVENTOS (ADAPTADO) ====================


def menu_eventos():
    """Menú de gestión de eventos (adaptado según el modo)"""
    while True:
        clear_screen()
        _show_header_wrapper()

        if modo_actual == MODO_USUARIO:
            choices = [
                "📋 Ver MIS eventos",
                "🔍 Ver detalles de un evento",
                "➕ Crear nuevo evento",
                "📨 Ver MIS invitaciones pendientes",
                "🔔 Suscribirme a usuario público",
                "⬅️  Volver al menú principal",
            ]
        else:  # MODO_BACKOFFICE
            choices = [
                "📋 Ver eventos de un usuario",
                "🔍 Ver detalles de un evento",
                "➕ Crear nuevo evento",
                "🗑️  Eliminar un evento",
                "⬅️  Volver al menú principal",
            ]

        choice = questionary.select(
            "📅 Gestión de Eventos - ¿Qué deseas hacer?",
            choices=choices,
            style=custom_style,
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
    """Muestra los eventos del usuario actual (Modo Usuario) con filtros"""
    clear_screen()
    _show_header_wrapper()

    # Ofrecer opciones de filtrado
    filter_choice = questionary.select("¿Cómo deseas ver tus eventos?", choices=["📅 Todos los eventos", "📆 Próximos 7 días", "📊 Este mes", "🔍 Buscar por nombre", "⬅️  Cancelar"], style=custom_style).ask()

    if filter_choice == "⬅️  Cancelar":
        return

    console.print(f"\n[cyan]Consultando tus eventos...[/cyan]\n")

    # Usar filtros predefinidos del backend
    params = {}

    if filter_choice == "📆 Próximos 7 días":
        params["filter"] = "next_7_days"
        title = "📆 Mis Eventos - Próximos 7 Días"
    elif filter_choice == "📊 Este mes":
        params["filter"] = "this_month"
        title = "📊 Mis Eventos - Este Mes"
    elif filter_choice == "🔍 Buscar por nombre":
        search_term = questionary.text("Ingresa el nombre o parte del nombre del evento:", validate=lambda text: len(text) > 0 or "Debe ingresar al menos un carácter").ask()

        if not search_term:
            return

        params["search"] = search_term
        title = f"🔍 Búsqueda: '{search_term}'"
    else:
        title = "📅 Mis Eventos"

    # Llamar a la API con los parámetros
    response = api_client.get(url_user_events(usuario_actual), params=params)
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
    _show_header_wrapper()

    console.print(f"[cyan]Consultando tus invitaciones pendientes...[/cyan]\n")

    # Obtener invitaciones pendientes CON datos de eventos (enriched)
    params = {"user_id": usuario_actual, "interaction_type": "invited", "status": "pending", "enriched": "true"}
    response = api_client.get(url_interactions(), params=params)
    invitations = handle_api_error(response)

    if not invitations:
        console.print("[yellow]No tienes invitaciones pendientes[/yellow]\n")
        pause()
        return

    # Mostrar tabla de invitaciones (datos ya vienen enriquecidos)
    table = Table(title="📨 Invitaciones Pendientes", show_header=True, header_style="bold magenta")
    table.add_column("ID Inv", style="cyan", justify="right", width=7)
    table.add_column("Evento", style="green", width=30)
    table.add_column("Fecha", style="yellow", width=18)
    table.add_column("Tipo", style="blue", width=10)

    for inv in invitations:
        table.add_row(str(inv["id"]), truncate_text(inv["event_name"], 28), inv.get("event_start_date_formatted", inv.get("event_start_date", "-")), inv["event_type"])

    console.print(table)
    console.print(f"\n[cyan]Total: {format_count_message(len(invitations), 'invitación pendiente', 'invitaciones pendientes')}[/cyan]\n")

    # Preguntar si desea gestionar alguna invitación
    gestionar = questionary.confirm("¿Deseas aceptar o rechazar alguna invitación?", default=False).ask()

    if not gestionar:
        return

    # Seleccionar invitación a gestionar
    inv_choices = []
    for inv in invitations:
        inv_choices.append(f"ID {inv['id']} - {inv['event_name'][:40]}")

    inv_choices.append("⬅️  Cancelar")

    inv_choice = questionary.select("Selecciona la invitación a gestionar:", choices=inv_choices, style=custom_style).ask()

    if inv_choice == "⬅️  Cancelar":
        return

    inv_id = int(inv_choice.split(" - ")[0].split()[1])

    # Obtener la invitación del backend (en lugar de buscar en array local)
    inv_response = api_client.get(url_interaction(inv_id))
    selected_inv = handle_api_error(inv_response)

    if not selected_inv:
        console.print("[red]Error: invitación no encontrada[/red]")
        pause()
        return

    # Obtener datos del evento para verificar conflictos
    event_response = api_client.get(url_event(selected_inv["event_id"]))
    event_data = handle_api_error(event_response)

    if not event_data:
        console.print("[red]Error: no se pudo obtener información del evento[/red]")
        pause()
        return

    # Preguntar acción
    action = questionary.select("¿Qué deseas hacer con esta invitación?", choices=["✅ Aceptar invitación", "❌ Rechazar invitación", "⬅️  Cancelar"], style=custom_style).ask()

    if action == "⬅️  Cancelar":
        return

    new_status = "accepted" if action == "✅ Aceptar invitación" else "rejected"

    console.print(f"\n[cyan]Actualizando invitación...[/cyan]\n")

    # Actualizar el estado de la invitación
    update_data = {"status": new_status}

    response = api_client.patch(url_interaction(inv_id), json=update_data)

    # Manejo de conflictos desde el backend (409)
    if response.status_code == 409:
        try:
            detail = response.json().get("detail")
        except Exception:
            detail = None
        conflicts = []
        if isinstance(detail, dict):
            conflicts = detail.get("conflicts") or []

        if conflicts:
            console.print(f"[bold yellow]⚠️  Conflictos detectados por el backend[/bold yellow]\n")
            conflict_table = create_conflicts_table(conflicts)
            console.print(conflict_table)
            console.print()

        continuar = questionary.confirm("Se han detectado conflictos. ¿Aceptar de todos modos?", default=False).ask()

        if not continuar:
            pause()
            return

        # Reintentar con force=true
        response = api_client.patch(url_interaction(inv_id) + "?force=true", json=update_data)

    if response.status_code in [200, 204]:
        status_text = "aceptada" if new_status == "accepted" else "rechazada"
        console.print(f"[bold green]✅ Invitación {status_text} exitosamente[/bold green]\n")
    else:
        handle_api_error(response)

    pause()


def suscribirse_a_usuario_publico():
    """Permite suscribirse a un usuario público usando endpoint bulk"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]🔔 Suscripción a Usuario Público[/bold cyan]\n")

    # Obtener usuarios públicos (YA FILTRADOS por el backend)
    response = api_client.get(url_users(), params={"public": "true"})
    public_users = handle_api_error(response)

    if not public_users:
        console.print("[yellow]No hay usuarios públicos disponibles[/yellow]\n")
        pause()
        return

    user_choices = [f"{u['id']} - {u['username']}" for u in public_users]
    user_choices.append("⬅️  Cancelar")

    user_choice = questionary.select("Selecciona un usuario público para suscribirte:", choices=user_choices, style=custom_style).ask()

    if user_choice == "⬅️  Cancelar":
        return

    public_user_id = int(user_choice.split(" - ")[0])

    console.print(f"\n[cyan]Suscribiéndote a eventos del usuario...[/cyan]\n")

    # Llamar al endpoint bulk de suscripción
    response = api_client.post(url_user_subscribe(usuario_actual, public_user_id))
    result = handle_api_error(response)

    if result:
        console.print(f"[bold green]✅ {result['message']}[/bold green]")
        if result.get("already_subscribed_count", 0) > 0:
            console.print(f"[yellow]ℹ️  Ya estabas suscrito a {result['already_subscribed_count']} eventos[/yellow]")
        if result.get("error_count", 0) > 0:
            console.print(f"[red]⚠️  {result['error_count']} errores durante la suscripción[/red]")

    console.print()
    pause()


def listar_eventos_usuario():
    """Lista eventos de un usuario (Modo Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    # Mostrar usuarios para seleccionar (enriquecidos desde el backend)
    users_response = api_client.get(url_users(), params={"enriched": "true"})
    users = handle_api_error(users_response)

    if not users:
        console.print("[red]Error al obtener usuarios[/red]")
        pause()
        return

    # Crear opciones de usuarios (solo formateo)
    user_choices = [f"{user['id']} - {user['display_name']}" for user in users]
    user_choices.append("⬅️  Cancelar")

    user_choice = questionary.select("Selecciona un usuario:", choices=user_choices, style=custom_style).ask()

    if user_choice == "⬅️  Cancelar":
        return

    user_id = int(user_choice.split(" - ")[0].split()[0])

    console.print(f"\n[cyan]Consultando eventos del usuario #{user_id}...[/cyan]\n")

    response = api_client.get(url_user_events(user_id))
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
    _show_header_wrapper()

    event_id = questionary.text("Ingresa el ID del evento:", validate=lambda text: text.isdigit() or "Debe ser un número").ask()

    if not event_id:
        return

    console.print(f"\n[cyan]Consultando evento #{event_id}...[/cyan]\n")

    # Pass current_user_id to get ownership info from backend
    params = {}
    if modo_actual == MODO_USUARIO and usuario_actual:
        params["current_user_id"] = usuario_actual

    response = api_client.get(url_event(event_id), params=params)
    event = handle_api_error(response)

    if not event:
        pause()
        return

    info = f"[yellow]ID:[/yellow] {event['id']}\n"
    info += f"[yellow]Nombre:[/yellow] {event['name']}\n"
    info += f"[yellow]Descripción:[/yellow] {event.get('description', '-')}\n"
    info += f"[yellow]Fecha Inicio:[/yellow] {event.get('start_date_formatted', event.get('start_date', '-'))}\n"

    if event.get("end_date"):
        info += f"[yellow]Fecha Fin:[/yellow] {event.get('end_date_formatted', event.get('end_date', '-'))}\n"

    info += f"[yellow]Tipo:[/yellow] {event['event_type']}\n"

    # Backend provides owner_display field
    if modo_actual == MODO_USUARIO:
        owner_display = event.get("owner_display", f"Usuario #{event['owner_id']}")
        info += f"[yellow]Propietario:[/yellow] {owner_display}\n"
    else:
        info += f"[yellow]Owner ID:[/yellow] {event['owner_id']}\n"

    if event.get("calendar_id"):
        info += f"[yellow]Calendario ID:[/yellow] {event['calendar_id']}\n"

    if event.get("parent_recurring_event_id"):
        info += f"[yellow]Evento Recurrente Padre:[/yellow] {event['parent_recurring_event_id']}\n"

    console.print(Panel(info, title=f"[bold cyan]Evento #{event['id']}[/bold cyan]", border_style="cyan"))
    console.print()

    # Obtener invitaciones del evento (CON datos de usuarios incluidos)
    console.print(f"[cyan]Consultando invitaciones del evento...[/cyan]\n")
    interactions_response = api_client.get(url_event_interactions_enriched(event_id))
    interactions = handle_api_error(interactions_response)

    if interactions:
        # Mostrar tabla de invitaciones (datos ya vienen enriquecidos del backend)
        table = Table(title="📨 Invitaciones del Evento", show_header=True, header_style="bold magenta")
        table.add_column("ID", style="cyan", justify="right", width=5)
        table.add_column("Usuario", style="green", width=25)
        table.add_column("Tipo", style="blue", width=12)
        table.add_column("Estado", style="yellow", width=12)
        table.add_column("Rol", style="magenta", width=10)

        for interaction in interactions:
            # Colorear estado
            status = interaction.get("status", "-")
            if status == "accepted":
                status = f"[green]{status}[/green]"
            elif status == "rejected":
                status = f"[red]{status}[/red]"
            elif status == "pending":
                status = f"[yellow]{status}[/yellow]"

            table.add_row(str(interaction["id"]), interaction["user_name"], interaction["interaction_type"], status, interaction.get("role", "-") or "-")  # Ya viene del backend

        console.print(table)
        console.print(f"\n[cyan]Total: {format_count_message(len(interactions), 'invitación', 'invitaciones')}[/cyan]\n")
    else:
        console.print("[dim]No hay invitaciones para este evento[/dim]\n")

    # Si es modo usuario y es propio, ofrecer opciones
    if modo_actual == MODO_USUARIO and event.get("is_owner", False):
        gestionar = questionary.confirm("¿Deseas invitar a un usuario a este evento?", default=False).ask()

        if gestionar:
            invitar_a_evento(event_id)
            return  # Volver a mostrar el evento después

    pause()


def invitar_a_evento(event_id):
    """Permite invitar a un usuario a un evento"""
    clear_screen()
    _show_header_wrapper()

    console.print(f"[bold cyan]📨 Invitar Usuario al Evento #{event_id}[/bold cyan]\n")

    # Obtener el evento para mostrar información
    event_response = api_client.get(url_event(event_id))
    event = handle_api_error(event_response)

    if not event:
        pause()
        return

    console.print(f"[yellow]Evento:[/yellow] {event['name']}\n")

    # Obtener usuarios disponibles (YA FILTRADOS por el backend)
    console.print("[cyan]Cargando usuarios disponibles...[/cyan]\n")
    available_response = api_client.get(url_event_available_invitees(event_id))
    available_users = handle_api_error(available_response)

    if not available_users:
        console.print("[yellow]No hay usuarios disponibles para invitar a este evento[/yellow]")
        console.print("[dim]Todos los usuarios ya han sido invitados o son propietarios del evento[/dim]\n")
        pause()
        return

    # Crear opciones de usuarios (solo formateo para display)
    user_choices = [f"{user['id']} - {user['display_name']}" for user in available_users]
    user_choices.append("⬅️  Cancelar")

    user_choice = questionary.select("Selecciona el usuario a invitar:", choices=user_choices, style=custom_style).ask()

    if user_choice == "⬅️  Cancelar":
        return

    # Parsear ID directamente del string seleccionado
    invited_user_id = int(user_choice.split(" - ")[0])

    # Preguntar por el rol (opcional)
    role_choice = questionary.select("¿Qué rol tendrá el usuario invitado?", choices=["Participante (sin rol especial)", "Admin", "⬅️  Cancelar"], style=custom_style).ask()

    if role_choice == "⬅️  Cancelar":
        return

    role = None
    if role_choice == "Admin":
        role = "admin"

    console.print(f"\n[cyan]Creando invitación...[/cyan]\n")

    # Crear la invitación
    invitation_data = {"event_id": int(event_id), "user_id": invited_user_id, "interaction_type": "invited", "status": "pending", "role": role, "invited_by_user_id": usuario_actual}

    response = api_client.post(url_interactions(), json=invitation_data)
    invitation = handle_api_error(response)

    if invitation:
        user_display = user_choice.split(" - ")[1] if " - " in user_choice else f"Usuario #{invited_user_id}"
        console.print(f"[bold green]✅ Invitación enviada exitosamente a {user_display}[/bold green]\n")
    else:
        console.print("[red]No se pudo crear la invitación[/red]\n")

    pause()


def crear_evento():
    """Crea un nuevo evento"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]➕ Crear Nuevo Evento[/bold cyan]\n")

    name = questionary.text("Nombre del evento:", validate=lambda text: len(text) > 0 or "No puede estar vacío").ask()

    if not name:
        return

    # En modo usuario, el owner es el usuario actual
    if modo_actual == MODO_USUARIO:
        owner_id = usuario_actual
        console.print(f"[dim]El evento será creado como tuyo (Usuario #{owner_id})[/dim]\n")
    else:
        # En modo backoffice, seleccionar owner
        users_response = api_client.get(url_users(), params={"enriched": "true"})
        if users_response.status_code != 200:
            console.print("[red]Error al obtener usuarios[/red]")
            pause()
            return

        users = users_response.json()
        user_choices = [f"{u['id']} - {u['display_name']}" for u in users]

        owner_choice = questionary.select("Selecciona el propietario del evento:", choices=user_choices).ask()

        owner_id = int(owner_choice.split(" - ")[0])

    start_date = questionary.text("Fecha y hora de inicio (YYYY-MM-DD HH:MM):", validate=lambda text: len(text) > 0 or "No puede estar vacío").ask()

    if not start_date:
        return

    try:
        parsed_start = date_parser.parse(start_date)
    except:
        console.print("[red]Formato de fecha inválido[/red]")
        pause()
        return

    tiene_fin = questionary.confirm("¿Tiene fecha de fin?", default=True).ask()

    end_date = None
    if tiene_fin:
        end_date = questionary.text("Fecha y hora de fin (YYYY-MM-DD HH:MM):").ask()

        if end_date:
            try:
                parsed_end = date_parser.parse(end_date)
                end_date = parsed_end.isoformat()
            except:
                console.print("[red]Formato de fecha inválido, se omitirá fecha de fin[/red]")
                end_date = None

    description = questionary.text("Descripción (opcional):").ask()

    data = {"name": name, "owner_id": owner_id, "start_date": parsed_start.isoformat(), "end_date": end_date, "description": description if description else None, "event_type": "regular"}

    console.print("\n[cyan]Creando evento...[/cyan]\n")
    response = api_client.post(url_events(), json=data)

    # Manejo de conflictos desde el backend (409) con reintento
    if response.status_code == 409:
        try:
            detail = response.json().get("detail")
        except Exception:
            detail = None
        conflicts = []
        if isinstance(detail, dict):
            conflicts = detail.get("conflicts") or []

        if conflicts:
            console.print(f"[bold yellow]⚠️  Conflictos detectados por el backend[/bold yellow]\n")
            conflict_table = create_conflicts_table(conflicts)
            console.print(conflict_table)
            console.print()

        continuar = questionary.confirm("Se han detectado conflictos. ¿Crear de todos modos?", default=False).ask()

        if not continuar:
            pause()
            return

        # Reintentar con force=true
        response = api_client.post(url_events() + "?force=true", json=data)
    event = handle_api_error(response)

    if event:
        console.print(f"[bold green]✅ Evento '{name}' creado exitosamente con ID: {event['id']}[/bold green]\n")

    pause()


def eliminar_evento():
    """Elimina un evento (solo Modo Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    event_id = questionary.text("Ingresa el ID del evento a eliminar:", validate=lambda text: text.isdigit() or "Debe ser un número").ask()

    if not event_id:
        return

    confirmar = questionary.confirm(f"¿Estás seguro de eliminar el evento #{event_id}?", default=False).ask()

    if not confirmar:
        console.print("[yellow]Operación cancelada[/yellow]")
        pause()
        return

    console.print(f"\n[cyan]Eliminando evento #{event_id}...[/cyan]\n")

    response = api_client.delete(url_event(event_id))

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
        _show_header_wrapper()

        if modo_actual == MODO_USUARIO:
            choices = [
                "📋 Ver MIS calendarios",
                "🔍 Ver detalles de un calendario",
                "📅 Ver eventos de un calendario",
                "➕ Crear nuevo calendario",
                "⬅️  Volver al menú principal",
            ]
        else:  # MODO_BACKOFFICE
            choices = [
                "📋 Ver todos los calendarios",
                "🔍 Ver detalles de un calendario",
                "📅 Ver eventos de un calendario",
                "👥 Ver miembros de un calendario",
                "➕ Crear nuevo calendario",
                "⬅️  Volver al menú principal",
            ]

        choice = questionary.select(
            "📆 Gestión de Calendarios - ¿Qué deseas hacer?",
            choices=choices,
            style=custom_style,
        ).ask()

        if choice == "📋 Ver MIS calendarios":
            ver_mis_calendarios()
        elif choice == "📋 Ver todos los calendarios":
            listar_todos_calendarios()
        elif choice == "🔍 Ver detalles de un calendario":
            ver_calendario()
        elif choice == "📅 Ver eventos de un calendario":
            ver_eventos_calendario()
        elif choice == "👥 Ver miembros de un calendario":
            ver_miembros_calendario()
        elif choice == "➕ Crear nuevo calendario":
            crear_calendario()
        elif choice == "⬅️  Volver al menú principal":
            break


def ver_mis_calendarios():
    """Muestra los calendarios del usuario actual (Modo Usuario) - propios y compartidos"""
    clear_screen()
    _show_header_wrapper()

    console.print(f"[cyan]Consultando tus calendarios...[/cyan]\n")

    # Obtener calendarios del usuario CON datos enriched (incluye calendar_type_display)
    calendars_response = api_client.get(url_calendars(), params={"user_id": usuario_actual, "enriched": "true"})
    my_calendars = handle_api_error(calendars_response)

    if not my_calendars:
        my_calendars = []

    # Obtener calendarios compartidos (memberships CON datos del calendario enriquecidos)
    # Usar exclude_owned para filtrar calendarios donde NO somos owner (se hace en backend)
    params = {"user_id": usuario_actual, "enriched": "true", "exclude_owned": "true"}
    memberships_response = api_client.get(url_calendar_memberships(), params=params)
    shared_calendars = handle_api_error(memberships_response) or []

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
            table_own.add_row(str(cal["id"]), cal["name"], truncate_text(cal.get("description", "-"), 28), cal["calendar_type_display"])

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
            status_color = "green" if cal["status"] == "accepted" else "yellow"
            table_shared.add_row(str(cal["calendar_id"]), truncate_text(cal["calendar_name"], 18), cal["role"], f"[{status_color}]{cal['status']}[/{status_color}]", f"Usuario #{cal['calendar_user_id']}")

        console.print(table_shared)
        console.print(f"\n[cyan]{len(shared_calendars)} calendario(s) compartido(s)[/cyan]\n")

        # Obtener pending memberships desde el backend (filtrado por status y exclude_owned)
        pending_params = {"user_id": usuario_actual, "status": "pending", "enriched": "true", "exclude_owned": "true"}
        pending_response = api_client.get(url_calendar_memberships(), params=pending_params)
        pending_memberships = handle_api_error(pending_response) or []

        if pending_memberships:
            console.print(f"[magenta]Tienes {len(pending_memberships)} invitación(es) pendiente(s) a calendarios[/magenta]\n")

            gestionar = questionary.confirm("¿Deseas aceptar o rechazar alguna invitación a calendario?", default=False).ask()

            if gestionar:
                gestionar_invitaciones_calendarios(pending_memberships)
                return  # Volver a mostrar después de gestionar

    pause()


def gestionar_invitaciones_calendarios(pending_calendars):
    """Permite aceptar o rechazar invitaciones a calendarios"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]📨 Gestionar Invitaciones a Calendarios[/bold cyan]\n")

    # Crear opciones para seleccionar
    cal_choices = []
    for cal in pending_calendars:
        cal_choices.append(f"ID {cal['id']} - {cal['name']}")

    cal_choices.append("⬅️  Cancelar")

    cal_choice = questionary.select("Selecciona la invitación a gestionar:", choices=cal_choices, style=custom_style).ask()

    if cal_choice == "⬅️  Cancelar":
        return

    # Extraer ID de la membership seleccionada
    membership_id = int(cal_choice.split(" - ")[0].split()[1])

    # Obtener la membership del backend (en lugar de buscar en array local)
    membership_response = api_client.get(url_calendar_membership(membership_id))
    selected_cal = handle_api_error(membership_response)

    if not selected_cal:
        console.print("[red]Error: membership no encontrada[/red]")
        pause()
        return

    # Obtener nombre del calendario para mostrar (si viene enriched tiene calendar_name, sino hay que obtenerlo)
    calendar_name = selected_cal.get("calendar_name")
    if not calendar_name:
        cal_response = api_client.get(url_calendar(selected_cal["calendar_id"]))
        cal_data = handle_api_error(cal_response)
        calendar_name = cal_data["name"] if cal_data else f"Calendario #{selected_cal['calendar_id']}"

    # Preguntar acción
    action = questionary.select(f"¿Qué deseas hacer con la invitación a '{calendar_name}'?", choices=["✅ Aceptar invitación", "❌ Rechazar invitación", "⬅️  Cancelar"], style=custom_style).ask()

    if action == "⬅️  Cancelar":
        return

    new_status = "accepted" if action == "✅ Aceptar invitación" else "rejected"

    console.print(f"\n[cyan]Actualizando invitación...[/cyan]\n")

    # Actualizar el estado de la membresía
    update_data = {"status": new_status, "role": selected_cal["role"]}  # Mantener el rol actual

    response = api_client.put(url_calendar_membership(membership_id), json=update_data)

    if response.status_code in [200, 204]:
        status_text = "aceptada" if new_status == "accepted" else "rechazada"
        console.print(f"[bold green]✅ Invitación {status_text} exitosamente[/bold green]\n")
    else:
        handle_api_error(response)

    pause()


def listar_todos_calendarios():
    """Lista todos los calendarios (Modo Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    console.print("[cyan]Consultando calendarios...[/cyan]\n")

    response = api_client.get(url_calendars())
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
        table.add_row(str(cal["id"]), cal["name"], cal.get("description", "-")[:28] + "..." if cal.get("description") and len(cal.get("description", "")) > 28 else cal.get("description", "-"), str(cal.get("user_id", "-")), "Sí" if cal.get("is_private_birthdays") else "No")

    console.print(table)
    console.print(f"\n[cyan]Total: {len(calendars)} calendarios[/cyan]\n")
    pause()


def ver_calendario():
    """Muestra detalles de un calendario específico"""
    clear_screen()
    _show_header_wrapper()

    calendar_id = questionary.text("Ingresa el ID del calendario:", validate=lambda text: text.isdigit() or "Debe ser un número").ask()

    if not calendar_id:
        return

    console.print(f"\n[cyan]Consultando calendario #{calendar_id}...[/cyan]\n")

    response = api_client.get(url_calendar(calendar_id))
    calendar = handle_api_error(response)

    if not calendar:
        pause()
        return

    info = f"[yellow]ID:[/yellow] {calendar['id']}\n"
    info += f"[yellow]Nombre:[/yellow] {calendar['name']}\n"
    info += f"[yellow]Descripción:[/yellow] {calendar.get('description', '-')}\n"

    # En modo usuario, mostrar si es propio
    if modo_actual == MODO_USUARIO:
        es_propio = calendar.get("user_id") == usuario_actual
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
    _show_header_wrapper()

    calendar_id = questionary.text("Ingresa el ID del calendario:", validate=lambda text: text.isdigit() or "Debe ser un número").ask()

    if not calendar_id:
        return

    console.print(f"\n[cyan]Consultando miembros del calendario #{calendar_id}...[/cyan]\n")

    response = api_client.get(url_calendar_memberships_nested(calendar_id))
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
        table.add_row(str(member["user_id"]), member["role"], member["status"], str(member.get("invited_by_user_id", "-")))

    console.print(table)
    console.print(f"\n[cyan]Total: {len(memberships)} miembros[/cyan]\n")
    pause()


def crear_calendario():
    """Crea un nuevo calendario"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]➕ Crear Nuevo Calendario[/bold cyan]\n")

    name = questionary.text("Nombre del calendario:", validate=lambda text: len(text) > 0 or "No puede estar vacío").ask()

    if not name:
        return

    # En modo usuario, el owner es el usuario actual
    if modo_actual == MODO_USUARIO:
        owner_id = usuario_actual
        console.print(f"[dim]El calendario será creado como tuyo (Usuario #{owner_id})[/dim]\n")
    else:
        # En modo backoffice, seleccionar owner
        users_response = api_client.get(url_users(), params={"enriched": "true"})
        if users_response.status_code != 200:
            console.print("[red]Error al obtener usuarios[/red]")
            pause()
            return

        users = users_response.json()
        user_choices = [f"{u['id']} - {u['display_name']}" for u in users]

        owner_choice = questionary.select("Selecciona el propietario del calendario:", choices=user_choices).ask()

        owner_id = int(owner_choice.split(" - ")[0])

    description = questionary.text("Descripción (opcional):").ask()

    is_birthdays = questionary.confirm("¿Es un calendario de cumpleaños?", default=False).ask()

    data = {"name": name, "user_id": owner_id, "description": description if description else None, "is_private_birthdays": is_birthdays}

    console.print("\n[cyan]Creando calendario...[/cyan]\n")
    response = api_client.post(url_calendars(), json=data)
    calendar = handle_api_error(response)

    if calendar:
        console.print(f"[bold green]✅ Calendario '{name}' creado exitosamente con ID: {calendar['id']}[/bold green]\n")

    pause()


def ver_eventos_calendario():
    """Muestra los eventos de un calendario específico"""
    clear_screen()
    _show_header_wrapper()

    calendar_id = questionary.text("Ingresa el ID del calendario:", validate=lambda text: text.isdigit() or "Debe ser un número").ask()

    if not calendar_id:
        return

    console.print(f"\n[cyan]Consultando calendario #{calendar_id}...[/cyan]\n")

    # Verificar que el calendario existe
    calendar_response = api_client.get(url_calendar(calendar_id))
    calendar = handle_api_error(calendar_response)

    if not calendar:
        pause()
        return

    # Mostrar información del calendario
    console.print(f"[bold cyan]Calendario:[/bold cyan] {calendar['name']}")
    if calendar.get("description"):
        console.print(f"[dim]{calendar['description']}[/dim]")
    console.print()

    console.print(f"[cyan]Consultando eventos del calendario...[/cyan]\n")

    # Obtener eventos filtrados por calendar_id (filtrado en el backend)
    params = {"calendar_id": calendar_id}
    if modo_actual == MODO_USUARIO and usuario_actual:
        params["current_user_id"] = usuario_actual

    events_response = api_client.get(url_events(), params=params)
    calendar_events = handle_api_error(events_response)

    if not calendar_events:
        console.print(f"[yellow]Este calendario no tiene eventos asociados[/yellow]\n")
        pause()
        return

    # Usar función de utilidad para crear la tabla
    title = f"📅 Eventos del Calendario: {calendar['name']}"

    # Si estamos en modo usuario, pasar el usuario actual
    current_user = usuario_actual if modo_actual == MODO_USUARIO else None

    table = create_events_table(calendar_events, title=title, current_user_id=current_user, max_rows=30)
    console.print(table)

    show_pagination_info(min(30, len(calendar_events)), len(calendar_events))

    console.print(f"\n[cyan]Total: {format_count_message(len(calendar_events), 'evento', 'eventos')} en este calendario[/cyan]\n")
    pause()


# ==================== MENÚ DE CONTACTOS Y USUARIOS (SOLO BACKOFFICE) ====================


def menu_usuarios_backoffice():
    """Menú de gestión de usuarios (solo Backoffice)"""
    while True:
        clear_screen()
        _show_header_wrapper()

        choice = questionary.select(
            "👥 Gestión de Usuarios - ¿Qué deseas hacer?",
            choices=[
                "📋 Ver todos los usuarios",
                "🔍 Ver detalles de un usuario",
                "➕ Crear nuevo usuario",
                "⬅️  Volver al menú principal",
            ],
            style=custom_style,
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
    _show_header_wrapper()

    console.print("[cyan]Consultando usuarios...[/cyan]\n")

    # Obtener users enriched desde el backend (con contact info)
    response = api_client.get(url_users(), params={"enriched": "true"})
    users = handle_api_error(response)

    if not users:
        pause()
        return

    table = Table(title="👥 Usuarios Registrados", show_header=True, header_style="bold magenta")
    table.add_column("ID", style="cyan", justify="right", width=5)
    table.add_column("Username", style="yellow", width=15)
    table.add_column("Nombre (Contacto)", style="green", width=20)
    table.add_column("Teléfono", style="blue", width=15)
    table.add_column("Auth Provider", style="magenta", width=15)

    for user in users:
        table.add_row(str(user["id"]), user.get("username", "-"), user.get("contact_name", "-"), user.get("contact_phone", "-"), user.get("auth_provider", "-"))

    console.print(table)
    console.print(f"\n[cyan]Total: {len(users)} usuarios[/cyan]\n")
    pause()


def ver_usuario_backoffice():
    """Muestra detalles de un usuario (Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    user_id = questionary.text("Ingresa el ID del usuario:", validate=lambda text: text.isdigit() or "Debe ser un número").ask()

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
    info += f"[yellow]Teléfono (Contacto):[/yellow] {user.get('contact_phone', '-')}\n"
    info += f"[yellow]Profile Picture:[/yellow] {user.get('profile_picture_url', '-')}\n"
    info += f"[yellow]Creado:[/yellow] {user.get('created_at', '-')}"

    console.print(Panel(info, title=f"[bold cyan]Usuario #{user['id']}[/bold cyan]", border_style="cyan"))
    console.print()
    pause()


def crear_usuario_backoffice():
    """Crea un nuevo usuario (Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]➕ Crear Nuevo Usuario[/bold cyan]\n")

    # Implementación simplificada
    console.print("[yellow]Funcionalidad de creación de usuarios (ver menu.py original)[/yellow]\n")
    pause()


def menu_contactos_backoffice():
    """Menú de gestión de contactos (solo Backoffice)"""
    while True:
        clear_screen()
        _show_header_wrapper()

        choice = questionary.select(
            "📞 Gestión de Contactos - ¿Qué deseas hacer?",
            choices=[
                "📋 Ver todos los contactos",
                "🔍 Ver detalles de un contacto",
                "➕ Crear nuevo contacto",
                "⬅️  Volver al menú principal",
            ],
            style=custom_style,
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
    _show_header_wrapper()

    console.print("[cyan]Consultando contactos...[/cyan]\n")

    response = api_client.get(url_contacts())
    contacts = handle_api_error(response)

    if not contacts:
        pause()
        return


def ver_contacto_backoffice():
    """Muestra detalles de un contacto (Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    contact_id = questionary.text(
        "Ingresa el ID del contacto:",
        validate=lambda text: text.isdigit() or "Debe ser un número",
    ).ask()

    if not contact_id:
        return

    console.print(f"\n[cyan]Consultando contacto #{contact_id}...[/cyan]\n")

    response = api_client.get(url_contact(contact_id))
    contact = handle_api_error(response)

    if not contact:
        pause()
        return

    info = f"[yellow]ID:[/yellow] {contact['id']}\n"
    info += f"[yellow]Nombre:[/yellow] {contact['name']}\n"
    info += f"[yellow]Teléfono:[/yellow] {contact.get('phone', '-')}\n"
    info += f"[yellow]Creado:[/yellow] {contact.get('created_at', '-') }"

    console.print(Panel(info, title=f"[bold cyan]Contacto #{contact['id']}[/bold cyan]", border_style="cyan"))
    console.print()
    pause()


def crear_contacto_backoffice():
    """Crea un nuevo contacto (Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]➕ Crear Nuevo Contacto[/bold cyan]\n")

    name = questionary.text("Nombre del contacto:", validate=lambda text: len(text) > 0 or "No puede estar vacío").ask()

    if not name:
        return

    phone = questionary.text("Teléfono (formato: +34XXXXXXXXX):", validate=lambda text: len(text) > 0 or "No puede estar vacío").ask()

    if not phone:
        return

    data = {"name": name, "phone": phone}

    console.print("\n[cyan]Creando contacto...[/cyan]\n")
    response = api_client.post(url_contacts(), json=data)
    contact = handle_api_error(response)

    if contact:
        console.print(f"[bold green]✅ Contacto '{name}' creado exitosamente con ID: {contact['id']}[/bold green]\n")

    pause()


# ==================== MENÚ PRINCIPAL ====================


def menu_principal():
    """Menú principal de la aplicación (adaptado según el modo)"""
    while True:
        clear_screen()
        _show_header_wrapper()

        if modo_actual == MODO_USUARIO:
            choices = ["📅 MIS Eventos", "📆 MIS Calendarios", "👤 Cambiar Usuario", "❌ Salir"]
        else:  # MODO_BACKOFFICE
            choices = ["👥 Gestionar Usuarios", "📞 Gestionar Contactos", "📅 Gestionar Eventos", "📆 Gestionar Calendarios", "🔄 Cambiar Modo", "❌ Salir"]

        choice = questionary.select("¿Qué deseas hacer?", choices=choices, style=custom_style).ask()

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
