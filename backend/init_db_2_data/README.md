# Init DB 2 - Sistema Completo de Datos de Prueba

## Usuario por Defecto

**USER_ID=1: Sonia Martínez** (`+34600000001`)
- Usuario privado que inicia la aplicación por defecto en `start.sh`
- `USER_ID=${USER_ID:-1}` en start.sh

---

## Archivos Creados ✅

### 1. `helpers.py` ✅
Funciones auxiliares, generadores, fechas de referencia, nombres.

### 2. `users_private.py` ✅
**85 usuarios privados (ID 1-85)** organizados en:
- **ID 1-10**: Familia de Sonia (Sonia, Miquel, Ada, Sara + familia)
- **ID 11-30**: Amigos cercanos (20 usuarios)
- **ID 31-60**: Conocidos y contactos (30 usuarios)
- **ID 61-85**: Usuarios nuevos/inactivos (25 usuarios)

### 3. `users_public.py` ✅
**15 usuarios públicos/organizaciones (ID 86-100)**:
- ID 86: @fcbarcelona - FC Barcelona
- ID 87: @teatrebarcelona - Teatro Nacional
- ID 88: @fitzonegym - Gimnasio FitZone
- ID 89: @saborcatalunya - Restaurante
- ID 90: @museupicasso - Museo Picasso
- ID 91: @festivalmerce - Festival Mercè
- ID 92: @greenpointbcn - Green Point Yoga
- ID 93: @techbarcelona - Tech Hub
- ID 94: @cinemaverdi - Cines Verdi
- ID 95: @labirreria - Craft Beer
- ID 96: @casabatllo - Casa Batlló
- ID 97: @primaverasound - Primavera Sound
- ID 98: @marketgoticbcn - Mercat Gòtic
- ID 99: @escaladabcn - Escalada
- ID 100: @librerialaie - Librería

### 4. `contacts.py` ✅
Relaciones de contactos:
- Sonia: 50 contactos registrados + 30 NO registrados (solo teléfono)
- Miquel, Ada, Sara: sus propios contactos
- Relaciones cruzadas entre amigos cercanos

### 5. `calendars.py` ✅
Calendarios privados y públicos:

**Privados**:
- Calendar "Personal" (solo Sonia)
- Calendar "Familia" (Sonia, Miquel, Ada, Sara)
- Calendar "Trabajo" (Sonia + equipo)

**Públicos con share_hash**:
- "FC Barcelona" - share_hash: `fcb25_26` (10k suscriptores)
- "Primavera Sound" - share_hash: `ps2025xx` (2k suscriptores)
- "Festivos Barcelona" - share_hash: `bcn2025f` (500 suscriptores)
- "Clases FitZone" - share_hash: `fitzone2` (300 suscriptores)
- "Clases Yoga" - share_hash: `yogabcn1` (200 suscriptores)

**Suscripciones**: Sonia, Miquel, Ada + 30 usuarios suscritos a calendarios públicos

---

## Archivos Pendientes de Crear 📝

### 6. `groups.py` (PENDIENTE)
Crear grupos con memberships:

```python
# Grupo "Familia Martínez" - owner: Sonia
# Miembros: Sonia (owner), Miquel (admin), Ada, Sara, familia (ID 5-10)

# Grupo "Compis Trabajo" - owner: Sonia
# Miembros: Sonia + ID 11-25 (15 compañeros)

# Grupo "Running Diagonal" - owner: Marc (ID 9)
# Miembros: 30 personas

# Total: 7+ grupos
```

### 7. `events_private.py` (PENDIENTE)
Eventos privados de usuarios:

```python
# Evento "Cena Cumpleaños Sonia" - owner: Sonia
# Invitados: 25 personas (familia + amigos)
# Estados: 20 aceptados, 3 pendientes, 2 rechazados

# Evento "Escapada Fin de Semana" - owner: Miquel
# Invitados: Sonia (pending), Ada (accepted), Sara (rejected)

# Evento "Fiesta Casa Ada" - con invitaciones en cadena
# Ada invita a Sonia, Miquel, Laura, Carlos
# Sonia acepta e invita a Marta, Ana
# Miquel acepta e invita a Pedro, Juan

# Total: 50+ eventos privados
```

### 8. `events_public.py` (PENDIENTE)
Eventos públicos de organizaciones:

```python
# Evento "Barça vs Madrid - El Clásico" - owner: @fcbarcelona
# 5000+ suscriptores
# CASO ESPECIAL: Sonia tiene 2 interactions:
#   - interaction_type="subscribed", status="accepted"
#   - interaction_type="invited", status="rejected", is_attending=True
#   (invitada por Miquel, rechaza pero mantiene suscripción)

# Evento "Clase Spinning" - owner: @fitzonegym
# CASO DOBLE INTERACTION:
#   - Sonia suscrita
#   - Miquel la invita (tiene 2 interactions)

# Total: 100+ eventos públicos
```

### 9. `events_recurring.py` (PENDIENTE)
Eventos recurrentes con instancias:

```python
# Evento Base "Sincro Lunes-Miércoles" - owner: Sonia
# recurring, weekly, end_date: 2026-06-23
# Genera 52 instancias
# Ada acepta todas, Sara acepta mitad

# Evento "Comida Semanal Viernes" - owner: Padre
# recurring, weekly, perpetual (sin end_date)

# Evento "Clase Yoga Matinal" - owner: @greenpointbcn
# recurring, weekly (Lunes, Miércoles, Viernes 7:00)

# Cumpleaños (recurring yearly perpetual):
# - Miquel: 30 abril
# - Ada: 6 septiembre
# - Sonia: 31 enero
# - Sara: 2 diciembre

# Total: 20+ eventos recurrentes, 500+ instancias
```

