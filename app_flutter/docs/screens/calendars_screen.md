# CalendarsScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/calendars_screen.dart`
**Líneas**: 462
**Tipo**: ConsumerStatefulWidget
**Propósito**: Pantalla principal que muestra la lista de calendarios del usuario y permite buscar/suscribirse a calendarios públicos mediante código hash

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **AdaptiveButton** (línea 139)
**Archivo**: `lib/widgets/adaptive/adaptive_button.dart`
**Documentación**: `lib/widgets_md/adaptive_button.md`

**Uso - FAB iOS**:
```dart
AdaptiveButton(
  config: const AdaptiveButtonConfig(
    variant: ButtonVariant.fab,
    size: ButtonSize.medium,
    fullWidth: false,
    iconPosition: IconPosition.only,
  ),
  icon: CupertinoIcons.add,
  onPressed: () => context.push('/calendars/create'),
)
```
**Ubicación**: Stack positioned (bottom: 100, right: 20) en iOS
**Propósito**: Botón flotante para crear calendario (solo iOS)
**Condición**: `if (isIOS)`

#### **EmptyState** (líneas 216, 240, 341, 356, 393)
**Archivo**: `lib/widgets/empty_state.dart`
**Documentación**: `lib/widgets_md/empty_state.md`

**Uso 1 - Error de búsqueda por hash** (línea 216):
```dart
EmptyState(
  icon: CupertinoIcons.search,
  message: _hashSearchError!,
)
```
**Ubicación**: `_buildSearchTab()` cuando `_hashSearchError != null`
**Propósito**: Mostrar mensaje de error al buscar por código hash
**Condición**: `_hashSearchError != null`

**Uso 2 - Instrucciones de búsqueda** (línea 240):
```dart
EmptyState(
  icon: CupertinoIcons.search,
  message: l10n.enterCodePrecededByHash,
)
```
**Ubicación**: `_buildSearchTab()` cuando no hay búsqueda activa
**Propósito**: Mostrar instrucciones para buscar calendarios públicos
**Condición**: `!_searchingByHash && _hashSearchResult == null && _hashSearchError == null`

**Uso 3 - Sin calendarios con acción** (línea 341):
```dart
EmptyState(
  icon: CupertinoIcons.calendar,
  message: context.l10n.noCalendarsYet,
  subtitle: context.l10n.noCalendarsSearchByCode,
  actionLabel: context.l10n.createCalendar,
  onAction: () => context.push('/calendars/create'),
)
```
**Ubicación**: `_buildMyCalendarsTab()` cuando `calendars.isEmpty`
**Propósito**: Estado vacío con llamada a acción para crear primer calendario
**Condición**: `calendars.isEmpty`
**Características**: Incluye subtítulo y botón de acción

**Uso 4 - Sin resultados de búsqueda** (línea 356):
```dart
EmptyState(
  icon: CupertinoIcons.search,
  message: context.l10n.noCalendarsFound,
)
```
**Ubicación**: `_buildMyCalendarsTab()` cuando hay búsqueda sin resultados
**Propósito**: Indicar que no hay calendarios que coincidan con la búsqueda
**Condición**: `filteredCalendars.isEmpty && searchQuery.isNotEmpty`

**Uso 5 - Error state** (línea 393):
```dart
EmptyState(
  icon: CupertinoIcons.exclamationmark_triangle,
  message: error.toString(),
)
```
**Ubicación**: `_buildMyCalendarsTab()` en el handler de error del AsyncValue
**Propósito**: Mostrar mensaje de error al cargar calendarios
**Condición**: `calendarsAsync.when(error: ...)`

#### **AdaptivePageScaffold** (línea 154)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_scaffold.md`

**Uso**:
```dart
AdaptivePageScaffold(
  title: isIOS ? null : l10n.calendars,
  body: body,
  floatingActionButton: !isIOS ? [FAB] : null,
)
```
**Propósito**: Scaffold adaptativo con navegación inferior y FAB condicional

