# EventDetailScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/event_detail_screen.dart`
**Líneas**: 1312
**Tipo**: ConsumerStatefulWidget with WidgetsBindingObserver
**Propósito**: Pantalla de detalle de un evento que muestra toda la información, permite gestionar invitaciones, editar, eliminar, y ver eventos relacionados

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **EventCard** (línea 760)
**Archivo**: `lib/widgets/event_card.dart`
**Documentación**: `lib/widgets_md/event_card.md`

**Uso en EventDetailScreen**:
```dart
EventCard(
  event: futureEvent,
  onTap: () => _navigateToFutureEvent(futureEvent),
  config: EventCardConfig(
    navigateAfterDelete: false,
    onDelete: _deleteEvent,
    onEdit: null,
  ),
)
```
**Ubicación**: Dentro de `_buildFutureEventsSection()`, mapeado para cada evento futuro de la serie
**Propósito**: Mostrar eventos futuros de la serie recurrente

#### **PersonalNoteWidget** (línea 254)
**Archivo**: `lib/widgets/personal_note_widget.dart`
**Documentación**: Pendiente

**Uso**:
```dart
PersonalNoteWidget(
  eventId: event.id!,
  initialNote: personalNote,
)
```
**Ubicación**: Dentro de `_buildContent()` (línea 254)
**Propósito**: Permitir al usuario agregar/editar nota personal del evento

#### **UserAvatar** (líneas 329, 1085)
**Archivo**: `lib/widgets/user_avatar.dart`
**Documentación**: `lib/widgets_md/user_avatar.md`

**Uso 1 - Avatar del organizador** (línea 329):
```dart
UserAvatar(user: owner.toUser(), radius: 28)
```
**Ubicación**: Dentro de `_buildOrganizerSection()`
**Propósito**: Mostrar avatar del organizador del evento

**Uso 2 - Avatar de asistente** (línea 1085):
```dart
UserAvatar(user: user, radius: 20)
```
**Ubicación**: Dentro de `_buildAttendeesSection()`
**Propósito**: Mostrar avatares de los asistentes al evento

#### **EmptyState** (línea 751)
**Archivo**: `lib/widgets/empty_state.dart`
**Documentación**: `lib/widgets_md/empty_state.md`

**Uso**:
```dart
EmptyState(
  message: l10n.noUpcomingEventsScheduled,
  icon: CupertinoIcons.calendar
)
```
**Ubicación**: Dentro de `_buildFutureEventsSection()` cuando no hay eventos futuros
**Condición**: `futureEvents.isEmpty`

#### **AdaptiveButton** (múltiples usos: 271, 845, 857, 977, 982)
**Archivo**: `lib/widgets/adaptive/adaptive_button.dart`
**Documentación**: `lib/widgets_md/adaptive_button.md`

**Uso 1 - Ver eventos del organizador** (línea 271):
```dart
AdaptiveButton(
  config: AdaptiveButtonConfig.secondary(),
  text: context.l10n.viewOrganizerEvents,
  onPressed: () => _viewPublicUserEvents()
)
```

**Uso 2 - Eliminar evento** (línea 845):
```dart
AdaptiveButton(
  config: AdaptiveButtonConfigExtended.destructive(),
  text: l10n.deleteEvent,
  icon: CupertinoIcons.delete,
  onPressed: () => _deleteEvent(_detailedEvent ?? currentEvent, shouldNavigate: true)
)
```

**Uso 3 - Remover de mi lista** (línea 857):
```dart
AdaptiveButton(
  config: AdaptiveButtonConfigExtended.destructive(),
  text: l10n.removeFromMyList,
  icon: CupertinoIcons.minus_circle,
  onPressed: () => _leaveEvent(_detailedEvent ?? currentEvent, shouldNavigate: true)
)
```

**Uso 4 - Ver eventos del calendario** (línea 977):
```dart
AdaptiveButton(
  config: AdaptiveButtonConfig.secondary(),
  text: context.l10n.viewCalendarEvents,
  icon: CupertinoIcons.calendar,
  onPressed: () => _viewCalendarEvents()
)
```

**Uso 5 - Ver serie de eventos** (línea 982):
```dart
AdaptiveButton(
  config: AdaptiveButtonConfig.secondary(),
  text: l10n.viewEventSeries,
  icon: CupertinoIcons.link,
  onPressed: () => _viewParentEventSeries()
)
```

#### **AdaptivePageScaffold** (usado como scaffold principal)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_scaffold.md`
**Propósito**: Scaffold adaptativo con back button

### 2.2. Resumen de Dependencias de Widgets

```
EventDetailScreen
├── AdaptivePageScaffold (scaffold principal)
└── SafeArea
    └── CustomScrollView
        ├── SliverToBoxAdapter (múltiples secciones)
        │   ├── Organizer section
        │   │   └── UserAvatar (organizador)
        │   ├── Personal note section
        │   │   └── PersonalNoteWidget
        │   ├── Actions sections
        │   │   └── AdaptiveButton (múltiples variantes)
        │   ├── Attendees section
        │   │   └── UserAvatar (múltiples asistentes)
        │   └── Future events section
        │       ├── EventCard (eventos futuros)
        │       └── EmptyState (si no hay eventos)
        └── SliverFillRemaining (si hay error)
            └── EmptyState (error state)
```

