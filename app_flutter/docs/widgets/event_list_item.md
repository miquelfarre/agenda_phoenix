# EventListItem - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/event_list_item.dart`
**Líneas**: 30
**Tipo**: StatelessWidget
**Propósito**: Wrapper simplificado de EventCard optimizado para uso en listas, con configuración predeterminada conveniente

## 2. TYPEDEFS

### EventTapCallback (línea 6)
```dart
typedef EventTapCallback = void Function(Event event)
```
**Propósito**: Tipo para callbacks al tocar un evento

### EventActionCallback (línea 7)
```dart
typedef EventActionCallback = Future<void> Function(Event event, {bool shouldNavigate})
```
**Propósito**: Tipo para callbacks de acciones async (ej: onDelete)

## 3. CLASE Y PROPIEDADES

### EventListItem (líneas 9-29)

**Propiedades**:

| Propiedad | Tipo | Default | Required | Descripción |
|-----------|------|---------|----------|-------------|
| `event` | Event | - | Sí | El evento a mostrar |
| `onTap` | EventTapCallback | - | Sí | Callback al tocar el evento |
| `onDelete` | EventActionCallback? | null | No | Callback al eliminar |
| `navigateAfterDelete` | bool | false | No | Si navegar después de eliminar |
| `hideInvitationStatus` | bool | false | No | Si ocultar el estado de invitación |
| `showDate` | bool | false | No | Si mostrar fecha en time container |
| `showNewBadge` | bool | true | No | Si mostrar badge "NEW" |

## 4. CONSTRUCTOR

### Constructor (línea 18)

**Firma**:
```dart
const EventListItem({
  super.key,
  required this.event,
  required this.onTap,
  this.onDelete,
  this.navigateAfterDelete = false,
  this.hideInvitationStatus = false,
  this.showDate = false,
  this.showNewBadge = true,
})
```

**Características**:
- Const constructor
- Solo 2 parámetros required: `event` y `onTap`
- Resto opcionales con defaults sensibles para listas

## 5. MÉTODO BUILD

### build(BuildContext context) (líneas 21-28)

**Retorna**: EventCard configurado

**Estructura**:
```
EventCard
├── key: 'event_list_item_{event.id}'
├── event: event
├── onTap: () => onTap(event)
└── config: EventCardConfig(...)
```

**Configuración del EventCardConfig** (línea 26):
```dart
EventCardConfig(
  onDelete: onDelete,
  navigateAfterDelete: navigateAfterDelete,
  showNewBadge: showNewBadge,
  showInvitationStatus: !hideInvitationStatus,  // ← Invertido
  showDate: showDate,
)
```

**Lógica de key** (línea 23):
- Key único por evento: `'event_list_item_${event.id}'`
- Ayuda a Flutter a identificar items en listas mutables

**Lógica de onTap** (línea 25):
- Wrapper: `() => onTap(event)`
- EventCard espera `VoidCallback`
- EventListItem expone `EventTapCallback` (con parámetro event)

## 6. MAPEO DE PROPIEDADES

### EventListItem → EventCard

| EventListItem | EventCard | Transformación |
|---------------|-----------|----------------|
| `event` | `event` | Directo |
| `onTap` | `onTap` | Wrapper: `() => onTap(event)` |
| `onDelete` | `config.onDelete` | Via config |
| `navigateAfterDelete` | `config.navigateAfterDelete` | Via config |
| `showNewBadge` | `config.showNewBadge` | Via config |
| `hideInvitationStatus` | `config.showInvitationStatus` | **Invertido**: `!hideInvitationStatus` |
| `showDate` | `config.showDate` | Via config |

## 7. DIFERENCIAS CON EventCard

### API más simple:
- **EventListItem**: Expone propiedades planas
- **EventCard**: Requiere EventCardConfig object

### Inversión de lógica:
- **EventListItem**: `hideInvitationStatus` (hide = true oculta)
- **EventCard**: `showInvitationStatus` (show = true muestra)
- **Mapeo**: `showInvitationStatus = !hideInvitationStatus`

### Defaults optimizados para listas:
| Propiedad | EventListItem | EventCard (via config) |
|-----------|---------------|------------------------|
| `showNewBadge` | true | false |
| `showDate` | false | false |
| `showInvitationStatus` | true (hideInvitationStatus=false) | false |

### Callback simplificado:
- **EventListItem**: `onTap(Event event)` - Recibe el evento
- **EventCard**: `onTap()` - Sin parámetros, solo VoidCallback

## 8. USO TÍPICO

### En ListView:
```dart
ListView.builder(
  itemCount: events.length,
  itemBuilder: (context, index) {
    return EventListItem(
      event: events[index],
      onTap: (event) => _navigateToDetail(event),
      onDelete: _deleteEvent,
      showNewBadge: true,
      showDate: true,
    );
  },
)
```

