# 🔍 Auditoría de Acceso Directo a Supabase

**Fecha:** 23 de Octubre, 2025
**Estado:** EN REVISIÓN

## 📋 Resumen

Se encontraron **8 pantallas** usando `SupabaseService` directamente en lugar del backend API con JWT.

## 🔴 Pantallas Problemáticas

### 1. ✅ subscription_detail_screen.dart (PUEDE MIGRAR)
**Línea:** 48
**Método:** `SupabaseService.instance.fetchPublicUserEvents(publicUserId)`
**Propósito:** Obtener eventos de un usuario público

**Endpoint Backend Disponible:**
```
GET /api/v1/users/{user_id}/events
```

**Acción Requerida:**
- Reemplazar por `ApiClient().fetchUserEvents(publicUserId)`
- El backend ya retorna los eventos con interacciones

---

### 2. ✅ public_user_events_screen.dart (PUEDE MIGRAR)
**Línea 64:** `SupabaseService.instance.fetchPublicUserEvents(userId)`
**Línea 67:** `SupabaseService.instance.isSubscribedToUser(userId, currentUserId)`

**Endpoints Backend Disponibles:**
```
GET /api/v1/users/{user_id}/events
```

**Acción Requerida:**
- Usar `ApiClient().fetchUserEvents(userId)`
- Para `isSubscribedToUser`: puede verificarse desde los datos retornados

---

### 3. ✅ invite_users_screen.dart (PUEDE MIGRAR)
**Línea:** 92
**Método:** `SupabaseService.instance.fetchAvailableInvitees(eventId, currentUserId)`

**Endpoint Backend Disponible:**
```
GET /api/v1/events/{event_id}/available-invitees
```

**Acción Requerida:**
- Ya existe `ApiClient().fetchAvailableInvitees(eventId)`
- Reemplazar la llamada directa a Supabase

---

### 4. ✅ app_state.dart (PUEDE MIGRAR)
**Línea:** 215
**Método:** `SupabaseService.instance.fetchSubscriptions(userId)`

**Endpoint Backend Disponible:**
```
GET /api/v1/interactions?user_id={userId}&interaction_type=subscribed&enriched=true
```

**Acción Requerida:**
- Usar `ApiClient().fetchInteractions(userId: userId, interactionType: 'subscribed', enriched: true)`
- Las subscripciones son interactions de tipo "subscribed"

---

### 5. ✅ event_detail_screen.dart (PUEDE MIGRAR)
**Línea:** 73
**Método:** `SupabaseService.instance.fetchEventDetail(eventId, userId)`

**Endpoint Backend Disponible:**
```
GET /api/v1/events/{event_id}
```

**Acción Requerida:**
- Ya existe `ApiClient().fetchEvent(eventId)`
- Reemplazar la llamada directa a Supabase

---

### 6. ✅ people_groups_screen.dart (PUEDE MIGRAR)
**Línea:** 80
**Método:** `SupabaseService.instance.fetchPeopleAndGroups(userId)`

**Endpoints Backend Disponibles:**
```
GET /api/v1/contacts
GET /api/v1/groups
```

**Acción Requerida:**
- Hacer dos llamadas separadas:
  - `ApiClient().fetchContacts(currentUserId: userId)`
  - `ApiClient().fetchGroups(currentUserId: userId)`
- Combinar los resultados en el cliente

---

### 7. ✅ contact_detail_screen.dart (PUEDE MIGRAR)
**Línea:** 84
**Método:** `SupabaseService.instance.fetchContactDetail(contactId, userId)`

**Endpoint Backend Disponible:**
```
GET /api/v1/contacts/{contact_id}
```

**Acción Requerida:**
- Ya existe `ApiClient().fetchContact(contactId)`
- Reemplazar la llamada directa a Supabase

---

### 8. ✅ subscriptions_screen.dart (PUEDE MIGRAR)
**Línea:** 68
**Método:** `SupabaseService.instance.fetchSubscriptions(userId)`

**Endpoint Backend Disponible:**
```
GET /api/v1/interactions?user_id={userId}&interaction_type=subscribed&enriched=true
```