**Total de widgets propios**: 6 (EventCard, PersonalNoteWidget, UserAvatar, EmptyState, AdaptiveButton, AdaptivePageScaffold)
**Widgets más usados**: AdaptiveButton (5 usos), UserAvatar (2 usos)

---

## 3. CLASE Y PROPIEDADES

### EventDetailScreen (líneas 30-37)
Widget principal que extiende `ConsumerStatefulWidget`

**Propiedades**:
- `event` (Event, required): El evento a mostrar en detalle

### _EventDetailScreenState (líneas 39-1311)
Estado del widget que gestiona la lógica de la pantalla. Implementa `WidgetsBindingObserver` para detectar cambios en el ciclo de vida de la app

**Propiedades de instancia**:
- `currentEvent` (Event, late): Evento actual mostrado (puede cambiar con actualizaciones)
- `_sendCancellationNotification` (bool): Si enviar notificación de cancelación
- `_cancellationNotificationController` (TextEditingController): Controller para mensaje de cancelación
- `_decisionMessageController` (TextEditingController): Controller para mensaje de decisión
- `_ephemeralMessage` (String?): Mensaje temporal a mostrar
- `_ephemeralMessageColor` (Color?): Color del mensaje temporal
- `_ephemeralTimer` (Timer?): Timer para ocultar mensaje temporal
- `_detailedEvent` (Event?): Evento con detalles completos (incluye interacciones, owner info, etc.)
- `_otherInvitations` (List<EventInteraction>?): Lista de otras invitaciones al evento (para mostrar al owner)
- `_isLoadingComposite` (bool): Si está cargando datos detallados
- `_interaction` (EventInteraction?): Interacción del usuario actual con el evento (si existe)
- `_eventRepository` (EventRepository?): Repositorio de eventos para Realtime
- `_eventsSubscription` (StreamSubscription<List<Event>>?): Suscripción a updates de Realtime

**Getters computados**:
- `currentUserId` (int): ID del usuario actual desde ConfigService
- `isEventOwner` (bool): Si el usuario actual es propietario del evento

## 3. CICLO DE VIDA

### initState() (líneas 142-155)
1. Llama a `super.initState()`
2. Registra el observer: `WidgetsBinding.instance.addObserver(this)`
3. Inicializa `currentEvent` con el evento del widget
4. Línea 148: hay un condicional vacío para usuarios públicos
5. Llama a `_initializeRealtimeListener()` para configurar updates en tiempo real
6. Usa `addPostFrameCallback` para llamar a `_loadDetailData()` después del primer frame

### dispose() (líneas 182-189)
1. Remueve el observer: `WidgetsBinding.instance.removeObserver(this)`
2. Limpia `_cancellationNotificationController.dispose()`
3. Limpia `_decisionMessageController.dispose()`
4. Cancela `_ephemeralTimer` si existe
5. Cancela `_eventsSubscription` si existe
6. Llama a `super.dispose()`

### didChangeAppLifecycleState(AppLifecycleState state) (líneas 192-198)
**Propósito**: Callback que se ejecuta cuando cambia el estado del ciclo de vida de la app

**Lógica**:
- Si el estado es `resumed` y el widget está montado: recarga datos con `_loadDetailData()`
- Útil para refrescar datos cuando el usuario vuelve a la app

## 4. MÉTODOS DE CARGA DE DATOS

### _loadDetailData() (líneas 64-127)
**Tipo de retorno**: `Future<void>`

**Propósito**: Carga los detalles completos del evento desde la API

**Lógica**:
1. Verifica que esté montado y no esté ya cargando
2. Obtiene el `eventId`, si es null retorna
3. Activa `_isLoadingComposite = true`
4. En bloque try-catch:
   - Llama a `apiClientProvider.fetchEvent(eventId)` para obtener datos completos
   - Parsea el evento detallado: `Event.fromJson(data)`
   - **Si NO es owner**:
     - Busca interacciones del usuario actual en `data['interactions']`
     - Filtra por `userId == currentUserId`
     - Guarda la primera interacción encontrada
     - Imprime logs de debug extensos
   - **Obtiene otras invitaciones** (para owner/admin/participante aceptado):
     - Filtra interacciones donde `userId != currentUserId`
   - Si está montado, actualiza estado:
     - `_detailedEvent`, `_otherInvitations`, `_interaction`, `currentEvent`
     - `_isLoadingComposite = false`
   - Si la interacción existe y no ha sido vista (`!interaction.viewed`):
     - Llama a `_markInteractionAsRead()`
5. En catch: desactiva loading si está montado

### _markInteractionAsRead() (líneas 129-139)
**Tipo de retorno**: `Future<void>`

**Propósito**: Marca la interacción como vista/leída

**Lógica**:
1. Verifica que `event.id` e `_interaction` no sean null
2. En try-catch:
   - Llama a `eventRepositoryProvider.markAsViewed(eventId)`
   - Imprime log de éxito
3. En catch:
   - Imprime log de error
   - NO muestra error al usuario (operación en background)

