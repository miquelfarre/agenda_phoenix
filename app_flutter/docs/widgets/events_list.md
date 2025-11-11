# EventsList - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/events_list.dart`
**Líneas**: 127
**Tipo**: StatelessWidget
**Propósito**: Lista de eventos agrupados por fecha con headers y estado vacío integrado

## 2. CLASE Y PROPIEDADES

### EventsList (líneas 12-126)

**Propiedades**:

| Propiedad | Tipo | Default | Required | Descripción |
|-----------|------|---------|----------|-------------|
| `events` | List<Event> | - | Sí | Lista de eventos a mostrar |
| `onEventTap` | EventTapCallback | - | Sí | Callback al tocar un evento |
| `onDelete` | EventActionCallback | - | Sí | Callback al eliminar un evento |
| `navigateAfterDelete` | bool | false | No | Si navegar después de eliminar |
| `header` | Widget? | null | No | Widget de cabecera opcional |

**Nota**: EventTapCallback y EventActionCallback están definidos en event_list_item.dart

## 3. MÉTODO BUILD

### build(BuildContext context) (líneas 22-48)

**Retorna**: SafeArea con ListView o EmptyState

**Lógica**:

1. **Estado vacío** (líneas 25-27):
   ```dart
   if (events.isEmpty) {
     return EmptyState(
       message: l10n.noEvents,
       icon: CupertinoIcons.calendar
     );
   }
   ```

2. **Agrupamiento** (línea 29):
   ```dart
   final groupedEvents = _groupEventsByDate(events);
   ```

3. **Cálculo de itemCount** (línea 36):
   ```dart
   itemCount = groupedEvents.length + (hasHeader ? 1 : 0)
   ```
   - Si hay header → +1 item
   - Header va en index 0

4. **itemBuilder lógica** (líneas 38-44):
   - Si `hasHeader && index == 0` → retorna header con Padding
   - Sino → calcula `effectiveIndex` y construye date group

5. **Wrapper** (línea 47):
   ```dart
   return SafeArea(
     top: true,
     bottom: false,
     child: listView
   );
   ```

**ListView configuración** (líneas 33-45):
- **physics**: ClampingScrollPhysics() (no rebota en iOS)
- **padding**: Top 12 (iOS) o 8 (otros), Left/Right 8
- **itemCount**: groupedEvents.length + header offset
- **itemBuilder**: Maneja header e items de fecha

## 4. MÉTODOS PRIVADOS

### _groupEventsByDate(List<Event> events) (líneas 50-78)
**Retorna**: `List<Map<String, dynamic>>` con estructura `[{date, events}, ...]`

**Lógica paso a paso**:

**1. Agrupamiento por fecha** (líneas 53-61):
```dart
final Map<String, List<Event>> groupedMap = {};

for (final event in events) {
  final eventDate = event.date;
  // Genera dateKey: 'YYYY-MM-DD' (con padding)
  final dateKey = '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';

  if (!groupedMap.containsKey(dateKey)) {
    groupedMap[dateKey] = [];
  }
  groupedMap[dateKey]!.add(event);
}
```
**Ejemplo dateKey**: '2025-11-03', '2025-12-25'

**2. Ordenamiento por hora dentro de cada día** (líneas 63-69):
```dart
for (final eventList in groupedMap.values) {
  eventList.sort((a, b) {
    return a.date.compareTo(b.date);  // Compara DateTime completo
  });
}
```
**Resultado**: Eventos del mismo día ordenados por hora

**3. Conversión a lista de mapas** (líneas 71-73):
```dart
final groupedList = groupedMap.entries.map((entry) {
  return {'date': entry.key, 'events': entry.value};
}).toList();
```
**Estructura**:
```json
[
  {"date": "2025-11-03", "events": [event1, event2]},
  {"date": "2025-11-04", "events": [event3]},
]
```

**4. Ordenamiento de grupos por fecha** (línea 75):
```dart
groupedList.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
```
**Resultado**: Grupos ordenados cronológicamente (más antiguos primero)

### _buildDateGroup(BuildContext context, Map<String, dynamic> group) (líneas 80-102)
**Retorna**: Column con header de fecha y eventos

**Parámetros**:
- `group`: Map con keys 'date' (String) y 'events' (List<Event>)

**Lógica**:

1. **Extracción** (líneas 81-82):
   ```dart
   final dateStr = group['date'] as String;  // 'YYYY-MM-DD'
   final events = group['events'] as List<Event>;
   ```

