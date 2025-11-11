# EventCardConfig - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/event_card/event_card_config.dart`
**Líneas**: 119
**Tipo**: Data class (configuración)
**Propósito**: Clase inmutable de configuración para EventCard, permite customizar comportamiento y apariencia

## 2. ESTRUCTURA DE LA CLASE

### EventCardConfig (líneas 4-118)

**Tipo**: Immutable configuration class

## 3. PROPIEDADES

### Boolean Flags (líneas 5-11)

| Propiedad | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `showChevron` | bool | true | Mostrar chevron de navegación (→) |
| `showActions` | bool | true | Mostrar botones de acción |
| `showInvitationStatus` | bool | false | Mostrar estado de invitación |
| `showOwner` | bool | true | Mostrar info del owner del evento |
| `navigateAfterDelete` | bool | false | Navegar después de eliminar |
| `showNewBadge` | bool | false | Mostrar badge "NEW" |
| `showDate` | bool | false | Mostrar fecha en time container |

### String Properties (líneas 13-16)

| Propiedad | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `customTitle` | String? | null | Título personalizado (override del título del evento) |
| `customSubtitle` | String? | null | Subtítulo personalizado (override de la descripción) |
| `customStatus` | String? | null | Status adicional personalizado |
| `invitationStatus` | String? | null | Estado de invitación ('pending', 'accepted', 'rejected') |

### Widget Properties (líneas 18-19)

| Propiedad | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `customAvatar` | Widget? | null | Avatar personalizado para el leading |
| `customAction` | Widget? | null | Acción personalizada en el trailing |

### Callback Properties (líneas 21-27)

| Propiedad | Tipo | Parámetros | Descripción |
|-----------|------|------------|-------------|
| `onDelete` | Function? | Event, {bool shouldNavigate} | Callback al eliminar evento |
| `onEdit` | Function? | Event | Callback al editar evento |
| `onInvite` | Function? | Event | Callback al invitar usuarios |
| `onDeleteSeries` | Function? | Event, {bool shouldNavigate} | Callback al eliminar serie completa |
| `onEditSeries` | Function? | Event | Callback al editar serie completa |
| `onToggleAcceptance` | Function? | int invitationId | Callback al toggle aceptación |
| `onRejectInvitation` | Function? | int invitationId | Callback al rechazar invitación |

## 4. CONSTRUCTOR

### Constructor principal (líneas 29-50)

**Firma**:
```dart
const EventCardConfig({
  this.showChevron = true,
  this.showActions = true,
  this.showInvitationStatus = false,
  this.showOwner = true,
  this.navigateAfterDelete = false,
  this.showNewBadge = false,
  this.showDate = false,
  this.customTitle,
  this.customSubtitle,
  this.customStatus,
  this.invitationStatus,
  this.customAvatar,
  this.customAction,
  this.onDelete,
  this.onEdit,
  this.onInvite,
  this.onDeleteSeries,
  this.onEditSeries,
  this.onToggleAcceptance,
  this.onRejectInvitation,
})
```

**Características**:
- Const constructor (inmutable)
- Todos los parámetros son opcionales
- Valores por defecto para booleans
- Nullable para strings, widgets y callbacks

## 5. MÉTODOS

### copyWith(...) (líneas 52-96)
**Retorna**: Nueva instancia de EventCardConfig con propiedades actualizadas

**Propósito**: Crear nueva configuración basada en la actual pero con algunos valores cambiados

**Parámetros**: Todos los mismos que el constructor (todos opcionales)

**Lógica**:
```dart
parametroNuevo ?? this.parametroActual
```
- Si se pasa nuevo valor → usa el nuevo
- Si no se pasa (null) → mantiene el actual

**Ejemplo de uso**:
```dart
final newConfig = config.copyWith(
  showChevron: false,
  showNewBadge: true,
);
// Resultado: newConfig tiene todos los valores de config
// excepto showChevron=false y showNewBadge=true
```

## 6. FACTORY CONSTRUCTORS

