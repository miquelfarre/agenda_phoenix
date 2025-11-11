# Análisis Exhaustivo: EventsScreen

## 1. Resumen Ejecutivo

**EventsScreen** es una pantalla principal de la aplicación que gestiona la visualización y navegación de eventos. Implementa un sistema de filtrado multinivel (por tipo de evento y búsqueda textual), agrupación temporal de eventos, y diferentes vistas según el estado de los datos. La arquitectura utiliza Riverpod para gestión de estado reactivo, con un enfoque en separación de responsabilidades y adaptabilidad multiplataforma (iOS/Android).

**Características principales:**
- Gestión de 4 tipos de filtros de eventos: todos, mis eventos, suscritos e invitaciones
- Búsqueda en tiempo real por título y descripción
- Agrupación de eventos por fecha con ordenamiento inteligente
- Soporte multiplataforma con UI adaptativa
- Gestión de estados vacíos y sin resultados
- Integración con sistema de permisos y operaciones de eventos

**Complejidad:** Media-Alta (476 líneas, múltiples responsabilidades)

**Ubicación:** `/lib/screens/events_screen.dart`

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **EventListItem** (línea 305)
**Archivo**: `lib/widgets/event_list_item.dart`
**Documentación**: `lib/widgets_md/event_list_item.md`

**Uso en EventsScreen**:
```dart
EventListItem(
  event: event,
  onTap: _navigateToEventDetail,
  onDelete: _deleteEvent,
  navigateAfterDelete: false,
  hideInvitationStatus: !shouldShowStatus
)
```

**Ubicación**: Dentro de `_buildDateGroup()` (línea 305), mapeado para cada evento del grupo
**Propósito**: Renderizar cada evento individual en la lista agrupada
**Configuración específica**:
- `hideInvitationStatus`: Condicional según filtro activo (muestra solo en 'invitations' o 'all' para eventos invitados)

#### **EmptyState** (líneas 444, 449)
**Archivo**: `lib/widgets/empty_state.dart`
**Documentación**: `lib/widgets_md/empty_state.md`

**Uso 1 - Sin resultados de búsqueda** (línea 444):
```dart
EmptyState(
  message: l10n.noEventsFound,
  icon: CupertinoIcons.search
)
```
**Ubicación**: `_buildNoSearchResults()` → llamado cuando hay búsqueda activa pero sin resultados
**Condición**: `events.isEmpty && isFiltered` (línea 221)

**Uso 2 - Sin eventos** (línea 449):
```dart
EmptyState(
  message: l10n.noEvents,
  icon: CupertinoIcons.calendar
)
```
**Ubicación**: `_buildEmptyState()` → llamado cuando no hay eventos en absoluto
**Condición**: `events.isEmpty && !isFiltered` (línea 223)

#### **AdaptiveButton** (líneas 125, 143, 427)
**Archivo**: `lib/widgets/adaptive/adaptive_button.dart`
**Documentación**: `lib/widgets_md/adaptive_button.md`

**Uso 1 - FAB iOS** (línea 125):
```dart
AdaptiveButton(
  config: const AdaptiveButtonConfig(
    variant: ButtonVariant.fab,
    size: ButtonSize.medium,
    fullWidth: false,
    iconPosition: IconPosition.only
  ),
  icon: CupertinoIcons.add,
  onPressed: _showCreateEventOptions,
)
```
**Ubicación**: Stack positioned (bottom: 100, right: 20) en iOS
**Propósito**: Botón flotante para crear evento (solo iOS)

**Uso 2 - FAB Android** (línea 143):
```dart
AdaptiveButton(
  config: const AdaptiveButtonConfig(
    variant: ButtonVariant.fab,
    size: ButtonSize.medium,
    fullWidth: false,
    iconPosition: IconPosition.only
  ),
  icon: CupertinoIcons.add,
  onPressed: _showCreateEventOptions,
)
```
**Ubicación**: `floatingActionButton` del scaffold (solo Android)
**Propósito**: Botón flotante para crear evento (solo Android)