**Acción Requerida:**
- Usar `ApiClient().fetchInteractions(userId: userId, interactionType: 'subscribed', enriched: true)`
- Mismo caso que app_state.dart (#4)

---

## 📊 Resumen de Estado

| Pantalla | Puede Migrar | Endpoint Existe | Estado |
|----------|--------------|-----------------|--------|
| subscription_detail_screen | ✅ Sí | ✅ Sí | ✅ MIGRADO |
| public_user_events_screen | ✅ Sí | ✅ Sí | ✅ MIGRADO |
| invite_users_screen | ✅ Sí | ✅ Sí | ✅ MIGRADO |
| event_detail_screen | ✅ Sí | ✅ Sí | ✅ MIGRADO |
| contact_detail_screen | ✅ Sí | ✅ Sí | ✅ MIGRADO |
| app_state | ✅ Sí | ✅ Sí | ✅ MIGRADO |
| people_groups_screen | ✅ Sí | ✅ Sí | ✅ MIGRADO |
| subscriptions_screen | ✅ Sí | ✅ Sí | ✅ MIGRADO |

**Total:**
- ✅ MIGRADOS: **8 pantallas (100%)**
- ⏳ PENDIENTES: **0 pantallas**
- ❌ BLOQUEADOS: **0 pantallas**

---

## ✅ Caso Correcto

### api_client.dart (✅ CORRECTO)
**Línea:** 18
**Uso:** `SupabaseService.instance.client.auth.currentSession`

**Por qué está bien:**
- Solo lee el JWT del auth de Supabase
- No accede a datos de la base de datos
- Es necesario para el flujo de autenticación

---

## 🎯 Plan de Acción

### Fase 1: Migraciones Inmediatas ✅ COMPLETADA
1. ✅ subscription_detail_screen.dart - MIGRADO
2. ✅ public_user_events_screen.dart - MIGRADO
3. ✅ invite_users_screen.dart - MIGRADO
4. ✅ event_detail_screen.dart - MIGRADO
5. ✅ contact_detail_screen.dart - MIGRADO

### Fase 2: Verificación de Endpoints ✅ COMPLETADA
1. ✅ Endpoint subscriptions: `/api/v1/interactions` con filtros
2. ✅ Endpoint contacts: `/api/v1/contacts`
3. ✅ Endpoint groups: `/api/v1/groups`
4. ✅ ApiClient actualizado con parámetro `enriched` en `fetchInteractions()`

### Fase 3: Migraciones Finales ✅ COMPLETADA
1. ✅ app_state.dart - MIGRADO a `ApiClient().fetchInteractions()` + procesamiento en cliente
2. ✅ people_groups_screen.dart - MIGRADO a dos llamadas: `fetchContacts()` + `fetchGroups()`
3. ✅ subscriptions_screen.dart - MIGRADO a `ApiClient().fetchInteractions()` + procesamiento en cliente

## ✅ MIGRACIÓN COMPLETADA

**Fecha de Finalización:** 23 de Octubre, 2025

**Resultados:**
- ✅ **8/8 pantallas migradas (100%)**
- ✅ **0 usos problemáticos de Supabase directamente**
- ✅ **Único uso restante:** `api_client.dart` línea 18 (correcto - solo para JWT)

**Verificación Final:**
```bash
grep -r "SupabaseService\.instance\." app_flutter/lib/
# Resultado: Solo api_client.dart:18 (auth.currentSession) ✅
```

---

## 🔐 Beneficios de la Migración

1. **Seguridad:** Todas las peticiones validadas con JWT
2. **Consistencia:** Un solo punto de acceso a datos
3. **Control:** Backend puede aplicar lógica de negocio
4. **Debugging:** Más fácil rastrear problemas
5. **Performance:** Backend puede optimizar queries

---

## 📝 Patrón de Migración

```dart
// ❌ ANTES
final data = await SupabaseService.instance.fetchSomething(id);

// ✅ DESPUÉS
final data = await ApiClient().fetchSomething(id);
```

**Importante:**
- Verificar que el backend retorna los mismos campos
- Ajustar el parseo de datos si es necesario
- Probar que JWT se envía correctamente

---

**Siguiente paso:** Comenzar con la Fase 1 (migraciones inmediatas)
