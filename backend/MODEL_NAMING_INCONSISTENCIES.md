# Model Naming Inconsistencies - Backend vs Flutter

**Date:** 2025-11-07
**Status:** Pending Review

## Overview

This document lists naming inconsistencies found between backend and Flutter models that need to be addressed individually. These are NOT related to the recent Calendar changes (which are already synchronized).

---

## 1. EventInteraction - Confusion entre `note` y `personalNote`

### Current State

**Backend (schemas.py:221-232):**
- `note`: Optional[str] - Campo usado para notas de la interacción
- `rejection_message`: Optional[str] - Mensaje cuando se rechaza

**Backend (models.py:349-434):**
- `note`: Text - Almacena una nota sobre la interacción
- `rejection_message`: Text - Mensaje de rechazo

**Flutter (event_interaction.dart:5-63):**
- `invitationMessage`: String? - Mapeado desde backend `note` (línea 94)
- `decisionMessage`: String? - Mapeado desde backend `rejection_message` (línea 98)
- `personalNote`: String? - Campo adicional que NO existe en backend

### Problem

Flutter tiene dos conceptos de "nota":
1. `invitationMessage` (nota de invitación, mapeada desde `note`)
2. `personalNote` (nota personal del usuario, NO existe en backend)

Pero el backend solo tiene un campo `note` que se está usando para el mensaje de invitación.

### Options

**Option A: Agregar `personal_note` al backend**
- Agregar nuevo campo `personal_note` a EventInteraction en backend
- Mantener `note` para mensajes de invitación
- Mantener `personal_note` para notas personales del usuario
- Flutter ya tiene ambos campos, solo necesita mapear correctamente

**Option B: Eliminar `personalNote` de Flutter**
- Remover el campo `personalNote` de Flutter
- Solo mantener `invitationMessage` mapeado desde backend `note`
- Más simple pero perdemos funcionalidad de notas personales

**Option C: Clarificar uso de `note`**
- Decidir si `note` es para invitaciones O para notas personales
- Unificar el uso en backend y Flutter
- Renombrar campos para claridad

### Recommendation

**Option A** - Agregar `personal_note` al backend porque:
- Flutter ya implementó esta funcionalidad
- Las notas personales son útiles (recordatorios privados del usuario)
- Mantiene separación clara entre mensaje de invitación y nota personal

### Files to Modify

**Backend:**
- `backend/models.py` - Agregar columna `personal_note` a EventInteraction
- `backend/schemas.py` - Agregar `personal_note` a EventInteractionResponse
- `backend/crud/crud_event_interaction.py` - Actualizar CRUD operations
- `backend/func_tests/` - Actualizar tests

**Flutter:**
- `app_flutter/lib/models/event_interaction.dart` - Actualizar fromJson/toJson para mapear `personal_note`

---

## 2. EventInteraction - `read_at` vs múltiples campos de viewed

### Current State

**Backend:**
- `read_at`: Optional[datetime] - Un solo timestamp de cuándo se leyó

**Flutter:**
- `viewed`: bool - Si se ha visto o no
- `firstViewedAt`: DateTime? - Primera vez que se vio
- `lastViewedAt`: DateTime? - Última vez que se vio

### Problem

Backend tiene un solo timestamp, Flutter tiene tres campos para tracking más detallado.

### Options

**Option A: Expandir backend**
- Agregar `first_viewed_at` y `last_viewed_at` al backend
- Mantener `read_at` por compatibilidad (deprecated)
- Flutter mantiene estructura actual

**Option B: Simplificar Flutter**
- Remover `firstViewedAt` y `lastViewedAt` de Flutter
- Mantener solo `readAt` (mapeado desde `read_at`)
- Más simple pero perdemos tracking detallado

**Option C: Mantener como está**
- Backend solo necesita saber si se leyó y cuándo (primera vez)
- Flutter puede mantener tracking adicional client-side
- No sincronizar campos adicionales de Flutter al backend

### Recommendation

**Option C** - Mantener como está porque:
- Backend solo necesita `read_at` (primera vez que se leyó)
- Flutter puede trackear detalles adicionales client-side
- No agrega complejidad innecesaria al backend
- Mapeo: backend `read_at` → Flutter `firstViewedAt`

### Files to Modify

**Flutter:**
- `app_flutter/lib/models/event_interaction.dart` - Clarificar en comentarios que `firstViewedAt` viene de backend `read_at`

---

## 3. Event - `is_birthday` vs `isBirthdayEvent`

### Current State

**Backend:**
- `is_birthday`: Optional[bool] - Campo enriched que indica si es cumpleaños

**Flutter:**
- `isBirthdayEvent`: bool? - Mismo concepto pero nombre diferente

### Problem

Inconsistencia de naming: `is_birthday` vs `isBirthdayEvent`

### Solution

Renombrar en Flutter de `isBirthdayEvent` a `isBirthday` para consistencia.

### Files to Modify

**Flutter:**
- `app_flutter/lib/models/event.dart` - Renombrar campo
- `app_flutter/lib/models/event_hive.dart` - Si existe el campo
- Buscar todos los usos de `isBirthdayEvent` en el código y actualizar

**Search for usages:**
```bash
grep -r "isBirthdayEvent" app_flutter/lib/
```

---

## 4. Event - Campos de subscripción faltantes en Flutter

### Current State