### EventCardConfig.simple(...) (líneas 98-100)
**Retorna**: Configuración para card simple con chevron

**Parámetros**:
- `onEdit` (Function(Event)?, optional)
- `onDelete` (Function(Event, {bool shouldNavigate})?, optional)

**Configuración**:
```dart
showChevron: true
showActions: true
showInvitationStatus: false
showOwner: true
onEdit: parámetro
onDelete: parámetro
// Resto: defaults
```

**Uso típico**: EventCard básico con navegación y acciones simples

### EventCardConfig.invitation({required String status}) (líneas 102-104)
**Retorna**: Configuración para card de invitación

**Parámetros**:
- `status` (String, required): Estado de la invitación

**Configuración**:
```dart
showChevron: true
showActions: false           // ← No actions (maneja invitación inline)
showInvitationStatus: true   // ← Muestra banner/estado
showOwner: true
invitationStatus: status     // ← El status pasado
// Resto: defaults
```

**Uso típico**: EventCard para eventos con invitación pendiente

### EventCardConfig.readOnly() (líneas 106-108)
**Retorna**: Configuración para card de solo lectura

**Configuración**:
```dart
showChevron: true
showActions: false           // ← No hay acciones
showInvitationStatus: false
showOwner: true
// Resto: defaults
```

**Uso típico**: EventCard en contextos donde no se permite editar/eliminar

### EventCardConfig.withCustomAction({required Widget action}) (líneas 110-112)
**Retorna**: Configuración con acción personalizada

**Parámetros**:
- `action` (Widget, required): Widget de acción personalizado

**Configuración**:
```dart
showChevron: false           // ← No chevron
showActions: false           // ← No acciones default
showInvitationStatus: false
showOwner: true
customAction: action         // ← Acción custom
// Resto: defaults
```

**Uso típico**: EventCard con acción especial (ej: botón custom, checkbox, etc.)

## 7. toString() (líneas 114-117)

**Retorna**: String con representación legible de la config

**Formato**:
```dart
'EventCardConfig(showActions: $showActions, showChevron: $showChevron, showNewBadge: $showNewBadge, customTitle: $customTitle, customStatus: $customStatus)'
```

**Propiedades incluidas**:
- showActions
- showChevron
- showNewBadge
- customTitle
- customStatus

**Nota**: No incluye todas las propiedades (solo las más relevantes para debugging)

## 8. PATRONES DE USO

### Configuración por defecto:
```dart
EventCard(
  event: event,
  onTap: _handleTap,
  // config: EventCardConfig() ← Default implícito
)
```

### Configuración custom inline:
```dart
EventCard(
  event: event,
  onTap: _handleTap,
  config: EventCardConfig(
    showChevron: false,
    showNewBadge: true,
    showDate: true,
    onDelete: _deleteEvent,
  ),
)
```

### Usando factories:
```dart
// Simple
EventCard(
  event: event,
  onTap: _handleTap,
  config: EventCardConfig.simple(
    onEdit: _editEvent,
    onDelete: _deleteEvent,
  ),
)

// Invitation
EventCard(
  event: event,
  onTap: _handleTap,
  config: EventCardConfig.invitation(
    status: 'pending',
  ),
)

// Read-only
EventCard(
  event: event,
  onTap: _handleTap,
  config: EventCardConfig.readOnly(),
)

// Custom action
EventCard(
  event: event,
  onTap: _handleTap,
  config: EventCardConfig.withCustomAction(
    action: Icon(CupertinoIcons.heart),
  ),
)
```

### Modificando config existente:
```dart
final baseConfig = EventCardConfig.simple();
final modifiedConfig = baseConfig.copyWith(
  showNewBadge: true,
  showDate: true,
);
```

## 9. VALORES POR DEFECTO DETALLADOS

### Banderas visuales:
- **showChevron: true** → Por defecto muestra navegación
- **showActions: true** → Por defecto muestra botones de acción
- **showOwner: true** → Por defecto muestra info del owner
- **showDate: false** → Por defecto NO muestra fecha en time container
- **showNewBadge: false** → Por defecto NO muestra badge NEW
- **showInvitationStatus: false** → Por defecto NO muestra estado de invitación