### _initializeRealtimeListener() (líneas 157-179)
**Tipo de retorno**: `Future<void>`

**Propósito**: Configura listener para actualizaciones en tiempo real del evento

**Lógica**:
1. En try-catch:
   - Obtiene el `eventRepositoryProvider`
   - Se suscribe a `eventsStream`
   - Para cada actualización de eventos:
     - Si `currentEvent.id` es null, ignora
     - Busca el evento actualizado por ID con `firstOrNull`
     - Si se encontró y el widget está montado:
       - Actualiza `currentEvent` con el evento actualizado
       - NO reemplaza `_detailedEvent` directamente
       - Recarga datos completos con `_loadDetailData()` para preservar detalles
2. En catch: imprime log de error

## 5. MÉTODO BUILD

### build(BuildContext context, WidgetRef ref) (líneas 201-205)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la UI principal de la pantalla

**Lógica**:
1. Usa `_detailedEvent` si existe, sino usa `currentEvent`
2. Retorna `AdaptivePageScaffold` con:
   - `title`: título del evento
   - `body`: llama a `_buildContent()`

### _buildContent() (líneas 207-289)
**Tipo de retorno**: `Widget`

**Propósito**: Construye el contenido scrollable de la pantalla

**Estructura**:
Retorna `SafeArea` con `SingleChildScrollView` (padding 16px) que contiene una Column con:

1. **Mensaje efímero** (líneas 214-225): Si existe `_ephemeralMessage`
   - Container con fondo de color personalizado
   - Text con el mensaje

2. **Sección de información** (línea 226): `_buildInfoSection()`

3. **Espaciador** (línea 227): 16px

4. **Sección de asistentes** (línea 229): `_buildAttendeesSection()`

5. **Espaciador** (línea 231): 24px

6. **Botones de participación** (líneas 233-250): Condicional con Builder
   - Si NO es owner Y hay interacción Y fue invitado (`wasInvited`):
     - Muestra `_buildParticipationStatusButtons()`
   - Sino: `SizedBox.shrink()`
   - Incluye logs de debug extensos

7. **Acciones adicionales** (línea 252): `_buildAdditionalActions()`

8. **Nota personal** (líneas 254-262): `PersonalNoteWidget`
   - Callback `onEventUpdated` que actualiza `currentEvent`

9. **Espaciador** (línea 262): 24px

10. **Lista de invitados** (línea 264): Si es owner, muestra `_buildInvitedUsersList()`

11. **Botones de acción** (línea 266): `_buildActionButtons()`

12. **Ver eventos del organizador** (líneas 267-273): Si es evento público y NO es owner
    - Botón secundario para ver eventos del organizador
    - Llama a `_viewPublicUserEvents()`

13. **Sección condicional** (línea 275):
    - Si es owner: muestra `_buildCancellationNotificationSection()`
    - Si NO es owner: muestra `_buildRemoveFromListButton()`

14. **Eventos futuros del organizador** (líneas 277-284): Si es evento público y tiene nombre de owner
    - Usa Consumer para construir `_buildPublicUserFutureEvents()`

## 6. SECCIONES DE INFORMACIÓN

### _buildInfoSection() (líneas 291-318)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la tarjeta con información principal del evento

**Estructura**:
Container con decoración de card, padding 16px, contiene Column con:
1. Si es evento público con nombre de owner: `_buildOrganizerRow()` + espaciador
2. Fila de descripción: llama a `_buildInfoRow()` con descripción o "Sin descripción"
3. Badges del evento: `_buildEventBadges()`
4. Espaciador de 8px
5. Fila de fecha: llama a `_buildInfoRow()` con fecha formateada (`_formatDateTime`)
6. Si NO es owner Y hay interacción Y fue invitado Y hay invitador:
   - Muestra fila "Invited by" con nombre del invitador
7. Si NO es owner Y hay interacción Y fue invitado Y el estado NO es 'pending':
   - Muestra `_buildParticipationStatusRow()`
8. Si es evento recurrente: muestra `_buildRecurrenceInfo()`

### _buildOrganizerRow() (líneas 320-350)
**Tipo de retorno**: `Widget`

**Propósito**: Construye fila con información del organizador

**Estructura**:
Row con:
- `UserAvatar` del owner (radio 28)
- Espaciador de 12px
- Column expandida con:
  - Label "Organizador" (tamaño 14, peso 600, gris)
  - Espaciador de 4px
  - Nombre completo del owner (tamaño 16, ellipsis)

### _buildInfoRow(String label, String value) (líneas 352-367)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `label`: Etiqueta del campo
- `value`: Valor a mostrar

**Estructura**:
Padding vertical de 8px con Column:
- Text con label (tamaño 14, peso 600, gris)
- Espaciador de 4px
- Text con value (tamaño 16, negro87)

### _buildEventBadges() (líneas 369-459)
**Tipo de retorno**: `Widget`

**Propósito**: Construye badges informativos del evento (calendario, cumpleaños, recurrente)

**Lógica**:
1. Crea lista vacía de badges
2. Si tiene calendario (`calendarId` y `calendarName`):
   - Añade badge con círculo de color del calendario + nombre
   - Fondo azul claro, borde azul
