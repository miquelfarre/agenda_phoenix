# CountryPickerModal

## 1. Overview

`CountryPickerModal` es un widget modal especializado para selección de países con búsqueda instantánea y adaptación completa de plataforma (iOS/Android). A diferencia de `CitySearchPickerModal`, este widget realiza búsquedas síncronas sobre una lista local de países, proporcionando filtrado instantáneo sin latencia de red. Incluye capacidad de mostrar offsets de zona horaria en tiempo real y permite tanto gestión interna como externa del controlador de búsqueda.

El widget implementa dos interfaces completamente distintas según la plataforma: en iOS utiliza `CupertinoPageScaffold` con navegación nativa full-screen, mientras que en Android usa un modal bottom sheet con altura configurable. Esta dualidad mantiene coherencia con las convenciones de diseño de cada plataforma mientras comparte la misma lógica de búsqueda y filtrado.

**Propósito principal:**
- Selección de país de una lista completa y localizada
- Búsqueda instantánea síncrona con filtrado en tiempo real
- Visualización de zona horaria primaria de cada país
- Opción de mostrar offset UTC actual (ej: "GMT+01:00")
- Adaptación completa de UI según plataforma (iOS vs Android)
- Flexibilidad para gestión interna o externa del controlador de búsqueda

## 2. File Location

**Path:** `/Users/miquelfarre/development/agenda_phoenix/app_flutter/lib/widgets/pickers/country_picker.dart`

**Ubicación en la arquitectura:**
- **Capa:** Presentation Layer - Pickers
- **Categoría:** Modal Picker Widget
- **Subcarpeta:** `pickers/` - agrupa widgets especializados en selección de datos geográficos

## 3. Dependencies

### External Dependencies

```dart
import 'package:flutter/cupertino.dart';
```
**Propósito:** Framework de widgets estilo iOS. Proporciona `CupertinoPageScaffold`, `CupertinoNavigationBar`, `CupertinoTextField`, `CupertinoIcons`, y otros componentes nativos de iOS.

### Internal Dependencies

```dart
import '../../models/country.dart';
```
**Propósito:** Modelo de datos `Country` que representa un país con propiedades como:
- `name`: Nombre del país (posiblemente localizado)
- `code`: Código ISO del país (ej: "ES", "US", "FR")
- `flag`: Emoji de bandera (🇪🇸, 🇺🇸, 🇫🇷)
- `primaryTimezone`: Zona horaria principal (ej: "Europe/Madrid", "America/New_York")

```dart
import '../../services/country_service.dart';
```
**Propósito:** Servicio que proporciona operaciones síncronas sobre países:
- `getAllCountries()` → Retorna lista completa de países
- `searchCountries(String query)` → Filtra países por query (nombre o código)
Operaciones son síncronas (no `Future`), lo que permite filtrado instantáneo

```dart
import '../../services/timezone_service.dart';
```
**Propósito:** Servicio que proporciona `getCurrentOffset(String timezone)` para calcular el offset UTC actual de una zona horaria (ej: "+01:00", "-05:00"). Considera horario de verano (DST) si aplica.

```dart
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
```
**Propósito:** Helper que proporciona widgets adaptativos cross-platform:
- `platformIcon()` - Iconos adaptativos
- `platformTextField()` - Campo de texto adaptativo
- `platformListTile()` - List item adaptativo

```dart
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
```
**Propósito:** Utilidad para detectar la plataforma actual. Proporciona `PlatformDetection.isIOS` que determina qué UI renderizar (full-screen vs bottom sheet).

```dart
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
```
**Propósito:** Sistema de localización. Proporciona extensión `context.l10n` con traducciones:
- `selectCountryTimezone` - Título del modal
- `cancel` - Texto del botón cancelar (iOS)
- `search` - Placeholder del campo de búsqueda
- `timezoneWithOffset(tz, offset)` - Formato "TIMEZONE (OFFSET)" (ej: "Europe/Madrid (GMT+01:00)")

```dart
import 'package:eventypop/ui/styles/app_styles.dart';
```
**Propósito:** Estilos globales de la aplicación:
- `headlineSmall` - Estilo base para banderas (emojis grandes)
- `cardTitle` - Estilo para título del modal
- `cardSubtitle` - Estilo para subtítulos (zona horaria)
- `grey600` - Color gris para texto secundario

```dart
import '../adaptive/adaptive_button.dart';
```
**Propósito:** Botón adaptativo usado para botones de cancelar/cerrar. Utiliza `AdaptiveButtonConfig` con variantes (secondary, icon).

### Type Definition

```dart
typedef CountrySelected = void Function(Country country);
```
**Línea:** 12

**Propósito:** Define el tipo para el callback de selección. Mejora la legibilidad al dar un nombre semántico al tipo de función que recibe un `Country` completo.

## 4. Class Declaration

```dart
class CountryPickerModal extends StatefulWidget {
```
**Línea:** 14

**Decisión de diseño:** `StatefulWidget`

**Justificación:**
1. **Gestión de controlador:** Necesita crear y gestionar `TextEditingController` (si no se proporciona externamente)
2. **Lista filtrada:** Mantiene `_filtered` que cambia dinámicamente según la búsqueda
3. **Búsqueda en tiempo real:** Actualiza UI instantáneamente al escribir
4. **Lifecycle management:** Requiere `initState` para inicializar y `dispose` para limpiar recursos
5. **Estado local:** Aunque la búsqueda es síncrona, necesita estado para la lista filtrada

## 5. Properties Analysis

### Required Properties

```dart
final CountrySelected onSelected;
```
**Línea:** 18

**Tipo:** `CountrySelected` (alias de `void Function(Country country)`)

**Propósito:** Callback invocado cuando el usuario selecciona un país de la lista. Recibe el objeto `Country` completo con todas sus propiedades (nombre, código, bandera, timezone).

**Flujo de ejecución:**
1. Usuario toca un país de la lista (líneas 89, 145)
2. Se invoca `widget.onSelected(country)` con el país seleccionado
3. Se cierra el modal con `Navigator.of(context).pop()`
4. El widget padre recibe el país seleccionado y puede procesarlo

### Optional Properties

```dart
final Country? initialCountry;
```
**Línea:** 15

**Tipo:** `Country?` (nullable)

**Default:** `null`

**Propósito:** País inicialmente seleccionado. Aunque el widget acepta este parámetro, **no se utiliza en la implementación actual** para marcar ningún país como seleccionado visualmente o hacer scroll automático.

**Observación:** Este es un parámetro residual que podría usarse para:
- Marcar visualmente el país actualmente seleccionado
- Auto-scroll al país inicial al abrir el modal
- Filtrar o reordenar lista poniendo el país inicial primero

