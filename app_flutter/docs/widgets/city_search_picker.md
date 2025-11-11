# CitySearchPickerModal

## 1. Overview

`CitySearchPickerModal` es un widget modal especializado para búsqueda y selección de ciudades con adaptación completa de plataforma (iOS/Android). Proporciona una interfaz de búsqueda en tiempo real que consulta un servicio de ciudades, con capacidad de filtrado opcional por país, estados de carga, y experiencia de usuario optimizada para cada plataforma.

El widget implementa dos interfaces completamente distintas: en iOS utiliza `CupertinoPageScaffold` con navegación nativa, mientras que en Android usa un modal bottom sheet con diseño Material. Esta dualidad permite mantener la coherencia con las convenciones de diseño de cada plataforma mientras comparte la misma lógica de negocio subyacente.

**Propósito principal:**
- Búsqueda asíncrona de ciudades con mínimo de 3 caracteres
- Filtrado opcional por código de país para búsquedas contextuales
- Presentación de resultados con banderas de países, nombres de ciudades y zonas horarias
- Adaptación completa de UI según plataforma (iOS vs Android)
- Gestión de estados de loading y resultados vacíos
- Callback de selección con objeto `City` completo

## 2. File Location

**Path:** `/Users/miquelfarre/development/agenda_phoenix/app_flutter/lib/widgets/pickers/city_search_picker.dart`

**Ubicación en la arquitectura:**
- **Capa:** Presentation Layer - Pickers
- **Categoría:** Modal Picker Widget
- **Subcarpeta:** `pickers/` - agrupa widgets especializados en selección de datos específicos

## 3. Dependencies

### External Dependencies

```dart
import 'package:flutter/cupertino.dart';
```
**Propósito:** Framework de widgets estilo iOS. Proporciona `CupertinoPageScaffold`, `CupertinoNavigationBar`, `CupertinoTextField`, `CupertinoIcons`, y otros componentes nativos de iOS.

### Internal Dependencies

```dart
import 'package:eventypop/models/city.dart';
```
**Propósito:** Modelo de datos `City` que representa una ciudad con propiedades como `name`, `countryCode`, `timezone`. Es el tipo de dato que retorna la búsqueda y que se pasa al callback `onSelected`.

```dart
import 'package:eventypop/services/city_service.dart';
```
**Propósito:** Servicio que proporciona `searchCities(String query)` para búsqueda asíncrona de ciudades. Retorna `Future<List<City>>`.

```dart
import 'package:eventypop/services/country_service.dart';
```
**Propósito:** Servicio que proporciona `getCountryByCode(String code)` para obtener información de países, específicamente usado para obtener banderas (emojis) de países.

```dart
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
```
**Propósito:** Helper que proporciona widgets adaptativos cross-platform:
- `platformIcon()` - Iconos adaptativos
- `platformLoadingIndicator()` - Spinner de carga adaptativo
- `platformTextField()` - Campo de texto adaptativo
- `platformListTile()` - List item adaptativo

```dart
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
```
**Propósito:** Utilidad para detectar la plataforma actual. Proporciona `PlatformDetection.isIOS` que determina qué UI renderizar.

```dart
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
```
**Propósito:** Sistema de localización. Proporciona extensión `context.l10n` con traducciones:
- `searchCity` - Título del modal
- `cancel` - Texto del botón cancelar
- `citySearchPlaceholder` - Placeholder del campo de búsqueda
- `countryCodeDotTimezone(code, tz)` - Formato "CODE · TIMEZONE"
- `worldFlag` - Emoji de mundo como fallback

```dart
import 'package:eventypop/ui/styles/app_styles.dart';
```
**Propósito:** Estilos globales de la aplicación:
- `headlineSmall` - Estilo para banderas (emojis grandes)
- `cardTitle` - Estilo para título del modal
- `cardSubtitle` - Estilo para subtítulos de ciudades
- `grey600` - Color gris para texto secundario

```dart
import 'package:eventypop/widgets/adaptive/adaptive_button.dart';
```
**Propósito:** Botón adaptativo usado para botones de cancelar/cerrar. Utiliza `AdaptiveButtonConfig` para configuración de variantes (secondary, icon).

### Type Definition

```dart
typedef CitySelected = void Function(City city);
```
**Línea:** 11

**Propósito:** Define el tipo para el callback de selección. Mejora la legibilidad del código al dar un nombre semántico al tipo de función.

## 4. Class Declaration

```dart
class CitySearchPickerModal extends StatefulWidget {
```
**Línea:** 13

**Decisión de diseño:** `StatefulWidget`

**Justificación:**
1. **Estado de búsqueda:** Necesita mantener `_searchController`, `_results`, `_isLoading`
2. **Interacción asíncrona:** La búsqueda es asíncrona y los resultados deben actualizar la UI
3. **Gestión de TextEditingController:** Requiere inicialización en `initState` y limpieza en `dispose`
4. **Estados de carga:** Debe mostrar indicadores de carga durante búsquedas
5. **Resultados dinámicos:** La lista de resultados cambia conforme el usuario escribe

## 5. Properties Analysis

### Required Properties

```dart
final CitySelected onSelected;
```
**Línea:** 15

**Tipo:** `CitySelected` (alias de `void Function(City city)`)

**Propósito:** Callback invocado cuando el usuario selecciona una ciudad de los resultados. Recibe el objeto `City` completo con toda su información (nombre, código de país, timezone).

**Flujo de ejecución:**
1. Usuario toca un resultado de búsqueda (líneas 100, 155)
2. Se invoca `widget.onSelected(city)` con la ciudad seleccionada
3. Se cierra el modal con `Navigator.of(context).pop()`
4. El widget padre recibe la ciudad seleccionada y puede procesarla

### Optional Properties

```dart
final String? initialCountryCode;
```
**Línea:** 14

**Tipo:** `String?` (nullable)

**Default:** `null`

**Propósito:** Código de país opcional para filtrar resultados de búsqueda. Cuando se proporciona, solo se muestran ciudades de ese país específico.

**Implementación del filtrado (línea 46):**
```dart
final filtered = widget.initialCountryCode != null
  ? res.where((c) => c.countryCode == widget.initialCountryCode).toList()
  : res;
```

**Casos de uso:**
- `initialCountryCode: null` → Búsqueda global de ciudades
- `initialCountryCode: "ES"` → Solo ciudades de España
- `initialCountryCode: "US"` → Solo ciudades de Estados Unidos

