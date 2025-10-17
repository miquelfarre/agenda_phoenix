#!/usr/bin/env python3
"""
Agenda Phoenix CLI - Gestión de calendarios, eventos y usuarios
"""
import typer
from typing import Optional
from datetime import datetime
from dateutil import parser as date_parser
import requests
from rich.console import Console
from rich.table import Table
from rich import print as rprint
from config import API_BASE_URL

app = typer.Typer(
    name="agenda",
    help="CLI para gestionar Agenda Phoenix - Calendarios, eventos y usuarios",
    add_completion=False,
)

# Sub-aplicaciones para cada categoría
users_app = typer.Typer(help="Gestión de usuarios")
contacts_app = typer.Typer(help="Gestión de contactos")
events_app = typer.Typer(help="Gestión de eventos")
calendars_app = typer.Typer(help="Gestión de calendarios")
subscribe_app = typer.Typer(help="Gestión de subscripciones")
interact_app = typer.Typer(help="Gestión de interacciones con eventos")

app.add_typer(users_app, name="users")
app.add_typer(contacts_app, name="contacts")
app.add_typer(events_app, name="events")
app.add_typer(calendars_app, name="calendars")
app.add_typer(subscribe_app, name="subscribe")
app.add_typer(interact_app, name="interact")

console = Console()


def handle_response(response: requests.Response, success_msg: str = None):
    """Maneja la respuesta de la API y muestra errores si hay"""
    if response.status_code >= 200 and response.status_code < 300:
        if success_msg:
            console.print(f"✅ {success_msg}", style="bold green")
        return response.json() if response.content else None
    else:
        console.print(f"❌ Error: {response.status_code}", style="bold red")
        try:
            error_detail = response.json()
            console.print(error_detail)
        except:
            console.print(response.text)
        raise typer.Exit(code=1)


# ==================== USERS COMMANDS ====================

@users_app.command("list")
def list_users():
    """Lista todos los usuarios"""
    response = requests.get(f"{API_BASE_URL}/users")
    users = handle_response(response)

    # Also get all contacts to match names
    contacts_response = requests.get(f"{API_BASE_URL}/contacts")
    contacts = {}
    if contacts_response.status_code == 200:
        for contact in contacts_response.json():
            contacts[contact['id']] = contact

    table = Table(title="Usuarios")
    table.add_column("ID", style="cyan", justify="right")
    table.add_column("Username", style="magenta")
    table.add_column("Contact", style="green")
    table.add_column("Auth Provider", style="yellow")
    table.add_column("Contact ID", style="blue", justify="right")

    for user in users:
        contact_name = "-"
        if user.get('contact_id') and user['contact_id'] in contacts:
            contact_name = f"{contacts[user['contact_id']]['name']}"

        table.add_row(
            str(user['id']),
            user.get('username', '-'),
            contact_name,
            user.get('auth_provider', '-'),
            str(user.get('contact_id', '-'))
        )

    console.print(table)


@users_app.command("get")
def get_user(user_id: int):
    """Obtiene información detallada de un usuario"""
    response = requests.get(f"{API_BASE_URL}/users/{user_id}")
    user = handle_response(response)

    rprint(f"\n[bold cyan]Usuario #{user['id']}[/bold cyan]")
    rprint(f"[yellow]Username:[/yellow] {user.get('username', '-')}")
    rprint(f"[yellow]Auth Provider:[/yellow] {user.get('auth_provider', '-')}")
    rprint(f"[yellow]Auth ID:[/yellow] {user.get('auth_id', '-')}")

    # Get contact info if available
    if user.get('contact_id'):
        contact_response = requests.get(f"{API_BASE_URL}/contacts/{user['contact_id']}")
        if contact_response.status_code == 200:
            contact = contact_response.json()
            rprint(f"[yellow]Nombre (Contact):[/yellow] {contact.get('name', '-')}")
            rprint(f"[yellow]Teléfono (Contact):[/yellow] {contact.get('phone', '-')}")

    rprint(f"[yellow]Profile Picture:[/yellow] {user.get('profile_picture_url', '-')}")
    rprint(f"[yellow]Creado:[/yellow] {user.get('created_at', '-')}\n")


