# -*- coding: utf-8 -*-
"""
Menu de gestion de eventos
Este es el modulo mas grande e incluye toda la funcionalidad de gestion de eventos:
creacion, edicion, visualizacion, invitaciones, suscripciones, recurrencia, etc.

Nota: Debido al tamano de este modulo, contiene 12 funciones principales.
Se recomienda leerlo por secciones.
"""
import questionary
import api_client
from datetime import datetime, timedelta
from rich.panel import Panel
from rich.table import Table
from dateutil import parser as date_parser

from ui.console import console, custom_style, clear_screen
from ui.tables import (
    truncate_text,
    format_count_message,
    create_events_table,
    create_conflicts_table,
    show_pagination_info,
)
from config import (
    API_BASE_URL,
    url_users,
    url_user_events,
    url_user_subscribe,
    url_events,
    url_event,
    url_event_interactions_enriched,
    url_event_available_invitees,
    url_interactions,
    url_interaction,
    url_recurring_configs,
)


# ==================== MENU PRINCIPAL DE EVENTOS ====================


def menu_eventos(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO, MODO_BACKOFFICE):
    """Menu de gestion de eventos (adaptado segun el modo)"""
    # Import nested functions
    def ver_mis_invitaciones_wrapper():
        ver_mis_invitaciones(_show_header_wrapper, handle_api_error, pause, usuario_actual)

    def ver_mis_eventos_wrapper():
        ver_mis_eventos(_show_header_wrapper, handle_api_error, pause, usuario_actual)

    def listar_eventos_usuario_wrapper():
        listar_eventos_usuario(_show_header_wrapper, handle_api_error, pause)

    def ver_evento_wrapper():
        ver_evento(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO)

    def crear_evento_wrapper():
        crear_evento(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO)

    def editar_evento_wrapper():
        editar_evento(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO)

    def invitar_usuario_a_evento_menu_wrapper():
        invitar_usuario_a_evento_menu(_show_header_wrapper, handle_api_error, pause, usuario_actual)

    def suscribirse_a_usuario_publico_wrapper():
        suscribirse_a_usuario_publico(_show_header_wrapper, handle_api_error, pause, usuario_actual)

    def eliminar_evento_wrapper():
        eliminar_evento(_show_header_wrapper, handle_api_error, pause)

    while True:
        clear_screen()
        _show_header_wrapper()

        if modo_actual == MODO_USUARIO:
            choices = [
                "Ver MIS invitaciones pendientes",
                "Ver MIS eventos",
                "Ver detalles de un evento",
                "Crear nuevo evento",
                "Editar evento",
                "Invitar usuario a un evento",
                "Suscribirme a usuario publico",
                "Volver al menu principal",
            ]
        else:  # MODO_BACKOFFICE
            choices = [
                "Ver eventos de un usuario",
                "Ver detalles de un evento",
                "Crear nuevo evento",
                "Editar evento",
                "Eliminar un evento",
                "Volver al menu principal",
            ]

        choice = questionary.select(
            "Gestion de Eventos - Que deseas hacer?",
            choices=choices,
            style=custom_style,
        ).ask()

        if choice == "Ver MIS invitaciones pendientes":
            ver_mis_invitaciones_wrapper()
        elif choice == "Ver MIS eventos":
            ver_mis_eventos_wrapper()
        elif choice == "Ver eventos de un usuario":
            listar_eventos_usuario_wrapper()
        elif choice == "Ver detalles de un evento":
            ver_evento_wrapper()
        elif choice == "Crear nuevo evento":
            crear_evento_wrapper()
        elif choice == "Editar evento":
            editar_evento_wrapper()
        elif choice == "Invitar usuario a un evento":
            invitar_usuario_a_evento_menu_wrapper()
        elif choice == "Suscribirme a usuario publico":
            suscribirse_a_usuario_publico_wrapper()
        elif choice == "Eliminar un evento":
            eliminar_evento_wrapper()
        elif choice == "Volver al menu principal":
            break


# ==================== FUNCIONES DE VISUALIZACION ====================


