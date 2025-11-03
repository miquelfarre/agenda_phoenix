# CalendarEventsScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/calendar_events_screen.dart`
**Líneas**: 264
**Tipo**: ConsumerStatefulWidget
**Propósito**: Pantalla que muestra todos los eventos de un calendario específico

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **EventListItem** (línea 237)
**Archivo**: `lib/widgets/event_list_item.dart`
**Documentación**: `lib/widgets_md/event_list_item.md`

**Uso en CalendarEventsScreen**:
```dart
EventListItem(
  event: event,
  onTap: _navigateToEventDetail,
  onDelete: _deleteEvent,
  showDate: true,
  showNewBadge: false,
)
```

**Ubicación**: Dentro de `_buildEventsList()` (línea 237), mapeado para cada evento
**Propósito**: Renderizar cada evento del calendario en la lista agrupada por fecha
**Configuración específica**:
- `showDate: true` - Muestra la fecha en cada evento (útil para vista de calendario completo)
- `showNewBadge: false` - No muestra badge NEW en esta vista

### 2.2. Resumen de Dependencias de Widgets

```
CalendarEventsScreen
└── CupertinoPageScaffold
    └── CustomScrollView
        ├── CupertinoSliverNavigationBar (título + search field)
        └── SliverList
            └── EventListItem (múltiples, por cada evento)
```

**Total de widgets propios**: 1 (EventListItem)
**Nota**: Esta pantalla es minimalista, usa principalmente widgets de Cupertino y solo un widget custom

---

## 3. CLASE Y PROPIEDADES

### CalendarEventsScreen (líneas 16-25)
Widget principal que extiende `ConsumerStatefulWidget`

