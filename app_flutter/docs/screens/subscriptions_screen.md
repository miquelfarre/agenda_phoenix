# SubscriptionsScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/subscriptions_screen.dart`
**Líneas**: 194
**Tipo**: ConsumerStatefulWidget with WidgetsBindingObserver
**Propósito**: Pantalla que muestra la lista de usuarios públicos a los que el usuario actual está suscrito, con funcionalidad de búsqueda y eliminación de suscripciones

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **AdaptivePageScaffold** (línea 130)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_page_scaffold.md`

**Uso en SubscriptionsScreen**:
```dart
AdaptivePageScaffold(
  key: const Key('subscriptions_screen_scaffold'),
  title: PlatformWidgets.isIOS ? null : l10n.subscriptions,
  actions: [
    if (kDebugMode)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CupertinoButton(
          key: const Key('subscriptions_refresh_button'),
          padding: const EdgeInsets.all(8),
          onPressed: () {
            ref.read(subscriptionRepositoryProvider).refresh();
          },
          child: PlatformWidgets.platformIcon(
            CupertinoIcons.refresh, size: 20
          ),
        ),
      ),
  ],
  body: SafeArea(...)
)
```

**Ubicación**: Widget raíz retornado por `build()`
**Propósito**: Proporciona scaffold adaptativo (iOS/Material) para la pantalla
**Configuración específica**:
- `key`: 'subscriptions_screen_scaffold' (para testing)
- `title`: null en iOS (usa tab bar), "Suscripciones" en Android
- `actions`: Botón de refresh solo en modo debug
- `body`: Maneja estados de loading, data y error con `subscriptionsAsync.when()`

#### **SubscriptionCard** (línea 95)
**Archivo**: `lib/widgets/subscription_card.dart`
**Documentación**: `lib/widgets_md/subscription_card.md`

**Uso en SubscriptionsScreen**:
```dart
SubscriptionCard(
  user: user,
  onTap: () => _showUserDetails(user),
  onDelete: () => _removeUser(user, ref)
)
```

**Ubicación**: Dentro de `SliverList` (delegate builder), renderizado para cada usuario
**Propósito**: Renderizar tarjeta de suscripción con información del usuario y acciones
**Configuración específica**:
- `user`: Usuario de la suscripción
- `onTap`: Navega a `PublicUserEventsScreen` para ver eventos del usuario
- `onDelete`: Llama a `_removeUser()` para cancelar suscripción

**Renderizado condicional**: Solo se muestra si `filteredUsers.isNotEmpty == true`

#### **EmptyState** (línea 75)
**Archivo**: `lib/widgets/empty_state.dart`
**Documentación**: `lib/widgets_md/empty_state.md`

**Uso en SubscriptionsScreen**:
```dart
EmptyState(
  message: l10n.noSubscriptions,
  icon: isIOS
    ? CupertinoIcons.person_2
    : CupertinoIcons.person_2
)
```

**Ubicación**: Dentro de `SliverFillRemaining` cuando `users.isEmpty` es true
**Propósito**: Mostrar estado vacío cuando no hay suscripciones (o no hay resultados de búsqueda)
**Configuración específica**:
- `message`: "Sin suscripciones" (traducido)
- `icon`: CupertinoIcons.person_2 (mismo en iOS y Android)

**Renderizado condicional**:
- Se muestra si `filteredUsers.isEmpty == true`
- Puede indicar: sin suscripciones inicialmente, o búsqueda sin resultados

### 2.2. Resumen de Dependencias de Widgets

```
SubscriptionsScreen
└── AdaptivePageScaffold
    ├── actions (botón refresh en debug mode)
    └── SafeArea
        └── subscriptionsAsync.when()
            ├── loading → CupertinoActivityIndicator
            ├── error → Column (mensaje + botón retry)
            └── data → CustomScrollView
                ├── SliverToBoxAdapter (campo de búsqueda)
                ├── SliverFillRemaining (si no hay usuarios)
                │   └── EmptyState
                └── SliverList (si hay usuarios)
                    └── SubscriptionCard (múltiples, uno por usuario)
                        └── PublicUserEventsScreen (navegación al tap)