**Estado actual:** Actualmente no tiene efecto en la UI.

---

```dart
final bool showOffset;
```
**Línea:** 16

**Tipo:** `bool`

**Default:** `true` (línea 20)

**Propósito:** Controla si se muestra el offset UTC en el subtítulo de cada país.

**Comportamiento (líneas 80, 85-87, 136, 141-143):**
- **Si `true`:** Subtítulo muestra "Europe/Madrid (GMT+01:00)"
- **Si `false`:** Subtítulo muestra solo "Europe/Madrid"

**Cálculo del offset:**
```dart
final offset = widget.showOffset ? TimezoneService.getCurrentOffset(country.primaryTimezone) : '';
```
- Se calcula en tiempo real para cada país
- Considera horario de verano (DST) actual
- Formato típico: "GMT+01:00", "GMT-05:00", "GMT+00:00"

**Casos de uso:**
- `showOffset: true` → Útil para que usuarios entiendan diferencia horaria
- `showOffset: false` → UI más limpia si offset no es relevante

---

```dart
final TextEditingController? searchController;
```
**Línea:** 17

**Tipo:** `TextEditingController?` (nullable)

**Default:** `null`

**Propósito:** Permite inyección de un controlador de búsqueda externo. Si se proporciona, el widget lo usa; si no, crea uno interno.

**Gestión (líneas 33, 39-41):**
```dart
// initState
_controller = widget.searchController ?? TextEditingController();

// dispose
if (widget.searchController == null) {
  _controller.dispose();
}
```

**Lógica de ownership:**
- **Si `searchController` es `null`:** Widget crea controller interno y lo dispone en `dispose()`
- **Si `searchController` es provisto:** Widget usa el externo pero NO lo dispone (el padre es responsable)

**Casos de uso:**
- **Controller interno (null):** Caso típico, el widget gestiona su propio estado de búsqueda
- **Controller externo:** Permite al widget padre:
  - Pre-popular el campo de búsqueda
  - Leer el valor de búsqueda actual
  - Resetear la búsqueda programáticamente
  - Sincronizar búsqueda con otros widgets

## 6. State Variables

```dart
late TextEditingController _controller;
```
**Línea:** 27

**Propósito:** Controlador del campo de texto de búsqueda. Puede ser instancia interna o referencia al controlador externo.

**Declarado como `late`:** Se inicializa en `initState` (línea 33) donde se decide si usar el externo o crear uno nuevo.

**Lifecycle:**
- **Inicialización:** `initState()` - asigna externo o crea nuevo
- **Uso:** Conectado al `CupertinoTextField`/`platformTextField`
- **Limpieza:** `dispose()` - solo disposed si fue creado internamente

---

```dart
List<Country> _filtered = [];
```
**Línea:** 28

**Propósito:** Lista de países filtrados según la búsqueda actual. Inicialmente contiene todos los países.

**Estados posibles:**
- `[]` (vacío) → Solo si `CountryService.getAllCountries()` retorna vacío (caso improbable)
- `[Country(...), Country(...), ...]` → Lista filtrada según query de búsqueda
- Todos los países → Cuando búsqueda está vacía o en estado inicial

**Actualización:**
- Línea 34 (`initState`): Inicializa con todos los países
- Línea 47 (`_onSearch`): Actualiza con resultados de búsqueda filtrados

**Performance:** Al ser búsqueda síncrona local, las actualizaciones son instantáneas sin delay perceptible.

## 7. Lifecycle Methods

### 7.1. initState

```dart
@override
void initState() {
  super.initState();
  _controller = widget.searchController ?? TextEditingController();
  _filtered = CountryService.getAllCountries();
}
```
**Líneas:** 31-35

**Propósito:** Inicializar estado del widget cuando se monta en el árbol.

**Análisis línea por línea:**

**Línea 32:** `super.initState();`
- Llama al método `initState` de la clase padre
- DEBE ser la primera línea (antes de acceder a cualquier estado)

**Línea 33:** `_controller = widget.searchController ?? TextEditingController();`
- **Operador ??:** Si `widget.searchController` es `null`, crea nuevo `TextEditingController()`
- **Patrón de ownership:** Si el widget padre proporciona controller, lo usa; si no, crea uno propio
- **No disposal condicional:** En `dispose()`, solo se libera si fue creado internamente

**Línea 34:** `_filtered = CountryService.getAllCountries();`
- Carga la lista completa de países al iniciar
- Operación síncrona (no hay `await`)
- Todos los países están disponibles inmediatamente para mostrar
- No hay estado de "loading" necesario

**Diferencia clave con CitySearchPickerModal:**
- `CitySearchPickerModal` inicia con lista vacía y requiere búsqueda
- `CountryPickerModal` muestra todos los países desde el inicio
- Esto mejora UX: usuario puede scrollear la lista completa sin necesidad de buscar

### 7.2. dispose

```dart
@override
void dispose() {
  if (widget.searchController == null) {
    _controller.dispose();
  }
  super.dispose();
}
```
**Líneas:** 38-43

**Propósito:** Liberar recursos cuando el widget se elimina del árbol.

**Análisis línea por línea:**

**Línea 39:** `if (widget.searchController == null) {`
- Verifica si el controller fue creado internamente
- Solo controllers creados internamente deben ser disposed por el widget

**Línea 40:** `_controller.dispose();`
- Libera recursos del `TextEditingController`
- Previene memory leaks eliminando listeners internos
- SOLO se ejecuta si el widget creó el controller

**Línea 42:** `super.dispose();`
- Llama al método dispose de la clase padre
- DEBE ser la última línea del método dispose
- Completa el proceso de limpieza del framework

**Patrón de ownership:**
- **Controller interno:** Widget es responsable → debe dispose
- **Controller externo:** Widget padre es responsable → NO debe dispose
- Este patrón previene double-disposal que causaría crashes

## 8. Methods

### 8.1. _onSearch

```dart
void _onSearch(String value) {
  setState(() {
    _filtered = CountryService.searchCountries(value);
  });
}
```
**Líneas:** 45-49

**Propósito:** Filtrar lista de países basándose en el query de búsqueda ingresado por el usuario.

**Análisis línea por línea:**

**Línea 45:** `void _onSearch(String value) {`
- Método sincrónico (no `async`)
- Recibe el valor actual del campo de texto
- Llamado en cada cambio del TextField (`onChanged`)

**Líneas 46-48:** Actualización de estado
```dart
setState(() {
  _filtered = CountryService.searchCountries(value);
});
```