3. Si es cumpleaños (`isBirthday`):
   - Añade badge con icono de regalo + texto "Cumpleaños"
   - Fondo naranja claro, borde naranja
4. Si es recurrente (`isRecurring`):
   - Añade badge con icono de repeat + texto "Recurrente"
   - Fondo verde claro, borde verde
5. Si no hay badges: retorna `SizedBox.shrink()`
6. Si hay badges: retorna Wrap con spacing 6px

## 7. MÉTODOS AUXILIARES DE FORMATO

### _parseColor(String colorString) (líneas 461-471)
**Tipo de retorno**: `Color`

**Propósito**: Convierte string hex a Color de Flutter

**Lógica**:
- En try-catch:
  - Elimina '#' del string
  - Si tiene 6 caracteres: añade 'FF' al inicio (alpha)
  - Parsea a int con radix 16
  - Retorna Color
- En catch: retorna azul por defecto

### _formatDateTime(DateTime dateTime) (líneas 473-508)
**Tipo de retorno**: `String`

**Propósito**: Formatea fecha y hora según el locale

**Lógica**:
1. Obtiene arrays de nombres de días y meses traducidos
2. Extrae weekday, month, minute del dateTime
3. **Si locale es inglés**:
   - Define función interna `ordinal(d)` para sufijos (st, nd, rd, th)
   - Convierte hora de 24h a 12h con AM/PM
   - Formato: "Monday, 1st of January 2025 at 3:30 PM"
4. **Si locale NO es inglés**:
   - Formato 24h con padding
   - Formato: "lunes, 1 de enero de 2025 a las 15:30"

## 8. SECCIÓN DE ASISTENTES

### _buildAttendeesSection() (líneas 510-610)
**Tipo de retorno**: `Widget`

**Propósito**: Muestra lista de otros asistentes al evento

**Lógica**:
1. Obtiene `event.attendees`
2. Itera sobre attendees y parsea a `User`:
   - Si es instancia de User: lo añade directo
   - Si es Map: parsea con `User.fromJson()`
   - Incluye logs de debug extensos
3. Filtra para excluir al usuario actual: `where((u) => u.id != currentUserId)`
4. Si no hay otros asistentes: retorna `SizedBox.shrink()`
5. Si hay asistentes: retorna Container con decoración de card que contiene:
   - **Header**: Icono de personas + "Asistentes" + badge con cantidad
   - **Wrap**: Para cada asistente:
     - Círculo azul con inicial del nombre (40x40)
     - Espaciador de 4px
     - Primer nombre (tamaño 11, 1 línea max, ellipsis)

## 9. BOTONES DE ACCIÓN

### _buildActionButtons() (líneas 612-616)
**Tipo de retorno**: `Widget`

**Propósito**: Construye botones principales de edición e invitación

**Lógica**:
Retorna `EventDetailActions` con:
- `isEventOwner`: si es propietario
- `canInvite`: si puede invitar usuarios
- `onEdit`: callback que llama a `_editEvent()`
- `onInvite`: callback que llama a `_navigateToInviteScreen()`

### _navigateToInviteScreen() (líneas 618-636)
**Tipo de retorno**: `void`

**Propósito**: Navega a la pantalla de invitar usuarios

**Lógica**:
1. Obtiene el evento actual
2. Imprime logs de debug
3. Navega con `CupertinoPageRoute` a `InviteUsersScreen(event: event)`
4. Imprime log de confirmación

### _editEvent(BuildContext context) (líneas 638-647)
**Tipo de retorno**: `Future<void>`

**Propósito**: Navega a la pantalla de edición y maneja el resultado

**Lógica**:
1. Navega con `pushScreen` a `CreateEditEventScreen(eventToEdit: currentEvent)`
2. Espera el resultado (`updatedEvent`)
3. Si hay resultado:
   - Incluye comentario: Realtime maneja el refresh automáticamente
   - Si está montado: llama a `setState(() {})` para rebuild

### _deleteEvent(Event event, {bool shouldNavigate = false}) (líneas 649-686)
**Tipo de retorno**: `Future<void>`

**Parámetros**:
- `event`: Evento a eliminar
- `shouldNavigate`: Si debe navegar después (default: false)

**Propósito**: Elimina o abandona el evento según permisos

**Lógica**:
1. Imprime logs de debug extensos
2. Si `event.id` es null: lanza excepción
3. En try-catch:
   - Verifica permisos con `EventPermissions.canEdit(event)`
   - **Si puede editar**: elimina con `eventServiceProvider.deleteEvent()`
   - **Si NO puede editar**: abandona con `eventRepositoryProvider.leaveEvent()`
4. Si hay error: relaniza la excepción
5. Si `shouldNavigate` y está montado: navega atrás con `Navigator.pop()`

### _leaveEvent(Event event, {bool shouldNavigate = false}) (líneas 688-719)
**Tipo de retorno**: `Future<void>`

**Parámetros**:
- `event`: Evento a abandonar
- `shouldNavigate`: Si debe navegar después (default: false)

**Propósito**: Abandona el evento (para participantes no-owner)

