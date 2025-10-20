# -*- coding: utf-8 -*-
"""
Menu de gestion de calendarios
"""
import questionary
import api_client
from rich.panel import Panel
from rich.table import Table
from dateutil import parser as date_parser

from ui.console import console, custom_style, clear_screen
from ui.tables import truncate_text, format_count_message, create_events_table, show_pagination_info
from config import (
    url_calendars, url_calendar, url_calendar_memberships, url_calendar_membership,
    url_calendar_memberships_nested, url_events, url_users
)


def menu_calendarios(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO, MODO_BACKOFFICE):
    """Menu de gestion de calendarios (adaptado segun el modo)"""
    while True:
        clear_screen()
        _show_header_wrapper()

        if modo_actual == MODO_USUARIO:
            choices = [
                "Ver MIS calendarios",
                "Ver detalles de un calendario",
                "Ver eventos de un calendario",
                "Crear nuevo calendario",
                "Editar calendario",
                "Volver al menu principal",
            ]
        else:  # MODO_BACKOFFICE
            choices = [
                "Ver todos los calendarios",
                "Ver detalles de un calendario",
                "Ver eventos de un calendario",
                "Ver miembros de un calendario",
                "Crear nuevo calendario",
                "Editar calendario",
                "Volver al menu principal",
            ]

        choice = questionary.select(
            "Gestion de Calendarios - Que deseas hacer?",
            choices=choices,
            style=custom_style,
        ).ask()

        if choice == "Ver MIS calendarios":
            ver_mis_calendarios(_show_header_wrapper, handle_api_error, pause, usuario_actual)
        elif choice == "Ver todos los calendarios":
            listar_todos_calendarios(_show_header_wrapper, handle_api_error, pause)
        elif choice == "Ver detalles de un calendario":
            ver_calendario(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO)
        elif choice == "Ver eventos de un calendario":
            ver_eventos_calendario(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO)
        elif choice == "Ver miembros de un calendario":
            ver_miembros_calendario(_show_header_wrapper, handle_api_error, pause)
        elif choice == "Crear nuevo calendario":
            crear_calendario(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO)
        elif choice == "Editar calendario":
            editar_calendario(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO)
        elif choice == "Volver al menu principal":
            break


def ver_mis_calendarios(_show_header_wrapper, handle_api_error, pause, usuario_actual):
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
        table_own = Table(title="Mis Calendarios Propios", show_header=True, header_style="bold magenta")
        table_own.add_column("ID", style="cyan", justify="right", width=5)
        table_own.add_column("Nombre", style="green", width=25)
        table_own.add_column("Descripcion", style="yellow", width=30)

        for cal in my_calendars:
            table_own.add_row(str(cal["id"]), cal["name"], truncate_text(cal.get("description", "-"), 28))

        console.print(table_own)
        console.print(f"\n[cyan]{len(my_calendars)} calendario(s) propio(s)[/cyan]\n")

    # Tabla de calendarios compartidos
    if shared_calendars:
        table_shared = Table(title="Calendarios Compartidos Conmigo", show_header=True, header_style="bold cyan")
        table_shared.add_column("ID", style="cyan", justify="right", width=5)
        table_shared.add_column("Nombre", style="green", width=20)
        table_shared.add_column("Rol", style="blue", width=10)
        table_shared.add_column("Estado", style="yellow", width=12)
        table_shared.add_column("Propietario", style="magenta", justify="right", width=12)

        for cal in shared_calendars:
            status_color = "green" if cal["status"] == "accepted" else "yellow"
            table_shared.add_row(str(cal["calendar_id"]), truncate_text(cal["calendar_name"], 18), cal["role"], f"[{status_color}]{cal['status']}[/{status_color}]", f"Usuario #{cal['calendar_owner_id']}")

        console.print(table_shared)
        console.print(f"\n[cyan]{len(shared_calendars)} calendario(s) compartido(s)[/cyan]\n")

        # Obtener pending memberships desde el backend (filtrado por status y exclude_owned)
        pending_params = {"user_id": usuario_actual, "status": "pending", "enriched": "true", "exclude_owned": "true"}
        pending_response = api_client.get(url_calendar_memberships(), params=pending_params)
        pending_memberships = handle_api_error(pending_response) or []

        if pending_memberships:
            console.print(f"[magenta]Tienes {len(pending_memberships)} invitacion(es) pendiente(s) a calendarios[/magenta]\n")

            gestionar = questionary.confirm("Deseas aceptar o rechazar alguna invitacion a calendario?", default=False).ask()

            if gestionar:
                gestionar_invitaciones_calendarios(_show_header_wrapper, handle_api_error, pause, pending_memberships)
                return  # Volver a mostrar despues de gestionar

    pause()


