#!/usr/bin/env python3
"""
CLI Utility Functions - Agenda Phoenix

Common functions for display, API calls, and user interaction.
Extracted to avoid code duplication and follow DRY principle.
"""
from rich.console import Console
from rich.table import Table
from datetime import datetime
from typing import List, Dict, Optional, Any

console = Console()


def format_datetime(dt_str: str, format: str = "%Y-%m-%d %H:%M") -> str:
    """
    Format an ISO datetime string to a readable format.

    Args:
        dt_str: ISO format datetime string
        format: Python datetime format string

    Returns:
        Formatted datetime string
    """
    try:
        dt = datetime.fromisoformat(dt_str.replace('Z', '+00:00'))
        return dt.strftime(format)
    except:
        return dt_str


def truncate_text(text: str, max_length: int) -> str:
    """
    Truncate text to max length and add ellipsis if needed.

    Args:
        text: Text to truncate
        max_length: Maximum length before truncation

    Returns:
        Truncated text with "..." if needed
    """
    if not text:
        return "-"
    if len(text) <= max_length:
        return text
    return text[:max_length - 3] + "..."


def create_events_table(
    events: List[Dict[str, Any]],
    title: str = "Events",
    current_user_id: Optional[int] = None,
    max_rows: int = 30
) -> Table:
    """
    Create a standardized events table.

    Args:
        events: List of event dictionaries from API
        title: Table title
        current_user_id: Current user ID to show ownership
        max_rows: Maximum rows to display

    Returns:
        Rich Table object ready to print
    """
    table = Table(title=title, show_header=True, header_style="bold magenta")
    table.add_column("ID", style="cyan", justify="right", width=5)
    table.add_column("Nombre", style="green", width=35)
    table.add_column("Fecha Inicio", style="yellow", width=18)
    table.add_column("Origen", style="blue", width=12)

    if current_user_id:
        table.add_column("Propietario", style="magenta", width=12)

    for event in events[:max_rows]:
        owner_text = None
        if current_user_id:
            is_owner = event.get('owner_id') == current_user_id
            owner_text = "Yo" if is_owner else f"Usuario #{event['owner_id']}"

        # Use 'source' field if available, otherwise fall back to event_type
        origin = event.get('source', event.get('event_type', 'regular'))

        row = [
            str(event['id']),
            truncate_text(event['name'], 33),
            format_datetime(event['start_date']),
            origin
        ]

        if owner_text:
            row.append(owner_text)

        table.add_row(*row)

    return table


def create_invitations_table(
    invitations: List[Dict[str, Any]],
    events_map: Dict[int, Dict[str, Any]],
    title: str = "Invitaciones"
) -> Table:
    """
    Create a standardized invitations table.

    Args:
        invitations: List of invitation dictionaries from API
        events_map: Mapping of event_id to event data
        title: Table title

    Returns:
        Rich Table object ready to print
    """
    table = Table(title=title, show_header=True, header_style="bold magenta")
    table.add_column("ID Inv", style="cyan", justify="right", width=7)
    table.add_column("Evento", style="green", width=30)
    table.add_column("Fecha", style="yellow", width=18)
    table.add_column("Invitado por", style="blue", justify="right", width=13)

    for inv in invitations:
        event = events_map.get(inv['event_id'])
        if event:
            table.add_row(
                str(inv['id']),
                truncate_text(event['name'], 28),
                format_datetime(event['start_date']),
                f"Usuario #{inv.get('invited_by_user_id', '?')}"
            )

    return table


def create_calendars_table(
    calendars: List[Dict[str, Any]],
    title: str = "Calendarios",
    include_user_column: bool = False
) -> Table:
    """
    Create a standardized calendars table.

    Args:
        calendars: List of calendar dictionaries from API
        title: Table title
        include_user_column: Whether to include user_id column

    Returns:
        Rich Table object ready to print
    """
    table = Table(title=title, show_header=True, header_style="bold magenta")
    table.add_column("ID", style="cyan", justify="right", width=5)
    table.add_column("Nombre", style="green", width=25)
    table.add_column("Descripción", style="yellow", width=30)
    table.add_column("Tipo", style="magenta", width=12)

    if include_user_column:
        table.add_column("User ID", style="blue", justify="right", width=8)

    for cal in calendars:
        tipo = "Cumpleaños" if cal.get('is_private_birthdays') else "Normal"

        row = [
            str(cal['id']),
            cal['name'],
            truncate_text(cal.get('description', '-'), 28),
            tipo
        ]

        if include_user_column:
            row.append(str(cal.get('user_id', '-')))

        table.add_row(*row)

    return table


def create_conflicts_table(conflicts: List[Dict[str, Any]]) -> Table:
    """
    Create a table showing event conflicts.

    Args:
        conflicts: List of conflicting events

    Returns:
        Rich Table object ready to print
    """
    table = Table(show_header=True, header_style="bold yellow")
    table.add_column("Evento", style="yellow", width=30)
    table.add_column("Fecha", style="cyan", width=18)

    for conf in conflicts[:5]:  # Show max 5 conflicts
        table.add_row(
            truncate_text(conf['name'], 28),
            format_datetime(conf['start_date'])
        )

    return table


def format_count_message(count: int, singular: str, plural: str) -> str:
    """
    Format a count message with proper singular/plural.

    Args:
        count: The count number
        singular: Singular form of the noun
        plural: Plural form of the noun

    Returns:
        Formatted message

    Examples:
        >>> format_count_message(1, "evento", "eventos")
        "1 evento"
        >>> format_count_message(5, "evento", "eventos")
        "5 eventos"
    """
    word = singular if count == 1 else plural
    return f"{count} {word}"


def get_user_display_name(user_info: Dict[str, Any]) -> str:
    """
    Get a display name for a user from their info.

    Args:
        user_info: User information dict

    Returns:
        Display name (username or contact_name or ID)
    """
    if user_info.get('username'):
        return user_info['username']
    if user_info.get('contact_name'):
        return user_info['contact_name']
    return f"Usuario #{user_info.get('id', '?')}"


def show_pagination_info(displayed: int, total: int):
    """
    Show pagination information if results are truncated.

    Args:
        displayed: Number of items displayed
        total: Total number of items
    """
    if total > displayed:
        console.print(f"\n[dim]Mostrando {displayed} de {total}[/dim]")