**Uso 3 - Clear search** (línea 427):
```dart
AdaptiveButton(
  key: const Key('events_search_clear_button'),
  config: const AdaptiveButtonConfig(
    variant: ButtonVariant.icon,
    size: ButtonSize.small,
    fullWidth: false,
    iconPosition: IconPosition.only
  ),
  icon: CupertinoIcons.clear,
  onPressed: () { /* clear search */ },
)
```
**Ubicación**: suffixIcon del campo de búsqueda
**Condición**: Solo visible si `_searchQuery.isNotEmpty`

#### **AdaptivePageScaffold** (línea 136)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_scaffold.md`

**Uso**:
```dart
AdaptivePageScaffold(
  key: const Key('events_screen_scaffold'),
  title: isIOS ? null : l10n.events,
  body: body,
  floatingActionButton: !isIOS ? [FAB] : null,
)
```
**Propósito**: Scaffold adaptativo con navegación inferior integrada

### 2.2. Widgets de Platform

#### **PlatformWidgets.platformTextField** (línea 422)
**Uso**:
```dart
PlatformWidgets.platformTextField(
  controller: _searchController,
  placeholder: l10n.searchEvents,
  prefixIcon: PlatformWidgets.platformIcon(CupertinoIcons.search, ...),
  suffixIcon: _searchQuery.isNotEmpty ? [AdaptiveButton clear] : null,
)
```
**Ubicación**: `_buildSearchField()` (línea 420)
**Propósito**: Campo de búsqueda adaptativo iOS/Android

#### **PlatformWidgets.platformLoadingIndicator** (línea 112)
**Uso**: Mostrado durante loading state del AsyncValue
**Ubicación**: Dentro del `eventsAsync.when(loading: ...)`

#### **PlatformWidgets.platformIcon** (líneas 425+)
**Uso**: Icono de búsqueda en prefixIcon del TextField

### 2.3. Widgets de Flutter Core

- **CustomScrollView** con **SliverAppBar** (líneas 189-206): App bar colapsable con título grande
- **SliverToBoxAdapter** (líneas 208, 212): Wrappers para widgets no-sliver
- **SliverList** (línea 233): Lista performante de eventos agrupados
- **SliverFillRemaining** (líneas 222, 224): Para estados vacíos
- **Stack** (línea 117): Para posicionar FAB en iOS
- **Positioned** (línea 120): Posicionamiento del FAB iOS
- **Tooltip** (líneas 123, 141): Tooltips de accesibilidad para FABs

### 2.4. Resumen de Dependencias de Widgets

```
EventsScreen
├── AdaptivePageScaffold (scaffold principal)
├── CustomScrollView
│   ├── SliverAppBar (título grande)
│   ├── SliverToBoxAdapter
│   │   └── PlatformWidgets.platformTextField (búsqueda)
│   │       └── AdaptiveButton (clear, condicional)
│   ├── SliverToBoxAdapter
│   │   └── Filter chips (custom, no widget separado)
│   └── [Condicional]
│       ├── SliverList
│       │   └── Date groups
│       │       └── EventListItem (múltiples)
│       └── SliverFillRemaining
│           └── EmptyState (sin eventos o sin resultados)
└── [Condicional iOS] Stack
    └── Positioned
        └── AdaptiveButton (FAB)
```

**Total de widgets propios**: 4 (EventListItem, EmptyState, AdaptiveButton, AdaptivePageScaffold)
**Total de widgets platform**: 3 (platformTextField, platformLoadingIndicator, platformIcon)

---

## 3. Análisis de la Clase y State

### 3.1. Jerarquía de Clases

```dart
EventsScreen extends ConsumerStatefulWidget
  └─> _EventsScreenState extends ConsumerState<EventsScreen>
```

**Justificación del tipo:** `ConsumerStatefulWidget` permite:
1. Acceso a providers de Riverpod mediante `ref`
2. Mantener estado mutable local (filtros, búsqueda)
3. Ciclo de vida para gestionar controladores

### 2.2. Clases Helper Auxiliares

#### **EventWithInteraction** (líneas 24-31)
```dart
class EventWithInteraction {
  final Event event;
  final String? interactionType;
  final String? invitationStatus;
  final bool isAttending;
}
```

**Propósito:** Envolver eventos con metadatos de interacción del usuario.

