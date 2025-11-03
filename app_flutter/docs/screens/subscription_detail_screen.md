# SubscriptionDetailScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/subscription_detail_screen.dart`
**Líneas**: 135
**Tipo**: ConsumerStatefulWidget
**Propósito**: Pantalla que muestra los eventos públicos de un usuario al que el usuario actual está suscrito

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **AdaptivePageScaffold** (línea 72)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_page_scaffold.md`

**Uso en SubscriptionDetailScreen**:
```dart
AdaptivePageScaffold(
  title: title,
  body: SafeArea(child: _buildBody()),
)
```

**Ubicación**: Widget raíz retornado por `build()`
**Propósito**: Proporciona scaffold adaptativo (iOS/Material) para la pantalla
**Configuración específica**:
- `title`: Nombre del usuario suscrito con cascada de fallbacks (displayName → fullName → instagramName → unknownUser)
- `body`: Envuelve `_buildBody()` en SafeArea

#### **EmptyState** (línea 106)
**Archivo**: `lib/widgets/empty_state.dart`
**Documentación**: `lib/widgets_md/empty_state.md`

**Uso en SubscriptionDetailScreen**:
```dart
EmptyState(
  message: l10n.noEvents,
  icon: CupertinoIcons.calendar
)
```

**Ubicación**: Dentro de `_buildBody()` cuando `_events.isEmpty` es true
**Propósito**: Mostrar estado vacío cuando el usuario suscrito no tiene eventos públicos
**Configuración específica**:
- `message`: "No hay eventos" (traducido)
- `icon`: Icono de calendario

**Renderizado condicional**: Solo se muestra si `_events.isEmpty == true && !_isLoading && _error == null`

#### **EventsList** (líneas 109-114)
**Archivo**: `lib/widgets/events_list.dart`
**Documentación**: `lib/widgets_md/events_list.md`

**Uso en SubscriptionDetailScreen**:
```dart
EventsList(
  events: _events,
  onEventTap: _openEventDetail,
  onDelete: (Event event, {bool shouldNavigate = false}) async {},
  navigateAfterDelete: false,
)
```

**Ubicación**: Dentro de `_buildBody()` cuando hay eventos
**Propósito**: Renderizar lista de eventos del usuario suscrito agrupados por fecha
**Configuración específica**:
- `events`: Lista de eventos cargados desde el backend
- `onEventTap`: Llama a `_openEventDetail()` que navega al detalle y recarga datos al volver
- `onDelete`: Callback vacío (no permite eliminar eventos de otros usuarios)
- `navigateAfterDelete`: false

**Renderizado condicional**: Solo se muestra si `_events.isNotEmpty && !_isLoading && _error == null`

**Nota importante**: Esta pantalla no permite eliminar eventos porque el usuario no es propietario

### 2.2. Resumen de Dependencias de Widgets

```
SubscriptionDetailScreen
└── AdaptivePageScaffold
    └── SafeArea
        └── _buildBody()
            ├── [loading] → PlatformWidgets.platformLoadingIndicator
            ├── [error] → Column (icono + mensaje de error)
            ├── [empty] → EmptyState
            └── [data] → EventsList
                └── EventDetailScreen (navegación al tap)
