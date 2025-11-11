# Corrección de Consistencia en Repositorios - Enero 2025

## Problema Identificado por el Usuario

El usuario identificó una **inconsistencia crítica** en los imports de los repositorios:

- ❌ **UserRepository**: NO tenía imports de Hive, Supabase, RealtimeSync
- ✅ **EventRepository**: SÍ tenía todos los imports necesarios
- ✅ **SubscriptionRepository**: SÍ tenía todos los imports necesarios

## Causa del Problema

Inicialmente se asumió que UserRepository no necesitaba Realtime/Hive porque solo gestiona el usuario actual (singleton). Sin embargo, el usuario clarificó que **TODA la aplicación debe usar Realtime y caché consistentemente**.

## Solución Implementada

### UserRepository Refactorizado Completamente

**Archivo**: `lib/repositories/user_repository.dart`

#### 1. Imports Añadidos (Ahora consistente con EventRepository y SubscriptionRepository)

```dart
// ANTES (inconsistente):
import 'dart:async';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/config_service.dart';
import '../services/supabase_auth_service.dart';
import '../utils/app_exceptions.dart' as exceptions;

// DESPUÉS (consistente):
import 'dart:async';
import 'package:hive_ce/hive.dart';                    // ✅ AÑADIDO
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ AÑADIDO
import '../core/realtime_sync.dart';                   // ✅ AÑADIDO
import '../models/user.dart' as models;                // ✅ MODIFICADO (alias para evitar conflicto)
import '../models/user_hive.dart';                     // ✅ AÑADIDO
import '../services/api_client.dart';
import '../services/supabase_service.dart';            // ✅ AÑADIDO
import '../services/config_service.dart';
import '../services/supabase_auth_service.dart';
import '../utils/app_exceptions.dart' as exceptions;
import '../utils/realtime_filter.dart';                // ✅ AÑADIDO
```

**Nota importante**: Se usa `as models` para el import de `User` porque `supabase_flutter` también exporta una clase `User`, causando un conflicto de nombres. Este es el mismo patrón usado en `SubscriptionRepository`.

#### 2. Propiedades de Clase Añadidas

```dart
class UserRepository {
  static const String _boxName = 'current_user';        // ✅ AÑADIDO
  final SupabaseService _supabaseService = SupabaseService.instance; // ✅ AÑADIDO
  final _apiClient = ApiClient();
  final RealtimeSync _rt = RealtimeSync();              // ✅ AÑADIDO

  Box<UserHive>? _box;                                  // ✅ AÑADIDO
  RealtimeChannel? _userChannel;                        // ✅ AÑADIDO
  final StreamController<models.User?> _currentUserController = ...
  models.User? _cachedCurrentUser;                      // ✅ MODIFICADO (models.User)

  // ... resto del código
}
```

#### 3. Método `initialize()` Refactorizado

```dart
// ANTES (sin Hive/Realtime):
Future<void> initialize() async {
  if (_initCompleter.isCompleted) return;

  try {
    await _loadCurrentUser();

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  } catch (e) {
    if (!_initCompleter.isCompleted) {
      _initCompleter.completeError(e);
    }
    rethrow;
  }
}

// DESPUÉS (con Hive/Realtime):
Future<void> initialize() async {
  if (_initCompleter.isCompleted) return;

  try {
    _box = await Hive.openBox<UserHive>(_boxName);       // ✅ AÑADIDO

    // Load current user from Hive cache first
    _loadCurrentUserFromHive();                          // ✅ AÑADIDO

    // Fetch and sync from API
    await _loadCurrentUser();

    // Subscribe to Realtime updates for current user
    await _startRealtimeSubscription();                  // ✅ AÑADIDO

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  } catch (e) {
    if (!_initCompleter.isCompleted) {
      _initCompleter.completeError(e);
    }
    rethrow;
  }
}
```

#### 4. Nuevos Métodos Añadidos

##### a) `_loadCurrentUserFromHive()`
```dart
void _loadCurrentUserFromHive() {
  if (_box == null) return;

  try {
    final configService = ConfigService.instance;
    final userId = configService.currentUserId;
    final userHive = _box!.get(userId);
    if (userHive != null) {
      _cachedCurrentUser = userHive.toUser();
    }
  } catch (e) {
    _cachedCurrentUser = null;
  }
}
```