**Justificación de propiedades:**
- `event`: Objeto principal del evento
- `interactionType`: Diferencia entre 'invited', 'subscribed' o null (propio)
- `invitationStatus`: Estado de invitación ('accepted', 'rejected', 'pending')
- `isAttending`: Flag booleano para casos especiales (eventos rechazados pero a los que se asiste)

**Uso:** Facilita el filtrado considerando el contexto de interacción sin modificar el modelo `Event` original.

#### **EventsData** (líneas 34-42)
```dart
class EventsData {
  final List<EventWithInteraction> events;
  final int myEventsCount;
  final int invitationsCount;
  final int subscribedCount;
  final int allCount;
}
```

**Propósito:** DTO (Data Transfer Object) que agrupa eventos con contadores precomputados.

**Justificación de propiedades:**
- `events`: Lista completa de eventos enriquecidos
- `myEventsCount`: Contador para badge del filtro "Mis Eventos"
- `invitationsCount`: Contador para badge del filtro "Invitaciones"
- `subscribedCount`: Contador para badge del filtro "Suscritos"
- `allCount`: Contador para badge del filtro "Todos"

**Beneficio:** Evita recalcular contadores en cada render, optimizando performance.

### 2.3. Propiedades de Estado (_EventsScreenState)

#### **_searchController** (línea 52)
```dart
final TextEditingController _searchController = TextEditingController();
```
- **Tipo:** `TextEditingController`
- **Mutabilidad:** `final` (referencia inmutable, contenido mutable)
- **Propósito:** Gestionar el input del campo de búsqueda
- **Justificación:** Requerido por Flutter para campos de texto. Permite acceso programático al texto y escuchar cambios
- **Gestión de memoria:** Correctamente dispuesto en `dispose()`

#### **_currentFilter** (línea 53)
```dart
String _currentFilter = 'all';
```
- **Tipo:** `String`
- **Mutabilidad:** Mutable
- **Valores posibles:** 'all', 'my', 'subscribed', 'invitations'
- **Propósito:** Mantener el filtro de tipo de evento activo
- **Justificación:** Estado local que no necesita persistencia ni compartirse con otros widgets
- **Patrón:** Estado simple sin necesidad de StateNotifier/Controller

#### **_searchQuery** (línea 54)
```dart
String _searchQuery = '';
```
- **Tipo:** `String`
- **Mutabilidad:** Mutable
- **Propósito:** Caché del texto de búsqueda actual
- **Justificación:** Separar el valor del controlador del estado reactivo permite control fino sobre cuándo re-renderizar
- **Optimización:** Evita reconstrucciones innecesarias durante la escritura

### 2.4. Lifecycle Methods

#### **initState()** (líneas 57-65)
```dart
@override
void initState() {
  super.initState();

  _searchController.addListener(() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  });
}
```

**Propósito:** Inicialización del widget y suscripción a cambios del controlador.

**Lógica:**
1. Llama a `super.initState()` (obligatorio)
2. Registra listener al controlador de búsqueda
3. Sincroniza `_searchQuery` con cambios en tiempo real
4. Dispara `setState()` para re-renderizar al cambiar la búsqueda

**Por qué no usar `onChanged` del TextField:**
- Mayor control sobre el ciclo de actualización
- Permite debouncing futuro si es necesario
- Centraliza la lógica de búsqueda

#### **dispose()** (líneas 97-100)
```dart
@override
void dispose() {
  _searchController.dispose();
  super.dispose();
}
```

**Propósito:** Limpieza de recursos para prevenir memory leaks.

**Secuencia:**
1. Libera recursos del `TextEditingController`
2. Llama a `super.dispose()` (obligatorio al final)

**Crítico:** Sin esto, el listener permanecería en memoria causando leaks.

---

## 3. Análisis Método por Método

### 3.1. _buildEventsData() - Construcción de Datos

**Líneas:** 68-94
**Firma:** `static EventsData _buildEventsData(List<Event> events)`
**Complejidad:** O(n) donde n = número de eventos

**Propósito:** Transformar lista de eventos en estructura enriquecida con metadatos de interacción y contadores precomputados.

**Lógica interna:**

1. **Obtención de usuario actual:**
   ```dart
   final userId = ConfigService.instance.currentUserId;
   ```

