# PublicUserEventsScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/public_user_events_screen.dart`
**Líneas**: 328
**Tipo**: ConsumerStatefulWidget
**Propósito**: Pantalla que muestra los eventos públicos de un usuario específico, permite suscribirse/desuscribirse del usuario y abandonar eventos individuales

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **EventListItem** (líneas 285-291)
**Archivo**: `lib/widgets/event_list_item.dart`
**Documentación**: `lib/widgets_md/event_list_item.md`

**Uso en PublicUserEventsScreen**:
```dart
EventListItem(
  event: event,
  onTap: (event) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => EventDetailScreen(event: event)
      )
    );
  },
  onDelete: _deleteEvent,
)
```

**Ubicación**: Dentro de `SliverList` (delegate builder), renderizado para cada evento
**Propósito**: Renderizar cada evento del usuario público en la lista
**Configuración específica**:
- `event`: Evento del usuario público
- `onTap`: Navega a EventDetailScreen
- `onDelete`: Llama a `_deleteEvent()` que SIEMPRE abandona el evento (nunca elimina)

**Nota importante**:
- Los eventos públicos solo pueden ser abandonados (LEFT), nunca eliminados
- El usuario nunca es owner/admin de eventos de otros usuarios

**Renderizado condicional**: Solo se muestra si `eventsToShow.isNotEmpty == true && !_isLoading && _error == null`

### 2.2. Resumen de Dependencias de Widgets

```
PublicUserEventsScreen
└── CupertinoPageScaffold
    ├── CupertinoNavigationBar
    │   ├── middle (texto con nombre del usuario)
    │   └── trailing (botón Seguir/Dejar de seguir)
    └── SafeArea
        └── _buildContent()
            ├── [loading] → CupertinoActivityIndicator
            ├── [error] → Column (mensaje + botón reintentar)
            └── [data] → CustomScrollView
                ├── SliverToBoxAdapter (campo de búsqueda)
                ├── SliverFillRemaining (estado vacío si no hay eventos)
                │   └── Icon + Text (mensaje vacío)
                └── SliverList (si hay eventos)
                    └── EventListItem (múltiples, uno por evento)
                        └── EventDetailScreen (navegación al tap)
```

**Total de widgets propios**: 1 (EventListItem)

**Funcionalidades especiales de la pantalla**:
- Botón de suscripción con flag `_isProcessingSubscription` para prevenir doble tap
- Detección de suscripción desde interacciones de eventos (no llamada API separada)
- Recarga automática después de suscribir/desuscribir
- Solo permite abandonar eventos, nunca eliminarlos

---

## 3. CLASE Y PROPIEDADES

### PublicUserEventsScreen (líneas 12-19)
Widget principal que extiende `ConsumerStatefulWidget`

**Propiedades**:
- `publicUser` (User, required): Usuario público cuyos eventos se mostrarán

### _PublicUserEventsScreenState (líneas 21-327)
Estado del widget que gestiona la lógica de la pantalla

**Propiedades de instancia**:
- `_searchController` (TextEditingController): Controlador para el campo de búsqueda
- `_isProcessingSubscription` (bool): Si está procesando suscripción/desuscripción (previene doble tap)
- `_hiddenEventIds` (Set<int>): Set de IDs de eventos ocultados localmente
- `_events` (List<Event>): Lista de eventos del usuario público
- `_isSubscribed` (bool): Si el usuario actual está suscrito a este usuario público
- `_isLoading` (bool): Si está cargando datos
- `_error` (String?): Mensaje de error si ocurrió alguno

## 3. CICLO DE VIDA

### initState() (líneas 33-37)
1. Llama a `super.initState()`
2. Añade listener al `_searchController` que llama a `_filterEvents()`
3. Llama a `_loadData()` para cargar eventos

### dispose() (líneas 40-43)
1. Limpia `_searchController.dispose()`
2. Llama a `super.dispose()`

## 4. MÉTODOS DE FILTRADO

### _filterEvents() (líneas 45-47)
**Tipo de retorno**: `void`

**Propósito**: Callback que se ejecuta cuando cambia el texto de búsqueda

**Lógica**:
- Verifica que esté montado
- Llama a `setState(() {})` para forzar rebuild

### _applySearchAndStatusFilters(List<Event> events) (líneas 192-201)
**Tipo de retorno**: `List<Event>`