**Propiedades**:
- `calendarId` (int, required): ID del calendario cuyos eventos se mostrarán
- `calendarName` (String, required): Nombre del calendario para mostrar en la UI
- `calendarColor` (String?, optional): Color del calendario en formato hex (#RRGGBB o #AARRGGBB)

### _CalendarEventsScreenState (líneas 27-263)
Estado del widget que gestiona la lógica de la pantalla

**Propiedades de instancia**:
- `_searchController` (TextEditingController): Controlador para el campo de búsqueda de eventos

## 3. CICLO DE VIDA

### initState() (líneas 31-34)
- Llama a `super.initState()`
- Añade un listener al `_searchController` que llama a `_filterEvents()` cuando cambia el texto

### dispose() (líneas 36-40)
- Limpia el `_searchController` llamando a su método `dispose()`
- Llama a `super.dispose()`

## 4. MÉTODOS DE FILTRADO

### _filterEvents() (líneas 42-44)
**Propósito**: Callback que se ejecuta cuando cambia el texto de búsqueda

**Lógica**:
- Verifica que el widget esté montado (`mounted`)
- Llama a `setState(() {})` para forzar un rebuild

### _applySearchFilter(List<Event> events) (líneas 46-53)
**Propósito**: Filtra la lista de eventos según la query de búsqueda

**Parámetros**:
- `events`: Lista de eventos a filtrar

**Retorna**: `List<Event>` filtrada

**Lógica**:
1. Obtiene el texto del `_searchController`, le hace trim y lo convierte a minúsculas
2. Si la query está vacía, retorna todos los eventos sin filtrar
3. Si hay query, filtra los eventos que:
   - Contienen la query en el título (case insensitive), O
   - Contienen la query en la descripción (case insensitive, si existe descripción)
4. Retorna la lista filtrada

## 5. GETTERS COMPUTADOS

### _calendar (líneas 55-71)
**Tipo de retorno**: `Calendar?`

**Propósito**: Obtiene el objeto Calendar completo desde el provider

**Lógica**:
1. Observa el `calendarsStreamProvider` con `ref.watch`
2. Usa `maybeWhen` para manejar el `AsyncValue`:
   - Si hay `data`: busca el calendario con `firstWhere` comparando el ID
   - Si no se encuentra: crea un Calendar dummy con los datos del widget
   - Si hay error o loading: retorna `null` con `orElse`

### _isOwner (líneas 73-77)
**Tipo de retorno**: `bool`

**Propósito**: Determina si el usuario actual es propietario del calendario

**Lógica**:
1. Obtiene el `_calendar` del getter
2. Si es null, retorna `false`
3. Usa `CalendarPermissions.isOwner(calendar)` para verificar propiedad

## 6. MÉTODOS DE UI

### _parseCalendarColor() (líneas 79-91)
**Tipo de retorno**: `Color`

**Propósito**: Convierte el string de color hex a objeto Color de Flutter

**Lógica**:
1. Si `calendarColor` es null, retorna `AppStyles.blue600` por defecto
2. En bloque try-catch:
   - Elimina el carácter '#' del string
   - Si el string tiene 6 caracteres (RGB), añade 'FF' al inicio para el alpha
   - Parsea el hex a int con radix 16
   - Crea y retorna el objeto Color
3. Si hay excepción, retorna `AppStyles.blue600` por defecto

## 7. MÉTODOS DE ACCIONES

### _showCalendarOptions() (líneas 93-136)
**Tipo de retorno**: `Future<void>`

**Propósito**: Muestra un action sheet con las opciones disponibles para el calendario

**Lógica**:
1. Obtiene el `l10n` del contexto
2. Obtiene el `_calendar` del getter, si es null retorna inmediatamente
3. Obtiene el `calendarRepository` del provider
4. Llama a `CalendarPermissions.canEdit()` (async) para verificar permisos
5. Construye lista de acciones:
   - Si `canEdit` es true: añade acción "Editar calendario" que navega a la ruta `/calendars/${calendarId}/edit`
   - Siempre añade acción destructiva: "Eliminar calendario" si es owner, o "Abandonar calendario" si no lo es
   - Esta acción llama a `_deleteOrLeaveCalendar(calendar)`
6. Muestra `CupertinoActionSheet` con:
   - Las acciones construidas
   - Botón de cancelar

### _deleteOrLeaveCalendar(Calendar calendar) (líneas 138-148)
**Tipo de retorno**: `Future<void>`

**Parámetros**:
- `calendar`: El calendario a eliminar o abandonar

**Propósito**: Delega la eliminación o abandono del calendario a CalendarOperations

**Lógica**:
1. Imprime log de debug
2. Llama a `CalendarOperations.deleteOrLeaveCalendar()` con:
   - `calendar`: el calendario a procesar
   - `repository`: el repositorio obtenido del provider
   - `context`: el contexto actual
   - `shouldNavigate`: true (para navegar de vuelta a la lista de calendarios)
   - `showSuccessMessage`: true (para mostrar mensaje de éxito)
3. Incluye comentario indicando que Realtime actualizará automáticamente la lista

### _deleteEvent(Event event, {bool shouldNavigate = false}) (líneas 252-262)
**Tipo de retorno**: `Future<void>`

**Parámetros**:
- `event`: El evento a eliminar
- `shouldNavigate`: Si debe navegar después de eliminar (default: false)

**Propósito**: Delega la eliminación del evento a EventOperations

**Lógica**:
1. Imprime log de debug
2. Llama a `EventOperations.deleteOrLeaveEvent()` con:
   - `event`: el evento a procesar
   - `repository`: el repositorio obtenido del provider
   - `context`: el contexto actual
   - `shouldNavigate`: el valor del parámetro
   - `showSuccessMessage`: true
3. Incluye comentario indicando que EventRepository maneja actualizaciones vía Realtime

## 8. MÉTODO BUILD

### build(BuildContext context, WidgetRef ref) (líneas 151-188)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la UI principal de la pantalla

**Lógica**:
1. Observa `eventsStreamProvider` con `ref.watch`
2. Extrae los eventos del `AsyncValue` usando `when`:
   - data: retorna los eventos
   - loading: retorna lista vacía
   - error: retorna lista vacía
3. Filtra `allEvents` para obtener solo los del calendario actual (comparando `calendarId`)
4. Ordena `calendarEvents` por `startDate` ascendente
5. Aplica filtro de búsqueda llamando a `_applySearchFilter()`
6. Obtiene el color del calendario llamando a `_parseCalendarColor()`
7. Retorna `CupertinoPageScaffold` con:
   - **NavigationBar**:
     - Fondo con color del sistema
     - Middle: Row con círculo de color del calendario + nombre del calendario
     - Trailing: Botón con icono ellipsis que llama a `_showCalendarOptions()`
   - **Child**: SafeArea con `_buildContent(eventsToShow)`

### _buildContent(List<Event> eventsToShow) (líneas 190-250)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `eventsToShow`: Lista de eventos filtrados a mostrar

**Propósito**: Construye el contenido scrollable de la pantalla

**Estructura**:
Retorna `CustomScrollView` con física `ClampingScrollPhysics` y los siguientes slivers:

1. **SliverToBoxAdapter** (líneas 194-199): Campo de búsqueda
   - Padding de 16px
   - `CupertinoSearchTextField` con el controller y placeholder

2. **SliverToBoxAdapter** (líneas 201-213): Contador de eventos
   - Padding horizontal de 16px
   - Text mostrando "{cantidad} evento(s)" con:
     - Singular si es 1 evento
     - Plural si son múltiples eventos
     - Color gris, tamaño 14, peso 500

3. **SliverToBoxAdapter** (línea 214): Espaciador de 8px

4. **Condicional** (líneas 216-229): Si NO hay eventos
   - `SliverFillRemaining` con `hasScrollBody: false`
   - Center con Column:
     - Icono de calendario (64px, gris)
     - Espaciador de 16px
     - Text: "No se encontraron eventos" si hay búsqueda activa, o "No hay eventos" si no hay búsqueda

5. **Condicional** (líneas 230-247): Si HAY eventos
   - `SliverList` con `SliverChildBuilderDelegate`
   - Para cada evento:
     - Padding simétrico (horizontal 16px, vertical 8px)
     - `EventListItem` con:
       - `event`: el evento actual
       - `onTap`: navega a `EventDetailScreen` con el evento
       - `onDelete`: callback `_deleteEvent`
       - `showDate`: true

## 9. DEPENDENCIAS

### Providers utilizados:
- `eventsStreamProvider`: Stream de todos los eventos (observado con watch)
- `calendarsStreamProvider`: Stream de todos los calendarios (observado con watch)
- `calendarRepositoryProvider`: Repositorio de calendarios (leído con read)
- `eventRepositoryProvider`: Repositorio de eventos (leído con read)

### Utilities:
- `CalendarPermissions.isOwner()`: Verifica si el usuario es propietario del calendario
- `CalendarPermissions.canEdit()`: Verifica si el usuario puede editar el calendario (owner o admin)
- `CalendarOperations.deleteOrLeaveCalendar()`: Maneja eliminación o abandono de calendario
- `EventOperations.deleteOrLeaveEvent()`: Maneja eliminación o abandono de evento

### Widgets externos:
- `CupertinoPageScaffold`: Scaffold de estilo iOS
- `CupertinoNavigationBar`: Barra de navegación de iOS
- `CupertinoButton`: Botón de estilo iOS
- `CupertinoSearchTextField`: Campo de búsqueda de iOS
- `CupertinoActionSheet`: Action sheet modal de iOS
- `CupertinoActionSheetAction`: Acción dentro del action sheet
- `CupertinoPageRoute`: Transición de página de iOS
- `CustomScrollView`: Vista scrollable personalizada
- `SliverToBoxAdapter`: Adapta un widget normal a sliver
- `SliverFillRemaining`: Sliver que llena el espacio restante
- `SliverList`: Lista perezosa en sliver
- `SliverChildBuilderDelegate`: Delegado para construir hijos de sliver

### Widgets internos:
- `EventListItem`: Widget personalizado para mostrar un item de evento
- `EventDetailScreen`: Pantalla de detalle de evento

### Navegación:
- `Navigator.of(context).push()`: Para navegar a EventDetailScreen
- `Navigator.pop(context)`: Para cerrar el action sheet
- `context.push()`: GoRouter para navegar a edición de calendario

### Estilos:
- `AppStyles.blue600`: Color azul por defecto
- `AppStyles.grey600`: Color gris para texto secundario
- `AppStyles.colorWithOpacity()`: (implícito en otros componentes)

### Localización:
- `context.l10n` o `AppLocalizations.of(context)!`: Acceso a traducciones
- Strings usados: `searchEvents`, `event`, `events`, `editCalendar`, `deleteCalendar`, `leaveCalendar`, `cancel`, `noEventsFound`, `noEvents`

## 10. FLUJO DE DATOS

1. **Entrada de datos**:
   - Parámetros del widget: `calendarId`, `calendarName`, `calendarColor`
   - Streams: `eventsStreamProvider`, `calendarsStreamProvider`

2. **Procesamiento**:
   - Los eventos se filtran por `calendarId`
   - Se ordenan por `startDate`
   - Se aplica filtro de búsqueda por texto
   - El color se parsea de hex a Color

3. **Salida a UI**:
   - Lista filtrada de eventos en `EventListItem`
   - Contador de eventos
   - Color del calendario en el navigation bar
   - Estado vacío si no hay eventos

4. **Interacciones del usuario**:
   - Búsqueda: actualiza `_searchController` → `_filterEvents()` → rebuild
   - Tap en evento: navega a `EventDetailScreen`
   - Tap en opciones: muestra `_showCalendarOptions()`
   - Delete evento: llama a `_deleteEvent()`
   - Delete/Leave calendario: llama a `_deleteOrLeaveCalendar()`

## 11. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Visualización de eventos**: Muestra todos los eventos de un calendario específico
2. **Búsqueda**: Permite buscar eventos por título o descripción
3. **Ordenación**: Los eventos se muestran ordenados por fecha de inicio
4. **Gestión de calendario**: Permite editar (si tiene permisos) o eliminar/abandonar el calendario
5. **Gestión de eventos**: Permite eliminar eventos individuales
6. **Estado vacío**: Muestra mensaje apropiado cuando no hay eventos
7. **Color personalizado**: Muestra el color del calendario en la UI

### Estados manejados:
- Lista de eventos (filtrada y ordenada)
- Query de búsqueda
- Loading de datos (implícito en AsyncValue)
- Error de datos (implícito en AsyncValue)
- Estado vacío (sin eventos)

### Permisos considerados:
- Owner del calendario: puede eliminar
- No owner: puede abandonar
- Admin o owner: puede editar
- Permisos de evento: manejados por `EventListItem`

## 12. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 264
**Métodos públicos**: 1 (build)
**Métodos privados**: 8
**Getters**: 2
**Callbacks**: 3

**Distribución aproximada**:
- Configuración y ciclo de vida: ~15 líneas (5.7%)
- Lógica de filtrado: ~12 líneas (4.5%)
- Getters computados: ~20 líneas (7.6%)
- Parsing de color: ~13 líneas (4.9%)
- Action sheet y opciones: ~44 líneas (16.7%)
- Método build principal: ~38 líneas (14.4%)
- Método _buildContent: ~61 líneas (23.1%)
- Callbacks de delete: ~21 líneas (8.0%)
- Imports y declaración: ~25 líneas (9.5%)
