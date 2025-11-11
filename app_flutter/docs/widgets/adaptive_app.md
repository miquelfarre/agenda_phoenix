# AdaptiveApp - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/adaptive_app.dart`
**Líneas**: 61
**Tipo**: StatelessWidget
**Propósito**: Widget raíz de la aplicación que crea una app adaptativa que se muestra como CupertinoApp en iOS y como WidgetsApp en otras plataformas, con soporte para navegación tradicional y GoRouter

## 2. CLASE Y PROPIEDADES

### AdaptiveApp (líneas 7-60)
Widget principal que extiende `StatelessWidget`

**Propiedades**:
- `appKey` (Key?, línea 8): Key opcional para la app raíz
- `title` (String, required, línea 9): Título de la aplicación
- `localizationsDelegates` (List<LocalizationsDelegate<dynamic>>, required, línea 10): Delegates de localización proporcionados por el usuario
- `supportedLocales` (List<Locale>, required, línea 11): Lista de locales soportados
- `locale` (Locale?, línea 12): Locale actual de la aplicación (nullable)
- `home` (Widget?, línea 13): Widget inicial de la app (solo para navegación tradicional)
- `routes` (Map<String, WidgetBuilder>?, línea 14): Mapa de rutas nombradas (solo para navegación tradicional)
- `routerConfig` (GoRouter?, línea 15): Configuración de GoRouter (solo para navegación con router)
- `debugShowCheckedModeBanner` (bool, línea 16): Muestra el banner de debug, default false

**Constructores**:

1. **Constructor tradicional** (línea 18):
```dart
const AdaptiveApp({
  super.key,
  this.appKey,
  required this.title,
  required this.localizationsDelegates,
  required this.supportedLocales,
  this.locale,
  this.home,
  this.routes,
  this.debugShowCheckedModeBanner = false
}) : routerConfig = null;
```
- Uso: navegación tradicional con home y routes
- Establece `routerConfig = null` en la lista de inicialización
- `home` y `routes` son opcionales

2. **Constructor con router** (línea 20):
```dart
const AdaptiveApp.router({
  super.key,
  this.appKey,
  required this.title,
  required this.localizationsDelegates,
  required this.supportedLocales,
  this.locale,
  required this.routerConfig,
  this.debugShowCheckedModeBanner = false
}) : home = null, routes = null;
```
- Uso: navegación declarativa con GoRouter
- Requiere `routerConfig`
- Establece `home = null` y `routes = null` en la lista de inicialización

**Patrón de diseño**: Usa named constructors para diferenciar entre navegación tradicional (.new) y navegación con router (.router)

## 3. MÉTODO BUILD

### Widget build(BuildContext context) (líneas 22-59)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la app raíz adaptándose a la plataforma y al tipo de navegación

**Lógica detallada**:

1. **Prepara delegates de localización** (línea 24):
   - Crea lista con delegates combinados:
     - `AppLocalizations.delegate`: Delegate personalizado de la app
     - `GlobalWidgetsLocalizations.delegate`: Widgets globales de Flutter
     - `GlobalCupertinoLocalizations.delegate`: Widgets de Cupertino globales
   - Los delegates del usuario (pasados como parámetro) no se usan directamente, se reemplazan por estos

2. **Caso: Navegación con router** (líneas 26-32):
   - Condición: `routerConfig != null`

   a) **iOS con router** (líneas 27-29):
      - Condición: `PlatformDetection.isIOS`
      - Retorna: `CupertinoApp.router` con:
        - key: `appKey`
        - title: `title`
        - localizationsDelegates: `delegates` (los 3 delegates preparados)
        - supportedLocales: `supportedLocales`
        - locale: `locale`
        - routerConfig: `routerConfig!` (force unwrap, se sabe que no es null)
        - debugShowCheckedModeBanner: `debugShowCheckedModeBanner`

   b) **Otras plataformas con router** (línea 31):
      - Retorna: `WidgetsApp.router` con:
        - key: `appKey`
        - color: `Color(0xFFFFFFFF)` (blanco)
        - title: `title`
        - localizationsDelegates: `delegates`
        - supportedLocales: `supportedLocales`
        - locale: `locale`
        - routerConfig: `routerConfig!`
        - debugShowCheckedModeBanner: `debugShowCheckedModeBanner`