**Backend (enriched fields):**
- `can_subscribe_to_owner`: Optional[bool] - Si se puede subscribir al owner
- `is_subscribed_to_owner`: Optional[bool] - Si está subscrito al owner
- `owner_upcoming_events`: Optional[List] - Eventos próximos del owner
- `invitation_stats`: Optional[InvitationStats] - Stats de invitaciones

**Flutter:**
- NO tiene estos campos

### Problem

Backend devuelve estos campos enriched pero Flutter no los captura.

### Options

**Option A: Agregar campos a Flutter**
- Agregar los 4 campos al modelo Event en Flutter
- Útil si se van a mostrar en UI

**Option B: No agregar (dejar como está)**
- Si no se usan en la UI, no es necesario agregarlos
- Flutter puede ignorar campos del JSON que no necesita

### Recommendation

**Option B** - No agregar hasta que se necesiten porque:
- Principio YAGNI (You Aren't Gonna Need It)
- Agregar complejidad innecesaria
- Si luego se necesitan, es fácil agregarlos

### Action

- Documentar que estos campos existen en backend pero no se usan en Flutter
- Agregar cuando se necesiten para features de UI

---

## 5. EventInteraction - `invited_via_group_id` faltante en Flutter

### Current State

**Backend:**
- `invited_via_group_id`: Optional[int] - ID del grupo usado para invitar

**Flutter:**
- NO tiene este campo

### Problem

Backend trackea por qué grupo se invitó, Flutter no lo captura.

### Solution

Agregar campo `invitedViaGroupId` a Flutter EventInteraction.

### Files to Modify

**Flutter:**
- `app_flutter/lib/models/event_interaction.dart` - Agregar campo
- Agregar a constructor, fromJson, toJson
- No necesita estar en EventInteractionHive a menos que se cache

---

## 6. Subscription Model - Flutter only (user-to-user)

### Current State

**Backend:**
- NO existe modelo de Subscription user-to-user
- Solo existe CalendarSubscription (ya sincronizado)

**Flutter:**
- `lib/models/subscription.dart` - Modelo de subscription user-to-user
- `lib/models/subscription_hive.dart` - Versión Hive

### Problem

Flutter tiene un modelo completo de subscripciones user-to-user que no existe en backend.

### Options

**Option A: Implementar en backend**
- Agregar modelo UserSubscription al backend
- Agregar endpoints para subscribirse a usuarios
- Migrar de sistema actual

**Option B: Eliminar de Flutter**
- Remover modelos de subscription user-to-user
- Solo mantener CalendarSubscription
- Verificar que no se use en el código

**Option C: Investigar uso actual**
- Verificar si actualmente se usa esta funcionalidad
- Determinar si es legacy code o feature activa

### Recommendation

**Option C** primero - Investigar porque:
- No está claro si es legacy code o feature activa
- Si no se usa, removerlo (clean code)
- Si se usa, decidir si implementar en backend o usar otro approach

### Action Required

1. Buscar usos de `Subscription` model en Flutter:
```bash
grep -r "Subscription" app_flutter/lib/ --include="*.dart" | grep -v "CalendarSubscription" | grep -v "StreamSubscription"
```

2. Revisar `SubscriptionRepository` para ver si se usa

3. Decidir: implementar backend, remover de Flutter, o documentar como "planned feature"

---

## 7. RecurringEventConfig - Falta modelo en Flutter

### Current State

**Backend:**
- Modelo completo `RecurringEventConfig` con `recurrence_type`, `schedule`, `recurrence_end_date`

**Flutter:**
- NO tiene modelo dedicado
- Info de recurrencia embebida en Event?

### Problem

Backend tiene soporte completo para eventos recurrentes pero Flutter no tiene modelo para gestionarlo.

### Solution

Agregar modelo `RecurringEventConfig` a Flutter cuando se implemente la feature de eventos recurrentes.

### Recommendation

- **Defer** - No implementar ahora
- Agregar cuando se trabaje en feature de eventos recurrentes
- Documentar como "planned feature"

---

## 8. Modelos de Moderación - Faltan en Flutter

### Current State

**Backend tiene:**
- EventBan
- UserBlock
- AppBan
- EventCancellation
- EventCancellationView

**Flutter:**
- NO tiene ninguno de estos modelos

### Problem

Features de moderación y administración no están disponibles en Flutter.

### Recommendation

- **Defer** - No implementar ahora
- Agregar cuando se necesiten features de administración en app
- Posiblemente solo para admin panel (web), no necesario en mobile app

---

## Priority Summary

### High Priority (Revisar próxima sesión)
1. ✅ EventInteraction - `note` vs `personalNote` (Option A recomendada)
2. ✅ Subscription model - Investigar si se usa (Option C)

### Medium Priority (Cuando se trabaje en features relacionadas)
3. Event - Renombrar `isBirthdayEvent` → `isBirthday`
4. EventInteraction - Agregar `invitedViaGroupId`
5. EventInteraction - Clarificar uso de `read_at` / `viewed` fields

### Low Priority (Defer hasta que se necesite)
6. Event - Campos de subscripción enriched
7. RecurringEventConfig - Agregar modelo cuando se implemente feature
8. Modelos de moderación - Agregar cuando se implemente admin features

---

## Next Steps

1. **Sesión individual para Item #1**: Decidir sobre `note` vs `personalNote`
2. **Investigar Item #6**: ¿Se usa el modelo Subscription en Flutter?
3. **Quick wins**: Items #3 y #4 (renombres simples)
4. **Documentar decisiones**: Actualizar este documento con decisiones tomadas
