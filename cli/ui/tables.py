from rich.table import Table
from .console import console


def truncate_text(text: str, max_length: int) -> str:
    if not text:
        return "-"
    if len(text) <= max_length:
        return text
    return text[: max_length - 3] + "..."


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
        row = [
            str(event["id"]),
            truncate_text(event["name"], 33),
            event.get("start_date_formatted", event.get("start_date", "-")),
            event.get("source", event.get("event_type", "regular")),
        ]
        if current_user_id:
            row.append(event.get("owner_display", f"Usuario #{event.get('owner_id', '?')}"))
        table.add_row(*row)
    return table


def create_conflicts_table(conflicts):
    table = Table(show_header=True, header_style="bold yellow")
    table.add_column("Evento", style="yellow", width=30)
    table.add_column("Fecha", style="cyan", width=18)
    for conf in conflicts[:5]:
        table.add_row(
            truncate_text(conf["name"], 28),
            conf.get("start_date_formatted", conf.get("start_date", "-")),
        )
    return table


# Note: Invitations and calendars tables previously lived here; removed as unused.
