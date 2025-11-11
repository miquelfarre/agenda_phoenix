# Documentación de Widgets

## Índice

1. [Resumen General](#resumen-general)
2. [Widgets de Eventos](#widgets-de-eventos)
3. [Widgets de UI Adaptativo](#widgets-de-ui-adaptativo)
4. [Widgets de Formulario](#widgets-de-formulario)
5. [Widgets de Visualización](#widgets-de-visualización)
6. [Widgets Especializados](#widgets-especializados)
7. [Patrones de Diseño](#patrones-de-diseño)
8. [Guía de Uso](#guía-de-uso)

---

## Resumen General

La aplicación contiene **48 widgets** organizados por funcionalidad:

- **Eventos**: 12 widgets (cards, listas, acciones, detalles)
- **UI Adaptativo**: 7 widgets (buttons, scaffolds, cards, text fields)
- **Formulario**: 11 widgets (selectores, pickers, campos personalizados)
- **Visualización**: 11 widgets (avatares, cards, estados vacíos)
- **Especializados**: 7 widgets (recurrencia, notas, permisos)

### Prioridad de Uso

| Prioridad | Widgets | Uso |
|-----------|---------|-----|
| **Alta** | 7 widgets | Usados en múltiples pantallas |
| **Media** | 13 widgets | Usados en contextos específicos |
| **Baja** | 28 widgets | Especializados o utilidades |

---

## Widgets de Eventos

### 1. EventCard

**Tarjeta Principal de Evento**

```dart
class EventCard extends ConsumerWidget
```

**Propósito**: Componente central para mostrar eventos en listas, con soporte para múltiples variantes y estados.

**Ubicación**: `lib/widgets/event_card.dart`

**Parámetros principales**:
```dart
final Event event; // Evento a mostrar (requerido)
final VoidCallback? onTap; // Callback al tocar
final EventCardConfig config; // Configuración de visualización
```

**Uso básico**:
```dart
EventCard(
  event: myEvent,
  onTap: () => Navigator.push(...),
  config: EventCardConfig(
    showNewBadge: true,
    showCalendarBadge: true,
    showChevron: true,
  )
)
```

**Características**:
- **Badges dinámicos**: NEW, calendario, cumpleaños, recurrente
- **Estados visuales**: Invitación pendiente, aceptada, rechazada
- **Acciones contextuales**: Según rol del usuario
- **Avatares**: Organizador y participantes
- **Responsive**: Se adapta a diferentes tamaños

**Componentes internos**:
- `EventCardHeader`: Banner y avatares
- `EventCardBadges`: Indicadores visuales
- `EventCardActions`: Botones de acción

---

#### EventCard Subcomponentes

**EventCardHeader** (`event_card/event_card_header.dart`)

```dart
class EventCardHeader extends StatelessWidget
```

**Propósito**: Sección superior de la tarjeta con banner de invitaciones y avatares.

**Características**:
- **Banner de invitación**: Fondo azul si hay invitación pendiente
- **Avatar del organizador**: Con nombre
- **Lista de asistentes**: Hasta 3 avatares + contador

**Uso**:
```dart
EventCardHeader(
  event: event,
  showInvitationBanner: true,
  showAttendees: true,
)
```

---

**EventCardBadges** (`event_card/event_card_badges.dart`)

```dart
class EventCardBadges extends StatelessWidget
```

**Propósito**: Mostrar badges informativos del evento.

**Badges disponibles**:
- 🆕 **NEW**: Evento nuevo (últimas 24h)
- 📅 **Calendar**: Nombre del calendario
- 🎂 **Birthday**: Indicador de cumpleaños
- 🔄 **Recurring**: Evento recurrente

**Uso**:
```dart
EventCardBadges(
  event: event,
  showNewBadge: true,
  showCalendarBadge: true,
  showBirthdayBadge: event.isBirthday,
  showRecurringBadge: event.isRecurring,
)
```

---

**EventCardActions** (`event_card/event_card_actions.dart`)

```dart
class EventCardActions extends ConsumerWidget
```

**Propósito**: Botones de acción en el trailing de la tarjeta.

**Acciones según contexto**:
- **Invitación**: Botones Aceptar ✓ / Rechazar ✗
- **Owner**: Botón eliminar 🗑️
- **Suscripción pública**: Botón eliminar
- **Default**: Chevron de navegación →

**Parámetros**:
```dart
final Event event;
final EventCardConfig config;
final EventInteraction? interaction;
final String? participationStatus;
```

**Ejemplo de uso**:
```dart
EventCardActions(
  event: event,
  config: config,
  interaction: interaction,
  participationStatus: 'pending',
)
```

---

**EventCardConfig** (`event_card/event_card_config.dart`)

```dart
class EventCardConfig
```

**Propósito**: Configuración centralizada para EventCard.

**Propiedades**:
```dart
final bool showNewBadge;           // Mostrar badge NEW
final bool showCalendarBadge;      // Mostrar badge calendario
final bool showBirthdayBadge;      // Mostrar badge cumpleaños
final bool showRecurringBadge;     // Mostrar badge recurrente
final bool showChevron;            // Mostrar chevron navegación
final bool showInvitationBanner;   // Banner de invitación
final bool showAttendees;          // Lista de asistentes
final bool compact;                // Modo compacto
```

**Factories predefinidos**:
```dart
// Card simple con chevron
EventCardConfig.simple() => EventCardConfig(
  showChevron: true,
  showNewBadge: false,
  showCalendarBadge: false,
)

// Card para invitaciones
EventCardConfig.invitation() => EventCardConfig(
  showInvitationBanner: true,
  showNewBadge: true,
  showChevron: false,
)

// Card solo lectura (sin acciones)
EventCardConfig.readOnly() => EventCardConfig(
  showChevron: false,
)
```

**Uso**:
```dart
// Usando factory
EventCard(
  event: event,
  config: EventCardConfig.invitation(),
)

// Personalizado
EventCard(
  event: event,
  config: EventCardConfig(
    showNewBadge: true,
    showCalendarBadge: true,
    compact: true,
  ),
)
```

---

### 2. EventListItem

**Wrapper Simplificado de EventCard**

```dart
class EventListItem extends StatelessWidget
```

**Propósito**: Simplifica el uso de EventCard en listas con configuración predeterminada.

**Ubicación**: `lib/widgets/event_list_item.dart`

**Parámetros**:
```dart
final Event event;                        // Evento a mostrar
final Function(Event) onTap;              // Callback de tap
final Function(Event, {bool})? onDelete;  // Callback de eliminación
final bool navigateAfterDelete;           // Navegar tras eliminar (default: false)
final bool hideInvitationStatus;          // Ocultar estado invitación (default: false)
final bool showDate;                      // Mostrar fecha (default: true)
final bool showNewBadge;                  // Mostrar badge NEW (default: true)
```

**Uso típico**:
```dart
ListView.builder(
  itemCount: events.length,
  itemBuilder: (context, index) {
    return EventListItem(
      event: events[index],
      onTap: (event) => _navigateToDetail(event),
      onDelete: _deleteEvent,
      showDate: true,
      showNewBadge: true,
    );
  },
)
```

**Diferencia con EventCard**:
- EventListItem configura automáticamente EventCard para uso en listas
- Incluye lógica de eliminación integrada
- Gestiona navegación post-eliminación
- Configuración más simple y directa

---

### 3. EventsList

**Lista Agrupada de Eventos**

```dart
class EventsList extends StatelessWidget
```

**Propósito**: Lista de eventos agrupados por fecha con headers.

**Ubicación**: `lib/widgets/events_list.dart`

**Parámetros**:
```dart
final List<Event> events;                 // Lista de eventos
final Function(Event)? onEventTap;        // Callback de tap
final Function(Event, {bool})? onDelete;  // Callback de eliminación
final bool navigateAfterDelete;           // Navegar tras eliminar
final Widget? header;                     // Widget de cabecera opcional
```

**Características**:
- **Agrupamiento automático**: Por fecha (Hoy, Mañana, Ayer, o fecha formateada)
- **Ordenamiento**: Por fecha y hora de inicio
- **Headers de fecha**: Con estilo consistente
- **Estado vacío**: Integrado con EmptyState
- **Scroll automático**: Al evento más próximo

**Uso**:
```dart
EventsList(
  events: allEvents,
  onEventTap: (event) => _navigateToDetail(event),
  onDelete: _deleteEvent,
  navigateAfterDelete: false,
  header: Text('Próximos eventos', style: headerStyle),
)
```

**Agrupamiento de fechas**:
```dart
// Hoy → "Hoy"
// Mañana → "Mañana"
// Ayer → "Ayer"
// Otra fecha → "Lunes, 3 de noviembre"
```

---

### 4. EventActions

**Botones de Acción para Eventos**

```dart
class EventActions extends StatelessWidget
```

**Propósito**: Componente de acciones contextuales para eventos (editar, eliminar, invitar).

**Ubicación**: `lib/widgets/event_actions.dart`

**Parámetros**:
```dart
final Event event;                          // Evento
final VoidCallback? onDelete;               // Callback eliminar
final VoidCallback? onEdit;                 // Callback editar
final VoidCallback? onInvite;               // Callback invitar
final VoidCallback? onDeleteSeries;         // Callback eliminar serie
final VoidCallback? onEditSeries;           // Callback editar serie
final bool isCompact;                       // Vista compacta (default: false)
final bool navigateAfterDelete;             // Navegar tras eliminar
```

**Características**:

**Eventos simples**:
- ✏️ Editar
- 🗑️ Eliminar
- 👥 Invitar (si tiene permisos)

**Eventos recurrentes**:
- ✏️ Editar instancia / Editar serie
- 🗑️ Eliminar instancia / Eliminar serie

**Modos de visualización**:
```dart
// Modo completo (botones con texto)
EventActions(
  event: event,
  onEdit: _edit,
  onDelete: _delete,
  isCompact: false,
)

// Modo compacto (solo iconos)
EventActions(
  event: event,
  onEdit: _edit,
  onDelete: _delete,
  isCompact: true,
)
```

**Confirmaciones integradas**:
- Diálogo de confirmación al eliminar
- Opciones diferenciadas para series recurrentes

---

### 5. EventDetailActions

**Acciones en Pantalla de Detalle**

```dart
class EventDetailActions extends StatelessWidget
```

**Propósito**: Botones de acción específicos para pantalla de detalle de evento.

**Ubicación**: `lib/widgets/event_detail_actions.dart`

**Parámetros**:
```dart
final bool isEventOwner;     // Si el usuario es propietario
final bool canInvite;        // Si puede invitar usuarios
final VoidCallback onEdit;   // Callback editar
final VoidCallback onInvite; // Callback invitar
```

**Uso**:
```dart
EventDetailActions(
  isEventOwner: true,
  canInvite: true,
  onEdit: () => _navigateToEdit(),
  onInvite: () => _navigateToInvite(),
)
```

**Botones mostrados**:
- **Owner**: Editar + Invitar
- **Admin**: Invitar
- **Otros**: Sin botones

---

### 6. EventActionSection

**Sección Completa de Acciones**

```dart
class EventActionSection extends ConsumerStatefulWidget
```

**Propósito**: Sección completa de acciones y opciones en detalle de evento.

**Ubicación**: `lib/widgets/event_detail/event_action_section.dart`

**Parámetros**:
```dart
final Event event;                // Evento
final VoidCallback? onEventUpdated; // Callback actualización
final VoidCallback? onEventDeleted; // Callback eliminación
```

**Características**:

**Para Owner**:
- Botones Editar e Invitar
- Sección de cancelación de evento:
  - Switch "Enviar notificación de cancelación"
  - Campo de texto para mensaje
  - Botón "Cancelar evento"

**Para No-Owner**:
- Botones de participación (si aplica)
- Botón "Remover de mi lista"

**Uso**:
```dart
EventActionSection(
  event: event,
  onEventUpdated: () => _refreshEvent(),
  onEventDeleted: () => Navigator.pop(context),
)
```

---

### 7. EventDateHeader

**Cabecera de Fecha para Grupos**

```dart
class EventDateHeader extends StatelessWidget
```

**Propósito**: Header visual para agrupar eventos por fecha.

**Ubicación**: `lib/widgets/event_date_header.dart`

**Parámetros**:
```dart
final String text; // Texto de fecha (ej: "Hoy", "Mañana", "Lunes, 3 de nov")
```

**Uso**:
```dart
EventDateHeader(text: 'Hoy')
EventDateHeader(text: 'Lunes, 3 de noviembre')
```

**Estilo**:
- Texto en gris, tamaño 14
- Padding vertical de 8px
- Fondo transparente
- Mayúsculas para "HOY", "MAÑANA", "AYER"

---

### 8. EventLocationFields

**Campos de Ubicación de Evento**

```dart
class EventLocationFields extends StatelessWidget
```

**Propósito**: Grupo de campos para seleccionar ubicación del evento.

**Ubicación**: `lib/widgets/event_location_fields.dart`

**Parámetros**:
```dart
final String? city;                           // Ciudad actual
final String? countryCode;                    // Código de país
final String? timezone;                       // Timezone actual
final Function(String?) onCityChanged;        // Callback ciudad
final Function(String?) onCountryChanged;     // Callback país
final Function(String?) onTimezoneChanged;    // Callback timezone
final bool enabled;                           // Habilitado (default: true)
final bool isRequired;                        // Requerido (default: false)
```

**Campos incluidos**:
1. **País**: Selector con bandera
2. **Ciudad**: Búsqueda de ciudades
3. **Timezone**: Selector de zona horaria

**Uso**:
```dart
EventLocationFields(
  city: _city,
  countryCode: _countryCode,
  timezone: _timezone,
  onCityChanged: (city) => setState(() => _city = city),
  onCountryChanged: (country) => setState(() => _countryCode = country),
  onTimezoneChanged: (tz) => setState(() => _timezone = tz),
  isRequired: true,
)
```

**Extensión con helpers**:
```dart
extension EventLocationFieldsExtension on EventLocationFields {
  String? validateCity() { ... }
  String? validateCountry() { ... }
  String formatLocation() { ... }
}
```

---

## Widgets de UI Adaptativo

### 1. AdaptiveApp

**Wrapper de Aplicación Adaptativo**

```dart
class AdaptiveApp extends StatelessWidget
```

**Propósito**: Wrapper raíz de la app que se adapta a iOS/Material Design.

**Ubicación**: `lib/widgets/adaptive_app.dart`

**Parámetros**:
```dart
final String title;                                    // Título de la app
final Widget? home;                                    // Home widget
final Map<String, WidgetBuilder>? routes;             // Rutas nombradas
final RouterConfig<Object>? routerConfig;             // Configuración de router
final Locale? locale;                                  // Locale actual
final Iterable<Locale> supportedLocales;              // Locales soportados
final Iterable<LocalizationsDelegate> localizationsDelegates; // Delegados i18n
final ThemeData? theme;                                // Tema Material
final CupertinoThemeData? cupertinoTheme;             // Tema Cupertino
```

**Uso**:
```dart
AdaptiveApp(
  title: 'EventyPop',
  routerConfig: router,
  locale: currentLocale,
  supportedLocales: [
    Locale('en'),
    Locale('es'),
    Locale('ca'),
  ],
  localizationsDelegates: [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
)
```

**Detección de plataforma**:
- iOS → `CupertinoApp`
- Android/otros → `MaterialApp`

---

### 2. AdaptiveScaffold

**Scaffold con Navegación Inferior**

```dart
class AdaptiveScaffold extends StatelessWidget
```

**Propósito**: Scaffold adaptativo con bottom navigation bar.

**Ubicación**: `lib/widgets/adaptive_scaffold.dart`

**Parámetros**:
```dart
final Widget body;                              // Contenido principal
final String? title;                            // Título (opcional)
final List<AdaptiveNavigationItem> navigationItems; // Items de navegación
final int currentIndex;                         // Índice activo
final ValueChanged<int> onNavigationChanged;    // Callback navegación
final List<Widget>? actions;                    // Acciones de toolbar
final Widget? floatingActionButton;             // FAB
final Widget? leading;                          // Widget inicial
```

**AdaptiveNavigationItem**:
```dart
class AdaptiveNavigationItem {
  final IconData icon;           // Icono
  final String label;            // Etiqueta
  final IconData? activeIcon;    // Icono activo (opcional)
}
```

**Uso típico**:
```dart
AdaptiveScaffold(
  body: _pages[_currentIndex],
  navigationItems: [
    AdaptiveNavigationItem(
      icon: CupertinoIcons.calendar,
      label: 'Eventos',
      activeIcon: CupertinoIcons.calendar_badge_plus,
    ),
    AdaptiveNavigationItem(
      icon: CupertinoIcons.person_2,
      label: 'Contactos',
    ),
  ],
  currentIndex: _currentIndex,
  onNavigationChanged: (index) => setState(() => _currentIndex = index),
)
```

---

**AdaptivePageScaffold** (sin navegación inferior)

```dart
class AdaptivePageScaffold extends StatelessWidget
```

**Propósito**: Scaffold simple sin bottom navigation (para pantallas secundarias).

**Parámetros**:
```dart
final Widget body;              // Contenido
final String? title;            // Título
final List<Widget>? actions;    // Acciones
final Widget? leading;          // Widget inicial
final Widget? floatingActionButton; // FAB
```

**Uso**:
```dart
AdaptivePageScaffold(
  title: 'Detalle',
  body: _buildContent(),
  actions: [
    IconButton(icon: Icon(Icons.share), onPressed: _share)
  ],
)
```

---

### 3. AdaptiveButton

**Botón Adaptativo Multi-Variante**

```dart
class AdaptiveButton extends StatelessWidget implements IButtonWidget
```

**Propósito**: Botón adaptativo con múltiples variantes y estados.

**Ubicación**: `lib/widgets/adaptive/adaptive_button.dart`

**Parámetros**:
```dart
final AdaptiveButtonConfig config;   // Configuración
final VoidCallback? onPressed;        // Callback
final String? text;                   // Texto del botón
final IconData? icon;                 // Icono
final bool isLoading;                 // Estado de carga
final bool enabled;                   // Habilitado
```

**AdaptiveButtonConfig**:
```dart
class AdaptiveButtonConfig {
  final ButtonVariant variant;    // primary, secondary, text, icon, fab
  final ButtonSize size;           // small, medium, large
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;
  final EdgeInsets? padding;
  final IconPosition iconPosition; // left, right, only
  final bool fullWidth;
}
```

**Variantes**:
- `primary`: Botón principal con fondo
- `secondary`: Botón secundario con borde
- `text`: Botón de texto sin fondo
- `icon`: Solo icono
- `fab`: Floating action button

**Factories predefinidos** (via extensión):
```dart
// Botones comunes
AdaptiveButtonConfig.destructive()  // Rojo, para eliminar
AdaptiveButtonConfig.submit()       // Verde, para guardar
AdaptiveButtonConfig.cancel()       // Gris, para cancelar

// Tamaños
AdaptiveButtonConfig.small()
AdaptiveButtonConfig.large()

// Especiales
AdaptiveButtonConfig.iconOnly()
AdaptiveButtonConfig.floatingAction()
AdaptiveButtonConfig.link()
```

**Ejemplos de uso**:
```dart
// Botón primario
AdaptiveButton(
  config: AdaptiveButtonConfig(variant: ButtonVariant.primary),
  text: 'Guardar',
  icon: CupertinoIcons.checkmark,
  onPressed: _save,
)

// Botón destructivo
AdaptiveButton(
  config: AdaptiveButtonConfig.destructive(),
  text: 'Eliminar',
  icon: CupertinoIcons.trash,
  onPressed: _delete,
)

// FAB
AdaptiveButton(
  config: AdaptiveButtonConfig.floatingAction(),
  icon: CupertinoIcons.add,
  onPressed: _create,
)

// Con estado de carga
AdaptiveButton(
  config: AdaptiveButtonConfig.submit(),
  text: 'Guardando...',
  isLoading: _isLoading,
  onPressed: _save,
)
```

---

### 4. AdaptiveCard

**Tarjeta Adaptativa Multi-Variante**

```dart
class AdaptiveCard extends StatelessWidget implements ICardWidget
```

**Propósito**: Tarjeta adaptativa con múltiples estilos predefinidos.

**Ubicación**: `lib/widgets/adaptive/adaptive_card.dart`

**Parámetros**:
```dart
final AdaptiveCardConfig config;      // Configuración
final Widget child;                    // Contenido
final VoidCallback? onTap;             // Callback tap
final bool selectable;                 // Si es seleccionable
final bool selected;                   // Estado seleccionado
final ValueChanged<bool>? onSelectionChanged; // Callback selección
```

**AdaptiveCardConfig**:
```dart
class AdaptiveCardConfig {
  final CardVariant variant;       // simple, listItem, selectable, elevated
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final double? elevation;
  final Border? border;
}
```

**Factories predefinidos**:
```dart
// Básicos
AdaptiveCardConfig.simple()       // Card simple
AdaptiveCardConfig.listItem()     // Item de lista
AdaptiveCardConfig.selectable()   // Card seleccionable
AdaptiveCardConfig.elevated()     // Card con elevación

// Específicos
AdaptiveCardConfig.contact()      // Card de contacto
AdaptiveCardConfig.event()        // Card de evento

// Extensiones adicionales
AdaptiveCardConfig.floating()     // Card flotante
AdaptiveCardConfig.compact()      // Card compacto
AdaptiveCardConfig.action()       // Card de acción
AdaptiveCardConfig.modal()        // Card para modal
AdaptiveCardConfig.subtle()       // Card sutil
AdaptiveCardConfig.media()        // Card con media
AdaptiveCardConfig.notification() // Card de notificación
AdaptiveCardConfig.dashboard()    // Card de dashboard
AdaptiveCardConfig.settings()     // Card de settings
```

**Uso**:
```dart
// Card simple
AdaptiveCard(
  config: AdaptiveCardConfig.simple(),
  child: Text('Contenido'),
  onTap: _handleTap,
)

// Card seleccionable
AdaptiveCard(
  config: AdaptiveCardConfig.selectable(),
  selectable: true,
  selected: _isSelected,
  onSelectionChanged: (selected) => setState(() => _isSelected = selected),
  child: ListTile(title: Text('Item')),
)

// Card elevado personalizado
AdaptiveCard(
  config: AdaptiveCardConfig(
    variant: CardVariant.elevated,
    backgroundColor: Colors.blue.shade50,
    borderRadius: 16,
    elevation: 8,
  ),
  child: _buildContent(),
)
```

---

### 5. AdaptiveTextField

**Campo de Texto con Validación**

```dart
class AdaptiveTextField extends StatefulWidget implements ITextFieldWidget
```

**Propósito**: Campo de texto adaptativo con validación integrada.

**Ubicación**: `lib/widgets/adaptive/adaptive_text_field.dart`

**Parámetros**:
```dart
final AdaptiveTextFieldConfig config;           // Configuración
final TextEditingController? controller;         // Controlador
final String? placeholder;                       // Placeholder
final List<Validator>? validators;              // Validadores
final ValidationState? validationState;          // Estado de validación
final ValueChanged<ValidationState>? onValidationChanged;
final ValueChanged<String>? onTextChanged;
final String? Function(String?)? customValidator; // Validador custom
```

**AdaptiveTextFieldConfig**:
```dart
class AdaptiveTextFieldConfig {
  final TextFieldVariant variant;      // standard, limited, multiline, email, phone, password
  final TextInputType? keyboardType;
  final int? maxLength;
  final int? maxLines;
  final bool obscureText;
  final ValidationMode validationMode;  // none, onChanged, onSubmitted, onFocusLost
  final EdgeInsets? padding;
  final IconData? prefixIcon;
  final Widget? suffix;
}
```

**Presets predefinidos**:
```dart
AdaptiveTextFieldConfig.username
AdaptiveTextFieldConfig.passwordField
AdaptiveTextFieldConfig.confirmPassword
AdaptiveTextFieldConfig.firstName
AdaptiveTextFieldConfig.lastName
AdaptiveTextFieldConfig.phoneNumber
AdaptiveTextFieldConfig.eventTitle
AdaptiveTextFieldConfig.eventDescription
AdaptiveTextFieldConfig.address
AdaptiveTextFieldConfig.zipCode
AdaptiveTextFieldConfig.searchField
AdaptiveTextFieldConfig.comment
```

**Factories via extensión**:
```dart
AdaptiveTextFieldConfig.name()        // Nombre
AdaptiveTextFieldConfig.search()      // Búsqueda
AdaptiveTextFieldConfig.url()         // URL
AdaptiveTextFieldConfig.number()      // Número
AdaptiveTextFieldConfig.description() // Descripción multi-línea
AdaptiveTextFieldConfig.comment()     // Comentario
AdaptiveTextFieldConfig.limitedText(int maxLength) // Texto limitado
```

**Validadores disponibles**:
```dart
RequiredValidator()
EmailValidator()
MinLengthValidator(int minLength)
MaxLengthValidator(int maxLength)
PhoneValidator()
PasswordValidator()
RegexValidator(String pattern, String message)
CompositeValidator([validator1, validator2])
```

**Uso**:
```dart
// Campo de email con validación
AdaptiveTextField(
  config: AdaptiveTextFieldConfig(
    variant: TextFieldVariant.email,
    validationMode: ValidationMode.onChanged,
  ),
  placeholder: 'Email',
  controller: _emailController,
  validators: [
    RequiredValidator(),
    EmailValidator(),
  ],
  onValidationChanged: (state) {
    setState(() => _emailValid = state.isValid);
  },
)

// Campo de contraseña
AdaptiveTextField(
  config: AdaptiveTextFieldConfig.passwordField,
  placeholder: 'Contraseña',
  controller: _passwordController,
  validators: [
    RequiredValidator(),
    MinLengthValidator(8),
    PasswordValidator(), // Valida mayúscula, número, símbolo
  ],
)

// Campo con preset
AdaptiveTextField(
  config: AdaptiveTextFieldConfig.eventTitle,
  controller: _titleController,
  placeholder: 'Título del evento',
)
```

---

### 6. PlatformTheme

**Temas Adaptativos**

```dart
class PlatformTheme
```

**Propósito**: Proporciona temas y estilos adaptativos según plataforma.

**Ubicación**: `lib/widgets/adaptive/platform_theme.dart`

**Propiedades**:
```dart
final bool isIOS;
final bool isDark;
final Color primaryColor;
final Color backgroundColor;
final Color secondaryColor;
final Color errorColor;
final Color surfaceColor;
final Color dividerColor;
final double cardElevation;
final double defaultBorderRadius;
final double buttonHeight;
final double textFieldHeight;
final TextStyle textStyle;
final EdgeInsets defaultPadding;
```

**Factory**:
```dart
PlatformTheme.adaptive(BuildContext context)
```

**Uso**:
```dart
final theme = PlatformTheme.adaptive(context);

Container(
  decoration: BoxDecoration(
    color: theme.surfaceColor,
    borderRadius: BorderRadius.circular(theme.defaultBorderRadius),
  ),
  padding: theme.defaultPadding,
  child: Text('Hola', style: theme.textStyle),
)
```

---

### 7. Validation Framework

**Framework de Validación Reutilizable**

**Ubicación**: `lib/widgets/adaptive/validation_framework.dart`

**Validadores disponibles**:

**RequiredValidator**:
```dart
RequiredValidator(message: 'Campo requerido')
```

**EmailValidator**:
```dart
EmailValidator(message: 'Email inválido')
```

**MinLengthValidator**:
```dart
MinLengthValidator(8, message: 'Mínimo 8 caracteres')
```

**MaxLengthValidator**:
```dart
MaxLengthValidator(100, message: 'Máximo 100 caracteres')
```

**PhoneValidator**:
```dart
PhoneValidator(message: 'Teléfono inválido')
```

**PasswordValidator**:
```dart
PasswordValidator(
  requireUppercase: true,
  requireNumber: true,
  requireSpecialChar: true,
  message: 'Contraseña debe contener mayúscula, número y símbolo'
)
```

**RegexValidator**:
```dart
RegexValidator(
  r'^[a-zA-Z0-9]+$',
  message: 'Solo letras y números'
)
```

**CompositeValidator** (combinar múltiples):
```dart
CompositeValidator([
  RequiredValidator(),
  MinLengthValidator(8),
  MaxLengthValidator(50),
])
```

**Uso en campos**:
```dart
AdaptiveTextField(
  validators: [
    RequiredValidator(),
    EmailValidator(),
  ],
  validationMode: ValidationMode.onChanged,
)
```

---

## Widgets de Formulario

### 1. CustomDateTimeWidget

**Selector de Fecha/Hora con Scroll**

```dart
class CustomDateTimeWidget extends StatefulWidget
```

**Propósito**: Selector personalizado de fecha y hora con scroll horizontal.

**Ubicación**: `lib/widgets/custom_datetime_widget.dart`

**Parámetros**:
```dart
final DateTime initialDateTime;         // Fecha/hora inicial
final String timezone;                  // Zona horaria
final ValueChanged<DateTime> onDateTimeChanged; // Callback
final Locale locale;                    // Idioma
final bool showTimePicker;              // Mostrar selector de hora (default: true)
final bool showTodayButton;             // Mostrar botón "Hoy" (default: true)
```

**Características**:
- **3 scrollers horizontales**: Mes, Día, Hora
- **Intervalos de 15 minutos**: 00, 15, 30, 45
- **Filtra horas pasadas**: Para el día actual
- **Botón "Hoy"**: Vuelve rápido a hoy
- **Localización**: Nombres de meses y días según locale

**Uso**:
```dart
CustomDateTimeWidget(
  initialDateTime: DateTime.now(),
  timezone: 'Europe/Madrid',
  locale: Locale('es'),
  showTimePicker: true,
  showTodayButton: true,
  onDateTimeChanged: (dateTime) {
    setState(() => _selectedDateTime = dateTime);
  },
)
```

**Comportamiento**:
- Si selecciona hoy, filtra horas pasadas
- Si selecciona otra fecha, muestra todas las horas
- Scrollea automáticamente a la selección inicial

---

### 2. CountryTimezoneSelector

**Selector de País/Ciudad/Timezone**

```dart
class CountryTimezoneSelector extends StatefulWidget
```

**Propósito**: Selector completo de ubicación con país, ciudad y zona horaria.

**Ubicación**: `lib/widgets/country_timezone_selector.dart`

**Parámetros**:
```dart
final String? initialCountry;           // Código de país inicial
final String? initialTimezone;          // Timezone inicial
final String? initialCity;              // Ciudad inicial
final Function(Country, String, String) onChanged; // Callback (country, timezone, city)
final bool showOffset;                  // Mostrar offset GMT (default: true)
final String? label;                    // Etiqueta opcional
```

**Características**:
- **Banderas de países**: Visualización con emojis
- **Búsqueda de ciudades**: Modal con buscador
- **Múltiples timezones**: Por país
- **Offset GMT**: Visualización de diferencia horaria
- **Cascada**: Selección de país → ciudad → timezone

**Uso**:
```dart
CountryTimezoneSelector(
  initialCountry: 'ES',
  initialTimezone: 'Europe/Madrid',
  initialCity: 'Madrid',
  showOffset: true,
  label: 'Ubicación del evento',
  onChanged: (country, timezone, city) {
    setState(() {
      _country = country;
      _timezone = timezone;
      _city = city;
    });
  },
)
```

**Flujo de selección**:
1. Usuario toca para abrir modal
2. Selecciona país de la lista (con banderas)
3. Si país tiene múltiples timezones, abre selector de ciudad
4. Callback con los 3 valores

---

### 3. LanguageSelector

**Selector de Idioma**

```dart
class LanguageSelector extends ConsumerWidget
```

**Propósito**: Selector de idioma de la aplicación.

**Ubicación**: `lib/widgets/language_selector.dart`

**Características**:
- Lista de idiomas disponibles con banderas
- Marca idioma actual seleccionado
- Integrado con `localeNotifierProvider` de Riverpod
- Cambio en tiempo real de idioma

**Idiomas soportados**:
- 🇪🇸 Español
- 🇬🇧 Inglés
- 🇪🇸 Catalán

**Uso**:
```dart
LanguageSelector()
```

**No requiere parámetros** - usa provider para estado global.

---

### 4. RecurrenceTimeSelector

**Selector de Hora para Recurrencia**

```dart
class RecurrenceTimeSelector extends StatelessWidget
```

**Propósito**: Selector de hora específico para patrones de recurrencia.

**Ubicación**: `lib/widgets/recurrence_time_selector.dart`

**Parámetros**:
```dart
final TimeOfDay initialTime;            // Hora inicial
final ValueChanged<TimeOfDay> onSelected; // Callback
final int minuteInterval;               // Intervalo de minutos (default: 5)
final int startHour;                    // Hora inicio (default: 0)
final int endHour;                      // Hora fin (default: 23)
final String? label;                    // Etiqueta
final IconData? icon;                   // Icono
```

**Características**:
- Formato 24 horas
- Scroll horizontal
- Auto-scroll a hora seleccionada
- Intervalos configurables de minutos

**Uso**:
```dart
RecurrenceTimeSelector(
  initialTime: TimeOfDay(hour: 9, minute: 0),
  minuteInterval: 15,
  startHour: 8,
  endHour: 20,
  label: 'Hora del recordatorio',
  icon: CupertinoIcons.clock,
  onSelected: (time) {
    setState(() => _selectedTime = time);
  },
)
```

---

### 5. RecurringEventToggle

**Switch de Evento Recurrente**

```dart
class RecurringEventToggle extends StatelessWidget
```

**Propósito**: Switch para activar/desactivar recurrencia de evento.

**Ubicación**: `lib/widgets/recurring_event_toggle.dart`

**Parámetros**:
```dart
final bool value;                       // Estado actual
final ValueChanged<bool> onChanged;     // Callback
final String? labelText;                // Texto etiqueta
final String? helperText;               // Texto de ayuda
final bool enabled;                     // Habilitado (default: true)
```

**Uso**:
```dart
RecurringEventToggle(
  value: _isRecurring,
  labelText: 'Evento recurrente',
  helperText: 'Crea múltiples instancias del evento',
  enabled: true,
  onChanged: (value) {
    setState(() => _isRecurring = value);
  },
)
```

---

### 6. HorizontalSelectorWidget

**Selector Horizontal Genérico**

```dart
class HorizontalSelectorWidget<T> extends StatefulWidget
```

**Propósito**: Selector horizontal genérico reutilizable para cualquier tipo.

**Ubicación**: `lib/widgets/horizontal_selector_widget.dart`

**Parámetros**:
```dart
final List<SelectorOption<T>> options;  // Opciones
final ValueChanged<T> onSelected;       // Callback
final T? selectedValue;                 // Valor seleccionado
final String? label;                    // Etiqueta
final IconData? icon;                   // Icono
final double itemHeight;                // Altura item (default: 50)
final EdgeInsets itemPadding;           // Padding item
final EdgeInsets itemMargin;            // Margin item
final String? emptyMessage;             // Mensaje vacío
final bool autoScrollToSelected;        // Auto-scroll (default: true)
```

**SelectorOption**:
```dart
class SelectorOption<T> {
  final T value;            // Valor
  final String label;       // Etiqueta
  final String? subtitle;   // Subtítulo opcional
  final Color? color;       // Color de resaltado
  final bool enabled;       // Habilitado (default: true)
}
```

**Uso**:
```dart
HorizontalSelectorWidget<String>(
  options: [
    SelectorOption(value: 'es', label: 'Español', subtitle: 'España'),
    SelectorOption(value: 'en', label: 'English', subtitle: 'UK'),
    SelectorOption(value: 'ca', label: 'Català', subtitle: 'Catalunya'),
  ],
  selectedValue: _selectedLanguage,
  label: 'Idioma',
  icon: CupertinoIcons.globe,
  onSelected: (value) => setState(() => _selectedLanguage = value),
)
```

---

### 7. CalendarHorizontalSelector

**Selector de Calendarios**

```dart
class CalendarHorizontalSelector extends ConsumerWidget
```

**Propósito**: Wrapper especializado de HorizontalSelectorWidget para calendarios.

**Ubicación**: `lib/widgets/calendar_horizontal_selector.dart`

**Parámetros**:
```dart
final int? selectedCalendarId;          // ID del calendario seleccionado
final ValueChanged<int> onCalendarSelected; // Callback
```

**Características**:
- Obtiene calendarios de `calendarsStreamProvider`
- Muestra nombre y color de cada calendario
- Incluye indicador de calendario público/privado

**Uso**:
```dart
CalendarHorizontalSelector(
  selectedCalendarId: _selectedCalendarId,
  onCalendarSelected: (calendarId) {
    setState(() => _selectedCalendarId = calendarId);
  },
)
```

---

### 8. TimezoneHorizontalSelector

**Selector de Timezone en Cascada**

```dart
class TimezoneHorizontalSelector extends StatefulWidget
```

**Propósito**: Selector de país y timezone con dos niveles.

**Ubicación**: `lib/widgets/timezone_horizontal_selector.dart`

**Parámetros**:
```dart
final String? initialCountryCode;       // País inicial
final String? initialTimezone;          // Timezone inicial
final Function(String, String) onChanged; // Callback (countryCode, timezone)
```

**Características**:
- **Primer nivel**: Selector de países con banderas
- **Segundo nivel**: Selector de timezones/ciudades del país seleccionado
- **Cascada automática**: Al cambiar país, actualiza timezones
- **Visualización**: Muestra offset GMT

**Uso**:
```dart
TimezoneHorizontalSelector(
  initialCountryCode: 'ES',
  initialTimezone: 'Europe/Madrid',
  onChanged: (countryCode, timezone) {
    setState(() {
      _countryCode = countryCode;
      _timezone = timezone;
    });
  },
)
```

---

### 9-11. Pickers (Modales)

**CitySearchPickerModal** (`pickers/city_search_picker.dart`)

```dart
Future<City?> showCitySearchPicker(
  BuildContext context, {
  String? countryCode,  // Filtrar por país
})
```

**Características**:
- Búsqueda en tiempo real
- Filtro por país opcional
- Muestra bandera, nombre, timezone

**Uso**:
```dart
final city = await showCitySearchPicker(
  context,
  countryCode: 'ES',
);
if (city != null) {
  print('Ciudad seleccionada: ${city.name}');
}
```

---

**CountryPickerModal** (`pickers/country_picker.dart`)

```dart
Future<Country?> showCountryPicker(BuildContext context)
```

**Características**:
- Lista completa de países
- Búsqueda por nombre
- Banderas, nombre, timezone con offset

**Uso**:
```dart
final country = await showCountryPicker(context);
if (country != null) {
  print('País: ${country.name}');
  print('Timezone: ${country.timezone}');
}
```

---

## Widgets de Visualización

### 1. EmptyState

**Estado Vacío Genérico**

```dart
class EmptyState extends StatelessWidget
```

**Propósito**: Componente de estado vacío reutilizable.

**Ubicación**: `lib/widgets/empty_state.dart`

**Parámetros**:
```dart
final String message;                   // Mensaje principal (requerido)
final String? subtitle;                 // Subtítulo opcional
final String? imagePath;                // Ruta a imagen
final IconData? icon;                   // Icono (alternativo a imagen)
final double imageSize;                 // Tamaño imagen/icono (default: 80)
final VoidCallback? onAction;           // Callback de acción
final String? actionLabel;              // Texto del botón
```

**Uso**:
```dart
// Con icono
EmptyState(
  icon: CupertinoIcons.calendar,
  message: 'No hay eventos',
  subtitle: 'Crea tu primer evento para comenzar',
  actionLabel: 'Crear evento',
  onAction: () => _navigateToCreate(),
)

// Con imagen
EmptyState(
  imagePath: 'assets/images/empty_calendar.png',
  message: 'Tu calendario está vacío',
  imageSize: 120,
)

// Simple
EmptyState(
  icon: CupertinoIcons.search,
  message: 'No se encontraron resultados',
)
```

**Variantes comunes**:
- Sin eventos
- Sin resultados de búsqueda
- Sin conexión
- Sin permisos
- Lista vacía

---

### 2. UserAvatar

**Avatar de Usuario**

```dart
class UserAvatar extends ConsumerWidget
```

**Propósito**: Avatar de usuario con carga de imagen y fallback.

**Ubicación**: `lib/widgets/user_avatar.dart`

**Parámetros**:
```dart
final User user;                        // Usuario (requerido)
final double radius;                    // Radio del avatar (default: 20)
final bool showOnlineIndicator;         // Indicador online (default: false)
```

**Características**:
- **Carga desde cache local o red**
- **Fallback a iniciales**: Con color generado del nombre
- **Placeholder**: Durante carga
- **Indicador online**: Punto verde si está activo

**Generación de color**:
```dart
// Color único basado en hash del nombre
final color = ColorGenerator.fromString(user.displayName);
```

**Uso**:
```dart
// Avatar pequeño
UserAvatar(
  user: user,
  radius: 16,
)

// Avatar grande con indicador
UserAvatar(
  user: user,
  radius: 40,
  showOnlineIndicator: true,
)

// En lista
ListTile(
  leading: UserAvatar(user: user),
  title: Text(user.displayName),
)
```

---

### 3. UserGroupAvatar

**Avatar de Grupo**

```dart
class UserGroupAvatar extends StatelessWidget
```

**Propósito**: Avatar para grupos (icono con fondo de color).

**Ubicación**: `lib/widgets/user_group_avatar.dart`

**Parámetros**:
```dart
final IconData icon;                    // Icono (default: person_2)
final Color color;                      // Color de fondo
final double size;                      // Tamaño (default: 40)
```

**Uso**:
```dart
UserGroupAvatar(
  icon: CupertinoIcons.person_3,
  color: Colors.blue,
  size: 48,
)
```

---

### 4. ContactCard

**Tarjeta de Contacto**

```dart
class ContactCard extends StatelessWidget
```

**Propósito**: Card para mostrar contactos en listas.

**Ubicación**: `lib/widgets/contact_card.dart`

**Parámetros**:
```dart
final User contact;                     // Contacto (requerido)
final VoidCallback? onTap;              // Callback tap
```

**Contenido**:
- Avatar del contacto
- Nombre (displayName)
- Subtítulo (displaySubtitle: email o teléfono)
- Chevron de navegación

**Uso**:
```dart
ListView.builder(
  itemCount: contacts.length,
  itemBuilder: (context, index) {
    return ContactCard(
      contact: contacts[index],
      onTap: () => _showContactDetail(contacts[index]),
    );
  },
)
```

---

### 5. GroupCard

**Tarjeta de Grupo**

```dart
class GroupCard extends StatelessWidget
```

**Propósito**: Card para mostrar grupos en listas.

**Ubicación**: `lib/widgets/group_card.dart`

**Parámetros**:
```dart
final Group group;                      // Grupo (requerido)
final int? partiallyInvitedCount;      // Contador de invitados parciales
final VoidCallback? onTap;              // Callback tap
final bool isSelected;                  // Estado seleccionado (default: false)
```

**Contenido**:
- Avatar circular con icono de grupo
- Nombre del grupo
- Descripción
- Contador de miembros
- Badge "parcialmente invitado" (si aplica)

**Uso**:
```dart
GroupCard(
  group: group,
  partiallyInvitedCount: 3,
  isSelected: _selectedGroupId == group.id,
  onTap: () => _selectGroup(group),
)
```

---

### 6. SubscriptionCard

**Tarjeta de Suscripción**

```dart
class SubscriptionCard extends ConsumerWidget
```

**Propósito**: Card para mostrar suscripciones a usuarios públicos.

**Ubicación**: `lib/widgets/subscription_card.dart`

**Parámetros**:
```dart
final User user;                        // Usuario público (requerido)
final VoidCallback? onTap;              // Callback tap
final VoidCallback? onDelete;           // Callback eliminar
final Widget? customAvatar;             // Avatar personalizado
final String? customTitle;              // Título personalizado
final String? customSubtitle;           // Subtítulo personalizado
```

**Contenido**:
- Avatar con iniciales
- Nombre del usuario
- Subtítulo con estadísticas:
  - "X eventos nuevos"
  - "Y eventos totales"
  - "Z suscriptores"
- Botón eliminar suscripción

**Uso**:
```dart
SubscriptionCard(
  user: publicUser,
  onTap: () => _showUserEvents(publicUser),
  onDelete: () => _unsubscribe(publicUser),
)
```

---

### 7. BaseCard

**Card Base Genérica**

```dart
class BaseCard extends StatelessWidget
```

**Propósito**: Card genérica reutilizable.

**Ubicación**: `lib/widgets/base_card.dart`

**Parámetros**:
```dart
final Widget child;                     // Contenido
final VoidCallback? onTap;              // Callback tap
final EdgeInsets? margin;               // Margen
final EdgeInsets? padding;              // Padding
final double? elevation;                // Elevación
final Color? backgroundColor;           // Color de fondo
final BorderRadius? borderRadius;       // Radio de borde
```

**Uso**:
```dart
BaseCard(
  margin: EdgeInsets.all(16),
  padding: EdgeInsets.all(12),
  elevation: 2,
  borderRadius: BorderRadius.circular(12),
  onTap: _handleTap,
  child: Column(
    children: [
      Text('Título'),
      Text('Contenido'),
    ],
  ),
)
```

---

### 8-10. Styled Containers

**StyledContainer** (`styled_container.dart`)

```dart
class StyledContainer extends StatelessWidget
```

**Propósito**: Container con estilos predefinidos.

**Parámetros**: `child`, `padding`, `color`, `borderRadius`, `boxShadow`, `border`

**Uso**:
```dart
StyledContainer(
  padding: EdgeInsets.all(16),
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  child: Text('Contenido'),
)
```

---

**ConfigurableStyledContainer** (`common/configurable_styled_container.dart`)

```dart
class ConfigurableStyledContainer extends StatelessWidget
```

**Propósito**: Container con variantes predefinidas.

**Variantes**:
- `header`: Con gradiente azul
- `card`: Tarjeta estándar
- `info`: Fondo azul claro

**Factories**:
```dart
ConfigurableStyledContainer.header(child: Widget)
ConfigurableStyledContainer.card(child: Widget)
ConfigurableStyledContainer.info(child: Widget)
```

**Uso**:
```dart
ConfigurableStyledContainer.header(
  child: Text('Cabecera', style: TextStyle(color: Colors.white)),
)

ConfigurableStyledContainer.card(
  child: _buildCardContent(),
)
```

---

**SectionHeader** (en mismo archivo)

```dart
class SectionHeader extends StatelessWidget
```

**Propósito**: Cabecera de sección con icono, título y subtítulo.

**Parámetros**:
```dart
final IconData icon;                    // Icono
final String title;                     // Título
final String? subtitle;                 // Subtítulo opcional
final Color? iconColor;                 // Color del icono
```

**Uso**:
```dart
SectionHeader(
  icon: CupertinoIcons.settings,
  title: 'Configuración',
  subtitle: 'Gestiona tus preferencias',
  iconColor: Colors.blue,
)
```

---

### 11. SelectableCard

**Tarjeta Seleccionable**

```dart
class SelectableCard extends StatelessWidget
```

**Propósito**: Card seleccionable con checkbox.

**Ubicación**: `lib/widgets/selectable_card.dart`

**Parámetros**:
```dart
final String title;                     // Título
final String? subtitle;                 // Subtítulo
final IconData? icon;                   // Icono
final Color? color;                     // Color del avatar
final bool selected;                    // Estado seleccionado
final VoidCallback? onTap;              // Callback tap
final ValueChanged<bool>? onChanged;    // Callback cambio
```

**Contenido**:
- Avatar circular con icono
- Título + subtítulo
- Checkbox personalizado (checked/unchecked)

**Uso**:
```dart
SelectableCard(
  title: 'Juan Pérez',
  subtitle: 'juan@example.com',
  icon: CupertinoIcons.person,
  color: Colors.blue,
  selected: _selectedUsers.contains(userId),
  onTap: () => _toggleSelection(userId),
  onChanged: (selected) => _updateSelection(userId, selected),
)
```

---

## Widgets Especializados

### 1. RecurrencePatternList

**Lista de Patrones de Recurrencia**

```dart
class RecurrencePatternList extends StatefulWidget
```

**Propósito**: Gestionar lista completa de patrones de recurrencia.

**Ubicación**: `lib/widgets/recurrence_pattern_list.dart`

**Parámetros**:
```dart
final List<RecurrencePattern> patterns;  // Lista de patrones
final ValueChanged<List<RecurrencePattern>> onPatternsChanged; // Callback
final bool enabled;                      // Habilitado (default: true)
final int? eventId;                      // ID del evento
```

**Características**:
- **Header**: Con contador de patrones
- **Lista de PatternCard**: Un card por patrón
- **Botón agregar**: Para nuevo patrón
- **Estado vacío**: Mensaje cuando no hay patrones
- **Integración**: Con PatternEditDialog
- **Confirmación**: Al eliminar patrón

**Uso**:
```dart
RecurrencePatternList(
  patterns: _recurrencePatterns,
  enabled: true,
  eventId: eventId,
  onPatternsChanged: (patterns) {
    setState(() => _recurrencePatterns = patterns);
  },
)
```

---

### 2. PatternCard

**Tarjeta de Patrón de Recurrencia**

```dart
class PatternCard extends StatelessWidget
```

**Propósito**: Mostrar un patrón de recurrencia individual.

**Ubicación**: `lib/widgets/pattern_card.dart`

**Parámetros**:
```dart
final RecurrencePattern pattern;        // Patrón (requerido)
final VoidCallback? onEdit;             // Callback editar
final VoidCallback? onDelete;           // Callback eliminar
final bool enabled;                     // Habilitado (default: true)
final bool showActions;                 // Mostrar botones (default: true)
```

**Contenido**:
- Icono de recurrencia (🔄)
- Día de la semana formateado (ej: "Lunes")
- Hora formateada (ej: "09:00")
- Botones: Editar ✏️ / Eliminar 🗑️

**Uso**:
```dart
PatternCard(
  pattern: pattern,
  onEdit: () => _editPattern(pattern),
  onDelete: () => _deletePattern(pattern),
  showActions: true,
)
```

---

### 3. PatternEditDialog

**Diálogo de Edición de Patrón**

```dart
class PatternEditDialog extends StatefulWidget
```

**Propósito**: Modal para crear/editar patrón de recurrencia.

**Ubicación**: `lib/widgets/pattern_edit_dialog.dart`

**Parámetros**:
```dart
final RecurrencePattern? pattern;       // Patrón existente (null = nuevo)
final int? eventId;                     // ID del evento
```

**Contenido**:
- **Selector de día**: Picker o scroll horizontal
- **Selector de hora**: Time picker adaptativo
- **Botones**: Cancelar / Guardar

**Características**:
- Ajusta hora a intervalos de 5 minutos
- Validación de datos
- Estilos adaptativos iOS/Material

**Uso**:
```dart
// Crear nuevo
final newPattern = await showDialog<RecurrencePattern>(
  context: context,
  builder: (context) => PatternEditDialog(
    eventId: eventId,
  ),
);

// Editar existente
final updatedPattern = await showDialog<RecurrencePattern>(
  context: context,
  builder: (context) => PatternEditDialog(
    pattern: existingPattern,
    eventId: eventId,
  ),
);
```

---

### 4. PersonalNoteWidget

**Widget de Nota Personal**

```dart
class PersonalNoteWidget extends ConsumerStatefulWidget
```

**Propósito**: Añadir/editar/eliminar nota personal en evento.

**Ubicación**: `lib/widgets/personal_note_widget.dart`

**Parámetros**:
```dart
final Event event;                      // Evento (requerido)
final VoidCallback? onEventUpdated;     // Callback actualización
```

**Estados**:
1. **Sin nota**: Botón "Agregar nota personal"
2. **Con nota**: Vista de nota + botones Editar/Eliminar
3. **Editando**: Campo de texto + Cancelar/Guardar

**Características**:
- Integración con API
- Confirmación al eliminar
- Estados de carga (spinner)
- Prevención de sobrescritura durante edición

**Uso**:
```dart
PersonalNoteWidget(
  event: event,
  onEventUpdated: () => _refreshEvent(),
)
```

**Flujo**:
```
Sin nota → [Agregar] → Editando → [Guardar] → Con nota
                                ↓ [Cancelar]
                              Sin nota
Con nota → [Editar] → Editando
        → [Eliminar + Confirmar] → Sin nota
```

---

### 5. ConfirmationActionWidget

**Wrapper de Confirmación**

```dart
class ConfirmationActionWidget extends StatefulWidget
```

**Propósito**: Añade confirmación a cualquier widget.

**Ubicación**: `lib/widgets/confirmation_action_widget.dart`

**Parámetros**:
```dart
final Widget child;                     // Widget hijo (se hace tappable)
final String dialogTitle;               // Título del diálogo
final String dialogMessage;             // Mensaje del diálogo
final String actionText;                // Texto botón confirmación
final Future<void> Function() onAction; // Callback async
final bool isDestructive;               // Acción destructiva (default: false)
```

**Uso**:
```dart
ConfirmationActionWidget(
  dialogTitle: 'Eliminar evento',
  dialogMessage: '¿Estás seguro de eliminar este evento?',
  actionText: 'Eliminar',
  isDestructive: true,
  onAction: () async {
    await _deleteEvent();
  },
  child: Icon(
    CupertinoIcons.trash,
    color: Colors.red,
  ),
)
```

**Comportamiento**:
1. Usuario toca el child
2. Muestra diálogo de confirmación
3. Si confirma, ejecuta onAction
4. Muestra loading durante ejecución
5. Cierra diálogo al completar

---

### 6. ContactsPermissionDialog

**Diálogo de Permisos de Contactos**

```dart
class ContactsPermissionDialog extends StatefulWidget
```

**Propósito**: Solicitar permiso de acceso a contactos del dispositivo.

**Ubicación**: `lib/widgets/contacts_permission_dialog.dart`

**Parámetros**:
```dart
final VoidCallback? onPermissionGranted;   // Callback si acepta
final VoidCallback? onPermissionDenied;    // Callback si rechaza
```

**Contenido**:
- Explicación de privacidad
- Bullets de beneficios:
  - "Encuentra amigos fácilmente"
  - "Invita contactos a eventos"
  - "Tus datos están seguros"
- Botones: "Ahora no" / "Permitir acceso"

**Características**:
- Redirección a settings si es necesario
- Manejo de estados de carga
- Explicación clara de uso de datos

**Uso**:
```dart
showDialog(
  context: context,
  builder: (context) => ContactsPermissionDialog(
    onPermissionGranted: () {
      _loadContacts();
    },
    onPermissionDenied: () {
      _showManualAddOption();
    },
  ),
)
```

---

### 7. AppInitializer

**Inicializador de App** (Legacy)

```dart
class AppInitializer extends StatelessWidget
```

**Propósito**: Widget inicializador (ahora simplificado).

**Ubicación**: `lib/widgets/app_initializer.dart`

**Nota**: En versiones anteriores inicializaba repositorios. Ahora solo pasa el child directamente. La inicialización se hace en SplashScreen.

**Uso actual**:
```dart
AppInitializer(
  child: MyApp(),
)
```

---

## Patrones de Diseño

### 1. Sistema de Configuración

**Concepto**: Los widgets complejos usan clases de configuración separadas.

**Widgets que lo implementan**:
- `EventCard` → `EventCardConfig`
- `AdaptiveButton` → `AdaptiveButtonConfig`
- `AdaptiveCard` → `AdaptiveCardConfig`
- `AdaptiveTextField` → `AdaptiveTextFieldConfig`

**Beneficios**:
- **Separación de concerns**: Configuración vs. lógica
- **Factories predefinidos**: Configuraciones comunes reutilizables
- **Composición**: Fácil combinar configs
- **Testabilidad**: Configs son objetos simples

**Ejemplo**:
```dart
// Sin config (malo)
EventCard(
  event: event,
  showNewBadge: true,
  showCalendarBadge: true,
  showRecurringBadge: event.isRecurring,
  showInvitationBanner: event.hasInvitation,
  // ... 10 parámetros más
)

// Con config (bueno)
EventCard(
  event: event,
  config: EventCardConfig.invitation(), // Factory predefinido
)

// Config personalizado
EventCard(
  event: event,
  config: EventCardConfig(
    showNewBadge: true,
    showCalendarBadge: true,
  ),
)
```

---

### 2. Adaptive Pattern

**Concepto**: Widgets se adaptan automáticamente a la plataforma (iOS/Material).

**Implementación**:
```dart
class AdaptiveButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (PlatformDetection.isIOS) {
      return _buildCupertinoButton();
    }
    return _buildMaterialButton();
  }
}
```

**Widgets adaptativos**:
- `AdaptiveApp`
- `AdaptiveScaffold`
- `AdaptiveButton`
- `AdaptiveCard`
- `AdaptiveTextField`
- `AdaptivePageScaffold`

**Detección de plataforma**:
```dart
class PlatformDetection {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
}
```

---

### 3. Composición

**Concepto**: Widgets complejos se descomponen en subcomponentes especializados.

**Ejemplo: EventCard**

```
EventCard
├── EventCardHeader
│   ├── InvitationBanner
│   ├── OwnerAvatar
│   └── AttendeesList
├── EventCardContent
│   ├── Title
│   ├── DateTime
│   └── Location
├── EventCardBadges
│   ├── NewBadge
│   ├── CalendarBadge
│   ├── BirthdayBadge
│   └── RecurringBadge
└── EventCardActions
    ├── AcceptRejectButtons
    ├── DeleteButton
    └── Chevron
```

**Beneficios**:
- **Modularidad**: Cada componente tiene una responsabilidad
- **Reutilización**: Los subcomponentes son reutilizables
- **Testabilidad**: Cada parte se puede testear independientemente
- **Mantenibilidad**: Cambios localizados

---

### 4. Validación Reutilizable

**Framework**: `validation_framework.dart`

**Conceptos**:
- **Validadores componibles**: Combinar múltiples validadores
- **Modos de validación**: onChanged, onSubmitted, onFocusLost
- **Estado de validación**: valid, invalid, pending

**Uso**:
```dart
AdaptiveTextField(
  validators: [
    RequiredValidator(),
    EmailValidator(),
  ],
  validationMode: ValidationMode.onChanged,
  onValidationChanged: (state) {
    if (state.isValid) {
      _enableSubmitButton();
    }
  },
)
```

**Validadores custom**:
```dart
class MinAgeValidator extends Validator {
  final int minAge;

  MinAgeValidator(this.minAge);

  @override
  ValidationResult validate(String? value) {
    if (value == null) return ValidationResult.invalid('Required');

    final date = DateTime.tryParse(value);
    if (date == null) return ValidationResult.invalid('Invalid date');

    final age = DateTime.now().difference(date).inDays ~/ 365;
    if (age < minAge) {
      return ValidationResult.invalid('Must be $minAge+');
    }

    return ValidationResult.valid();
  }
}
```

---

### 5. Selectores Genéricos

**Widget base**: `HorizontalSelectorWidget<T>`

**Concepto**: Selector horizontal genérico para cualquier tipo.

**Especializaciones**:
- `CalendarHorizontalSelector` → `HorizontalSelectorWidget<Calendar>`
- Futuro: `UserHorizontalSelector` → `HorizontalSelectorWidget<User>`

**Beneficios**:
- **DRY**: Un componente para múltiples casos de uso
- **Type-safe**: Usa genéricos de Dart
- **Consistencia**: UI idéntica para todos los selectores

**Crear nuevo selector**:
```dart
class LanguageHorizontalSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HorizontalSelectorWidget<String>(
      options: [
        SelectorOption(value: 'es', label: 'Español'),
        SelectorOption(value: 'en', label: 'English'),
      ],
      selectedValue: _selectedLanguage,
      onSelected: (lang) => _changeLanguage(lang),
    );
  }
}
```

---

## Guía de Uso

### Cuándo Usar Cada Widget

#### Para Mostrar Eventos:

**Lista simple**:
```dart
ListView.builder(
  itemBuilder: (context, index) {
    return EventListItem(
      event: events[index],
      onTap: _navigateToDetail,
    );
  },
)
```

**Lista agrupada por fecha**:
```dart
EventsList(
  events: allEvents,
  onEventTap: _navigateToDetail,
)
```

**Card personalizada**:
```dart
EventCard(
  event: event,
  config: EventCardConfig(
    showNewBadge: true,
    showChevron: false,
  ),
)
```

---

#### Para Formularios:

**Botón de acción**:
```dart
AdaptiveButton(
  config: AdaptiveButtonConfig.submit(),
  text: 'Guardar',
  onPressed: _save,
)
```

**Campo de texto simple**:
```dart
AdaptiveTextField(
  config: AdaptiveTextFieldConfig.eventTitle,
  controller: _titleController,
  placeholder: 'Título',
)
```

**Campo con validación**:
```dart
AdaptiveTextField(
  config: AdaptiveTextFieldConfig(
    variant: TextFieldVariant.email,
    validationMode: ValidationMode.onChanged,
  ),
  validators: [RequiredValidator(), EmailValidator()],
)
```

**Selector de fecha**:
```dart
CustomDateTimeWidget(
  initialDateTime: DateTime.now(),
  timezone: 'Europe/Madrid',
  onDateTimeChanged: (dt) => _updateDate(dt),
)
```

**Selector de ubicación**:
```dart
CountryTimezoneSelector(
  initialCountry: 'ES',
  onChanged: (country, tz, city) => _updateLocation(),
)
```

---

#### Para Estados Vacíos:

```dart
// Sin resultados de búsqueda
EmptyState(
  icon: CupertinoIcons.search,
  message: 'No se encontraron resultados',
  subtitle: 'Intenta con otros términos',
)

// Sin datos con CTA
EmptyState(
  icon: CupertinoIcons.calendar,
  message: 'No hay eventos',
  actionLabel: 'Crear evento',
  onAction: _navigateToCreate,
)
```

---

#### Para Confirmaciones:

```dart
ConfirmationActionWidget(
  dialogTitle: 'Eliminar',
  dialogMessage: '¿Seguro?',
  actionText: 'Eliminar',
  isDestructive: true,
  onAction: () async => _delete(),
  child: Icon(CupertinoIcons.trash),
)
```

---

### Best Practices

#### 1. Usa Factories Predefinidos

```dart
// ❌ Malo
AdaptiveButtonConfig(
  variant: ButtonVariant.primary,
  backgroundColor: Colors.red,
  foregroundColor: Colors.white,
)

// ✅ Bueno
AdaptiveButtonConfig.destructive()
```

---

#### 2. Reutiliza Widgets Existentes

```dart
// ❌ Malo: Crear widget custom para cada lista
class MyCustomEventList extends StatelessWidget { ... }

// ✅ Bueno: Usar EventsList con configuración
EventsList(
  events: myEvents,
  onEventTap: _handleTap,
)
```

---

#### 3. Composición sobre Herencia

```dart
// ❌ Malo
class MyEventCard extends EventCard { ... }

// ✅ Bueno
EventCard(
  event: event,
  config: EventCardConfig(...),
)
```

---

#### 4. Validación Centralizada

```dart
// ❌ Malo: Validación inline
String? _validateEmail(String? value) {
  if (value == null || !value.contains('@')) {
    return 'Email inválido';
  }
  return null;
}

// ✅ Bueno: Usar validadores reutilizables
AdaptiveTextField(
  validators: [RequiredValidator(), EmailValidator()],
)
```

---

#### 5. Estados de Carga

```dart
// ✅ Usa isLoading en botones
AdaptiveButton(
  text: _isLoading ? 'Guardando...' : 'Guardar',
  isLoading: _isLoading,
  onPressed: _save,
)

// ✅ Muestra placeholders durante carga
if (_isLoading) {
  return CupertinoActivityIndicator();
}
return EventsList(events: _events);
```

---

## Estadísticas

- **Total de widgets**: 48
- **Widgets de eventos**: 12 (25%)
- **Widgets adaptativos**: 7 (15%)
- **Widgets de formulario**: 11 (23%)
- **Widgets de visualización**: 11 (23%)
- **Widgets especializados**: 7 (14%)

**Widgets más usados** (aparecen en 5+ pantallas):
1. `EventCard` / `EventListItem` (13 pantallas)
2. `AdaptiveButton` (todas las pantallas)
3. `AdaptiveScaffold` / `AdaptivePageScaffold` (todas las pantallas)
4. `EmptyState` (10 pantallas)
5. `UserAvatar` (8 pantallas)

**Complejidad**:
- **Simple** (<100 líneas): 18 widgets (37%)
- **Media** (100-300 líneas): 22 widgets (46%)
- **Compleja** (>300 líneas): 8 widgets (17%)

---

**Última actualización**: 2025-11-03
**Versión de la app**: 1.0.0
