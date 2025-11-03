# SplashScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/splash_screen.dart`
**Líneas**: 307
**Tipo**: ConsumerStatefulWidget with TickerProviderStateMixin
**Propósito**: Pantalla inicial de la aplicación que muestra el logo animado mientras inicializa todos los repositorios, verifica permisos y asegura que existe el calendario de cumpleaños

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **AdaptivePageScaffold** (línea 205)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_page_scaffold.md`

**Uso**: Scaffold principal con `title: null` (sin barra de navegación)

#### **AdaptiveButton** (línea 286)
**Archivo**: `lib/widgets/adaptive/adaptive_button.dart`
**Documentación**: `lib/widgets_md/adaptive_button.md`

**Uso**: Botón "Reintentar" visible solo cuando hay error (_hasError == true)
**Configuración**: `config: AdaptiveButtonConfigExtended.submit()`

**Total de widgets propios**: 2 (AdaptivePageScaffold, AdaptiveButton)

**Características especiales**:
- 3 AnimationControllers (fade, scale, pulse)
- Timer de seguridad de 10 segundos
- Inicialización en paralelo de 5 repositorios
- Garantiza calendario de cumpleaños
- Duración mínima de 2 segundos para UX suave

---

## 3. CLASE Y PROPIEDADES

### SplashScreen (líneas 15-22)
Widget principal que extiende `ConsumerStatefulWidget`

**Propiedades**:
- `nextScreen` (Widget?, optional): Pantalla a la que navegar después de la inicialización (fallback si falla GoRouter)

### _SplashScreenState (líneas 24-306)
Estado del widget que gestiona la lógica de la pantalla. Implementa `TickerProviderStateMixin` para animaciones múltiples

**Propiedades de instancia - Animaciones**:
- `_fadeController` (AnimationController, late): Controla animación de fade in
- `_scaleController` (AnimationController, late): Controla animación de escala
- `_pulseController` (AnimationController, late): Controla animación de pulso
- `_fadeAnimation` (Animation<double>, late): Animación de opacidad (0.0 → 1.0)
- `_scaleAnimation` (Animation<double>, late): Animación de escala (0.8 → 1.0)
- `_pulseAnimation` (Animation<double>, late): Animación de pulso (1.0 → 1.05)
- `_safetyTimer` (Timer?): Timer de seguridad que navega después de 10 segundos si algo falla

**Propiedades de instancia - Estado**:
- `_statusMessage` (String): Mensaje de estado actual mostrado al usuario
- `_isLoading` (bool): Si está en proceso de carga
- `_hasError` (bool): Si ocurrió un error
- `_errorMessage` (String): Mensaje de error a mostrar

## 3. CICLO DE VIDA

### initState() (líneas 39-78)
1. Llama a `super.initState()`
2. **PostFrameCallback** (líneas 42-50):
   - Espera al primer frame
   - Si está montado:
     - Obtiene localizaciones
     - Actualiza `_statusMessage` con "Iniciando EventyPop"
     - Llama a `_initializeApp()`
3. **Inicializa controllers de animación**:
   - `_fadeController`: 1000ms de duración
   - `_scaleController`: 800ms de duración
   - `_pulseController`: 2000ms de duración
4. **Configura animaciones**:
   - `_fadeAnimation`: Tween de 0.0 a 1.0 con curva easeIn
   - `_scaleAnimation`: Tween de 0.8 a 1.0 con curva elasticOut
   - `_pulseAnimation`: Tween de 1.0 a 1.05 con curva easeInOut
5. **Inicia animaciones**:
   - Ejecuta fade forward
   - Ejecuta scale forward
   - Después de 1200ms: inicia pulso en repeat con reverse
6. **Safety timer** (líneas 73-77):
   - Timer de 10 segundos
   - Si después de 10 segundos sigue loading: navega automáticamente
   - Previene que el usuario quede atascado en splash

### dispose() (líneas 80-87)
1. Limpia `_fadeController.dispose()`
2. Limpia `_scaleController.dispose()`
3. Limpia `_pulseController.dispose()`
4. Cancela `_safetyTimer` si existe
5. Llama a `super.dispose()`

## 4. MÉTODOS DE INICIALIZACIÓN

### _initializeApp() (líneas 89-137)
**Tipo de retorno**: `Future<void>`

**Propósito**: Inicializa toda la aplicación en secuencia con duración mínima garantizada

**Lógica**:
1. En bloque try-catch principal:
2. Obtiene localizaciones
3. Guarda tiempo de inicio
4. Define duración mínima de 2 segundos (para UX suave)
5. **Paso 1 - Inicializar repositorios** (líneas 97-98):
   - Actualiza status: "Cargando datos locales"
   - Llama a `_initializeRepositories()` (async)
6. **Paso 2 - Verificar permisos** (líneas 101-112):
   - Actualiza status: "Verificando permisos de contactos"
   - En try-catch interno:
     - Cancela safety timer
     - Si está montado:
       - Llama a `PermissionService.shouldShowContactsPermissionDialog()`
       - Si debe mostrar: marca como preguntado con `markContactsPermissionAsked()`
   - En catch: ignora error
7. **Paso 3 - Datos listos** (línea 115):
   - Actualiza status: "Datos actualizados"
8. **Asegurar duración mínima** (líneas 118-122):
   - Calcula tiempo transcurrido
   - Si fue menor a 2 segundos:
     - Calcula tiempo restante
     - Espera con `Future.delayed()`
   - Garantiza que splash se muestre mínimo 2 segundos (UX)
9. **Navegación** (línea 124):
   - Llama a `_navigateToNextScreen()`
10. En catch del bloque principal (líneas 125-136):
    - Actualiza estado: `_hasError = true`, `_isLoading = false`
    - Si está montado:
      - Construye mensaje de error: "Error al inicializar app: {error}"

### _initializeRepositories() (líneas 139-157)
**Tipo de retorno**: `Future<void>`

**Propósito**: Inicializa todos los repositorios en paralelo y asegura calendario de cumpleaños

**Lógica**:
1. En try-catch:
2. **Obtiene instancias de todos los repositorios** (líneas 142-146):
   - subscriptionRepositoryProvider
   - eventRepositoryProvider
   - userRepositoryProvider
   - calendarRepositoryProvider
   - groupRepositoryProvider
   - Nota: Al leer el provider, se dispara `initialize()` automáticamente
3. **Espera inicialización paralela** (línea 149):
   - Usa `Future.wait()` con array de `initialized` futures
   - Espera a que TODOS los repositorios completen su inicialización
   - Se ejecuta en paralelo (no secuencial)
4. **Asegura calendario de cumpleaños** (línea 152):
   - Llama a `_ensureBirthdayCalendar()`
   - Se ejecuta después de que repositorios están listos
5. En catch (líneas 153-156):
   - Imprime error
   - NO relaniza excepción
   - Continúa ejecución (repositorios pueden ser parcialmente funcionales)

### _ensureBirthdayCalendar() (líneas 159-171)
**Tipo de retorno**: `Future<void>`

**Propósito**: Crea el calendario de cumpleaños si no existe

**Lógica**:
1. En try-catch:
2. Obtiene `calendarRepositoryProvider`
3. Obtiene primer valor del stream de calendarios con `.first`
4. Verifica si existe calendario llamado "Cumpleaños" o "Birthdays"
5. Si NO existe:
   - Llama a `calendarRepository.createCalendar()` con:
     - name: "Cumpleaños"
     - description: "Calendario para cumpleaños"
6. En catch: ignora errores (no crítico)

## 5. MÉTODOS DE NAVEGACIÓN Y ESTADO

### _updateStatus(String message) (líneas 173-179)
**Tipo de retorno**: `void`

**Parámetros**:
- `message`: Mensaje de estado a mostrar

**Propósito**: Actualiza el mensaje de estado mostrado en la UI

**Lógica**:
- Si está montado: llama a `setState()` para actualizar `_statusMessage`

### _navigateToNextScreen() (líneas 181-191)
**Tipo de retorno**: `void`

**Propósito**: Navega a la pantalla principal de eventos

**Lógica**:
1. Verifica que esté montado
2. En try-catch:
   - Intenta navegar con GoRouter: `context.go('/events')`
3. En catch:
   - Si hay `widget.nextScreen` definido:
     - Navega con `Navigator.pushReplacement` y `PlatformNavigation.platformPageRoute`
   - Si no hay nextScreen: no hace nada (línea 188 vacía)

### _retry() (líneas 193-201)
**Tipo de retorno**: `void`

**Propósito**: Reintenta la inicialización después de un error

**Lógica**:
1. Llama a `setState()` para actualizar:
   - `_hasError = false`
   - `_isLoading = true`
   - `_statusMessage` = "Reintentando..."
2. Llama a `_initializeApp()` de nuevo

## 6. MÉTODO BUILD

### build(BuildContext context) (líneas 204-206)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la UI principal de la pantalla

**Lógica**:
- Retorna `AdaptivePageScaffold` con:
  - key: 'splash_screen_scaffold'
  - title: null (sin título)
  - body: llama a `_buildContent(context)`

### _buildContent(BuildContext context) (líneas 208-305)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `context`: BuildContext para acceder a localizaciones

**Propósito**: Construye el contenido animado del splash

**Estructura**:
SafeArea con Center y Padding (32px), contiene Column centrada con:

1. **Logo animado** (líneas 217-268): Triple AnimatedBuilder anidado:
   - **AnimatedBuilder 1** (líneas 217-221): Escala con `_scaleAnimation`
     - Transform.scale aplicando la animación de escala
   - **AnimatedBuilder 2** (líneas 222-226): Opacidad con `_fadeAnimation`
     - Opacity aplicando la animación de fade
   - **AnimatedBuilder 3** (líneas 227-261): Pulso con `_pulseAnimation`
     - Transform.scale aplicando la animación de pulso
     - Column con:
       - **Container del logo** (líneas 234-243):
         - 120x120
         - Degradado splash (definido en AppStyles)
         - Border radius 24px
         - Sombra negra con opacidad 0.1
         - Icono: calendario blanco (tamaño 60)
       - **Espaciador**: 24px
       - **Título** (líneas 247-250):
         - Texto: "EventyPop" (traducido)
         - Tamaño 32, bold, negro87
         - Letter spacing -0.5
       - **Espaciador**: 8px
       - **Subtítulo** (líneas 254-257):
         - Texto: "Tus eventos siempre contigo"
         - Tamaño 16, gris600, peso 500

2. **Espaciador**: 80px

3. **Estado condicional** (líneas 272-299):
   - **Si hay error** (`_hasError` es true) (líneas 272-286):
     - Icono: exclamationmark_triangle gris (tamaño 48)
     - Espaciador 16px
     - Título: "Oops, algo salió mal" (tamaño 18, peso 600, gris700)
     - Espaciador 8px
     - Mensaje de error centrado (tamaño 14, gris600)
     - Espaciador 24px
     - Botón "Reintentar" con key 'splash_screen_retry_button', llama a `_retry()`
   - **Si está cargando** (`_isLoading` es true) (líneas 287-298):
     - Center con indicador de carga adaptativo
     - Espaciador 24px
     - Mensaje de estado (tamaño 16, gris700, peso 500)
     - Espaciador 8px
     - Texto "Por favor espera" (tamaño 14, gris500)

## 7. DEPENDENCIAS

### Providers utilizados:
- `subscriptionRepositoryProvider`: Repositorio de suscripciones (read)
- `eventRepositoryProvider`: Repositorio de eventos (read)
- `userRepositoryProvider`: Repositorio de usuarios (read)
- `calendarRepositoryProvider`: Repositorio de calendarios (read)
- `groupRepositoryProvider`: Repositorio de grupos (read)

### Services:
- `PermissionService.shouldShowContactsPermissionDialog()`: Verifica si debe mostrar diálogo de permisos
- `PermissionService.markContactsPermissionAsked()`: Marca que ya se preguntó por permisos

### Widgets externos:
- `AnimationController`: Controladores de animación
- `Animation<double>`: Animaciones
- `Tween<double>`: Interpolación de valores
- `CurvedAnimation`: Animación con curva
- `AnimatedBuilder`: Builder que se reconstruye con animación
- `Transform.scale`: Transforma escala de widget
- `Opacity`: Controla opacidad de widget
- `Timer`: Timer para safety timeout

### Widgets internos:
- `AdaptivePageScaffold`: Scaffold adaptativo
- `AdaptiveButton`: Botón adaptativo

### Helpers:
- `PlatformWidgets.platformIcon()`: Icono adaptativo
- `PlatformWidgets.platformLoadingIndicator()`: Indicador de carga adaptativo
- `PlatformNavigation.platformPageRoute()`: Ruta de navegación adaptativa
- `context.l10n`: Acceso a localizaciones

### Navegación:
- `context.go()`: GoRouter
- `Navigator.pushReplacement()`: Navegación con replace

### Curvas de animación:
- `Curves.easeIn`: Fade in suave
- `Curves.elasticOut`: Escala con rebote elástico
- `Curves.easeInOut`: Pulso suave

### Localización:
Strings usados:
- `startingEventyPop`: "Iniciando EventyPop"
- `loadingLocalData`: "Cargando datos locales"
- `checkingContactsPermissions`: "Verificando permisos de contactos"
- `dataUpdated`: "Datos actualizados"
- `retrying`: "Reintentando..."
- `errorInitializingApp`: "Error al inicializar app"
- `appTitle`: "EventyPop"
- `yourEventsAlwaysWithYou`: "Tus eventos siempre contigo"
- `oopsSomethingWentWrong`: "Oops, algo salió mal"
- `retry`: "Reintentar"
- `pleaseWait`: "Por favor espera"

## 8. FLUJO DE DATOS

### Flujo de inicialización exitosa:
1. Usuario abre la app
2. `initState()` se ejecuta
3. Animaciones se configuran e inician
4. Safety timer de 10s se activa
5. `_initializeApp()` inicia después del primer frame
6. **Status**: "Iniciando EventyPop"
7. **Status**: "Cargando datos locales"
8. Inicializa 5 repositorios en paralelo
9. Espera a que todos completen
10. Crea calendario de cumpleaños si no existe
11. **Status**: "Verificando permisos de contactos"
12. Verifica y marca permisos si es necesario
13. Cancela safety timer
14. **Status**: "Datos actualizados"
15. Si fue muy rápido: espera hasta completar 2 segundos mínimo
16. Navega a `/events`
17. Safety timer cancelado

### Flujo de error:
1. Error en cualquier paso de inicialización
2. Catch captura el error
3. Actualiza: `_hasError = true`, `_isLoading = false`
4. Construye mensaje de error
5. UI muestra icono de error + mensaje + botón reintentar
6. Usuario presiona reintentar
7. `_retry()` resetea estado y reinicia proceso

### Flujo de safety timeout:
1. Si después de 10 segundos sigue cargando
2. Safety timer se dispara
3. Navega automáticamente a `/events`
4. Previene que usuario quede atascado

### Animaciones:
- **Fade**: 0s → 1s (0.0 → 1.0 opacity)
- **Scale**: 0s → 0.8s (0.8 → 1.0 scale)
- **Pulse**: 1.2s → infinito (1.0 → 1.05 → 1.0 loop)

## 9. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Inicialización de repositorios**: Carga todos los repositorios en paralelo
2. **Verificación de permisos**: Maneja permisos de contactos
3. **Creación de calendario**: Asegura calendario de cumpleaños
4. **Animaciones múltiples**: Fade, scale y pulse combinados
5. **Mensajes de estado**: Informa al usuario del progreso
6. **Duración mínima**: Garantiza mínimo 2 segundos (UX)
7. **Safety timeout**: 10 segundos máximo antes de navegar
8. **Manejo de errores**: Captura errores y permite reintentar
9. **Navegación automática**: Navega cuando todo está listo

### Estados manejados:
- **Loading**: Mostrando progreso con animaciones
- **Error**: Mostrando mensaje de error con botón reintentar
- Mensajes de estado: 5 diferentes durante la carga

### Repositorios inicializados:
1. SubscriptionRepository
2. EventRepository
3. UserRepository
4. CalendarRepository
5. GroupRepository

Todos se inicializan en **paralelo** con `Future.wait()`

### Garantías de UX:
- **Duración mínima**: 2 segundos (no se ve "flash" si es muy rápido)
- **Timeout máximo**: 10 segundos (no se queda atascado)
- **Animaciones suaves**: Combinación de 3 animaciones
- **Feedback visual**: Mensajes de estado + loading indicator
- **Recuperación de errores**: Botón para reintentar

## 10. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 307
**Métodos públicos**: 2 (build, dispose)
**Métodos privados**: 7
**Animation controllers**: 3
**Timers**: 1

**Distribución aproximada**:
- Imports: ~14 líneas (4.6%)
- Declaración de clase y propiedades: ~18 líneas (5.9%)
- initState: ~40 líneas (13.0%)
- dispose: ~8 líneas (2.6%)
- Inicialización de app: ~49 líneas (16.0%)
- Inicialización de repositorios: ~19 líneas (6.2%)
- Asegurar calendario: ~13 líneas (4.2%)
- Métodos auxiliares: ~30 líneas (9.8%)
- build method: ~3 líneas (1.0%)
- _buildContent method: ~98 líneas (31.9%)
- Resto: ~15 líneas (4.9%)

## 11. CARACTERÍSTICAS TÉCNICAS

### Triple animación anidada:
- Combina fade, scale y pulse
- AnimatedBuilder anidados (no es eficiente pero es visual)
- Cada animación con su controller y curva

### TickerProviderStateMixin:
- Necesario para múltiples AnimationControllers
- Proporciona tickers para cada animación

### Inicialización paralela:
- Usa `Future.wait()` para esperar múltiples futures
- Más rápido que secuencial
- Todos los repositorios se cargan simultáneamente

### Safety mechanisms:
1. **Safety timer**: Navega después de 10s si algo falla
2. **Minimum duration**: Garantiza 2s para UX suave
3. **Error handling**: Catch en cada nivel crítico
4. **Mounted checks**: Verifica que widget esté montado antes de setState

### Duración mínima inteligente:
- Solo espera si fue **muy rápido**
- Calcula tiempo transcurrido
- Espera solo el tiempo restante
- No agrega delay innecesario si fue lento

### Fallback de navegación:
- Intenta GoRouter primero
- Si falla: usa Navigator con nextScreen param
- Si no hay nextScreen: no hace nada (caso edge)

### Permission handling silencioso:
- Verifica si debe mostrar diálogo
- Marca como preguntado
- NO muestra diálogo en splash (se hará después)
- Errores son ignorados (no crítico)

### Calendar creation lazy:
- Solo crea si no existe
- Busca por nombre "Cumpleaños" o "Birthdays"
- Errores ignorados (no crítico)

### Keys para testing:
- 'splash_screen_scaffold': Scaffold principal
- 'splash_screen_retry_button': Botón de reintentar

### Repository initialization pattern:
- Leer provider dispara `initialize()` automáticamente
- Cada repositorio expone `Future<void> initialized`
- Pattern permite esperar inicialización sin reiniciar

### Animaciones con diferentes timings:
- Fade: 1000ms
- Scale: 800ms
- Pulse: 2000ms (loop)
- Pulse empieza después de 1200ms
- Crea efecto visual escalonado