**Parámetros**:
- `events`: Lista de eventos a filtrar

**Propósito**: Aplica filtro de búsqueda a los eventos

**Lógica**:
1. Obtiene query del controller (trim + lowercase)
2. Inicia con todos los eventos
3. Si hay query no vacía:
   - Filtra eventos donde:
     - Título contiene la query, O
     - Descripción contiene la query (si existe)
4. Retorna lista filtrada

## 5. MÉTODOS DE CARGA DE DATOS

### _loadData() (líneas 49-105)
**Tipo de retorno**: `Future<void>`

**Propósito**: Carga los eventos del usuario público y determina estado de suscripción

**Lógica con logs detallados**:
1. **Prints iniciales** (líneas 50-51): Logs de inicio con estado actual
2. **Validación** (líneas 53-56):
   - Si ya está cargando Y NO está procesando suscripción:
     - Imprime log de advertencia
     - Retorna (previene carga duplicada)
3. **Activar loading** (líneas 58-62):
   - Imprime log
   - `setState()`: `_isLoading = true`, `_error = null`
4. **En bloque try-catch**:
   - **Fetch eventos** (líneas 65-68):
     - Imprime log con userId
     - Llama a `ApiClient().fetchUserEvents(userId)`
     - Parsea eventos con `Event.fromJson()`
     - Imprime cantidad de eventos obtenidos
   - **Determinar suscripción** (líneas 71-84):
     - Inicializa `isSubscribed = false`
     - Imprime log "Checking subscription status"
     - **Para cada eventData**:
       - Si tiene `interaction` no null:
         - Extrae interaction como Map
         - Imprime tipo de interacción
         - Si `interaction_type == 'subscribed'`:
           - `isSubscribed = true`
           - Imprime "User IS subscribed"
           - Break (sale del loop)
     - Imprime estado final de suscripción
   - **Actualizar estado** (líneas 86-94):
     - Si está montado:
       - Imprime log
       - `setState()`: actualiza `_events`, `_isSubscribed`, `_isLoading = false`
       - Imprime confirmación con valores actualizados
5. **En catch** (líneas 95-103):
   - Imprime error con ❌
   - Si está montado:
     - `setState()`: `_error = e.toString()`, `_isLoading = false`
6. **Print final** (línea 104): Log de fin

**Nota importante**: El estado de suscripción se determina buscando interacciones tipo 'subscribed' en los eventos, NO haciendo llamada separada a API

### _refreshEvents() (líneas 107-110)
**Tipo de retorno**: `Future<void>`

**Propósito**: Recarga los eventos limpiando la lista de ocultos

**Lógica**:
1. Limpia `_hiddenEventIds` con `.clear()`
2. Llama a `_loadData()`

## 6. MÉTODOS DE SUSCRIPCIÓN

### _subscribeToUser() (líneas 112-150)
**Tipo de retorno**: `Future<void>`

**Propósito**: Suscribe al usuario actual a este usuario público

**Lógica con logs detallados**:
1. **Print inicial** (línea 113): Log con 🟢 y userId
2. **Validación** (líneas 114-117):
   - Si ya está procesando: imprime advertencia y retorna
3. **Activar flag** (líneas 119-120):
   - Imprime log
   - `setState()`: `_isProcessingSubscription = true`
4. **En bloque try-catch-finally**:
   - **Try** (líneas 122-138):
     - Imprime log de llamada a API
     - Llama a `ApiClient().post('/users/{userId}/subscribe')`
     - Imprime éxito con ✅
     - Si está montado:
       - Imprime log
       - Muestra snackbar "Suscrito correctamente"
     - Imprime "Realtime handles subscriptions automatically"
     - Incluye comentario: Realtime maneja refresh via SubscriptionRepository
     - Imprime "Reloading local data..."
     - Llama a `_loadData()` para actualizar estado de suscripción
     - Imprime "Local data reloaded"
   - **Catch** (líneas 139-144):
     - Imprime error con ❌ y stack trace
     - Si está montado: muestra snackbar de error
   - **Finally** (líneas 145-147):
     - Imprime log
     - Si está montado: `setState()`: `_isProcessingSubscription = false`
5. **Print final** (línea 149): Log de fin

### _unsubscribeFromUser() (líneas 152-190)
**Tipo de retorno**: `Future<void>`