2. **Parsing de fecha** (líneas 84-89):
   ```dart
   DateTime date;
   try {
     date = DateTimeUtils.parseAndNormalize('${dateStr}T00:00:00');
   } catch (_) {
     date = DateTimeUtils.parseAndNormalize('${dateStr}T00:00:00');
   }
   ```
   **Nota**: Try-catch redundante (mismo código en ambos bloques)

3. **Formateo** (línea 90):
   ```dart
   final formattedDate = _formatDate(context, date);
   ```

4. **Construcción** (líneas 92-101):
   ```
   Column(crossAxisAlignment: start)
   ├── EventDateHeader(text: formattedDate)
   ├── ...eventos mapeados a EventListItem
   └── SizedBox(height: 16)  // Spacing final
   ```

**Mapeo de eventos** (líneas 96-98):
```dart
...events.map((event) {
  return EventListItem(
    event: event,
    onTap: onEventTap,
    onDelete: onDelete,
    navigateAfterDelete: navigateAfterDelete,
  );
}),
```

### _formatDate(BuildContext context, DateTime date) (líneas 104-125)
**Retorna**: String con fecha formateada en lenguaje natural

**Lógica de comparación** (líneas 106-108):
```dart
final now = DateTime.now();
final today = DateTime(now.year, now.month, now.day);      // Normaliza a medianoche
final eventDate = DateTime(date.year, date.month, date.day);  // Normaliza a medianoche
```

**Casos especiales** (líneas 110-116):

1. **Hoy** (línea 110-111):
   ```dart
   if (eventDate == today) {
     return l10n.today;  // "Hoy", "Today", etc.
   }
   ```

2. **Mañana** (líneas 112-113):
   ```dart
   else if (eventDate == today.add(const Duration(days: 1))) {
     return l10n.tomorrow;  // "Mañana", "Tomorrow", etc.
   }
   ```

3. **Ayer** (líneas 114-116):
   ```dart
   else if (eventDate == today.subtract(const Duration(days: 1))) {
     return l10n.yesterday;  // "Ayer", "Yesterday", etc.
   }
   ```

**Caso general** (líneas 117-123):
```dart
else {
  // Arrays localizados
  final weekdays = [l10n.monday, ..., l10n.sunday];
  final months = [l10n.january, ..., l10n.december];

  // Indexing (DateTime.weekday: 1=Monday, 7=Sunday)
  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];

  // Formato: "Lunes, 3 • Noviembre"
  return '$weekday, ${date.day} ${l10n.dotSeparator} $month';
}
```

**Ejemplos de output**:
- "Hoy"
- "Mañana"
- "Ayer"
- "Lunes, 3 • Noviembre"
- "Viernes, 25 • Diciembre"

## 5. COMPONENTES EXTERNOS

### EmptyState (línea 26)
**Usado cuando**: `events.isEmpty`
**Props**: message, icon
**Propósito**: Mostrar estado vacío con mensaje localizado

### EventDateHeader (línea 95)
**Usado en**: Cada grupo de fecha
**Props**: text (formattedDate)
**Propósito**: Header visual para separar grupos

### EventListItem (línea 97)
**Usado en**: Cada evento dentro del grupo
**Props**: event, onTap, onDelete, navigateAfterDelete
**Propósito**: Render individual de evento

## 6. ESTRUCTURA VISUAL

```
SafeArea
└── ListView.builder
    ├── [Opcional] Header widget (index 0)
    └── Grupos de fecha
        └── Column por cada grupo
            ├── EventDateHeader ("Hoy", "Lunes, 3 • Nov", etc.)
            ├── EventListItem (evento 1)
            ├── EventListItem (evento 2)
            ├── ...
            └── SizedBox(height: 16)
```

## 7. FLUJO DE DATOS

```
events (List<Event>)
  ↓
_groupEventsByDate()
  ↓
groupedEvents: [
  {date: '2025-11-03', events: [e1, e2]},
  {date: '2025-11-04', events: [e3]}
]
  ↓
ListView.builder
  ↓ (por cada grupo)
_buildDateGroup()
  ↓
_formatDate() → "Hoy" | "Lunes, 3 • Nov"
  ↓
Column
  ├── EventDateHeader("Hoy")
  ├── EventListItem(e1)
  └── EventListItem(e2)
```

## 8. COMPORTAMIENTO ESPECIAL

### Header opcional:
- Si `header != null` → se renderiza en index 0
- Resto de items tienen offset +1
- Padding personalizado: h8, v4

