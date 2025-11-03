# EventActionSection - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/event_detail/event_action_section.dart`
**Líneas**: 170
**Tipo**: ConsumerStatefulWidget
**Propósito**: Sección completa de acciones en detalle de evento (editar, invitar, cancelar, remover)

## 2. CLASE Y PROPIEDADES

### EventActionSection (líneas 14-23)

**Propiedades**:

| Propiedad | Tipo | Required | Descripción |
|-----------|------|----------|-------------|
| `event` | Event | Sí | El evento |
| `onEventUpdated` | VoidCallback? | No | Callback cuando el evento se actualiza |
| `onEventDeleted` | VoidCallback? | No | Callback cuando el evento se elimina |

### _EventActionSectionState (líneas 25-169)

**State properties**:
- `_sendCancellationNotification` (bool): Si enviar notificación de cancelación
- `_cancellationNotificationController` (TextEditingController): Controlador para mensaje de cancelación

**Computed getters**:
- `isEventOwner` (bool): Usa EventPermissions.isOwner(widget.event)
- `canInviteUsers` (bool): Usa widget.event.canInviteUsers

## 3. CICLO DE VIDA

### dispose() (líneas 34-37)
```dart
@override
void dispose() {
  _cancellationNotificationController.dispose();
  super.dispose();
}
```
- Limpia el TextEditingController
- Previene memory leaks

## 4. MÉTODO BUILD

### build(BuildContext context) (líneas 39-47)

**Estructura**:
```
Column
├── _buildActionButtons()
├── SizedBox(height: 24)
└── [Condicional] if (isEventOwner)
    │   └── _buildCancellationNotificationSection()
    └── else
        └── _buildRemoveFromListButton()
```

**Lógica**:
- Si es owner → muestra sección de cancelación
- Si no es owner → muestra botón "Remover de mi lista"

## 5. MÉTODOS DE CONSTRUCCIÓN DE UI

### _buildActionButtons() (líneas 49-67)

**Retorna**: Container con botones de acción o SizedBox.shrink()

**Validación** (líneas 50-52):
```dart
if (!canInviteUsers && !isEventOwner) {
  return const SizedBox.shrink();
}
```
- Si no puede invitar Y no es owner → no muestra nada

**Estructura** (líneas 54-66):
```
Container
├── margin: EdgeInsets.zero
├── decoration: AppStyles.cardDecoration
├── padding: EdgeInsets.all(16)
└── Column(stretch)
    ├── Text(l10n.eventActions) - style: cardTitle
    ├── SizedBox(height: 16)
    └── EventDetailActions
        - isEventOwner: isEventOwner
        - canInvite: canInviteUsers
        - onInvite: _navigateToInviteScreen
        - onEdit: widget.onEventUpdated
```

### _navigateToInviteScreen() (líneas 69-71)
```dart
void _navigateToInviteScreen() {
  Navigator.of(context).push(
    CupertinoPageRoute(builder: (context) => InviteUsersScreen(event: widget.event))
  );
}
```
- Navega a pantalla de invitación
- Pasa el evento actual

### _buildCancellationNotificationSection() (líneas 73-105)

**Retorna**: Container con sección de cancelación de evento

**Estructura** (líneas 74-104):
```
Container
├── decoration: AppStyles.cardDecoration
├── padding: EdgeInsets.all(16)
└── Column(crossAxisAlignment: start)
    ├── Text(l10n.eventCancellation) - style: cardTitle
    ├── SizedBox(height: 16)
    ├── Row
    │   ├── PlatformSwitch
    │   │   - value: _sendCancellationNotification
    │   │   - onChanged: toggle state
    │   ├── SizedBox(width: 12)
    │   └── Expanded
    │       └── Text(l10n.sendCancellationNotification)
    └── [Condicional] if (_sendCancellationNotification)
        ├── SizedBox(height: 16)
        ├── PlatformTextField
        │   - controller: _cancellationNotificationController
        │   - placeholder: l10n.cancellationMessage
        │   - maxLines: 3
        │   - keyboardType: multiline
        ├── SizedBox(height: 16)
        └── PlatformButton(onPressed: _handleCancelEvent)
            - child: Text(l10n.cancelEventWithNotification)
            - color: AppStyles.errorColor
```