##### b) `_startRealtimeSubscription()`
```dart
Future<void> _startRealtimeSubscription() async {
  final configService = ConfigService.instance;
  if (!configService.hasUser) return;

  final userId = configService.currentUserId;

  _userChannel = _supabaseService.client
      .channel('user_${userId}_changes')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'users',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: userId.toString(),
        ),
        callback: _handleUserChange,
      )
      .subscribe();
}
```

##### c) `_handleUserChange()`
```dart
void _handleUserChange(PostgresChangePayload payload) {
  if (!RealtimeFilter.shouldProcessEvent(payload, 'user', _rt)) {
    return;
  }

  try {
    final userData = payload.newRecord;
    final updatedUser = models.User.fromJson(userData);

    _cachedCurrentUser = updatedUser;

    // Update Hive cache
    final userHive = UserHive.fromUser(updatedUser);
    _box?.put(updatedUser.id, userHive);

    _emitCurrentUser();
    // ignore: empty_catches
  } catch (e) {
    // Intentionally ignore realtime handler errors
  }
}
```

##### d) `_updateLocalCache()`
```dart
Future<void> _updateLocalCache(models.User user) async {
  if (_box == null) return;

  try {
    final userHive = UserHive.fromUser(user);
    await _box!.put(user.id, userHive);
    // ignore: empty_catches
  } catch (e) {
    // Intentionally ignore cache update errors
  }
}
```

#### 5. Método `_loadCurrentUser()` Actualizado

```dart
// Añadidas 2 líneas en cada rama del try:
await _updateLocalCache(_cachedCurrentUser!);           // ✅ AÑADIDO
_rt.setServerSyncTs(DateTime.now().toUtc());           // ✅ AÑADIDO
```

Se añaden estas líneas después de cargar el usuario para:
1. Guardar en caché de Hive
2. Establecer timestamp de sincronización para filtrar eventos históricos de Realtime

#### 6. Método `dispose()` Actualizado

```dart
// ANTES:
void dispose() {
  _currentUserController.close();
}

// DESPUÉS:
void dispose() {
  _userChannel?.unsubscribe();                          // ✅ AÑADIDO
  _currentUserController.close();
  _box?.close();                                        // ✅ AÑADIDO
}
```

#### 7. Todos los Tipos `User` Cambiados a `models.User`

Para evitar el conflicto con `supabase_flutter/User`, todos los tipos se cambiaron:

- `User?` → `models.User?`
- `List<User>` → `List<models.User>`
- `User.fromJson()` → `models.User.fromJson()`

---

## Arquitectura Final Consistente

### Todos los Repositorios Ahora Siguen el Mismo Patrón

```dart
// ESTRUCTURA ESTÁNDAR DE REPOSITORY (UserRepository, EventRepository, SubscriptionRepository)

import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/realtime_sync.dart';
import '../models/[model].dart' as models;  // Con alias si hay conflicto
import '../models/[model]_hive.dart';
import '../services/api_client.dart';
import '../services/supabase_service.dart';
import '../services/config_service.dart';
import '../utils/app_exceptions.dart' as exceptions;
import '../utils/realtime_filter.dart';

class [Name]Repository {
  static const String _boxName = '[box_name]';
  final SupabaseService _supabaseService = SupabaseService.instance;
  final _apiClient = ApiClient();
  final RealtimeSync _rt = RealtimeSync();

  Box<[Model]Hive>? _box;
  RealtimeChannel? _channel;
  final StreamController<[Type]> _controller = StreamController<[Type]>.broadcast();
  [Type] _cached[Data];

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  Stream<[Type]> get [stream] async* {
    if (_cached[Data] != null/isNotEmpty) {
      yield _cached[Data];
    }
    yield* _controller.stream;
  }

  Future<void> initialize() async {
    if (_initCompleter.isCompleted) return;

    try {
      _box = await Hive.openBox<[Model]Hive>(_boxName);
      _load[Data]FromHive();
      await _fetchAndSync();
      await _startRealtimeSubscription();
      _emit[Current][Data]();

      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
      rethrow;
    }
  }

  void _load[Data]FromHive() { /* Carga desde Hive */ }

  Future<void> _fetchAndSync() {
    /* Fetch desde API + Update cache + Set sync timestamp */
  }

  Future<void> _startRealtimeSubscription() {
    /* Suscripción a cambios de Supabase */
  }

  void _handle[RealtimeEvent](PostgresChangePayload payload) {
    /* Maneja cambios en tiempo real */
  }

  Future<void> _updateLocalCache([Data]) {
    /* Actualiza Hive */
  }

  void _emit[Current][Data]() {
    /* Emite al Stream */
  }

  void dispose() {
    _channel?.unsubscribe();
    _controller.close();
    _box?.close();
  }
}
```

