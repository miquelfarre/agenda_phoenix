# InviteUsersScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/invite_users_screen.dart`
**Líneas**: 352
**Tipo**: ConsumerStatefulWidget with WidgetsBindingObserver
**Propósito**: Pantalla que permite invitar usuarios y grupos a un evento, con funcionalidad de búsqueda y selección múltiple

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **AdaptivePageScaffold** (línea 321)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_page_scaffold.md`

**Uso**: Scaffold principal con actions dinámicas (botón de enviar cuando hay selección)

#### **EmptyState** (2 usos)
**Archivo**: `lib/widgets/empty_state.dart`
**Documentación**: `lib/widgets_md/empty_state.md`

**Usos**:
1. **Línea 199**: Sin usuarios/grupos disponibles (icon: person_badge_plus)
2. **Línea 210**: Sin resultados de búsqueda (icon: search)

#### **SelectableCard** (2 usos en map)
**Archivo**: `lib/widgets/selectable_card.dart`
**Documentación**: Pendiente

**Usos**:
1. **Línea 220**: Tarjetas de usuarios (icon: person, color: blue600)
2. **Línea 234**: Tarjetas de grupos (icon: person_2, color: blue600)

**Configuración**: Cada tarjeta permite selección con checkbox y tap

#### **AdaptiveButton** (línea 342)
**Archivo**: `lib/widgets/adaptive/adaptive_button.dart`
**Documentación**: `lib/widgets_md/adaptive_button.md`

**Uso**: Botón "Enviar" en actions, solo visible cuando hay selección
**Configuración**: Variant text, size medium, con icono en iOS y solo icono en Android

**Total de widgets propios**: 4 (AdaptivePageScaffold, EmptyState, SelectableCard, AdaptiveButton)

**Características especiales**:
- Búsqueda en tiempo real
- Selección múltiple de usuarios y grupos
- Expansión de grupos a usuarios individuales
- Seguimiento de usuarios recientemente invitados
- Envío de invitaciones en lote

---

## 3. CLASE Y PROPIEDADES

### InviteUsersScreen (líneas 18-24)
Widget principal que extiende `ConsumerStatefulWidget`

**Propiedades**:
- `event` (Event, required): Evento al que se invitarán usuarios

### _InviteUsersScreenState (líneas 26-351)
Estado del widget que gestiona la lógica de la pantalla. Implementa `WidgetsBindingObserver` para detectar cambios en el ciclo de vida de la app

**Propiedades de instancia**:
- `_availableUsers` (List<User>): Lista de usuarios disponibles para invitar (cargados desde API)
- `_groups` (List<Group>): Lista de grupos disponibles (actualmente vacía, funcionalidad futura)
- `_recentlyInvitedUserIds` (Set<int>): Set de IDs de usuarios que ya fueron invitados en esta sesión
- `selectedUserIds` (Set<int>): Set de IDs de usuarios seleccionados para invitar
- `selectedGroupIds` (Set<int>): Set de IDs de grupos seleccionados para invitar
- `_isLoading` (bool): Si está cargando datos
- `isSending` (bool): Si está enviando invitaciones
- `_error` (String?): Mensaje de error si ocurrió alguno
- `searchQuery` (String): Query de búsqueda actual

## 3. CICLO DE VIDA

### initState() (líneas 38-45)
1. Llama a `super.initState()`
2. Registra el observer: `WidgetsBinding.instance.addObserver(this)`
3. Usa `addPostFrameCallback` para:
   - Verificar que esté montado
   - Llamar a `_loadData()`

### dispose() (líneas 48-51)
1. Remueve el observer: `WidgetsBinding.instance.removeObserver(this)`
2. Llama a `super.dispose()`

### didChangeAppLifecycleState(AppLifecycleState state) (líneas 54-60)
**Propósito**: Callback que se ejecuta cuando cambia el estado del ciclo de vida de la app

**Lógica**:
- Si el estado es `resumed` y está montado:
  - Llama a `_loadData()` para recargar datos

## 4. MÉTODOS DE CARGA DE DATOS

### _loadData() (líneas 62-110)
**Tipo de retorno**: `Future<void>`

**Propósito**: Carga usuarios disponibles para invitar desde la API

**Lógica con logs**:
1. **Print inicial** (línea 63): "🔵 [InviteUsersScreen] _loadData START"
2. **Activar loading** (líneas 64-67):
   - `setState()`: `_isLoading = true`, `_error = null`
3. **En bloque try-catch**:
   - **Validación de usuario** (líneas 70-77):
     - Si NO hay usuario logueado (`!ConfigService.instance.hasUser`):
       - Obtiene localizaciones
       - `setState()`: `_error = "Usuario no conectado"`, `_isLoading = false`
       - Retorna
   - **Validación de eventId** (líneas 79-87):
     - Si `widget.event.id` es null:
       - Obtiene localizaciones
       - `setState()`: `_error = "Event ID missing"`, `_isLoading = false`
       - Retorna
   - **Fetch usuarios** (líneas 89-92):
     - Imprime log "Calling fetchAvailableInvitees..."
     - Llama a `ApiClient().fetchAvailableInvitees(eventId)`
     - Imprime cantidad de usuarios disponibles
   - **Actualizar estado** (líneas 93-100):
     - Si está montado:
       - `setState()`:
         - `_availableUsers`: parsea users con `User.fromJson()`
         - `_groups = []` (vacío, funcionalidad futura)
         - `_isLoading = false`
       - Imprime confirmación
4. **En catch** (líneas 101-109):
   - Imprime error con 🔴
   - Si está montado:
     - `setState()`: `_error = e.toString()`, `_isLoading = false`

## 5. MÉTODOS DE SELECCIÓN

### _toggleUser(int userId) (líneas 112-116)
**Tipo de retorno**: `void`

**Parámetros**:
- `userId`: ID del usuario a toggle

**Propósito**: Añade o elimina usuario del set de selección

**Lógica**:
- `setState()`:
  - Si el ID está en el set: lo elimina
  - Si NO está: lo añade
- Usa operador ternario para toggle en una línea

### _toggleGroup(int groupId) (líneas 118-122)
**Tipo de retorno**: `void`

**Parámetros**:
- `groupId`: ID del grupo a toggle

**Propósito**: Añade o elimina grupo del set de selección

**Lógica**: Similar a `_toggleUser()`

## 6. MÉTODOS DE FILTRADO

### _getFilteredUsers() (líneas 124-135)
**Tipo de retorno**: `List<User>`

**Propósito**: Filtra usuarios por recién invitados y búsqueda

**Lógica**:
1. **Filtra recién invitados** (líneas 125-127):
   - Usa `where()` para excluir usuarios en `_recentlyInvitedUserIds`
   - Previene invitar al mismo usuario múltiples veces en la sesión
2. **Si no hay búsqueda** (línea 129): Retorna lista filtrada
3. **Si hay búsqueda** (líneas 131-134):
   - Convierte query a lowercase
   - Filtra donde:
     - `displayName` contiene query, O
     - `displaySubtitle` contiene query (si existe)
   - Búsqueda case insensitive
4. Retorna lista filtrada

### _getFilteredGroups() (líneas 137-144)
**Tipo de retorno**: `List<Group>`

**Propósito**: Filtra grupos por búsqueda

**Lógica**:
1. Si no hay búsqueda: retorna todos los grupos
2. Si hay búsqueda:
   - Filtra donde:
     - `name` contiene query, O
     - `description` contiene query
   - Case insensitive
3. Retorna lista filtrada

## 7. MÉTODOS DE CONSTRUCCIÓN DE UI

### _buildSearchField() (líneas 146-162)
**Tipo de retorno**: `Widget`

**Propósito**: Construye campo de búsqueda

**Estructura**:
- Padding (horizontal 16px, vertical 8px)
- `CupertinoSearchTextField` con:
  - placeholder: "Buscar"
  - onChanged: actualiza `searchQuery` con `setState()`
  - style: gris700
  - backgroundColor: gris100
  - borderRadius: 12px

### _buildBody(BuildContext context) (líneas 164-166)
**Tipo de retorno**: `Widget`

**Propósito**: Construye body con SafeArea

**Lógica**:
- Retorna SafeArea con `_buildContent()`

### _buildContent() (líneas 168-239)
**Tipo de retorno**: `Widget`

**Propósito**: Construye el contenido según el estado

**Lógica**:
1. **Si está loading** (líneas 170-172):
   - Retorna Center con loading indicator (radio 16)

2. **Si hay error** (líneas 174-193):
   - Retorna Center con Column:
     - Icono: exclamationmark_triangle (48px, gris500)
     - Espaciador 16px
     - Text: "Error al cargar datos" (cardTitle, gris700)
     - Espaciador 8px
     - Text con error (elimina "Exception: " del inicio, centrado, gris600)
     - Espaciador 24px
     - Botón "Reintentar" que llama a `_loadData()`

3. **Si hay datos** (líneas 195-238):
   - **Obtiene listas filtradas** (líneas 195-196):
     - Llama a `_getFilteredUsers()`
     - Llama a `_getFilteredGroups()`
   - **Si no hay usuarios ni grupos Y no hay búsqueda** (líneas 198-200):
     - Retorna `EmptyState`:
       - Mensaje: "No hay usuarios o grupos disponibles"
       - Icono: person_badge_plus
   - **Si hay datos o búsqueda** (líneas 202-238):
     - Retorna ListView con:
       - **Campo de búsqueda** (línea 206): `_buildSearchField()`
       - **Si hay búsqueda sin resultados** (líneas 207-212):
         - Padding con `EmptyState`: "No hay resultados"
       - **Si hay usuarios** (líneas 213-222):
         - Header "Usuarios" (padding, cardTitle, gris700)
         - Map de usuarios a `SelectableCard`:
           - title: displayName
           - subtitle: displaySubtitle
           - icon: person
           - color: azul600
           - selected: si está en selectedUserIds
           - onTap y onChanged: llama a `_toggleUser()`
       - **Si hay grupos** (líneas 223-236):
         - Header "Grupos" (padding, bold, tamaño 18, gris700)
         - Map de grupos a `SelectableCard`:
           - title: name
           - subtitle: description
           - icon: person_2
           - color: azul600
           - selected: si está en selectedGroupIds
           - onTap y onChanged: llama a `_toggleGroup()`

## 8. MÉTODO DE ENVÍO DE INVITACIONES

### _sendInvitations() (líneas 241-316)
**Tipo de retorno**: `Future<void>`

**Propósito**: Envía invitaciones a usuarios y grupos seleccionados

**Lógica**:
1. **Validaciones** (líneas 242-248):
   - Si ya está enviando: retorna (previene doble tap)
   - Si no hay selección: retorna

2. **Activar flag** (líneas 250-252):
   - `setState()`: `isSending = true`

3. **En bloque try-catch**:
   - **Validar eventId** (líneas 255-258):
     - Si es null: lanza excepción

   - **Recopilar IDs de usuarios** (líneas 260-269):
     - Inicializa set con usuarios seleccionados: `{...selectedUserIds}`
     - **Para cada grupo seleccionado**:
       - Busca el grupo en `_groups`
       - Si existe:
         - Añade IDs de todos los miembros al set
     - **Resultado**: Set con todos los IDs de usuarios a invitar (incluyendo miembros de grupos)

   - **Enviar invitaciones** (líneas 271-285):
     - Obtiene `eventInteractionRepositoryProvider`
     - Inicializa contadores: `successCount = 0`, `errorCount = 0`
     - **Para cada userId**:
       - En try-catch interno:
         - Llama a `eventInteractionRepository.sendInvitation(eventId, userId, null)`
         - Incrementa `successCount`
         - Añade userId a `_recentlyInvitedUserIds` (para ocultar en siguiente uso)
       - En catch interno:
         - Incrementa `errorCount`
         - Imprime error

   - **Actualizar UI** (líneas 287-306):
     - Si está montado:
       - `setState()`:
         - `isSending = false`
         - Limpia `selectedUserIds`
         - Limpia `selectedGroupIds`
       - Obtiene localizaciones
       - Si `successCount > 0`:
         - Muestra snackbar: "{cantidad} invitaciones enviadas"
       - Si `errorCount > 0`:
         - Muestra snackbar de error: "{cantidad} invitaciones fallaron"
       - Si todas exitosas (`successCount > 0` Y `errorCount == 0`):
         - Navega atrás con `Navigator.pop()`

4. **En catch principal** (líneas 307-315):
   - Si está montado:
     - `setState()`: `isSending = false`
     - Muestra snackbar de error

## 9. MÉTODO BUILD Y ACTIONS

### build(BuildContext context, WidgetRef ref) (líneas 319-322)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la UI principal de la pantalla

**Lógica**:
- Obtiene localizaciones
- Retorna `AdaptivePageScaffold` con:
  - title: "Invitar al evento"
  - actions: llama a `_buildActions()`
  - body: llama a `_buildBody()`

### _buildActions() (líneas 324-350)
**Tipo de retorno**: `List<Widget>`

**Propósito**: Construye las acciones del navigation bar

**Lógica**:
1. **Si está enviando** (líneas 326-333):
   - Retorna lista con:
     - Padding con loading indicator pequeño (20x20, radio 10, blanco)

2. **Si no hay selección** (líneas 335-337):
   - Retorna lista vacía (no muestra botón)

3. **Si hay selección** (líneas 339-349):
   - Retorna lista con:
     - Tooltip: "Enviar invitaciones"
     - `AdaptiveButton` con:
       - variant: text
       - size: medium
       - fullWidth: false
       - iconPosition: leading
       - text: "Enviar" (solo iOS)
       - icon: paperplane (solo Android)
       - onPressed: `_sendInvitations()`

## 10. DEPENDENCIAS

### Providers utilizados:
- `eventInteractionRepositoryProvider`: Repositorio de interacciones de eventos (read)

### Services:
- `ApiClient().fetchAvailableInvitees()`: Carga usuarios disponibles para invitar
- `ConfigService.instance.hasUser`: Si hay usuario logueado

### Widgets externos:
- `CupertinoSearchTextField`: Campo de búsqueda de iOS
- `ListView`: Lista scrollable
- `Tooltip`: Tooltip para botón

### Widgets internos:
- `AdaptivePageScaffold`: Scaffold adaptativo
- `SelectableCard`: Tarjeta seleccionable personalizada
- `EmptyState`: Estado vacío
- `AdaptiveButton`: Botón adaptativo

### Helpers:
- `PlatformWidgets.platformLoadingIndicator()`: Loading indicator adaptativo
- `PlatformWidgets.platformIcon()`: Icono adaptativo
- `PlatformWidgets.platformButton()`: Botón adaptativo
- `PlatformWidgets.showSnackBar()`: Muestra snackbars
- `PlatformWidgets.isIOS`: Detecta iOS

### Localización:
Strings usados:
- `inviteToEvent`: "Invitar al evento"
- `userNotLoggedIn`: "Usuario no conectado"
- `eventIdMissing`: "Event ID missing"
- `search`: "Buscar"
- `appErrorLoadingData`: "Error al cargar datos"
- `retry`: "Reintentar"
- `noUsersOrGroupsAvailable`: "No hay usuarios o grupos disponibles"
- `noSearchResults`: "No hay resultados"
- `users`: "Usuarios"
- `groups`: "Grupos"
- `sendInvitations`: "Enviar invitaciones"
- `send`: "Enviar"
- `invitationsSent`: "invitaciones enviadas"
- `invitationsFailed`: "invitaciones fallaron"

### Models:
- `Event`: Modelo de evento
- `User`: Modelo de usuario
- `Group`: Modelo de grupo

## 11. FLUJO DE DATOS

### Al abrir la pantalla:
1. `initState()` se ejecuta
2. Registra observer
3. Después del primer frame: llama a `_loadData()`
4. Fetch usuarios disponibles desde API
5. Parsea y guarda en `_availableUsers`
6. Renderiza lista de usuarios seleccionables

### Al buscar:
1. Usuario escribe en campo de búsqueda
2. onChanged actualiza `searchQuery`
3. `_getFilteredUsers()` filtra por nombre y subtitle
4. `_getFilteredGroups()` filtra por nombre y descripción
5. Lista se actualiza

### Al seleccionar usuario:
1. Usuario tap en `SelectableCard`
2. `_toggleUser()` se ejecuta
3. Toggle ID en `selectedUserIds` set
4. Card se marca/desmarca
5. Botón "Enviar" aparece/desaparece en navbar

### Al enviar invitaciones:
1. Usuario presiona botón "Enviar"
2. `_sendInvitations()` se ejecuta
3. Activa `isSending` (botón cambia a loading)
4. Recopila IDs de usuarios (incluyendo miembros de grupos)
5. **Para cada usuario**:
   - Llama a API para enviar invitación
   - Cuenta éxitos y fallos
   - Añade a `_recentlyInvitedUserIds`
6. Limpia selección
7. Muestra snackbars con resultados
8. Si todas exitosas: cierra pantalla

### Al volver a la app:
1. `didChangeAppLifecycleState()` detecta `resumed`
2. Llama a `_loadData()` para recargar

## 12. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Cargar usuarios disponibles**: Fetch desde API
2. **Buscar usuarios/grupos**: Filtra por nombre y descripción
3. **Selección múltiple**: Usuarios y grupos
4. **Expansión de grupos**: Incluye miembros automáticamente
5. **Envío paralelo**: Invita a todos los seleccionados
6. **Contadores**: Muestra éxitos y fallos
7. **Prevención de duplicados**: Oculta recién invitados

### Estados manejados:
- Loading (cargando usuarios)
- Error (con opción de reintentar)
- Data (lista de usuarios y grupos)
  - Lista vacía (estado vacío)
  - Lista con datos (filtrada o completa)
- Enviando invitaciones (loading indicator en navbar)
- Selección activa (botón enviar visible)

### Botón de enviar dinámico:
- Solo visible cuando hay selección
- Cambia a loading indicator mientras envía
- Texto en iOS, icono en Android
- Tooltip para accesibilidad

### Prevención de duplicados:
- Set `_recentlyInvitedUserIds` mantiene IDs invitados
- `_getFilteredUsers()` los excluye
- Evita invitar al mismo usuario múltiples veces en la sesión
- Se mantiene durante toda la vida del widget

### Expansión de grupos:
- Al enviar: extrae todos los miembros del grupo
- Añade IDs al set de usuarios a invitar
- Un grupo puede tener múltiples miembros
- Se invita a cada miembro individualmente

### Envío robusto:
- Try-catch individual por cada invitación
- Continúa si una falla
- Cuenta éxitos y fallos
- Muestra ambos resultados al usuario

### Cierre automático:
- Solo cierra si todas las invitaciones fueron exitosas
- Si hay algún fallo: no cierra (permite reintentar)

## 13. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 352
**Métodos públicos**: 2 (build, didChangeAppLifecycleState)
**Métodos privados**: 10

**Distribución aproximada**:
- Imports: ~17 líneas (4.8%)
- Declaración de clase y propiedades: ~17 líneas (4.8%)
- Ciclo de vida: ~24 líneas (6.8%)
- Carga de datos: ~49 líneas (13.9%)
- Métodos de selección: ~11 líneas (3.1%)
- Métodos de filtrado: ~22 líneas (6.3%)
- Construcción de UI: ~76 líneas (21.6%)
- Envío de invitaciones: ~76 líneas (21.6%)
- build y actions: ~33 líneas (9.4%)
- Resto: ~27 líneas (7.7%)

## 14. CARACTERÍSTICAS TÉCNICAS

### Set para selección:
- Usa `Set<int>` en lugar de `List<int>`
- Verificación O(1) con `.contains()`
- No permite duplicados naturalmente
- Más eficiente para toggle

### Set para usuarios invitados:
- `_recentlyInvitedUserIds` persiste durante toda la sesión
- Previene UI confusa con usuarios recién invitados aún visibles
- No se limpia hasta cerrar la pantalla

### Envío paralelo pero secuencial:
- NO usa `Future.wait()` para enviar en paralelo
- Usa `for` loop con `await` (secuencial)
- Permite continuar si una invitación falla
- Podría optimizarse con paralelo pero actual es más robusto

### Toggle en una línea:
- `contains(id) ? remove(id) : add(id)`
- Patrón conciso para toggle
- Fácil de leer y mantener

### Grupos como expansión:
- Grupos no se envían directamente
- Se extraen miembros del grupo
- Se invita a cada miembro individualmente
- Backend recibe invitaciones de usuarios, no de grupos

### Loading states diferenciados:
- `_isLoading`: Cargando usuarios disponibles
- `isSending`: Enviando invitaciones
- Permiten UIs diferentes según el estado

### Filtrado en dos pasos:
1. Filtra recién invitados (excluye de lista)
2. Filtra por búsqueda (si hay query)
- Separación clara de responsabilidades

### Error handling granular:
- Try-catch principal para operación completa
- Try-catch individual para cada invitación
- Permite reporte detallado de éxitos/fallos

### Limpieza de "Exception: ":
- `_error!.replaceFirst('Exception: ', '')`
- Mejora legibilidad de errores para usuario
- Elimina prefijo técnico de Dart

### Mounted checks:
- Verifica `mounted` después de operaciones async
- Previene errores si widget fue desmontado

### Groups preparado para futuro:
- `_groups = []` se inicializa vacío
- UI ya está preparada para mostrar grupos
- Backend/API aún no devuelve grupos en `fetchAvailableInvitees()`

### Logs con emojis:
- 🔵: Operaciones normales
- 🔴: Errores
- Ayuda a identificar visualmente en consola