**Propósito**: Desuscribe al usuario actual de este usuario público

**Lógica con logs detallados** (similar a _subscribeToUser):
1. **Print inicial** (línea 153): Log con 🔴 y userId
2. **Validación** (líneas 154-157): Si ya está procesando, retorna
3. **Activar flag** (líneas 159-160): `_isProcessingSubscription = true`
4. **En bloque try-catch-finally**:
   - **Try** (líneas 162-178):
     - Imprime log
     - Llama a `ApiClient().delete('/users/{userId}/subscribe')`
     - Imprime éxito
     - Muestra snackbar "Desuscrito correctamente"
     - Recarga datos con `_loadData()`
   - **Catch** (líneas 179-184): Maneja error con logs y snackbar
   - **Finally** (líneas 185-187): Desactiva flag
5. **Print final** (línea 189): Log de fin

**Nota**: Ambos métodos usan el mismo endpoint `/users/{userId}/subscribe` con diferentes verbos HTTP (POST vs DELETE)

## 7. MÉTODO BUILD

### build(BuildContext context, WidgetRef ref) (líneas 204-228)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la UI principal de la pantalla

**Lógica**:
1. **Print de debug** (línea 205): Log del build con estados
2. Retorna `CupertinoPageScaffold` con:
   - **NavigationBar** (líneas 207-225):
     - **middle** (línea 208):
       - Text: "Eventos - {nombre del usuario}"
       - Usa fullName, sino instagramName, sino 'User'
       - Tamaño 16
     - **trailing** (líneas 209-223): Botón Follow/Unfollow
       - Padding: horizontal 8, vertical 4
       - **onPressed**:
         - Si está procesando: null (botón deshabilitado)
         - Si está suscrito:
           - Imprime log "UNFOLLOW button pressed"
           - Llama a `_unsubscribeFromUser()`
         - Si NO está suscrito:
           - Imprime log "FOLLOW button pressed"
           - Llama a `_subscribeToUser()`
       - **child**: Text con "Dejar de seguir" o "Seguir" según `_isSubscribed`
     - backgroundColor: systemBackground
   - **child**: SafeArea con `_buildContent()`

### _buildContent() (líneas 230-297)
**Tipo de retorno**: `Widget`

**Propósito**: Construye el contenido de la pantalla según el estado

**Lógica**:
1. **Si está loading** (líneas 231-233):
   - Retorna Center con `CupertinoActivityIndicator`

2. **Si hay error** (líneas 235-246):
   - Retorna Center con Column:
     - Text: "Error al cargar eventos" (rojo, tamaño 16)
     - Espaciador 16px
     - Botón "Reintentar" que llama a `_refreshEvents()`

3. **Si hay datos** (líneas 248-296):
   - **Filtra eventos** (línea 250):
     - Elimina eventos ocultos: `where e.id no está en _hiddenEventIds`
   - **Aplica filtros** (línea 252):
     - Llama a `_applySearchAndStatusFilters()`
   - **Retorna CustomScrollView** con:
     - **SliverToBoxAdapter** (líneas 257-262): Campo de búsqueda
       - Padding 16px
       - `CupertinoSearchTextField` con controller y placeholder
     - **Condicional**:
       - **Si no hay eventos** (líneas 264-277):
         - `SliverFillRemaining` con estado vacío:
           - Icono calendario (64px, gris)
           - Espaciador 16px
           - Text:
             - "No se encontraron eventos" si hay búsqueda
             - "Sin eventos" si no hay búsqueda
       - **Si hay eventos** (líneas 278-294):
         - `SliverList` con builder:
           - Para cada evento: Padding + `EventListItem`
           - onTap: navega a `EventDetailScreen`
           - onDelete: llama a `_deleteEvent`

## 8. MÉTODO DE ELIMINACIÓN

### _deleteEvent(Event event, {bool shouldNavigate = false}) (líneas 299-326)
**Tipo de retorno**: `Future<void>`

**Parámetros**:
- `event`: Evento a abandonar
- `shouldNavigate`: Si debe navegar después (default: false, no se usa)

**Propósito**: Abandona un evento del usuario público (nunca elimina, solo abandona)