**Lógica**:
1. Imprime logs de debug extensos
2. Si `event.id` es null: retorna
3. En try-catch:
   - Llama a `eventRepositoryProvider.leaveEvent(eventId)`
   - Si `shouldNavigate` y está montado: navega atrás
4. En catch:
   - Imprime error
   - Si está montado: muestra mensaje efímero de error
   - Relaniza excepción

## 10. EVENTOS FUTUROS DEL ORGANIZADOR

### _buildPublicUserFutureEvents() (líneas 721-774)
**Tipo de retorno**: `Widget`

**Propósito**: Muestra lista de próximos eventos del organizador público

**Lógica**:
1. Obtiene `publicUserId` del owner del evento
2. Si es null: retorna `SizedBox.shrink()`
3. Retorna Consumer que:
   - Observa `eventsStreamProvider`
   - Filtra eventos futuros (`date.isAfter(now)`) del mismo organizador, excluyendo evento actual
   - Ordena por fecha
   - Limita a 5 eventos máximo
4. Construye Column con:
   - Título: "Próximos eventos de {nombre}"
   - Si no hay eventos: `EmptyState`
   - Si hay eventos: `ListView.separated` con `EventCard` para cada evento
     - onTap: navega a `EventDetailScreen` del evento
     - Config: `navigateAfterDelete: false`, callbacks de delete y edit

## 11. SECCIÓN DE CANCELACIÓN (OWNER)

### _buildCancellationNotificationSection() (líneas 776-850)
**Tipo de retorno**: `Widget`

**Propósito**: Construye sección para eliminar evento con opción de notificar

**Estructura**:
Container con padding 16px, decoración con borde, contiene Column con:
1. **Header**: Icono de campana + "Notificar cancelación"
2. **Descripción**: Texto explicativo
3. **Switch**: Toggle para activar/desactivar notificación
   - onChanged: actualiza `_sendCancellationNotification`
   - Si se desactiva: limpia el controller
4. **Campo de texto condicional**: Si está activada la notificación
   - TextField multilínea (3 líneas) para mensaje personalizado
   - Placeholder: "Mensaje personalizado (opcional)"
5. **Botón destructivo**: "Eliminar evento"
   - onPressed: llama a `_deleteEvent()` con `shouldNavigate: true`

### _buildRemoveFromListButton() (líneas 852-859)
**Tipo de retorno**: `Widget`

**Propósito**: Construye botón para abandonar evento (NO owner)

**Estructura**:
- `AdaptiveButton` destructivo con ancho completo
- Texto: "Eliminar de mi lista"
- Icono: minus_circle
- onPressed: llama a `_leaveEvent()` con `shouldNavigate: true`

### _showEphemeralMessage(String message, {Color? color, Duration duration = const Duration(seconds: 3)}) (líneas 861-874)
**Tipo de retorno**: `void`

**Parámetros**:
- `message`: Mensaje a mostrar
- `color`: Color del mensaje (opcional)
- `duration`: Duración del mensaje (default: 3 segundos)

**Propósito**: Muestra mensaje temporal que desaparece automáticamente

**Lógica**:
1. Cancela timer anterior si existe
2. Actualiza estado con el mensaje y color
3. Crea nuevo timer que:
   - Verifica que esté montado
   - Limpia el mensaje y color después de la duración

## 12. INFORMACIÓN DE RECURRENCIA

### _buildRecurrenceInfo() (líneas 876-887)
**Tipo de retorno**: `Widget`

**Propósito**: Muestra información de patrones de recurrencia

**Lógica**:
1. Si no hay patrones de recurrencia: retorna `SizedBox.shrink()`
2. Retorna Column con:
   - Fila "Evento" → "Evento recurrente"
   - Espaciador
   - Fila "Patrones de recurrencia" → patrones formateados

### _formatRecurrencePatterns(List<RecurrencePattern> patterns, String locale) (líneas 889-926)
**Tipo de retorno**: `String`

**Propósito**: Formatea patrones de recurrencia en texto legible

**Lógica**:
1. Si no hay patrones: retorna string vacío
2. Para cada patrón:
   - Extrae índice de día (0-6)
   - Extrae hora
   - Añade nombre del día (lowercase en español)
   - Guarda la hora común
3. Define función interna `joinWithAnd()` que une elementos con comas y "y"
4. Construye string: "Cada {días} a las {hora}"
   - Ejemplo: "Cada lunes, miércoles y viernes a las 18:00"

### _formatTime24To12(String time24) (líneas 928-943)
**Tipo de retorno**: `String`

**Propósito**: Convierte hora 24h a 12h con AM/PM

**Lógica**:
- En try-catch:
  - Split por ':'
  - Parsea hora y minuto
  - Convierte a formato 12h: 0→12, >12→resta 12
  - Determina AM/PM según si hora < 12
  - Retorna: "3:30 PM"
- En catch: retorna el string original

### _formatPatternTime(String time24, String locale) (líneas 945-957)
**Tipo de retorno**: `String`

**Propósito**: Formatea hora según locale

**Lógica**:
- Si locale es inglés: llama a `_formatTime24To12()`
- Si NO es inglés:
  - En try-catch: formatea con padding "HH:MM"
  - En catch: retorna string original

