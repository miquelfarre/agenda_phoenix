# SettingsScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/settings_screen.dart`
**Líneas**: 230
**Tipo**: ConsumerWidget (sin estado)
**Propósito**: Pantalla de configuración que permite al usuario ajustar idioma, país/timezone, gestionar permisos de contactos y ver usuarios bloqueados

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **AdaptivePageScaffold** (línea 33)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_page_scaffold.md`

**Uso**: Scaffold principal de la pantalla con título "Configuración"

#### **LanguageSelector** (línea 48)
**Archivo**: `lib/widgets/language_selector.dart`
**Documentación**: Pendiente

**Uso**: Permite seleccionar idioma de la app

#### **CountryTimezoneSelector** (líneas 204-214)
**Archivo**: `lib/widgets/country_timezone_selector.dart`
**Documentación**: Pendiente

**Uso**: Selector de país, ciudad y timezone para eventos por defecto

#### **AdaptiveButton** (3 usos)
**Archivo**: `lib/widgets/adaptive/adaptive_button.dart`
**Documentación**: `lib/widgets_md/adaptive_button.md`

**Usos**:
1. **Línea 98**: Botón "Resetear preferencias de contactos" (secondary)
2. **Línea 110**: Botón "Abrir ajustes de la app" (secondary)
3. **Línea 177**: Botón "Usuarios bloqueados" (secondary)

#### **ConfigurableStyledContainer** (6 usos)
**Archivo**: `lib/widgets/common/configurable_styled_container.dart`
**Documentación**: Pendiente

**Usos**:
1. **Línea 74**: `.header()` para header de sección
2. **Línea 80**: `.card()` para sección de permisos
3. **Línea 126**: `.info()` para card informativo
4. **Línea 152**: `.card()` para sección de usuarios bloqueados
5. **Línea 216**: `.card()` para loading state
6. **Línea 221**: `.card()` para error state

**Total de widgets propios**: 5 (AdaptivePageScaffold, LanguageSelector, CountryTimezoneSelector, AdaptiveButton, ConfigurableStyledContainer)

---

## 3. ENUM Y CLASE

### SettingsSection (línea 21)
Enum que define las secciones de configuración disponibles

**Valores**:
- `general`: Configuración general
- `profile`: Perfil de usuario
- `privacy`: Privacidad
- `notifications`: Notificaciones

**Nota**: Actualmente solo se muestra la sección general, el enum está preparado para futuras expansiones

### SettingsScreen (líneas 23-229)
Widget principal que extiende `ConsumerWidget`

**Propiedades**:
- `initialSection` (SettingsSection, default: general): Sección inicial a mostrar (actualmente no se usa en la UI)

## 3. MÉTODO BUILD PRINCIPAL

### build(BuildContext context, WidgetRef ref) (líneas 29-38)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la UI principal de la pantalla

**Lógica**:
1. Detecta plataforma con `PlatformDetection.isIOS`
2. Obtiene localizaciones
3. Retorna `AdaptivePageScaffold` con:
   - key: 'settings_screen_scaffold'
   - title: "Configuración" (traducido)
   - body: llama a `_buildBody()` pasando context, ref, isIOS y l10n

## 4. CONSTRUCCIÓN DEL BODY

### _buildBody(BuildContext context, WidgetRef ref, {required bool isIOS, required dynamic l10n}) (líneas 40-71)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `context`: BuildContext
- `ref`: WidgetRef para acceder a providers
- `isIOS`: Si es plataforma iOS (actualmente no se usa)
- `l10n`: Localizaciones

**Propósito**: Construye el contenido scrollable de configuración

**Estructura**:
SafeArea con SingleChildScrollView (padding 16px) que contiene Column con:

1. **LanguageSelector** (línea 48):
   - Widget personalizado para seleccionar idioma

2. **Espaciador**: 24px

3. **Header de sección** (línea 51):
   - Icono: globo
   - Título: "País y zona horaria"
   - Subtitle: "Configuración por defecto para nuevos eventos"
   - Usa `_buildSectionHeader()`

4. **Espaciador**: 24px

5. **Selector de timezone** (línea 55):
   - Llama a `_buildTimezoneSelector()`
   - Pasa settingsAsync, ref y l10n

6. **Espaciador**: 24px

7. **Sección de usuarios bloqueados** (línea 58):
   - Llama a `_buildBlockedUsersSection()`

8. **Espaciador**: 24px

9. **Sección de permisos** (línea 62):
   - Llama a `_buildPermissionsSection()`

10. **Espaciador**: 24px

11. **Tarjeta informativa** (línea 66):
    - Llama a `_buildInfoCard()`

## 5. MÉTODOS DE CONSTRUCCIÓN DE SECCIONES

### _buildSectionHeader({required BuildContext context, required IconData icon, required String title, required String subtitle}) (líneas 73-77)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `context`: BuildContext
- `icon`: Icono para el header
- `title`: Título del header
- `subtitle`: Subtítulo descriptivo

**Propósito**: Construye un header de sección con estilo consistente

**Lógica**:
- Usa `ConfigurableStyledContainer.header()` con un `SectionHeader` child
- SectionHeader recibe icon, title y subtitle

### _buildPermissionsSection(BuildContext context, dynamic l10n) (líneas 79-123)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `context`: BuildContext
- `l10n`: Localizaciones

**Propósito**: Construye sección para gestionar permisos de contactos

**Estructura**:
`ConfigurableStyledContainer.card()` con Column que contiene:

1. **Header Row** (líneas 84-90):
   - Icono de candado (primary600)
   - Espaciador 8px
   - Text: "Permiso de contactos requerido"

2. **Espaciador**: 12px

3. **Descripción** (línea 92):
   - Text: Instrucciones sobre permisos de contactos
   - Estilo: bodyTextSmall, gris700

4. **Espaciador**: 12px

5. **Wrap de botones** (líneas 94-119):
   - spacing: 12px, runSpacing: 12px
   - **Botón 1** (líneas 98-109): "Resetear preferencias de permisos"
     - key: 'settings_reset_preferences_button'
     - Config: secundario
     - onPressed:
       - Llama a `PermissionService.resetContactsPermissionPreferences()`
       - Si está montado: muestra snackbar "Preferencias reseteadas"
   - **Botón 2** (líneas 110-117): "Abrir ajustes de app"
     - key: 'settings_open_app_settings_button'
     - Config: secundario
     - onPressed: llama a `openAppSettings()` (de permission_handler)

### _buildInfoCard(BuildContext context, dynamic l10n) (líneas 125-144)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `context`: BuildContext
- `l10n`: Localizaciones

**Propósito**: Construye tarjeta informativa sobre sincronización

**Estructura**:
`ConfigurableStyledContainer.info()` con Row que contiene:

1. **Icono** (línea 129):
   - CupertinoIcons.info
   - Color: primary600
   - Tamaño: 24

2. **Espaciador**: 16px

3. **Column expandida** (líneas 131-140):
   - **Título** (línea 135):
     - Text: "Información"
     - Estilo: cardTitle, primary800
   - **Espaciador**: 8px
   - **Mensaje** (línea 137):
     - Text: Mensaje sobre sincronización
     - Estilo: bodyTextSmall, primary700, height 1.4

### _buildBlockedUsersSection(BuildContext context, dynamic l10n) (líneas 146-197)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `context`: BuildContext
- `l10n`: Localizaciones

**Propósito**: Construye sección para gestionar usuarios bloqueados

**Estructura**:
Usa `Consumer` para observar `blockedUsersStreamProvider` (líneas 147-196):

1. **Calcula cantidad de bloqueados** (línea 150):
   - Usa `.when()` para manejar AsyncValue
   - data: retorna length de users
   - loading/error: retorna 0

2. **ConfigurableStyledContainer.card()** con Column:
   - **Header Row** (líneas 156-173):
     - Icono: person_badge_minus (rojo600)
     - Espaciador 8px
     - Text: "Usuarios bloqueados"
     - Si hay bloqueados (blockedCount > 0):
       - Espaciador 8px
       - Container badge con:
         - Padding (horizontal 8, vertical 4)
         - Fondo gris100, border radius pequeño
         - Text con cantidad (rojo600, peso 600)
   - **Espaciador**: 12px
   - **Descripción** (línea 175):
     - Text: "Gestiona usuarios bloqueados"
     - Estilo: bodyTextSmall, gris700
   - **Espaciador**: 12px
   - **Botón** (líneas 177-191):
     - key: 'settings_blocked_users_button'
     - Text: "Usuarios bloqueados"
     - Config: secundario
     - onPressed: Muestra `CupertinoAlertDialog` con:
       - Título: "Usuarios bloqueados"
       - Contenido: "Esta funcionalidad estará disponible pronto"
       - Botón OK que cierra el diálogo

### _buildTimezoneSelector(BuildContext context, AsyncValue<AppSettings> settingsAsync, WidgetRef ref, dynamic l10n) (líneas 199-228)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `context`: BuildContext
- `settingsAsync`: AsyncValue con la configuración del usuario
- `ref`: WidgetRef para actualizar settings
- `l10n`: Localizaciones

**Propósito**: Construye selector de país, timezone y ciudad

**Lógica**:
Usa `settingsAsync.when()` para manejar estados:

1. **data** (líneas 201-214):
   - Obtiene país con `CountryService.getCountryByCode(settings.defaultCountryCode)`
   - Retorna `CountryTimezoneSelector` con:
     - `initialCountry`: país obtenido
     - `initialTimezone`: timezone guardada en settings
     - `initialCity`: ciudad guardada en settings
     - `onChanged`: Callback que:
       - Crea nuevos settings con `copyWith()`
       - Actualiza via `settingsNotifierProvider.notifier.updateSettings()`
     - `showOffset`: true (muestra offset de timezone)
     - `label`: "País y zona horaria"

2. **loading** (líneas 216-220):
   - Retorna `ConfigurableStyledContainer.card()` con:
     - Center con `CupertinoActivityIndicator`
     - Padding de 16px

3. **error** (líneas 221-226):
   - Retorna `ConfigurableStyledContainer.card()` con:
     - Padding 16px
     - Text mostrando error en color rojo

## 6. DEPENDENCIAS

### Providers utilizados:
- `settingsNotifierProvider`: Provider de configuración del usuario (watch, read notifier)
- `blockedUsersStreamProvider`: Stream de usuarios bloqueados (watch)

### Services:
- `CountryService.getCountryByCode()`: Obtiene país por código
- `PermissionService.resetContactsPermissionPreferences()`: Resetea preferencias de permisos
- `openAppSettings()`: Abre ajustes de la app (de permission_handler package)

### Widgets externos:
- `SingleChildScrollView`: Scroll simple
- `Consumer`: Para observar providers adicionales
- `CupertinoActivityIndicator`: Indicador de carga
- `CupertinoAlertDialog`: Diálogo de alerta de iOS
- `CupertinoDialogAction`: Acción en diálogo

### Widgets internos:
- `AdaptivePageScaffold`: Scaffold adaptativo
- `LanguageSelector`: Selector de idioma personalizado
- `CountryTimezoneSelector`: Selector de país/timezone/ciudad
- `ConfigurableStyledContainer`: Contenedor con estilos predefinidos (card, header, info)
- `SectionHeader`: Header de sección (usado dentro de ConfigurableStyledContainer)
- `AdaptiveButton`: Botón adaptativo

### Helpers:
- `PlatformDetection.isIOS`: Detecta plataforma iOS
- `PlatformWidgets.platformIcon()`: Icono adaptativo
- `PlatformDialogHelpers.showSnackBar()`: Muestra snackbars
- `context.l10n`: Acceso a localizaciones

### Models:
- `AppSettings`: Modelo de configuración de la app

### Localización:
Strings usados:
- `settings`: Título de la pantalla
- `countryAndTimezone`: "País y zona horaria"
- `defaultSettingsForNewEvents`: "Configuración por defecto para nuevos eventos"
- `contactsPermissionRequired`: "Permiso de contactos requerido"
- `contactsPermissionInstructions`: Instrucciones sobre permisos
- `resetContactsPermissions`: "Resetear preferencias de permisos"
- `openAppSettings`: "Abrir ajustes de app"
- `resetPreferences`: "Preferencias reseteadas"
- `info`: "Información"
- `syncInfoMessage`: Mensaje sobre sincronización
- `blockedUsers`: "Usuarios bloqueados"
- `manageBlockedUsersDescription`: "Gestiona usuarios bloqueados"
- `seriesEditNotAvailable`: "Esta funcionalidad estará disponible pronto"
- `ok`: "OK"

## 7. FLUJO DE DATOS

### Al abrir la pantalla:
1. `build()` se ejecuta
2. Observa `settingsNotifierProvider`
3. Renderiza todas las secciones
4. `CountryTimezoneSelector` se inicializa con settings actuales

### Al cambiar país/timezone:
1. Usuario selecciona nuevo país, timezone o ciudad
2. Callback `onChanged` se ejecuta
3. Crea nueva instancia de settings con `copyWith()`
4. Llama a `settingsNotifierProvider.notifier.updateSettings()`
5. Provider actualiza settings y notifica
6. UI se reconstruye con nuevos valores

### Al resetear preferencias de permisos:
1. Usuario presiona botón "Resetear preferencias"
2. Llama a `PermissionService.resetContactsPermissionPreferences()`
3. Service resetea las preferencias guardadas
4. Muestra snackbar de confirmación
5. La próxima vez que se abra la app, volverá a pedir permisos

### Al abrir ajustes de app:
1. Usuario presiona botón "Abrir ajustes"
2. Llama a `openAppSettings()`
3. Sistema abre configuración de la app
4. Usuario puede cambiar permisos manualmente

### Al ver usuarios bloqueados:
1. Screen observa `blockedUsersStreamProvider`
2. Stream emite lista de usuarios bloqueados
3. Calcula cantidad con `.length`
4. Muestra badge con número si hay bloqueados
5. Usuario presiona botón (actualmente muestra diálogo "pronto disponible")

## 8. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Selector de idioma**: Cambia idioma de la app
2. **Selector de país/timezone**: Configura timezone por defecto para nuevos eventos
3. **Gestión de permisos**:
   - Resetear preferencias de permisos de contactos
   - Abrir ajustes de la app para cambiar permisos
4. **Usuarios bloqueados**:
   - Ver cantidad de usuarios bloqueados
   - Gestionar usuarios bloqueados (pendiente)
5. **Información**: Muestra info sobre sincronización

### Estados manejados:
- Settings (loading/data/error)
- Usuarios bloqueados (loading/data/error)

### Configuraciones guardadas:
- `defaultCountryCode`: Código del país (ej: "ES")
- `defaultTimezone`: Timezone (ej: "Europe/Madrid")
- `defaultCity`: Ciudad (ej: "Madrid")
- Idioma (gestionado por LanguageSelector)
- Preferencias de permisos (gestionado por PermissionService)

### Funcionalidades pendientes:
- **Gestión de usuarios bloqueados**: Muestra diálogo "pronto disponible"
- **Secciones adicionales**: El enum tiene profile, privacy, notifications pero no se usan

## 9. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 230
**Métodos**: 6 (1 build + 5 builders)
**Tipo**: ConsumerWidget (sin estado local)

**Distribución aproximada**:
- Imports: ~20 líneas (8.7%)
- Enum: ~1 línea (0.4%)
- Declaración de clase: ~3 líneas (1.3%)
- build method: ~10 líneas (4.3%)
- _buildBody method: ~32 líneas (13.9%)
- _buildSectionHeader method: ~5 líneas (2.2%)
- _buildPermissionsSection method: ~45 líneas (19.6%)
- _buildInfoCard method: ~20 líneas (8.7%)
- _buildBlockedUsersSection method: ~52 líneas (22.6%)
- _buildTimezoneSelector method: ~30 líneas (13.0%)
- Resto: ~12 líneas (5.2%)

## 10. CARACTERÍSTICAS TÉCNICAS

### ConsumerWidget sin estado:
- No usa StatefulWidget
- Todo el estado viene de providers
- Más simple y menos propenso a bugs de estado

### AsyncValue handling:
- Maneja loading/data/error apropiadamente
- Muestra loading indicator mientras carga settings
- Muestra error si falla la carga
- UI responsiva a cambios en settings

### ConfigurableStyledContainer:
- Usa contenedores predefinidos con estilos consistentes
- `.card()`: Tarjeta con estilo de card
- `.header()`: Header de sección
- `.info()`: Tarjeta informativa con estilo azul
- Mantiene consistencia visual en toda la app

### Reseteo de preferencias:
- `PermissionService.resetContactsPermissionPreferences()`
- Resetea solo las preferencias, no los permisos del sistema
- Útil para volver a mostrar diálogos de permisos

### Open app settings:
- Usa `openAppSettings()` de permission_handler package
- Abre la configuración de la app en el sistema
- Usuario puede cambiar permisos manualmente

### Mounted check:
- Verifica `context.mounted` después de operaciones async
- Previene errores si el widget fue desmontado

### Consumer anidado:
- Usa `Consumer` dentro del builder
- Permite observar providers adicionales sin rebuild completo
- Solo rebuild de la sección de usuarios bloqueados cuando cambia

### Keys para testing:
- 'settings_screen_scaffold': Scaffold principal
- 'settings_reset_preferences_button': Botón de resetear preferencias
- 'settings_open_app_settings_button': Botón de abrir ajustes
- 'settings_blocked_users_button': Botón de usuarios bloqueados

### Enum preparado para expansión:
- SettingsSection tiene 4 valores
- Actualmente solo se muestra general
- Preparado para agregar tabs de profile, privacy, notifications

### Badge dinámico:
- Muestra cantidad de usuarios bloqueados
- Solo visible si hay bloqueados (> 0)
- Estilo: fondo gris claro, texto rojo

### Wrap para botones:
- Usa `Wrap` con spacing para botones
- Se adapta a diferentes tamaños de pantalla
- Botones se envuelven a nueva línea si no caben
