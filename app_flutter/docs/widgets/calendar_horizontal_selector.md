# CalendarHorizontalSelector - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/calendar_horizontal_selector.dart`
**Líneas**: 46
**Tipo**: StatelessWidget
**Propósito**: Selector horizontal especializado para calendarios que transforma una lista de calendarios en opciones seleccionables y delega la presentación al HorizontalSelectorWidget genérico

## 2. CLASE Y PROPIEDADES

### CalendarHorizontalSelector (líneas 7-45)
Widget que extiende `StatelessWidget` para crear un selector horizontal de calendarios

**Propiedades**:
- `calendars` (List<Calendar>, required, línea 8): Lista de calendarios disponibles para seleccionar
- `selectedCalendarId` (String?, línea 10): ID del calendario actualmente seleccionado (puede ser null si no hay selección)
- `onSelected` (Function(String calendarId), required, línea 12): Callback ejecutado cuando se selecciona un calendario, recibe el ID del calendario
- `isDisabled` (bool, default: false, línea 14): Indica si el selector está deshabilitado (no permite interacción)
- `label` (String?, línea 16): Etiqueta opcional que se muestra arriba del selector

## 3. CONSTRUCTOR

### CalendarHorizontalSelector (línea 18)
```dart
const CalendarHorizontalSelector({
  super.key,
  required this.calendars,
  this.selectedCalendarId,
  required this.onSelected,
  this.isDisabled = false,
  this.label
})
```

**Tipo**: Constructor const

**Parámetros**:
- `super.key`: Key? (opcional, para identificación de widget)
- `calendars`: List<Calendar> (required)
- `selectedCalendarId`: String? (opcional)
- `onSelected`: Function(String) (required)
- `isDisabled`: bool (opcional, default: false)
- `label`: String? (opcional)

**Uso típico**:
```dart
CalendarHorizontalSelector(
  calendars: userCalendars,
  selectedCalendarId: currentCalendarId,
  onSelected: (id) => setState(() => currentCalendarId = id),
  label: 'Selecciona un calendario',
)
```

## 4. MÉTODO _transformCalendars

### _transformCalendars() (líneas 20-24)
**Tipo de retorno**: `List<SelectorOption<Calendar>>`
**Visibilidad**: Privado

**Propósito**: Transforma la lista de calendarios en una lista de SelectorOption que puede usar el HorizontalSelectorWidget

**Lógica**:
1. Itera sobre cada calendario usando `.map()`
2. Para cada calendario, crea un `SelectorOption<Calendar>` con:
   - `value`: El objeto Calendar completo
   - `displayText`: El nombre del calendario (`calendar.name`)
   - `highlightColor`: Colors.blue (color de resaltado constante para todos)
   - `isSelected`: true si `calendar.id == selectedCalendarId` (comparación de IDs)
   - `isEnabled`: `!isDisabled` (invertido: si el selector está disabled, todas las opciones están disabled)
3. Convierte el resultado a lista con `.toList()`

**Características**:
- Todas las opciones usan el mismo highlightColor (azul)
- El estado isEnabled es global para todas las opciones (no hay opciones individuales deshabilitadas)
- La selección se determina comparando IDs (String comparison)
- Tipo genérico: SelectorOption\<Calendar\>

## 5. MÉTODO BUILD

### build(BuildContext context) (líneas 26-44)
**Tipo de retorno**: `Widget`
**Anotación**: `@override`

**Propósito**: Construye el widget del selector horizontal con estado visual de disabled

**Estructura del widget tree**:
```
Opacity (alpha basado en isDisabled)
└── HorizontalSelectorWidget<Calendar>
    └── (implementación interna del HorizontalSelectorWidget)
```

**Lógica detallada**:

1. **Transforma calendarios** (línea 28):
   ```dart
   final options = _transformCalendars();
   ```
   - Obtiene la lista de SelectorOption
   - Variable local inmutable

2. **Opacity wrapper** (líneas 30-31):
   ```dart
   return Opacity(
     opacity: isDisabled ? 0.5 : 1.0,
     ...
   )
   ```
   - **Propósito**: Feedback visual del estado disabled
   - **Si isDisabled = true**: opacity 0.5 (50% transparente, apariencia grisácea)
   - **Si isDisabled = false**: opacity 1.0 (completamente opaco, apariencia normal)
   - **Nota**: El Opacity afecta a todo el HorizontalSelectorWidget

