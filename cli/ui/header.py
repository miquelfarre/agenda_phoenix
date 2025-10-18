from rich.panel import Panel
from .console import console
import api_client
from config import url_interactions


def show_header(modo_actual: str = None, usuario_actual: int = None, usuario_actual_info: dict = None):
    """Renderiza el encabezado de la aplicación con información del modo/usuario.

    Este método realiza llamadas ligeras a la API solo para mostrar contadores (p. ej., invitaciones pendientes).
    No contiene lógica de negocio.
    """
    header_text = "[bold cyan]🗓️  Agenda Phoenix[/bold cyan]\n"
    header_text += "[dim]Sistema de gestión de calendarios y eventos[/dim]"

    if modo_actual == "usuario" and usuario_actual_info:
        header_text += f"\n\n[yellow]👤 Modo Usuario:[/yellow] " f"{usuario_actual_info.get('username', usuario_actual_info.get('contact_name', f'Usuario #{usuario_actual}'))}"

        # Obtener contador de invitaciones pendientes (no bloqueante)
        try:
            response = api_client.get(
                url_interactions() + f"?user_id={usuario_actual}&interaction_type=invited&status=pending",
                timeout=1,
            )
            if response.status_code == 200:
                pending_invitations = len(response.json())
                if pending_invitations > 0:
                    header_text += f"\n[magenta]📨 {pending_invitations} invitación" f"{'es' if pending_invitations != 1 else ''} pendiente" f"{'s' if pending_invitations != 1 else ''}[/magenta]"
        except Exception:
            pass  # si falla, simplemente no mostramos el contador

    elif modo_actual == "backoffice":
        header_text += "\n\n[green]🔧 Modo Backoffice[/green]"

    console.print(Panel.fit(header_text, border_style="cyan"))
    console.print()
