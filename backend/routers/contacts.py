"""
User Contacts Router

Handles contact syncing and retrieval for the new UserContact system.
"""

import logging
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user_id
from crud import user_contact
from dependencies import get_db
import schemas
from schemas import UserContactResponse, UserContactSync, UserContactSyncResponse

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/contacts", tags=["contacts"])


@router.post("/sync", response_model=UserContactSyncResponse)
async def sync_contacts(sync_data: UserContactSync, current_user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """
    Sincronizar contactos del dispositivo.

    Este endpoint:
    1. Recibe lista de contactos del dispositivo del usuario
    2. Para cada contacto:
       - Si ya existe (mismo owner_id + phone), actualiza nombre y timestamp
       - Si no existe, crea nuevo UserContact
    3. Busca si algún teléfono está registrado (existe en users.phone)
    4. Actualiza registered_user_id para los que están registrados
    5. Retorna lista de contactos que están registrados en la app

    Seguridad:
    - Requiere autenticación (JWT)
    - Solo sincroniza contactos del usuario autenticado
    - Solo retorna info mínima de usuarios registrados

    Example request:
    ```json
    {
      "contacts": [
        {"contact_name": "Juan", "phone_number": "+34666777888"},
        {"contact_name": "María", "phone_number": "+34611223344"}
      ]
    }
    ```

    Example response:
    ```json
    {
      "synced_count": 2,
      "registered_count": 1,
      "registered_contacts": [
        {
          "user_id": 5,
          "display_name": "Juan García",
          "phone": "+34666777888",
          "profile_picture_url": "https://...",
          "contact_name": "Juan"
        }
      ]
    }
    ```
    """
    logger.info(f"📱 [Sync] User {current_user_id} syncing {len(sync_data.contacts)} contacts")

    result = user_contact.sync_contacts(db, owner_id=current_user_id, contacts=sync_data.contacts)

    logger.info(f"✅ [Sync] User {current_user_id}: synced={result['synced_count']}, " f"registered={result['registered_count']}")

    return result


@router.get("", response_model=List[UserContactResponse])
async def get_my_contacts(only_registered: bool = True, limit: int = 100, skip: int = 0, current_user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    """
    Obtener lista de contactos del usuario autenticado.

    Por defecto, solo retorna contactos que están registrados en la app.

    Seguridad:
    - Requiere autenticación
    - Solo retorna contactos del usuario autenticado (owner_id)

    Query params:
    - only_registered: Si True, solo retorna contactos registrados (default: True)
    - limit: Máximo de contactos a retornar (default: 100, max: 200)
    - skip: Número de contactos a saltar para paginación (default: 0)

    Example response:
    ```json
    [
      {
        "id": 1,
        "owner_id": 3,
        "contact_name": "Juan",
        "phone_number": "+34666777888",
        "registered_user_id": 5,
        "is_registered": true,
        "last_synced_at": "2025-01-15T10:30:00Z",
        "created_at": "2025-01-10T08:00:00Z",
        "updated_at": "2025-01-15T10:30:00Z",
        "registered_user": {
          "id": 5,
          "display_name": "Juan García",
          "profile_picture_url": "https://..."
        }
      }
    ]
    ```
    """
    # Validate pagination
    limit = max(1, min(200, limit))
    skip = max(0, skip)

    logger.info(f"📋 [Get Contacts] User {current_user_id}: only_registered={only_registered}, " f"limit={limit}, skip={skip}")

    contacts = user_contact.get_by_owner(db, owner_id=current_user_id, only_registered=only_registered, skip=skip, limit=limit)

    # Enriquecer con datos del usuario registrado
    result = []
    for contact in contacts:
        contact_dict = {
            "id": contact.id,
            "owner_id": contact.owner_id,
            "contact_name": contact.contact_name,
            "phone_number": contact.phone_number,
            "registered_user_id": contact.registered_user_id,
            "is_registered": contact.registered_user_id is not None,
            "last_synced_at": contact.last_synced_at,
            "created_at": contact.created_at,
            "updated_at": contact.updated_at,
        }

        if contact.registered_user:
            contact_dict["registered_user"] = {
                "id": contact.registered_user.id,
                "display_name": contact.registered_user.display_name,
                "profile_picture_url": contact.registered_user.profile_picture_url,
            }

        result.append(contact_dict)

    logger.info(f"✅ [Get Contacts] User {current_user_id}: returning {len(result)} contacts")

    return result


@router.post("/webhook/user-registered")
async def webhook_user_registered(webhook_data: schemas.WebhookUserRegistered, db: Session = Depends(get_db)):
    """
    Webhook llamado cuando un usuario se registra con phone auth.

    Este webhook:
    1. Busca todos los UserContact con ese teléfono
    2. Actualiza registered_user_id para vincularlos al nuevo usuario
    3. Ahora todos los usuarios que tienen ese número ven que está registrado

    Flujo:
    - Usuario nuevo se registra con phone +34666
    - Este webhook se ejecuta
    - Busca todos los UserContact con phone_number = +34666
    - Actualiza registered_user_id = nuevo_user_id
    - Ahora todos los usuarios que tienen ese número ven que está registrado

    Note: Este endpoint normalmente sería llamado por el sistema de autenticación
    (ej: Supabase webhook, Firebase webhook, etc.)

    Example request:
    ```json
    {
      "user_id": 5,
      "phone": "+34666777888"
    }
    ```

    Example response:
    ```json
    {
      "updated_contacts": 3
    }
    ```
    """
    logger.info(f"🔔 [Webhook] New user registered: user_id={webhook_data.user_id}, phone={webhook_data.phone}")

    updated_count = user_contact.update_registered_user_for_phone(db, phone_number=webhook_data.phone, user_id=webhook_data.user_id)

    logger.info(f"✅ [Webhook] Linked {updated_count} contacts to user {webhook_data.user_id} (phone: {webhook_data.phone})")

    return {"updated_contacts": updated_count}