**Beneficio:** Reduce ruido en resultados cuando el contexto ya especifica un país.

## 6. State Variables

```dart
final TextEditingController _searchController = TextEditingController();
```
**Línea:** 24

**Propósito:** Controla el campo de texto de búsqueda. Permite acceder al valor actual del texto y debe ser disposed apropiadamente.

**Lifecycle:**
- Inicializado en la declaración de la variable de estado
- Usado en `CupertinoTextField`/`platformTextField` (líneas 79, 136)
- Disposed en `dispose()` método (línea 30)

---

```dart
List<City> _results = [];
```
**Línea:** 25

**Propósito:** Almacena los resultados de búsqueda obtenidos de `CityService.searchCities()`.

**Estados posibles:**
- `[]` (vacío) → Estado inicial, búsqueda con < 3 caracteres, o búsqueda sin resultados
- `[City(...), City(...), ...]` → Resultados de búsqueda activa

**Actualización:**
- Línea 37: Se vacía cuando query < 3 caracteres
- Línea 48: Se actualiza con resultados filtrados
- Línea 52: Se vacía en caso de error

---

```dart
bool _isLoading = false;
```
**Línea:** 26

**Propósito:** Indica si hay una búsqueda en progreso. Controla la visualización del loading indicator.

**Estados:**
- `false` → No hay búsqueda activa, mostrar resultados o estado vacío
- `true` → Búsqueda en progreso, mostrar loading indicator

**Gestión:**
- Línea 38: Se pone en `false` si query < 3 caracteres
- Línea 43: Se pone en `true` antes de iniciar búsqueda
- Línea 55: Se pone en `false` en el bloque `finally` (garantiza reset incluso con errores)

## 7. Lifecycle Methods

### 7.1. dispose

```dart
@override
void dispose() {
  _searchController.dispose();
  super.dispose();
}
```
**Líneas:** 29-32

**Propósito:** Liberar recursos cuando el widget se elimina del árbol de widgets.

**Análisis línea por línea:**

**Línea 30:** `_searchController.dispose();`
- Libera recursos del `TextEditingController`
- Previene memory leaks eliminando listeners internos
- DEBE llamarse antes de que el widget sea destruido

**Línea 31:** `super.dispose();`
- Llama al método dispose de la clase padre
- DEBE ser la última línea del método dispose
- Completa el proceso de limpieza

**Importancia:** Sin este método, el `TextEditingController` mantendría referencias que causarían memory leaks, especialmente si el modal se abre/cierra frecuentemente.

## 8. Methods

### 8.1. _search

```dart
Future<void> _search(String q) async {
  if (q.length < 3) {
    setState(() {
      _results = [];
      _isLoading = false;
    });
    return;
  }

  setState(() => _isLoading = true);
  try {
    final res = await CityService.searchCities(q);
    final filtered = widget.initialCountryCode != null
      ? res.where((c) => c.countryCode == widget.initialCountryCode).toList()
      : res;
    setState(() {
      _results = filtered;
    });
  } catch (_) {
    setState(() {
      _results = [];
    });
  } finally {
    setState(() => _isLoading = false);
  }
}
```
**Líneas:** 34-57

**Propósito:** Ejecutar búsqueda asíncrona de ciudades con validación de longitud mínima, manejo de errores, y filtrado opcional por país.

**Análisis línea por línea:**

**Línea 34:** `Future<void> _search(String q) async {`
- Método asíncrono que recibe el query de búsqueda
- `Future<void>` indica que es async pero no retorna valor
- Parámetro `q` es el texto ingresado por el usuario

**Líneas 35-41:** Validación de longitud mínima
```dart
if (q.length < 3) {
  setState(() {
    _results = [];
    _isLoading = false;
  });
  return;
}
```
- **Validación:** Requiere mínimo 3 caracteres para buscar
- **Razón:** Previene búsquedas demasiado genéricas que retornarían miles de resultados
- **Acción:** Vacía resultados y desactiva loading si query es muy corto
- **Early return:** Sale del método sin ejecutar búsqueda

**Línea 43:** `setState(() => _isLoading = true);`
- Activa el estado de carga ANTES de la llamada async
- Esto muestra el loading indicator inmediatamente
- Mejora la percepción de respuesta de la UI

**Línea 45:** `final res = await CityService.searchCities(q);`
- Llama al servicio de búsqueda de ciudades
- `await` pausa la ejecución hasta que la búsqueda completa
- `res` contiene la lista completa de resultados (sin filtrar por país aún)

**Líneas 46-47:** Filtrado condicional por país
```dart
final filtered = widget.initialCountryCode != null
  ? res.where((c) => c.countryCode == widget.initialCountryCode).toList()
  : res;
```
- **Condicional ternaria:** Si hay `initialCountryCode`, filtra; si no, usa resultados completos
- **Filtrado:** `where((c) => c.countryCode == widget.initialCountryCode)` mantiene solo ciudades del país especificado
- **toList():** Convierte el Iterable resultante de `where()` a List
- **Performance:** El filtrado ocurre en cliente, no en servidor

**Líneas 47-49:** Actualización de resultados
```dart
setState(() {
  _results = filtered;
});
```
- Actualiza el estado con los resultados filtrados
- Esto dispara un rebuild que muestra los resultados en el ListView

**Líneas 50-53:** Manejo de errores
```dart
catch (_) {
  setState(() {
    _results = [];
  });
}
```
- **Captura genérica:** `catch (_)` captura cualquier error sin usar el objeto de error
- **Acción:** Vacía los resultados en caso de error
- **UX:** No muestra mensaje de error al usuario, simplemente no muestra resultados
- **Posible mejora:** Podría mostrar un mensaje de error o log para debugging

**Líneas 54-56:** Cleanup final
```dart
finally {
  setState(() => _isLoading = false);
}
```
- **Garantía:** `finally` SIEMPRE se ejecuta, haya éxito o error
- **Acción:** Desactiva el loading indicator
- **Importancia:** Sin esto, el loading indicator podría quedarse activo indefinidamente si hay un error

**Observaciones importantes:**

1. **No hay debouncing:** El método se llama en cada cambio del TextField (`onChanged`). Esto puede causar muchas llamadas API si el usuario escribe rápido.

2. **No hay cancelación de búsquedas previas:** Si una búsqueda anterior aún está en progreso cuando se inicia una nueva, ambas continuarán y la última en completar "ganará".

