# REDISEÑO DEL SISTEMA DE USUARIOS Y CONTACTOS - PROGRESO

## 📋 ESTADO ACTUAL - ACTUALIZADO

### ✅ BACKEND COMPLETADO (6 de 13 tareas)

#### 1. ✅ Backend - Modelos (models.py)
- ✅ Creado nuevo modelo `UserContact` con todos los campos necesarios
- ✅ Actualizado modelo `User` con nuevos campos:
  - `display_name` (REQUIRED)
  - `phone` (unique, nullable)
  - `instagram_username` (unique, nullable)
  - `profile_picture_url`
- ✅ Mantenidos campos legacy para retrocompatibilidad
- ✅ Agregadas relaciones `my_contacts` y `contact_entries`

#### 2. ✅ Backend - Schemas (schemas.py)
- ✅ Creados schemas para UserContact:
  - `UserContactBase`
  - `UserContactCreate`
  - `UserContactSync`
  - `UserContactResponse`
  - `UserContactSyncResponse`
- ✅ Actualizados schemas de User con nuevos campos

#### 3. ✅ Backend - CRUD (crud/crud_user_contact.py)
- ✅ Creado CRUD completo para UserContact:
  - `get_by_owner()` - Obtener contactos de un usuario
  - `get_by_phone()` - Buscar contacto por teléfono
  - `sync_contacts()` - Sincronizar contactos del dispositivo
  - `update_registered_user_for_phone()` - Actualizar cuando usuario se registra
- ✅ Actualizado `crud/__init__.py` para exportar `user_contact`
- ✅ Actualizado `crud/crud_user.py` método `get_multi_with_optional_enrichment()`:
  - Eliminados JOINs con Contact legacy
  - Usa nuevos campos directamente

#### 4. ✅ Backend - Router Contacts (routers/contacts.py)
- ✅ **COMPLETAMENTE REESCRITO** con nuevos endpoints:
  - `POST /api/v1/contacts/sync` - Sincronizar contactos del dispositivo
  - `GET /api/v1/contacts` - Obtener mis contactos (con filtro only_registered)
  - `POST /api/v1/contacts/webhook/user-registered` - Webhook para vincular usuarios
- ✅ Todos los endpoints requieren autenticación
- ✅ Logging completo para debugging
- ✅ Documentación detallada con ejemplos

#### 5. ✅ Backend - Router Users (routers/users.py)
- ✅ Actualizado `GET /users/me` - Usa nuevos campos
- ✅ Actualizado `GET /users/{user_id}` - Usa nuevos campos
- ✅ Actualizado `GET /users/{user_id}/events`:
  - Eliminado JOIN con Contact en owner_info
  - Eliminado JOIN con Contact en attendees
  - Usa `display_name` y `profile_picture_url`

#### 6. ✅ Backend - Init DB (init_db.py)
- ✅ Eliminada creación de Contact legacy
- ✅ Usuarios creados directamente con `display_name`, `phone`, `instagram_username`
- ✅ Agregado import de `UserContact`
- ✅ Comentario explicativo: UserContacts se crean al sincronizar

---

## 🔨 TAREAS PENDIENTES (7 de 13 tareas)

### Backend

#### 4. Router de Contacts (routers/contacts.py)
**Archivo**: `/backend/routers/contacts.py`

**Acción**: Reemplazar completamente con los nuevos endpoints:

```python
"""
User Contacts Router

Handles contact syncing and retrieval.
"""

import logging
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user_id
from crud import user_contact
from dependencies import get_db
from schemas import UserContactResponse, UserContactSync, UserContactSyncResponse

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/contacts", tags=["contacts"])


@router.post("/sync", response_model=UserContactSyncResponse)
async def sync_contacts(
    sync_data: UserContactSync,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Sincronizar contactos del dispositivo.

    Este endpoint:
    1. Recibe lista de contactos del dispositivo
    2. Crea/actualiza UserContact para cada uno
    3. Busca cuáles están registrados
    4. Retorna lista de contactos registrados
    """
    result = user_contact.sync_contacts(
        db,
        owner_id=current_user_id,
        contacts=sync_data.contacts
    )
    return result


@router.get("", response_model=List[UserContactResponse])
async def get_my_contacts(
    only_registered: bool = True,
    limit: int = 100,
    skip: int = 0,
    current_user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Obtener mis contactos.

    Por defecto solo retorna contactos que usan la app.
    """
    contacts = user_contact.get_by_owner(
        db,
        owner_id=current_user_id,
        only_registered=only_registered,
        skip=skip,
        limit=limit
    )

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

    return result


@router.post("/webhook/user-registered")
async def webhook_user_registered(
    user_id: int,
    phone: str,
    db: Session = Depends(get_db)
):
    """
    Webhook llamado cuando un usuario se registra.

    Actualiza todos los UserContact con ese teléfono.
    """
    updated_count = user_contact.update_registered_user_for_phone(
        db,
        phone_number=phone,
        user_id=user_id
    )

    logger.info(f"✅ Linked {updated_count} contacts to new user {user_id} (phone: {phone})")

    return {"updated_contacts": updated_count}
```