def ver_mis_eventos(_show_header_wrapper, handle_api_error, pause, usuario_actual):
    """Muestra los eventos del usuario actual (Modo Usuario) con filtros"""
    clear_screen()
    _show_header_wrapper()

    # Ofrecer opciones de filtrado
    filter_choice = questionary.select(
        "Como deseas ver tus eventos?",
        choices=[
            "Todos los eventos",
            "Hoy",
            "Esta semana (proximos 7 dias)",
            "Este mes",
            "Buscar por nombre",
            "Cancelar"
        ],
        style=custom_style
    ).ask()

    if filter_choice == "Cancelar":
        return

    # Usar filtros predefinidos del backend
    params = {}
    enable_pagination = False

    if filter_choice == "Hoy":
        params["filter"] = "today"
        title = "Mis Eventos - Hoy"
    elif filter_choice == "Esta semana (proximos 7 dias)":
        params["filter"] = "next_7_days"
        title = "Mis Eventos - Proximos 7 Dias"
    elif filter_choice == "Este mes":
        params["filter"] = "this_month"
        title = "Mis Eventos - Este Mes"
    elif filter_choice == "Buscar por nombre":
        search_term = questionary.text("Ingresa el nombre o parte del nombre del evento:", validate=lambda text: len(text) > 0 or "Debe ingresar al menos un caracter").ask()

        if not search_term:
            return

        params["search"] = search_term
        title = f"Busqueda: '{search_term}'"
    else:
        # "Todos los eventos" - habilitar paginacion
        title = "Mis Eventos"
        enable_pagination = True

    # Variables para paginacion
    offset = 0
    limit = 30
    all_events = []

    while True:
        clear_screen()
        _show_header_wrapper()
        console.print(f"\n[cyan]Consultando tus eventos...[/cyan]\n")

        # Anadir parametros de paginacion si esta habilitada
        if enable_pagination:
            params["limit"] = limit
            params["offset"] = offset

        # Llamar a la API con los parametros
        response = api_client.get(url_user_events(usuario_actual), params=params)
        events = handle_api_error(response)

        if not events:
            if offset == 0:
                console.print(f"[yellow]No se encontraron eventos[/yellow]\n")
                pause()
                return
            else:
                console.print(f"[yellow]No hay mas eventos para mostrar[/yellow]\n")
                pause()
                break

        # Si no hay paginacion, mostrar todo y terminar
        if not enable_pagination:
            table = create_events_table(events, title=title, current_user_id=usuario_actual, max_rows=50)
            console.print(table)
            show_pagination_info(min(50, len(events)), len(events))
            console.print(f"\n[cyan]Total: {format_count_message(len(events), 'evento', 'eventos')}[/cyan]")
            console.print("[dim]Incluye tus eventos propios, invitaciones aceptadas y suscripciones[/dim]\n")
            pause()
            break

        # Con paginacion: acumular eventos y mostrar
        all_events.extend(events)

        page_title = f"{title} (mostrando {len(all_events)} eventos)"
        table = create_events_table(all_events, title=page_title, current_user_id=usuario_actual, max_rows=len(all_events))
        console.print(table)

        # Mostrar info de paginacion
        console.print(f"\n[cyan]Mostrando {len(all_events)} eventos[/cyan]")
        console.print("[dim]Incluye tus eventos propios, invitaciones aceptadas y suscripciones[/dim]\n")

        # Si obtuvimos menos eventos que el limite, no hay mas paginas
        if len(events) < limit:
            console.print("[dim]No hay mas eventos para mostrar[/dim]\n")
            pause()
            break

        # Preguntar si quiere ver mas
        ver_mas = questionary.confirm(
            f"Hay mas eventos disponibles. Deseas cargar los siguientes {limit}?",
            default=True
        ).ask()

        if not ver_mas:
            break

        # Avanzar a la siguiente pagina
        offset += limit