3. **No hay mounted check:** Después del `await`, debería verificar `if (!mounted) return;` para prevenir llamadas a `setState` en un widget desmontado.

4. **Filtrado client-side:** El filtrado por país ocurre después de recibir resultados. Sería más eficiente si el servicio aceptara el código de país como parámetro.

### 8.2. _flagFor

```dart
String _flagFor(String code) {
  final country = CountryService.getCountryByCode(code);
  return country?.flag ?? context.l10n.worldFlag;
}
```
**Líneas:** 59-62

**Propósito:** Obtener el emoji de bandera para un código de país, con fallback a un emoji de mundo.

**Análisis línea por línea:**

**Línea 60:** `final country = CountryService.getCountryByCode(code);`
- Busca el país usando el código (ej: "ES", "US", "FR")
- Retorna un objeto `Country` o `null` si no se encuentra
- Operación probablemente síncrona (lookup en mapa o lista)

**Línea 61:** `return country?.flag ?? context.l10n.worldFlag;`
- **Null-safe access:** `country?.flag` retorna `null` si `country` es `null`
- **Operador ??:** Si `country?.flag` es `null`, usa `context.l10n.worldFlag` como fallback
- **Emojis de banderas:** Las banderas son emojis Unicode (🇪🇸, 🇺🇸, etc.)
- **Fallback localizado:** `worldFlag` probablemente es 🌍 u otro emoji de mundo

**Uso en el widget:**
- Líneas 96, 151: Se usa como `leading` en los list tiles
- Estilo aplicado: `fontSize: 24` para hacer la bandera bien visible

## 9. Build Method

El método `build` implementa dos UIs completamente diferentes según la plataforma:

```dart
@override
Widget build(BuildContext context) {
  final l10n = context.l10n;
  if (PlatformDetection.isIOS) {
    // iOS UI
  }
  // Android UI
}
```
**Líneas:** 65-165

### 9.1. iOS UI (CupertinoPageScaffold)

**Líneas:** 67-110

**Estructura general:**
```dart
if (PlatformDetection.isIOS) {
  return CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(...),
    child: SafeArea(
      child: Column(
        children: [
          Padding(...) // Search field
          Expanded(...) // Results list
        ],
      ),
    ),
  );
}
```

**Análisis detallado:**

**Línea 68:** `return CupertinoPageScaffold(`
- Scaffold estilo iOS con navegación Cupertino
- Proporciona estructura de página con navigation bar

**Líneas 69-72:** Navigation Bar
```dart
navigationBar: CupertinoNavigationBar(
  middle: Text(l10n.searchCity),
  leading: AdaptiveButton(
    config: AdaptiveButtonConfig.secondary(),
    text: l10n.cancel,
    onPressed: () => Navigator.of(context).pop()
  ),
),
```
- **middle:** Título centrado "Buscar ciudad" (localizado)
- **leading:** Botón "Cancelar" en la izquierda
- **Acción:** Cierra el modal sin seleccionar nada
- **AdaptiveButton:** Usa configuración secundaria para estilo apropiado

**Línea 73:** `child: SafeArea(`
- Previene que el contenido se solape con notch, status bar, etc.
- Crítico en iOS para evitar que contenido quede detrás de áreas del sistema

**Líneas 76-84:** Campo de búsqueda
```dart
Padding(
  padding: const EdgeInsets.all(16.0),
  child: CupertinoTextField(
    controller: _searchController,
    placeholder: l10n.citySearchPlaceholder,
    onChanged: (v) => _search(v),
    prefix: Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: PlatformWidgets.platformIcon(CupertinoIcons.search)
    ),
  ),
),
```
- **CupertinoTextField:** Campo de texto estilo iOS
- **placeholder:** Texto de hint localizado
- **onChanged:** Dispara búsqueda en cada cambio de texto
- **prefix:** Icono de búsqueda a la izquierda con padding

**Líneas 85-106:** Área de resultados
```dart
Expanded(
  child: _isLoading
    ? Center(child: PlatformWidgets.platformLoadingIndicator())
    : (_results.isEmpty
        ? const SizedBox.shrink()
        : ListView.builder(...)
    )
)
```

**Lógica de renderizado condicional:**
1. **Si `_isLoading` es true:** Muestra spinner centrado
2. **Si no está cargando y `_results` está vacío:** Muestra `SizedBox.shrink()` (widget invisible de tamaño cero)
3. **Si no está cargando y hay resultados:** Muestra `ListView.builder` con los resultados

**ListView.builder (líneas 90-105):**
```dart
ListView.builder(
  physics: const ClampingScrollPhysics(),
  itemCount: _results.length,
  itemBuilder: (context, index) {
    final city = _results[index];
    return PlatformWidgets.platformListTile(
      leading: Text(_flagFor(city.countryCode), style: ...),
      title: Text(city.name),
      subtitle: Text(l10n.countryCodeDotTimezone(...), style: ...),
      onTap: () {
        widget.onSelected(city);
        Navigator.of(context).pop();
      },
    );
  },
)
```

**Características:**
- **ClampingScrollPhysics:** Scroll sin efecto de rebote (más típico de Android, pero usado aquí)
- **leading:** Emoji de bandera grande (fontSize: 24)
- **title:** Nombre de la ciudad
- **subtitle:** "CODE · TIMEZONE" (ej: "ES · Europe/Madrid")
- **onTap:** Invoca callback y cierra modal

### 9.2. Android UI (Bottom Sheet Modal)

**Líneas:** 113-164

**Estructura general:**
```dart
final modalHeight = MediaQuery.of(context).size.height * 0.8;
return SizedBox(
  height: modalHeight,
  child: Column(
    children: [
      Container(...) // Header with title and close button
      Expanded(...) // Results list
    ],
  ),
);
```

**Análisis detallado:**

**Línea 113:** `final modalHeight = MediaQuery.of(context).size.height * 0.8;`
- Calcula altura del modal como 80% de la altura de pantalla
- Permite scroll del contenido si hay muchos resultados
- Deja 20% visible del fondo para indicar que es un modal

**Líneas 118-139:** Header del modal
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