**Línea 47:** `_filtered = CountryService.searchCountries(value);`
- Llama al servicio de búsqueda de países
- **Operación síncrona:** No hay `await`, retorna inmediatamente
- El servicio probablemente filtra por:
  - Nombre del país (case-insensitive)
  - Código del país (ej: "ES", "US")
  - Posiblemente alias o nombres alternativos

**Efecto en UI:**
- `setState` dispara rebuild inmediato
- `ListView.builder` muestra la lista filtrada actualizada
- No hay delay perceptible (búsqueda local es instantánea)
- Si `value` es vacío, probablemente retorna todos los países

**Diferencias con CitySearchPickerModal:**

| Aspecto | CountryPickerModal | CitySearchPickerModal |
|---------|-------------------|----------------------|
| **Búsqueda** | Síncrona local | Asíncrona con API |
| **Loading state** | No necesario | Requiere `_isLoading` |
| **Validación mínima** | No (filtra con cualquier input) | Sí (mínimo 3 caracteres) |
| **Latencia** | Instantánea | Depende de red |
| **Complejidad** | Simple | Compleja (async, error handling) |

**Performance:** Al ser búsqueda local sobre lista en memoria, es extremadamente rápida incluso con cientos de países. No hay necesidad de debouncing o throttling.

## 9. Build Method

El método `build` implementa dos UIs completamente diferentes según la plataforma:

```dart
@override
Widget build(BuildContext context) {
  final l10n = context.l10n;
  final modalHeight = MediaQuery.of(context).size.height * 0.8;

  if (PlatformDetection.isIOS) {
    // iOS UI
  }
  // Android UI
}
```
**Líneas:** 52-155

**Variables comunes:**
- **Línea 53:** `final l10n = context.l10n;` - Helper de localización
- **Línea 54:** `final modalHeight = MediaQuery.of(context).size.height * 0.8;` - Altura para modal Android (80% de pantalla)

### 9.1. iOS UI (CupertinoPageScaffold)

**Líneas:** 56-99

**Estructura general:**
```dart
if (PlatformDetection.isIOS) {
  return CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(...),
    child: SafeArea(
      child: Column(
        children: [
          Padding(...) // Search field
          Expanded(...) // Countries list
        ],
      ),
    ),
  );
}
```

**Análisis detallado:**

**Línea 57:** `return CupertinoPageScaffold(`
- Scaffold estilo iOS con navegación Cupertino
- Presenta el modal como página completa

**Líneas 58-61:** Navigation Bar
```dart
navigationBar: CupertinoNavigationBar(
  middle: Text(l10n.selectCountryTimezone),
  leading: AdaptiveButton(
    key: const Key('country_picker_cancel_button'),
    config: AdaptiveButtonConfig.secondary(),
    text: l10n.cancel,
    onPressed: () => Navigator.of(context).pop()
  ),
),
```
- **middle:** Título centrado (localizado)
- **leading:** Botón "Cancelar" en la izquierda
- **key:** Para testing (`country_picker_cancel_button`)
- **Acción:** Cierra el modal sin seleccionar nada

**Línea 62:** `child: SafeArea(`
- Previene que el contenido se solape con notch, status bar, home indicator
- Esencial en dispositivos iOS modernos (iPhone X+)

**Líneas 65-73:** Campo de búsqueda
```dart
Padding(
  padding: const EdgeInsets.all(16.0),
  child: CupertinoTextField(
    controller: _controller,
    placeholder: l10n.search,
    onChanged: _onSearch,
    prefix: Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: PlatformWidgets.platformIcon(CupertinoIcons.search)
    ),
  ),
),
```
- **CupertinoTextField:** Campo de texto estilo iOS
- **controller:** Usa `_controller` (interno o externo)
- **placeholder:** Texto hint localizado ("Buscar")
- **onChanged:** Invoca `_onSearch` en cada keystroke
- **prefix:** Icono de búsqueda a la izquierda

**Líneas 74-95:** Lista de países
```dart
Expanded(
  child: ListView.builder(
    physics: const ClampingScrollPhysics(),
    itemCount: _filtered.length,
    itemBuilder: (context, index) {
      final country = _filtered[index];
      final offset = widget.showOffset
        ? TimezoneService.getCurrentOffset(country.primaryTimezone)
        : '';

      return PlatformWidgets.platformListTile(
        leading: Text(country.flag, style: AppStyles.headlineSmall.copyWith(fontSize: 24)),
        title: Text(country.name),
        subtitle: widget.showOffset
          ? Text(l10n.timezoneWithOffset(country.primaryTimezone, offset), ...)
          : Text(country.primaryTimezone, ...),
        onTap: () {
          widget.onSelected(country);
          Navigator.of(context).pop();
        },
      );
    },
  ),
)
```

**Características clave:**

**Línea 80:** Cálculo condicional de offset
```dart
final offset = widget.showOffset
  ? TimezoneService.getCurrentOffset(country.primaryTimezone)
  : '';
```
- Solo calcula offset si `showOffset` es `true`
- Evita cálculos innecesarios cuando no se va a mostrar
- Offset se calcula para CADA país en la lista (puede ser costoso para listas grandes)

**Línea 83:** Leading con bandera
```dart
leading: Text(country.flag, style: AppStyles.headlineSmall.copyWith(fontSize: 24)),
```
- Emoji de bandera grande (fontSize: 24)
- Visualmente atractivo y reconocible

**Línea 84:** Título con nombre del país
```dart
title: Text(country.name),
```
- Nombre localizado del país (si el servicio lo soporta)

**Líneas 85-87:** Subtítulo condicional
```dart
subtitle: widget.showOffset
  ? Text(l10n.timezoneWithOffset(country.primaryTimezone, offset), ...)
  : Text(country.primaryTimezone, ...),
```
- **Con offset:** "Europe/Madrid (GMT+01:00)"
- **Sin offset:** "Europe/Madrid"
- Formato localizado usando `l10n.timezoneWithOffset`

**Líneas 88-91:** Acción de selección
```dart
onTap: () {
  widget.onSelected(country);
  Navigator.of(context).pop();
},
```
- Invoca callback con el país seleccionado
- Cierra el modal inmediatamente después
- Widget padre recibe el país y puede actualizar su estado

### 9.2. Android UI (Bottom Sheet Modal)

**Líneas:** 102-154

**Estructura general:**
```dart
return SizedBox(
  height: modalHeight,
  child: Column(
    children: [
      Container(...) // Header with title, close button, search field
      Expanded(...) // Countries list
    ],
  ),
);
```

**Análisis detallado:**