3. **HorizontalSelectorWidget\<Calendar\>** (líneas 32-42):
   ```dart
   child: HorizontalSelectorWidget<Calendar>(
     options: options,
     onSelected: (calendar) {
       if (!isDisabled) {
         onSelected(calendar.id);
       }
     },
     label: label,
     icon: Icons.calendar_today,
     emptyMessage: context.l10n.noCalendarsAvailable,
   )
   ```

   **Propiedades**:

   a) **options** (línea 33):
      - Pasa la lista transformada de SelectorOption<Calendar>
      - Ya incluye información de selección y habilitación

   b) **onSelected** (líneas 34-38):
      - **Tipo**: Function(Calendar)
      - **Lógica**:
        - Verifica `if (!isDisabled)` antes de ejecutar
        - Si no está disabled: ejecuta `onSelected(calendar.id)`
        - Si está disabled: no hace nada (callback vacío)
      - **Nota**: Double-check del estado disabled (también se aplica en isEnabled de las opciones)
      - **Extracción de ID**: Recibe Calendar completo, extrae solo el ID para el callback externo

   c) **label** (línea 39):
      - Pasa directamente la propiedad label (puede ser null)
      - HorizontalSelectorWidget maneja la visualización condicional

   d) **icon** (línea 40):
      - **Valor fijo**: Icons.calendar_today
      - Icono de calendario para identificación visual
      - Siempre presente (no condicional)

   e) **emptyMessage** (línea 41):
      - **Localizado**: `context.l10n.noCalendarsAvailable`
      - Mensaje mostrado cuando `calendars.isEmpty`
      - Depende del idioma del usuario

## 6. COMPONENTES EXTERNOS UTILIZADOS

### HorizontalSelectorWidget\<Calendar\> (líneas 32-42)
**Archivo**: `horizontal_selector_widget.dart`
**Tipo genérico**: Calendar
**Props utilizadas**:
- `options`: List<SelectorOption<Calendar>>
- `onSelected`: Function(Calendar)
- `label`: String?
- `icon`: IconData
- `emptyMessage`: String

**Propósito**: Widget genérico reutilizable que maneja la presentación visual y la interacción del selector horizontal

**Relación**: CalendarHorizontalSelector es un wrapper especializado que adapta datos de Calendar al formato esperado por HorizontalSelectorWidget

### SelectorOption\<Calendar\> (línea 22)
**Archivo**: `../models/selector_option.dart`
**Tipo genérico**: Calendar
**Propiedades usadas**:
- `value`: Calendar
- `displayText`: String
- `highlightColor`: Color
- `isSelected`: bool
- `isEnabled`: bool

**Propósito**: Modelo de datos para opciones del selector

## 7. MODELOS UTILIZADOS

### Calendar (línea 3)
**Archivo**: `../models/calendar.dart`
**Propiedades usadas en este widget**:
- `id`: String (para comparación y callback)
- `name`: String (para displayText)

**Propósito**: Modelo de datos de calendario

## 8. LOCALIZACIÓN

### Strings localizados usados:
- `context.l10n.noCalendarsAvailable` (línea 41): Mensaje cuando no hay calendarios disponibles

**Acceso**: Mediante extension `context.l10n` de `l10n_helpers.dart`

## 9. COMPORTAMIENTO ESPECIAL

### Estado Disabled (isDisabled = true):
1. **Feedback visual**: Opacity 0.5 (50% transparente)
2. **Bloqueo de interacción**:
   - onSelected verifica `!isDisabled` antes de ejecutar
   - Todas las opciones tienen `isEnabled: false`
3. **Double protection**: Dos niveles de protección contra interacción accidental

### Selección:
- **Comparación**: Por ID de calendario (`calendar.id == selectedCalendarId`)
- **Single selection**: Solo un calendario puede estar seleccionado a la vez
- **Feedback**: Visual provisto por HorizontalSelectorWidget

### Lista vacía:
- **Detección**: HorizontalSelectorWidget detecta `options.isEmpty`
- **Mensaje**: Muestra `emptyMessage` localizado
- **No error**: Comportamiento graceful sin crashes

## 10. FLUJO DE DATOS

### Input:
1. `calendars`: Lista de calendarios (externa)
2. `selectedCalendarId`: ID del calendario seleccionado (externa, puede venir de state)
3. `isDisabled`: Estado de habilitación (externa)

### Transformación:
1. `_transformCalendars()`: Convierte Calendar → SelectorOption<Calendar>
2. Añade información de selección (isSelected)
3. Añade información de habilitación (isEnabled)

### Output:
1. `onSelected(String calendarId)`: Callback con ID del calendario seleccionado
   - Recibe Calendar completo de HorizontalSelectorWidget
   - Extrae solo el ID
   - Pasa el ID al callback externo

### Diagrama de flujo:
```
calendars (List<Calendar>)
    ↓ _transformCalendars()
options (List<SelectorOption<Calendar>>)
    ↓ HorizontalSelectorWidget
User interaction
    ↓ onSelected (Calendar)
Extract calendar.id
    ↓ onSelected (String)
External callback
```

## 11. ESTILOS Y CONSTANTES