**Row con título y botón cerrar (líneas 123-134):**
```dart
Row(
  children: [
    Expanded(
      child: Text(
        l10n.searchCity,
        style: AppStyles.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.bold)
      ),
    ),
    AdaptiveButton(
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
- **Expanded en título:** Ocupa todo el espacio disponible, empujando el botón a la derecha
- **AdaptiveButton como icono:** Solo muestra icono sin texto
- **Icono:** `CupertinoIcons.clear` (X para cerrar)

**Campo de búsqueda (línea 136):**
```dart
PlatformWidgets.platformTextField(
  controller: _searchController,
  hintText: l10n.citySearchPlaceholder,
  prefixIcon: PlatformWidgets.platformIcon(CupertinoIcons.search, size: 20),
  onChanged: (v) => _search(v)
)
```
- **platformTextField:** Versión adaptativa del campo de texto
- **prefixIcon:** Icono de búsqueda más pequeño (size: 20) que en iOS

**Área de resultados (líneas 140-161):**
Idéntica lógica que en iOS:
- Loading indicator centrado si `_isLoading`
- `SizedBox.shrink()` si resultados vacíos
- `ListView.builder` con resultados si hay datos

**Diferencias sutiles con iOS:**
- Mismo `platformListTile` pero puede renderizar diferente según plataforma
- Mismos estilos aplicados
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
| **Border radius** | Sin (full screen) | Top corners redondeadas |

**Consistencias:**
- Misma lógica de búsqueda y filtrado
- Mismo formato de resultados (bandera, ciudad, código · timezone)
- Mismo comportamiento de selección y cierre
- Mismos estados de loading

## 10. Technical Characteristics

### Platform Adaptation Strategy
- **Detección:** Usa `PlatformDetection.isIOS` para branch de UI
- **iOS:** Full-screen modal con navegación Cupertino
- **Android:** Bottom sheet modal con altura 80%
- **Lógica compartida:** Todo el código de búsqueda y estado es idéntico
- **Separación clara:** Solo el `build()` diverge según plataforma

### Asynchronous Search Pattern
- **Trigger:** Búsqueda se dispara en cada `onChanged` del TextField
- **Validación:** Mínimo 3 caracteres antes de buscar
- **Loading state:** Spinner mostrado durante búsquedas
- **Error handling:** Errores resultan en lista vacía (sin mensaje visible al usuario)
- **No debouncing:** Cada keystroke dispara búsqueda (potencial para optimización)

### State Management
- **Local state:** Todo el estado es local al widget (no Riverpod, no Provider)
- **Estados:** `_searchController`, `_results`, `_isLoading`
- **Inmutabilidad:** Los resultados se reemplazan completamente, no se mutan
- **Lifecycle:** `TextEditingController` disposed correctamente

### Filtering Strategy
- **Client-side filtering:** El filtrado por país ocurre después de recibir resultados
- **Trade-off:** Simple pero menos eficiente que filtrado server-side
- **Ventaja:** No requiere cambios en la API
- **Desventaja:** Transfiere datos innecesarios si hay filtro de país

### Navigation Pattern
- **Modal navigation:** Se presenta como modal (probablemente via `showModalBottomSheet` o `Navigator.push`)
- **Cierre:** Navigator.pop() sin valor de retorno
- **Callback pattern:** Usa `onSelected` callback en lugar de retornar valor via pop
- **Orden:** Callback se llama ANTES de pop (líneas 100, 155)

### UI States
1. **Initial state:** Campo vacío, sin resultados, no loading
2. **Typing < 3 chars:** Sin resultados, no loading
3. **Loading:** Spinner centrado, no resultados
4. **Results displayed:** ListView con ciudades
5. **No results (after search):** `SizedBox.shrink()` (nada visible)
6. **Error state:** Misma UI que "No results"

### Type Safety
- **Typedef:** `CitySelected` mejora legibilidad
- **Genéricos:** `List<City>` tipado explícitamente
- **Null safety:** Uso apropiado de `?`, `??`, null checks

## 11. Usage Examples

### Example 1: Basic Global City Search

```dart
class EventLocationForm extends StatefulWidget {
  @override
  _EventLocationFormState createState() => _EventLocationFormState();
}

class _EventLocationFormState extends State<EventLocationForm> {
  City? selectedCity;

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CitySearchPickerModal(
        onSelected: (city) {
          setState(() {
            selectedCity = city;
          });
          print('Ciudad seleccionada: ${city.name}, ${city.countryCode}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Ubicación del evento'),
          subtitle: Text(selectedCity?.name ?? 'Ninguna ciudad seleccionada'),
          trailing: Icon(Icons.location_city),
          onTap: _showCityPicker,
        ),
        if (selectedCity != null)
          Text('Zona horaria: ${selectedCity!.timezone}'),
      ],
    );
  }
}
```

**Características:**
- Búsqueda global sin filtro de país
- Presentación como bottom sheet modal
- Estado manejado en widget padre
- Feedback visual de ciudad seleccionada

### Example 2: Country-Filtered City Search

```dart
class CountrySpecificForm extends StatefulWidget {
  final String countryCode;

  const CountrySpecificForm({required this.countryCode});

  @override
  _CountrySpecificFormState createState() => _CountrySpecificFormState();
}

class _CountrySpecificFormState extends State<CountrySpecificForm> {
  City? selectedCity;

  void _showCityPicker() {
    // iOS: Navigator.push para full-screen modal
    if (PlatformDetection.isIOS) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => CitySearchPickerModal(
            initialCountryCode: widget.countryCode,
            onSelected: (city) {
              setState(() {
                selectedCity = city;
              });
            },
          ),
        ),
      );
    } else {
      // Android: Bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => CitySearchPickerModal(
          initialCountryCode: widget.countryCode,
          onSelected: (city) {
            setState(() {
              selectedCity = city;
            });
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final countryName = CountryService.getCountryByCode(widget.countryCode)?.name ?? widget.countryCode;

    return Card(
      child: ListTile(
        leading: Icon(Icons.location_city),
        title: Text('Ciudad en $countryName'),
        subtitle: Text(selectedCity?.name ?? 'Toca para seleccionar'),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showCityPicker,
      ),
    );
  }
}
```

**Características:**
- Filtrado por país específico usando `initialCountryCode`
- Presentación adaptativa según plataforma
- iOS: Full-screen modal via CupertinoPageRoute
- Android: Bottom sheet con bordes redondeados
- Muestra nombre del país en el título

### Example 3: Integration with Form Validation

```dart
class EventDetailsForm extends StatefulWidget {
  @override
  _EventDetailsFormState createState() => _EventDetailsFormState();
}