**Lógica con logs detallados**:
1. **Print inicial** (línea 300): Log con 👋 y detalles del evento
2. **En bloque try-catch**:
   - **Validación** (líneas 302-305):
     - Si event.id es null:
       - Imprime error
       - Lanza excepción
   - **Incluye comentario importante** (líneas 307-308):
     - "Public user events can only be LEFT, never DELETED"
     - "(user is never owner/admin of public user events)"
   - **Abandona evento** (líneas 309-311):
     - Imprime log "LEAVING public user event"
     - Llama a `eventRepositoryProvider.leaveEvent(eventId)`
     - Imprime éxito con ✅
   - **Actualiza lista local** (líneas 314-318):
     - Si está montado:
       - `setState()`: elimina evento con `removeWhere`
   - **Print final** (línea 320): Log de operación completada
3. **En catch** (líneas 321-325):
   - Imprime error y stack trace
   - Relaniza excepción (rethrow)

## 9. DEPENDENCIAS

### Providers utilizados:
- `eventRepositoryProvider`: Repositorio de eventos (read)

### Services:
- `ApiClient().fetchUserEvents()`: Carga eventos de usuario
- `ApiClient().post()`: Suscribe a usuario
- `ApiClient().delete()`: Desuscribe de usuario

### Widgets externos:
- `CupertinoPageScaffold`: Scaffold de iOS
- `CupertinoNavigationBar`: Barra de navegación
- `CupertinoButton`: Botón de iOS
- `CupertinoActivityIndicator`: Indicador de carga
- `CupertinoSearchTextField`: Campo de búsqueda
- `CupertinoPageRoute`: Transición de página
- `CustomScrollView`: Vista scrollable
- `SliverToBoxAdapter`: Adapta widget a sliver
- `SliverFillRemaining`: Llena espacio restante
- `SliverList`: Lista perezosa
- `SliverChildBuilderDelegate`: Builder de hijos

### Widgets internos:
- `EventListItem`: Item de evento
- `EventDetailScreen`: Pantalla de detalle

### Helpers:
- `PlatformDialogHelpers.showSnackBar()`: Muestra snackbars

### Navegación:
- `Navigator.of(context).push()`: Para navegar

### Localización:
- `AppLocalizations.of(context)!`: Acceso a traducciones
- Strings usados: `events`, `unfollow`, `follow`, `errorLoadingEvents`, `retry`, `searchEvents`, `noEventsFound`, `noEvents`, `subscribedSuccessfully`, `unsubscribedSuccessfully`

### Models:
- `User`: Modelo de usuario
- `Event`: Modelo de evento

## 10. FLUJO DE DATOS

### Al abrir la pantalla:
1. `initState()` se ejecuta
2. Configura listener de búsqueda
3. Llama a `_loadData()`
4. Fetch eventos desde API
5. Determina suscripción desde interacciones
6. Actualiza estado con eventos y suscripción
7. Renderiza lista de eventos

### Al suscribirse:
1. Usuario presiona botón "Seguir"
2. `_subscribeToUser()` se ejecuta
3. Activa flag `_isProcessingSubscription`
4. Botón se deshabilita (previene doble tap)
5. POST a `/users/{userId}/subscribe`
6. Muestra snackbar de éxito
7. Recarga datos con `_loadData()` para actualizar UI local
8. Realtime actualiza `subscriptionsStream` automáticamente
9. Desactiva flag
10. Botón muestra "Dejar de seguir"

### Al desuscribirse:
1. Usuario presiona botón "Dejar de seguir"
2. `_unsubscribeFromUser()` se ejecuta
3. Similar al flujo de suscribirse pero con DELETE
4. Botón muestra "Seguir" de nuevo

### Al buscar:
1. Usuario escribe en campo de búsqueda
2. Listener se ejecuta
3. `_filterEvents()` llama a `setState()`
4. `_applySearchAndStatusFilters()` filtra eventos
5. Lista se actualiza

### Al abandonar evento:
1. Usuario presiona botón de eliminar en `EventListItem`
2. `_deleteEvent()` se ejecuta
3. Llama a `eventRepository.leaveEvent()`
4. Elimina evento de lista local con `removeWhere`
5. UI se actualiza sin el evento

