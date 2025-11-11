# Documentación de Pantallas (Screens)

## Índice

1. [Resumen General](#resumen-general)
2. [Pantallas de Eventos](#pantallas-de-eventos)
3. [Pantallas de Calendarios](#pantallas-de-calendarios)
4. [Pantallas de Contactos y Suscripciones](#pantallas-de-contactos-y-suscripciones)
5. [Pantallas de Configuración](#pantallas-de-configuración)
6. [Pantallas de Sistema](#pantallas-de-sistema)
7. [Patrones de Arquitectura](#patrones-de-arquitectura)

---

## Resumen General

La aplicación contiene **18 pantallas** organizadas por funcionalidad:

- **Eventos**: 5 pantallas (events, event_detail, create_edit_event, event_series, birthdays)
- **Calendarios**: 3 pantallas (calendars, calendar_events, create/edit_calendar)
- **Contactos/Suscripciones**: 5 pantallas (people_groups, contact_detail, subscriptions, subscription_detail, public_user_events)
- **Configuración**: 1 pantalla (settings)
- **Sistema**: 4 pantallas (splash, access_denied, invite_users, más implícitas)

### State Management

| Tipo | Cantidad | Pantallas |
|------|----------|-----------|
| `ConsumerStatefulWidget` | 15 | Mayoría de pantallas interactivas |
| `ConsumerWidget` | 1 | settings_screen |
| `StatelessWidget` | 1 | access_denied_screen |
| `BaseFormScreen` | 1 | create_edit_event_screen |

---

## Pantallas de Eventos

### 1. events_screen.dart

**Pantalla Principal de Eventos**

```dart
class EventsScreen extends ConsumerStatefulWidget
```

**Propósito**: Pantalla principal que muestra todos los eventos del usuario con filtros y búsqueda.

**Parámetros**:
- Ninguno (accede a providers de Riverpod)

**Características**:
- **Filtros**: Todos, Mis Eventos, Suscritos, Invitaciones
- **Búsqueda**: Por nombre o descripción del evento
- **FAB**: Botón flotante para crear nuevo evento
- **Ordenamiento**: Por fecha de inicio (más próximos primero)

**Widgets principales**:
- `AdaptivePageScaffold`: Scaffold adaptativo iOS/Android
- `CupertinoSearchTextField`: Campo de búsqueda
- `EventListItem`: Item de lista para cada evento
- `CustomScrollView` con `SliverList`: Lista performante
- `AdaptiveButton`: Botón FAB para crear evento

**State interno**:
```dart
String _selectedFilter = 'all'; // Filtro activo
TextEditingController _searchController; // Controlador de búsqueda
```

**Navegación**:
- → `EventDetailScreen`: Al tocar un evento
- → `CreateEditEventScreen`: Desde FAB o botón crear

**Providers utilizados**:
- `eventsStreamProvider`: Stream de eventos en tiempo real
- `eventRepositoryProvider`: Operaciones CRUD de eventos

---

### 2. event_detail_screen.dart

**Vista Detallada de Evento**

```dart
class EventDetailScreen extends ConsumerStatefulWidget with WidgetsBindingObserver
```

**Propósito**: Muestra todos los detalles de un evento y permite realizar acciones sobre él.

**Parámetros**:
```dart
final Event event; // Evento a mostrar (requerido)
```

**Características**:
- **Detalles completos**: Título, descripción, fecha, ubicación, organizador
- **Acciones contextuales**: Según rol del usuario (owner/admin/invitado/participante)
- **Estado de participación**: Aceptar/Rechazar invitación, marcar asistencia
- **Nota personal**: Widget para agregar notas privadas
- **Notificaciones**: Opciones de recordatorios

**Widgets principales**:
- `EventCard`: Card principal con info del evento
- `EventDetailActions`: Botones de acción (editar, eliminar, compartir)
- `PersonalNoteWidget`: Widget para nota personal
- `UserAvatar`: Avatar del organizador
- `AdaptiveButton`: Botones de estado (Aceptar/Rechazar)

**State interno**:
```dart
String? _participationStatus; // Estado actual de participación
bool _isAttending; // Si el usuario asiste
String _personalNote; // Nota personal del usuario
```

**Acciones disponibles** (según permisos):

**Owner/Admin**:
- ✏️ Editar evento
- 🗑️ Eliminar evento
- 👥 Invitar usuarios
- 📊 Ver participantes
- 🔗 Compartir enlace

**Invitado**:
- ✅ Aceptar invitación
- ❌ Rechazar invitación
- 📝 Agregar nota personal
- 👋 Abandonar evento

**Navegación**:
- → `CreateEditEventScreen`: Editar evento
- → `InviteUsersScreen`: Invitar usuarios
- → `PublicUserEventsScreen`: Ver eventos del organizador
- → `CalendarEventsScreen`: Ver eventos del calendario
- → `EventSeriesScreen`: Ver serie completa (si es recurrente)
- → `EventDetailScreen`: Ver eventos futuros de la serie

**Providers utilizados**:
- `eventRepositoryProvider`: Operaciones del evento
- `calendarsStreamProvider`: Datos del calendario

---

### 3. create_edit_event_screen.dart

**Crear o Editar Evento**

```dart
class CreateEditEventScreen extends BaseFormScreen
```

**Propósito**: Formulario completo para crear nuevos eventos o editar existentes.

**Parámetros**:
```dart
final Event? eventToEdit; // Evento a editar (null = crear nuevo)
final bool isRecurring; // Si es evento recurrente (default: false)
```

**Características**:
- **Tipos de evento**: Único, Recurrente, Cumpleaños
- **Campos**: Título, descripción, fecha inicio/fin, ubicación, calendario
- **Recurrencia**: Patrones personalizables (diario, semanal, mensual, anual)
- **Timezone**: Selector de zona horaria
- **Permisos**: Quién puede invitar, visibilidad
- **Validación**: Formulario completo con validaciones

**Widgets principales**:
- `BaseFormScreen`: Clase base con funcionalidad de formulario
- `CustomDateTimeWidget`: Selector de fecha y hora
- `CalendarHorizontalSelector`: Selector horizontal de calendarios
- `TimezoneHorizontalSelector`: Selector de timezone
- `RecurrenceTimeSelector`: Configuración de recurrencia
- `CupertinoSwitch`: Switches para opciones booleanas

**State interno**:
```dart
String _title;
String _description;
DateTime _startDate;
DateTime _endDate;
int? _calendarId;
String _timezone;
bool _isRecurring;
RecurrencePattern? _recurrencePattern;
bool _canInviteUsers;
bool _isPublic;
```

**Validaciones**:
- ✅ Título requerido
- ✅ Fecha inicio < Fecha fin
- ✅ Calendario seleccionado
- ✅ Patrón de recurrencia válido (si aplica)

**Navegación**:
- → `/calendars/create`: Crear calendario nuevo (desde selector)
- ← Pop: Al guardar o cancelar

**Operaciones**:
- `createEvent()`: Crear nuevo evento
- `updateEvent()`: Actualizar evento existente

---

### 4. event_series_screen.dart

**Serie de Eventos Recurrentes**

```dart
class EventSeriesScreen extends ConsumerStatefulWidget
```

**Propósito**: Muestra todos los eventos que pertenecen a una serie recurrente.

**Parámetros**:
```dart
final List<Event> events; // Lista de eventos de la serie (requerido)
final String seriesName; // Nombre de la serie (requerido)
```

**Características**:
- **Lista ordenada**: Eventos ordenados por fecha
- **Contador**: Muestra total de eventos en la serie
- **Acciones individuales**: Editar/eliminar cada instancia
- **Navegación**: Acceso a detalle de cada evento

**Widgets principales**:
- `AdaptivePageScaffold`
- `EventListItem`: Con `showDate: true` para mostrar fecha
- `ListView.separated`: Lista con separadores
- `EmptyState`: Si no hay eventos

**Navegación**:
- → `EventDetailScreen`: Al tocar cualquier evento de la serie

**Operaciones**:
- `_deleteEvent()`: Eliminar evento individual de la serie

---

### 5. birthdays_screen.dart

**Cumpleaños**

```dart
class BirthdaysScreen extends ConsumerStatefulWidget
```

**Propósito**: Muestra cumpleaños de contactos ordenados por proximidad.

**Parámetros**:
- Ninguno

**Características**:
- **Ordenamiento especial**: Próximos cumpleaños primero
- **Búsqueda**: Por nombre de contacto
- **Badges**: Indicador de "Hoy" o "Próximamente"
- **Edad**: Calcula y muestra edad actual/futura

**Widgets principales**:
- `CupertinoPageScaffold`
- `CupertinoSearchTextField`
- `EventCard`: Para cada cumpleaños
- `CustomScrollView` con `SliverList`

**Navegación**:
- → `EventDetailScreen`: Ver detalles del cumpleaños

---

## Pantallas de Calendarios

### 6. calendars_screen.dart

**Gestión de Calendarios**

```dart
class CalendarsScreen extends ConsumerStatefulWidget
```

**Propósito**: Pantalla principal para gestionar calendarios propios y buscar/suscribirse a calendarios públicos.

**Parámetros**:
- Ninguno

**Características especiales**:

**Búsqueda por Hash**:
```dart
// Buscar calendario público por código
// Ejemplo: #ABC123
_searchController.text.startsWith('#')
```

**Tipos de calendario**:
1. **Propios**: Calendarios creados por el usuario
2. **Compartidos**: Calendarios donde es miembro/admin
3. **Públicos**: Calendarios suscritos vía hash

**Widgets principales**:
- `CupertinoSearchTextField`: Con soporte para búsqueda por #hash
- `CupertinoListTile`: Cada calendario
- `EmptyState`: Estado vacío con CTA
- `AdaptiveButton`: FAB para crear

**Visualización de calendario**:
```dart
// Indicadores visuales
Icon: calendar.isPublic ? CupertinoIcons.globe : CupertinoIcons.lock
Badge: isOwner ? "Owner" : (isPublic ? "Subscriber" : "Member")
Color: Círculo con color del calendario
```

**Navegación**:
- → `CalendarEventsScreen`: Ver eventos del calendario
- → `/calendars/create`: Crear nuevo calendario

**Operaciones**:
- `_searchByHash()`: Buscar calendario público
- `_subscribeToCalendar()`: Suscribirse a calendario
- `_deleteOrLeaveCalendar()`: Eliminar (owner) o abandonar (member)

---

### 7. calendar_events_screen.dart

**Eventos de un Calendario**

```dart
class CalendarEventsScreen extends ConsumerStatefulWidget
```

**Propósito**: Muestra todos los eventos de un calendario específico.

**Parámetros**:
```dart
final int calendarId; // ID del calendario (requerido)
final String calendarName; // Nombre del calendario (requerido)
final String? calendarColor; // Color hex del calendario (opcional)
```

**Características**:
- **Filtrado**: Solo eventos de este calendario
- **Búsqueda**: Por título o descripción
- **Header personalizado**: Con color del calendario
- **Opciones**: Menú para editar/eliminar calendario

**Widgets principales**:
- `CupertinoNavigationBar`: Con indicador de color del calendario
- `CupertinoSearchTextField`
- `EventListItem`
- `CupertinoActionSheet`: Menú de opciones

**NavigationBar personalizado**:
```dart
middle: Row([
  Container(color: calendarColor, shape: circle), // Indicador de color
  Text(calendarName)
]),
trailing: CupertinoButton(icon: ellipsis_circle) // Menú opciones
```

**Menú de opciones** (según permisos):
- ✏️ **Editar calendario** (si es owner o admin)
- 🗑️ **Eliminar calendario** (si es owner)
- 👋 **Abandonar calendario** (si no es owner)

**Navegación**:
- → `EventDetailScreen`: Ver evento
- → `/calendars/{id}/edit`: Editar calendario

---

### 8. create_calendar_screen.dart

**Crear Calendario**

```dart
class CreateCalendarScreen extends ConsumerStatefulWidget
```

**Propósito**: Formulario para crear un nuevo calendario/comunidad.

**Parámetros**:
- Ninguno

**Campos del formulario**:
```dart
String name; // Nombre del calendario (requerido)
String? description; // Descripción (opcional)
bool isPublic; // Si es público o privado (default: false)
bool deleteEventsOnRemoval; // Eliminar eventos al abandonar (default: false)
```

**Características**:

**Visibilidad**:
- **Privado**: Solo miembros invitados
- **Público**: Cualquiera puede suscribirse con el código hash

**Opciones**:
- 🌐 **Calendario Público**: Genera código hash para compartir
- 🗑️ **Eliminar eventos**: Al eliminar calendario o que miembro abandone

**Widgets principales**:
- `CupertinoTextField`: Nombre y descripción
- `CupertinoSwitch`: Opciones booleanas
- `CupertinoButton`: Botón crear

**Validación**:
- ✅ Nombre requerido (mínimo 3 caracteres)

**Navegación**:
- ← Pop: Tras crear calendario exitosamente

---

### 9. edit_calendar_screen.dart

**Editar Calendario**

```dart
class EditCalendarScreen extends ConsumerStatefulWidget
```

**Propósito**: Editar configuración de calendario existente o eliminarlo.

**Parámetros**:
```dart
final String calendarId; // ID del calendario a editar (requerido)
```

**Secciones del formulario**:

**1. Información Básica**:
- Nombre
- Descripción
- Color

**2. Visibilidad**:
- Descubrible (si otros pueden encontrarlo)
- Código hash (si es público)

**3. Opciones de Eliminación**:
```dart
bool _deleteAssociatedEvents; // Eliminar eventos al borrar calendario
// Si false: eventos quedan huérfanos y se asignan a calendario por defecto
```

**Widgets principales**:
- `AdaptivePageScaffold`
- `CupertinoTextField`
- `CupertinoSwitch`
- Secciones con `Container` estilizados

**Confirmación de eliminación**:
```dart
// Muestra diálogo diferente según opción
_deleteAssociatedEvents ?
  "Eliminará calendario Y todos los eventos" :
  "Eliminará calendario pero conservará eventos"
```

**Navegación**:
- ← Pop: Tras actualizar o eliminar

**Operaciones**:
- `_updateCalendar()`: Actualizar información
- `_deleteCalendar()`: Eliminar calendario (con confirmación)

---

## Pantallas de Contactos y Suscripciones

### 10. people_groups_screen.dart

**Contactos y Grupos**

```dart
class PeopleGroupsScreen extends ConsumerStatefulWidget
```

**Propósito**: Gestión de contactos y grupos con navegación por tabs.

**Parámetros**:
- Ninguno

**Estructura de tabs**:
```dart
PageController _pageController;
int _currentTab = 0; // 0: Contactos, 1: Grupos
```

**Tab 1: Contactos**:
- Lista de contactos del usuario
- Búsqueda por nombre
- Indicadores de estado (bloqueado, amigo)
- Botón para importar contactos del dispositivo

**Tab 2: Grupos**:
- Lista de grupos del usuario
- Contador de miembros
- Botón para crear nuevo grupo
- Navegación a detalles del grupo

**Widgets principales**:
- `PageView`: Navegación entre tabs
- `ContactCard`: Card de contacto
- `CupertinoListTile`: Item de grupo
- `CupertinoSearchTextField`: Búsqueda
- `ContactsPermissionDialog`: Diálogo de permisos

**Navegación**:
- → `/people/contacts/{id}`: Ver detalle de contacto
- → Diálogo crear grupo (modal)
- → Diálogo detalles grupo (modal)

**Permisos**:
- 📱 Acceso a contactos del dispositivo
- Solicitud de permisos con `ContactsPermissionDialog`

---

### 11. contact_detail_screen.dart

**Detalle de Contacto**

```dart
class ContactDetailScreen extends ConsumerStatefulWidget
```

**Propósito**: Ver información de un contacto y eventos compartidos con él.

**Parámetros**:
```dart
final User contact; // Contacto a mostrar (requerido)
final List<Event>? excludedEventIds; // Eventos a excluir (opcional)
```

**Secciones**:

**1. Header**:
```dart
UserAvatar(size: large)
Text(displayName)
Text(email)
```

**2. Información**:
- Teléfono
- Fecha de nacimiento
- País/Ciudad
- Timezone

**3. Eventos Compartidos**:
- Lista de eventos donde ambos participan
- Filtro para excluir ciertos eventos

**4. Acciones**:
- 🚫 Bloquear usuario
- ✉️ Enviar mensaje (si implementado)

**Widgets principales**:
- `UserAvatar`: Avatar grande del contacto
- `EventCard`: Para eventos compartidos
- `AdaptiveButton`: Botón de bloquear

**Navegación**:
- → `EventDetailScreen`: Ver evento compartido

**Operaciones**:
- `_blockUser()`: Bloquear contacto (con confirmación)

---

### 12. subscriptions_screen.dart

**Suscripciones**

```dart
class SubscriptionsScreen extends ConsumerStatefulWidget with WidgetsBindingObserver
```

**Propósito**: Gestionar suscripciones a usuarios públicos.

**Parámetros**:
- Ninguno

**Características**:
- **Lista de suscripciones**: Usuarios públicos seguidos
- **Búsqueda**: Por nombre de usuario
- **Contador de eventos**: Eventos públicos de cada suscripción
- **Acciones**: Ver eventos o cancelar suscripción

**Widgets principales**:
- `SubscriptionCard`: Card con info de suscripción
- `CupertinoSearchTextField`
- `CustomScrollView` con `SliverList`

**SubscriptionCard incluye**:
```dart
UserAvatar
Text(displayName)
Text(eventCount + " eventos")
Button("Ver eventos")
Button("Cancelar suscripción")
```

**Navegación**:
- → `PublicUserEventsScreen`: Ver eventos de la suscripción

**Operaciones**:
- `_unsubscribe()`: Cancelar suscripción

---

### 13. subscription_detail_screen.dart

**Detalle de Suscripción**

```dart
class SubscriptionDetailScreen extends ConsumerStatefulWidget
```

**Propósito**: Ver todos los eventos públicos de una suscripción específica.

**Parámetros**:
```dart
final Subscription subscription; // Suscripción a mostrar (requerido)
```

**Características**:
- **Eventos filtrados**: Solo eventos públicos del usuario
- **Ordenamiento**: Por fecha (próximos primero)
- **Estado vacío**: Mensaje si no hay eventos

**Widgets principales**:
- `EventsList`: Lista reutilizable de eventos
- `EmptyState`

**Navegación**:
- → `EventDetailScreen`: Ver detalle del evento

---

### 14. public_user_events_screen.dart

**Eventos Públicos de Usuario**

```dart
class PublicUserEventsScreen extends ConsumerStatefulWidget
```

**Propósito**: Ver eventos públicos de un usuario y gestionar suscripción.

**Parámetros**:
```dart
final User publicUser; // Usuario público a mostrar (requerido)
```

**Características**:

**Header**:
```dart
UserAvatar(publicUser)
Text(displayName)
Button(isSubscribed ? "Dejar de seguir" : "Seguir")
```

**Lista de eventos**:
- Solo eventos públicos del usuario
- Búsqueda por nombre
- Ordenamiento cronológico

**Widgets principales**:
- `CupertinoNavigationBar`: Con botón Follow/Unfollow
- `EventListItem`
- `CupertinoSearchTextField`

**Navegación**:
- → `EventDetailScreen`: Ver evento público

**Operaciones**:
- `_toggleSubscription()`: Suscribirse/Desuscribirse

---

## Pantallas de Configuración

### 15. settings_screen.dart

**Configuración**

```dart
class SettingsScreen extends ConsumerWidget
```

**Propósito**: Configuración general de la aplicación.

**Parámetros**:
```dart
final SettingsSection initialSection; // Sección inicial (default: general)
```

**Secciones disponibles**:

**1. General**:
```dart
enum SettingsSection {
  general,
  permissions,
  blocked,
  about
}
```

**Configuraciones**:

**Idioma**:
- `LanguageSelector`: Selector de idioma
- Opciones: Español, Inglés, Catalán
- Cambio en tiempo real con `context.l10n`

**Timezone**:
- `CountryTimezoneSelector`: Selector de país y zona horaria
- Búsqueda de ciudades
- Conversión automática de horarios

**Permisos**:
- 📱 Contactos
- 📍 Ubicación
- 🔔 Notificaciones
- Botones para abrir configuración del sistema

**Usuarios Bloqueados**:
- Lista de usuarios bloqueados
- Opción para desbloquear

**Acerca de**:
- Versión de la app
- Términos y condiciones
- Política de privacidad
- Créditos

**Widgets principales**:
- `LanguageSelector`
- `CountryTimezoneSelector`
- `ConfigurableStyledContainer`: Contenedores estilizados
- `AdaptiveButton`

**Navegación**:
- No navega (abre configuración del sistema con `openAppSettings`)

**Operaciones**:
- `_changeLanguage()`: Cambiar idioma
- `_changeTimezone()`: Cambiar zona horaria
- `_unblockUser()`: Desbloquear usuario

---

## Pantallas de Sistema

### 16. splash_screen.dart

**Pantalla de Carga**

```dart
class SplashScreen extends ConsumerStatefulWidget with TickerProviderStateMixin
```

**Propósito**: Pantalla inicial mientras se inicializan repositorios y servicios.

**Parámetros**:
```dart
final Widget? nextScreen; // Pantalla siguiente (opcional)
```

**Características**:

**Animaciones**:
```dart
AnimationController _fadeController; // Fade in del logo
AnimationController _scaleController; // Scale del logo
AnimationController _pulseController; // Pulse del logo
```

**Secuencia de inicialización**:
```dart
1. initializeRepositories() // Inicializar Hive, Supabase
2. Wait for providers to be ready
3. Timer de seguridad (máximo 10 segundos)
4. Navigate to nextScreen o /events
```

**Estados**:
- ⏳ **Loading**: Mostrando animaciones
- ✅ **Success**: Navegación automática
- ❌ **Error**: Botón de reintentar

**Widgets principales**:
- `AnimatedBuilder`: Animaciones del logo
- `CupertinoActivityIndicator`: Indicador de carga
- `AdaptiveButton`: Botón retry

**Navegación**:
- → `/events`: Si inicialización exitosa
- → `nextScreen`: Si se proporciona

**Timeout de seguridad**:
```dart
Timer(Duration(seconds: 10), () {
  if (!_initialized) {
    _showRetryButton();
  }
});
```

---

### 17. access_denied_screen.dart

**Acceso Denegado**

```dart
class AccessDeniedScreen extends StatelessWidget
```

**Propósito**: Pantalla de error cuando el usuario no tiene permisos.

**Parámetros**:
- Ninguno

**Características**:
- ⛔ Icono grande de error
- Mensaje explicativo
- Información de contacto
- Sin navegación (pantalla terminal)

**Widgets principales**:
- `Container`: Con gradiente de fondo
- `Icon`: CupertinoIcons.clear_thick (grande)
- `Text`: Mensajes informativos

**Casos de uso**:
- Usuario sin permisos de acceso
- Cuenta suspendida
- Error de autenticación
- Acceso desde dispositivo no autorizado

---

### 18. invite_users_screen.dart

**Invitar Usuarios**

```dart
class InviteUsersScreen extends ConsumerStatefulWidget
```

**Propósito**: Seleccionar usuarios y grupos para invitar a un evento.

**Parámetros**:
```dart
final Event event; // Evento al que invitar (requerido)
```

**Características**:

**Tabs**:
1. **Usuarios**: Lista de contactos individuales
2. **Grupos**: Lista de grupos del usuario

**Búsqueda**:
- Búsqueda en ambos tabs
- Filtrado en tiempo real

**Selección múltiple**:
```dart
Set<int> _selectedUserIds;
Set<int> _selectedGroupIds;
```

**Widgets principales**:
- `PageView`: Navegación entre tabs
- `SelectableCard`: Cards seleccionables
- `CupertinoSearchTextField`
- `AdaptiveButton`: Botón enviar invitaciones

**Estado de selección**:
```dart
SelectableCard(
  isSelected: _selectedUserIds.contains(userId),
  onTap: () => _toggleSelection(userId)
)
```

**Navegación**:
- ← Pop: Tras enviar invitaciones

**Operaciones**:
- `_sendInvitations()`: Enviar invitaciones a seleccionados
- `_toggleSelection()`: Agregar/quitar de selección

---

## Patrones de Arquitectura

### 1. State Management

**Riverpod en todas las pantallas**:
```dart
class XScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<XScreen> createState() => _XScreenState();
}

class _XScreenState extends ConsumerState<XScreen> {
  // Acceso a providers con ref.watch(), ref.read()
}
```

**Providers comunes**:
- `eventsStreamProvider`: Stream de eventos
- `calendarsStreamProvider`: Stream de calendarios
- `subscriptionsProvider`: Estado de suscripciones
- `eventRepositoryProvider`: Repositorio de eventos
- `calendarRepositoryProvider`: Repositorio de calendarios

---

### 2. Navegación

**Dos sistemas de navegación**:

**GoRouter** (preferido para rutas nombradas):
```dart
context.go('/events');
context.push('/calendars/create');
context.push('/calendars/${calendarId}/edit');
```

**Navigator tradicional** (para flujos complejos):
```dart
Navigator.of(context).push(
  CupertinoPageRoute(
    builder: (context) => EventDetailScreen(event: event)
  )
);
```

**Patrón de retorno**:
```dart
// Con resultado
final result = await Navigator.of(context).push(...);
if (result == true) {
  _refreshData();
}

// Con GoRouter
context.pop(result);
```

---

### 3. Gestión de Formularios

**BaseFormScreen**:
```dart
abstract class BaseFormScreen extends StatefulWidget {
  // Funcionalidad común de formularios
  - Validación
  - Estado de carga
  - Manejo de errores
  - Guardado/Cancelación
}
```

**Validación**:
```dart
String? _validateField(String? value) {
  if (value == null || value.isEmpty) {
    return context.l10n.fieldRequired;
  }
  return null;
}
```

---

### 4. Búsqueda y Filtrado

**Patrón estándar**:
```dart
final TextEditingController _searchController = TextEditingController();

@override
void initState() {
  super.initState();
  _searchController.addListener(_onSearchChanged);
}

void _onSearchChanged() {
  setState(() {}); // Rebuild con nuevo filtro
}

List<T> _applySearchFilter(List<T> items) {
  final query = _searchController.text.toLowerCase();
  if (query.isEmpty) return items;

  return items.where((item) =>
    item.name.toLowerCase().contains(query)
  ).toList();
}
```

---

### 5. Operaciones Asíncronas

**Patrón con loading state**:
```dart
bool _isLoading = false;

Future<void> _performOperation() async {
  setState(() => _isLoading = true);

  try {
    await repository.operation();
    if (mounted) {
      PlatformDialogHelpers.showSuccess(context, l10n.success);
      Navigator.of(context).pop();
    }
  } catch (e) {
    if (mounted) {
      final error = ErrorMessageParser.parse(e, context);
      PlatformDialogHelpers.showError(context, error);
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

---

### 6. Permisos y Roles

**Verificación de permisos**:
```dart
// Para eventos
final canEdit = EventPermissions.canEdit(event: event);
final isOwner = EventPermissions.isOwner(event);

// Para calendarios
final canEdit = await CalendarPermissions.canEdit(
  calendar: calendar,
  repository: repository
);
final isOwner = CalendarPermissions.isOwner(calendar);
```

**Acciones condicionales**:
```dart
if (canEdit) {
  actions.add(CupertinoActionSheetAction(
    child: Text(l10n.edit),
    onPressed: _edit,
  ));
}
```

---

### 7. Gestión de Errores

**Patrón centralizado**:
```dart
try {
  await operation();
} catch (e) {
  if (mounted) {
    final errorMessage = ErrorMessageParser.parse(e, context);
    PlatformDialogHelpers.showSnackBar(
      context: context,
      message: errorMessage,
      isError: true,
    );
  }
}
```

**ErrorMessageParser** localiza errores:
- Errores de red
- Timeouts
- Errores del servidor (500, 401, 403, 404)
- Errores de permisos

---

### 8. Lifecycle

**WidgetsBindingObserver** para lifecycle:
```dart
class _XScreenState extends ConsumerState<XScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }
}
```

---

### 9. Widgets Reutilizables

**Todas las pantallas usan**:
- `AdaptivePageScaffold`: Scaffold adaptativo
- `EmptyState`: Estado vacío consistente
- `CupertinoSearchTextField`: Búsqueda estándar
- `AdaptiveButton`: Botones adaptativos
- Custom widgets del proyecto

---

### 10. Internacionalización

**Acceso a traducciones**:
```dart
final l10n = context.l10n;
Text(l10n.events)
Text(l10n.confirmDeleteEvent)
```

**Idiomas soportados**:
- 🇪🇸 Español
- 🇬🇧 Inglés
- 🇪🇸 Catalán

---

## Diagrama de Navegación

```
splash_screen
    ↓
events_screen ←─────────────────┐
    ↓                            │
    ├→ event_detail_screen       │
    │     ├→ create_edit_event   │
    │     ├→ invite_users        │
    │     ├→ public_user_events  │
    │     ├→ calendar_events ────┘
    │     └→ event_series ───────┐
    │                             │
    ├→ create_edit_event          │
    │                             │
    └→ event_series ──────────────┘
         └→ event_detail (loop)

calendars_screen
    ├→ calendar_events_screen
    │     ├→ event_detail_screen
    │     └→ edit_calendar_screen
    └→ create_calendar_screen

subscriptions_screen
    ├→ public_user_events_screen
    │     └→ event_detail_screen
    └→ subscription_detail_screen
          └→ event_detail_screen

people_groups_screen
    └→ contact_detail_screen
          └→ event_detail_screen

birthdays_screen
    └→ event_detail_screen

settings_screen
    (sin navegación, abre configuración sistema)

access_denied_screen
    (pantalla terminal)
```

---

## Mejores Prácticas Implementadas

### ✅ Consistencia
- Todas usan Riverpod para state management
- Patrón similar para búsqueda y filtrado
- Gestión de errores centralizada
- Navegación predecible

### ✅ Performance
- `CustomScrollView` con `SliverList` para listas largas
- Lazy loading de eventos
- Caching con Hive
- Debounce en búsquedas (donde aplica)

### ✅ UX
- Estados vacíos con `EmptyState`
- Loading states consistentes
- Confirmaciones para acciones destructivas
- Mensajes de error localizados

### ✅ Seguridad
- Verificación de permisos antes de acciones
- Validación de formularios
- Protección contra operaciones no autorizadas

### ✅ Mantenibilidad
- Separación de concerns (UI, lógica, datos)
- Utils reutilizables (EventOperations, CalendarOperations)
- Widgets componibles
- Código DRY

---

## Estadísticas

- **Total de pantallas**: 18
- **Pantallas con búsqueda**: 10 (55%)
- **Pantallas con CustomScrollView**: 8 (44%)
- **Pantallas que navegan a EventDetailScreen**: 13 (72%)
- **Pantallas con formularios**: 4 (22%)
- **Pantallas con lifecycle observer**: 3 (17%)

---

**Última actualización**: 2025-11-03
**Versión de la app**: 1.0.0
