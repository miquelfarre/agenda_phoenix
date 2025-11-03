# PeopleGroupsScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/people_groups_screen.dart`
**Líneas**: 391
**Tipo**: ConsumerStatefulWidget with WidgetsBindingObserver
**Propósito**: Pantalla con dos tabs (Contactos y Grupos) que muestra los contactos del usuario y los grupos a los que pertenece

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **AdaptivePageScaffold** (línea 315)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_page_scaffold.md`

**Uso en PeopleGroupsScreen**:
```dart
AdaptivePageScaffold(
  key: const Key('people_groups_screen_scaffold'),
  title: l10n.peopleAndGroups,
  floatingActionButton: _tabIndex == 1
    ? CupertinoButton.filled(
        key: const Key('people_groups_create_group_fab'),
        onPressed: _navigateToCreateGroup,
        child: Icon(CupertinoIcons.plus, color: AppStyles.white),
      )
    : null,
  body: Column(...)
)
```

**Ubicación**: Widget raíz retornado por `build()`
**Propósito**: Proporciona scaffold adaptativo para la pantalla con tabs
**Configuración específica**:
- `key`: 'people_groups_screen_scaffold' (para testing)
- `title`: "Personas y grupos" (traducido)
- `floatingActionButton`: FAB condicional solo visible en tab de grupos (_tabIndex == 1)
- `body`: Column con selector de tabs + PageView

#### **ContactCard** (líneas 229-234)
**Archivo**: `lib/widgets/contact_card.dart`
**Documentación**: `lib/widgets_md/contact_card.md`

**Uso en PeopleGroupsScreen**:
```dart
ContactCard(
  contact: contact,
  onTap: () {
    context.go('/people/contacts/${contact.id}', extra: contact);
  },
)
```

**Ubicación**: Dentro de `ListView.builder` en tab de contactos, renderizado para cada contacto
**Propósito**: Renderizar tarjeta de contacto con información y navegación al detalle
**Configuración específica**:
- `contact`: Contacto a mostrar
- `onTap`: Navega a `/people/contacts/{id}` con GoRouter, pasando contact como extra

**Renderizado condicional**: Solo se muestra en tab de contactos (_tabIndex == 0) y si hay contactos

#### **EmptyState** (línea 248)
**Archivo**: `lib/widgets/empty_state.dart`
**Documentación**: `lib/widgets_md/empty_state.md`

**Uso en PeopleGroupsScreen**:
```dart
EmptyState(
  message: l10n.noGroupsMessage,
  icon: CupertinoIcons.group
)
```

**Ubicación**: Dentro de `_buildGroupsTab()` cuando `userGroups.isEmpty` es true
**Propósito**: Mostrar estado vacío cuando el usuario no pertenece a ningún grupo
**Configuración específica**:
- `message`: "No tienes grupos" (traducido)
- `icon`: CupertinoIcons.group

**Renderizado condicional**: Solo se muestra en tab de grupos si `userGroups.isEmpty == true`

#### **AdaptiveButton** (líneas 138-151)
**Archivo**: `lib/widgets/adaptive/adaptive_button.dart`
**Documentación**: `lib/widgets_md/adaptive_button.md`

**Uso en PeopleGroupsScreen**:
```dart
AdaptiveButton(
  key: const Key('people_groups_grant_permission_button'),
  config: AdaptiveButtonConfigExtended.submit(),
  text: l10n.allowAccess,
  icon: CupertinoIcons.person_2,
  onPressed: () async {
    final hasPermission = await Permission.contacts.request().isGranted;
    if (hasPermission) {
      await _loadContacts();
    } else {
      await openAppSettings();
    }
  },
)
```

**Ubicación**: Dentro de `_buildContactsError()` cuando es error de permisos
**Propósito**: Botón para solicitar permiso de acceso a contactos del dispositivo
**Configuración específica**:
- `key`: 'people_groups_grant_permission_button' (para testing)
- `config`: AdaptiveButtonConfigExtended.submit() (estilo de botón de submit)
- `text`: "Permitir acceso" (traducido)
- `icon`: person_2
- `onPressed`: Solicita permiso, si se concede recarga contactos, si no abre ajustes

**Renderizado condicional**: Solo se muestra si `_contactsError` contiene 'permission'

### 2.2. Resumen de Dependencias de Widgets

```
PeopleGroupsScreen
└── AdaptivePageScaffold
    ├── floatingActionButton (FAB de crear grupo, solo en tab grupos)
    └── Column
        ├── Container (selector de tabs personalizado)
        │   ├── GestureDetector (tab Contactos)
        │   └── GestureDetector (tab Grupos)
        └── PageView
            ├── _buildContactsTab()
            │   ├── [loading] → CupertinoActivityIndicator
            │   ├── [error] → Column
            │   │   └── AdaptiveButton (si error de permisos)
            │   └── [data] → ListView.builder
            │       └── ContactCard (múltiples, uno por contacto)
            └── _buildGroupsTab()
                ├── [loading] → CupertinoActivityIndicator
                ├── [error] → Column (mensaje + botón reintentar)
                └── [data] → EmptyState o ListView.builder
                    └── Container (tarjeta de grupo)