## 11. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Ver eventos públicos**: Muestra eventos de un usuario público específico
2. **Suscribirse/Desuscribirse**: Toggle para seguir/dejar de seguir al usuario
3. **Búsqueda**: Filtra eventos por título o descripción
4. **Ver detalle**: Tap en evento navega a detalle
5. **Abandonar eventos**: Permite dejar eventos individuales
6. **Refresh**: Recarga eventos con botón de reintentar
7. **Estado de suscripción**: Muestra botón apropiado según suscripción

### Estados manejados:
- Loading (cargando eventos)
- Error (con opción de reintentar)
- Data (lista de eventos)
  - Lista vacía (estado vacío)
  - Lista con eventos (filtrada o completa)
- Procesando suscripción (botón deshabilitado)
- Suscrito/No suscrito (texto del botón)

### Prevención de doble tap:
- Flag `_isProcessingSubscription`
- Deshabilita botón mientras procesa
- Previene múltiples llamadas simultáneas

### Detección de suscripción:
- NO hace llamada separada a API
- Busca en las interacciones de los eventos
- Si encuentra interaction_type='subscribed': está suscrito
- Método eficiente que reutiliza datos ya cargados

### Logs exhaustivos:
- Emojis para identificar secciones:
  - 📊: Carga de datos
  - 🟢: Suscripción
  - 🔴: Desuscripción
  - 👋: Abandonar evento
  - ✅: Éxito
  - ❌: Error
  - ⚠️: Advertencia
  - 🔘: Interacción de botón
  - 🎨: Build
- Útil para debugging en producción

## 12. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 328
**Métodos públicos**: 2 (build, dispose)
**Métodos privados**: 8

**Distribución aproximada**:
- Imports: ~11 líneas (3.4%)
- Declaración de clase y propiedades: ~19 líneas (5.8%)
- Ciclo de vida: ~13 líneas (4.0%)
- Filtrado: ~13 líneas (4.0%)
- Carga de datos: ~63 líneas (19.2%)
- Suscripción: ~39 líneas (11.9%)
- Desuscripción: ~39 líneas (11.9%)
- build method: ~25 líneas (7.6%)
- _buildContent method: ~68 líneas (20.7%)
- _deleteEvent method: ~28 líneas (8.5%)
- Resto: ~10 líneas (3.0%)

## 13. CARACTERÍSTICAS TÉCNICAS

### Flag de procesamiento:
- `_isProcessingSubscription` previene doble tap
- Se activa antes de operación async
- Se desactiva en finally (siempre se ejecuta)
- Deshabilita botón (onPressed: null)

### Recarga después de suscribir:
- Llama a `_loadData()` después de suscribir/desuscribir
- Actualiza estado local inmediatamente
- No espera a Realtime para refrescar UI
- Mejor UX con feedback instantáneo

### Validación en carga:
- Si ya está cargando Y NO está procesando suscripción: retorna
- Permite recarga durante procesamiento de suscripción
- Previene cargas duplicadas innecesarias

### Hidden events set:
- Mantiene `_hiddenEventIds` para ocultar eventos localmente
- Se limpia en `_refreshEvents()`
- Patrón para UI optimista (ocultar antes de confirmar)

### Lista local actualizada:
- Después de abandonar evento: `removeWhere` de lista local
- No espera a recarga completa
- UI se actualiza inmediatamente

### Solo LEAVE, nunca DELETE:
- Comentario explícito en código
- Usuario nunca es owner de eventos públicos de otros
- Solo puede abandonar, no eliminar

### Endpoints de bulk subscribe:
- Comentarios mencionan "new bulk subscribe endpoint"
- POST `/users/{userId}/subscribe`: suscribe a todos los eventos del usuario
- DELETE `/users/{userId}/subscribe`: desuscribe de todos los eventos
- Más eficiente que suscribir evento por evento

### Print statements extensivos:
- Más de 40 print statements
- Útiles para debugging
- Incluyen emojis para identificación visual
- Muestran flujo completo de operaciones
- Stack traces en errores

### Mounted checks:
- Verifica `mounted` antes de setState después de async
- Previene errores si widget fue desmontado

### AsyncValue implícito:
- NO usa AsyncValue de Riverpod
- Gestiona loading/error/data con variables de estado propias
- Más control manual pero más código

### Filtrado en dos pasos:
1. Filtra eventos ocultos: `where id not in _hiddenEventIds`
2. Aplica filtros de búsqueda: `_applySearchAndStatusFilters()`
- Separación clara de responsabilidades