**Switch logic** (líneas 85-90):
```dart
onChanged: (value) {
  setState(() {
    _sendCancellationNotification = value;
  });
}
```
- Toggle para mostrar/ocultar mensaje de cancelación

### _buildRemoveFromListButton() (líneas 107-120)

**Retorna**: Container con botón para remover evento de lista

**Estructura** (líneas 108-119):
```
Container
├── decoration: AppStyles.cardDecoration
├── padding: EdgeInsets.all(16)
└── Column(stretch)
    ├── Text(l10n.eventOptions) - style: cardTitle
    ├── SizedBox(height: 16)
    └── PlatformButton(onPressed: _handleRemoveFromList)
        - child: Text(l10n.removeFromMyList)
        - color: AppStyles.errorColor
        - filled: false (outline button)
```

## 6. MÉTODOS DE ACCIÓN

### _handleCancelEvent() (líneas 122-144)

**Tipo**: `Future<void>`

**Propósito**: Cancela el evento (lo elimina con confirmación)

**Flujo**:

1. **Confirmación** (línea 123):
   ```dart
   final confirmed = await PlatformDialogHelpers.showPlatformConfirmDialog(
     context,
     title: l10n.cancelEvent,
     message: l10n.confirmCancelEvent,
     confirmText: l10n.cancel,
     cancelText: l10n.doNotCancel,
     isDestructive: true
   );
   ```

2. **Validación** (línea 125):
   ```dart
   if (confirmed != true) return;
   ```

3. **Try block** (líneas 127-137):
   - Verifica `mounted`
   - Llama a `eventServiceProvider.deleteEvent(event.id!)`
   - Comentario: "Realtime handles refresh automatically via EventRepository"
   - Si mounted: muestra snackbar de éxito
   - Llama a `widget.onEventDeleted?.call()`

4. **Catch block** (líneas 139-142):
   - Si mounted: muestra snackbar de error

**Nota**: No usa el mensaje de cancelación (línea 127 no lo pasa al backend)

### _handleRemoveFromList() (líneas 146-168)

**Tipo**: `Future<void>`

**Propósito**: Remueve el evento de la lista del usuario (no-owner)

**Flujo**:

1. **Confirmación** (línea 147):
   ```dart
   final confirmed = await PlatformDialogHelpers.showPlatformConfirmDialog(
     context,
     title: l10n.removeFromList,
     message: l10n.confirmRemoveFromList,
     confirmText: l10n.remove,
     cancelText: l10n.cancel,
     isDestructive: true
   );
   ```

2. **Validación** (línea 149):
   ```dart
   if (confirmed != true) return;
   ```

3. **Try block** (líneas 151-161):
   - Verifica `mounted`
   - Llama a `eventServiceProvider.deleteEvent(event.id!)`
   - Comentario: "Realtime handles refresh automatically via EventRepository"
   - Si mounted: muestra snackbar de éxito (diferente mensaje)
   - Llama a `widget.onEventDeleted?.call()`

4. **Catch block** (líneas 163-166):
   - Si mounted: muestra snackbar de error

**Nota**: Usa el mismo método (deleteEvent) que _handleCancelEvent

## 7. PROVIDERS UTILIZADOS

### eventServiceProvider (líneas 130, 154)
**Tipo**: EventService
**Métodos usados**:
- `deleteEvent(int eventId)`

## 8. UTILS UTILIZADOS

### EventPermissions.isOwner(Event) (línea 30)
**Ubicación**: `lib/utils/event_permissions.dart`
**Retorna**: bool
**Propósito**: Verificar si el usuario actual es propietario del evento

## 9. LOCALIZACIÓN

### Strings usados:

**Acciones**:
- `l10n.eventActions`: "Acciones del evento"
- `l10n.eventOptions`: "Opciones"

