# ContactDetailScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/contact_detail_screen.dart`
**Líneas**: 293
**Tipo**: ConsumerStatefulWidget with WidgetsBindingObserver
**Propósito**: Pantalla que muestra el detalle de un contacto, incluye su información personal, eventos en los que participa y permite bloquear al usuario

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **AdaptivePageScaffold** (línea 172)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_page_scaffold.md`

**Uso en ContactDetailScreen**:
```dart
AdaptivePageScaffold(
  title: widget.contact.displayName,
  body: SafeArea(child: _buildBody(isIOS, l10n)),
)
```

**Ubicación**: Widget raíz retornado por `build()`
**Propósito**: Proporciona scaffold adaptativo para la pantalla
**Configuración específica**:
- `title`: Nombre para mostrar del contacto
- `body`: Envuelve `_buildBody()` en SafeArea

#### **UserAvatar** (línea 188)
**Archivo**: `lib/widgets/user_avatar.dart`
**Documentación**: `lib/widgets_md/user_avatar.md`

**Uso en ContactDetailScreen**:
```dart
UserAvatar(
  user: widget.contact,
  radius: 30,
  showOnlineIndicator: false
)
```

**Ubicación**: Dentro del header card, lado izquierdo antes del nombre
**Propósito**: Mostrar avatar del contacto
**Configuración específica**:
- `user`: Objeto User del contacto
- `radius`: 30 (tamaño del avatar)
- `showOnlineIndicator`: false (no muestra estado online)

#### **EmptyState** (línea 252)
**Archivo**: `lib/widgets/empty_state.dart`
**Documentación**: `lib/widgets_md/empty_state.md`

**Uso en ContactDetailScreen**:
```dart
EmptyState(
  message: l10n.noEventsMessage,
  icon: CupertinoIcons.calendar
)
```

**Ubicación**: Dentro de `SliverToBoxAdapter` cuando `availableEvents.isEmpty` es true
**Propósito**: Mostrar estado vacío cuando el contacto no tiene eventos
**Configuración específica**:
- `message`: "Sin eventos" (traducido)
- `icon`: Icono de calendario

**Renderizado condicional**: Solo se muestra si `availableEvents.isEmpty == true`

#### **EventCard** (líneas 266-270)
**Archivo**: `lib/widgets/event_card.dart`
**Documentación**: `lib/widgets_md/event_card.md`

**Uso en ContactDetailScreen**:
```dart
EventCard(
  event: event,
  onTap: () => _navigateToEventDetail(event),
  config: EventCardConfig(
    onDelete: (event, {bool shouldNavigate = false}) => _hideEvent(event)
  ),
)
```

**Ubicación**: Dentro de `SliverList` (delegate builder), renderizado para cada evento del contacto
**Propósito**: Renderizar cada evento en el que participa el contacto
**Configuración específica**:
- `event`: Evento en el que participa el contacto
- `onTap`: Navega a EventDetailScreen
- `config`: EventCardConfig con `onDelete` que oculta el evento (no lo elimina)

**Nota importante**:
- El botón de eliminar oculta el evento localmente agregándolo a `_hiddenEventIds`
- No elimina el evento del backend
- Se muestra snackbar "Evento oculto"

**Renderizado condicional**: Solo se muestra si `availableEvents.isNotEmpty == true`

#### **AdaptiveButton** (línea 261)
**Archivo**: `lib/widgets/adaptive/adaptive_button.dart`
**Documentación**: `lib/widgets_md/adaptive_button.md`

**Uso en ContactDetailScreen**:
```dart
AdaptiveButton(
  config: AdaptiveButtonConfigExtended.destructive(),
  text: l10n.blockUser,
  enabled: !_blockingUser,
  onPressed: _showBlockConfirmation
)
```

**Ubicación**: Dentro de `SliverList` como último elemento (index == availableEvents.length)
**Propósito**: Botón para bloquear al usuario
**Configuración específica**:
- `config`: AdaptiveButtonConfigExtended.destructive() (estilo destructivo/rojo)
- `text`: "Bloquear usuario" (traducido)
- `enabled`: Deshabilitado mientras está bloqueando (_blockingUser)
- `onPressed`: Llama a `_showBlockConfirmation()` que muestra diálogo de confirmación

**Renderizado condicional**: Solo se muestra si hay eventos (no se muestra en estado vacío)

### 2.2. Resumen de Dependencias de Widgets

```
ContactDetailScreen
└── AdaptivePageScaffold
    └── SafeArea
        └── Column
            ├── Container (header card)
            │   └── Row
            │       ├── UserAvatar
            │       └── Column (nombre + Instagram)
            └── Expanded
                ├── [loading] → PlatformWidgets.platformLoadingIndicator
                ├── [error] → Column (mensaje + botón reintentar)
                └── [data] → CustomScrollView
                    ├── SliverToBoxAdapter (título "Eventos")
                    ├── SliverToBoxAdapter (si no hay eventos)
                    │   └── EmptyState
                    └── SliverList (si hay eventos)
                        ├── EventCard (múltiples, uno por evento)
                        │   └── EventDetailScreen (navegación al tap)
                        └── AdaptiveButton (bloquear usuario, último elemento)