### 2.2. Resumen de Dependencias de Widgets

```
CalendarsScreen
├── AdaptivePageScaffold (scaffold principal)
├── CustomScrollView
│   ├── SliverAppBar (título grande)
│   ├── SliverToBoxAdapter (search field)
│   ├── [Tab: Mis Calendarios]
│   │   ├── SliverList (calendarios)
│   │   └── [Condicional] SliverFillRemaining
│   │       └── EmptyState (sin calendarios, sin resultados, error)
│   └── [Tab: Buscar]
│       └── [Condicional] SliverFillRemaining
│           ├── EmptyState (instrucciones, error búsqueda)
│           └── Hash result card (custom)
└── [Condicional iOS] Stack
    └── Positioned
        └── AdaptiveButton (FAB)
```

**Total de widgets propios**: 3 (EmptyState, AdaptiveButton, AdaptivePageScaffold)
**Widget más usado**: EmptyState (5 casos de uso diferentes)

---

## 3. CLASE Y PROPIEDADES

### CalendarsScreen (líneas 17-22)
Widget principal que extiende `ConsumerStatefulWidget`

**Propiedades**: Ninguna (constructor solo con key)

### _CalendarsScreenState (líneas 24-461)
Estado del widget que gestiona la lógica de la pantalla

**Propiedades de instancia**:
- `_searchController` (TextEditingController): Controlador para el campo de búsqueda
- `_searchingByHash` (bool): Indica si se está buscando un calendario por código hash
- `_loadingHashSearch` (bool): Indica si se está cargando la búsqueda por hash
- `_hashSearchResult` (Calendar?): Resultado de la búsqueda por hash (si se encontró)
- `_hashSearchError` (String?): Mensaje de error si la búsqueda por hash falló

## 3. CICLO DE VIDA

### dispose() (líneas 32-35)
- Limpia el `_searchController` llamando a su método `dispose()`
- Llama a `super.dispose()`

**Nota**: No hay `initState()` en esta clase

## 4. MÉTODOS DE BÚSQUEDA

### _onSearchChanged(String value) (líneas 37-54)
**Propósito**: Callback que se ejecuta cuando cambia el texto del campo de búsqueda

**Parámetros**:
- `value`: El nuevo texto del campo de búsqueda

**Lógica**:
1. Llama a `setState()` con:
   - Resetea `_hashSearchResult` a null
   - Resetea `_hashSearchError` a null
   - Si el texto empieza con '#':
     - Activa `_searchingByHash = true`
     - Extrae el hash quitando el '#' y haciendo trim
     - Si el hash tiene 3 o más caracteres, llama a `_searchByHash(hash)`
   - Si el texto NO empieza con '#':
     - Desactiva `_searchingByHash = false`
     - Desactiva `_loadingHashSearch = false`

### _searchByHash(String hash) (líneas 56-86)
**Tipo de retorno**: `Future<void>`

**Parámetros**:
- `hash`: El código hash del calendario a buscar (sin el '#')

**Propósito**: Busca un calendario público por su código hash

**Lógica**:
1. Si ya está cargando (`_loadingHashSearch`), retorna inmediatamente
2. Activa estado de loading:
   - `_loadingHashSearch = true`
   - `_hashSearchError = null`
3. En bloque try-catch:
   - Obtiene el `calendarRepositoryProvider`
   - Llama a `repository.searchByShareHash(hash)` (async)
   - Si el widget está montado:
     - Si se encontró calendario: guarda en `_hashSearchResult`
     - Si NO se encontró: guarda mensaje de error en `_hashSearchError`
   - Desactiva `_loadingHashSearch`
4. En catch:
   - Si está montado: guarda mensaje de error genérico
   - Desactiva `_loadingHashSearch`

## 5. MÉTODOS DE ACCIÓN

### _subscribeToCalendar(Calendar calendar) (líneas 88-111)
**Tipo de retorno**: `Future<void>`

**Parámetros**:
- `calendar`: El calendario al que suscribirse