2. **Enriquecimiento de eventos:**
   - Solo extrae metadatos para eventos no propios
   - Maneja `interactionData` opcional correctamente
   - Complejidad: O(n)

3. **Cálculo de contadores:**
   ```dart
   final myEvents = eventItems.where((e) =>
     EventPermissions.canEdit(event: e.event) ||
     (e.invitationStatus == 'rejected' && e.isAttending)
   ).length;
   ```
   - Caso especial: Eventos rechazados pero con asistencia confirmada
   - Complejidad: O(3n) → **OPTIMIZABLE**

**Optimización identificada:**
```dart
// ACTUAL: 3 iteraciones
final myEvents = eventItems.where(...).length;
final invitations = eventItems.where(...).length;
final subscribed = eventItems.where(...).length;

// PROPUESTA: 1 iteración
int myEvents = 0, invitations = 0, subscribed = 0;
for (final item in eventItems) {
  if (EventPermissions.canEdit(event: item.event) || ...) myEvents++;
  else if (item.interactionType == 'invited' && ...) invitations++;
  else if (item.interactionType == 'subscribed') subscribed++;
}
```

---

### 3.2. build() - Construcción Principal

**Líneas:** 102-151
**Complejidad:** O(1) decisiones + O(n) de `_buildEventsData`

**Flujo de decisión:**

1. **Detección de plataforma:**
   ```dart
   final isIOS = PlatformDetection.isIOS;
   ```

2. **Consumo de stream reactivo:**
   ```dart
   final eventsAsync = ref.watch(eventsStreamProvider);
   ```

3. **Patrón de estados asíncronos:**
   ```dart
   Widget body = eventsAsync.when(
     data: (events) => _buildBody(...),
     loading: () => Center(child: PlatformWidgets.platformLoadingIndicator()),
     error: (e, _) => Center(child: Text('Error: $e')),
   );
   ```

4. **Lógica condicional iOS:**
   - iOS: FAB en Stack posicionado
   - Android: FAB nativo de Material

**Justificación:** Diferentes convenciones de plataforma requieren layouts distintos.

---

### 3.3. _buildContent() - Contenido con Slivers

**Líneas:** 157-218
**Tipo retornado:** `CustomScrollView`

**Arquitectura de slivers:**

1. **SliverToBoxAdapter - Saludo personalizado:**
   - Usa `Consumer` adicional para optimizar rebuilds
   - Solo se reconstruye esta sección al cambiar usuario

2. **SliverToBoxAdapter - Campo de búsqueda:**
   - Campo de texto con botón de limpieza condicional

3. **SliverToBoxAdapter - Filtros:**
   - Chips con contadores

4. **Sliver variable - Contenido:**
   - `SliverFillRemaining` para estados vacíos
   - `SliverList` para lista de eventos

**Pipeline de filtrado:**
```
Eventos originales
  ↓ _applyEventTypeFilterWithInteraction()
Eventos filtrados por tipo
  ↓ Extraer Event de EventWithInteraction
Lista de Events
  ↓ _applySearchFilter() (si hay query)
Eventos filtrados finales
```

**Por qué este orden:** El filtro de tipo reduce el conjunto antes de la búsqueda textual (optimización).

---

### 3.4. _groupEventsByDate() - Agrupación

**Líneas:** 241-272
**Complejidad total:** O(n log n)

**Algoritmo en 4 fases:**

1. **Agrupación por fecha (O(n)):**
   ```dart
   final dateKey = '${event.date.year}-${event.date.month.toString().padLeft(2, '0')}-${event.date.day.toString().padLeft(2, '0')}';
   ```
   - Formato de clave: 'YYYY-MM-DD' (ISO 8601 parcial)
   - `padLeft(2, '0')` asegura formato consistente

2. **Ordenamiento intra-grupo (O(g * k log k)):**
   ```dart
   eventList.sort((a, b) {
     if (a.isBirthday && !b.isBirthday) return -1;
     if (!a.isBirthday && b.isBirthday) return 1;
     return a.date.compareTo(b.date);
   });
   ```
   - Prioridad 1: Cumpleaños primero
   - Prioridad 2: Orden cronológico