class _EventDetailsFormState extends State<EventDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  City? selectedCity;
  String? eventName;

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CitySearchPickerModal(
        onSelected: (city) {
          setState(() {
            selectedCity = city;
          });
          // Trigger form validation after selection
          _formKey.currentState?.validate();
        },
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      print('Creando evento "$eventName" en ${selectedCity!.name}');
      print('Zona horaria: ${selectedCity!.timezone}');

      // Create event with timezone-aware DateTime
      // ...
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Nombre del evento'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa un nombre';
              }
              return null;
            },
            onSaved: (value) => eventName = value,
          ),

          SizedBox(height: 16),

          // City selector with validation
          FormField<City>(
            initialValue: selectedCity,
            validator: (value) {
              if (value == null) {
                return 'Por favor selecciona una ciudad';
              }
              return null;
            },
            builder: (FormFieldState<City> field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _showCityPicker,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Ciudad',
                        errorText: field.errorText,
                        suffixIcon: Icon(Icons.search),
                      ),
                      child: Text(
                        selectedCity?.name ?? 'Toca para buscar',
                        style: TextStyle(
                          color: selectedCity != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 24),

          ElevatedButton(
            onPressed: _submitForm,
            child: Text('Crear Evento'),
          ),
        ],
      ),
    );
  }
}
```

**Características:**
- Integración completa con `Form` y `FormField`
- Validación requerida de ciudad
- Trigger de validación después de selección
- UI consistente con otros campos del formulario
- Manejo de timezone para eventos

### Example 4: Multiple City Selection (Modified)

```dart
class MultiCityTourForm extends StatefulWidget {
  @override
  _MultiCityTourFormState createState() => _MultiCityTourFormState();
}

class _MultiCityTourFormState extends State<MultiCityTourForm> {
  List<City> tourCities = [];

  void _addCity() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CitySearchPickerModal(
        onSelected: (city) {
          setState(() {
            // Prevent duplicates
            if (!tourCities.any((c) => c.name == city.name && c.countryCode == city.countryCode)) {
              tourCities.add(city);
            } else {
              PlatformDialogHelpers.showSnackBar(
                context: context,
                message: 'Esta ciudad ya está en la lista',
              );
            }
          });
        },
      ),
    );
  }

  void _removeCity(int index) {
    setState(() {
      tourCities.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ciudades del tour', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 8),

        // List of selected cities
        ...tourCities.asMap().entries.map((entry) {
          final index = entry.key;
          final city = entry.value;
          return Card(
            child: ListTile(
              leading: Text(
                CountryService.getCountryByCode(city.countryCode)?.flag ?? '🌍',
                style: TextStyle(fontSize: 24),
              ),
              title: Text(city.name),
              subtitle: Text('${city.countryCode} · ${city.timezone}'),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeCity(index),
              ),
            ),
          );
        }).toList(),

        SizedBox(height: 16),

        // Add city button
        OutlinedButton.icon(
          onPressed: _addCity,
          icon: Icon(Icons.add),
          label: Text('Agregar ciudad'),
        ),

        if (tourCities.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Total: ${tourCities.length} ciudades'),
          ),
      ],
    );
  }
}
```

**Características:**
- Selección múltiple de ciudades
- Prevención de duplicados
- Lista visual de ciudades seleccionadas
- Capacidad de eliminar ciudades
- Útil para tours multi-ciudad o itinerarios

### Example 5: City Search with Recent Selections Cache

```dart
class CityPickerWithRecents extends StatefulWidget {
  @override
  _CityPickerWithRecentsState createState() => _CityPickerWithRecentsState();
}

class _CityPickerWithRecentsState extends State<CityPickerWithRecents> {
  City? selectedCity;
  List<City> recentCities = [];

  @override
  void initState() {
    super.initState();
    _loadRecentCities();
  }

  Future<void> _loadRecentCities() async {
    final prefs = await SharedPreferences.getInstance();
    final recentsJson = prefs.getStringList('recent_cities') ?? [];

    if (mounted) {
      setState(() {
        recentCities = recentsJson
          .map((json) => City.fromJson(jsonDecode(json)))
          .toList();
      });
    }
  }