---

## Beneficios de la Consistencia

### 1. Caché Local Completa
✅ UserRepository ahora guarda el usuario actual en Hive
✅ Disponible offline instantáneamente
✅ Persiste entre reinicios de la app

### 2. Sincronización en Tiempo Real
✅ Cambios en el perfil del usuario se reflejan automáticamente
✅ Si admin cambia permisos, el usuario lo ve inmediatamente
✅ Actualizaciones de foto de perfil, nombre, etc. en tiempo real

### 3. Arquitectura Predecible
✅ Todos los repositorios funcionan igual
✅ Fácil de entender para nuevos desarrolladores
✅ Patrón claro para añadir nuevos repositorios

### 4. Performance
✅ Primera carga instantánea desde Hive
✅ Network request en segundo plano
✅ UI nunca se bloquea esperando datos

---

## Comparación de Imports

### Antes de la Corrección

| Repositorio | Hive | Supabase | RealtimeSync | Hive Model | Utils |
|-------------|------|----------|--------------|------------|-------|
| UserRepository | ❌ | ❌ | ❌ | ❌ | ❌ |
| EventRepository | ✅ | ✅ | ✅ | ✅ | ✅ |
| SubscriptionRepository | ✅ | ✅ | ✅ | ✅ | ✅ |

**Resultado**: ❌ Inconsistente

### Después de la Corrección

| Repositorio | Hive | Supabase | RealtimeSync | Hive Model | Utils |
|-------------|------|----------|--------------|------------|-------|
| UserRepository | ✅ | ✅ | ✅ | ✅ | ✅ |
| EventRepository | ✅ | ✅ | ✅ | ✅ | ✅ |
| SubscriptionRepository | ✅ | ✅ | ✅ | ✅ | ✅ |

**Resultado**: ✅ 100% Consistente

---

## Verificación

### Flutter Analyze
```bash
flutter analyze
```

**Resultado**:
- ✅ 0 errores
- ⚠️ Warnings solo de imports no usados (limpiables)
- ℹ️ Info solo de prints (aceptables)

### Pruebas Necesarias

1. **Caché de Usuario**:
   - [ ] Verificar que el usuario se guarda en Hive al hacer login
   - [ ] Cerrar app y reabrir: usuario debe cargar instantáneamente desde Hive
   - [ ] Verificar que cambios en perfil se sincronizan con servidor

2. **Realtime del Usuario**:
   - [ ] Cambiar nombre de usuario desde admin panel
   - [ ] Verificar que el cambio aparece en la app automáticamente
   - [ ] Cambiar foto de perfil remotamente
   - [ ] Verificar que la UI se actualiza sin refrescar

3. **Compatibilidad**:
   - [ ] Verificar que todos los providers siguen funcionando
   - [ ] Verificar que las pantallas que usan `currentUserStream` funcionan
   - [ ] Verificar logout (debe limpiar Hive)

---

## Conclusión

UserRepository ahora tiene **100% de consistencia** con EventRepository y SubscriptionRepository:

✅ **Mismos imports**
✅ **Misma estructura de clase**
✅ **Mismo flujo de inicialización**
✅ **Misma gestión de caché**
✅ **Misma suscripción a Realtime**
✅ **Mismo patrón de dispose**

**La arquitectura es ahora completamente coherente y predecible en toda la aplicación.**

---

**Fecha de corrección**: Enero 2025
**Reportado por**: Usuario
**Implementado por**: Claude Code Assistant