@users_app.command("create")
def create_user(
    auth_provider: str = typer.Option(..., "--provider", "-p", help="Proveedor de autenticación (phone, instagram, etc.)"),
    auth_id: str = typer.Option(..., "--auth-id", "-a", help="ID de autenticación"),
    username: Optional[str] = typer.Option(None, "--username", help="Nombre de usuario"),
    contact_id: Optional[int] = typer.Option(None, "--contact", "-c", help="ID del contacto asociado"),
    profile_pic: Optional[str] = typer.Option(None, "--pic", help="URL de la foto de perfil")
):
    """Crea un nuevo usuario"""
    data = {
        "auth_provider": auth_provider,
        "auth_id": auth_id,
        "username": username,
        "contact_id": contact_id,
        "profile_picture_url": profile_pic
    }

    response = requests.post(f"{API_BASE_URL}/users", json=data)
    user = handle_response(response, f"Usuario creado correctamente")

    rprint(f"[green]ID del nuevo usuario: {user['id']}[/green]")


# ==================== CONTACTS COMMANDS ====================

@contacts_app.command("list")
def list_contacts():
    """Lista todos los contactos"""
    response = requests.get(f"{API_BASE_URL}/contacts")
    contacts = handle_response(response)

    table = Table(title="Contactos")
    table.add_column("ID", style="cyan", justify="right")
    table.add_column("Nombre", style="magenta")
    table.add_column("Teléfono", style="green")

    for contact in contacts:
        table.add_row(
            str(contact['id']),
            contact['name'],
            contact.get('phone', '-')
        )

    console.print(table)


@contacts_app.command("get")
def get_contact(contact_id: int):
    """Obtiene información detallada de un contacto"""
    response = requests.get(f"{API_BASE_URL}/contacts/{contact_id}")
    contact = handle_response(response)

    rprint(f"\n[bold cyan]Contacto #{contact['id']}[/bold cyan]")
    rprint(f"[yellow]Nombre:[/yellow] {contact['name']}")
    rprint(f"[yellow]Teléfono:[/yellow] {contact.get('phone', '-')}")
    rprint(f"[yellow]Creado:[/yellow] {contact.get('created_at', '-')}\n")


@contacts_app.command("create")
def create_contact(
    name: str = typer.Option(..., "--name", "-n", help="Nombre del contacto"),
    phone: str = typer.Option(..., "--phone", "-p", help="Teléfono del contacto")
):
    """Crea un nuevo contacto"""
    data = {
        "name": name,
        "phone": phone
    }

    response = requests.post(f"{API_BASE_URL}/contacts", json=data)
    contact = handle_response(response, f"Contacto '{name}' creado correctamente")

    rprint(f"[green]ID del nuevo contacto: {contact['id']}[/green]")


# ==================== EVENTS COMMANDS ====================

@events_app.command("list")
def list_events(
    user_id: int,
    from_date: Optional[str] = typer.Option(None, "--desde", help="Fecha desde (formato: YYYY-MM-DD)"),
    to_date: Optional[str] = typer.Option(None, "--hasta", help="Fecha hasta (formato: YYYY-MM-DD)"),
):
    """Lista todos los eventos de un usuario

    Args:
        user_id: ID del usuario (argumento posicional)
    """
    params = {}
    if from_date:
        params['from_date'] = from_date
    if to_date:
        params['to_date'] = to_date

    response = requests.get(f"{API_BASE_URL}/users/{user_id}/events", params=params)
    events = handle_response(response)

    table = Table(title=f"Eventos del Usuario #{user_id}")
    table.add_column("ID", style="cyan", justify="right")
    table.add_column("Nombre", style="magenta")
    table.add_column("Fecha Inicio", style="green")
    table.add_column("Fecha Fin", style="yellow")
    table.add_column("Tipo", style="blue")
    table.add_column("Owner ID", style="red", justify="right")

    for event in events:
        start = datetime.fromisoformat(event['start_date'].replace('Z', '+00:00'))
        end = datetime.fromisoformat(event['end_date'].replace('Z', '+00:00')) if event.get('end_date') else None

        table.add_row(
            str(event['id']),
            event['name'],
            start.strftime("%Y-%m-%d %H:%M"),
            end.strftime("%Y-%m-%d %H:%M") if end else '-',
            event['event_type'],
            str(event['owner_id'])
        )

    console.print(table)
    console.print(f"\n[cyan]Total de eventos: {len(events)}[/cyan]")