def ver_mis_invitaciones(_show_header_wrapper, handle_api_error, pause, usuario_actual):
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
    table = Table(title="Invitaciones Pendientes", show_header=True, header_style="bold magenta")
    table.add_column("ID Inv", style="cyan", justify="right", width=7)
    table.add_column("Evento", style="green", width=30)
    table.add_column("Fecha", style="yellow", width=18)
    table.add_column("Tipo", style="blue", width=10)

    for inv in invitations:
        table.add_row(str(inv["id"]), truncate_text(inv["event_name"], 28), inv.get("event_start_date_formatted", inv.get("event_start_date", "-")), inv["event_type"])

    console.print(table)
    console.print(f"\n[cyan]Total: {format_count_message(len(invitations), 'invitacion pendiente', 'invitaciones pendientes')}[/cyan]\n")

    # Preguntar si desea gestionar alguna invitacion
    gestionar = questionary.confirm("Deseas aceptar o rechazar alguna invitacion?", default=False).ask()

    if not gestionar:
        return

    # Seleccionar invitacion a gestionar
    inv_choices = []
    for inv in invitations:
        inv_choices.append(f"ID {inv['id']} - {inv['event_name'][:40]}")

    inv_choices.append("Cancelar")

    inv_choice = questionary.select("Selecciona la invitacion a gestionar:", choices=inv_choices, style=custom_style).ask()

    if inv_choice == "Cancelar":
        return

    inv_id = int(inv_choice.split(" - ")[0].split()[1])

    # Obtener la invitacion del backend (en lugar de buscar en array local)
    inv_response = api_client.get(url_interaction(inv_id))
    selected_inv = handle_api_error(inv_response)

    if not selected_inv:
        console.print("[red]Error: invitacion no encontrada[/red]")
        pause()
        return

    # Obtener datos del evento para verificar conflictos
    event_response = api_client.get(url_event(selected_inv["event_id"]))
    event_data = handle_api_error(event_response)

    if not event_data:
        console.print("[red]Error: no se pudo obtener informacion del evento[/red]")
        pause()
        return

    # Preguntar accion
    action = questionary.select("Que deseas hacer con esta invitacion?", choices=["Aceptar invitacion", "Rechazar invitacion", "Cancelar"], style=custom_style).ask()

    if action == "Cancelar":
        return

    new_status = "accepted" if action == "Aceptar invitacion" else "rejected"

    console.print(f"\n[cyan]Actualizando invitacion...[/cyan]\n")

    # Actualizar el estado de la invitacion
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
            console.print(f"[bold yellow]Conflictos detectados por el backend[/bold yellow]\n")
            conflict_table = create_conflicts_table(conflicts)
            console.print(conflict_table)
            console.print()

        continuar = questionary.confirm("Se han detectado conflictos. Aceptar de todos modos?", default=False).ask()

        if not continuar:
            pause()
            return

        # Reintentar con force=true
        response = api_client.patch(url_interaction(inv_id) + "?force=true", json=update_data)

    if response.status_code in [200, 204]:
        status_text = "aceptada" if new_status == "accepted" else "rechazada"
        console.print(f"[bold green]Invitacion {status_text} exitosamente[/bold green]\n")
    else:
        handle_api_error(response)

    pause()