## 13. ACCIONES ADICIONALES

### _buildAdditionalActions() (líneas 959-974)
**Tipo de retorno**: `Widget`

**Propósito**: Construye botones de acciones adicionales (ver calendario, ver serie)

**Lógica**:
1. Crea lista vacía de actions
2. Si tiene `calendarId` y `calendarName`: añade `_buildCalendarEventActions()`
3. Si tiene `parentRecurringEventId`: añade `_buildParentEventActions()`
4. Si no hay actions: retorna `SizedBox.shrink()`
5. Si hay actions: retorna Column con todas las actions + espaciador

### _buildCalendarEventActions() (líneas 976-978)
**Tipo de retorno**: `List<Widget>`

**Propósito**: Construye botón para ver eventos del calendario

**Retorna**:
- Lista con `AdaptiveButton` secundario:
  - Texto: "Ver eventos del calendario"
  - Icono: calendar
  - onPressed: `_viewCalendarEvents()`
- Espaciador de 8px

### _buildParentEventActions() (líneas 980-983)
**Tipo de retorno**: `List<Widget>`

**Propósito**: Construye botón para ver serie de eventos

**Retorna**:
- Lista con `AdaptiveButton` secundario:
  - Texto: "Ver serie de eventos"
  - Icono: link
  - onPressed: `_viewParentEventSeries()`
- Espaciador de 8px

### _viewCalendarEvents() (líneas 985-995)
**Tipo de retorno**: `void`

**Propósito**: Navega a la pantalla de eventos del calendario

**Lógica**:
1. Obtiene evento actual
2. Si tiene `calendarId` y `calendarName`:
   - Navega con `CupertinoPageRoute` a `CalendarEventsScreen` con:
     - calendarId
     - calendarName
     - calendarColor

### _viewPublicUserEvents() (líneas 997-1003)
**Tipo de retorno**: `void`

**Propósito**: Navega a la pantalla de eventos públicos del organizador

**Lógica**:
1. Si el evento tiene owner:
   - Navega con `CupertinoPageRoute` a `PublicUserEventsScreen` con el owner

### _viewParentEventSeries() (líneas 1005-1047)
**Tipo de retorno**: `Future<void>`

**Propósito**: Carga y muestra la serie completa de eventos recurrentes

**Lógica**:
1. Verifica que tenga `parentRecurringEventId`, sino retorna
2. En try-catch:
   - Muestra mensaje efímero "Cargando serie"
   - Obtiene userId del ConfigService
   - Llama a API: `GET /users/{userId}/events`
   - Parsea todos los eventos
   - Filtra eventos de la misma serie (mismo `parentRecurringEventId` o ID igual al parent)
   - Si no hay eventos: muestra mensaje "Sin eventos en la serie"
   - Si hay eventos: navega a `EventSeriesScreen` con los eventos y nombre de serie
3. En catch:
   - Imprime error
   - Muestra mensaje efímero de error

## 14. LISTA DE INVITADOS (OWNER)

### _buildInvitedUsersList() (líneas 1049-1121)
**Tipo de retorno**: `Widget`

**Propósito**: Muestra lista de usuarios invitados con su estado (solo para owner)

**Lógica**:
1. Si `_otherInvitations` es null o vacío: retorna `SizedBox.shrink()`
2. Retorna Column con:
   - Container con decoración de card que contiene:
     - **Header**: Icono de personas + "Usuarios invitados"
     - **Lista de invitaciones**: Para cada invitation donde user no es null:
       - Obtiene user, status, statusColor, statusText
       - Construye Row con:
         - `UserAvatar` (radio 20)
         - Espaciador
         - Column expandida con:
           - Nombre del usuario (peso 500)
           - Subtitle si existe (tamaño 13, gris)
         - Badge de estado con:
           - Fondo de color según estado (10% opacity)
           - Borde de color según estado (30% opacity)
           - Texto del estado (peso 600)
   - Espaciador de 24px

### _getStatusColor(String status) (líneas 1123-1135)
**Tipo de retorno**: `Color`

**Propósito**: Obtiene color según el estado de participación

**Lógica**:
Switch sobre status:
- 'accepted' → verde
- 'rejected' → rojo
- 'postponed' → naranja
- 'pending' / default → gris

### _getStatusText(String status) (líneas 1137-1150)
**Tipo de retorno**: `String`

**Propósito**: Obtiene texto traducido según el estado

**Lógica**:
Switch sobre status:
- 'accepted' → "Aceptado"
- 'rejected' → "Rechazado"
- 'postponed' → "Pospuesto"
- 'pending' / default → "Pendiente"

## 15. GESTIÓN DE INVITACIONES (INVITADO)

### _buildParticipationStatusRow() (líneas 1152-1195)
**Tipo de retorno**: `Widget`

**Propósito**: Muestra el estado actual de la invitación como badge

**Lógica**:
1. Si `_interaction` es null: retorna `SizedBox.shrink()`
2. Obtiene status de la interacción
3. Detecta caso especial: rechazado pero asistiendo
   - statusText: "Acepto evento pero rechazo invitación"
   - statusColor: azul