3. **Conversión a lista de mapas (O(g)):**
   ```dart
   {'date': entry.key, 'events': entry.value}
   ```

4. **Ordenamiento inter-grupos (O(g log g)):**
   - Orden cronológico ascendente

**Optimización potencial:** Usar `SplayTreeMap` para mantener orden automático durante inserción.

**Problema de diseño:** Uso de `Map<String, dynamic>` en lugar de clase dedicada.

**Recomendación:**
```dart
class DateEventGroup {
  final String date;
  final List<Event> events;
  DateEventGroup({required this.date, required this.events});
}
```

---

### 3.5. _formatDate() - Formateo de Fechas

**Líneas:** 313-334
**Propósito:** Formatear fechas de forma amigable y localizada

**Lógica de etiquetas relativas:**
```dart
if (eventDate == today) return l10n.today;
else if (eventDate == today.add(const Duration(days: 1))) return l10n.tomorrow;
else if (eventDate == today.subtract(const Duration(days: 1))) return l10n.yesterday;
```

**Por qué normalizar a medianoche:** Comparación de días sin considerar horas.

**Formato para otras fechas:**
```dart
'$weekday, ${date.day} ${l10n.dotSeparator} $month'
// Ejemplo: "Lunes, 15 · Enero"
```

**Localización completa:** Nombres de días y meses vienen de l10n.

---

### 3.6. _applyEventTypeFilterWithInteraction() - Filtrado por Tipo

**Líneas:** 356-371
**Complejidad:** O(n)

**Lógica por filtro:**

**'my':**
```dart
EventPermissions.canEdit(event: item.event) ||
(item.invitationStatus == 'rejected' && item.isAttending)
```
- Incluye: Eventos propios, con permisos de admin, rechazados pero asistiendo

**'subscribed':**
```dart
item.event.ownerId != userId && item.interactionType == 'subscribed'
```
- Excluye eventos propios, solo suscritos

**'invitations':**
```dart
item.event.ownerId != userId &&
item.interactionType == 'invited' &&
!(item.invitationStatus == 'rejected' && item.isAttending)
```
- Excluye rechazados con asistencia (van a 'my')

**'all':**
```dart
return items;
```
- Sin filtrado

---

### 3.7. _applySearchFilter() - Búsqueda Textual

**Líneas:** 373-380
**Complejidad:** O(n * m) donde m = longitud promedio de strings

**Campos buscados:**
- `title` (obligatorio)
- `description` (opcional, con null safety)

**Case-insensitive:** Convierte todo a minúsculas.

**Optimización identificada:**
```dart
// ACTUAL: Sin debouncing
_searchController.addListener(() {
  setState(() {
    _searchQuery = _searchController.text;
  });
});

// PROPUESTA: Con debouncing
Timer? _debounceTimer;
_searchController.addListener(() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    setState(() => _searchQuery = _searchController.text);
  });
});
```

**Beneficio:** Reduce rebuilds durante escritura rápida.

---

### 3.8. _deleteEvent() - Eliminación

**Líneas:** 456-466
**Delegación a:** `EventOperations.deleteOrLeaveEvent()`

**Lógica:**
```dart
await EventOperations.deleteOrLeaveEvent(
  event: event,
  repository: ref.read(eventRepositoryProvider),
  context: context,
  shouldNavigate: shouldNavigate,
  showSuccessMessage: false,
);
```

**Comentario importante (líneas 464-465):**
```dart
// EventRepository handles updates via Realtime, but we manually remove
// for non-owners as RLS policies can prevent the DELETE event from broadcasting.
```

**Problema identificado:** El comentario sugiere remoción manual, pero no se implementa.

**Solución esperada:**
```dart
ref.read(eventsStreamProvider.notifier).removeEvent(event.id);
```

**Recomendación:** Implementar remoción manual o actualizar comentario.

---

## 4. Dependencias y Providers

### 4.1. Providers de Riverpod

| Provider | Tipo | Uso | Línea |
|----------|------|-----|-------|
| `eventsStreamProvider` | `AsyncValue<List<Event>>` | Stream reactivo de eventos | 108 |
| `currentUserStreamProvider` | `AsyncValue<User?>` | Usuario autenticado actual | 181 |
| `eventRepositoryProvider` | `EventRepository` | Operaciones CRUD | 459 |