def suscribirse_a_usuario_publico(_show_header_wrapper, handle_api_error, pause, usuario_actual):
    """Permite suscribirse a un usuario publico usando endpoint bulk"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]Suscripcion a Usuario Publico[/bold cyan]\n")

    # Obtener usuarios publicos (YA FILTRADOS por el backend)
    response = api_client.get(url_users(), params={"public": "true"})
    public_users = handle_api_error(response)

    if not public_users:
        console.print("[yellow]No hay usuarios publicos disponibles[/yellow]\n")
        pause()
        return

    user_choices = [f"{u['id']} - {u['username']}" for u in public_users]
    user_choices.append("Cancelar")

    user_choice = questionary.select("Selecciona un usuario publico para suscribirte:", choices=user_choices, style=custom_style).ask()

    if user_choice == "Cancelar":
        return

    public_user_id = int(user_choice.split(" - ")[0])

    console.print(f"\n[cyan]Suscribiendote a eventos del usuario...[/cyan]\n")

    # Llamar al endpoint bulk de suscripcion
    response = api_client.post(url_user_subscribe(usuario_actual, public_user_id))
    result = handle_api_error(response)

    if result:
        console.print(f"[bold green]{result['message']}[/bold green]")
        if result.get("already_subscribed_count", 0) > 0:
            console.print(f"[yellow]Ya estabas suscrito a {result['already_subscribed_count']} eventos[/yellow]")
        if result.get("error_count", 0) > 0:
            console.print(f"[red]{result['error_count']} errores durante la suscripcion[/red]")

    console.print()
    pause()


def listar_eventos_usuario(_show_header_wrapper, handle_api_error, pause):
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
    user_choices.append("Cancelar")

    user_choice = questionary.select("Selecciona un usuario:", choices=user_choices, style=custom_style).ask()

    if user_choice == "Cancelar":
        return

    user_id = int(user_choice.split(" - ")[0].split()[0])

    console.print(f"\n[cyan]Consultando eventos del usuario #{user_id}...[/cyan]\n")

    response = api_client.get(url_user_events(user_id))
    events = handle_api_error(response)

    if not events:
        console.print("[yellow]Este usuario no tiene eventos[/yellow]\n")
        pause()
        return

    # Usar funcion de utilidad para crear la tabla
    table = create_events_table(events, title=f"Eventos del Usuario #{user_id}", max_rows=20)
    console.print(table)

    show_pagination_info(min(20, len(events)), len(events))

    console.print(f"\n[cyan]Total: {format_count_message(len(events), 'evento', 'eventos')}[/cyan]\n")
    pause()


def ver_evento(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO):
    """Muestra detalles de un evento especifico"""
    clear_screen()
    _show_header_wrapper()

    event_id = questionary.text("Ingresa el ID del evento:", validate=lambda text: text.isdigit() or "Debe ser un numero").ask()

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
    info += f"[yellow]Descripcion:[/yellow] {event.get('description', '-')}\n"
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
        table = Table(title="Invitaciones del Evento", show_header=True, header_style="bold magenta")
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

            table.add_row(str(interaction["id"]), interaction["user_name"], interaction["interaction_type"], status, interaction.get("role", "-") or "-")

        console.print(table)
        console.print(f"\n[cyan]Total: {format_count_message(len(interactions), 'invitacion', 'invitaciones')}[/cyan]\n")
    else:
        console.print("[dim]No hay invitaciones para este evento[/dim]\n")

    # Si es modo usuario y es propio, ofrecer opciones
    if modo_actual == MODO_USUARIO and event.get("is_owner", False):
        gestionar = questionary.confirm("Deseas invitar a un usuario a este evento?", default=False).ask()

        if gestionar:
            invitar_a_evento(_show_header_wrapper, handle_api_error, pause, usuario_actual, event_id)
            return  # Volver a mostrar el evento despues

    pause()


# ==================== FUNCIONES DE INVITACION ====================


def invitar_a_evento(_show_header_wrapper, handle_api_error, pause, usuario_actual, event_id):
    """Permite invitar a un usuario a un evento (con soporte para eventos recurrentes)"""
    clear_screen()
    _show_header_wrapper()

    console.print(f"[bold cyan]Invitar Usuario al Evento #{event_id}[/bold cyan]\n")

    # Obtener el evento para mostrar informacion
    event_response = api_client.get(url_event(event_id))
    event = handle_api_error(event_response)

    if not event:
        pause()
        return

    console.print(f"[yellow]Evento:[/yellow] {event['name']}")
    console.print(f"[yellow]Tipo:[/yellow] {event['event_type']}\n")

    # Detectar si es evento recurrente o instancia de recurrente
    target_event_id = event_id
    is_recurring_instance = event.get('parent_recurring_event_id') is not None
    is_recurring_base = event.get('event_type') == 'recurring'

    if is_recurring_instance or is_recurring_base:
        console.print("[yellow]Este es un evento recurrente[/yellow]\n")

        # Si es una instancia, preguntar si quiere invitar al padre o solo a esta instancia
        if is_recurring_instance:
            invite_choice = questionary.select(
                "A que eventos deseas invitar al usuario?",
                choices=[
                    "A TODAS las instancias de esta recurrencia",
                    "Solo a ESTA instancia especifica",
                    "Cancelar"
                ],
                style=custom_style
            ).ask()

            if invite_choice == "Cancelar":
                return
            elif invite_choice == "A TODAS las instancias de esta recurrencia":
                # Necesitamos obtener el evento base (parent)
                console.print("[cyan]Buscando evento base recurrente...[/cyan]\n")

                # Obtener la config para saber el event_id base
                config_response = api_client.get(f"{API_BASE_URL}/recurring_configs/{event['parent_recurring_event_id']}")
                config = handle_api_error(config_response)

                if config:
                    target_event_id = config['event_id']
                    console.print(f"[green]Invitaras al evento base #{target_event_id} (todas las instancias)[/green]\n")
                else:
                    console.print("[red]No se pudo obtener el evento base, invitando solo a esta instancia[/red]\n")
            else:
                console.print(f"[green]Invitaras solo a esta instancia #{event_id}[/green]\n")

        elif is_recurring_base:
            console.print("[cyan]Este es el evento base de una recurrencia[/cyan]")
            console.print("[dim]Al invitar aqui, el usuario sera invitado a TODAS las instancias[/dim]\n")

    # Obtener usuarios disponibles (YA FILTRADOS por el backend)
    console.print("[cyan]Cargando usuarios disponibles...[/cyan]\n")
    available_response = api_client.get(url_event_available_invitees(target_event_id))
    available_users = handle_api_error(available_response)

    if not available_users:
        console.print("[yellow]No hay usuarios disponibles para invitar a este evento[/yellow]")
        console.print("[dim]Todos los usuarios ya han sido invitados o son propietarios del evento[/dim]\n")
        pause()
        return

    # Crear opciones de usuarios (solo formateo para display)
    user_choices = [f"{user['id']} - {user['display_name']}" for user in available_users]
    user_choices.append("Cancelar")

    user_choice = questionary.select("Selecciona el usuario a invitar:", choices=user_choices, style=custom_style).ask()

    if user_choice == "Cancelar":
        return

    # Parsear ID directamente del string seleccionado
    invited_user_id = int(user_choice.split(" - ")[0])

    # Preguntar por el rol (opcional)
    role_choice = questionary.select("Que rol tendra el usuario invitado?", choices=["Participante (sin rol especial)", "Admin", "Cancelar"], style=custom_style).ask()

    if role_choice == "Cancelar":
        return

    role = None
    if role_choice == "Admin":
        role = "admin"

    console.print(f"\n[cyan]Creando invitacion...[/cyan]\n")

    # Crear la invitacion (usando target_event_id que puede ser el padre o la instancia)
    invitation_data = {
        "event_id": int(target_event_id),
        "user_id": invited_user_id,
        "interaction_type": "invited",
        "status": "pending",
        "role": role,
        "invited_by_user_id": usuario_actual
    }

    response = api_client.post(url_interactions(), json=invitation_data)
    invitation = handle_api_error(response)

    if invitation:
        user_display = user_choice.split(" - ")[1] if " - " in user_choice else f"Usuario #{invited_user_id}"
        if target_event_id != event_id:
            console.print(f"[bold green]Invitacion enviada a {user_display} para TODAS las instancias del evento recurrente[/bold green]\n")
        else:
            console.print(f"[bold green]Invitacion enviada exitosamente a {user_display}[/bold green]\n")
    else:
        console.print("[red]No se pudo crear la invitacion[/red]\n")

    pause()


def invitar_usuario_a_evento_menu(_show_header_wrapper, handle_api_error, pause, usuario_actual):
    """Menu para seleccionar un evento propio e invitar a un usuario"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]Invitar Usuario a un Evento[/bold cyan]\n")
    console.print("[cyan]Cargando tus eventos...[/cyan]\n")

    # Obtener eventos del usuario actual
    response = api_client.get(url_user_events(usuario_actual))
    events = handle_api_error(response)

    if not events:
        console.print("[yellow]No tienes eventos creados[/yellow]\n")
        pause()
        return

    # Filtrar solo eventos propios
    my_events = [e for e in events if e.get('is_owner', False) or e.get('source') == 'owned']

    if not my_events:
        console.print("[yellow]No tienes eventos propios a los que puedas invitar usuarios[/yellow]\n")
        pause()
        return

    # Crear opciones de eventos
    event_choices = []
    for event in my_events:
        event_name = truncate_text(event['name'], 40)
        event_date = event.get('start_date_formatted', event.get('start_date', ''))
        event_choices.append(f"{event['id']} - {event_name} ({event_date})")

    event_choices.append("Cancelar")

    event_choice = questionary.select(
        "Selecciona el evento al que deseas invitar usuarios:",
        choices=event_choices,
        style=custom_style
    ).ask()

    if event_choice == "Cancelar":
        return

    # Parsear ID del evento
    event_id = int(event_choice.split(" - ")[0])

    # Llamar a la funcion existente para invitar
    invitar_a_evento(_show_header_wrapper, handle_api_error, pause, usuario_actual, event_id)