**Líneas 102-103:** Contenedor con altura fija
```dart
return SizedBox(
  height: modalHeight,
```
- `modalHeight` es 80% de altura de pantalla (línea 54)
- Permite scroll del contenido si la lista es larga
- Deja 20% del fondo visible indicando que es un modal

**Líneas 106-129:** Header del modal
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: const BoxDecoration(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20))
  ),
  child: Column(
    children: [
      Row(...), // Title and close button
      SizedBox(height: 16),
      PlatformWidgets.platformTextField(...), // Search field
    ],
  ),
)
```

**Row con título y botón cerrar (líneas 111-123):**
```dart
Row(
  children: [
    Expanded(
      child: Text(
        l10n.selectCountryTimezone,
        style: AppStyles.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.bold)
      ),
    ),
    AdaptiveButton(
      key: const Key('country_picker_close_button'),
      config: const AdaptiveButtonConfig(
        variant: ButtonVariant.icon,
        size: ButtonSize.medium,
        fullWidth: false,
        iconPosition: IconPosition.only
      ),
      icon: CupertinoIcons.clear,
      onPressed: () => Navigator.of(context).pop(),
    ),
  ],
)
```

**Características:**
- **Expanded en título:** Título ocupa espacio disponible, empujando botón a la derecha
- **AdaptiveButton como icono:** Solo muestra icono "X" sin texto
- **key:** Para testing (`country_picker_close_button`)
- **Diseño horizontal:** Título y cerrar en la misma línea

**Campo de búsqueda (línea 126):**
```dart
PlatformWidgets.platformTextField(
  controller: _controller,
  hintText: l10n.search,
  prefixIcon: PlatformWidgets.platformIcon(CupertinoIcons.search),
  onChanged: _onSearch
),
```
- **platformTextField:** Versión adaptativa que renderiza según plataforma
- **prefixIcon:** Icono de búsqueda adaptativo
- Mismo comportamiento que versión iOS

**Líneas 130-151:** Lista de países
Estructura idéntica a iOS:
```dart
Expanded(
  child: ListView.builder(
    physics: const ClampingScrollPhysics(),
    itemCount: _filtered.length,
    itemBuilder: (context, index) {
      final country = _filtered[index];
      final offset = widget.showOffset
        ? TimezoneService.getCurrentOffset(country.primaryTimezone)
        : '';

      return PlatformWidgets.platformListTile(...);
    },
  ),
)
```

**Diferencias sutiles con iOS:**
- Mismo código exacto del `itemBuilder`
- `platformListTile` puede renderizar diferente según plataforma
- Mismo comportamiento de selección

### 9.3. Comparación iOS vs Android UI

| Aspecto | iOS | Android |
|---------|-----|---------|
| **Scaffold** | CupertinoPageScaffold | SizedBox con altura |
| **Navegación** | CupertinoNavigationBar | Row con título y botón |
| **Campo búsqueda** | CupertinoTextField | platformTextField |
| **Ubicación del campo** | Dentro de SafeArea | Dentro de Container header |
| **Botón cerrar** | "Cancelar" texto en navbar | Icono "X" en header |
| **Altura** | Full screen | 80% de pantalla |
| **Border radius** | Sin (full screen) | Top corners redondeadas (20px) |
| **Test keys** | `country_picker_cancel_button` | `country_picker_close_button` |

**Consistencias:**
- Misma lógica de búsqueda y filtrado
- Mismo formato de resultados (bandera, país, timezone)
- Mismo cálculo de offset
- Mismo comportamiento de selección

## 10. Technical Characteristics

### Synchronous Search Pattern
- **Operación:** Búsqueda síncrona sobre datos locales
- **Ventaja:** Resultados instantáneos sin latencia
- **No requiere:** Loading states, error handling async, mounted checks
- **Performance:** Extremadamente rápida incluso con cientos de países
- **Trade-off:** Requiere que todos los datos estén en memoria

### Platform Adaptation Strategy
- **Detección:** Usa `PlatformDetection.isIOS` para branch de UI
- **iOS:** Full-screen modal con `CupertinoPageScaffold`
- **Android:** Bottom sheet modal (80% altura) con bordes redondeados
- **Lógica compartida:** Todo el código de búsqueda es idéntico
- **Separación clara:** Solo el método `build()` diverge según plataforma

### Controller Ownership Pattern
- **Flexibilidad:** Acepta controller externo o crea uno interno
- **Conditional disposal:** Solo dispone si creó el controller
- **Ventaja:** Permite control externo del estado de búsqueda
- **Uso típico:** Controller interno para casos simples

### Timezone Offset Calculation
- **Condicional:** Solo calcula si `showOffset` es `true`
- **Tiempo real:** Usa `TimezoneService.getCurrentOffset()` en cada item
- **DST-aware:** Considera horario de verano actual
- **Performance:** Cálculo por cada país visible (potencial optimización: cacheo)

### State Management
- **Local state:** Todo el estado es local al widget
- **Estados:** `_controller`, `_filtered`
- **Inmutabilidad:** `_filtered` se reemplaza completamente en cada búsqueda
- **Sin loading states:** Búsqueda síncrona no requiere estados intermedios

### Navigation Pattern
- **Modal presentation:** Presentado como modal (showModalBottomSheet o Navigator.push)
- **Cierre:** `Navigator.pop()` sin valor de retorno
- **Callback pattern:** Usa `onSelected` callback en lugar de retornar valor via pop
- **Orden:** Callback se ejecuta ANTES de pop (líneas 89, 145)

### List Rendering
- **ListView.builder:** Renderizado lazy eficiente
- **ClampingScrollPhysics:** Scroll sin efecto de rebote
- **Todos los items disponibles:** No hay paginación (todos los países en memoria)
- **Filtrado instantáneo:** UI actualiza inmediatamente al escribir

## 11. Usage Examples

### Example 1: Basic Country Selection

```dart
class EventLocationForm extends StatefulWidget {
  @override
  _EventLocationFormState createState() => _EventLocationFormState();
}

class _EventLocationFormState extends State<EventLocationForm> {
  Country? selectedCountry;

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CountryPickerModal(
        onSelected: (country) {
          setState(() {
            selectedCountry = country;
          });
          print('País seleccionado: ${country.name} (${country.code})');
          print('Zona horaria: ${country.primaryTimezone}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: selectedCountry != null
            ? Text(selectedCountry!.flag, style: TextStyle(fontSize: 32))
            : Icon(Icons.public),
          title: Text('País'),
          subtitle: Text(selectedCountry?.name ?? 'Selecciona un país'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showCountryPicker,
        ),
        if (selectedCountry != null)
          Padding(
            padding: EdgeInsets.all(16),
            child: Text('Zona horaria: ${selectedCountry!.primaryTimezone}'),
          ),
      ],
    );
  }
}
```

**Características:**
- Selección básica con bottom sheet (Android)
- Estado manejado en widget padre
- Feedback visual con bandera grande
- Muestra timezone después de seleccionar

### Example 2: iOS Full-Screen Modal

```dart
class CountrySelector extends StatefulWidget {
  @override
  _CountrySelectorState createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  Country? selectedCountry;