**Propósito**: Suscribe al usuario al calendario público encontrado

**Lógica**:
1. Si el calendario no tiene `shareHash`, retorna inmediatamente
2. En bloque try-catch:
   - Obtiene el `calendarRepositoryProvider`
   - Llama a `repository.subscribeByShareHash(shareHash)` (async)
   - Si está montado:
     - Muestra snackbar de éxito con mensaje "Suscrito a {nombre}"
     - Limpia el campo de búsqueda
     - Resetea estados: `_searchingByHash = false`, `_hashSearchResult = null`
     - Incluye comentario: Realtime actualizará automáticamente la lista
3. En catch:
   - Si está montado:
     - Parsea el error con `ErrorMessageParser.parse()`
     - Muestra snackbar de error

### _deleteOrLeaveCalendar(Calendar calendar) (líneas 113-123)
**Tipo de retorno**: `Future<void>`

**Parámetros**:
- `calendar`: El calendario a eliminar o abandonar

**Propósito**: Delega la eliminación o abandono del calendario a CalendarOperations

**Lógica**:
1. Imprime log de debug
2. Llama a `CalendarOperations.deleteOrLeaveCalendar()` con:
   - `calendar`: el calendario a procesar
   - `repository`: obtenido del provider
   - `context`: el contexto actual
   - `shouldNavigate`: false (no navega porque ya está en la lista)
   - `showSuccessMessage`: true
3. Incluye comentario: Realtime actualizará automáticamente la lista

## 6. MÉTODO BUILD PRINCIPAL

### build(BuildContext context, WidgetRef ref) (líneas 126-158)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la UI principal de la pantalla

**Lógica**:
1. Obtiene `l10n` del contexto
2. Detecta si es iOS con `PlatformDetection.isIOS`
3. Construye el body llamando a `_buildCalendarsView()`
4. Si es iOS:
   - Envuelve el body en un `Stack`
   - Añade un FAB posicionado (bottom: 100, right: 20) con:
     - `AdaptiveButton` con variant FAB
     - Icono de "add"
     - Navega a '/calendars/create'
5. Retorna `AdaptivePageScaffold` con:
   - `title`: null en iOS, "Calendars" en Android
   - `body`: el body construido (con o sin FAB)

## 7. MÉTODOS DE CONSTRUCCIÓN DE UI

### _buildCalendarsView() (líneas 160-173)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la vista principal con búsqueda y lista de calendarios

**Estructura**:
- Retorna `SafeArea` con `CustomScrollView` (física: ClampingScrollPhysics)
- Slivers:
  1. `SliverToBoxAdapter` con `_buildSearchBar()`
  2. Condicional:
     - Si `_searchingByHash`: spread de `_buildHashSearchResults()`
     - Si NO: spread de `_buildMyCalendarsList()`

### _buildSearchBar() (líneas 175-198)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la barra de búsqueda con hint para códigos hash

**Estructura**:
- Padding de 16px en todos los lados
- Column con:
  1. `CupertinoSearchTextField`:
     - Controller: `_searchController`
     - Placeholder: "Buscar por nombre o código"
     - onChanged: `_onSearchChanged`
  2. Si el texto empieza con '#':
     - Espaciador de 8px
     - Text con hint: "Introduce el código precedido de #"
     - Color gris, tamaño 12

### _buildHashSearchResults() (líneas 200-246)
**Tipo de retorno**: `List<Widget>`

**Propósito**: Construye los diferentes estados de la búsqueda por hash

**Estados manejados**:
1. **Loading** (`_loadingHashSearch` es true):
   - Retorna `SliverFillRemaining` con `CupertinoActivityIndicator` centrado

2. **Error** (`_hashSearchError` no es null):
   - Retorna `SliverFillRemaining` con `EmptyState`:
     - Icono: search
     - Mensaje: el error guardado

3. **Resultado encontrado** (`_hashSearchResult` no es null):
   - Retorna `SliverPadding` (horizontal 16px) con `SliverList`
   - Contiene `_buildHashResultCard(_hashSearchResult!)`