# ==================== FUNCIONES DE CREACION Y EDICION ====================


def crear_evento(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO):
    """Crea un nuevo evento"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]Crear Nuevo Evento[/bold cyan]\n")

    name = questionary.text("Nombre del evento:", validate=lambda text: len(text) > 0 or "No puede estar vacio").ask()

    if not name:
        return

    # En modo usuario, el owner es el usuario actual
    if modo_actual == MODO_USUARIO:
        owner_id = usuario_actual
        console.print(f"[dim]El evento sera creado como tuyo (Usuario #{owner_id})[/dim]\n")
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

    # Preguntar tipo de evento
    event_type_choice = questionary.select(
        "Que tipo de evento deseas crear?",
        choices=[
            "Evento Regular (fecha especifica)",
            "Evento Recurrente (se repite)",
            "Cancelar"
        ],
        style=custom_style
    ).ask()

    if event_type_choice == "Cancelar":
        return

    if event_type_choice == "Evento Recurrente (se repite)":
        crear_evento_recurrente(_show_header_wrapper, handle_api_error, pause, owner_id, name)
        return

    # Flujo para evento regular
    now = datetime.now()
    default_datetime = now.strftime("%Y-%m-%d %H:%M")
    start_date = questionary.text(
        "Fecha y hora de inicio (YYYY-MM-DD HH:MM):",
        default=default_datetime,
        validate=lambda text: len(text) > 0 or "No puede estar vacio"
    ).ask()

    if not start_date:
        return

    try:
        parsed_start = date_parser.parse(start_date)
    except:
        console.print("[red]Formato de fecha invalido[/red]")
        pause()
        return

    description = questionary.text("Descripcion (opcional):").ask()

    # Los eventos regulares NO tienen end_date (se omite del payload)
    data = {
        "name": name,
        "owner_id": owner_id,
        "start_date": parsed_start.isoformat(),
        "event_type": "regular"
    }

    if description:
        data["description"] = description

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
            console.print(f"[bold yellow]Conflictos detectados por el backend[/bold yellow]\n")
            conflict_table = create_conflicts_table(conflicts)
            console.print(conflict_table)
            console.print()

        continuar = questionary.confirm("Se han detectado conflictos. Crear de todos modos?", default=False).ask()

        if not continuar:
            pause()
            return

        # Reintentar con force=true
        response = api_client.post(url_events() + "?force=true", json=data)
    event = handle_api_error(response)

    if event:
        console.print(f"[bold green]Evento '{name}' creado exitosamente con ID: {event['id']}[/bold green]\n")

    pause()


def editar_evento(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO):
    """Edita un evento existente (solo si eres el propietario)"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]Editar Evento[/bold cyan]\n")

    event_id = questionary.text("ID del evento a editar:", validate=lambda text: text.isdigit() or "Debe ser un numero").ask()

    if not event_id:
        return

    # Obtener evento actual
    console.print(f"\n[cyan]Consultando evento #{event_id}...[/cyan]\n")
    response = api_client.get(url_event(event_id))
    event = handle_api_error(response)

    if not event:
        pause()
        return

    # Verificar permisos (solo en modo usuario)
    if modo_actual == MODO_USUARIO:
        # Verificar si es owner
        is_owner = event.get('owner_id') == usuario_actual

        # Si no es owner, verificar si es admin del evento
        has_admin_role = False
        if not is_owner:
            interaction_response = api_client.get(url_interactions(), params={"event_id": event_id, "user_id": usuario_actual})
            interactions = handle_api_error(interaction_response)

            if interactions:
                for interaction in interactions:
                    if interaction.get('role') == 'admin' and interaction.get('status') == 'accepted':
                        has_admin_role = True
                        break

        if not is_owner and not has_admin_role:
            console.print("[red]No tienes permisos para editar este evento[/red]")
            console.print("[yellow]Solo el propietario o administradores del evento pueden editarlo[/yellow]\n")
            pause()
            return

    # Mostrar datos actuales
    console.print(Panel(
        f"[yellow]Nombre:[/yellow] {event['name']}\n"
        f"[yellow]Descripcion:[/yellow] {event.get('description', 'Sin descripcion')}\n"
        f"[yellow]Tipo:[/yellow] {event['event_type']}\n"
        f"[yellow]Fecha inicio:[/yellow] {event['start_date']}\n"
        f"[yellow]Fecha fin:[/yellow] {event.get('end_date', 'Sin fecha fin')}",
        title=f"[bold]Evento #{event['id']}[/bold]",
        border_style="yellow"
    ))
    console.print()

    # Solo permitir editar eventos regulares (no recurrentes)
    if event['event_type'] != 'regular':
        console.print(f"[red]No se pueden editar eventos de tipo '{event['event_type']}' directamente[/red]")
        console.print("[yellow]Para eventos recurrentes, edita la configuracion de recurrencia[/yellow]\n")
        pause()
        return

    # Editar nombre
    new_name = questionary.text(
        "Nuevo nombre (Enter para mantener):",
        default=event['name']
    ).ask()

    if not new_name:
        return

    # Editar descripcion
    new_description = questionary.text(
        "Nueva descripcion (Enter para mantener):",
        default=event.get('description', '')
    ).ask()

    # Editar fecha inicio
    current_start = event['start_date'][:16] if event.get('start_date') else datetime.now().strftime("%Y-%m-%d %H:%M")
    new_start_str = questionary.text(
        "Nueva fecha inicio (YYYY-MM-DD HH:MM, Enter para mantener):",
        default=current_start
    ).ask()

    if not new_start_str:
        return

    try:
        new_start_date = date_parser.parse(new_start_str).isoformat()
    except:
        console.print("[red]Formato de fecha invalido[/red]")
        pause()
        return

    # Preguntar si quiere fecha fin
    has_end_date = questionary.confirm(
        "Tiene fecha fin?",
        default=bool(event.get('end_date'))
    ).ask()

    new_end_date = None
    if has_end_date:
        current_end = event['end_date'][:16] if event.get('end_date') else new_start_str
        new_end_str = questionary.text(
            "Nueva fecha fin (YYYY-MM-DD HH:MM):",
            default=current_end
        ).ask()

        if new_end_str:
            try:
                new_end_date = date_parser.parse(new_end_str).isoformat()
            except:
                console.print("[red]Formato de fecha invalido, se ignorara[/red]")

    # Preparar datos
    data = {
        "name": new_name,
        "description": new_description if new_description else None,
        "start_date": new_start_date,
        "end_date": new_end_date,
        "event_type": event['event_type'],
        "owner_id": event['owner_id']
    }

    # Mantener calendar_id si existe
    if event.get('calendar_id'):
        data['calendar_id'] = event['calendar_id']

    # Actualizar
    console.print("\n[cyan]Actualizando evento...[/cyan]\n")
    response = api_client.put(url_event(event_id), json=data)
    updated_event = handle_api_error(response)

    if updated_event:
        console.print(f"[bold green]Evento actualizado exitosamente[/bold green]\n")

    pause()


