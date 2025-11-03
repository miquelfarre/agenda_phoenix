# EventCardActions - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/event_card/event_card_actions.dart`
**Líneas**: 161
**Tipo**: ConsumerWidget
**Propósito**: Botones de acción en el trailing de EventCard (aceptar/rechazar invitación, eliminar, chevron)

## 2. CLASE Y PROPIEDADES

### EventCardActions (líneas 13-160)

**Propiedades**:
- `event` (Event, required): El evento a mostrar
- `config` (EventCardConfig, required): Configuración de visualización
- `interaction` (EventInteraction?, optional): Interacción del usuario con el evento
- `participationStatus` (String?, optional): Estado actual de participación ('pending', 'accepted', 'rejected')

## 3. MÉTODO BUILD

### build(BuildContext context, WidgetRef ref) (líneas 22-52)

**Retorna**: Widget con acciones según el contexto del usuario

**Lógica de decisión en cascada**:

1. **Línea 23**: Verifica permisos con `EventPermissions.isOwner(event)`

2. **Prioridad 1: Invitación** (líneas 26-28):
   - Si `interaction != null` Y `interaction.inviterId != null`
   - Entonces: retorna `_buildInvitationActions(context, ref)`
   - **Caso**: Usuario recibió invitación de alguien

3. **Prioridad 2: Owner** (líneas 30-33):
   - Si `isOwner == true`
   - Entonces: retorna `_buildOwnerActions(context)`
   - **Caso**: Usuario es propietario del evento

4. **Prioridad 3: Suscripción pública** (líneas 35-44):
   - Obtiene suscripciones del `subscriptionsProvider`
   - Verifica si `event.owner?.isPublic == true`
   - Verifica si usuario está suscrito: `subs.any((s) => s.id == event.ownerId)`
   - Si es público, está suscrito Y `event.id != null`:
     - Retorna `_buildSubscriptionActions(context)`
   - **Caso**: Evento de usuario público al que está suscrito

5. **Default: Chevron o nada** (líneas 46-51):
   - Si `config.showChevron == true`:
     - Retorna chevron derecho (grey 400, size 20)
   - Sino: retorna SizedBox.shrink()

## 4. MÉTODOS PRIVADOS DE CONSTRUCCIÓN

### _buildInvitationActions(BuildContext context, WidgetRef ref) (líneas 54-98)
**Retorna**: Row con botones de aceptar/rechazar

**Lógica de estado** (líneas 55-57):
- `currentStatus = participationStatus ?? 'pending'`
- `isCurrentlyAccepted = currentStatus == 'accepted'`
- `isCurrentlyRejected = currentStatus == 'rejected'`

**Estructura** (líneas 59-97):
```
Row(mainAxisSize: min)
├── _actionCircle (Aceptar/Corazón)
│   - Icono: heart_fill si accepted, heart si no
│   - Color: Green 600
│   - onTap: Toggle entre 'accepted' y 'pending'
├── SizedBox(width: 8)
└── _actionCircle (Rechazar/X)
    - Icono: xmark_circle_fill si rejected, xmark si no
    - Color: Red 600
    - onTap: Toggle entre 'rejected' y 'pending'
```

**Lógica de toggle** (líneas 67-78, 85-94):
```dart
// Botón aceptar
final newStatus = isCurrentlyAccepted ? 'pending' : 'accepted';
await eventInteractionRepositoryProvider.updateParticipationStatus(
  event.id!,
  newStatus,
  isAttending: false
);

// Botón rechazar
final newStatus = isCurrentlyRejected ? 'pending' : 'rejected';
await eventInteractionRepositoryProvider.updateParticipationStatus(
  event.id!,
  newStatus,
  isAttending: false
);
```

**Manejo de errores** (líneas 72-75, 90-93):
- Try-catch alrededor de updateParticipationStatus
- En catch: muestra snackbar con mensaje de error localizado
  - Aceptar: `l10n.errorAcceptingInvitation`
  - Rechazar: `l10n.errorRejectingInvitation`
- Verifica `context.mounted` antes de mostrar snackbar

### _buildOwnerActions(BuildContext context) (líneas 100-119)
**Retorna**: Row con botón de eliminar

**Estructura** (líneas 101-118):
```
Row(mainAxisSize: min)
└── _actionCircle (Eliminar)
    - Icono: CupertinoIcons.delete
    - Color: Red 600
    - tooltip: l10n.delete
    - onTap: Llama a config.onDelete
```

**Lógica del onTap** (líneas 109-115):
- Si `config.onDelete != null`:
  - Try-catch vacío
  - Llama a `config.onDelete!(event, shouldNavigate: config.navigateAfterDelete)`
  - **Nota**: El catch está vacío, los errores se manejan en el callback

### _buildSubscriptionActions(BuildContext context) (líneas 121-140)
**Retorna**: Row con botón de eliminar (para eventos de suscripciones)

**Estructura**: Idéntica a `_buildOwnerActions`
- Mismo botón rojo de delete
- tooltip: `l10n.decline` (en lugar de delete)
- Mismo callback a `config.onDelete`

**Diferencia con _buildOwnerActions**:
- Solo el texto del tooltip es diferente
- Lógica y estructura idénticas
- **Uso**: Para desuscribirse de eventos públicos

### _actionCircle(...) (líneas 142-159)
**Retorna**: GestureDetector con círculo de acción

**Parámetros**:
- `context` (BuildContext, required)
- `icon` (IconData, required): Icono a mostrar
- `color` (Color, required): Color del icono y borde
- `onTap` (VoidCallback, required): Callback al tocar
- `tooltip` (String?, optional): Tooltip de accesibilidad