  Future<void> _saveRecentCity(City city) async {
    // Remove if already exists (to move to front)
    recentCities.removeWhere((c) => c.name == city.name && c.countryCode == city.countryCode);

    // Add to front
    recentCities.insert(0, city);

    // Keep only last 5
    if (recentCities.length > 5) {
      recentCities = recentCities.sublist(0, 5);
    }

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final recentsJson = recentCities.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList('recent_cities', recentsJson);
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CitySearchPickerModal(
        onSelected: (city) async {
          setState(() {
            selectedCity = city;
          });
          await _saveRecentCity(city);
        },
      ),
    );
  }

  void _selectRecentCity(City city) {
    setState(() {
      selectedCity = city;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current selection
        Card(
          child: ListTile(
            title: Text('Ciudad seleccionada'),
            subtitle: Text(selectedCity?.name ?? 'Ninguna'),
            trailing: Icon(Icons.search),
            onTap: _showCityPicker,
          ),
        ),

        if (recentCities.isNotEmpty) ...[
          SizedBox(height: 16),
          Text('Recientes', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentCities.map((city) {
              final flag = CountryService.getCountryByCode(city.countryCode)?.flag ?? '🌍';
              return ActionChip(
                label: Text('$flag ${city.name}'),
                onPressed: () => _selectRecentCity(city),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
```

**Características:**
- Cache de ciudades recientemente seleccionadas
- Persistencia usando SharedPreferences
- Chips para selección rápida de recientes
- Limita a últimas 5 ciudades
- Mejora UX evitando búsquedas repetidas

### Example 6: Integration with Country Selection Flow

```dart
class LocationSelector extends StatefulWidget {
  @override
  _LocationSelectorState createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  Country? selectedCountry;
  City? selectedCity;

  void _selectCountry() {
    // Show country picker (another widget)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CountryPickerModal(
          onSelected: (country) {
            setState(() {
              selectedCountry = country;
              selectedCity = null; // Reset city when country changes
            });
          },
        ),
      ),
    );
  }

  void _selectCity() {
    if (selectedCountry == null) {
      PlatformDialogHelpers.showSnackBar(
        context: context,
        message: 'Por favor selecciona un país primero',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CitySearchPickerModal(
        initialCountryCode: selectedCountry!.code,
        onSelected: (city) {
          setState(() {
            selectedCity = city;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Country selection
        Card(
          child: ListTile(
            leading: selectedCountry != null
              ? Text(selectedCountry!.flag, style: TextStyle(fontSize: 24))
              : Icon(Icons.public),
            title: Text('País'),
            subtitle: Text(selectedCountry?.name ?? 'Selecciona un país'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _selectCountry,
          ),
        ),

        SizedBox(height: 8),

        // City selection (enabled only if country selected)
        Card(
          color: selectedCountry == null
            ? Theme.of(context).disabledColor.withOpacity(0.1)
            : null,
          child: ListTile(
            enabled: selectedCountry != null,
            leading: Icon(Icons.location_city),
            title: Text('Ciudad'),
            subtitle: Text(selectedCity?.name ?? 'Selecciona una ciudad'),
            trailing: Icon(Icons.search, size: 16),
            onTap: _selectCity,
          ),
        ),

        if (selectedCity != null) ...[
          SizedBox(height: 16),
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ubicación seleccionada', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('${selectedCity!.name}, ${selectedCountry!.name}'),
                  Text('Zona horaria: ${selectedCity!.timezone}'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
```

**Características:**
- Flujo de dos pasos: primero país, luego ciudad
- Ciudad filtrada automáticamente por país seleccionado
- Validación: no permite seleccionar ciudad sin país
- Reset de ciudad cuando cambia el país
- Summary card con ubicación completa

## 12. Testing Recommendations

### 12.1. Unit Tests

```dart
void main() {
  group('CitySearchPickerModal Unit Tests', () {

    testWidgets('initializes with empty results and not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CitySearchPickerModal(
              onSelected: (city) {},
            ),
          ),
        ),
      );

      final state = tester.state<_CitySearchPickerModalState>(
        find.byType(CitySearchPickerModal)
      );

      expect(state._results, isEmpty);
      expect(state._isLoading, isFalse);
    });

    testWidgets('search not triggered for queries < 3 characters', (tester) async {
      bool searchCalled = false;
      // Mock CityService.searchCities to detect calls
      // This would require dependency injection or mockito

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CitySearchPickerModal(
              onSelected: (city) {},
            ),
          ),
        ),
      );

      // Enter 2 characters
      final textField = find.byType(PlatformDetection.isIOS ? CupertinoTextField : TextField);
      await tester.enterText(textField, 'AB');
      await tester.pump();

      // Verify search was not called
      expect(searchCalled, isFalse);
    });

    testWidgets('disposes TextEditingController', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CitySearchPickerModal(
              onSelected: (city) {},
            ),
          ),
        ),
      );

      final state = tester.state<_CitySearchPickerModalState>(
        find.byType(CitySearchPickerModal)
      );

      // Store controller reference
      final controller = state._searchController;

      // Remove widget from tree
      await tester.pumpWidget(Container());

      // Verify controller was disposed
      // Note: There's no direct way to check if disposed in Flutter
      // This would need to be verified through absence of memory leaks
    });
  });

  group('CitySearchPickerModal Filtering Logic', () {

    test('filters results by initialCountryCode when provided', () {
      final allCities = [
        City(name: 'Madrid', countryCode: 'ES', timezone: 'Europe/Madrid'),
        City(name: 'Barcelona', countryCode: 'ES', timezone: 'Europe/Madrid'),
        City(name: 'Paris', countryCode: 'FR', timezone: 'Europe/Paris'),
      ];

      final countryCode = 'ES';
      final filtered = allCities.where((c) => c.countryCode == countryCode).toList();

      expect(filtered.length, equals(2));
      expect(filtered.every((c) => c.countryCode == 'ES'), isTrue);
    });

    test('returns all results when initialCountryCode is null', () {
      final allCities = [
        City(name: 'Madrid', countryCode: 'ES', timezone: 'Europe/Madrid'),
        City(name: 'Paris', countryCode: 'FR', timezone: 'Europe/Paris'),
      ];

      final String? countryCode = null;
      final filtered = countryCode != null
        ? allCities.where((c) => c.countryCode == countryCode).toList()
        : allCities;

      expect(filtered.length, equals(2));
    });
  });
}
```

### 12.2. Widget Tests

```dart
void main() {
  group('CitySearchPickerModal Widget Tests', () {

    testWidgets('renders iOS UI when platform is iOS', (tester) async {
      // This requires mocking PlatformDetection.isIOS
      await tester.pumpWidget(
        MaterialApp(
          home: CitySearchPickerModal(
            onSelected: (city) {},
          ),
        ),
      );

      if (PlatformDetection.isIOS) {
        expect(find.byType(CupertinoPageScaffold), findsOneWidget);
        expect(find.byType(CupertinoNavigationBar), findsOneWidget);
        expect(find.byType(CupertinoTextField), findsOneWidget);
      } else {
        expect(find.byType(CupertinoPageScaffold), findsNothing);
      }
    });

    testWidgets('shows loading indicator when searching', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CitySearchPickerModal(
            onSelected: (city) {},
          ),
        ),
      );

      // Enter search query
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Madrid');
      await tester.pump(); // Start search

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onSelected and pops when city is tapped', (tester) async {
      City? selectedCity;
      bool popped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onPopPage: (route, result) {
              popped = true;
              return route.didPop(result);
            },
            pages: [
              MaterialPage(
                child: CitySearchPickerModal(
                  onSelected: (city) {
                    selectedCity = city;
                  },
                ),
              ),
            ],
          ),
        ),
      );

      // Mock search results (would require dependency injection)
      // Simulate tapping a city result
      // ...

      // Verify callback was called and navigator popped
      // expect(selectedCity, isNotNull);
      // expect(popped, isTrue);
    });

    testWidgets('shows flag emoji for each city result', (tester) async {
      // This test requires mocking CityService to return predictable results
      await tester.pumpWidget(
        MaterialApp(
          home: CitySearchPickerModal(
            onSelected: (city) {},
          ),
        ),
      );

      // Trigger search
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Madrid');
      await tester.pumpAndSettle();

      // Verify flag emojis are displayed (fontSize 24)
      // This depends on search results
    });

    testWidgets('filters to only show cities from initialCountryCode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CitySearchPickerModal(
            initialCountryCode: 'ES',
            onSelected: (city) {},
          ),
        ),
      );

      // Enter search query that would return cities from multiple countries
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Barcelona');
      await tester.pumpAndSettle();

      // Verify only Spanish cities are shown
      // This requires mocking the service
    });
  });
}
```

### 12.3. Integration Tests

```dart
void main() {
  group('CitySearchPickerModal Integration Tests', () {

    testWidgets('complete search and selection workflow', (tester) async {
      City? selectedCity;

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
                      builder: (context) => CitySearchPickerModal(
                        onSelected: (city) {
                          selectedCity = city;
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

      // Enter search query (>= 3 characters)
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Madrid');
      await tester.pumpAndSettle();

      // Wait for search results (requires real or mocked service)
      await tester.pump(Duration(seconds: 1));

      // Tap first result
      // await tester.tap(find.byType(ListTile).first);
      // await tester.pumpAndSettle();

      // Verify callback was called
      // expect(selectedCity, isNotNull);
      // expect(selectedCity!.name, contains('Madrid'));
    });

    testWidgets('search with less than 3 characters shows no results', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CitySearchPickerModal(
            onSelected: (city) {},
          ),
        ),
      );

      // Enter 2 characters
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'MA');
      await tester.pumpAndSettle();

      // Should not show loading indicator
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Should show empty state (SizedBox.shrink)
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('error during search shows no results', (tester) async {
      // Mock CityService to throw error
      await tester.pumpWidget(
        MaterialApp(
          home: CitySearchPickerModal(
            onSelected: (city) {},
          ),
        ),
      );

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'ErrorQuery');
      await tester.pumpAndSettle();

      // Should not show results or loading
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ListView), findsNothing);
    });
  });
}
```

## 13. Comparison with Similar Widgets

### vs. CountryPickerModal

| Característica | CitySearchPickerModal | CountryPickerModal (hipotético) |
|----------------|----------------------|--------------------------------|
| **Búsqueda** | Asíncrona vía servicio | Probablemente filtrado local |
| **Datos** | Cities con timezone | Countries con código y nombre |
| **Filtrado** | Opcional por país | No aplica |
| **Validación mínima** | 3 caracteres | Probablemente sin mínimo |
| **Complejidad** | Mayor (API calls) | Menor (datos locales) |
| **Mejor para** | Seleccionar ubicación específica | Seleccionar país/región |

### vs. Standard CupertinoPicker/Material DropdownButton

| Característica | CitySearchPickerModal | CupertinoPicker | DropdownButton |
|----------------|----------------------|-----------------|----------------|
| **Búsqueda** | Sí, con mínimo 3 chars | No | No |
| **Datos** | Dinámicos vía API | Estáticos predefinidos | Estáticos predefinidos |
| **UI** | Modal adaptativo | Rueda iOS | Dropdown Material |
| **Filtrado** | Sí (por país) | No | No |
| **Escalabilidad** | Miles de ciudades | Limitado (scroll tedioso) | Limitado (lista muy larga) |

### vs. Google Places Autocomplete

| Característica | CitySearchPickerModal | Google Places Autocomplete |
|----------------|----------------------|---------------------------|
| **Servicio** | Custom backend (CityService) | Google Maps API |
| **Costo** | Depende del backend | Requiere API key, puede tener costo |
| **Datos** | Cities con timezone | Lugares completos con detalles |
| **Precisión** | Depende del servicio | Muy preciso |
| **Offline** | Depende del servicio | Requiere conexión |
| **Privacidad** | Controlado internamente | Datos enviados a Google |

## 14. Possible Improvements

1. **Debouncing de búsqueda**
   - **Problema actual:** Cada keystroke dispara una búsqueda, potencialmente causando muchas llamadas API
   - **Mejora:** Implementar debouncing con `Timer` o paquete como `easy_debounce`
   ```dart
   void _search(String q) {
     _debouncer?.cancel();
     _debouncer = Timer(Duration(milliseconds: 300), () async {
       // Ejecutar búsqueda
     });
   }
   ```
   - **Beneficio:** Reduce carga del servidor y mejora performance

2. **Cancelación de búsquedas anteriores**
   - **Problema actual:** Múltiples búsquedas pueden completar fuera de orden
   - **Mejora:** Implementar cancelación de búsquedas obsoletas
   ```dart
   CancelToken? _cancelToken;

   void _search(String q) async {
     _cancelToken?.cancel();
     _cancelToken = CancelToken();
     await CityService.searchCities(q, cancelToken: _cancelToken);
   }
   ```
   - **Beneficio:** Previene race conditions y resultados incorrectos

3. **Mounted check después de await**
   - **Problema actual:** No hay verificación de `mounted` después de llamadas async
   - **Mejora:** Añadir checks
   ```dart
   final res = await CityService.searchCities(q);
   if (!mounted) return;
   setState(() { ... });
   ```
   - **Beneficio:** Previene crashes por llamadas a `setState` en widgets desmontados

4. **Mensaje de error visible al usuario**
   - **Problema actual:** Errores solo resultan en lista vacía sin feedback
   - **Mejora:** Mostrar mensaje de error
   ```dart
   String? _errorMessage;

   catch (e) {
     if (mounted) {
       setState(() {
         _errorMessage = 'Error al buscar ciudades: ${e.toString()}';
         _results = [];
       });
     }
   }
   ```
   - **Beneficio:** Usuario entiende por qué no hay resultados

5. **Estado vacío más informativo**
   - **Problema actual:** `SizedBox.shrink()` no proporciona guidance
   - **Mejora:** Mostrar mensaje contextual
   ```dart
   if (_results.isEmpty && !_isLoading) {
     if (_searchController.text.length < 3) {
       return Center(child: Text('Escribe al menos 3 caracteres'));
     } else {
       return Center(child: Text('No se encontraron ciudades'));
     }
   }
   ```
   - **Beneficio:** Mejor UX con feedback claro

6. **Filtrado server-side por país**
   - **Problema actual:** Filtrado ocurre en cliente después de recibir todos los resultados
   - **Mejora:** Pasar `initialCountryCode` al servicio
   ```dart
   final res = await CityService.searchCities(
     q,
     countryCode: widget.initialCountryCode,
   );
   ```
   - **Beneficio:** Menos datos transferidos, búsquedas más rápidas

7. **Cache de resultados de búsqueda**
   - **Problema actual:** Búsquedas idénticas se ejecutan múltiples veces
   - **Mejora:** Cache con TTL
   ```dart
   Map<String, CachedResult> _searchCache = {};

   if (_searchCache.containsKey(q) && !_searchCache[q]!.isExpired) {
     setState(() => _results = _searchCache[q]!.results);
     return;
   }
   ```
   - **Beneficio:** Respuestas instantáneas para búsquedas repetidas

8. **Resaltado de texto de búsqueda en resultados**
   - **Problema actual:** No hay indicación visual de qué parte del nombre coincide
   - **Mejora:** Highlight del texto buscado
   ```dart
   title: RichText(
     text: TextSpan(
       children: _highlightMatches(city.name, _searchController.text),
     ),
   ),
   ```
   - **Beneficio:** Usuario entiende mejor por qué un resultado aparece

9. **Paginación o lazy loading**
   - **Problema actual:** Todos los resultados se cargan de una vez
   - **Mejora:** Paginación con scroll infinito
   ```dart
   ListView.builder(
     controller: _scrollController,
     itemBuilder: (context, index) {
       if (index >= _results.length - 5) {
         _loadMoreResults();
       }
       return ...;
     },
   )
   ```
   - **Beneficio:** Performance mejorada para búsquedas con muchos resultados

10. **Sugerencias o trending cities**
    - **Problema actual:** UI vacía hasta que el usuario escribe
    - **Mejora:** Mostrar ciudades sugeridas o populares antes de búsqueda
    ```dart
    if (_searchController.text.isEmpty && _results.isEmpty) {
      return _buildTrendingCities();
    }
    ```
    - **Beneficio:** UX más rica, ayuda a usuarios indecisos

11. **Accesibilidad mejorada**
    - **Problema actual:** No hay semántica específica para lectores de pantalla
    - **Mejora:** Añadir `Semantics` widgets
    ```dart
    Semantics(
      label: 'Buscar ciudad. Ingresa al menos 3 caracteres',
      child: TextField(...),
    )
    ```
    - **Beneficio:** Mejor experiencia para usuarios con discapacidades visuales

12. **Animaciones de transición**
    - **Problema actual:** Resultados aparecen abruptamente
    - **Mejora:** Animaciones suaves
    ```dart
    AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: _isLoading ? LoadingIndicator() : ResultsList(),
    )
    ```
    - **Beneficio:** Transiciones más suaves y profesionales

## 15. Real-World Usage Context

### En el contexto de la aplicación EventyPop

`CitySearchPickerModal` se utiliza principalmente en flujos de creación/edición de eventos donde se necesita especificar una ubicación geográfica precisa con zona horaria correcta.

**Flujos típicos de uso:**

1. **Selección de ubicación de evento:**
   - Usuario crea un evento
   - Toca campo "Ubicación"
   - Se abre `CitySearchPickerModal`
   - Usuario busca su ciudad
   - Sistema obtiene timezone automáticamente de la ciudad seleccionada

2. **Configuración de perfil de usuario:**
   - Usuario configura su ciudad de residencia
   - Búsqueda global sin filtro de país
   - Se usa para mostrar eventos cercanos o calcular zonas horarias

3. **Eventos multi-ciudad:**
   - Organizador crea tour o evento en múltiples ciudades
   - Abre el picker varias veces
   - Cada ciudad seleccionada se añade a la lista de ubicaciones del evento

### Integración típica con CountryTimezoneSelector

Es probable que este widget se use en conjunto con `CountryTimezoneSelector` (widget 17 documentado previamente):

```dart
// Opción 1: Primero país, luego ciudad filtrada
CountryTimezoneSelector(...) → CitySearchPickerModal(initialCountryCode: selectedCountry)