### 10. `interactions_invitations.py` (PENDIENTE)
Invitaciones con diferentes estados:

```python
# Para cada evento, crear EventInteractions con:
# - interaction_type="invited"
# - status: "pending", "accepted", "rejected"
# - invited_by_user_id
# - personal_note (algunas)
# - cancellation_note (para rejected)
# - read_at (algunas leídas, otras sin leer)

# CASOS ESPECIALES:
# - Doble interaction (suscrito + invitado)
# - Rechazado pero asiste (rejected + is_attending=True)
# - Invitaciones en cadena (invited_by_user_id en cascada)

# Total: 1000+ interactions de tipo "invited"
```

### 11. `interactions_subscriptions.py` (PENDIENTE)
Suscripciones a eventos públicos:

```python
# Para eventos públicos, crear EventInteractions:
# - interaction_type="subscribed"
# - status="accepted"

# Sonia suscrita a:
# - 20 eventos de @fcbarcelona
# - 15 eventos de @fitzonegym
# - 10 eventos de @greenpointbcn
# - 8 eventos de @saborcatalunya
# - 5 eventos de @teatrebarcelona

# Total: 3000+ interactions de tipo "subscribed"
```

### 12. `blocks_bans.py` (ACTUALIZADO)
Bloqueos (bans eliminados del proyecto):

```python
from models import UserBlock

# UserBlocks:
# - Sonia bloquea a usuario ID 50 (ex-pareja)
# - Sonia bloquea a usuario ID 75 (spam)
# - Usuario ID 63 bloquea a Sonia

# Total: 5-10 bloqueos
```

### 13. `init_db_2.py` (ARCHIVO PRINCIPAL - PENDIENTE)
Archivo principal que ejecuta todo:

```python
"""
Database initialization script v2 - Complete test dataset
100 users, multiple complex interaction scenarios
"""

import logging
from database import SessionLocal
from init_db_2_data import (
    helpers,
    users_private,
    users_public,
    contacts,
    groups,
    calendars,
    events_private,
    events_public,
    events_recurring,
    interactions_invitations,
    interactions_subscriptions,
    blocks_bans
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def insert_sample_data_v2():
    """Insert complete sample data with 100 users"""
    db = SessionLocal()

    try:
        logger.info("📊 Creating 100 users and complex scenarios...")

        # 1. Create users
        logger.info("👥 Creating private users (1-85)...")
        private_users = users_private.create_private_users(db)

        logger.info("🏢 Creating public users (86-100)...")
        public_users = users_public.create_public_users(db)

        # 2. Create contacts
        logger.info("📇 Creating contacts...")
        contacts.create_contacts(db, private_users, public_users)

        # 3. Create groups
        logger.info("👥 Creating groups...")
        groups_data = groups.create_groups(db, private_users)

        # 4. Create calendars
        logger.info("📅 Creating calendars...")
        calendars_data = calendars.create_calendars(db, private_users, public_users)

        # 5. Create private events
        logger.info("🎉 Creating private events...")
        private_events = events_private.create_private_events(db, private_users, groups_data)

        # 6. Create public events
        logger.info("📢 Creating public events...")
        public_events = events_public.create_public_events(db, public_users)

        # 7. Create recurring events
        logger.info("🔄 Creating recurring events...")
        recurring_events = events_recurring.create_recurring_events(db, private_users, public_users)

        # 8. Create invitations
        logger.info("✉️ Creating invitations...")
        interactions_invitations.create_invitations(
            db, private_users, private_events, public_events, recurring_events
        )

        # 9. Create subscriptions
        logger.info("🔔 Creating subscriptions...")
        interactions_subscriptions.create_subscriptions(
            db, private_users, public_events
        )

        # 10. Create blocks and bans
        logger.info("🚫 Creating blocks and bans...")
        blocks_bans.create_blocks_and_bans(db, private_users, private_events)

        db.commit()
        logger.info("✅ Sample data v2 inserted successfully!")

    except Exception as e:
        logger.error(f"❌ Error inserting sample data: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    insert_sample_data_v2()
```

---

## Uso

```bash
# En start.sh, cambiar DB_SCRIPT:
DB_SCRIPT=${DB_SCRIPT:-init_db_2.py}

# O ejecutar directamente:
python init_db_2.py

# La app iniciará con USER_ID=1 (Sonia) por defecto
```

---

## Estadísticas Finales del Dataset

- **100 usuarios** (85 privados + 15 públicos)
- **2000+ contactos** en agendas
- **50+ grupos** (familiares, sociales, deportes)
- **30+ calendarios** (privados + públicos con share_hash)
- **700+ eventos** (privados + públicos + recurrentes)
- **5000+ interacciones** (invited + subscribed + joined)
- **10+ bloqueos y bans**

---

## Casos de Uso Complejos Implementados

✅ Usuario público con eventos y suscriptores (share_hash)
✅ Doble interacción (suscrito + invitado al mismo evento)
✅ Rechazo de invitación pero asistencia independiente (is_attending=True)
✅ Invitaciones en cadena (Ada → Sonia → Marta)
✅ Eventos recurrentes con instancias
✅ Cumpleaños anuales perpetuos
✅ Calendarios públicos descubribles por hash
✅ Contactos registrados y NO registrados
✅ Grupos con roles (owner, admin, member)
✅ Bloqueos bidireccionales
❌ Event bans (eliminado)

---

## Documentación Completa

Ver: `backend/CASOS_USO_INIT_DB_2.md` para especificación detallada de todos los 100 casos.