3. **Caso: Navegación tradicional en iOS** (líneas 34-36):
   - Condición: `PlatformDetection.isIOS && routerConfig == null`
   - Retorna: `CupertinoApp` con:
     - key: `appKey`
     - title: `title`
     - localizationsDelegates: `delegates`
     - supportedLocales: `supportedLocales`
     - locale: `locale`
     - home: `home!` (force unwrap)
     - routes: `routes ?? const {}` (mapa vacío si routes es null)
     - debugShowCheckedModeBanner: `debugShowCheckedModeBanner`

4. **Caso: Navegación tradicional en otras plataformas** (líneas 38-58):
   - Condición: `!isIOS && routerConfig == null`
   - Retorna: `WidgetsApp` con:
     - key: `appKey` (línea 39)
     - color: `Color(0xFFFFFFFF)` (línea 40)
     - title: `title` (línea 41)
     - localizationsDelegates: `delegates` (línea 42)
     - supportedLocales: `supportedLocales` (línea 43)
     - locale: `locale` (línea 44)
     - routes: `routes ?? {}` (línea 45)
     - **onGenerateRoute** (líneas 46-55): Función personalizada para generar rutas:
       - Parámetro: `RouteSettings settings`
       - **Ruta por defecto** (líneas 47-49):
         - Condición: `settings.name == Navigator.defaultRouteName` (ruta '/')
         - Retorna: `CupertinoPageRoute` con `builder: (_) => home!`
       - **Rutas nombradas** (líneas 50-53):
         - Obtiene builder de `routes?[settings.name]`
         - Si existe: retorna `CupertinoPageRoute` con ese builder
       - **Ruta no encontrada** (línea 54):
         - Retorna: `null` (Flutter manejará el error)
     - **builder** (línea 56): `(context, child) => child ?? home!`
       - Fallback a `home` si child es null
     - debugShowCheckedModeBanner: `debugShowCheckedModeBanner` (línea 57)

**Decisiones de plataforma**:
- iOS → CupertinoApp / CupertinoApp.router
- Otras plataformas → WidgetsApp / WidgetsApp.router

**Decisiones de navegación**:
- Con GoRouter → usa constructores .router
- Sin GoRouter → usa constructores normales con onGenerateRoute

## 4. DEPENDENCIAS

### Packages externos:
- `flutter/cupertino.dart`: Widgets de estilo iOS
- `flutter_localizations/flutter_localizations.dart`: Localizaciones globales
  - `GlobalWidgetsLocalizations.delegate`
  - `GlobalCupertinoLocalizations.delegate`
- `go_router`: Sistema de navegación declarativa
  - `GoRouter`: Configuración de rutas

### Imports internos - Helpers:
- `eventypop/ui/helpers/platform/platform_detection.dart`: `PlatformDetection.isIOS` para detectar plataforma

### Imports internos - Localización:
- `../l10n/app_localizations.dart`: `AppLocalizations.delegate` para localizaciones de la app

### Widgets de Flutter:
- `CupertinoApp`: App raíz de estilo iOS (navegación tradicional)
- `CupertinoApp.router`: App raíz de estilo iOS (con GoRouter)
- `WidgetsApp`: App raíz básica sin material design (navegación tradicional)
- `WidgetsApp.router`: App raíz básica sin material design (con GoRouter)
- `CupertinoPageRoute`: Transición de página de estilo iOS

### Tipos:
- `LocalizationsDelegate<dynamic>`: Delegate para localización
- `Locale`: Representación de locale (idioma/país)
- `WidgetBuilder`: Función que construye un widget
- `RouteSettings`: Configuración de una ruta

## 5. FLUJO DE DATOS

### Al inicializar la app:
1. Usuario crea `AdaptiveApp` o `AdaptiveApp.router` en main.dart
2. Pasa configuración:
   - title de la app
   - localizationsDelegates (ignorados, se usan los internos)
   - supportedLocales
   - locale actual (opcional)
   - debugShowCheckedModeBanner (opcional)
3. Si usa `.router`:
   - Pasa `routerConfig` con instancia de GoRouter
   - `home` y `routes` son null automáticamente
4. Si usa constructor normal:
   - Pasa `home` con widget inicial
   - Opcionalmente pasa `routes` con mapa de rutas nombradas
   - `routerConfig` es null automáticamente