def gestionar_invitaciones_calendarios(_show_header_wrapper, handle_api_error, pause, pending_calendars):
    """Permite aceptar o rechazar invitaciones a calendarios"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]Gestionar Invitaciones a Calendarios[/bold cyan]\n")

    # Crear opciones para seleccionar
    cal_choices = []
    for cal in pending_calendars:
        cal_choices.append(f"ID {cal['id']} - {cal['name']}")

    cal_choices.append("Cancelar")

    cal_choice = questionary.select("Selecciona la invitacion a gestionar:", choices=cal_choices, style=custom_style).ask()

    if cal_choice == "Cancelar":
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

    # Preguntar accion
    action = questionary.select(f"Que deseas hacer con la invitacion a '{calendar_name}'?", choices=["Aceptar invitacion", "Rechazar invitacion", "Cancelar"], style=custom_style).ask()

    if action == "Cancelar":
        return

    new_status = "accepted" if action == "Aceptar invitacion" else "rejected"

    console.print(f"\n[cyan]Actualizando invitacion...[/cyan]\n")

    # Actualizar el estado de la membresia
    update_data = {"status": new_status, "role": selected_cal["role"]}  # Mantener el rol actual

    response = api_client.put(url_calendar_membership(membership_id), json=update_data)

    if response.status_code in [200, 204]:
        status_text = "aceptada" if new_status == "accepted" else "rechazada"
        console.print(f"[bold green]Invitacion {status_text} exitosamente[/bold green]\n")
    else:
        handle_api_error(response)

    pause()


def listar_todos_calendarios(_show_header_wrapper, handle_api_error, pause):
    """Lista todos los calendarios (Modo Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    console.print("[cyan]Consultando calendarios...[/cyan]\n")

    response = api_client.get(url_calendars())
    calendars = handle_api_error(response)

    if not calendars:
        pause()
        return

    table = Table(title="Calendarios", show_header=True, header_style="bold magenta")
    table.add_column("ID", style="cyan", justify="right", width=5)
    table.add_column("Nombre", style="green", width=20)
    table.add_column("Descripcion", style="yellow", width=30)
    table.add_column("User ID", style="blue", justify="right", width=8)

    for cal in calendars:
        table.add_row(str(cal["id"]), cal["name"], cal.get("description", "-")[:28] + "..." if cal.get("description") and len(cal.get("description", "")) > 28 else cal.get("description", "-"), str(cal.get("user_id", "-")))

    console.print(table)
    console.print(f"\n[cyan]Total: {len(calendars)} calendarios[/cyan]\n")
    pause()


def ver_calendario(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO):
    """Muestra detalles de un calendario especifico con sus eventos"""
    clear_screen()
    _show_header_wrapper()

    calendar_id = questionary.text("Ingresa el ID del calendario:", validate=lambda text: text.isdigit() or "Debe ser un numero").ask()

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

    # Mostrar fechas de calendario temporal si existen
    if calendar.get('start_date'):
        info += f"[yellow]Fecha Inicio:[/yellow] {calendar['start_date']}\n"
    if calendar.get('end_date'):
        info += f"[yellow]Fecha Fin:[/yellow] {calendar['end_date']}\n"

    if not calendar.get('start_date') and not calendar.get('end_date'):
        info += f"[yellow]Tipo:[/yellow] Calendario permanente\n"
    else:
        info += f"[yellow]Tipo:[/yellow] Calendario temporal\n"

    # En modo usuario, mostrar si es propio
    if modo_actual == MODO_USUARIO:
        es_propio = calendar.get("owner_id") == usuario_actual
        propietario = "Yo" if es_propio else f"Usuario #{calendar.get('owner_id', '-')}"
        info += f"[yellow]Propietario:[/yellow] {propietario}"
    else:
        info += f"[yellow]Owner ID:[/yellow] {calendar.get('owner_id', '-')}"

    console.print(Panel(info, title=f"[bold cyan]Calendario #{calendar['id']}[/bold cyan]", border_style="cyan"))
    console.print()

    # Obtener eventos del calendario
    console.print(f"[cyan]Consultando eventos del calendario...[/cyan]\n")

    params = {"calendar_id": calendar_id}
    if modo_actual == MODO_USUARIO and usuario_actual:
        params["current_user_id"] = usuario_actual

    events_response = api_client.get(url_events(), params=params)
    calendar_events = handle_api_error(events_response)

    if calendar_events:
        # Usar funcion de utilidad para crear la tabla
        current_user = usuario_actual if modo_actual == MODO_USUARIO else None
        table = create_events_table(
            calendar_events,
            title=f"Eventos en '{calendar['name']}'",
            current_user_id=current_user,
            max_rows=20
        )
        console.print(table)
        show_pagination_info(min(20, len(calendar_events)), len(calendar_events))
        console.print(f"\n[cyan]Total: {format_count_message(len(calendar_events), 'evento', 'eventos')}[/cyan]\n")
    else:
        console.print("[dim]Este calendario no tiene eventos[/dim]\n")

    pause()


def ver_miembros_calendario(_show_header_wrapper, handle_api_error, pause):
    """Muestra los miembros de un calendario (Modo Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    calendar_id = questionary.text("Ingresa el ID del calendario:", validate=lambda text: text.isdigit() or "Debe ser un numero").ask()

    if not calendar_id:
        return

    console.print(f"\n[cyan]Consultando miembros del calendario #{calendar_id}...[/cyan]\n")

    response = api_client.get(url_calendar_memberships_nested(calendar_id))
    memberships = handle_api_error(response)

    if not memberships:
        console.print("[yellow]Este calendario no tiene miembros adicionales[/yellow]\n")
        pause()
        return

    table = Table(title=f"Miembros del Calendario #{calendar_id}", show_header=True, header_style="bold magenta")
    table.add_column("User ID", style="cyan", justify="right", width=10)
    table.add_column("Rol", style="green", width=15)
    table.add_column("Estado", style="yellow", width=15)
    table.add_column("Invitado Por", style="blue", justify="right", width=15)

    for member in memberships:
        table.add_row(str(member["user_id"]), member["role"], member["status"], str(member.get("invited_by_user_id", "-")))

    console.print(table)
    console.print(f"\n[cyan]Total: {len(memberships)} miembros[/cyan]\n")
    pause()


def crear_calendario(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO):
    """Crea un nuevo calendario"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]Crear Nuevo Calendario[/bold cyan]\n")

    name = questionary.text("Nombre del calendario:", validate=lambda text: len(text) > 0 or "No puede estar vacio").ask()

    if not name:
        return

    # En modo usuario, el owner es el usuario actual
    if modo_actual == MODO_USUARIO:
        owner_id = usuario_actual
        console.print(f"[dim]El calendario sera creado como tuyo (Usuario #{owner_id})[/dim]\n")
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

    # Preguntar si es calendario temporal
    is_temporal = questionary.confirm(
        "Es un calendario temporal (con fechas de inicio/fin)?",
        default=False
    ).ask()

    start_date = None
    end_date = None

    if is_temporal:
        console.print("\n[cyan]Configurar fechas del calendario temporal[/cyan]\n")

        # Pedir fecha de inicio
        start_date_str = questionary.text(
            "Fecha de inicio (YYYY-MM-DD):",
            validate=lambda text: len(text) > 0 or "No puede estar vacio"
        ).ask()

        if not start_date_str:
            return

        try:
            start_date = date_parser.parse(start_date_str).isoformat()
        except:
            console.print("[red]Formato de fecha invalido[/red]")
            pause()
            return

        # Pedir fecha fin
        end_date_str = questionary.text(
            "Fecha fin (YYYY-MM-DD):",
            validate=lambda text: len(text) > 0 or "No puede estar vacio"
        ).ask()

        if not end_date_str:
            return

        try:
            end_date = date_parser.parse(end_date_str).isoformat()
        except:
            console.print("[red]Formato de fecha invalido[/red]")
            pause()
            return

    data = {
        "name": name,
        "owner_id": owner_id,
        "start_date": start_date,
        "end_date": end_date
    }

    console.print("\n[cyan]Creando calendario...[/cyan]\n")
    response = api_client.post(url_calendars(), json=data)
    calendar = handle_api_error(response)

    if calendar:
        tipo = "temporal" if is_temporal else "permanente"
        console.print(f"[bold green]Calendario '{name}' ({tipo}) creado exitosamente con ID: {calendar['id']}[/bold green]\n")

    pause()