4. Si no es caso especial: usa `_getStatusText()` y `_getStatusColor()`
5. Retorna Padding con Column:
   - Label "Estado de invitación"
   - Badge con fondo y borde de color del estado

### _buildParticipationStatusButtons() (líneas 1197-1250)
**Tipo de retorno**: `Widget`

**Propósito**: Construye botones para cambiar estado de invitación

**Lógica**:
1. Si `_interaction` es null: retorna `SizedBox.shrink()`
2. Obtiene status actual e identifica estados:
   - `isAccepted`: status == 'accepted'
   - `isDeclined`: status == 'rejected'
   - `isDeclinedNotAttending`: rechazado y no asistiendo
   - `isDeclinedButAttending`: rechazado pero asistiendo
3. Retorna Column con Container decorado que contiene:
   - Título: "Cambiar estado de invitación"
   - Row con botones:
     - **Aceptar**: Icono corazón (filled si activo), verde
       - onTap: `_updateParticipationStatus('accepted', isAttending: false)`
     - **Rechazar**: Icono X (filled si activo), rojo
       - onTap: `_updateParticipationStatus('rejected', isAttending: false)`
     - **Asistir independientemente** (solo eventos públicos): Icono personas (filled si activo), azul
       - onTap: `_updateParticipationStatus('rejected', isAttending: true)`

### _buildStatusButton({...}) (líneas 1252-1276)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `icon`: Icono a mostrar
- `label`: Texto del botón
- `color`: Color del botón
- `isActive`: Si el botón está activo
- `onTap`: Callback al presionar

**Propósito**: Construye un botón de estado personalizado

**Estructura**:
- GestureDetector con Container:
  - Padding vertical 12px
  - Fondo: 15% opacity si activo, 5% si no
  - Borde: 2px si activo, 1px si no
  - Column con:
    - Icono (tamaño 28)
    - Espaciador
    - Texto centrado (peso 700 si activo, 500 si no)

### _updateParticipationStatus(String status, {required bool isAttending}) (líneas 1278-1310)
**Tipo de retorno**: `Future<void>`

**Parámetros**:
- `status`: Nuevo estado ('accepted', 'rejected', etc.)
- `isAttending`: Si asistirá al evento

**Propósito**: Actualiza el estado de participación del usuario

**Lógica**:
1. Si `currentEvent.id` es null: retorna
2. En try-catch:
   - Llama a `eventInteractionRepositoryProvider.updateParticipationStatus()` con status e isAttending
   - Recarga datos detallados con `_loadDetailData()` para actualizar UI inmediatamente
   - Si está montado:
     - Determina mensaje según el status:
       - 'accepted' → "Invitación aceptada" (verde)
       - 'rejected' + isAttending → "Acepto evento pero rechazo invitación" (azul)
       - Otro → "Invitation rejected" (rojo)
     - Muestra mensaje efímero con `_showEphemeralMessage()`
3. En catch:
   - Si está montado: muestra mensaje de error efímero

## 16. DEPENDENCIAS

### Providers utilizados:
- `apiClientProvider`: Cliente API para llamadas HTTP (read)
- `eventRepositoryProvider`: Repositorio de eventos con Realtime (read, watch stream)
- `eventServiceProvider`: Servicio de eventos (read)
- `eventInteractionRepositoryProvider`: Repositorio de interacciones (read)
- `eventsStreamProvider`: Stream de eventos (watch)
- `calendarRepositoryProvider`: (implícito en otros componentes)

### Utilities:
- `EventPermissions.canEdit()`: Verifica permisos de edición
- `ConfigService.instance`: Acceso a configuración global (currentUserId)

### Widgets externos:
- `CupertinoPageRoute`: Transiciones de iOS
- `SingleChildScrollView`: Scroll simple
- `Timer`: Para mensajes efímeros

### Widgets internos:
- `AdaptivePageScaffold`: Scaffold adaptativo
- `EventCard`: Tarjeta de evento
- `EventCardConfig`: Configuración de EventCard
- `EmptyState`: Estado vacío
- `EventDetailActions`: Botones de acciones principales
- `PersonalNoteWidget`: Widget de notas personales
- `UserAvatar`: Avatar de usuario
- `AdaptiveButton`: Botón adaptativo
- `CreateEditEventScreen`: Pantalla de creación/edición
- `InviteUsersScreen`: Pantalla de invitación
- `CalendarEventsScreen`: Pantalla de eventos de calendario
- `PublicUserEventsScreen`: Pantalla de eventos públicos de usuario
- `EventSeriesScreen`: Pantalla de serie de eventos

### Navegación:
- `Navigator.of(context).push()`: Para transiciones
- `Navigator.of(context).pop()`: Para volver atrás
- `pushScreen()`: Extension method para navegación

### Helpers:
- `PlatformWidgets`: Widgets adaptativos (icon, switch, textField)
- `context.l10n`: Acceso a localizaciones

### Models:
- `Event`: Modelo de evento
- `EventInteraction`: Modelo de interacción
- `RecurrencePattern`: Modelo de patrón de recurrencia
- `User`: Modelo de usuario

## 17. FLUJO DE DATOS