**Cancelación**:
- `l10n.eventCancellation`: "Cancelación del evento"
- `l10n.sendCancellationNotification`: "Enviar notificación de cancelación"
- `l10n.cancellationMessage`: "Mensaje de cancelación"
- `l10n.cancelEventWithNotification`: "Cancelar evento"
- `l10n.cancelEvent`: "Cancelar evento" (título diálogo)
- `l10n.confirmCancelEvent`: "¿Confirmar cancelación?"
- `l10n.cancel`: "Cancelar"
- `l10n.doNotCancel`: "No cancelar"
- `l10n.eventCancelledSuccessfully`: "Evento cancelado"
- `l10n.failedToCancelEvent`: "Error al cancelar"

**Remover**:
- `l10n.removeFromMyList`: "Remover de mi lista"
- `l10n.removeFromList`: "Remover de lista" (título)
- `l10n.confirmRemoveFromList`: "¿Confirmar remoción?"
- `l10n.remove`: "Remover"
- `l10n.eventRemovedFromList`: "Evento removido"
- `l10n.failedToRemoveFromList`: "Error al remover"

## 10. ESTILOS

### AppStyles usados:
- `cardDecoration`: Decoración de cards
- `cardTitle`: Títulos de secciones
- `errorColor`: Color rojo para acciones destructivas

## 11. DIFERENCIAS ENTRE OWNER Y NO-OWNER

| Aspecto | Owner | No-Owner |
|---------|-------|----------|
| **Sección superior** | Botones editar/invitar | Botones editar/invitar (si puede) |
| **Sección inferior** | Cancelación con notificación | Botón "Remover de mi lista" |
| **Switch** | Sí (enviar notificación) | No |
| **TextField** | Sí (mensaje) | No |
| **Botón principal** | "Cancelar evento" (rojo filled) | "Remover" (rojo outline) |
| **Operación** | deleteEvent() | deleteEvent() |
| **Mensaje éxito** | "Evento cancelado" | "Evento removido" |

## 12. COMPORTAMIENTO ESPECIAL

### Mensaje de cancelación no usado:
```dart
// En _handleCancelEvent(), línea 130
await ref.read(eventServiceProvider).deleteEvent(widget.event.id!);
```
- El campo `_cancellationNotificationController.text` no se usa
- El backend no recibe el mensaje
- **Posible bug o feature no implementada**

### Realtime auto-refresh:
- Ambos métodos confían en que Realtime actualizará la UI
- No refrescan manualmente la lista de eventos
- Callback `onEventDeleted` permite al parent manejar navegación

### Mismo método para ambos:
- `_handleCancelEvent` y `_handleRemoveFromList`
- Ambos llaman a `deleteEvent()`
- Diferencia solo en UI y mensajes

## 13. DEPENDENCIAS

**Imports principales**:
- flutter/cupertino.dart
- flutter_riverpod (ConsumerStatefulWidget, WidgetRef)
- models/event.dart
- core/state/app_state.dart (eventServiceProvider)
- screens/invite_users_screen.dart
- utils/event_permissions.dart (EventPermissions)
- helpers/platform_widgets.dart (PlatformWidgets)
- helpers/dialog_helpers.dart (PlatformDialogHelpers)
- helpers/l10n_helpers.dart
- styles/app_styles.dart
- event_detail_actions.dart (EventDetailActions)

## 14. USO TÍPICO

### En EventDetailScreen:
```dart
EventActionSection(
  event: currentEvent,
  onEventUpdated: () {
    // Refrescar evento
    _refreshEventData();
  },
  onEventDeleted: () {
    // Navegar atrás
    Navigator.pop(context);
  },
)
```

## 15. NOTAS ADICIONALES

- **State management**: Usa setState para switch de notificación
- **Confirmaciones**: Ambas acciones destructivas tienen confirmación
- **Error handling**: Try-catch con snackbars
- **Mounted checks**: Verifica mounted antes de setState/mostrar mensajes
- **TextField disposal**: Correctamente dispuesto en dispose()
- **Platform widgets**: Usa widgets adaptativos (PlatformButton, PlatformSwitch, etc.)
- **Validation**: No valida longitud del mensaje de cancelación
- **Cancellation notification**: Feature implementada en UI pero no conectada al backend
- **Color coding**: Rojo para acciones destructivas
- **Unused feature**: El mensaje de cancelación se puede escribir pero no se envía