```

**Total de widgets propios**: 3 (AdaptivePageScaffold, EmptyState, EventsList)

**Flujo especial al volver del detalle**:
1. Usuario toca evento → navega a EventDetailScreen
2. Al volver → recarga datos con `_loadData()`
3. Si `_events.isEmpty` después de recargar → cierra pantalla automáticamente con `Navigator.pop()`

---

## 3. CLASE Y PROPIEDADES

### SubscriptionDetailScreen (líneas 15-22)
Widget principal que extiende `ConsumerStatefulWidget`

**Propiedades**:
- `subscription` (Subscription, required): La suscripción que contiene información del usuario suscrito

**Constructor**:
```dart
const SubscriptionDetailScreen({super.key, required this.subscription})
```

### _SubscriptionDetailScreenState (líneas 24-134)
Estado del widget que extiende `ConsumerState<SubscriptionDetailScreen>`

**Variables de estado**:
- `_events` (List<Event>, línea 25): Lista de eventos del usuario suscrito, inicializada como lista vacía
- `_isLoading` (bool, línea 26): Indica si se están cargando los datos, inicializada en false
- `_error` (String?, línea 27): Mensaje de error si la carga falla, inicializada en null

## 3. CICLO DE VIDA

### initState() (líneas 29-33)
**Tipo de retorno**: `void`

**Propósito**: Inicializa el estado del widget y carga los datos al montar la pantalla

**Lógica**:
1. Llama a `super.initState()`
2. Llama a `_loadData()` para cargar los eventos

**Momento de ejecución**: Se ejecuta una sola vez cuando el widget se monta

## 4. MÉTODOS PRINCIPALES

### Future<void> _loadData() (líneas 35-65)
**Tipo de retorno**: `Future<void>`
**Es async**: Sí

**Propósito**: Carga los eventos del usuario suscrito desde el backend

**Lógica detallada**:
1. **Log inicial** (línea 36):
   - Imprime "🔵 [SubscriptionDetailScreen] _loadData START"

2. **Actualiza estado a loading** (líneas 37-40):
   - Llama a `setState()`
   - Establece `_isLoading = true`
   - Establece `_error = null`

3. **Bloque try** (líneas 42-55):
   - **Log de inicio de petición** (línea 43):
     - Imprime "🔵 [SubscriptionDetailScreen] Calling Backend API for user events..."

   - **Obtiene ID del usuario suscrito** (línea 44):
     - `publicUserId = widget.subscription.subscribedToId`

   - **Llama al API** (línea 45):
     - Llama a `ApiClient().fetchUserEvents(publicUserId)`
     - Obtiene datos raw del backend

   - **Convierte datos a objetos Event** (línea 46):
     - Mapea cada elemento con `Event.fromJson(e)`
     - Convierte a lista con `.toList()`

   - **Log de resultado** (línea 47):
     - Imprime "🔵 [SubscriptionDetailScreen] Backend API completed, events count: ${events.length}"

   - **Actualiza estado si montado** (líneas 49-54):
     - Verifica `mounted` antes de setState
     - Establece `_events = events`
     - Establece `_isLoading = false`
     - Imprime log de confirmación

4. **Bloque catch** (líneas 56-64):
   - **Log de error** (línea 57):
     - Imprime "🔴 [SubscriptionDetailScreen] ERROR: $e"

   - **Actualiza estado de error si montado** (líneas 58-63):
     - Verifica `mounted` antes de setState
     - Establece `_error = e.toString()`
     - Establece `_isLoading = false`

**Casos manejados**:
- Carga exitosa: actualiza _events con los eventos obtenidos
- Error en la petición: guarda el mensaje de error en _error
- Widget desmontado: verifica mounted antes de cada setState

### Widget build(BuildContext context, WidgetRef ref) (líneas 67-76)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `context`: BuildContext para acceso al contexto
- `ref`: WidgetRef para acceso a providers (no utilizado en este caso)

**Propósito**: Construye la UI principal de la pantalla con el scaffold y título

**Lógica detallada**:
1. **Obtiene localizaciones** (línea 69):
   - Usa `context.l10n` para acceder a traducciones

2. **Construye título dinámico** (línea 70):
   - Prioridad 1: `subscription.subscribed?.displayName` si no está vacío
   - Prioridad 2: `subscription.subscribed?.fullName`
   - Prioridad 3: `subscription.subscribed?.instagramName`
   - Prioridad 4: `l10n.unknownUser` como fallback

3. **Retorna AdaptivePageScaffold** (líneas 72-75):
   - Parámetro `title`: el título calculado
   - Parámetro `body`: envuelve `_buildBody()` en SafeArea

**Lógica del título**: Cascada de fallbacks para asegurar que siempre hay un título visible

### Widget _buildBody() (líneas 78-115)
**Tipo de retorno**: `Widget`

**Propósito**: Construye el contenido principal de la pantalla según el estado actual

**Lógica detallada**:
1. **Obtiene localizaciones** (línea 79):
   - Usa `context.l10n`

2. **Estado: Cargando** (líneas 81-83):
   - Condición: `_isLoading == true`
   - Retorna: `Center` con `PlatformWidgets.platformLoadingIndicator(radius: 16)`
   - Muestra spinner de carga centrado

3. **Estado: Error** (líneas 85-103):
   - Condición: `_error != null`
   - Retorna: `Center` con Column que contiene:
     - Padding de 16px en todos los lados
     - Column con `mainAxisSize: MainAxisSize.min`:
       - **Icono de error** (línea 92):
         - `CupertinoIcons.exclamationmark_triangle`
         - Color: `AppStyles.grey500`
         - Tamaño: 48
       - **Espaciador**: 12px
       - **Mensaje de error** (líneas 94-98):
         - Text con `_error!.replaceFirst('Exception: ', '')`
         - TextAlign: center
         - Estilo: color gris700

4. **Estado: Sin eventos** (líneas 105-107):
   - Condición: `_events.isEmpty`
   - Retorna: `EmptyState` con:
     - message: `l10n.noEvents`
     - icon: `CupertinoIcons.calendar`

5. **Estado: Con eventos** (líneas 109-115):
   - Condición: tiene eventos en `_events`
   - Retorna: `EventsList` con:
     - `events`: `_events` (lista de eventos)
     - `onEventTap`: `_openEventDetail` (callback)
     - `onDelete`: callback vacío `(Event event, {bool shouldNavigate = false}) async {}` (no permite borrar)
     - `navigateAfterDelete`: false

**Estados manejados**: loading, error, empty, data

### void _openEventDetail(Event event) (líneas 117-133)
**Tipo de retorno**: `void`
**Es async**: Sí (implícitamente por await)

**Parámetros**:
- `event` (Event): El evento que se va a mostrar en detalle

**Propósito**: Navega a la pantalla de detalle del evento y recarga los datos al volver. Si no quedan eventos, cierra la pantalla actual

**Lógica detallada**:
1. **Verificación inicial** (línea 118):
   - Si `!mounted`, retorna inmediatamente (previene errores)

2. **Navegación al detalle** (línea 120):
   - Usa `Navigator.of(context).push()`
   - Crea ruta con `PlatformNavigation.platformPageRoute()`
   - Builder crea `EventDetailScreen(event: event)`
   - Usa `await` para esperar a que el usuario vuelva

3. **Verificación después de navegación** (línea 122):
   - Si `!mounted`, retorna (el widget pudo desmontarse mientras navegaba)

4. **Recarga de datos** (línea 124):
   - Llama a `await _loadData()` para actualizar la lista de eventos
   - Espera a que termine la recarga

5. **Verificación después de recarga** (línea 126):
   - Si `!mounted`, retorna

6. **Cierre automático si no hay eventos** (líneas 128-132):
   - Condición: `_events.isEmpty`
   - Si está montado y puede hacer pop:
     - Llama a `Navigator.of(context).pop()`
     - Cierra la pantalla actual

**Razón del cierre automático**: Si el usuario eliminó o ocultó todos los eventos del usuario suscrito, no tiene sentido mantener la pantalla vacía abierta

**Verificaciones mounted**: 4 verificaciones para prevenir errores de estado

## 5. DEPENDENCIAS

### Packages externos:
- `flutter/cupertino.dart`: Widgets de estilo iOS
- `flutter_riverpod`: Estado con Riverpod (ConsumerStatefulWidget, ConsumerState, WidgetRef)

### Imports internos - Helpers:
- `eventypop/ui/helpers/l10n/l10n_helpers.dart`: Extensión para localizaciones
- `eventypop/ui/helpers/platform/platform_widgets.dart`: Widgets adaptativos (platformLoadingIndicator, platformIcon)
- `eventypop/ui/helpers/platform/platform_navigation.dart`: Navegación adaptativa (platformPageRoute)
- `eventypop/ui/styles/app_styles.dart`: Estilos de la aplicación (colores)

### Imports internos - Models:
- `../models/subscription.dart`: Modelo `Subscription` con información del usuario suscrito
- `../models/event.dart`: Modelo `Event`

### Imports internos - Services:
- `../services/api_client.dart`: Cliente API para llamadas al backend
  - Usa: `ApiClient().fetchUserEvents(publicUserId)`

### Imports internos - Widgets:
- `../widgets/adaptive_scaffold.dart`: `AdaptivePageScaffold` para scaffold adaptativo
- `../widgets/empty_state.dart`: `EmptyState` para estado vacío
- `../widgets/events_list.dart`: `EventsList` para mostrar lista de eventos

### Imports internos - Screens:
- `event_detail_screen.dart`: `EventDetailScreen` para navegación

### Datos de Subscription utilizados:
- `subscription.subscribedToId`: ID del usuario público suscrito
- `subscription.subscribed?.displayName`: Nombre para mostrar
- `subscription.subscribed?.fullName`: Nombre completo
- `subscription.subscribed?.instagramName`: Nombre de Instagram

### Métodos de ApiClient:
- `fetchUserEvents(publicUserId)`: Obtiene eventos de un usuario público

### Localización:
Strings usados:
- `unknownUser`: "Usuario desconocido" (fallback para título)
- `noEvents`: "No hay eventos" (mensaje de estado vacío)

## 6. FLUJO DE DATOS

### Al abrir la pantalla:
1. Usuario navega desde SubscriptionsScreen pasando `Subscription`
2. Constructor recibe la suscripción
3. `initState()` se ejecuta
4. Llama a `_loadData()`
5. Establece `_isLoading = true`
6. Llama a `ApiClient().fetchUserEvents(subscription.subscribedToId)`
7. Backend retorna lista de eventos del usuario suscrito
8. Convierte JSON a objetos `Event`
9. Establece `_events` con los eventos
10. Establece `_isLoading = false`
11. UI reconstruye mostrando `EventsList`

### Al tocar un evento:
1. Usuario toca evento en `EventsList`
2. Callback `onEventTap` se ejecuta con el evento
3. Llama a `_openEventDetail(event)`
4. Verifica `mounted`
5. Navega a `EventDetailScreen(event: event)`
6. Usuario interactúa con el evento (puede ver, ocultar, etc.)
7. Usuario vuelve (pop)
8. Verifica `mounted`
9. Llama a `_loadData()` para recargar eventos
10. Obtiene nueva lista de eventos del backend
11. Actualiza `_events`
12. Si `_events.isEmpty`:
    - Verifica `mounted` y `canPop()`
    - Hace `pop()` para cerrar la pantalla
13. Si tiene eventos:
    - UI reconstruye mostrando lista actualizada

### Flujo de error:
1. Durante `_loadData()`, si `ApiClient().fetchUserEvents()` lanza excepción
2. Catch captura el error
3. Imprime log con 🔴
4. Establece `_error = e.toString()`
5. Establece `_isLoading = false`
6. UI reconstruye mostrando mensaje de error con icono de triángulo

### Flujo de estado vacío:
1. Si backend retorna lista vacía de eventos
2. `_events = []`
3. `_isLoading = false`
4. `_buildBody()` detecta `_events.isEmpty`
5. Muestra `EmptyState` con icono de calendario

## 7. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Visualización de eventos**: Muestra todos los eventos del usuario suscrito
2. **Navegación a detalle**: Permite abrir cada evento para ver más información
3. **Recarga automática**: Recarga los eventos al volver del detalle
4. **Cierre automático**: Cierra la pantalla si no quedan eventos después de volver del detalle
5. **Estados visuales**: Maneja loading, error, vacío y datos

### Características de UI:
1. **Título dinámico**: Muestra el nombre del usuario suscrito con cascada de fallbacks
2. **Indicador de carga**: Spinner centrado mientras carga datos
3. **Mensaje de error**: Icono de triángulo con mensaje descriptivo
4. **Estado vacío**: Usa `EmptyState` con mensaje traducido e icono de calendario
5. **Lista de eventos**: Usa `EventsList` para mostrar eventos de forma consistente

### Interacciones disponibles:
1. **Tocar evento**: Navega a detalle del evento
2. **Volver**: Cierra la pantalla y vuelve a SubscriptionsScreen

### Restricciones:
1. **No permite eliminar eventos**: `onDelete` callback está vacío, el usuario no puede eliminar eventos de otros usuarios
2. **Solo lectura**: La pantalla es de solo lectura, no permite ediciones

## 8. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 135
**Métodos**: 4 (1 initState + 1 loadData + 1 build + 1 buildBody + 1 openEventDetail)
**Tipo**: ConsumerStatefulWidget con estado local

**Distribución aproximada**:
- Imports: ~13 líneas (9.6%)
- Declaración de clase ConsumerStatefulWidget: ~8 líneas (5.9%)
- Variables de estado: ~3 líneas (2.2%)
- initState method: ~5 líneas (3.7%)
- _loadData method: ~31 líneas (23.0%)
- build method: ~10 líneas (7.4%)
- _buildBody method: ~38 líneas (28.1%)
- _openEventDetail method: ~17 líneas (12.6%)
- Resto (espacios, llaves): ~10 líneas (7.4%)

**Complejidad por método**:
- `_loadData()`: Complejidad media (maneja async, try-catch, mounted checks)
- `build()`: Complejidad baja (solo construye título y scaffold)
- `_buildBody()`: Complejidad media (maneja 4 estados diferentes)
- `_openEventDetail()`: Complejidad media (maneja navegación, recarga y cierre condicional)

## 9. CARACTERÍSTICAS TÉCNICAS

### ConsumerStatefulWidget:
- Usa `ConsumerStatefulWidget` para tener acceso a Riverpod y estado local
- El `WidgetRef ref` está disponible en `build()` pero no se usa en esta pantalla
- Estado local (`_events`, `_isLoading`, `_error`) se maneja con `setState()`

### Gestión de estado local:
- **_events**: Lista mutable que almacena los eventos cargados
- **_isLoading**: Booleano para controlar el indicador de carga
- **_error**: String nullable para almacenar mensajes de error

### Llamadas al API:
- Usa `ApiClient().fetchUserEvents(publicUserId)` para obtener eventos
- Retorna `Future<List<dynamic>>` con datos JSON
- Convierte cada elemento con `Event.fromJson(e)`

### Logging extensivo:
- Usa emojis para distinguir tipos de logs:
  - 🔵: Logs de flujo normal y éxito
  - 🔴: Logs de error
- Prefijo: `[SubscriptionDetailScreen]` para filtrar logs
- Logs en puntos clave: inicio, llamada API, resultado, error

### Mounted checks:
- Verifica `mounted` antes de cada `setState()` (2 veces en _loadData)
- Verifica `mounted` 4 veces en `_openEventDetail()`:
  1. Antes de navegar
  2. Después de navegar
  3. Después de recargar
  4. Antes de hacer pop
- Previene errores de llamar setState en widget desmontado

### Navegación con PlatformNavigation:
- Usa `PlatformNavigation.platformPageRoute()` para rutas adaptativas
- Soporta navegación en iOS (CupertinoPageRoute) y Android (MaterialPageRoute)

### Recarga al volver:
- Siempre recarga datos después de volver del detalle con `await _loadData()`
- Asegura que la lista esté actualizada después de interacciones
- Ejemplo: si el usuario ocultó un evento en el detalle, desaparece de la lista

### Cierre automático inteligente:
- Si después de recargar `_events.isEmpty`, cierra la pantalla automáticamente
- Verifica `mounted && Navigator.of(context).canPop()` antes de hacer pop
- Previene que el usuario vea una pantalla vacía sin contenido útil

### Gestión de errores:
- Try-catch en `_loadData()` captura cualquier excepción
- Muestra mensaje de error limpio con `.replaceFirst('Exception: ', '')`
- Remove el prefijo "Exception: " para mejor UX

### Callback vacío para onDelete:
- `onDelete: (Event event, {bool shouldNavigate = false}) async {}`
- `EventsList` espera este callback pero no se ejecuta nada
- El usuario no puede eliminar eventos de otros usuarios desde esta pantalla

### Título con fallbacks en cascada:
- 4 niveles de fallback para asegurar que siempre hay un título
- Orden: displayName → fullName → instagramName → unknownUser
- Usa operador `?.` para navegación segura con nullables
- Verifica `isNotEmpty` para displayName para evitar títulos en blanco

### Manejo de estados en _buildBody:
- Orden de verificación: loading → error → empty → data
- Early returns para cada estado
- Solo muestra `EventsList` cuando hay datos
- Arquitectura clara de if-else sin anidamiento profundo

### SafeArea:
- Envuelve `_buildBody()` en `SafeArea` para evitar overlays del sistema
- Asegura que el contenido no quede debajo de status bar o notch

### EventsList reutilizable:
- Usa widget compartido `EventsList` para consistencia
- Configuración:
  - `events`: lista de eventos a mostrar
  - `onEventTap`: callback al tocar evento
  - `onDelete`: callback vacío (no permite borrar)
  - `navigateAfterDelete`: false (no navega después de borrar)

### EmptyState reutilizable:
- Usa widget compartido `EmptyState` para estado vacío consistente
- Recibe mensaje traducido e icono personalizable
- Mantiene UX consistente en toda la app

### PlatformWidgets adaptativos:
- `platformLoadingIndicator()`: Spinner adaptado a la plataforma
- `platformIcon()`: Icono adaptado con color y tamaño
- Asegura look & feel nativo en iOS y Android