### Colores:
- **highlightColor**: Colors.blue (constante para todos los calendarios)
- **Opacity disabled**: 0.5 (50% transparente)
- **Opacity enabled**: 1.0 (opaco)

### Iconos:
- **Icons.calendar_today**: Icono de calendario (línea 40)

**Nota**: No hay estilos personalizados en este widget, toda la presentación visual es delegada a HorizontalSelectorWidget

## 12. DEPENDENCIAS

**Imports**:
```dart
import 'package:flutter/material.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../models/calendar.dart';
import '../models/selector_option.dart';
import 'horizontal_selector_widget.dart';
```

### Dependencias externas:
1. **flutter/material.dart** (línea 1):
   - StatelessWidget, Widget, BuildContext
   - Opacity
   - Colors, Icons

2. **l10n_helpers.dart** (línea 2):
   - Extension `context.l10n`
   - Acceso a strings localizados

### Dependencias internas:
3. **calendar.dart** (línea 3):
   - Modelo Calendar

4. **selector_option.dart** (línea 4):
   - Modelo SelectorOption<T>

5. **horizontal_selector_widget.dart** (línea 5):
   - Widget genérico HorizontalSelectorWidget<T>

## 13. CARACTERÍSTICAS TÉCNICAS

### Inmutabilidad:
- **Todas las propiedades son final**
- **Constructor const**: Permite optimizaciones de compilación
- Widget completamente inmutable (StatelessWidget)

### Tipo genérico:
- SelectorOption<Calendar>
- HorizontalSelectorWidget<Calendar>
- Preserva el tipo Calendar a través de la cadena

### Programación funcional:
- Uso de `.map()` para transformación de listas
- Funciones de orden superior (callbacks)
- Expresiones lambda en onSelected

### Separation of concerns:
- **CalendarHorizontalSelector**: Lógica de negocio específica de calendarios
- **HorizontalSelectorWidget**: Presentación y UI genérica
- Bajo acoplamiento, alta cohesión

### Null safety:
- `selectedCalendarId`: String? (puede ser null si no hay selección)
- `label`: String? (opcional)
- Uso de operador `==` para comparación segura

### Doble validación de disabled:
1. `isEnabled: !isDisabled` en SelectorOption
2. `if (!isDisabled)` en callback onSelected
- Previene interacción accidental en múltiples niveles

### Extension methods:
- `context.l10n`: Extension para acceso a localizaciones
- Sintaxis limpia y concisa

## 14. PATRONES DE DISEÑO

### Adapter Pattern:
- CalendarHorizontalSelector adapta Calendar a SelectorOption<Calendar>
- Permite reutilizar HorizontalSelectorWidget genérico para casos específicos

### Delegation Pattern:
- Delega toda la presentación visual a HorizontalSelectorWidget
- Solo se encarga de la transformación de datos y lógica específica

### Wrapper Pattern:
- Envuelve HorizontalSelectorWidget con Opacity para feedback visual
- Añade comportamiento adicional sin modificar el componente base

## 15. CASOS DE USO

### Uso básico:
```dart
CalendarHorizontalSelector(
  calendars: availableCalendars,
  selectedCalendarId: selectedId,
  onSelected: (id) {
    setState(() {
      selectedId = id;
    });
  },
)
```

### Con label:
```dart
CalendarHorizontalSelector(
  calendars: calendars,
  selectedCalendarId: currentId,
  onSelected: handleCalendarChange,
  label: 'Calendario de destino',
)
```

### Disabled:
```dart
CalendarHorizontalSelector(
  calendars: calendars,
  selectedCalendarId: lockedId,
  onSelected: (_) {}, // No se ejecutará
  isDisabled: true, // Visual feedback + bloqueo de interacción
  label: 'Calendario (bloqueado)',
)
```

### Lista vacía:
```dart
CalendarHorizontalSelector(
  calendars: [], // Lista vacía
  selectedCalendarId: null,
  onSelected: (_) {},
  // Mostrará mensaje: "No hay calendarios disponibles"
)
```

## 16. TESTING

### Test cases recomendados:

1. **Transformación de datos**:
   ```dart
   test('transforms calendars to selector options', () {
     final calendars = [
       Calendar(id: '1', name: 'Personal'),
       Calendar(id: '2', name: 'Work'),
     ];
     // Verificar que _transformCalendars() produce opciones correctas
   });
   ```

2. **Selección correcta**:
   ```dart
   testWidgets('marks correct calendar as selected', (tester) async {
     await tester.pumpWidget(
       CalendarHorizontalSelector(
         calendars: testCalendars,
         selectedCalendarId: '2',
         onSelected: (_) {},
       ),
     );
     // Verificar que la opción con id '2' está marcada como selected
   });
   ```