#### 5. Router de Users - Actualizar GET /users
**Archivo**: `/backend/routers/users.py`

**Problema actual** (línea 29-45): El endpoint GET `/users` retorna usuarios con `enriched=True` que usa la tabla `Contact` legacy.

**Acción**: Actualizar para usar nuevos campos:
- Cambiar `contact.name` por `user.display_name`
- Eliminar lógica que hace JOIN con `contacts`
- Simplificar para solo retornar campos del User

#### 6. Tests
**Archivo nuevo**: `/backend/tests/test_user_contacts.py`

Crear tests para:
- POST `/contacts/sync` - Sincronización
- GET `/contacts` - Obtener contactos
- Webhook de registro

#### 7. Init DB - Actualizar datos de prueba
**Archivo**: `/backend/init_db.py`

**Cambios necesarios** (línea 466-574):
1. Eliminar creación de Contact legacy
2. Crear usuarios directamente con `display_name`
3. NO crear UserContacts en init (se sincronizarán desde la app)

**Ejemplo**:
```python
# ANTES (línea 467-476)
contact_sonia = Contact(name="Sonia", phone="+34606014680")
db.add(contact_sonia)
db.flush()

sonia = User(contact_id=contact_sonia.id, name=contact_sonia.name, ...)

# DESPUÉS
sonia = User(
    display_name="Sonia",
    phone="+34606014680",
    auth_provider="phone",
    auth_id="+34606014680",
    is_public=False,
    last_login=now,
)
```

### Flutter App

#### 8. Modelos
**Archivo**: `/app_flutter/lib/models/user.dart` (o similar)

Actualizar modelo User para incluir nuevos campos:
```dart
class User {
  final int id;
  final String displayName;  // NUEVO - REQUIRED
  final String? phone;
  final String? instagramUsername;  // NUEVO
  final String? profilePictureUrl;  // NUEVO
  // ... resto de campos
}
```

Crear nuevo modelo `UserContact`:
```dart
class UserContact {
  final int id;
  final int ownerId;
  final String contactName;
  final String phoneNumber;
  final int? registeredUserId;
  final bool isRegistered;
  final RegisteredUser? registeredUser;
  // ...
}
```

#### 9. ApiClient
**Archivo**: `/app_flutter/lib/services/api_client.dart`

Reemplazar métodos (líneas 356-374):
```dart
// ELIMINAR
Future<List<Map<String, dynamic>>> fetchContacts({
  required int currentUserId,
}) async {
  final result = await get('/users?public=false&enriched=true&exclude_user_id=$currentUserId');
  return List<Map<String, dynamic>>.from(result);
}

// AGREGAR
Future<Map<String, dynamic>> syncContacts({
  required int currentUserId,
  required List<Map<String, String>> contacts,
}) async {
  final result = await post('/contacts/sync', {
    'contacts': contacts,
  });
  return result as Map<String, dynamic>;
}

Future<List<Map<String, dynamic>>> fetchMyContacts({
  required int currentUserId,
  bool onlyRegistered = true,
}) async {
  final result = await get('/contacts?only_registered=$onlyRegistered');
  return List<Map<String, dynamic>>.from(result);
}
```

#### 10. Repositories
**Archivo**: `/app_flutter/lib/repositories/user_repository.dart`