@events_app.command("get")
def get_event(event_id: int):
    """Obtiene información detallada de un evento"""
    response = requests.get(f"{API_BASE_URL}/events/{event_id}")
    event = handle_response(response)

    rprint(f"\n[bold cyan]Evento #{event['id']}[/bold cyan]")
    rprint(f"[yellow]Nombre:[/yellow] {event['name']}")
    rprint(f"[yellow]Descripción:[/yellow] {event.get('description', '-')}")

    start = datetime.fromisoformat(event['start_date'].replace('Z', '+00:00'))
    rprint(f"[yellow]Inicio:[/yellow] {start.strftime('%Y-%m-%d %H:%M')}")

    if event.get('end_date'):
        end = datetime.fromisoformat(event['end_date'].replace('Z', '+00:00'))
        rprint(f"[yellow]Fin:[/yellow] {end.strftime('%Y-%m-%d %H:%M')}")

    rprint(f"[yellow]Tipo:[/yellow] {event['event_type']}")
    rprint(f"[yellow]Owner ID:[/yellow] {event['owner_id']}")

    if event.get('calendar_id'):
        rprint(f"[yellow]Calendario ID:[/yellow] {event['calendar_id']}")

    if event.get('parent_recurring_event_id'):
        rprint(f"[yellow]Evento Recurrente Padre ID:[/yellow] {event['parent_recurring_event_id']}")

    rprint()


@events_app.command("create")
def create_event(
    name: str = typer.Option(..., "--name", "-n", help="Nombre del evento"),
    owner_id: int = typer.Option(..., "--owner", "-o", help="ID del propietario del evento"),
    start: str = typer.Option(..., "--start", "-s", help="Fecha y hora de inicio (YYYY-MM-DD HH:MM)"),
    end: Optional[str] = typer.Option(None, "--end", "-e", help="Fecha y hora de fin (YYYY-MM-DD HH:MM)"),
    description: Optional[str] = typer.Option(None, "--desc", "-d", help="Descripción del evento"),
    calendar_id: Optional[int] = typer.Option(None, "--calendar", "-c", help="ID del calendario"),
):
    """Crea un nuevo evento"""
    try:
        start_date = date_parser.parse(start)
        end_date = date_parser.parse(end) if end else None
    except Exception as e:
        console.print(f"❌ Error al parsear fechas: {e}", style="bold red")
        raise typer.Exit(code=1)

    data = {
        "name": name,
        "owner_id": owner_id,
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat() if end_date else None,
        "description": description,
        "calendar_id": calendar_id,
        "event_type": "regular"
    }

    response = requests.post(f"{API_BASE_URL}/events", json=data)
    event = handle_response(response, f"Evento '{name}' creado correctamente")

    rprint(f"[green]ID del nuevo evento: {event['id']}[/green]")


@events_app.command("delete")
def delete_event(
    event_id: int = typer.Argument(..., help="ID del evento a eliminar"),
    yes: bool = typer.Option(False, "--yes", "-y", help="Confirmar sin preguntar")
):
    """Elimina un evento"""
    if not yes:
        confirm = typer.confirm(f"¿Estás seguro de eliminar el evento #{event_id}?")
        if not confirm:
            raise typer.Abort()

    response = requests.delete(f"{API_BASE_URL}/events/{event_id}")
    handle_response(response, f"Evento #{event_id} eliminado correctamente")


# ==================== CALENDARS COMMANDS ====================

@calendars_app.command("list")
def list_calendars():
    """Lista todos los calendarios"""
    response = requests.get(f"{API_BASE_URL}/calendars")
    calendars = handle_response(response)

    table = Table(title="Calendarios")
    table.add_column("ID", style="cyan", justify="right")
    table.add_column("Nombre", style="magenta")
    table.add_column("Descripción", style="green")
    table.add_column("Owner ID", style="yellow", justify="right")
    table.add_column("Cumpleaños", style="blue")

    for cal in calendars:
        table.add_row(
            str(cal['id']),
            cal['name'],
            cal.get('description', '-'),
            str(cal.get('user_id', '-')),  # API usa 'user_id' no 'owner_id'
            "Sí" if cal.get('is_private_birthdays') else "No"
        )

    console.print(table)