```

**Total de widgets propios**: 5 (AdaptivePageScaffold, UserAvatar, EmptyState, EventCard, AdaptiveButton)

**Características especiales**:
- Observer de ciclo de vida para recargar al volver a la app
- Filtrado de eventos con `excludedEventIds` y `_hiddenEventIds`
- Ocultar eventos localmente (no eliminación real)
- Botón de bloquear con confirmación y estado de procesamiento
- Navegación con resultado 'blocked' al volver

---

## 3. CLASE Y PROPIEDADES

### ContactDetailScreen (líneas 23-31)
Widget principal que extiende `ConsumerStatefulWidget`

**Propiedades**:
- `contact` (User, required): Contacto cuyos detalles se mostrarán
- `excludedEventIds` (List<Event>?, optional): Lista de eventos a excluir de la visualización

**Nota**: El parámetro excludedEventIds es una lista de Events pero se usa para extraer IDs

### _ContactDetailScreenState (líneas 33-292)
Estado del widget que gestiona la lógica de la pantalla. Implementa `WidgetsBindingObserver` para detectar cambios en el ciclo de vida de la app

**Propiedades de instancia**:
- `_isLoading` (bool): Si está cargando detalles del contacto
- `_error` (String?): Mensaje de error si ocurrió alguno
- `_blockingUser` (bool): Si está en proceso de bloquear al usuario
- `_hiddenEventIds` (Set<int>): Set de IDs de eventos ocultados localmente

## 3. CICLO DE VIDA

### initState() (líneas 41-48)
1. Llama a `super.initState()`
2. Registra el observer: `WidgetsBinding.instance.addObserver(this)`
3. Usa `addPostFrameCallback` para:
   - Esperar al primer frame
   - Llamar a `_loadContactDetail()`

### dispose() (líneas 51-54)
1. Remueve el observer: `WidgetsBinding.instance.removeObserver(this)`
2. Llama a `super.dispose()`

### didChangeAppLifecycleState(AppLifecycleState state) (líneas 57-65)
**Propósito**: Callback que se ejecuta cuando cambia el estado del ciclo de vida de la app

**Lógica**:
- Si el estado es `resumed` y está montado:
  - Ejecuta función anónima async que llama a `_loadContactDetail()`
  - Recarga detalles del contacto al volver a la app

## 4. MÉTODOS DE CARGA DE DATOS

### _loadContactDetail() (líneas 67-92)
**Tipo de retorno**: `Future<void>`

**Propósito**: Carga los detalles del contacto desde la API

**Lógica**:
1. **Validación** (línea 68):
   - Si NO está montado O ya está cargando: retorna
2. **Activar loading** (líneas 70-73):
   - `setState()`: `_isLoading = true`, `_error = null`
3. **En bloque try-catch**:
   - **Try** (líneas 76-83):
     - Obtiene `currentUserId` del ConfigService
     - Llama a `ApiClient().fetchContact(contactId, currentUserId)`
     - Si está montado: `setState()`: `_isLoading = false`
   - **Catch** (líneas 84-91):
     - Si está montado:
       - `setState()`: `_error = e.toString()`, `_isLoading = false`

**Nota**: La API parece cargar detalles del contacto pero NO se guarda en variable de estado, posiblemente actualiza algún provider o se usa para tracking

## 5. MÉTODOS DE FILTRADO

### _filterAvailableEvents(List<Event> allEvents) (líneas 94-107)
**Tipo de retorno**: `List<Event>`

**Parámetros**:
- `allEvents`: Lista de todos los eventos a filtrar

**Propósito**: Filtra eventos excluyendo los que están en excludedEventIds o hiddenEventIds

**Lógica**:
1. **Crea set de IDs excluidos** (líneas 95-98):
   - Inicializa `excludedIds` como Set vacío
   - Si hay `excludedEventIds`:
     - Extrae los IDs de los eventos (map a id)
     - Filtra nulls con `where((id) => id != null)`
     - Cast a int
     - Añade al set con `addAll()`
2. **Combina exclusiones** (línea 100):
   - Crea `allExcludedIds` con spread operator: `{...excludedIds, ..._hiddenEventIds}`
   - Une ambos sets
3. **Filtra eventos** (líneas 102-104):
   - Usa `where()` para filtrar eventos donde:
     - `event.id` NO es null
     - `event.id` NO está en `allExcludedIds`
4. Retorna lista filtrada

## 6. MÉTODOS DE NAVEGACIÓN

### _navigateToEventDetail(Event event) (líneas 109-111)
**Tipo de retorno**: `void`

**Parámetros**:
- `event`: Evento a mostrar en detalle

**Propósito**: Navega a la pantalla de detalle del evento

**Lógica**:
- Usa `Navigator.of(context).pushScreen()` (extension method)
- Navega a `EventDetailScreen(event: event)`

## 7. MÉTODOS DE BLOQUEO

### _showBlockConfirmation() (líneas 113-125)
**Tipo de retorno**: `void`

**Propósito**: Muestra diálogo de confirmación antes de bloquear al usuario

**Lógica**:
1. Obtiene localizaciones
2. Guarda contexto en `safeContext` (para uso en async)
3. Obtiene nombre del contacto
4. **Define función interna async** `handleBlockConfirmation()` (líneas 117-122):
   - Llama a `PlatformWidgets.showPlatformConfirmDialog()` con:
     - title: "Bloquear usuario"
     - message: "¿Confirmar bloquear a {nombre}?"
     - confirmText: "Bloquear usuario"
     - cancelText: "Cancelar"
     - isDestructive: true (botón rojo)
   - Si confirmed es true: llama a `_blockUser()`
5. Llama a la función interna

**Nota**: Patrón de función interna para manejar async dentro de método síncrono

### _blockUser() (líneas 127-161)
**Tipo de retorno**: `Future<void>`

**Propósito**: Bloquea al usuario contacto

**Lógica**:
1. **Validación** (línea 128):
   - Si ya está bloqueando: retorna (previene doble tap)
2. **Preparación** (líneas 130-136):
   - Guarda contacto en variable local `safeContact`
   - Obtiene localizaciones
   - Obtiene `userBlockingRepositoryProvider`
   - Verifica que usuario esté logueado con `ConfigService.instance.hasUser`:
     - Si NO está logueado: muestra mensaje y retorna
3. **Activar flag** (líneas 138-140):
   - `setState()`: `_blockingUser = true`
4. **En bloque try-catch-finally**:
   - **Try** (líneas 142-149):
     - Llama a `userBlockingRepo.blockUser(contactId)`
     - Verifica mounted (línea 144)
     - Verifica mounted de nuevo (línea 146, duplicado)
     - Muestra mensaje "Usuario bloqueado correctamente"
     - Navega atrás con `Navigator.pop('blocked')` y retorna 'blocked'
   - **Catch** (líneas 150-153):
     - Si está montado: muestra mensaje de error con detalles
   - **Finally** (líneas 154-160):
     - Si está montado: `setState()`: `_blockingUser = false`

**Nota**: Líneas 144 y 146 tienen mounted checks duplicados

### _showMessage(String message, {bool isSuccess = false}) (líneas 163-165)
**Tipo de retorno**: `void`

**Parámetros**:
- `message`: Mensaje a mostrar
- `isSuccess`: Si es mensaje de éxito (default: false)

**Propósito**: Muestra snackbar con mensaje

**Lógica**:
- Llama a `PlatformWidgets.showSnackBar()` con:
  - `isError: !isSuccess` (invierte el flag)

## 8. MÉTODO BUILD PRINCIPAL

### build(BuildContext context, WidgetRef ref) (líneas 168-176)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la UI principal de la pantalla

**Lógica**:
1. Obtiene localizaciones
2. Detecta plataforma iOS
3. Retorna `AdaptivePageScaffold` con:
   - title: nombre del contacto (displayName)
   - body: SafeArea con `_buildBody(isIOS, l10n)`

### _buildBody(bool isIOS, AppLocalizations l10n) (líneas 178-280)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `isIOS`: Si es plataforma iOS
- `l10n`: Localizaciones

**Propósito**: Construye el contenido de la pantalla

**Estructura**:
Column con:

1. **Tarjeta de información del contacto** (líneas 181-210):
   - Container con:
     - Width: double.infinity
     - Padding: 16px
     - Margin: 16px
     - Fondo: systemGroupedBackground (iOS) o cardBackgroundColor (Android)
     - Border radius: 12px
   - Contenido Row:
     - `UserAvatar` del contacto (radio 30, sin indicador online)
     - Espaciador 16px
     - Column expandida:
       - Nombre del contacto (tamaño 18, peso 600, negro87)
       - Si tiene Instagram:
         - Espaciador 4px
         - Text: "@{instagramName}" (tamaño 14, gris600)

2. **Contenido expandido** (líneas 212-277):
   - Usa Builder para acceder a contexto
   - **Si está loading** (líneas 215-217):
     - Center con loading indicator adaptativo
   - **Si hay error** (líneas 219-230):
     - Center con Column:
       - Text: "Error al cargar datos" (gris600, tamaño 16)
       - Espaciador 16px
       - Botón "Reintentar" que llama a `_loadContactDetail()`
   - **Si hay datos** (líneas 232-274):
     - **Obtiene eventos del contacto** (líneas 232-235):
       - Observa `eventsStreamProvider`
       - Extrae eventos con `.when()` (data/loading/error)
       - Filtra eventos donde el contacto es asistente:
         - Verifica que attendees contenga el contacto
         - Maneja attendees como User o como Map
         - Compara por ID
     - **Filtra eventos disponibles** (línea 235):
       - Llama a `_filterAvailableEvents()`
     - **Retorna CustomScrollView** con:
       - **SliverToBoxAdapter** (líneas 240-248): Header "Eventos"
         - Padding 16px
         - Text: "Eventos" (tamaño 18, bold, negro87)
       - **Condicional**:
         - **Si no hay eventos** (líneas 250-253):
           - `SliverToBoxAdapter` con `EmptyState`:
             - Mensaje: "Sin eventos"
             - Icono: calendario
         - **Si hay eventos** (líneas 254-272):
           - `SliverList` con builder:
             - **Si es último índice** (líneas 257-263):
               - Retorna botón de bloqueo:
                 - Container con margin 16px, ancho completo
                 - `AdaptiveButton` destructivo
                 - Text: "Bloquear usuario"
                 - enabled: `!_blockingUser`
                 - onPressed: `_showBlockConfirmation()`
             - **Si NO es último índice** (líneas 265-270):
               - `EventCard` con:
                 - event: el evento
                 - onTap: navega a detalle
                 - config: con `onDelete` que llama a `_hideEvent()`
             - **childCount**: `availableEvents.length + 1` (el +1 es para el botón)

## 9. MÉTODO DE OCULTAR EVENTO

### _hideEvent(Event event) (líneas 282-291)
**Tipo de retorno**: `void`

**Parámetros**:
- `event`: Evento a ocultar

**Propósito**: Oculta un evento de la lista localmente (no lo elimina)

**Lógica**:
1. Si `event.id` NO es null:
   - `setState()`: añade ID al set `_hiddenEventIds`
   - Obtiene localizaciones
   - Muestra snackbar: "Evento {título} ocultado"
   - Duración: 2 segundos

**Nota**: Es un ocultar "soft", no elimina ni abandona el evento, solo lo oculta de esta vista

## 10. DEPENDENCIAS

### Providers utilizados:
- `eventsStreamProvider`: Stream de eventos (watch)
- `userBlockingRepositoryProvider`: Repositorio de bloqueo de usuarios (read)

### Services:
- `ConfigService.instance.currentUserId`: ID del usuario actual
- `ConfigService.instance.hasUser`: Si hay usuario logueado

### Repositories:
- `UserRepository.fetchContact()`: Carga detalles del contacto (a través del provider)

**Arquitectura**: Screen → Provider → Repository → ApiClient

### Widgets externos:
- `CustomScrollView`: Vista scrollable
- `SliverToBoxAdapter`: Adapta widget a sliver
- `SliverList`: Lista perezosa
- `SliverChildBuilderDelegate`: Builder de hijos
- `CupertinoButton`: Botón de iOS

### Widgets internos:
- `AdaptivePageScaffold`: Scaffold adaptativo
- `UserAvatar`: Avatar de usuario
- `EventCard`: Tarjeta de evento
- `EventCardConfig`: Configuración de EventCard
- `EmptyState`: Estado vacío
- `EventDetailScreen`: Pantalla de detalle
- `AdaptiveButton`: Botón adaptativo

### Helpers:
- `PlatformWidgets.platformLoadingIndicator()`: Loading indicator adaptativo
- `PlatformWidgets.showPlatformConfirmDialog()`: Diálogo de confirmación
- `PlatformWidgets.showSnackBar()`: Muestra snackbars
- `PlatformWidgets.isIOS`: Detecta iOS
- `Navigator.pushScreen()`: Extension method para navegación

### Localización:
Strings usados:
- `displayName`: Nombre a mostrar del contacto
- `events`: "Eventos"
- `errorLoadingData`: "Error al cargar datos"
- `retry`: "Reintentar"
- `noEventsMessage`: "Sin eventos"
- `blockUser`: "Bloquear usuario"
- `confirmBlockUser`: "¿Confirmar bloquear a {nombre}?"
- `cancel`: "Cancelar"
- `userNotLoggedIn`: "Usuario no conectado"
- `userBlockedSuccessfully`: "Usuario bloqueado correctamente"
- `errorBlockingUserDetail`: "Error al bloquear usuario: {detalle}"
- `eventHidden`: "Evento {título} ocultado"

### Models:
- `User`: Modelo de usuario/contacto
- `Event`: Modelo de evento

## 11. FLUJO DE DATOS

### Al abrir la pantalla:
1. `initState()` se ejecuta
2. Registra observer de ciclo de vida
3. Después del primer frame: llama a `_loadContactDetail()`
4. API carga detalles del contacto
5. Observa `eventsStreamProvider` para obtener eventos
6. Filtra eventos donde el contacto es asistente
7. Aplica filtros de exclusión
8. Renderiza lista de eventos + botón de bloqueo

### Al volver a la app:
1. `didChangeAppLifecycleState()` detecta `resumed`
2. Llama a `_loadContactDetail()` de nuevo
3. Refresca datos del contacto

### Al ocultar evento:
1. Usuario presiona botón de "delete" en `EventCard`
2. `_hideEvent()` se ejecuta
3. Añade ID al set `_hiddenEventIds`
4. `setState()` reconstruye UI
5. `_filterAvailableEvents()` excluye eventos ocultos
6. Evento desaparece de la lista
7. Muestra snackbar de confirmación

### Al bloquear usuario:
1. Usuario presiona botón "Bloquear usuario"
2. `_showBlockConfirmation()` muestra diálogo
3. Usuario confirma
4. `_blockUser()` se ejecuta:
   - Activa flag `_blockingUser` (deshabilita botón)
   - Llama a API de bloqueo
   - Muestra mensaje de éxito
   - Navega atrás con resultado 'blocked'
5. Pantalla se cierra

## 12. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Ver información del contacto**: Avatar, nombre, Instagram
2. **Ver eventos compartidos**: Lista de eventos en los que ambos participan
3. **Ocultar eventos**: Oculta eventos de la vista temporalmente
4. **Bloquear usuario**: Permite bloquear al contacto
5. **Navegación a detalle**: Tap en evento muestra detalle
6. **Exclusión de eventos**: Puede recibir lista de eventos a excluir

### Estados manejados:
- Loading (cargando detalles)
- Error (con opción de reintentar)
- Data (lista de eventos)
  - Lista vacía (estado vacío)
  - Lista con eventos
- Bloqueando usuario (botón deshabilitado)

### Botón de bloqueo:
- Posicionado al final de la lista
- Estilo destructivo (rojo)
- Se deshabilita mientras bloquea
- Requiere confirmación antes de bloquear
- Cierra pantalla después de bloquear

### Evento ocultar vs eliminar:
- Esta pantalla NO permite eliminar eventos
- Solo permite "ocultar" localmente
- Uso del callback `onDelete` de EventCard para ocultar (nombre confuso)
- Los eventos ocultos se mantienen en `_hiddenEventIds` set

### Filtrado de eventos:
- Filtra por asistentes que incluyen al contacto
- Maneja attendees como User o Map (robustez)
- Excluye eventos de parámetro `excludedEventIds`
- Excluye eventos ocultos localmente `_hiddenEventIds`

## 13. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 293
**Métodos públicos**: 2 (build, didChangeAppLifecycleState)
**Métodos privados**: 8

**Distribución aproximada**:
- Imports: ~22 líneas (7.5%)
- Declaración de clase y propiedades: ~16 líneas (5.5%)
- Ciclo de vida: ~25 líneas (8.5%)
- Carga de datos: ~26 líneas (8.9%)
- Filtrado: ~14 líneas (4.8%)
- Navegación: ~3 líneas (1.0%)
- Bloqueo: ~52 líneas (17.7%)
- Mostrar mensaje: ~3 líneas (1.0%)
- build method: ~9 líneas (3.1%)
- _buildBody method: ~103 líneas (35.2%)
- _hideEvent method: ~10 líneas (3.4%)
- Resto: ~10 líneas (3.4%)

## 14. CARACTERÍSTICAS TÉCNICAS

### WidgetsBindingObserver:
- Detecta cambios en ciclo de vida de la app
- Recarga datos al volver a la app (`resumed`)
- Útil para refrescar después de dar permisos o hacer cambios externos

### PostFrameCallback:
- Espera al primer frame antes de cargar datos
- Previene llamadas a setState durante build
- Patrón común en initState

### Safe context pattern:
- Guarda contexto en variable antes de async
- Previene uso de contexto desmontado
- Usado en `_showBlockConfirmation()`

### Función interna async:
- Define función async dentro de método síncrono
- Permite await en método que no puede ser async
- Patrón para manejar diálogos con confirmación

### Mounted checks duplicados:
- Líneas 144 y 146 en `_blockUser()` verifican mounted dos veces
- Posiblemente código legacy o error de merge
- Primer check es suficiente

### Botón como último item:
- Builder de SliverList incluye botón al final
- `if (index == availableEvents.length)`: retorna botón
- childCount: `length + 1` para incluir botón
- Patrón para añadir elemento fijo al final de lista dinámica

### Hidden events con Set:
- Usa `Set<int>` en lugar de `List<int>`
- Búsqueda O(1) vs O(n)
- Más eficiente para verificar si ID está oculto

### Navigator con resultado:
- `Navigator.pop('blocked')` retorna string
- Pantalla anterior puede reaccionar a bloqueo
- Pattern para comunicación entre pantallas

### ExcludedEventIds confuso:
- Parámetro es `List<Event>?` pero se usa para IDs
- Debería ser `List<int>?` directamente
- Necesita map + filter + cast para extraer IDs

### FetchContact sin guardar:
- `ApiClient().fetchContact()` se llama pero resultado no se guarda
- Posiblemente actualiza caché o se usa para analytics
- O es llamada legacy que ya no se necesita

### Ocultar vs Eliminar:
- EventCard config usa `onDelete` pero solo oculta
- Nombre del callback no refleja comportamiento real
- Podría confundir en mantenimiento futuro

### Filtrado de asistentes robusto:
- Maneja attendees como `User` o como `Map`
- Usa `is User` para type check
- Usa `is Map` para type check
- Extrae ID apropiadamente según tipo