// Opción 2: Ciudad directamente, luego auto-seleccionar país
CitySearchPickerModal() → Extrae countryCode de City → Actualiza país
```

## 16. Performance Considerations

### Network Performance
- **Búsquedas frecuentes:** Sin debouncing, puede generar muchas requests
- **Tamaño de respuesta:** Depende del backend, pero potencialmente grande
- **Latencia:** Usuario ve loading indicator durante búsqueda
- **Optimización recomendada:** Debouncing + cancelación de requests obsoletas

### UI Performance
- **ListView.builder:** Eficiente incluso con muchos resultados (lazy rendering)
- **ClampingScrollPhysics:** Performance similar a default scroll physics
- **Rebuilds:** Solo se reconstruye cuando cambia estado (`_results`, `_isLoading`)
- **Potencial mejora:** Si hay miles de resultados, considerar paginación

### Memory Management
- **TextEditingController:** Correctamente disposed
- **State variables:** Limpiadas automáticamente al desmontar widget
- **Cache:** Sin cache implementado actualmente, pero si se añade debe tener TTL o límite de tamaño
- **Memory leaks:** Riesgo bajo debido a correcto manejo de lifecycle

### Platform Differences
- **iOS (full-screen):** Potencialmente usa más memoria que bottom sheet
- **Android (80% height):** Más eficiente en memoria
- **Rendering:** Ambas plataformas usan componentes nativos optimizados

## 17. Security and Privacy Considerations

### Data Privacy
- **Datos buscados:** Las queries de búsqueda se envían al backend
- **Implicaciones:** Queries pueden revelar intenciones del usuario (ej: búsquedas de ciudades específicas)
- **Recomendación:** Si la app maneja datos sensibles, considerar cifrado de queries o logging mínimo en servidor

### Network Security
- **API calls:** `CityService.searchCities()` debe usar HTTPS
- **Input sanitization:** El query es un string de búsqueda, debería ser sanitizado en backend
- **Inyección:** Bajo riesgo ya que es búsqueda de texto, no SQL directo

### User Input Validation
- **Client-side:** Solo validación de longitud mínima (3 caracteres)
- **Server-side:** Backend debe validar y sanitizar queries
- **Rate limiting:** Backend debería implementar rate limiting para prevenir abuso

### Error Information Disclosure
- **Problema actual:** Errores se capturan genéricamente sin mostrar detalles
- **Beneficio de seguridad:** No expone información de errores internos al usuario
- **Logging:** Errores deberían loggearse para debugging pero no mostrarse al usuario

### Data Exposure
- **Resultados mostrados:** Nombres de ciudades, códigos de país, timezones
- **Sensibilidad:** Datos geográficos generalmente públicos, bajo riesgo
- **Banderas:** Emojis de países, sin riesgo de seguridad

---

**Última actualización:** 2025-11-03
**Widget documentado:** 24 de 26