### Comparado con EventCard directo:
```dart
// Con EventListItem (más simple)
EventListItem(
  event: event,
  onTap: (e) => _navigate(e),
  showNewBadge: true,
)

// Con EventCard (más verbose)
EventCard(
  event: event,
  onTap: () => _navigate(event),  // ← Necesita closure
  config: EventCardConfig(
    showNewBadge: true,
  ),
)
```

## 9. CUANDO USAR EventListItem vs EventCard

### Usa EventListItem cuando:
- Estás creando una lista de eventos
- Quieres API simple y conveniente
- Los defaults (showNewBadge=true, etc.) son apropiados
- No necesitas customización avanzada

### Usa EventCard cuando:
- Necesitas control total sobre la configuración
- Quieres usar factories (EventCardConfig.invitation, etc.)
- Necesitas custom widgets (customAvatar, customAction)
- Los defaults de EventListItem no sirven

## 10. PATRONES DE USO

### Lista simple:
```dart
EventListItem(
  event: event,
  onTap: _navigateToDetail,
)
```

### Con eliminación:
```dart
EventListItem(
  event: event,
  onTap: _navigateToDetail,
  onDelete: _deleteEvent,
  navigateAfterDelete: false,
)
```

### Ocultando invitaciones:
```dart
EventListItem(
  event: event,
  onTap: _navigateToDetail,
  hideInvitationStatus: true,  // No mostrar banner/estado
)
```

### Con fecha visible:
```dart
EventListItem(
  event: event,
  onTap: _navigateToDetail,
  showDate: true,  // Mostrar fecha en time container
)
```

### Sin badge NEW:
```dart
EventListItem(
  event: event,
  onTap: _navigateToDetail,
  showNewBadge: false,
)
```

## 11. KEYS Y OPTIMIZACIÓN

### Key único (línea 23):
```dart
key: Key('event_list_item_${event.id}')
```

**Propósito**:
- Identifica cada item de forma única
- Ayuda a Flutter a preservar estado en listas
- Optimiza re-renders en listas mutables

**Cuando importa**:
- Lista se reordena
- Items se añaden/eliminan
- AnimatedList o ReorderableList

## 12. DEPENDENCIAS

**Imports**:
- flutter/widgets.dart (StatelessWidget, Key)
- models/event.dart (Event)
- widgets/event_card.dart (EventCard)
- widgets/event_card/event_card_config.dart (EventCardConfig)

**No depende de**:
- Providers
- Services
- Styles
- Helpers

**Nota**: Es un wrapper puro sin lógica de negocio

## 13. PROPIEDADES NO EXPUESTAS

EventListItem NO expone todas las propiedades de EventCardConfig:

**No disponibles**:
- `showChevron` (siempre true por default de EventCard)
- `showActions` (siempre true por default)
- `showOwner` (siempre true por default)
- `customTitle`, `customSubtitle`, `customStatus`
- `customAvatar`, `customAction`
- `invitationStatus`
- `onEdit`, `onInvite`, `onDeleteSeries`, `onEditSeries`
- `onToggleAcceptance`, `onRejectInvitation`

**Si necesitas estas**: Usa EventCard directamente con EventCardConfig

## 14. TYPEDEFS Y TYPE SAFETY

### EventTapCallback:
```dart
void Function(Event event)
```
- Recibe el evento como parámetro
- Retorna void (sync)
- Usado en `onTap`

### EventActionCallback:
```dart
Future<void> Function(Event event, {bool shouldNavigate})
```
- Recibe el evento como parámetro
- Named parameter `shouldNavigate`
- Retorna Future (async)
- Usado en `onDelete`

**Beneficios**:
- Type safety
- Autocomplete en IDE
- Documentación implícita
- Menos errores de tipo

## 15. VALORES POR DEFECTO DETALLADOS

| Propiedad | Default | Razón |
|-----------|---------|-------|
| `navigateAfterDelete` | false | En listas generalmente no quieres navegar |
| `hideInvitationStatus` | false | En listas sí quieres mostrar invitaciones |
| `showDate` | false | En listas del mismo día no hace falta fecha |
| `showNewBadge` | true | En listas es útil resaltar eventos nuevos |

**Comparado con EventCardConfig defaults**:
- EventListItem.showNewBadge: **true** ← Diferente
- EventCardConfig.showNewBadge: **false**

## 16. NOTAS ADICIONALES

- **Wrapper ligero**: Solo 30 líneas, mínima abstracción
- **Naming semántico**: hideInvitationStatus es más claro para listas que showInvitationStatus
- **Const constructor**: Permite optimizaciones de Flutter
- **Key automático**: Usa event.id para key único (no configurable)
- **Sin estado**: StatelessWidget, puramente presentacional
- **Callback transformación**: Transforma callback con parámetro a VoidCallback
- **Config parcial**: Solo expone subset de EventCardConfig
- **No validación**: No valida que event.id sea único
- **Simplicidad por conveniencia**: Trade-off entre simplicidad y flexibilidad
- **Usado extensivamente**: En EventsScreen, CalendarEventsScreen, PublicUserEventsScreen, etc.