**Estructura**:
```
GestureDetector(onTap)
└── Semantics(label: tooltip)
    └── Container (32x32, circular)
        - Color de fondo: color con 10% opacidad
        - Borde: color con 25% opacidad, width 1
        - Shape: BoxShape.circle
        └── Center
            └── PlatformIcon(icon, color, size 16)
```

## 5. PROVIDERS UTILIZADOS

### subscriptionsProvider (línea 36)
**Tipo**: AsyncValue<List<User>>
**Propósito**: Obtener la lista de usuarios públicos a los que está suscrito
**Uso**: Determinar si mostrar botón de eliminar para eventos de suscripciones

### eventInteractionRepositoryProvider (líneas 71, 88)
**Tipo**: EventInteractionRepository
**Propósito**: Actualizar el estado de participación en invitaciones
**Métodos usados**:
- `updateParticipationStatus(int eventId, String status, {bool isAttending})`

## 6. UTILS UTILIZADOS

### EventPermissions.isOwner(Event event) (línea 23)
**Retorna**: bool
**Propósito**: Verificar si el usuario actual es propietario del evento
**Ubicación**: `lib/utils/event_permissions.dart`

## 7. CONFIGURACIÓN

### EventCardConfig
**Propiedades usadas**:
- `showChevron` (bool): Si mostrar chevron de navegación
- `onDelete` (Future<void> Function(Event, {bool shouldNavigate})?): Callback al eliminar
- `navigateAfterDelete` (bool): Si navegar después de eliminar

## 8. ESTILOS Y CONSTANTES

### Colores utilizados:
- `AppStyles.green600`: Botón aceptar invitación
- `AppStyles.red600`: Botones rechazar y eliminar
- `AppStyles.grey400`: Chevron de navegación

### Tamaños:
- **Action circle**: 32x32 px
- **Icono**: 16px
- **Spacing entre botones**: 8px

### Opacidades:
- **Fondo del círculo**: 10% (0.1)
- **Borde del círculo**: 25% (0.25)

## 9. LOCALIZACIÓN

Strings localizados usados:
- `l10n.delete`: Tooltip del botón eliminar (owner)
- `l10n.decline`: Tooltip del botón eliminar (suscripción)
- `l10n.accept`: Tooltip del botón aceptar
- `l10n.errorAcceptingInvitation`: Mensaje de error al aceptar
- `l10n.errorRejectingInvitation`: Mensaje de error al rechazar

## 10. ESTADOS Y TRANSICIONES

### Estado de invitación:

**Pending** (inicial):
- Botón aceptar: Icono heart outline
- Botón rechazar: Icono X outline
- Al tocar accept → cambia a 'accepted'
- Al tocar reject → cambia a 'rejected'

**Accepted**:
- Botón aceptar: Icono heart fill (filled)
- Botón rechazar: Icono X outline
- Al tocar accept → cambia a 'pending' (toggle)

**Rejected**:
- Botón aceptar: Icono heart outline
- Botón rechazar: Icono xmark_circle_fill (filled)
- Al tocar reject → cambia a 'pending' (toggle)

### Diagrama de transiciones:
```
      pending
       /  \
      /    \
accepted  rejected
     \     /
      \   /
      pending
```

## 11. COMPORTAMIENTO ESPECIAL

### Prioridad de acciones:
1. **Invitación** (más alta): Si hay interaction con inviterId
2. **Owner**: Si es propietario del evento
3. **Suscripción**: Si es evento de suscripción pública
4. **Chevron**: Default si config lo permite
5. **Nada**: Si no cumple ninguna condición

### Validaciones:
- **event.id != null**: Requerido para actualizar participación y para suscripciones
- **context.mounted**: Verificado antes de mostrar snackbars
- **config.onDelete != null**: Verificado antes de llamar al callback

### Toggle behavior:
- Los botones de invitación actúan como toggles
- Si ya está aceptado y vuelves a tocar aceptar → vuelve a pending
- Si ya está rechazado y vuelves a tocar rechazar → vuelve a pending
- **Nota**: `isAttending: false` se pasa siempre (no se usa attending aquí)

## 12. MANEJO DE ERRORES

### Errores en updateParticipationStatus:
- Capturados con try-catch
- Muestra snackbar con mensaje de error
- **No revierte el estado visual** (el provider lo maneja)

### Errores en onDelete:
- Try-catch vacío en el widget
- **Responsabilidad del callback**: El parent debe manejar errores
- Permite que el callback decida cómo mostrar errores

## 13. DEPENDENCIAS

**Imports principales**:
- flutter/cupertino.dart
- flutter_riverpod (ConsumerWidget, WidgetRef)
- Models: Event, EventInteraction
- Providers: app_state (subscriptionsProvider, eventInteractionRepositoryProvider)
- Utils: event_permissions (EventPermissions.isOwner)
- Helpers: platform_widgets, l10n_helpers
- Styles: app_styles
- event_card_config (EventCardConfig)

## 14. NOTAS ADICIONALES

- **Iconos adaptativos**: Usan filled variants cuando el estado está activo
- **Accesibilidad**: Usa Semantics con label para tooltips
- **Platform widgets**: Usa PlatformWidgets.platformIcon para adaptar a plataforma
- **Gestión de estado via providers**: No mantiene estado local, todo via providers
- **Callbacks async**: updateParticipationStatus y onDelete son async
- **Duplicación _buildOwnerActions vs _buildSubscriptionActions**: Podría refactorizarse
- **isAttending: false hardcoded**: No se diferencia entre attending y participation status aquí
- **Empty catch en onDelete**: Confía en que el callback maneje sus propios errores
- **Realtime updates**: Los cambios de participación se reflejan via eventInteractionsProvider automáticamente
