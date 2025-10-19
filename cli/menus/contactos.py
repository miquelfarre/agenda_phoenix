"""
Menu de gestion de contactos (Backoffice)
"""
import questionary
import api_client
from rich.panel import Panel

from ui.console import console, custom_style, clear_screen
from config import url_contacts, url_contact


def menu_contactos_backoffice(_show_header_wrapper, handle_api_error, pause):
    """Menu de gestion de contactos (solo Backoffice)"""
    while True:
        clear_screen()
        _show_header_wrapper()

        choice = questionary.select(
            "Gestion de Contactos - Que deseas hacer?",
            choices=[
                "Ver todos los contactos",
                "Ver detalles de un contacto",
                "Crear nuevo contacto",
                "Volver al menu principal",
            ],
            style=custom_style,
        ).ask()

        if choice == "Ver todos los contactos":
            listar_contactos_backoffice(_show_header_wrapper, handle_api_error, pause)
        elif choice == "Ver detalles de un contacto":
            ver_contacto_backoffice(_show_header_wrapper, handle_api_error, pause)
        elif choice == "Crear nuevo contacto":
            crear_contacto_backoffice(_show_header_wrapper, handle_api_error, pause)
        elif choice == "Volver al menu principal":
            break


def listar_contactos_backoffice(_show_header_wrapper, handle_api_error, pause):
    """Lista todos los contactos (Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    console.print("[cyan]Consultando contactos...[/cyan]\n")

    response = api_client.get(url_contacts())
    contacts = handle_api_error(response)

    if not contacts:
        pause()
        return


def ver_contacto_backoffice(_show_header_wrapper, handle_api_error, pause):
    """Muestra detalles de un contacto (Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    contact_id = questionary.text(
        "Ingresa el ID del contacto:",
        validate=lambda text: text.isdigit() or "Debe ser un numero",
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
    info += f"[yellow]Telefono:[/yellow] {contact.get('phone', '-')}\n"
    info += f"[yellow]Creado:[/yellow] {contact.get('created_at', '-') }"

    console.print(Panel(info, title=f"[bold cyan]Contacto #{contact['id']}[/bold cyan]", border_style="cyan"))
    console.print()
    pause()


def crear_contacto_backoffice(_show_header_wrapper, handle_api_error, pause):
    """Crea un nuevo contacto (Backoffice)"""
    clear_screen()
    _show_header_wrapper()

    console.print("[bold cyan]Crear Nuevo Contacto[/bold cyan]\n")

    name = questionary.text("Nombre del contacto:", validate=lambda text: len(text) > 0 or "No puede estar vacio").ask()

    if not name:
        return

    phone = questionary.text("Telefono (formato: +34XXXXXXXXX):", validate=lambda text: len(text) > 0 or "No puede estar vacio").ask()

    if not phone:
        return

    data = {"name": name, "phone": phone}

    console.print("\n[cyan]Creando contacto...[/cyan]\n")
    response = api_client.post(url_contacts(), json=data)
    contact = handle_api_error(response)

    if contact:
        console.print(f"[bold green]Contacto '{name}' creado exitosamente con ID: {contact['id']}[/bold green]\n")

    pause()