4. **Estado inicial** (ninguno de los anteriores):
   - Retorna `SliverFillRemaining` con `EmptyState`:
     - Icono: search
     - Mensaje: "Introduce el código precedido de #"

### _buildHashResultCard(Calendar calendar) (líneas 248-324)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `calendar`: El calendario encontrado a mostrar

**Propósito**: Construye una tarjeta con los detalles del calendario encontrado

**Estructura**:
- `Container` con:
  - Margin bottom de 16px
  - Padding de 16px
  - Fondo: systemBackground
  - Border radius: 12px
  - Border: systemGrey5

- Contenido (`Column`):
  1. **Header Row**:
     - Círculo azul de 48x48 (placeholder de imagen)
     - Espaciador de 12px
     - Column expandida con:
       - Nombre del calendario (tamaño 18, peso 600)
       - Si hay descripción: texto gris (tamaño 14)

  2. **Espaciador**: 16px

  3. **Contador de suscriptores Row**:
     - Icono de personas (tamaño 16, gris)
     - Espaciador de 4px
     - Text: "{cantidad} subscriber(s)" (tamaño 14, gris)

  4. **Espaciador**: 16px

  5. **Botón de suscripción**:
     - `CupertinoButton.filled` con ancho completo
     - Texto: "Suscribirse"
     - onPressed: llama a `_subscribeToCalendar(calendar)`

### _buildMyCalendarsList() (líneas 326-401)
**Tipo de retorno**: `List<Widget>`

**Propósito**: Construye la lista de calendarios propios y suscritos del usuario

**Lógica**:
1. Observa `calendarsStreamProvider` con `ref.watch`
2. Obtiene el texto de búsqueda (lowercase)
3. Usa `when()` para manejar el AsyncValue:

**Estado `data`** (líneas 331-382):
- Filtra calendarios por nombre si hay búsqueda activa
- **Si no hay calendarios** (lista original vacía):
  - Retorna `SliverFillRemaining` con `EmptyState`:
    - Icono: calendar
    - Mensaje: "No tienes calendarios aún"
    - Subtitle: "Busca por código"
    - Action button: "Crear calendario" → navega a '/calendars/create'

- **Si hay búsqueda pero no resultados**:
  - Retorna `SliverFillRemaining` con `EmptyState`:
    - Icono: search
    - Mensaje: "No se encontraron calendarios"

- **Si hay calendarios a mostrar**:
  - Retorna `SliverList` con `SliverChildBuilderDelegate`
  - Usa truco de índices: items impares son separadores, pares son calendarios
  - Cálculo: `childCount = filteredCalendars.length * 2 - 1`
  - Para índices impares: crea separador (línea 0.5px, margin left 72px)
  - Para índices pares: llama a `_buildCalendarItem()`

**Estado `loading`** (líneas 383-388):
- Retorna `SliverFillRemaining` con `CupertinoActivityIndicator` centrado

**Estado `error`** (líneas 389-399):
- Retorna `SliverFillRemaining` con `EmptyState`:
  - Icono: exclamationmark_triangle
  - Mensaje: el error convertido a string

### _buildCalendarItem(Calendar calendar) (líneas 403-460)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `calendar`: El calendario a mostrar

**Propósito**: Construye un item de lista para un calendario

**Lógica**:
1. Obtiene `l10n` del contexto
2. Verifica si es owner con `CalendarPermissions.isOwner()`
3. Retorna `CupertinoListTile` con:

**onTap** (líneas 408-416):
- Navega a `CalendarEventsScreen` con:
  - `calendarId`: int.parse(calendar.id)
  - `calendarName`: calendar.name

**leading** (líneas 418-430):
- Círculo azul de 40x40
- Icono blanco (tamaño 20):
  - Globo si es público
  - Candado si es privado

**title** (línea 431):
- Nombre del calendario