3. **Callback con ID correcto**:
   ```dart
   testWidgets('calls onSelected with calendar ID', (tester) async {
     String? selectedId;
     await tester.pumpWidget(
       CalendarHorizontalSelector(
         calendars: testCalendars,
         selectedCalendarId: null,
         onSelected: (id) => selectedId = id,
       ),
     );
     // Simular tap en calendario
     // Verificar que selectedId recibe el ID correcto
   });
   ```

4. **Comportamiento disabled**:
   ```dart
   testWidgets('does not call onSelected when disabled', (tester) async {
     bool wasCalled = false;
     await tester.pumpWidget(
       CalendarHorizontalSelector(
         calendars: testCalendars,
         selectedCalendarId: null,
         onSelected: (_) => wasCalled = true,
         isDisabled: true,
       ),
     );
     // Simular tap
     expect(wasCalled, false);
   });
   ```

5. **Opacity visual**:
   ```dart
   testWidgets('shows reduced opacity when disabled', (tester) async {
     await tester.pumpWidget(
       CalendarHorizontalSelector(
         calendars: testCalendars,
         selectedCalendarId: null,
         onSelected: (_) {},
         isDisabled: true,
       ),
     );
     final opacity = tester.widget<Opacity>(find.byType(Opacity));
     expect(opacity.opacity, 0.5);
   });
   ```

## 17. POSIBLES MEJORAS (NO implementadas)

### 1. HighlightColor personalizable:
```dart
// Permitir colores diferentes por calendario
final Color? highlightColor;

SelectorOption<Calendar>(
  highlightColor: highlightColor ?? Colors.blue,
  ...
)
```

### 2. Opciones individuales deshabilitadas:
```dart
// Permitir deshabilitar calendarios específicos
final Set<String> disabledCalendarIds;

SelectorOption<Calendar>(
  isEnabled: !isDisabled && !disabledCalendarIds.contains(calendar.id),
  ...
)
```

### 3. Filtrado de calendarios:
```dart
// Filtrar calendarios según criterio
final bool Function(Calendar)? filter;

List<SelectorOption<Calendar>> _transformCalendars() {
  final filtered = filter != null
      ? calendars.where(filter!)
      : calendars;
  return filtered.map(...).toList();
}
```

### 4. Callback con Calendar completo:
```dart
// Opción de callback con objeto completo
final Function(Calendar)? onCalendarSelected;

onSelected: (calendar) {
  if (!isDisabled) {
    onSelected(calendar.id);
    onCalendarSelected?.call(calendar);
  }
}
```

### 5. CustomPaint para badges:
```dart
// Badges visuales (compartido, solo lectura, etc.)
SelectorOption<Calendar>(
  badge: calendar.isShared ? 'Compartido' : null,
  ...
)
```

## 18. RELACIÓN CON OTROS SELECTORES

### Familia de selectores en la app:
- **CalendarHorizontalSelector**: Para calendarios
- **TimezoneHorizontalSelector**: Para zonas horarias (probable)
- Todos usan el patrón de wrapper sobre HorizontalSelectorWidget

### Consistencia:
- Misma estructura (transformación → delegación)
- Mismo patrón de disabled con Opacity
- Mismo tipo de callback especializado

## 19. PERFORMANCE

### Optimizaciones:
- **Constructor const**: Permite instancias constantes cuando sea posible
- **StatelessWidget**: No tiene estado interno, más eficiente que StatefulWidget
- **Transformación bajo demanda**: `_transformCalendars()` solo se ejecuta en build

### Posibles problemas:
- **Transformación en cada build**: Si el padre hace rebuild frecuente, `_transformCalendars()` se ejecuta cada vez
- **Solución potencial**: Usar `useMemoized` (si se convierte a HookWidget) o calcular en el padre

### Tamaño del widget tree:
- 2 niveles: Opacity → HorizontalSelectorWidget
- Delegación eficiente sin nesting excesivo

## 20. RESUMEN

### Propósito:
Selector horizontal especializado para calendarios que transforma datos de Calendar en formato SelectorOption y delega la presentación a un componente genérico reutilizable

### Características clave:
- **Adapter pattern**: Adapta Calendar a SelectorOption<Calendar>
- **Delegation**: Delega presentación a HorizontalSelectorWidget
- **Estado disabled**: Visual (opacity) + funcional (callback bloqueado)
- **Localización**: Mensaje de lista vacía localizado
- **Type-safe**: Usa genéricos para preservar tipos
- **Inmutable**: StatelessWidget con propiedades final

### Estructura:
Opacity → HorizontalSelectorWidget<Calendar>

### Flujo:
Input (calendars) → Transformación (_transformCalendars) → Presentación (HorizontalSelectorWidget) → Output (onSelected con ID)

### Uso:
Pantallas de creación/edición de eventos donde se necesita seleccionar el calendario de destino

---

**Fin de la documentación de calendar_horizontal_selector.dart**