**Por qué `watch` vs `read`:**
- `watch`: Re-renderiza al cambiar datos (eventsStreamProvider, currentUserStreamProvider)
- `read`: Acceso puntual sin reactividad (eventRepositoryProvider en operaciones)

### 4.2. Servicios y Utilidades

| Clase | Tipo | Propósito |
|-------|------|-----------|
| `ConfigService.instance` | Singleton | Acceso a configuración global (userId) |
| `EventPermissions` | Static utility | Lógica centralizada de permisos |
| `EventOperations` | Static utility | Operaciones complejas sobre eventos |

---

## 5. Navegación y Routing

### 5.3. Widgets de Estado

| Widget | Propósito |
|--------|-----------|
| `Consumer` | Re-render localizado |
| `EmptyState` | Estados vacíos consistentes |
| `EventListItem` | Item reutilizable |

---

## 6. Flujo de Datos

```
┌─────────────────────────────┐
│ Supabase Realtime (Events)  │
└──────────┬──────────────────┘
           │ Stream
           ▼
┌─────────────────────────────┐
│  eventsStreamProvider       │
└──────────┬──────────────────┘
           │ AsyncValue<List<Event>>
           ▼
┌─────────────────────────────┐
│  build() - when()           │
│  ├─ loading: Spinner        │
│  ├─ error: Mensaje          │
│  └─ data: Procesamiento     │
└──────────┬──────────────────┘
           │ List<Event>
           ▼
┌─────────────────────────────┐
│  _buildEventsData()         │
│  └─ Enriquece + contadores  │
└──────────┬──────────────────┘
           │ EventsData
           ▼
┌─────────────────────────────┐
│  _buildContent()            │
│  ├─ Filtro de tipo          │
│  └─ Filtro de búsqueda      │
└──────────┬──────────────────┘
           │ List<Event> filtrados
           ▼
┌─────────────────────────────┐
│  _groupEventsByDate()       │
│  └─ Agrupa + ordena         │
└──────────┬──────────────────┘
           │ List<Map>
           ▼
┌─────────────────────────────┐
│  _buildDateGroup()          │
│  └─ EventListItem           │
└─────────────────────────────┘
```

---

## 7. Optimizaciones Identificadas

### 7.1. Código Duplicado

**Problema:** Construcción de FAB duplicada
- Líneas 123-130 (iOS)
- Líneas 140-148 (Android)

**Solución:**
```dart
Widget _buildCreateEventButton() {
  return Tooltip(
    message: context.l10n.createEvent,
    child: AdaptiveButton(...),
  );
}
```

### 7.2. Performance

**Optimización 1: Contadores en un solo pass**
- Actual: O(3n)
- Propuesta: O(n)
- Beneficio: 3x menos iteraciones

**Optimización 2: Debouncing de búsqueda**
- Actual: setState en cada keystroke
- Propuesta: Timer de 300ms
- Beneficio: Menos rebuilds

**Optimización 3: Memoización de agrupación**
- Actual: Re-agrupa en cada build
- Propuesta: Cachear si eventos no cambiaron
- Beneficio: Evita O(n log n) innecesario

### 7.3. Refactorizaciones Sugeridas

**1. Extraer lógica de filtrado:**
```dart
class EventFilterService {
  static List<EventWithInteraction> applyTypeFilter(...) { ... }
  static List<Event> applySearchFilter(...) { ... }
  static EventsData buildEventsData(...) { ... }
}
```

**2. Widget dedicado para filtros:**
```dart
class EventFilterChips extends StatelessWidget {
  final String currentFilter;
  final EventsData eventsData;
  final ValueChanged<String> onFilterChanged;
}
```

**3. Reemplazar Map por clase:**
```dart
class DateEventGroup {
  final String date;
  final List<Event> events;
}
```

---

## 8. Código que Necesita Justificación

### 8.1. Eventos Rechazados pero Asistiendo

**Código:**
```dart
(e.invitationStatus == 'rejected' && e.isAttending)
```

**Pregunta:** ¿Cómo es posible?