@calendars_app.command("get")
def get_calendar(calendar_id: int):
    """Obtiene información detallada de un calendario"""
    response = requests.get(f"{API_BASE_URL}/calendars/{calendar_id}")
    calendar = handle_response(response)

    rprint(f"\n[bold cyan]Calendario #{calendar['id']}[/bold cyan]")
    rprint(f"[yellow]Nombre:[/yellow] {calendar['name']}")
    rprint(f"[yellow]Descripción:[/yellow] {calendar.get('description', '-')}")
    rprint(f"[yellow]User ID:[/yellow] {calendar.get('user_id', '-')}")  # API usa 'user_id'
    rprint(f"[yellow]Calendario de Cumpleaños:[/yellow] {'Sí' if calendar.get('is_private_birthdays') else 'No'}")
    rprint()


@calendars_app.command("create")
def create_calendar(
    name: str = typer.Option(..., "--name", "-n", help="Nombre del calendario"),
    owner_id: int = typer.Option(..., "--owner", "-o", help="ID del propietario del calendario"),
    description: Optional[str] = typer.Option(None, "--desc", "-d", help="Descripción del calendario"),
    is_birthdays: bool = typer.Option(False, "--birthdays", help="Es calendario de cumpleaños privado")
):
    """Crea un nuevo calendario"""
    data = {
        "name": name,
        "owner_id": owner_id,
        "description": description,
        "is_private_birthdays": is_birthdays
    }

    response = requests.post(f"{API_BASE_URL}/calendars", json=data)
    calendar = handle_response(response, f"Calendario '{name}' creado correctamente")

    rprint(f"[green]ID del nuevo calendario: {calendar['id']}[/green]")


@calendars_app.command("share")
def share_calendar(
    calendar_id: int = typer.Option(..., "--calendar", "-c", help="ID del calendario a compartir"),
    user_id: int = typer.Option(..., "--user", "-u", help="ID del usuario con quien compartir"),
    role: str = typer.Option("member", "--role", "-r", help="Rol del usuario (owner/admin/member)"),
    invited_by: int = typer.Option(..., "--invited-by", "-i", help="ID del usuario que invita")
):
    """Comparte un calendario con un usuario"""
    data = {
        "calendar_id": calendar_id,
        "user_id": user_id,
        "role": role,
        "invited_by_user_id": invited_by,
        "status": "pending"
    }

    response = requests.post(f"{API_BASE_URL}/calendars/memberships", json=data)
    handle_response(response, f"Calendario #{calendar_id} compartido con usuario #{user_id}")


@calendars_app.command("members")
def list_calendar_members(calendar_id: int):
    """Lista los miembros de un calendario"""
    response = requests.get(f"{API_BASE_URL}/calendars/{calendar_id}/memberships")
    memberships = handle_response(response)

    table = Table(title=f"Miembros del Calendario #{calendar_id}")
    table.add_column("User ID", style="cyan", justify="right")
    table.add_column("Rol", style="magenta")
    table.add_column("Estado", style="green")
    table.add_column("Invitado por", style="yellow", justify="right")

    for member in memberships:
        table.add_row(
            str(member['user_id']),
            member['role'],
            member['status'],
            str(member.get('invited_by_user_id', '-'))
        )

    console.print(table)


# ==================== SUBSCRIBE COMMANDS ====================

@subscribe_app.command("subscribe")
def subscribe_to_user(
    user_id: int = typer.Option(..., "--user", "-u", help="ID del usuario que se suscribe"),
    public_user_id: int = typer.Option(..., "--to", "-t", help="ID del usuario público al que suscribirse")
):
    """Suscribe a un usuario a los eventos de un usuario público"""
    # Primero obtener todos los eventos del usuario público
    response = requests.get(f"{API_BASE_URL}/users/{public_user_id}/events")
    events = handle_response(response)

    if not events:
        console.print("❌ El usuario público no tiene eventos", style="bold red")
        raise typer.Exit(code=1)

    # Crear interacciones de tipo 'subscribed' para cada evento
    subscribed_count = 0
    for event in events:
        data = {
            "event_id": event['id'],
            "user_id": user_id,
            "interaction_type": "subscribed"
        }
        try:
            response = requests.post(f"{API_BASE_URL}/event-interactions", json=data)
            if response.status_code in [200, 201]:
                subscribed_count += 1
        except:
            pass

    console.print(
        f"✅ Usuario #{user_id} suscrito a {subscribed_count} eventos del usuario #{public_user_id}",
        style="bold green"
    )