### Banderas de comportamiento:
- **navigateAfterDelete: false** → Por defecto NO navega tras eliminar

### Contenido custom:
- Todos **null por defecto** → Usa contenido del evento

### Callbacks:
- Todos **null por defecto** → Sin acciones asignadas

## 10. COMBINACIONES COMUNES

### EventCard en lista principal:
```dart
EventCardConfig(
  showChevron: true,
  showActions: true,
  showNewBadge: true,
  showDate: true,
  onDelete: _deleteEvent,
)
```

### EventCard en pantalla de detalle:
```dart
EventCardConfig.readOnly()
// O
EventCardConfig(
  showChevron: false,
  showActions: false,
)
```

### EventCard con invitación:
```dart
EventCardConfig.invitation(status: participationStatus)
// Internamente usa:
// - showInvitationStatus: true
// - invitationStatus: status
// - showActions: false
```

### EventCard customizado:
```dart
EventCardConfig(
  customTitle: "Título alternativo",
  customSubtitle: "Descripción alternativa",
  customAvatar: CircleAvatar(...),
  showChevron: false,
)
```

## 11. PROPIEDADES MÁS USADAS

| Propiedad | Frecuencia | Uso típico |
|-----------|------------|------------|
| `showChevron` | Alta | Control de navegación visual |
| `showNewBadge` | Alta | Resaltar eventos nuevos |
| `showDate` | Media | Listas de eventos multi-día |
| `onDelete` | Alta | Gestión de eventos |
| `showInvitationStatus` | Media | Pantallas de invitaciones |
| `customTitle/Subtitle` | Baja | Casos especiales de presentación |

## 12. CALLBACKS Y NAMED PARAMETERS

### onDelete y onDeleteSeries:
```dart
onDelete: (Event event, {bool shouldNavigate = false}) async {
  await deleteEvent(event);
  if (shouldNavigate) Navigator.pop(context);
}
```

**Named parameter**: `shouldNavigate`
- Default: false
- Usado en: EventCard, EventCardActions

### Callbacks simples:
```dart
onEdit: (Event event) {
  Navigator.push(context, ...);
}

onInvite: (Event event) {
  Navigator.push(context, InviteUsersScreen(event: event));
}
```

## 13. INMUTABILIDAD

### Const constructor:
- Permite crear instancias const
- Optimización de memoria
- No se puede modificar después de crear

### CopyWith pattern:
- Única forma de "modificar" una config
- Crea nueva instancia
- Mantiene inmutabilidad

**Ejemplo**:
```dart
const config1 = EventCardConfig(); // const
final config2 = config1.copyWith(showChevron: false); // Nueva instancia
// config1 no cambió, config2 es nueva
```

## 14. DEPENDENCIAS

**Imports**:
- flutter/cupertino.dart (para Widget)
- models/event.dart (para Event en signatures)

**No tiene dependencias** de:
- Providers
- Services
- Styles
- Helpers

**Nota**: Es una clase pura de datos sin lógica de negocio

## 15. NOTAS ADICIONALES

- **Clase pura de datos**: Sin lógica, solo configuración
- **Inmutable**: Const constructor y copyWith pattern
- **Type-safe**: Todos los callbacks tienen signatures explícitas
- **Nullable design**: Permite ausencia de valores (null = usar default del evento)
- **Factory pattern**: Múltiples constructores nombrados para casos comunes
- **toString útil**: Para debugging, incluye propiedades clave
- **No validación**: No valida combinaciones de flags (ej: showActions=true pero onDelete=null)
- **Flexible**: Permite cualquier combinación de propiedades
- **Callback onToggleAcceptance y onRejectInvitation**: Definidos pero **no usados actualmente** en EventCardActions (usa updateParticipationStatus directamente)
- **Custom action poco usado**: customAction permite widgets completamente personalizados pero rara vez se usa
- **CopyWith completo**: Incluye todas las propiedades (algunos configs solo incluyen las mutables)