### Durante build:
1. `build()` se ejecuta
2. Crea lista de `delegates` con los 3 delegates fijos
3. Verifica si `routerConfig != null`:
   - **Si true** (navegación con GoRouter):
     - Verifica plataforma con `PlatformDetection.isIOS`
     - Si iOS: crea `CupertinoApp.router`
     - Si no iOS: crea `WidgetsApp.router`
     - Retorna la app con configuración de router
   - **Si false** (navegación tradicional):
     - Verifica plataforma con `PlatformDetection.isIOS`
     - Si iOS: crea `CupertinoApp` con home y routes
     - Si no iOS: crea `WidgetsApp` con:
       - home como widget inicial
       - routes para rutas nombradas
       - onGenerateRoute para crear CupertinoPageRoute
       - builder para fallback a home

### Durante navegación tradicional:
1. Usuario navega con `Navigator.pushNamed('/ruta')`
2. Flutter llama a `onGenerateRoute` con settings
3. onGenerateRoute verifica:
   - Si es ruta por defecto '/': retorna CupertinoPageRoute a home
   - Si está en routes: retorna CupertinoPageRoute con el builder
   - Si no existe: retorna null (error de ruta)
4. Flutter muestra la pantalla con transición de Cupertino

### Durante navegación con router:
1. Usuario navega con `context.go('/ruta')` o `context.push('/ruta')`
2. GoRouter maneja la navegación según su configuración
3. CupertinoApp.router o WidgetsApp.router integran automáticamente GoRouter
4. No se usa onGenerateRoute, todo lo maneja GoRouter

## 6. CARACTERÍSTICAS DEL WIDGET

### Funcionalidades principales:
1. **App adaptativa**: Cambia entre CupertinoApp y WidgetsApp según plataforma
2. **Dos modos de navegación**: Soporta navegación tradicional y GoRouter
3. **Localización**: Integra delegates de localización automáticamente
4. **Rutas nombradas**: Soporta mapa de rutas en navegación tradicional
5. **Transiciones iOS**: Usa CupertinoPageRoute para transiciones nativas de iOS en todas las plataformas

### Adaptaciones por plataforma:
- **iOS**:
  - Usa `CupertinoApp` o `CupertinoApp.router`
  - Incluye `GlobalCupertinoLocalizations.delegate`
  - Transiciones nativas de iOS

- **Otras plataformas**:
  - Usa `WidgetsApp` o `WidgetsApp.router`
  - Sin Material Design (más ligero)
  - Aún usa CupertinoPageRoute para consistencia visual

### Delegates de localización:
- **Fijos** (siempre incluidos):
  1. `AppLocalizations.delegate`: Traducciones personalizadas de la app
  2. `GlobalWidgetsLocalizations.delegate`: Widgets básicos de Flutter
  3. `GlobalCupertinoLocalizations.delegate`: Widgets de Cupertino

- **No incluye**:
  - `GlobalMaterialLocalizations.delegate` (porque no usa Material)
  - Los delegates pasados como parámetro (se ignoran)

### Constructores diferenciados:
1. **AdaptiveApp()**: Constructor principal para navegación tradicional
   - Requiere `home` o manejo manual de rutas
   - Acepta `routes` opcional
   - Fuerza `routerConfig = null`

2. **AdaptiveApp.router()**: Named constructor para GoRouter
   - Requiere `routerConfig`
   - Fuerza `home = null` y `routes = null`
   - Previene uso incorrecto de parámetros

### onGenerateRoute personalizado:
- Solo en `WidgetsApp` (no iOS) con navegación tradicional
- Crea `CupertinoPageRoute` para todas las rutas
- Consistencia visual: transiciones de iOS incluso en Android
- Maneja ruta por defecto '/' especialmente
- Retorna null si ruta no existe

### Builder fallback:
- En `WidgetsApp`: `builder: (context, child) => child ?? home!`
- Asegura que siempre hay un widget a mostrar
- Fallback a `home` si child es null

## 7. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 61
**Métodos**: 1 (build)
**Constructores**: 2 (normal + router)
**Tipo**: StatelessWidget