  void _showCountryPicker() {
    if (PlatformDetection.isIOS) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => CountryPickerModal(
            initialCountry: selectedCountry,
            showOffset: true,
            onSelected: (country) {
              setState(() {
                selectedCountry = country;
              });
            },
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => CountryPickerModal(
          initialCountry: selectedCountry,
          showOffset: true,
          onSelected: (country) {
            setState(() {
              selectedCountry = country;
            });
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: selectedCountry != null
          ? Text(selectedCountry!.flag, style: TextStyle(fontSize: 24))
          : Icon(Icons.flag),
        title: Text('País de residencia'),
        subtitle: Text(selectedCountry?.name ?? 'No seleccionado'),
        onTap: _showCountryPicker,
      ),
    );
  }
}
```

**Características:**
- Presentación adaptativa según plataforma
- iOS: Full-screen modal con `CupertinoPageRoute`
- Android: Bottom sheet
- Muestra offset de timezone

### Example 3: Country Picker with External Controller

```dart
class AdvancedCountryPicker extends StatefulWidget {
  @override
  _AdvancedCountryPickerState createState() => _AdvancedCountryPickerState();
}

class _AdvancedCountryPickerState extends State<AdvancedCountryPicker> {
  Country? selectedCountry;
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CountryPickerModal(
        searchController: searchController,
        showOffset: true,
        onSelected: (country) {
          setState(() {
            selectedCountry = country;
          });
        },
      ),
    );
  }

  void _preselectSpain() {
    searchController.text = 'Spain';
    _showCountryPicker();
  }

  void _clearSearch() {
    searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('País seleccionado'),
          subtitle: Text(selectedCountry?.name ?? 'Ninguno'),
          trailing: Icon(Icons.edit),
          onTap: _showCountryPicker,
        ),

        Row(
          children: [
            ElevatedButton(
              onPressed: _preselectSpain,
              child: Text('Preseleccionar España'),
            ),
            SizedBox(width: 8),
            TextButton(
              onPressed: _clearSearch,
              child: Text('Limpiar búsqueda'),
            ),
          ],
        ),

        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Búsqueda actual: "${searchController.text}"',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
```

**Características:**
- Control externo del estado de búsqueda
- Pre-población del campo de búsqueda antes de abrir modal
- Limpieza programática de búsqueda
- Visualización del texto de búsqueda actual
- Widget padre gestiona el lifecycle del controller

### Example 4: Country Picker Without Timezone Offset

```dart
class SimpleCountryPicker extends StatelessWidget {
  final Country? currentCountry;
  final ValueChanged<Country> onCountryChanged;

  const SimpleCountryPicker({
    super.key,
    required this.currentCountry,
    required this.onCountryChanged,
  });

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CountryPickerModal(
        showOffset: false, // No mostrar offset para UI más limpia
        onSelected: (country) {
          onCountryChanged(country);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: currentCountry != null
          ? Text(currentCountry!.flag, style: TextStyle(fontSize: 28))
          : Icon(Icons.language, size: 28),
        title: Text(currentCountry?.name ?? 'Selecciona país'),
        subtitle: currentCountry != null
          ? Text(currentCountry!.code)
          : null,
        trailing: Icon(Icons.expand_more),
        onTap: () => _showPicker(context),
      ),
    );
  }
}
```

**Características:**
- Widget stateless con callbacks
- Oculta offset para UI minimalista
- Muestra código de país como subtítulo
- Diseño con borde personalizado

### Example 5: Multi-Country Selection (Modified Usage)

```dart
class MultiCountrySelector extends StatefulWidget {
  @override
  _MultiCountrySelectorState createState() => _MultiCountrySelectorState();
}

class _MultiCountrySelectorState extends State<MultiCountrySelector> {
  List<Country> selectedCountries = [];

  void _addCountry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CountryPickerModal(
        showOffset: true,
        onSelected: (country) {
          setState(() {
            // Prevent duplicates
            if (!selectedCountries.any((c) => c.code == country.code)) {
              selectedCountries.add(country);
            } else {
              PlatformDialogHelpers.showSnackBar(
                context: context,
                message: '${country.name} ya está en la lista',
              );
            }
          });
        },
      ),
    );
  }

  void _removeCountry(int index) {
    setState(() {
      selectedCountries.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Países seleccionados',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 12),

        // List of selected countries
        if (selectedCountries.isEmpty)
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay países seleccionados',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...selectedCountries.asMap().entries.map((entry) {
            final index = entry.key;
            final country = entry.value;
            final offset = TimezoneService.getCurrentOffset(country.primaryTimezone);

            return Card(
              child: ListTile(
                leading: Text(country.flag, style: TextStyle(fontSize: 24)),
                title: Text(country.name),
                subtitle: Text('${country.primaryTimezone} ($offset)'),
                trailing: IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () => _removeCountry(index),
                ),
              ),
            );
          }).toList(),

        SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: _addCountry,
          icon: Icon(Icons.add),
          label: Text('Agregar país'),
        ),
      ],
    );
  }
}
```

**Características:**
- Selección múltiple de países
- Prevención de duplicados por código de país
- Lista visual con banderas y timezones
- Capacidad de eliminar países
- Útil para eventos internacionales multi-país

### Example 6: Integration with Form Validation

```dart
class CountryFormField extends StatefulWidget {
  final FormFieldValidator<Country>? validator;
  final ValueChanged<Country>? onSaved;

  const CountryFormField({
    super.key,
    this.validator,
    this.onSaved,
  });

  @override
  _CountryFormFieldState createState() => _CountryFormFieldState();
}