```

**Total de widgets propios**: 3 (AdaptivePageScaffold, SubscriptionCard, EmptyState)

---

## 3. CLASE Y PROPIEDADES

### SubscriptionsScreen (líneas 17-21)
Widget principal que extiende `ConsumerStatefulWidget`

**Propiedades**: Ninguna (constructor solo con key)

### _SubscriptionsScreenState (líneas 23-193)
Estado del widget que gestiona la lógica de la pantalla. Implementa `WidgetsBindingObserver` para detectar cambios en el ciclo de vida de la app

**Propiedades de instancia**:
- `_searchController` (TextEditingController): Controlador para el campo de búsqueda
- `_searchQuery` (String): Query de búsqueda actual (actualizada al cambiar el controller)

## 3. CICLO DE VIDA

### initState() (líneas 28-39)
1. Llama a `super.initState()`
2. Registra el observer: `WidgetsBinding.instance.addObserver(this)`
3. Añade listener al `_searchController` que:
   - Verifica que el widget esté montado
   - Actualiza `_searchQuery` con el texto del controller
   - Llama a `setState()` para rebuild

### dispose() (líneas 100-104)
1. Remueve el observer: `WidgetsBinding.instance.removeObserver(this)`
2. Limpia `_searchController.dispose()`
3. Llama a `super.dispose()`

### didChangeAppLifecycleState(AppLifecycleState state) (líneas 107-113)
**Propósito**: Callback que se ejecuta cuando cambia el estado del ciclo de vida de la app

**Lógica**:
- Si el estado es `resumed` y el widget está montado:
  - Llama a `subscriptionRepositoryProvider.refresh()` para recargar suscripciones
  - Útil para actualizar datos cuando el usuario vuelve a la app

## 4. MÉTODO BUILD PRINCIPAL

### build(BuildContext context, WidgetRef ref) (líneas 124-177)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la UI principal de la pantalla

**Lógica**:
1. Línea 125: `Navigator.of(context);` - línea sin uso aparente (posible código legacy)
2. Obtiene `isIOS` de PlatformWidgets
3. Obtiene `l10n` del contexto
4. Observa `subscriptionsStreamProvider` con `ref.watch`
5. Retorna `AdaptivePageScaffold` con:
   - key: 'subscriptions_screen_scaffold'
   - title: null en iOS, "Suscripciones" en Android
   - **actions**: Array con:
     - Si está en modo debug (`kDebugMode`):
       - Botón de refresh con key 'subscriptions_refresh_button'
       - Icono: CupertinoIcons.refresh
       - onPressed: llama a `subscriptionRepositoryProvider.refresh()`
   - **body**: SafeArea con `subscriptionsAsync.when()`:
     - **data** (líneas 149-157): Lista de usuarios
       - Filtra usuarios según `_searchQuery`:
         - Si query vacía: retorna todos
         - Si hay query: filtra por nombre completo O nombre de Instagram (case insensitive)
       - Retorna `_buildScrollableContent()` con usuarios filtrados
     - **loading** (línea 158): Center con `CupertinoActivityIndicator`
     - **error** (líneas 159-173): Center con Column:
       - Text con mensaje de error
       - Espaciador de 16px
       - Botón "Reintentar" que llama a `subscriptionRepositoryProvider.refresh()`

## 5. MÉTODOS DE CONSTRUCCIÓN DE UI

### _buildSearchField(bool isIOS) (líneas 41-64)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `isIOS`: Si la plataforma es iOS (actualmente no se usa en el método)

**Propósito**: Construye el campo de búsqueda

**Estructura**:
- Padding de 16px en todos los lados
- `PlatformWidgets.platformTextField` con:
  - controller: `_searchController`
  - placeholder: "Buscar suscripciones"
  - prefixIcon: Icono de búsqueda (gris)
  - suffixIcon: Si hay texto en el controller:
    - Botón con key 'subscriptions_search_clear_button'
    - Icono: clear_circled_solid (gris, tamaño 18)
    - onPressed: limpia el controller y la query

### _buildScrollableContent(List<User> users, bool isIOS, AppLocalizations l10n, WidgetRef ref) (líneas 66-90)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `users`: Lista de usuarios (ya filtrados) a mostrar
- `isIOS`: Si la plataforma es iOS
- `l10n`: Localizaciones
- `ref`: Widget ref para acceder a providers

**Propósito**: Construye el contenido scrollable con lista de suscripciones

**Estructura**:
- SafeArea con CustomScrollView (física: ClampingScrollPhysics)
- Slivers:
  1. `SliverToBoxAdapter` con el campo de búsqueda
  2. Condicional:
     - **Si no hay usuarios** (líneas 72-76):
       - `SliverFillRemaining` con `EmptyState`:
         - Mensaje: "Sin suscripciones"
         - Icono: person_2
     - **Si hay usuarios** (líneas 77-86):
       - `SliverList` con `SliverChildBuilderDelegate`:
         - Para cada usuario: llama a `_buildUserItem()`
         - childCount: cantidad de usuarios

### _buildUserItem(User user, bool isIOS, AppLocalizations l10n, WidgetRef ref) (líneas 92-97)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `user`: Usuario a mostrar
- `isIOS`: Si la plataforma es iOS (actualmente no se usa)
- `l10n`: Localizaciones (actualmente no se usa)
- `ref`: Widget ref (actualmente no se usa)

**Propósito**: Construye el item de lista para un usuario

**Estructura**:
- Padding simétrico (horizontal 16px, vertical 4px)
- `SubscriptionCard` con:
  - user: el usuario
  - onTap: callback que llama a `_showUserDetails(user)`
  - onDelete: callback que llama a `_removeUser(user, ref)`

## 6. MÉTODOS DE ACCIÓN

### _showUserDetails(User user) (líneas 179-181)
**Tipo de retorno**: `void`

**Parámetros**:
- `user`: Usuario cuyos detalles se mostrarán

**Propósito**: Navega a la pantalla de eventos del usuario público

**Lógica**:
- Navega con `CupertinoPageRoute` a `PublicUserEventsScreen(publicUser: user)`

### _removeUser(User user, WidgetRef ref) (líneas 183-192)
**Tipo de retorno**: `Future<void>`

**Parámetros**:
- `user`: Usuario del que se cancelará la suscripción
- `ref`: Widget ref para acceder a providers

**Propósito**: Elimina la suscripción al usuario

**Lógica**:
1. En try-catch:
2. Llama a `subscriptionRepositoryProvider.deleteSubscription(targetUserId: user.id)`
3. Si exitoso: muestra mensaje de éxito "Te has desuscrito correctamente"
4. En catch:
   - Parsea el error con `ErrorMessageParser.parse(e, context)`
   - Muestra mensaje de error con `_showErrorMessage()`

## 7. MÉTODOS DE NOTIFICACIÓN

### _showSuccessMessage(String message) (líneas 115-117)
**Tipo de retorno**: `void`

**Parámetros**:
- `message`: Mensaje de éxito a mostrar

**Propósito**: Muestra snackbar de éxito

**Lógica**:
- Llama a `PlatformDialogHelpers.showSnackBar()` con el mensaje

### _showErrorMessage(String message) (líneas 119-121)
**Tipo de retorno**: `void`

**Parámetros**:
- `message`: Mensaje de error a mostrar

**Propósito**: Muestra snackbar de error

**Lógica**:
- Llama a `PlatformDialogHelpers.showSnackBar()` con `isError: true`

## 8. DEPENDENCIAS

### Providers utilizados:
- `subscriptionsStreamProvider`: Stream de suscripciones (observado con watch)
- `subscriptionRepositoryProvider`: Repositorio de suscripciones (leído con read)

### Utilities:
- `ErrorMessageParser.parse()`: Parsea errores para mostrar mensajes legibles
- `PlatformWidgets`: Widgets adaptativos y helpers de plataforma

### Widgets externos:
- `CupertinoActivityIndicator`: Indicador de carga de iOS
- `CupertinoButton`: Botón de iOS
- `CupertinoPageRoute`: Transición de página de iOS
- `CustomScrollView`: Vista scrollable personalizada
- `SliverToBoxAdapter`: Adapta widget normal a sliver
- `SliverFillRemaining`: Sliver que llena el espacio restante
- `SliverList`: Lista perezosa en sliver
- `SliverChildBuilderDelegate`: Delegado para construir hijos de sliver

### Widgets internos:
- `AdaptivePageScaffold`: Scaffold adaptativo (iOS/Material)
- `SubscriptionCard`: Tarjeta de suscripción personalizada
- `EmptyState`: Widget para estados vacíos
- `PublicUserEventsScreen`: Pantalla de eventos públicos de un usuario

### Helpers:
- `PlatformDialogHelpers.showSnackBar()`: Muestra snackbars adaptativos
- `context.l10n`: Acceso a localizaciones

### Models:
- `User`: Modelo de usuario

### Otros:
- `kDebugMode`: Flag de Flutter para modo debug

## 9. FLUJO DE DATOS

### Al abrir la pantalla:
1. `initState()` se ejecuta
2. Registra observer de ciclo de vida
3. Configura listener del search controller
4. `build()` observa `subscriptionsStreamProvider`
5. Stream emite lista de usuarios
6. Renderiza lista (sin filtros inicialmente)

### Al buscar:
1. Usuario escribe en campo de búsqueda
2. Listener del controller se ejecuta
3. Actualiza `_searchQuery` con `setState()`
4. `build()` se ejecuta de nuevo
5. Filtra usuarios por nombre o Instagram
6. Renderiza lista filtrada

### Al eliminar suscripción:
1. Usuario presiona botón de eliminar en `SubscriptionCard`
2. `_removeUser()` llama a repositorio
3. Si exitoso:
   - Muestra mensaje de éxito
   - Stream se actualiza automáticamente
   - UI se actualiza con nueva lista (sin el usuario eliminado)
4. Si falla:
   - Muestra mensaje de error
   - Lista no cambia

### Al volver a la app:
1. `didChangeAppLifecycleState()` detecta `resumed`
2. Llama a `subscriptionRepositoryProvider.refresh()`
3. Recarga datos desde API
4. Stream emite nueva lista
5. UI se actualiza

### Al presionar refresh (modo debug):
1. Usuario presiona botón de refresh
2. Llama a `subscriptionRepositoryProvider.refresh()`
3. Similar al flujo de "volver a la app"

## 10. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Listado de suscripciones**: Muestra todos los usuarios a los que está suscrito
2. **Búsqueda**: Filtra usuarios por nombre completo o nombre de Instagram
3. **Ver eventos**: Tap en usuario navega a sus eventos públicos
4. **Cancelar suscripción**: Permite desuscribirse de un usuario
5. **Refresh manual**: Botón de refresh en modo debug
6. **Refresh automático**: Al volver a la app
7. **Estado vacío**: Muestra mensaje si no hay suscripciones
8. **Estado de error**: Permite reintentar si falla la carga

### Estados manejados:
- Loading (cargando suscripciones)
- Data (lista de usuarios)
  - Lista vacía (estado vacío)
  - Lista con datos (filtrada o completa)
- Error (con opción de reintentar)
- Query de búsqueda (vacía o con texto)

### Búsqueda:
- **Campos buscados**: fullName, instagramName
- **Case insensitive**: Convierte query y campos a lowercase
- **Filtrado local**: No hace llamadas a API, filtra en memoria
- **Búsqueda en tiempo real**: Se actualiza mientras se escribe
- **Botón de limpiar**: Aparece cuando hay texto

## 11. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 194
**Métodos públicos**: 2 (build, didChangeAppLifecycleState)
**Métodos privados**: 6

**Distribución aproximada**:
- Imports: ~16 líneas (8.2%)
- Declaración de clase y propiedades: ~7 líneas (3.6%)
- Ciclo de vida: ~25 líneas (12.9%)
- Método build principal: ~54 líneas (27.8%)
- Construcción de UI: ~55 líneas (28.4%)
- Métodos de acción: ~13 líneas (6.7%)
- Métodos de notificación: ~7 líneas (3.6%)
- Resto: ~17 líneas (8.8%)

## 12. CARACTERÍSTICAS TÉCNICAS

### Observador de ciclo de vida:
- Implementa `WidgetsBindingObserver`
- Detecta cuando la app vuelve a primer plano
- Recarga suscripciones automáticamente al resumir

### Búsqueda reactiva:
- Listener en el controller actualiza query al escribir
- Filtrado en el método `build()` en cada rebuild
- No usa debouncing (filtrado instantáneo en memoria)

### Botón de refresh condicional:
- Solo visible en modo debug (`kDebugMode`)
- Útil para testing sin necesitar cambiar de app

### Filtrado local eficiente:
- Usa `where()` para filtrar en memoria
- No hace llamadas a API por cada búsqueda
- Performance O(n) donde n es cantidad de suscripciones

### Keys para testing:
- 'subscriptions_screen_scaffold': Scaffold principal
- 'subscriptions_search_clear_button': Botón de limpiar búsqueda
- 'subscriptions_refresh_button': Botón de refresh (debug)

### Parsing de errores:
- Usa `ErrorMessageParser.parse()` para mensajes legibles
- Pasa contexto para internacionalización

### Arquitectura con Riverpod:
- Stream provider para datos en tiempo real
- Repository provider para operaciones
- No mantiene estado local de suscripciones (confía en provider)

### Sliver performance:
- Usa `SliverList` con builder delegate
- Renderizado perezoso (solo items visibles)
- Buena performance con muchas suscripciones

### Línea curiosa:
- Línea 125: `Navigator.of(context);` no tiene efecto
- Posiblemente código legacy o comentado que quedó