### Al abrir la pantalla:
1. `initState()` se ejecuta
2. Se inicializa Realtime listener
3. `addPostFrameCallback` llama a `_loadDetailData()`
4. Se cargan detalles completos desde API
5. Se parsean interacciones, invitaciones
6. Se marca como leída si es necesario
7. Se renderiza la UI con los datos

### Actualizaciones en tiempo real:
1. Supabase Realtime emite cambio
2. `eventsStream` recibe evento actualizado
3. Listener detecta cambio en evento actual
4. Actualiza `currentEvent`
5. Recarga datos completos con `_loadDetailData()`
6. UI se actualiza automáticamente

### Al cambiar estado de invitación:
1. Usuario presiona botón (Aceptar/Rechazar/Asistir)
2. `_updateParticipationStatus()` actualiza en API
3. `_loadDetailData()` recarga datos inmediatamente
4. Muestra mensaje efímero de confirmación
5. Realtime mantiene sincronización con otros cambios

### Al volver a la app:
1. `didChangeAppLifecycleState()` detecta `resumed`
2. Llama a `_loadDetailData()` para refrescar
3. UI se actualiza con datos más recientes

## 18. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Visualización completa**: Muestra todos los detalles del evento
2. **Gestión de invitaciones**: Aceptar/rechazar/asistir independientemente
3. **Ver asistentes**: Lista de otros participantes
4. **Edición**: Permite editar evento (si tiene permisos)
5. **Eliminación**: Permite eliminar (owner) o abandonar (participante)
6. **Invitaciones**: Permite invitar usuarios (si tiene permisos)
7. **Nota personal**: Permite añadir notas privadas al evento
8. **Eventos relacionados**:
   - Ver otros eventos del calendario
   - Ver serie de eventos recurrentes
   - Ver eventos futuros del organizador público
9. **Información de recurrencia**: Muestra patrones de repetición
10. **Lista de invitados** (owner): Ve estado de todos los invitados
11. **Notificación de cancelación** (owner): Puede notificar al eliminar
12. **Actualización en tiempo real**: Se sincroniza automáticamente

### Estados manejados:
- Loading de datos detallados
- Datos cargados (evento, interacciones, invitaciones)
- Mensajes efímeros (éxito, error, información)
- Estados de invitación (pending, accepted, rejected, postponed)
- Caso especial: rechazar invitación pero asistir al evento
- Interacción leída/no leída
- Evento actualizado vía Realtime

### Permisos considerados:
- **Owner**: Puede editar, eliminar, ver invitados, enviar notificaciones
- **Admin** (implícito): Puede editar según `EventPermissions.canEdit()`
- **Invitado**: Puede aceptar/rechazar, añadir nota personal, abandonar
- **Participante aceptado**: Puede ver invitados (backend filtra)
- **Suscriptor de evento público**: Puede asistir sin invitación

## 19. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 1312
**Métodos públicos**: 2 (build, didChangeAppLifecycleState)
**Métodos privados**: 32
**Getters**: 2
**Callbacks**: Múltiples (onTap, onEdit, onDelete, onUpdate, etc.)

**Distribución aproximada**:
- Declaración de clase y propiedades: ~60 líneas (4.6%)
- Ciclo de vida: ~25 líneas (1.9%)
- Carga de datos: ~116 líneas (8.8%)
- Método build y content: ~83 líneas (6.3%)
- Sección de información: ~147 líneas (11.2%)
- Formato de fecha/hora: ~85 líneas (6.5%)
- Sección de asistentes: ~101 líneas (7.7%)
- Botones de acción: ~68 líneas (5.2%)
- Eventos futuros organizador: ~54 líneas (4.1%)
- Sección de cancelación: ~99 líneas (7.5%)
- Recurrencia: ~82 líneas (6.3%)
- Acciones adicionales: ~90 líneas (6.9%)
- Lista de invitados: ~101 líneas (7.7%)
- Gestión de invitaciones: ~159 líneas (12.1%)
- Imports y otros: ~42 líneas (3.2%)

## 20. CARACTERÍSTICAS TÉCNICAS

### Observador de ciclo de vida:
- Implementa `WidgetsBindingObserver`
- Detecta cuando la app vuelve a primer plano
- Recarga datos automáticamente al resumir

### Manejo de Realtime:
- Mantiene suscripción a stream de eventos
- Detecta cambios en el evento actual
- Recarga datos completos al recibir update
- Cancela suscripción en dispose

### Mensajes efímeros:
- Sistema de notificaciones temporales
- Timer automático para ocultarlos
- Colores personalizables según tipo de mensaje

### Carga progresiva:
- Primera carga con datos básicos del widget
- Carga completa desde API después del primer frame
- Recarga selectiva según eventos

### Parsing robusto:
- Maneja attendees como User o Map
- Maneja interacciones con logs extensos
- Try-catch en parsing de colores y fechas

### Estado dual:
- `currentEvent`: Dato básico, actualizado por Realtime
- `_detailedEvent`: Dato completo con interacciones y owner info
- UI prioriza `_detailedEvent` si existe

### Debug extensivo:
- Logs en consola para debugging
- Prints en operaciones críticas (delete, leave, interactions)
- Útil para troubleshooting de permisos e invitaciones