class _CountryFormFieldState extends State<CountryFormField> {
  Country? selectedCountry;

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CountryPickerModal(
        showOffset: true,
        onSelected: (country) {
          setState(() {
            selectedCountry = country;
          });
          widget.onSaved?.call(country);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<Country>(
      initialValue: selectedCountry,
      validator: widget.validator,
      builder: (FormFieldState<Country> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _showCountryPicker,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'País',
                  errorText: field.hasError ? field.errorText : null,
                  suffixIcon: Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(),
                ),
                child: selectedCountry != null
                  ? Row(
                      children: [
                        Text(selectedCountry!.flag, style: TextStyle(fontSize: 24)),
                        SizedBox(width: 8),
                        Text(selectedCountry!.name),
                      ],
                    )
                  : Text(
                      'Toca para seleccionar',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Usage in a form:
Form(
  child: Column(
    children: [
      CountryFormField(
        validator: (country) {
          if (country == null) {
            return 'Por favor selecciona un país';
          }
          return null;
        },
        onSaved: (country) {
          print('País guardado: ${country.name}');
        },
      ),
      ElevatedButton(
        onPressed: () {
          // Validate and save form
        },
        child: Text('Submit'),
      ),
    ],
  ),
)
```

**Características:**
- Integración completa con Flutter Form
- Validación requerida
- Mensajes de error consistentes con otros campos
- InputDecorator para apariencia de TextField
- Callback onSaved para persistencia

## 12. Testing Recommendations

### 12.1. Unit Tests

```dart
void main() {
  group('CountryPickerModal Unit Tests', () {

    testWidgets('initializes with all countries', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryPickerModal(
              onSelected: (country) {},
            ),
          ),
        ),
      );

      final state = tester.state<_CountryPickerModalState>(
        find.byType(CountryPickerModal)
      );

      expect(state._filtered.isNotEmpty, isTrue);
      expect(state._filtered.length, equals(CountryService.getAllCountries().length));
    });

    testWidgets('creates internal controller when not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CountryPickerModal(
            onSelected: (country) {},
          ),
        ),
      );

      final state = tester.state<_CountryPickerModalState>(
        find.byType(CountryPickerModal)
      );

      expect(state._controller, isNotNull);
    });

    testWidgets('uses external controller when provided', (tester) async {
      final externalController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: CountryPickerModal(
            searchController: externalController,
            onSelected: (country) {},
          ),
        ),
      );

      final state = tester.state<_CountryPickerModalState>(
        find.byType(CountryPickerModal)
      );

      expect(state._controller, equals(externalController));
    });

    testWidgets('disposes internal controller but not external', (tester) async {
      final externalController = TextEditingController();

      // Test with internal controller
      await tester.pumpWidget(
        MaterialApp(
          home: CountryPickerModal(
            onSelected: (country) {},
          ),
        ),
      );

      // Remove widget
      await tester.pumpWidget(Container());

      // Internal controller should be disposed
      // (no direct way to test, but ensures no memory leak)

      // Test with external controller
      await tester.pumpWidget(
        MaterialApp(
          home: CountryPickerModal(
            searchController: externalController,
            onSelected: (country) {},
          ),
        ),
      );

      await tester.pumpWidget(Container());

      // External controller should NOT be disposed
      // We can verify by trying to use it
      externalController.text = 'test';
      expect(externalController.text, equals('test'));

      externalController.dispose();
    });

    test('filters countries based on search query', () {
      final allCountries = CountryService.getAllCountries();
      final filtered = CountryService.searchCountries('spain');

      expect(filtered.length, lessThan(allCountries.length));
      expect(filtered.any((c) => c.name.toLowerCase().contains('spain')), isTrue);
    });
  });

  group('CountryPickerModal Offset Display', () {

    testWidgets('shows offset when showOffset is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CountryPickerModal(
            showOffset: true,
            onSelected: (country) {},
          ),
        ),
      );

      await tester.pump();

      // Should find timezone with offset format
      expect(find.textContaining('GMT'), findsWidgets);
    });

    testWidgets('hides offset when showOffset is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CountryPickerModal(
            showOffset: false,
            onSelected: (country) {},
          ),
        ),
      );

      await tester.pump();

      // Should not find GMT offset
      expect(find.textContaining('GMT+'), findsNothing);
      expect(find.textContaining('GMT-'), findsNothing);
    });
  });
}
```

### 12.2. Widget Tests

```dart
void main() {
  group('CountryPickerModal Widget Tests', () {

    testWidgets('renders iOS UI when platform is iOS', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CountryPickerModal(
            onSelected: (country) {},
          ),
        ),
      );

      if (PlatformDetection.isIOS) {
        expect(find.byType(CupertinoPageScaffold), findsOneWidget);
        expect(find.byType(CupertinoNavigationBar), findsOneWidget);
        expect(find.byKey(Key('country_picker_cancel_button')), findsOneWidget);
      } else {
        expect(find.byType(CupertinoPageScaffold), findsNothing);
        expect(find.byKey(Key('country_picker_close_button')), findsOneWidget);
      }
    });

    testWidgets('displays all countries initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CountryPickerModal(
            onSelected: (country) {},
          ),
        ),
      );

      await tester.pump();

      // Should display multiple countries
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('filters countries when typing in search field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CountryPickerModal(
            onSelected: (country) {},
          ),
        ),
      );

      // Get initial count
      await tester.pump();
      final initialCount = tester.widgetList(find.byType(ListTile)).length;

      // Type in search field
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Spain');
      await tester.pump();

      // Count should be less after filtering
      final filteredCount = tester.widgetList(find.byType(ListTile)).length;
      expect(filteredCount, lessThan(initialCount));
    });

    testWidgets('calls onSelected and pops when country is tapped', (tester) async {
      Country? selectedCountry;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            pages: [
              MaterialPage(
                child: CountryPickerModal(
                  onSelected: (country) {
                    selectedCountry = country;
                  },
                ),
              ),
            ],
            onPopPage: (route, result) => route.didPop(result),
          ),
        ),
      );

      await tester.pump();

      // Tap first country
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(selectedCountry, isNotNull);
    });

    testWidgets('displays country flags as emojis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CountryPickerModal(
            onSelected: (country) {},
          ),
        ),
      );

      await tester.pump();

      // Flags should be displayed with fontSize 24
      expect(find.textContaining('🇪'), findsWidgets); // Regional indicator emojis
    });
  });
}
```

### 12.3. Integration Tests

```dart
void main() {
  group('CountryPickerModal Integration Tests', () {

    testWidgets('complete selection workflow', (tester) async {
      Country? selectedCountry;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => CountryPickerModal(
                        showOffset: true,
                        onSelected: (country) {
                          selectedCountry = country;
                        },
                      ),
                    );
                  },
                  child: Text('Open Picker'),
                );
              },
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Search for specific country
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Spain');
      await tester.pump();

      // Tap first result
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(selectedCountry, isNotNull);
      expect(selectedCountry!.name.toLowerCase(), contains('spain'));
    });

    testWidgets('external controller persists search text', (tester) async {
      final searchController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text('Search: ${searchController.text}'),
                    ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => CountryPickerModal(
                            searchController: searchController,
                            onSelected: (country) {},
                          ),
                        );
                      },
                      child: Text('Open Picker'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Type in search
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'France');
      await tester.pump();

      // Close modal
      await tester.tap(find.byKey(Key('country_picker_close_button')));
      await tester.pumpAndSettle();

      // Verify external controller retains text
      expect(searchController.text, equals('France'));

      searchController.dispose();
    });

    testWidgets('offset display toggles correctly', (tester) async {
      // Test with showOffset: true
      await tester.pumpWidget(
        MaterialApp(
          home: CountryPickerModal(
            showOffset: true,
            onSelected: (country) {},
          ),
        ),
      );

      await tester.pump();
      expect(find.textContaining('GMT'), findsWidgets);

      // Test with showOffset: false
      await tester.pumpWidget(
        MaterialApp(
          home: CountryPickerModal(
            showOffset: false,
            onSelected: (country) {},
          ),
        ),
      );

      await tester.pump();
      expect(find.textContaining('GMT'), findsNothing);
    });
  });
}
```

## 13. Comparison with Similar Widgets

### vs. CitySearchPickerModal

| Característica | CountryPickerModal | CitySearchPickerModal |
|----------------|-------------------|----------------------|
| **Búsqueda** | Síncrona local | Asíncrona vía API |
| **Datos** | Lista fija de países | Ciudades dinámicas |
| **Loading state** | No necesario | Requiere loading indicator |
| **Filtrado** | Instantáneo | Con latencia de red |
| **Validación mínima** | No | Sí (3 caracteres) |
| **Error handling** | No necesario | Try-catch con fallbacks |
| **Performance** | Siempre rápida | Depende de red |
| **Datos mostrados** | País, timezone, offset | Ciudad, país, timezone |
| **Mejor para** | Selección de país/región | Selección de ubicación específica |

### vs. Standard CupertinoPicker

| Característica | CountryPickerModal | CupertinoPicker |
|----------------|-------------------|-----------------|
| **UI** | Lista scrollable con búsqueda | Rueda giratoria (wheel) |
| **Búsqueda** | Sí, con campo de texto | No |
| **Platform-specific** | Adaptativo (iOS/Android) | Solo estilo iOS |
| **Mejor para** | Listas largas (países) | Listas cortas predefinidas |

### vs. DropdownButton

| Característica | CountryPickerModal | DropdownButton |
|----------------|-------------------|----------------|
| **UI** | Modal full-screen o bottom sheet | Dropdown overlay |
| **Búsqueda** | Sí | No (solo scroll) |
| **Escalabilidad** | Excelente para 200+ países | Tedioso para listas muy largas |
| **Banderas/iconos** | Sí, con emojis grandes | Limitado |
| **Mejor para** | Selección de país con búsqueda | Listas cortas sin búsqueda |

## 14. Possible Improvements

1. **Uso del parámetro `initialCountry`**
   - **Problema actual:** El parámetro existe pero no se usa en la implementación
   - **Mejora:** Auto-scroll al país inicial y/o marcarlo visualmente
   ```dart
   @override
   void initState() {
     super.initState();
     _controller = widget.searchController ?? TextEditingController();
     _filtered = CountryService.getAllCountries();

     // Nuevo: scroll al país inicial
     if (widget.initialCountry != null) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         _scrollToCountry(widget.initialCountry!);
       });
     }
   }
   ```
   - **Beneficio:** Mejor UX al abrir el picker con un país ya seleccionado

2. **Cacheo de offsets de timezone**
   - **Problema actual:** `getCurrentOffset()` se llama para cada país en cada build
   - **Mejora:** Cachear offsets calculados
   ```dart
   Map<String, String> _offsetCache = {};

   String _getOffset(String timezone) {
     if (!_offsetCache.containsKey(timezone)) {
       _offsetCache[timezone] = TimezoneService.getCurrentOffset(timezone);
     }
     return _offsetCache[timezone]!;
   }
   ```
   - **Beneficio:** Reduce cálculos redundantes, mejora performance de scroll

3. **Indicador visual del país seleccionado**
   - **Problema actual:** No hay indicación visual de cuál país está actualmente seleccionado
   - **Mejora:** Checkmark o highlight en el país activo
   ```dart
   trailing: widget.initialCountry?.code == country.code
     ? Icon(Icons.check, color: Theme.of(context).primaryColor)
     : null,
   ```
   - **Beneficio:** Usuario sabe qué país tiene seleccionado actualmente

4. **Agrupación alfabética con headers**
   - **Problema actual:** Lista larga sin agrupación visual
   - **Mejora:** Headers de sección por letra
   ```dart
   ListView.builder(
     itemBuilder: (context, index) {
       if (_shouldShowHeader(index)) {
         return _buildSectionHeader(_filtered[index].name[0]);
       }
       return _buildCountryTile(_filtered[index]);
     },
   )
   ```
   - **Beneficio:** Navegación más fácil en listas muy largas

5. **Búsqueda por código de país**
   - **Problema actual:** No está claro si la búsqueda funciona con códigos (ej: "ES", "US")
   - **Mejora:** Documentar y asegurar que funciona con códigos
   - **Ejemplo de búsqueda mejorada:**
     - "Spain" → España
     - "ES" → España
     - "spa" → España
   - **Beneficio:** Usuarios avanzados pueden buscar por código ISO

6. **Países favoritos o recientes**
   - **Problema actual:** No hay acceso rápido a países frecuentes
   - **Mejora:** Sección de países recientes o favoritos al inicio
   ```dart
   if (searchQuery.isEmpty && recentCountries.isNotEmpty) {
     return Column(
       children: [
         _buildRecentSection(),
         Divider(),
         _buildAllCountriesSection(),
       ],
     );
   }
   ```
   - **Beneficio:** Acceso más rápido a países usados frecuentemente

7. **Sorting options**
   - **Problema actual:** Países probablemente ordenados alfabéticamente, sin otras opciones
   - **Mejora:** Opciones de ordenamiento
     - Alfabético (actual)
     - Por timezone offset
     - Por frecuencia de uso
   - **Beneficio:** Flexibilidad según caso de uso

8. **Resaltado de texto de búsqueda**
   - **Problema actual:** No se resalta qué parte del nombre coincide con la búsqueda
   - **Mejora:** Highlight del texto buscado
   ```dart
   title: RichText(
     text: TextSpan(
       children: _highlightMatches(country.name, _controller.text),
     ),
   ),
   ```
   - **Beneficio:** Claridad visual de por qué aparece un resultado

9. **Accessibilidad mejorada**
   - **Problema actual:** No hay semántica específica para lectores de pantalla
   - **Mejora:** Añadir `Semantics` widgets
   ```dart
   Semantics(
     label: 'Lista de países. ${_filtered.length} países encontrados',
     child: ListView.builder(...),
   )
   ```
   - **Beneficio:** Mejor experiencia para usuarios con discapacidades visuales

10. **Modo de selección: solo timezone vs país completo**
    - **Problema actual:** Siempre selecciona país completo
    - **Mejora:** Opción para seleccionar solo timezone
    ```dart
    final bool selectTimezoneOnly;
    ```
    - **Uso:** Cuando solo interesa la timezone, no el país específico
    - **Beneficio:** Mayor flexibilidad de uso del widget

11. **Animaciones de transición**
    - **Problema actual:** Lista aparece y filtra abruptamente
    - **Mejora:** Animaciones suaves
    ```dart
    AnimatedList(
      key: _listKey,
      itemBuilder: (context, index, animation) {
        return SizeTransition(
          sizeFactor: animation,
          child: _buildCountryTile(_filtered[index]),
        );
      },
    )
    ```
    - **Beneficio:** Transiciones más profesionales

12. **Empty state cuando no hay resultados**
    - **Problema actual:** Lista vacía sin mensaje si búsqueda no tiene resultados
    - **Mejora:** Mensaje informativo
    ```dart
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No se encontraron países'),
            Text('Intenta con otro término de búsqueda'),
          ],
        ),
      );
    }
    ```
    - **Beneficio:** Mejor feedback cuando no hay resultados

## 15. Real-World Usage Context

### En el contexto de la aplicación EventyPop

`CountryPickerModal` se utiliza principalmente en flujos donde se necesita especificar un país, típicamente como primer paso antes de seleccionar una ciudad específica.

**Flujos típicos de uso:**

1. **Configuración de ubicación de eventos:**
   ```
   Usuario crea evento
   → Selecciona país (CountryPickerModal)
   → Selecciona ciudad (CitySearchPickerModal filtrada por país)
   → Sistema obtiene timezone automáticamente
   ```

2. **Perfil de usuario:**
   ```
   Usuario configura perfil
   → Selecciona país de residencia (CountryPickerModal)
   → Sistema usa timezone del país para mostrar fechas/horas correctas
   ```

3. **Filtros de búsqueda:**
   ```
   Usuario busca eventos
   → Filtra por país (CountryPickerModal)
   → Ve eventos solo de ese país
   ```

### Integración con otros widgets

**Patrón común con CountryTimezoneSelector:**
```dart
// CountryTimezoneSelector (widget 17) probablemente usa este modal internamente
CountryTimezoneSelector(
  onChanged: (country, timezone, city) {
    // country seleccionado vía CountryPickerModal
    // timezone del país seleccionado
    // city opcional vía CitySearchPickerModal
  }
)
```

### Diferencias de UX entre plataformas

**iOS (full-screen):**
- Mejor para usuarios que prefieren enfoque completo en selección
- Navegación nativa con botón "Cancelar"
- Más espacio para lista larga de países

**Android (bottom sheet):**
- Mantiene contexto visible (20% de pantalla de fondo)
- Más rápido de cerrar (swipe down)
- Diseño más compacto

## 16. Performance Considerations

### Synchronous Search Performance
- **Ventaja:** Filtrado instantáneo sin latency
- **Complejidad:** O(n) donde n = número de países (~200)
- **Tiempo típico:** < 1ms en dispositivos modernos
- **No requiere:** Debouncing, throttling, o cancelación

### List Rendering Performance
- **ListView.builder:** Lazy rendering, solo renderiza items visibles
- **Performance:** Excelente incluso con 200+ países
- **Scroll:** Suave gracias a ClampingScrollPhysics
- **Memory:** Baja, solo mantiene widgets visibles en memoria

### Offset Calculation Performance
- **Cálculo:** `TimezoneService.getCurrentOffset()` por cada país visible
- **Frecuencia:** En cada build (cada vez que aparece un item)
- **Costo:** Depende de implementación de TimezoneService
- **Optimización recomendada:** Cacheo de offsets (ver mejora #2)

**Medición aproximada:**
- 200 países × cálculo de offset (si showOffset: true)
- Solo países visibles se calculan (gracias a ListView.builder)
- Típicamente 10-15 países visibles simultáneamente
- Cálculos totales: ~15 por frame de scroll

### Platform-Specific Performance
- **iOS (full-screen):** Potencialmente más memoria (página completa)
- **Android (bottom sheet):** Más eficiente en memoria
- **Ambos:** Performance similar gracias a ListView.builder

### Memory Management
- **TextEditingController:** Correctamente disposed si es interno
- **Controller externo:** No disposed, responsabilidad del padre
- **Lista de países:** Reutiliza lista de CountryService (no copia)
- **Filtrado:** Crea nueva lista filtrada en cada búsqueda (no muta original)

## 17. Security and Privacy Considerations

### Data Privacy
- **Datos locales:** Toda la búsqueda es local, no se envía información a servidores
- **Privacidad:** Selección de país puede revelar ubicación/intereses del usuario
- **Persistencia:** Si se guarda país seleccionado, considerar cifrado si datos son sensibles

### Input Sanitization
- **Búsqueda local:** Query de búsqueda no se envía a servidor
- **No SQL injection:** Filtrado en memoria, no hay queries SQL
- **Riesgo:** Bajo, solo filtrado de strings locales

### Timezone Offset Calculation
- **Tiempo real:** Usa timezone del dispositivo para calcular offsets
- **DST-aware:** Considera horario de verano actual
- **No requiere:** Permisos de ubicación ni acceso a internet
- **Datos públicos:** Offsets de timezone son información pública

### Data Exposure
- **Información mostrada:** Nombres de países, banderas, timezones, offsets
- **Sensibilidad:** Datos geográficos públicos, sin riesgo de seguridad
- **No expone:** Ubicación actual del usuario ni datos personales

### Memory Safety
- **Controller lifecycle:** Correctamente gestionado con conditional disposal
- **No memory leaks:** Recursos liberados apropiadamente en dispose
- **Safe state updates:** No hay await sin mounted checks (búsqueda síncrona)

---

**Última actualización:** 2025-11-03
**Widget documentado:** 25 de 26 (falta verificar si hay más widgets o si son 25 totales)
**Nota:** Revisar lista completa de widgets para confirmar recuento final.