### Empty state automático:
- No requiere check en parent
- Maneja `events.isEmpty` internamente
- Usa icono de calendario

### Ordenamiento multi-nivel:
1. **Por fecha**: Grupos ordenados cronológicamente
2. **Por hora**: Eventos dentro del grupo ordenados por hora

### Date key format:
- **Formato**: 'YYYY-MM-DD'
- **Padding**: Mes y día con 2 dígitos
- **Ejemplo**: '2025-11-03', '2025-12-25'
- **Propósito**: Sorting lexicográfico funciona correctamente

### Platform-aware padding:
```dart
padding: EdgeInsets.only(
  top: PlatformDetection.isIOS ? 12.0 : 8.0,
  left: 8.0,
  right: 8.0
)
```

## 9. LOCALIZACIÓN

### Strings usados:
- `l10n.noEvents`: "No hay eventos", "No events"
- `l10n.today`: "Hoy", "Today"
- `l10n.tomorrow`: "Mañana", "Tomorrow"
- `l10n.yesterday`: "Ayer", "Yesterday"
- `l10n.monday` hasta `l10n.sunday`: Días de la semana
- `l10n.january` hasta `l10n.december`: Meses
- `l10n.dotSeparator`: " • " o separador localizado

### Date format localizado:
- Usa strings localizados para días y meses
- Formato puede variar según idioma
- Separador (•) también localizable

## 10. DEPENDENCIAS

**Imports**:
- flutter/cupertino.dart
- models/event.dart
- widgets/empty_state.dart
- widgets/event_date_header.dart
- widgets/event_list_item.dart
- utils/datetime_utils.dart
- helpers/platform_detection.dart
- helpers/l10n_helpers.dart

## 11. CASOS DE USO

### Pantalla de eventos principal:
```dart
EventsList(
  events: allEvents,
  onEventTap: (event) => _navigateToDetail(event),
  onDelete: _deleteEvent,
)
```

### Con header:
```dart
EventsList(
  events: upcomingEvents,
  onEventTap: _navigateToDetail,
  onDelete: _deleteEvent,
  header: Text('Próximos eventos', style: headerStyle),
)
```

### Con navegación post-delete:
```dart
EventsList(
  events: calendarEvents,
  onEventTap: _navigateToDetail,
  onDelete: _deleteEvent,
  navigateAfterDelete: true,  // Navega al eliminar
)
```

## 12. LIMITACIONES Y NOTAS

### Try-catch redundante (líneas 85-89):
```dart
try {
  date = DateTimeUtils.parseAndNormalize('${dateStr}T00:00:00');
} catch (_) {
  date = DateTimeUtils.parseAndNormalize('${dateStr}T00:00:00');  // ← Mismo código
}
```
**Problema**: Si falla en try, fallará en catch también

### ClampingScrollPhysics:
- No rebota en iOS (comportamiento no-estándar)
- Deliberado para este widget

### Date normalization:
- Usa medianoche para comparaciones
- Ignora hora al comparar fechas

### No scroll controller expuesto:
- No permite scroll programático
- No permite listeners externos

### SafeArea parcial:
- `top: true` → Respeta notch
- `bottom: false` → No respeta bottom safe area

## 13. OPTIMIZACIONES

### Sorting efficiency:
- Sort se hace una vez al agrupar
- No re-sort en cada rebuild

### Key en EventListItem:
- EventListItem genera key automático por event.id
- Ayuda a Flutter a optimizar re-renders

### Const donde posible:
- `const Duration(days: 1)`
- `const EdgeInsets...`
- `const SizedBox(height: 16)`

## 14. NOTAS ADICIONALES

- **StatelessWidget**: Sin estado, puramente presentacional
- **Agrupamiento dinámico**: Funciona con cualquier cantidad de eventos y fechas
- **Fecha ISO**: Usa formato ISO para date keys (YYYY-MM-DD)
- **DateTime comparisons**: Normaliza a medianoche para comparar solo fechas
- **Spacing consistente**: 16px entre grupos
- **Empty state integrado**: No requiere manejo en parent
- **Header flexible**: Acepta cualquier Widget
- **Callbacks requeridos**: onEventTap y onDelete son required (aunque podrían ser opcionales)
- **Locale-aware**: Todo el formateo de fechas está localizado
- **No pagination**: Muestra todos los eventos sin paginación
- **No search/filter**: Solo visualización, no filtra
- **Usado extensivamente**: EventsScreen, CalendarEventsScreen, PublicUserEventsScreen