**Distribución aproximada**:
- Imports: ~5 líneas (8.2%)
- Declaración de clase: ~1 línea (1.6%)
- Propiedades: ~9 líneas (14.8%)
- Constructor normal: ~1 línea (1.6%)
- Constructor router: ~1 línea (1.6%)
- build method: ~37 líneas (60.7%)
- Resto (espacios, llaves): ~7 líneas (11.5%)

**Complejidad**: Media
- 4 branches principales (router iOS, router otras, tradicional iOS, tradicional otras)
- Lógica de onGenerateRoute añade complejidad
- Decisiones basadas en plataforma y tipo de navegación

## 8. CARACTERÍSTICAS TÉCNICAS

### Named constructor para diferenciación:
- `.router` hace explícita la intención de usar GoRouter
- Previene errores al mezclar navegación tradicional y router
- Fuerza valores null apropiados en lista de inicialización

### Lista de inicialización:
- Constructor normal: `routerConfig = null`
- Constructor router: `home = null, routes = null`
- Asegura que solo un tipo de navegación esté activo
- Validación en tiempo de compilación

### Force unwrap (!):
- `home!` en líneas 35, 48, 56: Se asume que home no es null cuando routerConfig es null
- `routerConfig!` en líneas 28, 31: Se asume que routerConfig no es null en el branch correspondiente
- Seguro porque los constructores garantizan estos valores

### Null-aware operator (??):
- `routes ?? const {}` en línea 35: Mapa vacío si routes es null
- `routes ?? {}` en línea 45: Mapa vacío si routes es null
- `child ?? home!` en línea 56: Fallback a home si child es null
- Previene errores de null

### Color hardcoded:
- `Color(0xFFFFFFFF)` (blanco) en líneas 31 y 40
- Requerido por WidgetsApp
- No afecta visualmente (es color de fondo base)

### Delegates reemplazan parámetro:
- Parámetro `localizationsDelegates` se ignora
- Se usan delegates fijos internos
- **Razón**: Garantizar que siempre estén los 3 delegates necesarios
- **Implicación**: El parámetro es engañoso, no hace nada

### PlatformDetection.isIOS:
- Usado 2 veces para decidir qué app crear
- Centraliza la detección de plataforma
- Permite cambiar lógica de detección en un solo lugar

### CupertinoPageRoute en todas las plataformas:
- En `WidgetsApp`, todas las rutas usan `CupertinoPageRoute`
- **Razón**: Consistencia visual con iOS
- Transiciones suaves de deslizamiento horizontal
- Mejor UX que transiciones por defecto de WidgetsApp

### onGenerateRoute complejo:
- 3 branches: ruta por defecto, rutas nombradas, ruta no encontrada
- Usa `settings.name` y `settings` para configurar rutas
- Retorna `null` si ruta no existe (Flutter muestra error)
- Solo necesario en WidgetsApp porque CupertinoApp lo maneja automáticamente

### Builder en WidgetsApp:
- `builder: (context, child) => child ?? home!`
- Requerido por WidgetsApp
- CupertinoApp no lo necesita
- Asegura que siempre hay un widget raíz

### Const constructors:
- Ambos constructores son `const`
- Permite optimizaciones de compilación
- Widget se puede crear como constante si todos los parámetros lo son

### Default value:
- `debugShowCheckedModeBanner = false`
- Por defecto oculta el banner "DEBUG"
- Común en apps de producción
- Puede ser true en desarrollo

### GoRouter opcional:
- `routerConfig` es nullable
- Permite usar la app sin GoRouter
- Flexibilidad en el tipo de navegación

### Symmetric handling:
- Ambos tipos de navegación tienen branches para iOS y otras plataformas
- Simetría en la lógica facilita mantenimiento
- Decisiones consistentes entre modos

### No Material Design:
- Usa `WidgetsApp` en lugar de `MaterialApp`
- **Razón**: App con look & feel completamente de Cupertino
- Más ligero (menos código de Material)
- Consistencia visual en todas las plataformas

### GlobalCupertinoLocalizations:
- Incluido en delegates
- Proporciona traducciones para widgets de Cupertino
- Ejemplo: textos de botones "OK", "Cancel", etc.
- Esencial para UI de Cupertino multilingüe

### Stateless design:
- No tiene estado mutable
- Toda la configuración viene de parámetros
- Widget raíz inmutable
- Cambios de locale/etc. requieren rebuild completo de la app