```

**Total de widgets propios**: 4 (AdaptivePageScaffold, ContactCard, EmptyState, AdaptiveButton)

**Características especiales**:
- Arquitectura de tabs con PageView (swipe entre tabs)
- Selector de tabs personalizado (no usa TabBar nativo)
- FAB condicional solo en tab de grupos
- Gestión de permisos de contactos con plugin permission_handler
- Carga híbrida: contactos desde API (no Realtime), grupos desde Stream Provider

---

## 3. CLASE Y PROPIEDADES

### PeopleGroupsScreen (líneas 20-24)
Widget principal que extiende `ConsumerStatefulWidget`

**Propiedades**: Ninguna (constructor solo con key)

### _PeopleGroupsScreenState (líneas 26-390)
Estado del widget que gestiona la lógica de la pantalla. Implementa `WidgetsBindingObserver` para detectar cambios en el ciclo de vida de la app

**Propiedades de instancia**:
- `_pageController` (PageController, late): Controlador para el PageView que maneja las tabs
- `_tabIndex` (int): Índice de la tab actual (0: contactos, 1: grupos)
- `searchController` (TextEditingController): Controlador para el campo de búsqueda de contactos
- `_contacts` (List<User>): Lista de contactos cargados desde la API
- `_isLoadingContacts` (bool): Si está cargando contactos
- `_contactsError` (String?): Mensaje de error si falla la carga de contactos

**Getters**:
- `userId` (int): ID del usuario actual desde ConfigService

## 3. CICLO DE VIDA

### initState() (líneas 37-43)
1. Llama a `super.initState()`
2. Registra el observer: `WidgetsBinding.instance.addObserver(this)`
3. Inicializa `_pageController` con página inicial 0
4. Llama a `_checkContactsPermission()` para verificar permisos
5. Llama a `_loadContacts()` para cargar contactos

### dispose() (líneas 46-51)
1. Remueve el observer: `WidgetsBinding.instance.removeObserver(this)`
2. Limpia `_pageController.dispose()`
3. Limpia `searchController.dispose()`
4. Llama a `super.dispose()`

### didChangeAppLifecycleState(AppLifecycleState state) (líneas 54-61)
**Propósito**: Callback que se ejecuta cuando cambia el estado del ciclo de vida de la app

**Lógica**:
- Si el estado es `resumed`:
  - Llama a `_checkContactsPermission()` para reverificar permisos
  - Llama a `_loadContacts()` para recargar contactos
  - Invalida `groupsStreamProvider` para recargar grupos

## 4. MÉTODOS DE PERMISOS Y CARGA

### _checkContactsPermission() (líneas 63-65)
**Tipo de retorno**: `Future<void>`

**Propósito**: Verifica el estado de los permisos de contactos

**Lógica**:
- Llama a `Permission.contacts.status` (await pero no hace nada con el resultado)
- Método parece incompleto o legacy (solo verifica pero no guarda el estado)

### _loadContacts() (líneas 67-93)
**Tipo de retorno**: `Future<void>`

**Propósito**: Carga la lista de contactos desde la API

**Lógica**:
1. Si ya está cargando (`_isLoadingContacts`), retorna inmediatamente
2. Actualiza estado:
   - `_isLoadingContacts = true`
   - `_contactsError = null`
3. En try-catch:
   - Llama a `ApiClient().fetchContacts(currentUserId: userId)`
   - Incluye comentario: "not migrated to Realtime"
   - Si está montado:
     - Parsea datos a lista de User con `map((c) => User.fromJson(c))`
     - Actualiza `_contacts` y `_isLoadingContacts = false`
4. En catch:
   - Si está montado:
     - Guarda error en `_contactsError`
     - `_isLoadingContacts = false`

## 5. MÉTODO DE NAVEGACIÓN

### _navigateToCreateGroup() (líneas 95-104)
**Tipo de retorno**: `Future<void>`

**Propósito**: Muestra diálogo indicando que la creación de grupos no está disponible

**Lógica**:
- Muestra `CupertinoAlertDialog` con:
  - Título: "Crear grupo"
  - Contenido: "Esta funcionalidad estará disponible pronto"
  - Botón "OK" que cierra el diálogo

## 6. TAB DE CONTACTOS

### _buildContactsTab() (líneas 106-118)
**Tipo de retorno**: `Widget`

**Propósito**: Construye el contenido de la tab de contactos

**Lógica**:
1. Si está cargando: retorna Center con `CupertinoActivityIndicator`
2. Si hay error: retorna `_buildContactsError()` con el error
3. Si no hay error: retorna `_buildContactsList()` con los contactos

### _buildContactsError(AppLocalizations l10n, Object error) (líneas 120-156)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `l10n`: Localizaciones
- `error`: Error a mostrar

**Propósito**: Construye UI para mostrar error de contactos (especialmente permisos)

**Lógica**:
1. Detecta si es error de permisos: `error.toString().contains('permission')`
2. Retorna Center con Column:
   - **Icono**:
     - person_2 naranja si es error de permisos
     - exclamationmark_triangle gris si es otro error
   - **Título**:
     - "Permiso de contactos requerido" si es error de permisos
     - "Error al cargar amigos" si es otro error
   - **Descripción**:
     - Instrucciones de permisos si es error de permisos
     - Texto del error si es otro error
   - **Botón** (solo si es error de permisos):
     - Key: 'people_groups_grant_permission_button'
     - Texto: "Permitir acceso"
     - Icono: person_2
     - onPressed:
       - Solicita permiso con `Permission.contacts.request().isGranted`
       - Si se otorga: llama a `_loadContacts()`
       - Si no se otorga: abre ajustes de la app con `openAppSettings()`

### _buildContactsList(List<User> contacts, AppLocalizations l10n) (líneas 158-237)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `contacts`: Lista de contactos a mostrar
- `l10n`: Localizaciones

**Propósito**: Construye la lista de contactos con búsqueda

**Lógica**:
1. **Filtra contactos** según `searchController.text`:
   - Si está vacío: muestra todos
   - Si hay texto: filtra por nombre (case insensitive)
2. **Si hay búsqueda pero no resultados** (líneas 167-196):
   - Retorna CustomScrollView con:
     - Campo de búsqueda en SliverToBoxAdapter
     - SliverFillRemaining con estado vacío:
       - Icono de búsqueda
       - Mensaje "No se encontraron contactos"
3. **Si no hay contactos** (líneas 198-209):
   - Retorna Center con Column:
     - Icono de person_2
     - Mensaje "No tienes contactos"
4. **Si hay contactos** (líneas 211-236):
   - Retorna ListView.builder con:
     - itemCount: `filteredContacts.length + 1` (el +1 es para el campo de búsqueda)
     - Si `index == 0`: retorna campo de búsqueda
     - Si `index > 0`: retorna `ContactCard` con:
       - contact: el contacto (index - 1)
       - onTap: navega a `/people/contacts/{contactId}` con GoRouter, pasando contact como extra

## 7. TAB DE GRUPOS

### _buildGroupsTab() (líneas 239-278)
**Tipo de retorno**: `Widget`

**Propósito**: Construye el contenido de la tab de grupos

**Lógica**:
1. Observa `groupsStreamProvider` con `ref.watch`
2. Usa `when()` para manejar el AsyncValue:
   - **data** (líneas 244-259):
     - Filtra grupos donde el usuario es miembro: `groups.where((group) => group.members.any((member) => member.id == userId))`
     - Si no hay grupos del usuario: retorna `EmptyState` con mensaje "No tienes grupos" e icono group
     - Si hay grupos: retorna ListView.builder con:
       - itemCount: cantidad de grupos del usuario
       - Para cada grupo: `_buildGroupCard(group, l10n)`
   - **loading** (línea 261): Center con `CupertinoActivityIndicator`
   - **error** (líneas 262-276): Center con Column:
     - Texto con error
     - Espaciador de 16px
     - Botón "Reintentar" que invalida `groupsStreamProvider`

### _buildGroupCard(Group group, AppLocalizations l10n) (líneas 280-308)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `group`: Grupo a mostrar
- `l10n`: Localizaciones

**Propósito**: Construye la tarjeta de un grupo

**Estructura**:
- Container con decoración de card
- `CupertinoListTile` con:
  - **leading**: Círculo morado (50x50) con icono de group blanco
  - **title**: Nombre del grupo
  - **subtitle**: "{cantidad} miembros"
  - **trailing**: Icono chevron_right gris
  - **onTap**: Muestra diálogo con:
    - Título: "Detalles del grupo"
    - Contenido: "Esta funcionalidad estará disponible pronto"
    - Botón "OK"

## 8. MÉTODO BUILD PRINCIPAL

### build(BuildContext context, WidgetRef ref) (líneas 311-389)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la UI principal de la pantalla

**Estructura**:
- `AdaptivePageScaffold` con:
  - key: 'people_groups_screen_scaffold'
  - title: "Personas y grupos"
  - **floatingActionButton**: Si `_tabIndex == 1` (tab de grupos):
    - `CupertinoButton.filled` con key 'people_groups_create_group_fab'
    - Icono: plus blanco
    - onPressed: `_navigateToCreateGroup()`
  - **body**: Column con:
    1. **Selector de tabs** (líneas 327-374):
       - Container con fondo gris redondeado (margin 16px)
       - Row con 2 tabs expandidas:
         - **Tab Contactos** (key: 'people_groups_contacts_tab'):
           - GestureDetector que:
             - Actualiza `_tabIndex = 0`
             - Anima PageController a página 0
           - Fondo azul si activo, transparente si no
           - Texto blanco si activo, gris si no
         - **Tab Grupos** (key: 'people_groups_groups_tab'):
           - Similar pero con `_tabIndex = 1` y página 1
    2. **PageView expandido** (líneas 375-385):
       - controller: `_pageController`
       - onPageChanged: actualiza `_tabIndex` con el índice
       - children:
         - `_buildContactsTab()`
         - `_buildGroupsTab()`

## 9. DEPENDENCIAS

### Providers utilizados:
- `groupsStreamProvider`: Stream de grupos (observado con watch, invalidado)

### Services:
- `ApiClient().fetchContacts()`: Carga contactos desde API (no Realtime)
- `ConfigService.instance.currentUserId`: ID del usuario actual

### Permissions:
- `Permission.contacts`: Permiso de acceso a contactos del dispositivo
- `openAppSettings()`: Abre configuración de la app

### Widgets externos:
- `PageController`: Controlador para PageView
- `PageView`: Vista paginada con swipe
- `CupertinoActivityIndicator`: Indicador de carga de iOS
- `CupertinoButton.filled`: Botón filled de iOS
- `CupertinoAlertDialog`: Diálogo de alerta de iOS
- `CupertinoDialogAction`: Acción en diálogo de iOS
- `CupertinoListTile`: Item de lista de iOS
- `CupertinoPageRoute`: Transición de página de iOS
- `ListView.builder`: Lista con builder
- `CustomScrollView`: Vista scrollable personalizada
- `SliverToBoxAdapter`: Adapta widget a sliver
- `SliverFillRemaining`: Sliver que llena espacio restante
- `GestureDetector`: Detector de gestos

### Widgets internos:
- `AdaptivePageScaffold`: Scaffold adaptativo
- `ContactCard`: Tarjeta de contacto personalizada
- `EmptyState`: Estado vacío
- `AdaptiveButton`: Botón adaptativo

### Helpers:
- `PlatformWidgets`: Widgets y helpers adaptativos
- `context.l10n` / `AppLocalizations.of(context)`: Localizaciones

### Navegación:
- `context.go()`: GoRouter para navegación
- `Navigator.of(context).pop()`: Para cerrar diálogos

### Models:
- `User`: Modelo de usuario/contacto
- `Group`: Modelo de grupo

## 10. FLUJO DE DATOS

### Al abrir la pantalla:
1. `initState()` se ejecuta
2. Registra observer de ciclo de vida
3. Inicializa PageController
4. Verifica permisos de contactos
5. Carga contactos desde API
6. Renderiza tab de contactos (índice 0 por defecto)

### Al cambiar de tab (tap en selector):
1. Usuario presiona tab (Contactos o Grupos)
2. GestureDetector actualiza `_tabIndex`
3. Anima PageController a la página correspondiente
4. PageView cambia de página con animación
5. Se muestra el contenido de la nueva tab

### Al cambiar de tab (swipe en PageView):
1. Usuario hace swipe en PageView
2. `onPageChanged` se ejecuta
3. Actualiza `_tabIndex` con el nuevo índice
4. Selector de tabs se actualiza visualmente

### Al buscar contactos:
1. Usuario escribe en campo de búsqueda
2. Controller actualiza su texto
3. `_buildContactsList()` filtra contactos en cada rebuild
4. ListView se actualiza con contactos filtrados

### Al cargar contactos:
- **Si tiene permisos**: carga contactos desde API, parsea a User, actualiza estado
- **Si NO tiene permisos**: muestra error con botón para solicitar permiso
- **Si hay error de API**: muestra error genérico con botón reintentar

### Al volver a la app:
1. `didChangeAppLifecycleState()` detecta `resumed`
2. Verifica permisos de nuevo
3. Recarga contactos
4. Invalida provider de grupos (recarga grupos)

### Navegación a contacto:
1. Usuario tap en `ContactCard`
2. Navega a `/people/contacts/{contactId}` con GoRouter
3. Pasa objeto `contact` como extra

## 11. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Dos tabs**: Contactos y Grupos
2. **Lista de contactos**:
   - Cargados desde API (no Realtime)
   - Búsqueda local por nombre
   - Navegación a detalle de contacto
3. **Lista de grupos**:
   - Stream en tiempo real de Supabase
   - Filtrados por membresía del usuario
   - Navegación a detalle (pendiente de implementar)
4. **Gestión de permisos**:
   - Verifica permiso de contactos
   - Solicita permiso si no se tiene
   - Abre ajustes si se niega
5. **FAB para crear grupo** (solo en tab de grupos)
6. **Estados vacíos** apropiados para cada caso
7. **Recarga automática** al volver a la app

### Estados manejados:

**Tab de Contactos**:
- Loading (cargando contactos)
- Error (permisos o API)
- Data:
  - Sin contactos (estado vacío)
  - Con contactos sin filtrar (lista completa + búsqueda)
  - Con contactos filtrados (lista filtrada + búsqueda)
  - Búsqueda sin resultados (estado vacío de búsqueda)

**Tab de Grupos**:
- Loading (cargando grupos)
- Error (con reintentar)
- Data:
  - Sin grupos (estado vacío)
  - Con grupos (lista)

**Selector de tabs**:
- Tab activa (fondo azul, texto blanco)
- Tab inactiva (fondo transparente, texto gris)

### Funcionalidades pendientes:
- **Crear grupo**: Muestra diálogo "pronto disponible"
- **Ver detalles de grupo**: Muestra diálogo "pronto disponible"

## 12. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 391
**Métodos públicos**: 2 (build, didChangeAppLifecycleState)
**Métodos privados**: 9

**Distribución aproximada**:
- Imports: ~19 líneas (4.9%)
- Declaración de clase y propiedades: ~15 líneas (3.8%)
- Ciclo de vida: ~26 líneas (6.6%)
- Permisos y carga: ~32 líneas (8.2%)
- Navegación: ~10 líneas (2.6%)
- Tab de contactos: ~131 líneas (33.5%)
  - _buildContactsTab: ~13 líneas
  - _buildContactsError: ~37 líneas
  - _buildContactsList: ~80 líneas
- Tab de grupos: ~70 líneas (17.9%)
  - _buildGroupsTab: ~40 líneas
  - _buildGroupCard: ~29 líneas
- build principal: ~79 líneas (20.2%)

## 13. CARACTERÍSTICAS TÉCNICAS

### Arquitectura de tabs:
- Usa `PageView` para swipe entre tabs
- Selector de tabs personalizado (no usa TabBar nativo)
- Sincronización bidireccional: tap en selector ↔ swipe en PageView

### Carga de datos híbrida:
- **Contactos**: API sin Realtime (método legacy)
- **Grupos**: Riverpod Stream Provider con Realtime
- Comentario explícito: "not migrated to Realtime" para contactos

### Gestión de permisos:
- Usa plugin `permission_handler`
- Verifica estado: `Permission.contacts.status`
- Solicita permiso: `Permission.contacts.request()`
- Abre ajustes: `openAppSettings()`
- Detección de errores: `error.toString().contains('permission')`

### Búsqueda en memoria:
- No hace llamadas a API por cada búsqueda
- Filtra lista cargada con `where()`
- Búsqueda case insensitive
- Solo para contactos (grupos no tienen búsqueda)

### Campo de búsqueda como item:
- En ListView.builder: primer item (index 0) es el campo de búsqueda
- itemCount: `length + 1` para incluir el campo
- `contactIndex = index - 1` para mapear correctamente

### FAB condicional:
- Solo visible en tab de grupos (_tabIndex == 1)
- Se oculta/muestra al cambiar de tab

### Observer de ciclo de vida:
- Implementa `WidgetsBindingObserver`
- Recarga datos al volver a la app (`resumed`)
- Útil para refrescar después de dar permisos en ajustes

### Keys para testing:
- 'people_groups_screen_scaffold': Scaffold principal
- 'people_groups_create_group_fab': FAB de crear grupo
- 'people_groups_grant_permission_button': Botón de permisos
- 'people_groups_contacts_tab': Tab de contactos
- 'people_groups_groups_tab': Tab de grupos

### Animaciones suaves:
- PageController con `animateToPage()`
- Duración: 300ms
- Curva: Curves.easeInOut

### Estados vacíos diferenciados:
- Sin contactos (general)
- Búsqueda sin resultados (específico de búsqueda)
- Sin grupos
- Cada uno con icono y mensaje apropiados

### Método de permiso incompleto:
- `_checkContactsPermission()` solo verifica pero no hace nada con el resultado
- Posiblemente legacy o placeholder para futura implementación