@subscribe_app.command("unsubscribe")
def unsubscribe_from_user(
    user_id: int = typer.Option(..., "--user", "-u", help="ID del usuario que se desuscribe"),
    public_user_id: int = typer.Option(..., "--de", "-f", help="ID del usuario público del que desuscribirse")
):
    """Desuscribe a un usuario de los eventos de un usuario público"""
    # Obtener eventos del usuario público
    response = requests.get(f"{API_BASE_URL}/users/{public_user_id}/events")
    events = handle_response(response)

    # Eliminar interacciones de tipo 'subscribed' para cada evento
    unsubscribed_count = 0
    for event in events:
        try:
            response = requests.delete(
                f"{API_BASE_URL}/event-interactions/{event['id']}/{user_id}"
            )
            if response.status_code in [200, 204]:
                unsubscribed_count += 1
        except:
            pass

    console.print(
        f"✅ Usuario #{user_id} desuscrito de {unsubscribed_count} eventos del usuario #{public_user_id}",
        style="bold green"
    )


# ==================== INTERACT COMMANDS ====================

@interact_app.command("invite")
def invite_to_event(
    event_id: int = typer.Option(..., "--event", "-e", help="ID del evento"),
    user_id: int = typer.Option(..., "--user", "-u", help="ID del usuario a invitar")
):
    """Invita a un usuario a un evento"""
    data = {
        "event_id": event_id,
        "user_id": user_id,
        "interaction_type": "invited"
    }

    response = requests.post(f"{API_BASE_URL}/event-interactions", json=data)
    handle_response(response, f"Usuario #{user_id} invitado al evento #{event_id}")


@interact_app.command("accept")
def accept_event(
    event_id: int = typer.Option(..., "--event", "-e", help="ID del evento"),
    user_id: int = typer.Option(..., "--user", "-u", help="ID del usuario que acepta")
):
    """Acepta una invitación a un evento"""
    # Actualizar la interacción existente a 'accepted'
    data = {
        "event_id": event_id,
        "user_id": user_id,
        "interaction_type": "accepted"
    }

    response = requests.put(
        f"{API_BASE_URL}/event-interactions/{event_id}/{user_id}",
        json=data
    )
    handle_response(response, f"Usuario #{user_id} aceptó el evento #{event_id}")


@interact_app.command("reject")
def reject_event(
    event_id: int = typer.Option(..., "--event", "-e", help="ID del evento"),
    user_id: int = typer.Option(..., "--user", "-u", help="ID del usuario que rechaza")
):
    """Rechaza una invitación a un evento"""
    # Actualizar la interacción existente a 'rejected'
    data = {
        "event_id": event_id,
        "user_id": user_id,
        "interaction_type": "rejected"
    }

    response = requests.put(
        f"{API_BASE_URL}/event-interactions/{event_id}/{user_id}",
        json=data
    )
    handle_response(response, f"Usuario #{user_id} rechazó el evento #{event_id}")


@interact_app.command("list")
def list_event_interactions(event_id: int):
    """Lista todas las interacciones de un evento"""
    response = requests.get(f"{API_BASE_URL}/events/{event_id}/interactions")
    interactions = handle_response(response)

    table = Table(title=f"Interacciones del Evento #{event_id}")
    table.add_column("User ID", style="cyan", justify="right")
    table.add_column("Tipo", style="magenta")
    table.add_column("Fecha", style="green")

    for interaction in interactions:
        table.add_row(
            str(interaction['user_id']),
            interaction['interaction_type'],
            interaction.get('created_at', '-')
        )

    console.print(table)


# ==================== MAIN APP COMMANDS ====================

@app.command("status")
def status():
    """Verifica el estado de la API"""
    try:
        response = requests.get(f"{API_BASE_URL}/")
        if response.status_code == 200:
            console.print("✅ API conectada correctamente", style="bold green")
            rprint(f"[cyan]URL:[/cyan] {API_BASE_URL}")
        else:
            console.print(f"⚠️  API respondió con código {response.status_code}", style="bold yellow")
    except requests.exceptions.ConnectionError:
        console.print(f"❌ No se pudo conectar a la API en {API_BASE_URL}", style="bold red")
        raise typer.Exit(code=1)


if __name__ == "__main__":
    app()
