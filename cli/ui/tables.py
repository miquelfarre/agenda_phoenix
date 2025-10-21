from rich.table import Table
from .console import console
from datetime import datetime


def truncate_text(text: str, max_length: int) -> str:
    if not text:
        return "-"
    if len(text) <= max_length:
        return text
    return text[: max_length - 3] + "..."


def format_datetime(date_str):
    """Format ISO datetime string to 'YYYY-MM-DD HH:MM'"""
    if not date_str:
        return "-"
    try:
        # Parse ISO format datetime
        dt = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
        return dt.strftime("%Y-%m-%d %H:%M")
    except:
        # If parsing fails, return as-is
        return str(date_str)


def format_count_message(count: int, singular: str, plural: str) -> str:
    return f"{count} {singular if count == 1 else plural}"


def show_pagination_info(displayed: int, total: int) -> None:
    if total > displayed:
        console.print(f"\n[dim]Mostrando {displayed} de {total}[/dim]")


def create_events_table(events, title="Events", current_user_id=None, max_rows=30):
    table = Table(title=title, show_header=True, header_style="bold magenta")
    table.add_column("ID", style="cyan", justify="right", width=5)
    table.add_column("Nombre", style="green", width=35)
    table.add_column("Fecha Inicio", style="yellow", width=18)
    table.add_column("Origen", style="blue", width=12)

    if current_user_id:
        table.add_column("Propietario", style="magenta", width=12)

    for event in events[:max_rows]:
        # Calculate source: owned if no interaction, otherwise use interaction type
        if event.get("interaction"):
            source = event["interaction"].get("interaction_type", "regular")
        else:
            source = "owned"

        row = [
            str(event["id"]),
            truncate_text(event["name"], 33),
            format_datetime(event.get("start_date")),
            source,
        ]
        if current_user_id:
            # Show owner_id (client can fetch username separately if needed)
            row.append(f"Usuario #{event.get('owner_id', '?')}")
        table.add_row(*row)
    return table


def create_conflicts_table(conflicts):
    table = Table(show_header=True, header_style="bold yellow")
    table.add_column("Evento", style="yellow", width=30)
    table.add_column("Fecha", style="cyan", width=18)
    for conf in conflicts[:5]:
        table.add_row(
            truncate_text(conf["name"], 28),
            format_datetime(conf.get("start_date")),
        )
    return table


# Note: Invitations and calendars tables previously lived here; removed as unused.