def editar_calendario(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO):
    """Edita un calendario existente (solo si tienes permisos)"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]Editar Calendario[/bold cyan]\n")

    # En modo usuario, primero mostrar los calendarios que puede editar
    if modo_actual == MODO_USUARIO:
        console.print("[cyan]Cargando calendarios que puedes editar...[/cyan]\n")

        # Obtener memberships del usuario
        memberships_response = api_client.get(url_calendar_memberships(), params={"user_id": usuario_actual, "status": "accepted"})
        memberships = handle_api_error(memberships_response)

        if not memberships:
            console.print("[yellow]No tienes calendarios que puedas editar[/yellow]\n")
            pause()
            return

        # Filtrar solo calendarios donde sea owner o admin
        editable_calendars = []
        calendar_ids_to_fetch = set()

        for membership in memberships:
            if membership.get('role') in ['owner', 'admin']:
                calendar_ids_to_fetch.add(membership['calendar_id'])

        if not calendar_ids_to_fetch:
            console.print("[yellow]No tienes calendarios donde seas propietario o administrador[/yellow]\n")
            pause()
            return

        # Obtener detalles de calendarios
        for cal_id in calendar_ids_to_fetch:
            cal_response = api_client.get(url_calendar(cal_id))
            calendar = handle_api_error(cal_response)
            if calendar:
                # Agregar rol del usuario
                for membership in memberships:
                    if membership['calendar_id'] == cal_id:
                        calendar['_user_role'] = membership.get('role')
                        break
                editable_calendars.append(calendar)

        if not editable_calendars:
            console.print("[yellow]No se pudieron cargar los calendarios[/yellow]\n")
            pause()
            return

        # Mostrar tabla de calendarios editables
        table = Table(title="Calendarios que puedes editar", show_header=True, header_style="bold cyan")
        table.add_column("ID", style="cyan", justify="right", width=8)
        table.add_column("Nombre", style="yellow", width=30)
        table.add_column("Tipo", style="green", width=15)
        table.add_column("Rol", style="magenta", width=10)

        for calendar in editable_calendars:
            tipo = "Temporal" if calendar.get('start_date') or calendar.get('end_date') else "Permanente"
            rol = calendar.get('_user_role', 'N/A').capitalize()

            table.add_row(
                str(calendar['id']),
                truncate_text(calendar['name'], 28),
                tipo,
                rol
            )

        console.print(table)
        console.print()

    calendar_id = questionary.text("ID del calendario a editar:", validate=lambda text: text.isdigit() or "Debe ser un numero").ask()

    if not calendar_id:
        return

    # Obtener calendario actual
    console.print(f"\n[cyan]Consultando calendario #{calendar_id}...[/cyan]\n")
    response = api_client.get(url_calendar(calendar_id))
    calendar = handle_api_error(response)

    if not calendar:
        pause()
        return

    # Verificar permisos (solo en modo usuario)
    if modo_actual == MODO_USUARIO:
        # Verificar si es owner
        is_owner = calendar.get('owner_id') == usuario_actual

        # Si no es owner, verificar si es admin del calendario
        has_admin_access = False
        if not is_owner:
            memberships_response = api_client.get(url_calendar_memberships(), params={"calendar_id": calendar_id, "user_id": usuario_actual})
            memberships = handle_api_error(memberships_response)

            if memberships:
                for membership in memberships:
                    if membership.get('role') == 'admin' and membership.get('status') == 'accepted':
                        has_admin_access = True
                        break

        if not is_owner and not has_admin_access:
            console.print("[red]No tienes permisos para editar este calendario[/red]")
            console.print("[yellow]Solo el propietario o administradores pueden editar calendarios[/yellow]\n")
            pause()
            return

    # Mostrar datos actuales
    console.print(Panel(
        f"[yellow]Nombre actual:[/yellow] {calendar['name']}\n"
        f"[yellow]Start Date:[/yellow] {calendar.get('start_date', 'Sin fecha')}\n"
        f"[yellow]End Date:[/yellow] {calendar.get('end_date', 'Sin fecha')}",
        title=f"[bold]Calendario #{calendar['id']}[/bold]",
        border_style="yellow"
    ))
    console.print()

    # Editar nombre
    new_name = questionary.text(
        "Nuevo nombre (Enter para mantener):",
        default=calendar['name']
    ).ask()

    if not new_name:
        return

    # Preguntar si es calendario temporal
    is_temporal = questionary.confirm(
        "Es un calendario temporal (con fechas de inicio/fin)?",
        default=bool(calendar.get('start_date') or calendar.get('end_date'))
    ).ask()

    start_date = None
    end_date = None

    if is_temporal:
        # Pedir fecha de inicio
        start_date_str = questionary.text(
            "Fecha inicio (YYYY-MM-DD HH:MM, Enter para mantener/quitar):",
            default=calendar.get('start_date', '')[:16] if calendar.get('start_date') else ''
        ).ask()

        if start_date_str:
            try:
                start_date = date_parser.parse(start_date_str).isoformat()
            except:
                console.print("[red]Formato de fecha invalido, se ignorara[/red]")

        # Pedir fecha fin
        end_date_str = questionary.text(
            "Fecha fin (YYYY-MM-DD HH:MM, Enter para mantener/quitar):",
            default=calendar.get('end_date', '')[:16] if calendar.get('end_date') else ''
        ).ask()

        if end_date_str:
            try:
                end_date = date_parser.parse(end_date_str).isoformat()
            except:
                console.print("[red]Formato de fecha invalido, se ignorara[/red]")

    # Preparar datos
    data = {
        "name": new_name,
        "start_date": start_date,
        "end_date": end_date
    }

    # Actualizar
    console.print("\n[cyan]Actualizando calendario...[/cyan]\n")
    response = api_client.put(url_calendar(calendar_id), json=data)
    updated_calendar = handle_api_error(response)

    if updated_calendar:
        console.print(f"[bold green]Calendario actualizado exitosamente[/bold green]\n")

    pause()


def ver_eventos_calendario(_show_header_wrapper, handle_api_error, pause, modo_actual, usuario_actual, MODO_USUARIO):
    """Muestra los eventos de un calendario especifico"""
    clear_screen()
    _show_header_wrapper()

    calendar_id = questionary.text("Ingresa el ID del calendario:", validate=lambda text: text.isdigit() or "Debe ser un numero").ask()

    if not calendar_id:
        return

    console.print(f"\n[cyan]Consultando calendario #{calendar_id}...[/cyan]\n")

    # Verificar que el calendario existe
    calendar_response = api_client.get(url_calendar(calendar_id))
    calendar = handle_api_error(calendar_response)

    if not calendar:
        pause()
        return

    # Mostrar informacion del calendario
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

    # Usar funcion de utilidad para crear la tabla
    title = f"Eventos del Calendario: {calendar['name']}"

    # Si estamos en modo usuario, pasar el usuario actual
    current_user = usuario_actual if modo_actual == MODO_USUARIO else None

    table = create_events_table(calendar_events, title=title, current_user_id=current_user, max_rows=30)
    console.print(table)

    show_pagination_info(min(30, len(calendar_events)), len(calendar_events))

    console.print(f"\n[cyan]Total: {format_count_message(len(calendar_events), 'evento', 'eventos')} en este calendario[/cyan]\n")
    pause()