**subtitle** (líneas 432-449):
- Column con:
  - Si hay descripción: la muestra (1 línea max, ellipsis)
  - Etiqueta de rol:
    - "Propietario" si es owner
    - "Suscriptor" si tiene shareHash (calendario público suscrito)
    - "Miembro" en otros casos
  - Estilo: tamaño 12, gris

**trailing** (líneas 450-458):
- `CupertinoButton` con icono de basura roja
- onPressed: llama a `_deleteOrLeaveCalendar(calendar)`

## 8. DEPENDENCIAS

### Providers utilizados:
- `calendarsStreamProvider`: Stream de todos los calendarios del usuario (observado con watch)
- `calendarRepositoryProvider`: Repositorio de calendarios (leído con read)

### Utilities:
- `CalendarPermissions.isOwner()`: Verifica si el usuario es propietario del calendario
- `CalendarOperations.deleteOrLeaveCalendar()`: Maneja eliminación o abandono de calendario
- `ErrorMessageParser.parse()`: Parsea errores para mostrar mensajes legibles
- `PlatformDetection.isIOS`: Detecta si es plataforma iOS

### Widgets externos:
- `CupertinoSearchTextField`: Campo de búsqueda de iOS
- `CupertinoActivityIndicator`: Indicador de carga de iOS
- `CupertinoListTile`: Item de lista de iOS
- `CupertinoButton`: Botón de iOS
- `CupertinoButton.filled`: Botón filled de iOS
- `CupertinoPageRoute`: Transición de página de iOS
- `CustomScrollView`: Vista scrollable personalizada
- `SliverToBoxAdapter`: Adapta widget normal a sliver
- `SliverFillRemaining`: Sliver que llena el espacio restante
- `SliverList`: Lista perezosa en sliver
- `SliverPadding`: Padding en sliver
- `SliverChildBuilderDelegate`: Delegado para construir hijos
- `SliverChildListDelegate`: Delegado con lista fija de hijos

### Widgets internos:
- `AdaptivePageScaffold`: Scaffold adaptativo (iOS/Material)
- `EmptyState`: Widget para estados vacíos
- `AdaptiveButton`: Botón adaptativo
- `CalendarEventsScreen`: Pantalla de eventos de un calendario

### Navegación:
- `Navigator.of(context).push()`: Para navegar a CalendarEventsScreen
- `context.push()`: GoRouter para navegar a creación/edición

### Helpers:
- `PlatformDialogHelpers.showSnackBar()`: Muestra snackbars adaptativos

### Localización:
- `context.l10n`: Acceso a traducciones
- Strings usados: `calendars`, `searchByNameOrCode`, `enterCodePrecededByHash`, `calendarNotFoundByHash`, `error`, `subscribedTo`, `noCalendarsYet`, `noCalendarsSearchByCode`, `createCalendar`, `noCalendarsFound`, `subscriber`, `owner`, `member`, `subscribe`

## 9. FLUJO DE DATOS

### Flujo de búsqueda normal (por nombre):
1. Usuario escribe en `_searchController` (sin '#')
2. `_onSearchChanged()` detecta que no empieza con '#'
3. Desactiva `_searchingByHash`
4. `_buildCalendarsView()` renderiza `_buildMyCalendarsList()`
5. Los calendarios se filtran localmente por nombre

### Flujo de búsqueda por hash:
1. Usuario escribe '#' + código
2. `_onSearchChanged()` detecta el '#'
3. Activa `_searchingByHash = true`
4. Si el hash tiene 3+ caracteres, llama a `_searchByHash()`
5. `_searchByHash()` consulta el backend
6. Actualiza estados: `_loadingHashSearch`, `_hashSearchResult`, o `_hashSearchError`
7. `_buildHashSearchResults()` renderiza el estado correspondiente

### Flujo de suscripción:
1. Usuario encuentra calendario por hash
2. Presiona botón "Suscribirse"
3. `_subscribeToCalendar()` llama al repositorio
4. Muestra mensaje de éxito
5. Limpia búsqueda
6. Realtime actualiza automáticamente `calendarsStreamProvider`
7. El calendario aparece en la lista principal