def crear_evento_recurrente(_show_header_wrapper, handle_api_error, pause, owner_id, name):
    """Crea un evento recurrente con su configuracion - soporta daily, weekly, monthly, yearly"""
    clear_screen()
    _show_header_wrapper()

    console.print(f"[bold cyan]Crear Evento Recurrente: {name}[/bold cyan]\n")

    # 1. Seleccionar tipo de recurrencia
    recurrence_choice = questionary.select(
        "Que tipo de recurrencia deseas?",
        choices=[
            "Diaria - Se repite cada X dias",
            "Semanal - Dias especificos de la semana",
            "Mensual - Dias especificos del mes",
            "Anual - Fecha especifica cada ano (cumpleanos, festividades)",
            "Cancelar"
        ],
        style=custom_style
    ).ask()

    if recurrence_choice == "Cancelar":
        return

    # Mapeo del choice al tipo
    recurrence_type_map = {
        "Diaria - Se repite cada X dias": "daily",
        "Semanal - Dias especificos de la semana": "weekly",
        "Mensual - Dias especificos del mes": "monthly",
        "Anual - Fecha especifica cada ano (cumpleanos, festividades)": "yearly"
    }
    recurrence_type = recurrence_type_map[recurrence_choice]

    # 2. Fecha de inicio
    now = datetime.now()
    default_start = now.strftime("%Y-%m-%d %H:%M")
    start_date_str = questionary.text(
        "Fecha y hora de INICIO (YYYY-MM-DD HH:MM):",
        default=default_start
    ).ask()

    if not start_date_str:
        return

    try:
        parsed_start_date = date_parser.parse(start_date_str)
    except:
        console.print("[red]Formato de fecha invalido[/red]")
        pause()
        return

    # 3. Configurar schedule segun el tipo
    schedule = []

    if recurrence_type == "daily":
        interval = questionary.text(
            "Cada cuantos dias se repite? (1 = todos los dias, 2 = dia si dia no, etc.):",
            default="1"
        ).ask()
        try:
            interval = int(interval)
        except:
            interval = 1
        schedule = [{"interval_days": interval}]

    elif recurrence_type == "weekly":
        console.print("\n[cyan]Selecciona los dias de la semana:[/cyan]")
        days_choices = questionary.checkbox(
            "Dias:",
            choices=["0 - Lunes", "1 - Martes", "2 - Miercoles", "3 - Jueves", "4 - Viernes", "5 - Sabado", "6 - Domingo"]
        ).ask()

        if not days_choices:
            console.print("[yellow]Debes seleccionar al menos un dia[/yellow]")
            pause()
            return

        day_names = ["Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo"]
        for day_choice in days_choices:
            day_num = int(day_choice.split(" - ")[0])
            schedule.append({"day": day_num, "day_name": day_names[day_num]})

    elif recurrence_type == "monthly":
        console.print("\n[cyan]Selecciona los dias del mes:[/cyan]")
        console.print("[dim]Ejemplos: 1, 15, 30 o -1 para ultimo dia del mes[/dim]")
        days_input = questionary.text(
            "Dias del mes (separados por coma):",
            default="1"
        ).ask()

        try:
            days_of_month = [int(d.strip()) for d in days_input.split(",")]
            schedule = [{"day_of_month": day} for day in days_of_month]
        except:
            console.print("[red]Formato invalido[/red]")
            pause()
            return

    elif recurrence_type == "yearly":
        console.print("\n[cyan]Evento anual - se repetira cada ano en la misma fecha[/cyan]")
        month = parsed_start_date.month
        day = parsed_start_date.day
        schedule = [{"month": month, "day_of_month": day}]
        console.print(f"[dim]Se repetira cada ano el {day}/{month}[/dim]")

    # 4. Preguntar si es perpetuo o tiene fecha fin
    is_perpetual = questionary.confirm(
        "Es un evento perpetuo/infinito? (ej: cumpleanos, festividades)",
        default=(recurrence_type == "yearly")
    ).ask()

    recurrence_end = None
    if not is_perpetual:
        default_end = (parsed_start_date + timedelta(days=90)).strftime("%Y-%m-%d")
        recurrence_end_str = questionary.text(
            "Fecha de fin de la recurrencia (YYYY-MM-DD):",
            default=default_end
        ).ask()

        if recurrence_end_str:
            try:
                recurrence_end = date_parser.parse(recurrence_end_str)
            except:
                console.print("[yellow]Formato invalido, se creara como perpetuo[/yellow]")

    # 5. Descripcion
    description = questionary.text("Descripcion (opcional):").ask()

    # 6. Crear evento base
    console.print("\n[cyan]Creando evento recurrente...[/cyan]\n")

    event_data = {
        "name": name,
        "owner_id": owner_id,
        "start_date": parsed_start_date.isoformat(),
        "event_type": "recurring"
    }

    if description:
        event_data["description"] = description

    response = api_client.post(url_events(), json=event_data)
    event = handle_api_error(response)

    if not event:
        console.print("[red]No se pudo crear el evento base[/red]")
        pause()
        return

    console.print(f"[green]Evento base creado con ID: {event['id']}[/green]\n")

    # 7. Crear configuracion recurrente
    console.print("[cyan]Creando configuracion de recurrencia...[/cyan]\n")

    config_data = {
        "event_id": event['id'],
        "recurrence_type": recurrence_type,
        "schedule": schedule,
        "recurrence_end_date": recurrence_end.isoformat() if recurrence_end else None
    }

    config_response = api_client.post(url_recurring_configs(), json=config_data)
    config = handle_api_error(config_response)

    if not config:
        console.print("[red]No se pudo crear la configuracion de recurrencia[/red]")
        pause()
        return

    console.print(f"[bold green]Evento recurrente '{name}' creado exitosamente![/bold green]")
    console.print(f"[dim]Tipo: {recurrence_type}[/dim]")
    if is_perpetual:
        console.print(f"[dim]Recurrencia: Perpetua (sin fecha fin)[/dim]")
    else:
        console.print(f"[dim]Hasta: {recurrence_end.strftime('%Y-%m-%d') if recurrence_end else 'Perpetuo'}[/dim]")
    console.print()

    pause()


def eliminar_evento(_show_header_wrapper, handle_api_error, pause):
    """Elimina un evento (solo Modo Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    event_id = questionary.text("Ingresa el ID del evento a eliminar:", validate=lambda text: text.isdigit() or "Debe ser un numero").ask()

    if not event_id:
        return

    confirmar = questionary.confirm(f"Estas seguro de eliminar el evento #{event_id}?", default=False).ask()

    if not confirmar:
        console.print("[yellow]Operacion cancelada[/yellow]")
        pause()
        return

    console.print(f"\n[cyan]Eliminando evento #{event_id}...[/cyan]\n")

    response = api_client.delete(url_event(event_id))

    if response.status_code in [200, 204]:
        console.print(f"[bold green]Evento #{event_id} eliminado exitosamente[/bold green]\n")
    else:
        handle_api_error(response)

    pause()
