# Plan de Migración a Arquitectura CDC 100% Pura

**Versión:** 1.0
**Fecha:** 2025-10-28
**Objetivo:** Unificar arquitectura de EventRepository y SubscriptionRepository para usar CDC granular sin refetch
**Duración estimada:** 3.5 horas
**Complejidad:** Media-Alta

---

## 📋 Tabla de Contenidos

1. [Contexto y Motivación](#contexto-y-motivación)
2. [Estado Actual vs Estado Objetivo](#estado-actual-vs-estado-objetivo)
3. [Prerequisitos y Verificaciones Iniciales](#prerequisitos-y-verificaciones-iniciales)
4. [Fase 1: Backend - Tabla de Estadísticas](#fase-1-backend---tabla-de-estadísticas)
5. [Fase 2: Backend - Modelo SQLAlchemy](#fase-2-backend---modelo-sqlalchemy)
6. [Fase 3: Frontend - Refactorizar SubscriptionRepository](#fase-3-frontend---refactorizar-subscriptionrepository)
7. [Fase 4: Frontend - Migrar EventsScreen](#fase-4-frontend---migrar-eventsscreen)
8. [Fase 5: Unificar Logs](#fase-5-unificar-logs)
9. [Fase 6: Testing Exhaustivo](#fase-6-testing-exhaustivo)
10. [Rollback y Troubleshooting](#rollback-y-troubleshooting)

---

## Contexto y Motivación

### ¿Qué es CDC?

**CDC (Change Data Capture)** es un patrón arquitectónico que detecta y captura cambios en la base de datos en tiempo real. En lugar de hacer polling (GET cada X segundos), PostgreSQL notifica automáticamente cuando hay INSERT/UPDATE/DELETE.

### Problema Actual

- **EventRepository:** Usa CDC 100% - Actualización instantánea sin API calls
- **SubscriptionRepository:** Usa CDC como "trigger" pero hace refetch completo (1 GET por cambio)

**Inconsistencia:** Dos arquitecturas diferentes para el mismo problema.

### Objetivo

**Ambos repositories usando CDC 100% granular:**
- ✅ Sin refetch innecesarios
- ✅ Actualización instantánea
- ✅ Mínimo tráfico de red
- ✅ Arquitectura consistente

---

## Estado Actual vs Estado Objetivo

### Estado Actual

| Componente | Método | API Calls | Latencia | CDC |
|------------|--------|-----------|----------|-----|
| EventRepository | CDC granular | 0 | 50ms | ✅ 100% |
| SubscriptionRepository | CDC trigger + Refetch | 1 GET por cambio | 300ms | ⚠️ 50% |

**Logs actuales (Subscriptions):**
```
🟢 [SubscriptionRepository] Realtime event received! type=DELETE
🔄 [SubscriptionRepository] Manual refresh triggered
🔵 [SubscriptionRepository] Fetching subscriptions for user 1
GET: http://localhost:8001/api/v1/users/1/subscriptions
🔵 [SubscriptionRepository] Received 2 subscriptions from view
```

### Estado Objetivo

| Componente | Método | API Calls | Latencia | CDC |
|------------|--------|-----------|----------|-----|
| EventRepository | CDC granular | 0 | 50ms | ✅ 100% |
| SubscriptionRepository | CDC granular | 0 | 60ms | ✅ 100% |

**Logs esperados (Subscriptions):**
```
📡 [SubscriptionRepository] CDC event: user_subscription_stats UPDATE
📊 [SubscriptionRepository] Stats updated for user 5: events=15, subscribers=3
📤 [SubscriptionRepository] Emitting 3 subscriptions to stream
```

---

## Prerequisitos y Verificaciones Iniciales

### ✅ Checklist Pre-Implementación

Ejecuta estos comandos para verificar el estado del sistema:

```bash
# 1. Verificar que Docker está corriendo
docker info > /dev/null 2>&1 && echo "✅ Docker running" || echo "❌ Docker not running"

# 2. Verificar que el backend está levantado
nc -z localhost 8001 && echo "✅ Backend running" || echo "❌ Backend not running"

# 3. Verificar que PostgreSQL responde
nc -z localhost 5432 && echo "✅ PostgreSQL running" || echo "❌ PostgreSQL not running"

# 4. Verificar archivos críticos existen
ls -la database/init/01_init.sql && echo "✅ 01_init.sql found"
ls -la backend/init_db.py && echo "✅ init_db.py found"
ls -la docker-compose.yml && echo "✅ docker-compose.yml found"
```

**Logs esperados:**
```
✅ Docker running
✅ Backend running
✅ PostgreSQL running
✅ 01_init.sql found
✅ init_db.py found
✅ docker-compose.yml found
```

### 🔴 Si algo falla:

**Docker not running:**
```bash
open -a Docker  # macOS
# Espera 30 segundos y vuelve a verificar
```

**Backend not running:**
```bash
./start.sh backend
```

### 📸 Backup Pre-Cambios

```bash
# Crear directorio de backups
mkdir -p backups/$(date +%Y%m%d_%H%M%S)

# Backup base de datos
docker exec agenda_phoenix_db pg_dump -U postgres postgres > backups/$(date +%Y%m%d_%H%M%S)/db_backup.sql

# Backup archivos que vamos a modificar
cp database/init/01_init.sql backups/$(date +%Y%m%d_%H%M%S)/
cp backend/init_db.py backups/$(date +%Y%m%d_%H%M%S)/
cp app_flutter/lib/repositories/subscription_repository.dart backups/$(date +%Y%m%d_%H%M%S)/
cp app_flutter/lib/screens/events_screen.dart backups/$(date +%Y%m%d_%H%M%S)/

echo "✅ Backup creado en backups/$(date +%Y%m%d_%H%M%S)/"
```

---

## Fase 1: Backend - Tabla de Estadísticas

**Duración:** 30 minutos
**Archivos:** `database/init/01_init.sql`

### 🎯 Objetivo

Crear tabla `user_subscription_stats` que mantiene estadísticas pre-calculadas actualizadas automáticamente vía triggers.

### 📝 Paso 1.1: Abrir archivo

```bash
code database/init/01_init.sql  # O tu editor preferido
```

### 📝 Paso 1.2: Añadir SQL al final del archivo

**Ubicación:** Al final del archivo, después de todas las tablas existentes.

**Contenido a añadir:**

```sql
-- ============================================================================
-- USER SUBSCRIPTION STATS TABLE (CDC Optimization)
-- ============================================================================
-- This table maintains pre-calculated statistics for user subscriptions
-- Updated automatically via triggers for maximum performance
-- Created: 2025-10-28
-- Ticket: CDC Architecture Unification

CREATE TABLE IF NOT EXISTS user_subscription_stats (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    new_events_count INTEGER DEFAULT 0,          -- Events created in last 7 days
    total_events_count INTEGER DEFAULT 0,        -- Total events created
    subscribers_count INTEGER DEFAULT 0,         -- Number of subscribers to user's events
    last_event_date TIMESTAMP,                   -- Last event creation date
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_stats_updated ON user_subscription_stats(updated_at);
CREATE INDEX IF NOT EXISTS idx_user_stats_user_id ON user_subscription_stats(user_id);

-- Grant permissions for Realtime CDC
ALTER TABLE user_subscription_stats REPLICA IDENTITY FULL;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_subscription_stats TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_subscription_stats TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_subscription_stats TO authenticated;

-- ============================================================================
-- TRIGGER 1: Update stats when event is created
-- ============================================================================
CREATE OR REPLACE FUNCTION update_stats_on_event_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_subscription_stats (
        user_id,
        total_events_count,
        new_events_count,
        last_event_date
    )
    VALUES (
        NEW.owner_id,
        1,
        CASE WHEN NEW.created_at > NOW() - INTERVAL '7 days' THEN 1 ELSE 0 END,
        NEW.created_at
    )
    ON CONFLICT (user_id) DO UPDATE SET
        total_events_count = user_subscription_stats.total_events_count + 1,
        new_events_count = CASE
            WHEN NEW.created_at > NOW() - INTERVAL '7 days'
            THEN user_subscription_stats.new_events_count + 1
            ELSE user_subscription_stats.new_events_count
        END,
        last_event_date = GREATEST(user_subscription_stats.last_event_date, NEW.created_at),
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_insert_stats_trigger
AFTER INSERT ON events
FOR EACH ROW
EXECUTE FUNCTION update_stats_on_event_insert();

-- ============================================================================
-- TRIGGER 2: Update stats when event is deleted
-- ============================================================================
CREATE OR REPLACE FUNCTION update_stats_on_event_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE user_subscription_stats
    SET total_events_count = GREATEST(0, total_events_count - 1),
        new_events_count = CASE
            WHEN OLD.created_at > NOW() - INTERVAL '7 days'
            THEN GREATEST(0, new_events_count - 1)
            ELSE new_events_count
        END,
        updated_at = NOW()
    WHERE user_id = OLD.owner_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_delete_stats_trigger
AFTER DELETE ON events
FOR EACH ROW
EXECUTE FUNCTION update_stats_on_event_delete();

-- ============================================================================
-- TRIGGER 3: Update subscriber count on subscription
-- ============================================================================
CREATE OR REPLACE FUNCTION update_stats_on_subscription()
RETURNS TRIGGER AS $$
DECLARE
    event_owner_id INTEGER;
BEGIN
    -- Get the owner of the event being subscribed to
    SELECT owner_id INTO event_owner_id
    FROM events
    WHERE id = NEW.event_id;

    IF event_owner_id IS NOT NULL AND NEW.interaction_type = 'subscribed' THEN
        INSERT INTO user_subscription_stats (user_id, subscribers_count)
        VALUES (event_owner_id, 1)
        ON CONFLICT (user_id) DO UPDATE SET
            subscribers_count = user_subscription_stats.subscribers_count + 1,
            updated_at = NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER subscription_insert_stats_trigger
AFTER INSERT ON event_interactions
FOR EACH ROW
WHEN (NEW.interaction_type = 'subscribed')
EXECUTE FUNCTION update_stats_on_subscription();

-- ============================================================================
-- TRIGGER 4: Update subscriber count on unsubscription
-- ============================================================================
CREATE OR REPLACE FUNCTION update_stats_on_unsubscription()
RETURNS TRIGGER AS $$
DECLARE
    event_owner_id INTEGER;
BEGIN
    -- Get the owner of the event being unsubscribed from
    SELECT owner_id INTO event_owner_id
    FROM events
    WHERE id = OLD.event_id;

    IF event_owner_id IS NOT NULL AND OLD.interaction_type = 'subscribed' THEN
        UPDATE user_subscription_stats
        SET subscribers_count = GREATEST(0, subscribers_count - 1),
            updated_at = NOW()
        WHERE user_id = event_owner_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER subscription_delete_stats_trigger
AFTER DELETE ON event_interactions
FOR EACH ROW
WHEN (OLD.interaction_type = 'subscribed')
EXECUTE FUNCTION update_stats_on_unsubscription();

-- ============================================================================
-- Initialize stats for existing users
-- ============================================================================
-- This runs once during initial setup to populate stats from existing data
INSERT INTO user_subscription_stats (user_id, total_events_count, new_events_count, subscribers_count, last_event_date)
SELECT
    u.id as user_id,
    COALESCE(e.total_events, 0) as total_events_count,
    COALESCE(e.new_events, 0) as new_events_count,
    COALESCE(s.subscribers, 0) as subscribers_count,
    e.last_event
FROM users u
LEFT JOIN (
    SELECT owner_id,
           COUNT(*) as total_events,
           COUNT(CASE WHEN created_at > NOW() - INTERVAL '7 days' THEN 1 END) as new_events,
           MAX(created_at) as last_event
    FROM events
    GROUP BY owner_id
) e ON u.id = e.owner_id
LEFT JOIN (
    SELECT e.owner_id, COUNT(DISTINCT ei.user_id) as subscribers
    FROM events e
    JOIN event_interactions ei ON e.id = ei.event_id
    WHERE ei.interaction_type = 'subscribed'
    GROUP BY e.owner_id
) s ON u.id = s.owner_id
ON CONFLICT (user_id) DO NOTHING;
```

### ✅ Verificación Paso 1.2

**Verifica que el SQL está bien formateado:**
```bash
# Cuenta líneas añadidas (debe ser ~165 líneas)
tail -n 165 database/init/01_init.sql | wc -l

# Verifica sintaxis SQL (opcional, requiere psql)
docker exec -i agenda_phoenix_db psql -U postgres -d postgres --dry-run < database/init/01_init.sql
```

**Logs esperados:**
```
165  # Número de líneas
```

### 📝 Paso 1.3: Recrear base de datos

```bash
# Detener todo
./start.sh stop

# Eliminar volumen de BD (esto borra todos los datos!)
docker volume rm agenda_phoenix_db_data 2>/dev/null || echo "Volumen no existe"

# Arrancar backend (ejecutará init_db.py que usa 01_init.sql)
./start.sh backend
```

**Logs esperados:**
```
[start] Starting backend services (Agenda Phoenix v2.0.0)...
[start] Ensuring clean state (stopping any existing containers)...
[start] Building backend Docker image...
[start] Starting all Supabase services in Docker (detached mode)...
[✔] Backend ready at http://localhost:8001

# En logs del contenedor backend:
🏗️  Creating tables from models...
✅ All tables created successfully
🔐 Granting permissions on Supabase schemas...
✅ Permissions handled by initial SQL scripts.
```

### ✅ Verificación Paso 1.3

```bash
# Verificar que la tabla existe
docker exec agenda_phoenix_db psql -U postgres -d postgres -c "\dt user_subscription_stats"

# Verificar que los triggers existen
docker exec agenda_phoenix_db psql -U postgres -d postgres -c "SELECT tgname FROM pg_trigger WHERE tgname LIKE '%stats%';"

# Verificar que hay datos iniciales
docker exec agenda_phoenix_db psql -U postgres -d postgres -c "SELECT COUNT(*) FROM user_subscription_stats;"
```

**Logs esperados:**
```
# Tabla existe:
                    List of relations
 Schema |           Name             | Type  |  Owner
--------+----------------------------+-------+----------
 public | user_subscription_stats    | table | postgres

# Triggers existen:
              tgname
------------------------------------
 event_insert_stats_trigger
 event_delete_stats_trigger
 subscription_insert_stats_trigger
 subscription_delete_stats_trigger

# Datos iniciales (depende de cuántos usuarios tengas):
 count
-------
     5
```

### 🔴 Troubleshooting Fase 1

**Error: "relation user_subscription_stats already exists"**
```bash
# Eliminar tabla manualmente
docker exec agenda_phoenix_db psql -U postgres -d postgres -c "DROP TABLE IF EXISTS user_subscription_stats CASCADE;"

# Volver a arrancar
./start.sh stop
./start.sh backend
```

**Error: "permission denied for table user_subscription_stats"**
```bash
# Otorgar permisos manualmente
docker exec agenda_phoenix_db psql -U postgres -d postgres -c "
GRANT SELECT, INSERT, UPDATE, DELETE ON user_subscription_stats TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_subscription_stats TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_subscription_stats TO authenticated;
"
```

### 📍 Checkpoint Fase 1

✅ Si llegaste aquí:
- Tabla `user_subscription_stats` existe
- 4 triggers están activos
- Datos iniciales cargados

**Puedes continuar a Fase 2**

---

## Fase 2: Backend - Modelo SQLAlchemy

**Duración:** 15 minutos
**Archivos:** `backend/models/user_subscription_stats.py` (NUEVO), `backend/models/__init__.py`

### 🎯 Objetivo

Crear modelo SQLAlchemy para que el ORM reconozca la tabla (opcional pero recomendado).

### 📝 Paso 2.1: Crear archivo del modelo

```bash
touch backend/models/user_subscription_stats.py
```

### 📝 Paso 2.2: Escribir modelo

**Archivo:** `backend/models/user_subscription_stats.py`

```python
"""
User Subscription Statistics Model
Stores pre-calculated statistics for user subscriptions
Updated automatically via database triggers
"""

from sqlalchemy import Column, Integer, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base


class UserSubscriptionStats(Base):
    """
    Statistics table for user subscriptions.

    This table is populated and maintained by database triggers:
    - event_insert_stats_trigger: Updates when events are created
    - event_delete_stats_trigger: Updates when events are deleted
    - subscription_insert_stats_trigger: Updates when users subscribe
    - subscription_delete_stats_trigger: Updates when users unsubscribe

    Fields:
        user_id: Foreign key to users table
        new_events_count: Number of events created in last 7 days
        total_events_count: Total number of events created by user
        subscribers_count: Number of unique subscribers to user's events
        last_event_date: Timestamp of most recent event creation
        updated_at: Last update timestamp (auto-updated by trigger)
    """
    __tablename__ = "user_subscription_stats"

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True, doc="User ID (FK)")
    new_events_count = Column(Integer, default=0, nullable=False, doc="Events in last 7 days")
    total_events_count = Column(Integer, default=0, nullable=False, doc="Total events created")
    subscribers_count = Column(Integer, default=0, nullable=False, doc="Number of subscribers")
    last_event_date = Column(DateTime, nullable=True, doc="Last event creation timestamp")
    updated_at = Column(DateTime, nullable=False, doc="Last stats update")

    # Relationship to User
    user = relationship("User", back_populates="subscription_stats")

    def __repr__(self):
        return f"<UserSubscriptionStats(user_id={self.user_id}, events={self.total_events_count}, subscribers={self.subscribers_count})>"
```

### 📝 Paso 2.3: Actualizar __init__.py

**Archivo:** `backend/models/__init__.py`

Añade al final del archivo:

```python
from .user_subscription_stats import UserSubscriptionStats
```

Y añade `UserSubscriptionStats` al `__all__` si existe:

```python
__all__ = [
    # ... modelos existentes ...
    "UserSubscriptionStats",  # ← AÑADIR
]
```

### 📝 Paso 2.4: Actualizar modelo User (opcional)

**Archivo:** `backend/models/user.py`

Busca la clase `User` y añade la relación inversa (si quieres acceder a stats desde user):

```python
from sqlalchemy.orm import relationship

class User(Base):
    # ... campos existentes ...

    # Añadir al final de las relaciones:
    subscription_stats = relationship(
        "UserSubscriptionStats",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan"
    )
```

### ✅ Verificación Fase 2

```bash
# Verificar sintaxis Python
python3 -m py_compile backend/models/user_subscription_stats.py
echo $?  # Debe retornar 0

# Verificar import
cd backend
python3 -c "from models import UserSubscriptionStats; print('✅ Import OK')"
```

**Logs esperados:**
```
0
✅ Import OK
```

### 🔴 Troubleshooting Fase 2

**Error: "cannot import name UserSubscriptionStats"**
```bash
# Verificar que añadiste el import en __init__.py
grep "UserSubscriptionStats" backend/models/__init__.py

# Debe mostrar:
from .user_subscription_stats import UserSubscriptionStats
```

**Error: "No module named database"**
```bash
# Ejecutar desde el directorio backend
cd backend
python3 -c "from models import UserSubscriptionStats"
```

### 📍 Checkpoint Fase 2

✅ Si llegaste aquí:
- Modelo UserSubscriptionStats creado
- Import funciona correctamente
- SQLAlchemy reconoce la tabla

**Puedes continuar a Fase 3**

---

## Fase 3: Frontend - Refactorizar SubscriptionRepository

**Duración:** 1 hora
**Archivos:** `app_flutter/lib/repositories/subscription_repository.dart`

### 🎯 Objetivo

Cambiar de "CDC trigger + Refetch" a "CDC granular 100%".

### 📝 Paso 3.1: Backup del archivo original

```bash
cp app_flutter/lib/repositories/subscription_repository.dart app_flutter/lib/repositories/subscription_repository.dart.backup
echo "✅ Backup creado"
```

### 📝 Paso 3.2: Modificar imports

**Archivo:** `app_flutter/lib/repositories/subscription_repository.dart`

**Buscar (línea ~1-6):**
```dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../core/realtime_sync.dart';
```

**No cambiar, solo verificar que existen estos imports.**

### 📝 Paso 3.3: Añadir canal para stats

**Buscar (línea ~14):**
```dart
final StreamController<List<models.User>> _subscriptionsController = StreamController<List<models.User>>.broadcast();
List<models.User> _cachedUsers = [];
RealtimeChannel? _realtimeChannel;
```

**Reemplazar con:**
```dart
final StreamController<List<models.User>> _subscriptionsController = StreamController<List<models.User>>.broadcast();
List<models.User> _cachedUsers = [];
RealtimeChannel? _realtimeChannel;
RealtimeChannel? _statsChannel;  // ← NUEVO: Canal para escuchar cambios en stats
```

### 📝 Paso 3.4: Refactorizar _startRealtimeSubscription

**Buscar método (línea ~96-115):**
```dart
Future<void> _startRealtimeSubscription() async {
  final userId = ConfigService.instance.currentUserId;

  print('🔵 [SubscriptionRepository] Starting Realtime subscription for user_id=$userId');

  await SupabaseService.instance.applyTestAuthIfNeeded();

  _realtimeChannel = RealtimeUtils.subscribeTable(
    client: _supabaseService.client,
    schema: 'public',
    table: 'event_interactions',
    filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId.toString()),
    onChange: _handleSubscriptionChange,
  );

  print('✅ Realtime subscription started for subscriptions (event_interactions)');
}
```

**Reemplazar con:**
```dart
Future<void> _startRealtimeSubscription() async {
  final userId = ConfigService.instance.currentUserId;

  print('🔵 [SubscriptionRepository] Starting Realtime subscriptions for user_id=$userId');

  await SupabaseService.instance.applyTestAuthIfNeeded();

  // Canal 1: Escuchar cambios en event_interactions (subscripciones)
  _realtimeChannel = RealtimeUtils.subscribeTable(
    client: _supabaseService.client,
    schema: 'public',
    table: 'event_interactions',
    filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId.toString()),
    onChange: _handleSubscriptionChange,
  );

  print('✅ Realtime subscription started for event_interactions');

  // Canal 2: Escuchar cambios en user_subscription_stats
  _statsChannel = RealtimeUtils.subscribeTable(
    client: _supabaseService.client,
    schema: 'public',
    table: 'user_subscription_stats',
    onChange: _handleStatsChange,
  );

  print('✅ Realtime subscription started for user_subscription_stats');
}
```

### 📝 Paso 3.5: Refactorizar _handleSubscriptionChange

**Buscar método (línea ~117-156):**
```dart
void _handleSubscriptionChange(PostgresChangePayload payload) {
  final userId = ConfigService.instance.currentUserId;
  print('🟢 [SubscriptionRepository] Realtime event received! type=${payload.eventType} ct=${payload.commitTimestamp}');

  bool isSubscribed(Map<String, dynamic> rec) => rec['user_id'] == userId && rec['interaction_type'] == 'subscribed';

  // ... resto del código ...

  if (payload.eventType == PostgresChangeEvent.delete) {
    final oldRec = Map<String, dynamic>.from(payload.oldRecord);
    print('🗑️ [SubscriptionRepository] DELETE oldRecord: ' + oldRec.toString());
    if (isSubscribed(oldRec) && _rt.shouldProcessDelete()) {
      print('🟢 [SubscriptionRepository] DELETE subscribed -> refetch');
      _fetchAndSync().then((_) => _emitCurrentSubscriptions());
    }
    return;
  }

  final newRec = Map<String, dynamic>.from(payload.newRecord);
  print('📝 [SubscriptionRepository] UPSERT newRecord: ' + newRec.toString());
  if (isSubscribed(newRec)) {
    if (_rt.shouldProcessInsertOrUpdate(ct)) {
      print('🟢 [SubscriptionRepository] ${payload.eventType.name.toUpperCase()} subscribed (after gate) -> refetch');
      _fetchAndSync().then((_) => _emitCurrentSubscriptions());
    }
  }
}
```

**Reemplazar con:**
```dart
void _handleSubscriptionChange(PostgresChangePayload payload) {
  final userId = ConfigService.instance.currentUserId;
  print('📡 [SubscriptionRepository] CDC ${payload.eventType.name.toUpperCase()}: event_interactions');

  // Validar que sea una interacción de tipo 'subscribed'
  bool isSubscribedInteraction(Map<String, dynamic> rec) {
    return rec['user_id'] == userId && rec['interaction_type'] == 'subscribed';
  }

  DateTime? ct;
  final ctRaw = payload.commitTimestamp;
  if (ctRaw is DateTime) {
    ct = ctRaw.toUtc();
  } else if (ctRaw != null) {
    ct = DateTime.tryParse(ctRaw.toString())?.toUtc();
  }

  if (payload.eventType == PostgresChangeEvent.delete) {
    final oldRec = Map<String, dynamic>.from(payload.oldRecord);

    if (isSubscribedInteraction(oldRec) && _rt.shouldProcessDelete()) {
      final eventId = oldRec['event_id'];
      print('🗑️ [SubscriptionRepository] User unsubscribed from event $eventId - removing from cache');

      // Encontrar y eliminar el usuario de la lista
      // (El trigger de stats ya actualizó los contadores)
      _fetchAndSync().then((_) => _emitCurrentSubscriptions());
    }
    return;
  }

  final newRec = Map<String, dynamic>.from(payload.newRecord);

  if (isSubscribedInteraction(newRec)) {
    if (_rt.shouldProcessInsertOrUpdate(ct)) {
      final eventId = newRec['event_id'];
      print('✅ [SubscriptionRepository] User subscribed to event $eventId - adding to cache');

      // Nueva suscripción - refetch para obtener datos del usuario
      _fetchAndSync().then((_) => _emitCurrentSubscriptions());
    } else {
      print('⏸️ [SubscriptionRepository] Event skipped by time gate');
    }
  }
}
```

### 📝 Paso 3.6: Añadir nuevo método _handleStatsChange

**Añadir después de _handleSubscriptionChange (línea ~157):**

```dart
/// Handle changes in user_subscription_stats table (CDC)
void _handleStatsChange(PostgresChangePayload payload) {
  print('📊 [SubscriptionRepository] CDC ${payload.eventType.name.toUpperCase()}: user_subscription_stats');

  if (payload.eventType == PostgresChangeEvent.delete) {
    // Stats deleted (usuario eliminado) - ya manejado por CASCADE
    return;
  }

  final statsRecord = Map<String, dynamic>.from(payload.newRecord);
  final affectedUserId = statsRecord['user_id'] as int?;

  if (affectedUserId == null) {
    print('⚠️ [SubscriptionRepository] Stats change without user_id');
    return;
  }

  // Buscar el usuario en cache
  final userIndex = _cachedUsers.indexWhere((u) => u.id == affectedUserId);

  if (userIndex == -1) {
    // Usuario no está en nuestra lista de suscripciones - ignorar
    return;
  }

  // Actualizar solo las estadísticas del usuario (CDC granular!)
  final user = _cachedUsers[userIndex];
  _cachedUsers[userIndex] = models.User(
    id: user.id,
    contactId: user.contactId,
    instagramName: user.instagramName,
    fullName: user.fullName,
    authProvider: user.authProvider,
    authId: user.authId,
    isPublic: user.isPublic,
    isAdmin: user.isAdmin,
    profilePicture: user.profilePicture,
    lastSeen: user.lastSeen,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
    // Actualizar stats desde CDC
    newEventsCount: statsRecord['new_events_count'] as int? ?? user.newEventsCount,
    totalEventsCount: statsRecord['total_events_count'] as int? ?? user.totalEventsCount,
    subscribersCount: statsRecord['subscribers_count'] as int? ?? user.subscribersCount,
  );

  print('📊 [SubscriptionRepository] Stats updated for user $affectedUserId: '
        'events=${statsRecord['total_events_count']}, '
        'new=${statsRecord['new_events_count']}, '
        'subscribers=${statsRecord['subscribers_count']}');

  _emitCurrentSubscriptions();
}
```

### 📝 Paso 3.7: Actualizar dispose

**Buscar método dispose (línea ~167-170):**
```dart
void dispose() {
  _realtimeChannel?.unsubscribe();
  _subscriptionsController.close();
}
```

**Reemplazar con:**
```dart
void dispose() {
  _realtimeChannel?.unsubscribe();
  _statsChannel?.unsubscribe();  // ← NUEVO
  _subscriptionsController.close();
}
```

### ✅ Verificación Fase 3

```bash
# Compilar para verificar sintaxis
cd app_flutter
flutter analyze lib/repositories/subscription_repository.dart

# Debe retornar sin errores
```

**Logs esperados:**
```
Analyzing app_flutter...
No issues found!
```

### 🔴 Troubleshooting Fase 3

**Error: "Undefined name 'RealtimeUtils'"**
```dart
// Verificar import en la parte superior del archivo:
import '../core/realtime_sync.dart';
```

**Error: "The method 'subscribeTable' isn't defined"**
```bash
# Verificar que RealtimeUtils existe
grep -r "class RealtimeUtils" app_flutter/lib/
```

**Error: "Undefined class 'PostgresChangePayload'"**
```dart
// Verificar import
import 'package:supabase_flutter/supabase_flutter.dart';
```

### 📍 Checkpoint Fase 3

✅ Si llegaste aquí:
- SubscriptionRepository refactorizado
- Dos canales CDC configurados
- Método _handleStatsChange añadido
- Sin errores de compilación

**Puedes continuar a Fase 4**

---

## Fase 4: Frontend - Migrar EventsScreen

**Duración:** 45 minutos
**Archivos:** `app_flutter/lib/screens/events_screen.dart`

### 🎯 Objetivo

Migrar EventsScreen de patrón manual (`.listen()`) a patrón Riverpod (StreamProvider) para consistencia con SubscriptionsScreen.

### 📝 Paso 4.1: Backup

```bash
cp app_flutter/lib/screens/events_screen.dart app_flutter/lib/screens/events_screen.dart.backup
echo "✅ Backup creado"
```

### 📝 Paso 4.2: Remover estado local

**Buscar (línea ~54-57):**
```dart
class _EventsScreenState extends ConsumerState<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = 'all';
  String _searchQuery = '';
  EventsData? _eventsData;
  bool _isLoading = true;
  EventRepository? _eventRepository;
  StreamSubscription<List<Event>>? _eventsSubscription;
```

**Reemplazar con:**
```dart
class _EventsScreenState extends ConsumerState<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = 'all';
  String _searchQuery = '';
  // Removido: EventsData? _eventsData;
  // Removido: bool _isLoading = true;
  // Removido: EventRepository? _eventRepository;
  // Removido: StreamSubscription<List<Event>>? _eventsSubscription;
```

### 📝 Paso 4.3: Simplificar initState

**Buscar (línea ~60-70):**
```dart
@override
void initState() {
  super.initState();

  _searchController.addListener(() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  });

  _initializeRepository();
}
```

**Reemplazar con:**
```dart
@override
void initState() {
  super.initState();

  _searchController.addListener(() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  });

  // Ya no necesitamos _initializeRepository() - Riverpod lo maneja
}
```

### 📝 Paso 4.4: Eliminar métodos obsoletos

**Eliminar estos métodos completos:**
- `_initializeRepository()` (líneas ~72-88)
- `_loadData()` (líneas ~90-111)

### 📝 Paso 4.5: Refactorizar _buildEventsDataFromRepository

**Buscar método (línea ~113-168):**
```dart
void _buildEventsDataFromRepository(List<Event> events) {
  print('🔧 [EventsScreen] _buildEventsDataFromRepository START');
  // ... procesamiento ...
  setState(() {
    _eventsData = EventsData(/* ... */);
    _isLoading = false;
  });
}
```

**Reemplazar con método estático:**
```dart
static EventsData _buildEventsData(List<Event> events) {
  // Removido: print statements (ya no necesarios)

  final userId = ConfigService.instance.currentUserId;

  final eventItems = <EventWithInteraction>[];
  for (final event in events) {
    final eventOwnerId = event.ownerId;
    final isOwner = eventOwnerId == userId;

    String? interactionType;
    String? invitationStatus;

    if (!isOwner && event.interactionData != null) {
      interactionType = event.interactionData!['interaction_type'] as String?;
      invitationStatus = event.interactionData!['status'] as String?;
    }

    eventItems.add(EventWithInteraction(event, interactionType, invitationStatus));
  }

  final myEvents = eventItems.where((e) =>
    e.event.ownerId == userId ||
    (e.event.ownerId != userId &&
     (e.interactionType == 'invited' || e.interactionType == 'joined') &&
     e.invitationStatus == 'accepted')
  ).length;

  final invitations = eventItems.where((e) =>
    e.event.ownerId != userId &&
    e.interactionType == 'invited' &&
    e.invitationStatus == 'pending'
  ).length;

  final subscribed = eventItems.where((e) =>
    e.event.ownerId != userId &&
    e.interactionType == 'subscribed'
  ).length;

  return EventsData(
    events: eventItems,
    myEventsCount: myEvents,
    invitationsCount: invitations,
    subscribedCount: subscribed,
    allCount: eventItems.length,
  );
}
```

### 📝 Paso 4.6: Refactorizar build method

**Buscar build method (línea ~247-xxx):**
```dart
@override
Widget build(BuildContext context) {
  final l10n = context.l10n;

  // Código actual que usa _eventsData y _isLoading
}
```

**Reemplazar con:**
```dart
@override
Widget build(BuildContext context) {
  final l10n = context.l10n;

  // Usar StreamProvider en lugar de estado local
  final eventsAsync = ref.watch(eventsStreamProvider);

  return eventsAsync.when(
    data: (events) {
      final eventsData = _buildEventsData(events);
      return _buildUI(context, eventsData, l10n);
    },
    loading: () => AdaptivePageScaffold(
      title: PlatformWidgets.isIOS ? null : l10n.events,
      body: const Center(child: CupertinoActivityIndicator()),
    ),
    error: (error, stack) => AdaptivePageScaffold(
      title: PlatformWidgets.isIOS ? null : l10n.events,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 64),
            const SizedBox(height: 16),
            Text('Error: $error', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    ),
  );
}
```

### 📝 Paso 4.7: Crear método _buildUI

**Añadir después de build:**
```dart
Widget _buildUI(BuildContext context, EventsData eventsData, AppLocalizations l10n) {
  // Filtrar eventos según búsqueda y filtro actual
  final filteredEvents = eventsData.events.where((eventItem) {
    // Filtro por categoría
    switch (_currentFilter) {
      case 'my_events':
        final userId = ConfigService.instance.currentUserId;
        return eventItem.event.ownerId == userId ||
            (eventItem.event.ownerId != userId &&
                (eventItem.interactionType == 'invited' || eventItem.interactionType == 'joined') &&
                eventItem.invitationStatus == 'accepted');
      case 'invitations':
        final userId = ConfigService.instance.currentUserId;
        return eventItem.event.ownerId != userId &&
               eventItem.interactionType == 'invited' &&
               eventItem.invitationStatus == 'pending';
      case 'subscribed':
        final userId = ConfigService.instance.currentUserId;
        return eventItem.event.ownerId != userId &&
               eventItem.interactionType == 'subscribed';
      case 'all':
      default:
        return true;
    }
  }).where((eventItem) {
    // Filtro por búsqueda
    if (_searchQuery.isEmpty) return true;
    return eventItem.event.name.toLowerCase().contains(_searchQuery.toLowerCase());
  }).toList();

  // Aquí va el código actual del UI
  // Copia todo el contenido que estaba en build() después de verificar _isLoading
  // Reemplaza todas las referencias a _eventsData con eventsData
  return AdaptivePageScaffold(
    // ... código del UI existente ...
  );
}
```

### 📝 Paso 4.8: Actualizar dispose

**Buscar dispose:**
```dart
@override
void dispose() {
  _searchController.dispose();
  _eventsSubscription?.cancel();  // ← ELIMINAR esta línea
  super.dispose();
}
```

**Reemplazar con:**
```dart
@override
void dispose() {
  _searchController.dispose();
  // Ya no necesitamos cancelar subscripción - Riverpod lo maneja
  super.dispose();
}
```

### ✅ Verificación Fase 4

```bash
# Compilar
cd app_flutter
flutter analyze lib/screens/events_screen.dart

# Sin errores
```

**Logs esperados:**
```
Analyzing app_flutter...
No issues found!
```

### 🔴 Troubleshooting Fase 4

**Error: "Undefined name eventsStreamProvider"**
```dart
// Verificar import
import '../core/state/app_state.dart';

// Verificar que eventsStreamProvider existe en app_state.dart:
final eventsStreamProvider = StreamProvider<List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.eventsStream;
});
```

**Error: "The method 'when' isn't defined for the type"**
```dart
// Asegúrate de que eventsAsync es AsyncValue<List<Event>>
final eventsAsync = ref.watch(eventsStreamProvider);
```

### 📍 Checkpoint Fase 4

✅ Si llegaste aquí:
- EventsScreen migrado a StreamProvider
- Consistencia con SubscriptionsScreen
- Sin estado local mutable
- Sin errores de compilación

**Puedes continuar a Fase 5**

---

## Fase 5: Unificar Logs

**Duración:** 30 minutos
**Archivos:** `subscription_repository.dart`, `event_repository.dart`

### 🎯 Objetivo

Logs consistentes entre ambos repositories para facilitar debugging.

### 📝 Paso 5.1: Formato de logs estándar

**Patrón a seguir:**
```dart
// Inicialización
print('🔵 [${repositoryName}] Fetching ${resourceName} for user $userId');

// CDC recibido
print('📡 [${repositoryName}] CDC ${eventType}: ${tableName}');

// Actualización granular
print('✅ [${repositoryName}] ${resourceName} updated: id=$id');

// Emisión al stream
print('📤 [${repositoryName}] Emitting ${count} ${resourceName} to stream');

// Error
print('❌ [${repositoryName}] Error: $errorMessage');
```

### 📝 Paso 5.2: Actualizar logs en SubscriptionRepository

**Buscar y reemplazar:**

```dart
// ANTES:
print('🔵 [SubscriptionRepository] Fetching subscriptions for user $userId');

// DESPUÉS (ya está correcto, verificar)
print('🔵 [SubscriptionRepository] Fetching subscriptions for user $userId');

// ANTES:
print('🟢 [SubscriptionRepository] Realtime event received!');

// DESPUÉS:
print('📡 [SubscriptionRepository] CDC ${payload.eventType.name.toUpperCase()}: event_interactions');
```

### 📝 Paso 5.3: Verificar logs en EventRepository

Abrir `event_repository.dart` y verificar que los logs siguen el formato:

```bash
grep "print(" app_flutter/lib/repositories/event_repository.dart | head -20
```

**Formato esperado:**
```dart
print('✅ [EventRepository] Loaded $count events from Hive cache');
print('📡 [EventRepository] CDC INSERT: events');
print('📤 [EventRepository] Emitting $count events to stream');
```

### ✅ Verificación Fase 5

```bash
# Buscar todos los logs en repositories
grep -E "print\(" app_flutter/lib/repositories/*.dart | wc -l

# Verificar formato consistente (debe empezar con emoji)
grep -E "print\('(🔵|📡|✅|📤|❌)" app_flutter/lib/repositories/*.dart | wc -l
```

### 📍 Checkpoint Fase 5

✅ Si llegaste aquí:
- Logs unificados
- Formato consistente
- Fácil debugging

**Puedes continuar a Fase 6 (Testing)**

---

## Fase 6: Testing Exhaustivo

**Duración:** 1 hora
**Objetivo:** Verificar que todo funciona correctamente

### 🧪 Test 1: Arranque Limpio

```bash
# 1. Detener todo
./start.sh stop

# 2. Limpiar volúmenes
docker volume rm agenda_phoenix_db_data 2>/dev/null

# 3. Arrancar backend
./start.sh backend
```

**Logs esperados:**
```
[start] Building backend Docker image...
✅ All tables created successfully
✅ Permissions handled by initial SQL scripts
[✔] Backend ready at http://localhost:8001
```

**Verificar tabla existe:**
```bash
docker exec agenda_phoenix_db psql -U postgres -d postgres -c "SELECT COUNT(*) FROM user_subscription_stats;"
```

**Log esperado:**
```
 count
-------
     5
```

✅ **Test 1 PASS**

---

### 🧪 Test 2: Triggers Funcionan

```bash
# Crear un evento y verificar que stats se actualizan
docker exec agenda_phoenix_db psql -U postgres -d postgres << EOF
-- Ver stats del usuario 1 antes
SELECT * FROM user_subscription_stats WHERE user_id = 1;

-- Crear evento
INSERT INTO events (owner_id, name, start_date, event_type, created_at)
VALUES (1, 'Test Event', NOW(), 'social', NOW());

-- Ver stats del usuario 1 después
SELECT * FROM user_subscription_stats WHERE user_id = 1;
EOF
```

**Logs esperados:**
```
# ANTES:
 user_id | new_events_count | total_events_count | subscribers_count
---------+------------------+--------------------+-------------------
       1 |                5 |                 10 |                 2

# DESPUÉS:
 user_id | new_events_count | total_events_count | subscribers_count
---------+------------------+--------------------+-------------------
       1 |                6 |                 11 |                 2  ← Incrementó
```

✅ **Test 2 PASS** si los contadores aumentaron

---

### 🧪 Test 3: Flutter App Arranca

```bash
# Arrancar iOS app
./start.sh ios
```

**Logs esperados en consola:**
```
🔵 [SubscriptionRepository] Starting Realtime subscriptions for user_id=1
✅ Realtime subscription started for event_interactions
✅ Realtime subscription started for user_subscription_stats  ← NUEVO
✅ Loaded 183 events from Hive cache
📤 [EventRepository] Emitting 183 events to stream
```

✅ **Test 3 PASS** si app arranca sin crashes

---

### 🧪 Test 4: CDC en Subscriptions (Sin Refetch)

**Acción:** En la app, ir a Subscriptions y eliminar una suscripción

**Logs esperados:**
```
📝 [API] DELETE: .../users/8/subscribe [subscriptions_screen.dart:195]
📡 [SubscriptionRepository] CDC DELETE: event_interactions
🗑️ [SubscriptionRepository] User unsubscribed from event X - removing from cache
📤 [SubscriptionRepository] Emitting 2 subscriptions to stream

# IMPORTANTE: NO debe haber GET /users/1/subscriptions
```

✅ **Test 4 PASS** si NO hay GET después del DELETE

---

### 🧪 Test 5: CDC Stats Funcionan

**Acción:** Crear un evento nuevo desde la app

**Logs esperados:**
```
📝 [API] POST: .../events [event_service.dart:XX]
📡 [EventRepository] CDC INSERT: events
📊 [SubscriptionRepository] CDC UPDATE: user_subscription_stats  ← NUEVO
📊 [SubscriptionRepository] Stats updated for user 1: events=11, new=6, subscribers=2
📤 [SubscriptionRepository] Emitting 3 subscriptions to stream
```

✅ **Test 5 PASS** si aparecen logs de stats CDC

---

### 🧪 Test 6: Performance

**Medir latencia de actualización:**

1. Abrir cronómetro
2. Crear evento en la app
3. Medir cuánto tarda en aparecer en EventsScreen

**Resultado esperado:** < 100ms

✅ **Test 6 PASS** si es casi instantáneo

---

### 🧪 Test 7: Consistencia Arquitectónica

```bash
# Verificar que ambos usan StreamProvider
grep "ref.watch.*StreamProvider" app_flutter/lib/screens/events_screen.dart
grep "ref.watch.*StreamProvider" app_flutter/lib/screens/subscriptions_screen.dart
```

**Logs esperados:**
```
events_screen.dart: final eventsAsync = ref.watch(eventsStreamProvider);
subscriptions_screen.dart: final subscriptionsAsync = ref.watch(subscriptionsStreamProvider);
```

✅ **Test 7 PASS** si ambos usan mismo patrón

---

## Rollback y Troubleshooting

### 🔄 Rollback Completo

```bash
# 1. Restaurar archivos desde backup
cp backups/YYYYMMDD_HHMMSS/01_init.sql database/init/
cp backups/YYYYMMDD_HHMMSS/subscription_repository.dart.backup app_flutter/lib/repositories/subscription_repository.dart
cp backups/YYYYMMDD_HHMMSS/events_screen.dart.backup app_flutter/lib/screens/events_screen.dart

# 2. Eliminar modelo nuevo
rm backend/models/user_subscription_stats.py

# 3. Limpiar __init__.py
# Editar backend/models/__init__.py y eliminar línea:
# from .user_subscription_stats import UserSubscriptionStats

# 4. Recrear BD
./start.sh stop
docker volume rm agenda_phoenix_db_data
./start.sh backend
```

### 🔴 Problemas Comunes

#### Problema 1: "Tabla user_subscription_stats no existe"

**Síntoma:**
```
ERROR: relation "user_subscription_stats" does not exist
```

**Solución:**
```bash
# Recrear BD desde cero
./start.sh stop
docker volume rm agenda_phoenix_db_data
./start.sh backend
```

#### Problema 2: "No recibo eventos CDC de stats"

**Síntoma:** No aparecen logs de `📊 [SubscriptionRepository] CDC UPDATE: user_subscription_stats`

**Verificar:**
```bash
# 1. Verificar que REPLICA IDENTITY está configurado
docker exec agenda_phoenix_db psql -U postgres -d postgres -c "
SELECT relname, relreplident
FROM pg_class
WHERE relname = 'user_subscription_stats';
"

# Debe retornar: relreplident = 'f' (FULL)
```

**Solución:**
```bash
docker exec agenda_phoenix_db psql -U postgres -d postgres -c "
ALTER TABLE user_subscription_stats REPLICA IDENTITY FULL;
"
```

#### Problema 3: "Stats no se actualizan"

**Síntoma:** Triggers no disparan

**Verificar triggers:**
```bash
docker exec agenda_phoenix_db psql -U postgres -d postgres -c "
SELECT tgname, tgenabled
FROM pg_trigger
WHERE tgname LIKE '%stats%';
"

# tgenabled debe ser 'O' (origin)
```

**Solución:**
```bash
# Re-ejecutar sección de triggers de 01_init.sql
```

#### Problema 4: "EventsScreen crashea"

**Síntoma:**
```
Error: Undefined name 'eventsStreamProvider'
```

**Solución:**
```dart
// Verificar import en events_screen.dart
import '../core/state/app_state.dart';

// Verificar que existe en app_state.dart:
final eventsStreamProvider = StreamProvider<List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.eventsStream;
});
```

#### Problema 5: "App más lenta después de cambios"

**Síntoma:** Latencia mayor a 200ms

**Diagnóstico:**
```bash
# Ver logs en tiempo real
./start.sh backend
# En otra terminal:
./start.sh ios

# Buscar GET innecesarios en logs
```

**Solución:** Revisar que no haya refetch donde no debería

---

## ✅ Checklist Final

Antes de dar por terminado, verifica:

- [ ] Tabla `user_subscription_stats` existe
- [ ] 4 triggers activos
- [ ] Modelo SQLAlchemy creado
- [ ] SubscriptionRepository usa 2 canales CDC
- [ ] EventsScreen usa StreamProvider
- [ ] Logs unificados
- [ ] Test 1-7 pasan
- [ ] Sin GET innecesarios en logs
- [ ] Latencia < 100ms
- [ ] App estable sin crashes

---

## 📊 Métricas de Éxito

| Métrica | Antes | Objetivo | Actual |
|---------|-------|----------|--------|
| API calls (cambio perfil) | 1 GET | 0 | ___ |
| API calls (nueva subscription) | 1 GET | 0 | ___ |
| Latencia actualización | 300ms | 60ms | ___ ms |
| Arquitectura consistente | 50% | 100% | ___ % |
| Triggers activos | 0 | 4 | ___ |

**Estado final:** ⬜ PENDIENTE / ✅ COMPLETO / ❌ FALLIDO

---

## 📝 Notas de Implementación

**Fecha inicio:** ___________
**Fecha fin:** ___________
**Implementado por:** ___________

**Problemas encontrados:**
-
-

**Soluciones aplicadas:**
-
-

**Tiempo total:** _____ horas

---

## 🎯 Siguientes Pasos (Opcional)

1. **Monitoreo:** Configurar alertas si CDC falla
2. **Dashboard:** Crear UI para ver stats en tiempo real
3. **Optimización:** Añadir índices adicionales si es necesario
4. **Documentación:** Actualizar docs del proyecto

---

**Fin del plan de migración**