Actualizar método `fetchContacts` (línea 219-221):
```dart
// ANTES
Future<List<models.User>> fetchContacts(int userId) async {
  final contactsData = await _apiClient.fetchContacts(currentUserId: userId);
  return contactsData.map((data) => models.User.fromJson(data)).toList();
}

// DESPUÉS
Future<List<UserContact>> fetchMyContacts(int userId) async {
  final contactsData = await _apiClient.fetchMyContacts(currentUserId: userId);
  return contactsData.map((data) => UserContact.fromJson(data)).toList();
}

Future<SyncResult> syncDeviceContacts(int userId, List<Contact> deviceContacts) async {
  final contactsToSync = deviceContacts.map((c) => {
    'contact_name': c.name,
    'phone_number': c.phoneNumber,
  }).toList();

  final result = await _apiClient.syncContacts(
    currentUserId: userId,
    contacts: contactsToSync,
  );

  return SyncResult.fromJson(result);
}
```

#### 11. Screens
**Archivos**:
- `/app_flutter/lib/screens/people_groups_screen.dart` (línea 76)
- `/app_flutter/lib/screens/add_group_members_screen.dart` (línea 51)

Actualizar para usar nuevo método `fetchMyContacts()` en lugar de `fetchContacts()`.

### Migración

#### 12. Script de Migración
**Archivo nuevo**: `/backend/migrate_contacts.py`

Crear script que:
1. Copia datos de `users.name` → `users.display_name` (si NULL)
2. Copia `users.instagram_name` → `users.instagram_username` (si NULL)
3. Copia `users.profile_picture` → `users.profile_picture_url` (si NULL)
4. NO migra tabla `contacts` (los usuarios tendrán que resincronizar)

```python
def migrate():
    db = SessionLocal()

    # Actualizar usuarios existentes
    users = db.query(User).all()
    for user in users:
        if not user.display_name:
            # Si era phone user con contact, usar contact.name
            if user.contact_id:
                old_contact = db.query(Contact).filter(Contact.id == user.contact_id).first()
                if old_contact:
                    user.display_name = old_contact.name
            # Si era instagram user, usar instagram_name
            elif user.instagram_name:
                user.display_name = user.instagram_name
            else:
                user.display_name = f"Usuario #{user.id}"

        # Migrar otros campos
        if not user.instagram_username and user.instagram_name:
            user.instagram_username = user.instagram_name

        if not user.profile_picture_url and user.profile_picture:
            user.profile_picture_url = user.profile_picture

    db.commit()
    print("✅ Migration completed")
```

---

## 📝 DOCUMENTACIÓN

#### 13. Documento de Arquitectura
**Archivo nuevo**: `/docs/CONTACT_SYSTEM_ARCHITECTURE.md`

Documentar:
- Flujo completo de sincronización
- Diagrama de modelos
- Casos de uso
- Ejemplos de API calls

---

## 🚀 ORDEN DE IMPLEMENTACIÓN RECOMENDADO

1. **Backend Router** - Actualizar `/routers/contacts.py`
2. **Backend Router** - Actualizar GET `/users` en `/routers/users.py`
3. **Backend Init** - Actualizar `init_db.py`
4. **Test Backend** - Ejecutar `python init_db.py` y verificar
5. **Script Migración** - Crear y probar `migrate_contacts.py`
6. **Flutter Modelos** - Actualizar modelos
7. **Flutter ApiClient** - Actualizar métodos
8. **Flutter Repos** - Actualizar repositories
9. **Flutter Screens** - Actualizar pantallas
10. **Tests** - Crear tests para endpoints
11. **Documentación** - Crear docs

---

## ⚠️ NOTAS IMPORTANTES

### Compatibilidad Retroactiva
- Los modelos mantienen campos legacy (contact_id, name, instagram_name, profile_picture)
- La tabla `contacts` legacy se mantiene temporalmente
- Endpoints legacy de `/contacts` pueden eliminarse o marcarse como deprecated

### Seguridad
- Todos los endpoints requieren autenticación (JWT)
- Los contactos están aislados por owner_id
- No hay posibilidad de leak entre usuarios

### Performance
- Sync de contactos usa 1 query para buscar usuarios registrados
- Índices creados en phone_number, owner_id, registered_user_id

---

## 📞 SIGUIENTES PASOS

**Para continuar el rediseño:**

1. Implementar router de contacts (tarea #4)
2. Actualizar router de users (tarea #5)
3. Actualizar init_db.py (tarea #7)
4. Probar backend con `python init_db.py`
5. Continuar con Flutter

**Comando para reiniciar DB y probar:**
```bash
cd backend
python init_db.py
```

**Verificar que funciona:**
```bash
# Debe crear tabla user_contacts
# Debe crear usuarios con display_name
```