**Escenarios posibles:**
1. Usuario rechaza, luego cambia a "asistiré"
2. Invitación múltiple: rechaza invitación formal pero se suscribe al evento público
3. Override de administrador

**Recomendación:** Documentar explícitamente este flujo de negocio.

### 8.2. Comentario sobre RLS (líneas 464-465)

**Problema:** Comentario sugiere implementación manual que no existe.

**Recomendación:** Implementar o actualizar comentario.

### 8.3. Método _showCreateEventOptions

**Código:**
```dart
void _showCreateEventOptions() {
  _navigateToCreateEvent();
}
```

**Justificación probable:** Abstracción para futuro menú de opciones.

**Recomendación:** Añadir comentario explicativo o eliminar si no se usará.

---

## 9. Métricas

### 9.1. Líneas de Código

| Categoría | Líneas | % |
|-----------|--------|---|
| **Total** | **476** | **100%** |
| Imports | 22 | 4.6% |
| Clases Helper | 19 | 4.0% |
| Propiedades y Lifecycle | 49 | 10.3% |
| Lógica de Filtrado | 80 | 16.8% |
| Construcción UI | 267 | 56.1% |
| Navegación y Acciones | 23 | 4.8% |
| Comentarios | 16 | 3.4% |

### 9.2. Métodos

| Tipo | Cantidad |
|------|----------|
| **Total** | **18** |
| Lifecycle | 3 |
| Builders de UI | 9 |
| Lógica de negocio | 4 |
| Navegación/acciones | 3 |

### 9.3. Complejidad Ciclomática

| Método | Complejidad | Clasificación |
|--------|-------------|---------------|
| `_buildEventsData` | 6 | Media |
| `_formatDate` | 7 | Media-Alta |
| `_groupEventsByDate` | 5 | Media |
| `_applyEventTypeFilterWithInteraction` | 5 | Media |
| Resto | 1-3 | Baja |
| **Promedio** | **3.5** | **Baja-Media** |

### 9.4. Dependencias

| Tipo | Cantidad |
|------|----------|
| Packages de Flutter | 3 |
| Módulos internos | 13 |
| - Models | 1 |
| - State Management | 1 |
| - Widgets | 5 |
| - Screens | 2 |
| - Services | 1 |
| - Utils | 2 |
| - Helpers | 3 |

---

## 10. Conclusiones y Recomendaciones

### 10.1. Fortalezas

1. ✅ Arquitectura reactiva sólida con Riverpod
2. ✅ Separación de concerns inicial
3. ✅ UI adaptativa bien implementada
4. ✅ Gestión de estados asíncronos correcta
5. ✅ Localización completa
6. ✅ Accesibilidad (tooltips, mensajes)

### 10.2. Debilidades

1. ❌ Widget demasiado grande (476 líneas)
2. ❌ Lógica de negocio mezclada
3. ❌ Falta de optimizaciones de performance
4. ❌ Código duplicado (FAB)
5. ❌ Testing difícil (métodos privados)
6. ❌ Comentarios obsoletos

### 10.3. Roadmap de Mejoras

**Prioridad Alta:**
1. Extraer lógica de filtrado a servicio
2. Implementar debouncing en búsqueda
3. Optimizar cálculo de contadores
4. Dividir en componentes más pequeños

**Prioridad Media:**
1. Crear `DateEventGroup` class
2. Memoizar eventos agrupados
3. Eliminar duplicación de FAB
4. Documentar caso "rechazado pero asistiendo"

**Prioridad Baja:**
1. Añadir logging en catch
2. Evaluar `_showCreateEventOptions`
3. Mejorar mensajes de error

### 10.4. Propuesta de Refactorización

**Estructura sugerida:**
```
screens/
  events_screen.dart (solo UI, <200 líneas)
services/
  event_filter_service.dart
  event_grouping_service.dart
widgets/
  event_filter_chips.dart
  event_date_group.dart
  event_search_field.dart
models/
  date_event_group.dart
```

**Beneficios:**
- ✅ Testability
- ✅ Reusability
- ✅ Maintainability
- ✅ Readability

---

**Documento generado:** 2025-11-03
**Versión:** events_screen.dart (476 líneas)
**Autor del análisis:** Claude Code (Sonnet 4.5)