### Flujo de eliminación:
1. Usuario presiona icono de basura en un calendario
2. Llama a `_deleteOrLeaveCalendar()`
3. CalendarOperations maneja la lógica (pide confirmación, elimina/abandona)
4. Realtime actualiza automáticamente `calendarsStreamProvider`
5. El calendario desaparece de la lista

## 10. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Listado de calendarios**: Muestra todos los calendarios del usuario (propios y suscritos)
2. **Búsqueda por nombre**: Filtra localmente los calendarios por nombre
3. **Búsqueda por código hash**: Busca calendarios públicos por código compartido
4. **Suscripción a calendarios**: Permite suscribirse a calendarios públicos encontrados
5. **Navegación a eventos**: Tap en calendario navega a sus eventos
6. **Eliminación/Abandono**: Permite eliminar calendarios propios o abandonar suscritos
7. **Creación de calendarios**: FAB (iOS) o botón de action (Android) para crear
8. **Estados vacíos**: Muestra mensajes apropiados para diferentes situaciones
9. **Indicadores de estado**: Muestra owner/subscriber/member para cada calendario
10. **Indicadores de privacidad**: Icono de globo o candado según privacidad

### Estados manejados:
- Lista de calendarios (con/sin datos)
- Loading de calendarios (desde provider)
- Error de calendarios (desde provider)
- Búsqueda por nombre (filtrado local)
- Búsqueda por hash (búsqueda remota)
- Loading de búsqueda por hash
- Resultado de búsqueda por hash (encontrado/no encontrado/error)
- Estado vacío (sin calendarios)
- Estado vacío (sin resultados de búsqueda)

### Roles/Permisos considerados:
- **Owner**: Puede eliminar el calendario
- **Subscriber** (de calendario público): Puede abandonar el calendario
- **Member** (de calendario privado): Puede abandonar el calendario
- Etiquetas visuales diferentes según el rol

## 11. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 462
**Métodos públicos**: 1 (build)
**Métodos privados**: 8
**Callbacks**: 2 (onChanged, async operations)

**Distribución aproximada**:
- Declaración de clase y propiedades: ~30 líneas (6.5%)
- Ciclo de vida: ~4 líneas (0.9%)
- Lógica de búsqueda: ~51 líneas (11.0%)
- Operaciones async (subscribe, delete): ~35 líneas (7.6%)
- Método build principal: ~33 líneas (7.1%)
- Construcción de vista principal: ~14 líneas (3.0%)
- Barra de búsqueda: ~24 líneas (5.2%)
- Resultados de búsqueda por hash: ~47 líneas (10.2%)
- Tarjeta de resultado hash: ~77 líneas (16.7%)
- Lista de calendarios: ~76 líneas (16.5%)
- Item de calendario: ~58 líneas (12.6%)
- Imports: ~16 líneas (3.5%)

## 12. CARACTERÍSTICAS TÉCNICAS

### Gestión de estado:
- Usa `setState()` para estado local (búsqueda, loading, resultados)
- Usa Riverpod providers para datos remotos (calendarios)
- Combina estado local y remoto eficientemente

### Optimización de lista:
- Usa `SliverList` para rendering perezoso
- Truco de índices para separadores (evita widgets innecesarios)
- Fórmula: `childCount = items * 2 - 1`

### Búsqueda dual:
- Búsqueda local: filtrado en memoria por nombre (rápido)
- Búsqueda remota: consulta API por hash (async)
- Detección automática según formato ('#' al inicio)

### Validación de búsqueda por hash:
- Requiere mínimo 3 caracteres después del '#'
- Previene búsquedas innecesarias
- Loading state durante la búsqueda

### Manejo de mounted:
- Verifica `mounted` antes de setState después de operaciones async
- Previene actualizaciones en widgets desmontados

### Realtime updates:
- No actualiza manualmente después de operaciones
- Confía en que Supabase Realtime actualiza los providers
- Código más limpio y menos propenso a inconsistencias
