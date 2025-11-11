# RecurrenceTimeSelector

## 1. Overview

`RecurrenceTimeSelector` es un widget especializado que proporciona una interfaz para seleccionar horas específicas dentro de un rango horario configurable, con intervalos de minutos personalizables. Este widget es específicamente diseñado para la selección de horarios en el contexto de eventos recurrentes, ofreciendo una experiencia de usuario optimizada mediante un selector horizontal que genera automáticamente todas las opciones de tiempo válidas según los parámetros configurados.

El widget actúa como una capa de abstracción sobre `HorizontalSelectorWidget`, encapsulando la lógica de generación de opciones temporales y formato de tiempo en formato 24 horas. Su diseño stateless garantiza un rendimiento óptimo al evitar estado innecesario, mientras que su sistema de validación mediante assertions previene configuraciones inválidas.

**Propósito principal:**
- Generar automáticamente opciones de tiempo basadas en rangos y intervalos configurables
- Proporcionar selección de tiempo en formato 24 horas
- Facilitar la configuración de horarios para eventos recurrentes
- Delegar la UI de selección a `HorizontalSelectorWidget` para consistencia visual
- Validar parámetros de configuración mediante assertions

## 2. File Location

**Path:** `/Users/miquelfarre/development/agenda_phoenix/app_flutter/lib/widgets/recurrence_time_selector.dart`

**Ubicación en la arquitectura:**
- **Capa:** Presentation Layer - Widgets
- **Categoría:** Time Selection Widget
- **Relación con otros widgets:** Utiliza `HorizontalSelectorWidget` como componente base para la UI de selección

## 3. Dependencies

### External Dependencies

```dart
import 'package:flutter/material.dart';
```
**Propósito:** Framework principal de Flutter. Proporciona `StatelessWidget`, `TimeOfDay`, `IconData`, `Icons`, y otros componentes fundamentales de la UI.

```dart
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
```
**Propósito:** Sistema de localización. Proporciona extensiones de contexto (`context.l10n`) para acceder a traducciones, específicamente `noTimeOptionsAvailable` para el mensaje cuando no hay opciones disponibles.

### Internal Dependencies

```dart
import '../models/selector_option.dart';
```
**Propósito:** Modelo genérico `SelectorOption<T>` que encapsula las opciones que se pasan a `HorizontalSelectorWidget`. Contiene:
- `value`: El valor real (`TimeOfDay`)
- `displayText`: El texto a mostrar (formato "HH:mm")
- `isSelected`: Si la opción está seleccionada inicialmente
- `isEnabled`: Si la opción es seleccionable

```dart
import 'horizontal_selector_widget.dart';
```
**Propósito:** Widget base reutilizable que proporciona la UI de selector horizontal con scroll. `RecurrenceTimeSelector` genera las opciones y delega toda la lógica de visualización y selección a este widget.

**Dependencias transitivas importantes:**
- `HorizontalSelectorWidget` maneja el scroll automático hacia el elemento seleccionado
- `HorizontalSelectorWidget` gestiona la interacción táctil y callbacks
- `HorizontalSelectorWidget` aplica estilos consistentes a todas las opciones

## 4. Class Declaration

```dart
class RecurrenceTimeSelector extends StatelessWidget {
```
**Línea:** 6

**Decisión de diseño:** `StatelessWidget`

**Justificación:**
1. **Sin estado mutable:** El widget no necesita mantener estado interno. Toda la configuración se pasa como parámetros inmutables
2. **Delegación de estado:** La selección activa se maneja en `HorizontalSelectorWidget`, que es stateless pero usa sus propios parámetros para determinar qué mostrar
3. **Generación determinística:** Las opciones de tiempo se generan de manera determinística basándose únicamente en los parámetros de entrada (`startHour`, `endHour`, `minuteInterval`)
4. **Performance óptima:** Al ser stateless, Flutter puede optimizar el rebuilding del widget más eficientemente
5. **Testabilidad:** Los widgets stateless son más fáciles de testear ya que son funciones puras de sus inputs

## 5. Properties Analysis

### Required Properties

```dart
final Function(TimeOfDay time) onSelected;
```
**Línea:** 9

**Tipo:** Function callback que recibe `TimeOfDay`

**Propósito:** Callback invocado cuando el usuario selecciona un tiempo. Es responsabilidad del widget padre actualizar su estado y potencialmente reconstruir este widget con un nuevo `initialTime`.

**Flujo de datos:**
1. Usuario toca una opción en `HorizontalSelectorWidget`
2. `HorizontalSelectorWidget` invoca su callback `onSelected` con `SelectorOption<TimeOfDay>`
3. `RecurrenceTimeSelector` pasa el `onSelected` directamente, por lo que se invoca con el `TimeOfDay`
4. El widget padre actualiza su estado
5. Opcionalmente, el padre reconstruye `RecurrenceTimeSelector` con nuevo `initialTime`

### Optional Properties

```dart
final TimeOfDay? initialTime;
```
**Línea:** 7

**Tipo:** `TimeOfDay?` (nullable)

**Default:** `null`

**Propósito:** Tiempo inicialmente seleccionado. Se usa para marcar la opción correspondiente como `isSelected: true` en la lista de opciones generadas. Si es `null`, ninguna opción está preseleccionada.

**Validación:** No hay validación explícita de que `initialTime` esté dentro del rango `startHour`-`endHour`. Si está fuera del rango, simplemente no habrá ninguna opción marcada como seleccionada.

---

```dart
final int minuteInterval;
```
**Línea:** 11

**Tipo:** `int`

**Default:** `5` (línea 21)

**Propósito:** Intervalo en minutos entre opciones consecutivas. Por ejemplo:
- `minuteInterval: 5` → 00:00, 00:05, 00:10, 00:15, etc.
- `minuteInterval: 15` → 00:00, 00:15, 00:30, 00:45, etc.
- `minuteInterval: 30` → 00:00, 00:30, 01:00, 01:30, etc.

**Validación (línea 22):**
```dart
assert(minuteInterval > 0 && minuteInterval <= 60)
```
- Debe ser mayor que 0 (evita loops infinitos)
- Debe ser menor o igual a 60 (evita configuraciones sin sentido)

---

```dart
final int startHour;
```
**Línea:** 13

**Tipo:** `int`

**Default:** `0` (línea 21)

**Propósito:** Hora de inicio del rango (inclusive). En formato 24 horas (0-23).

**Validación (líneas 23, 25):**
```dart
assert(startHour >= 0 && startHour <= 23)
assert(startHour <= endHour)
```
- Debe estar entre 0 y 23 (rango válido de horas)
- Debe ser menor o igual a `endHour` (rango válido)

---

```dart
final int endHour;
```
**Línea:** 15

**Tipo:** `int`

**Default:** `23` (línea 21)

**Propósito:** Hora de fin del rango (inclusive). En formato 24 horas (0-23).

**Validación (línea 24):**
```dart
assert(endHour >= 0 && endHour <= 23)
```
- Debe estar entre 0 y 23 (rango válido de horas)

**Ejemplo de rango:** `startHour: 9, endHour: 17` genera opciones solo entre 09:00 y 17:59.

---

```dart
final String? label;
```
**Línea:** 17

**Tipo:** `String?` (nullable)

**Default:** `null`, se usa 'Hora' como fallback en build (línea 48)

**Propósito:** Etiqueta descriptiva que se muestra junto al selector. Se pasa directamente a `HorizontalSelectorWidget`.

---

```dart
final IconData? icon;
```
**Línea:** 19

**Tipo:** `IconData?` (nullable)

**Default:** `null`, se usa `Icons.access_time` como fallback en build (línea 48)

**Propósito:** Icono que se muestra junto al selector. Se pasa directamente a `HorizontalSelectorWidget`.

## 6. Constructor

```dart
const RecurrenceTimeSelector({
  super.key,
  this.initialTime,
  required this.onSelected,
  this.minuteInterval = 5,
  this.startHour = 0,
  this.endHour = 23,
  this.label,
  this.icon
})
  : assert(minuteInterval > 0 && minuteInterval <= 60),
    assert(startHour >= 0 && startHour <= 23),
    assert(endHour >= 0 && endHour <= 23),
    assert(startHour <= endHour);
```
**Líneas:** 21-25

**Características:**

1. **Constructor const:** Permite optimizaciones de compilación cuando todos los parámetros son constantes.

2. **Assertions de validación:**
   - **Línea 22:** `minuteInterval` debe estar en rango (1-60)
   - **Línea 23:** `startHour` debe estar en rango (0-23)
   - **Línea 24:** `endHour` debe estar en rango (0-23)
   - **Línea 25:** `startHour` no puede ser mayor que `endHour`

3. **Valores por defecto razonables:**
   - `minuteInterval: 5` → Intervalos de 5 minutos (común en calendarios)
   - `startHour: 0, endHour: 23` → Día completo (00:00 - 23:59)

**Ejemplos de configuración válidos:**
```dart
RecurrenceTimeSelector(onSelected: (time) {}) // Día completo, intervalos de 5 min
RecurrenceTimeSelector(onSelected: (time) {}, minuteInterval: 15) // Intervalos de 15 min
RecurrenceTimeSelector(onSelected: (time) {}, startHour: 8, endHour: 18) // Horario laboral
```

**Ejemplos que causarían assertion errors:**
```dart
RecurrenceTimeSelector(onSelected: (time) {}, minuteInterval: 0) // Error: debe ser > 0
RecurrenceTimeSelector(onSelected: (time) {}, startHour: 10, endHour: 8) // Error: start > end
RecurrenceTimeSelector(onSelected: (time) {}, startHour: 25) // Error: hora fuera de rango
```

## 7. Methods

### 7.1. _generateTimeOptions

```dart
List<SelectorOption<TimeOfDay>> _generateTimeOptions() {
  final options = <SelectorOption<TimeOfDay>>[];

  for (int hour = startHour; hour <= endHour; hour++) {
    for (int minute = 0; minute < 60; minute += minuteInterval) {
      final time = TimeOfDay(hour: hour, minute: minute);
      final isSelected = initialTime != null &&
                         time.hour == initialTime!.hour &&
                         time.minute == initialTime!.minute;

      options.add(SelectorOption<TimeOfDay>(
        value: time,
        displayText: _formatTime24Hour(time),
        isSelected: isSelected,
        isEnabled: true
      ));
    }
  }

  return options;
}
```
**Líneas:** 27-40

**Propósito:** Generar la lista completa de opciones de tiempo basándose en los parámetros de configuración.

**Análisis línea por línea:**

**Línea 28:** `final options = <SelectorOption<TimeOfDay>>[];`
- Inicializa lista vacía con tipo explícito `SelectorOption<TimeOfDay>`
- Uso de `final` indica que la referencia no cambiará (aunque el contenido sí mediante `add`)

**Línea 30:** `for (int hour = startHour; hour <= endHour; hour++) {`
- Loop externo que itera sobre cada hora en el rango configurado
- Incluye tanto `startHour` como `endHour` (operador `<=`)
- Ejemplo: `startHour: 9, endHour: 17` → itera 9, 10, 11, ..., 17

**Línea 31:** `for (int minute = 0; minute < 60; minute += minuteInterval) {`
- Loop interno que genera minutos dentro de cada hora
- Siempre empieza en 0 (no importa si es la primera hora)
- Incrementa por `minuteInterval` en cada iteración
- Ejemplo con `minuteInterval: 15` → 0, 15, 30, 45
- Ejemplo con `minuteInterval: 5` → 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55

**Nota importante:** Esto significa que si `startHour: 9`, la primera opción será 09:00, no 09:05 ni otro minuto. Similarmente, si `endHour: 17`, las opciones para esa hora serán 17:00, 17:05, ..., hasta el último minuto que sea < 60.

**Línea 32:** `final time = TimeOfDay(hour: hour, minute: minute);`
- Crea instancia de `TimeOfDay` con hora y minuto actuales del loop
- `TimeOfDay` es inmutable, por lo que cada iteración crea un nuevo objeto

**Líneas 33-34:** Lógica de selección inicial
```dart
final isSelected = initialTime != null &&
                   time.hour == initialTime!.hour &&
                   time.minute == initialTime!.minute;
```
- **Condición 1:** `initialTime != null` → Verifica que hay un tiempo inicial
- **Condición 2:** `time.hour == initialTime!.hour` → Compara horas
- **Condición 3:** `time.minute == initialTime!.minute` → Compara minutos
- Operador `!` después de null check es seguro porque ya verificamos `!= null`
- Solo una opción en toda la lista tendrá `isSelected: true` (o ninguna si `initialTime` es null o está fuera de rango)

**Líneas 35:** `options.add(SelectorOption<TimeOfDay>(...));`
- Añade nuevo `SelectorOption` a la lista
- **value:** El objeto `TimeOfDay` (usado cuando se selecciona)
- **displayText:** Texto formateado "HH:mm" (usado para mostrar al usuario)
- **isSelected:** `true` solo si coincide con `initialTime`
- **isEnabled:** Siempre `true` (todas las opciones son seleccionables)

**Línea 39:** `return options;`
- Retorna la lista completa de opciones generadas

**Complejidad computacional:**
- **Tiempo:** O(h × m) donde h = número de horas, m = opciones por hora
- **Espacio:** O(h × m) para almacenar todas las opciones
- Ejemplo práctico: `startHour: 0, endHour: 23, minuteInterval: 5`
  - 24 horas × 12 opciones por hora = 288 opciones totales
  - Esto es manejable y se genera rápidamente

**Posible optimización no implementada:** Lazy loading o paginación para rangos muy grandes, pero no es necesario para casos de uso típicos.

### 7.2. _formatTime24Hour

```dart
String _formatTime24Hour(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
```
**Líneas:** 42-44

**Propósito:** Formatear un `TimeOfDay` en formato de 24 horas con padding de ceros.

**Análisis detallado:**

**Estructura del string:** `HH:mm`
- `HH`: Hora con padding (00-23)
- `:`: Separador fijo (no localizado)
- `mm`: Minutos con padding (00-59)

**Técnica de padding:**
```dart
time.hour.toString().padLeft(2, '0')
```
1. `time.hour` → int (0-23)
2. `.toString()` → String ("0", "1", ..., "23")
3. `.padLeft(2, '0')` → Añade '0' a la izquierda si longitud < 2

**Ejemplos:**
- `TimeOfDay(hour: 9, minute: 5)` → `"09:05"`
- `TimeOfDay(hour: 14, minute: 30)` → `"14:30"`
- `TimeOfDay(hour: 0, minute: 0)` → `"00:00"`
- `TimeOfDay(hour: 23, minute: 59)` → `"23:59"`

**Consideraciones:**

1. **No localizado:** El formato siempre es 24 horas, independientemente de la configuración regional del dispositivo. Esto es apropiado para eventos recurrentes donde se necesita formato consistente.

2. **Separador fijo:** Usa `:` en lugar de obtenerlo de `MaterialLocalizations.of(context).timeSeparator`. Esto podría ser un problema en regiones que usan otros separadores (ej: `h` en algunos idiomas), pero para datos técnicos (como horarios de recurrencia) es aceptable.

3. **Sin AM/PM:** Formato 24 horas puro, no hay ambigüedad entre AM/PM.

4. **Sin segundos:** Solo muestra horas y minutos, asumiendo que los segundos siempre son :00 para eventos recurrentes.

## 8. Build Method

```dart
@override
Widget build(BuildContext context) {
  return HorizontalSelectorWidget<TimeOfDay>(
    options: _generateTimeOptions(),
    onSelected: onSelected,
    label: label ?? 'Hora',
    icon: icon ?? Icons.access_time,
    autoScrollToSelected: true,
    emptyMessage: context.l10n.noTimeOptionsAvailable
  );
}
```
**Líneas:** 46-49

**Análisis línea por línea:**

**Línea 48:** `return HorizontalSelectorWidget<TimeOfDay>(`
- Instancia `HorizontalSelectorWidget` con tipo genérico `TimeOfDay`
- Esto asegura type safety: las opciones son `SelectorOption<TimeOfDay>` y el callback recibe `TimeOfDay`

**Parámetros pasados:**

**`options: _generateTimeOptions()`**
- Genera la lista completa de opciones cada vez que se hace build
- Esto es aceptable porque `_generateTimeOptions()` es rápido y el widget es stateless
- Si `initialTime` cambia, las opciones se regeneran con la nueva selección

**`onSelected: onSelected`**
- Pasa directamente el callback recibido como propiedad
- `HorizontalSelectorWidget` invocará este callback cuando el usuario seleccione una opción

**`label: label ?? 'Hora'`**
- Usa la label proporcionada o 'Hora' como fallback
- Nota: 'Hora' está hardcodeado en español, no localizado. Debería usar `context.l10n.hour` o similar.

**`icon: icon ?? Icons.access_time`**
- Usa el icono proporcionado o el icono de reloj estándar
- `Icons.access_time` es semánticamente apropiado para selección de tiempo

**`autoScrollToSelected: true`**
- Activa el scroll automático hacia la opción seleccionada cuando el widget se monta
- Mejora UX: el usuario ve inmediatamente la opción actualmente seleccionada sin tener que scrollear

**`emptyMessage: context.l10n.noTimeOptionsAvailable`**
- Mensaje localizado que se mostraría si `options` está vacío
- En práctica, esto solo ocurriría si hubiera un error en la lógica de generación (ej: `startHour > endHour`, pero eso está prevenido por assertions)

**Jerarquía de widgets construida:**

```
RecurrenceTimeSelector (StatelessWidget)
└─ HorizontalSelectorWidget<TimeOfDay> (StatelessWidget)
   ├─ Label y Icon (si están provistos)
   ├─ ScrollView horizontal con las opciones
   └─ Cada opción como widget seleccionable
```

**Rebuilding:** El widget se reconstruye cuando:
1. Cambia cualquier parámetro pasado desde el padre
2. El padre se reconstruye y decide reconstruir este widget
3. Las opciones se regeneran en cada build (no hay cacheo)

## 9. Technical Characteristics

### Stateless Design
- Widget completamente stateless, delegando gestión de selección al widget padre
- La generación de opciones es determinística basada en parámetros inmutables
- No hay efectos secundarios ni estado mutable interno

### Time Generation Algorithm
- **Algoritmo:** Nested loops (hora × minuto)
- **Complejidad temporal:** O(n × m) donde n = horas, m = minutos por hora
- **Complejidad espacial:** O(n × m) para almacenar todas las opciones
- **Número típico de opciones:** 288 (día completo con intervalos de 5 min)
- Genera todas las opciones anticipadamente (eager evaluation) en lugar de lazy loading

### Validation Strategy
- **Validación en tiempo de compilación:** Constructor const con assertions
- **Assertions verificadas en modo debug:** Fallan rápido con mensajes claros
- **No hay validación en runtime:** Las assertions se eliminan en modo release
- **Parámetros validados:**
  - `minuteInterval` en rango [1, 60]
  - `startHour` y `endHour` en rango [0, 23]
  - `startHour <= endHour`

### Time Formatting
- **Formato:** 24 horas (HH:mm)
- **Padding:** Ceros a la izquierda para consistencia
- **No localizado:** Separador `:` fijo (no adaptado a región)
- **Sin AM/PM:** Evita ambigüedad en tiempos recurrentes
- **Precision:** Minutos (los segundos se asumen :00)

### Delegation Pattern
- Delega toda la lógica de UI a `HorizontalSelectorWidget`
- Se enfoca únicamente en generación de datos (opciones de tiempo)
- Separación clara de responsabilidades: datos vs presentación

### Type Safety
- Uso de genéricos `<TimeOfDay>` para type safety en tiempo de compilación
- `SelectorOption<TimeOfDay>` asegura que las opciones tengan el tipo correcto
- Callback `Function(TimeOfDay time)` tiene tipado explícito

### Performance Considerations
- Sin cacheo de opciones generadas (se regeneran en cada build)
- Esto es aceptable porque la generación es rápida (< 1ms típicamente)
- Si se usara con rangos muy grandes o intervalos muy pequeños, podría beneficiarse de memoization

## 10. Usage Examples

### Example 1: Basic Time Selector (Default Configuration)

```dart
class EventRecurrenceForm extends StatefulWidget {
  @override
  _EventRecurrenceFormState createState() => _EventRecurrenceFormState();
}

class _EventRecurrenceFormState extends State<EventRecurrenceForm> {
  TimeOfDay? selectedTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Selecciona hora de recurrencia:'),
        RecurrenceTimeSelector(
          initialTime: selectedTime,
          onSelected: (time) {
            setState(() {
              selectedTime = time;
            });
            print('Hora seleccionada: ${time.hour}:${time.minute}');
          },
        ),
        if (selectedTime != null)
          Text('Recurrencia configurada a las ${selectedTime!.hour}:${selectedTime!.minute}'),
      ],
    );
  }
}
```

**Características:**
- Configuración por defecto: día completo (00:00 - 23:59), intervalos de 5 minutos
- Estado manejado en el widget padre
- Feedback visual cuando se selecciona un tiempo

### Example 2: Business Hours with 15-Minute Intervals

```dart
class BusinessHoursSelector extends StatefulWidget {
  @override
  _BusinessHoursSelectorState createState() => _BusinessHoursSelectorState();
}

class _BusinessHoursSelectorState extends State<BusinessHoursSelector> {
  TimeOfDay? meetingTime;

  @override
  Widget build(BuildContext context) {
    return RecurrenceTimeSelector(
      initialTime: meetingTime ?? TimeOfDay(hour: 9, minute: 0), // Default 9 AM
      startHour: 8,  // Abre a las 8 AM
      endHour: 18,   // Cierra a las 6 PM
      minuteInterval: 15, // Intervalos de 15 minutos
      label: 'Hora de reunión',
      icon: Icons.business,
      onSelected: (time) {
        setState(() {
          meetingTime = time;
        });
        _scheduleRecurringMeeting(time);
      },
    );
  }

  void _scheduleRecurringMeeting(TimeOfDay time) {
    // Lógica para programar reunión recurrente
    print('Reunión programada para las ${time.hour}:${time.minute} cada semana');
  }
}
```

**Características:**
- Horario laboral restringido (8 AM - 6 PM)
- Intervalos de 15 minutos (más comunes en calendarios corporativos)
- Hora inicial por defecto (9 AM)
- Callback que ejecuta lógica de negocio

### Example 3: Reminder Times with Custom Icon and Label

```dart
class ReminderTimeSelector extends StatelessWidget {
  final TimeOfDay? currentReminderTime;
  final ValueChanged<TimeOfDay> onReminderTimeChanged;

  const ReminderTimeSelector({
    super.key,
    required this.currentReminderTime,
    required this.onReminderTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configura recordatorio diario',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12),
            RecurrenceTimeSelector(
              initialTime: currentReminderTime,
              startHour: 6,  // Recordatorios desde las 6 AM
              endHour: 22,   // Hasta las 10 PM
              minuteInterval: 30, // Intervalos de 30 minutos
              label: context.l10n.reminderTime,
              icon: Icons.notifications_active,
              onSelected: (time) {
                onReminderTimeChanged(time);
                PlatformDialogHelpers.showSnackBar(
                  context: context,
                  message: 'Recordatorio configurado para las ${time.hour}:${time.minute}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

**Características:**
- Widget stateless que recibe estado como parámetros
- Horario razonable para recordatorios (6 AM - 10 PM)
- Intervalos más amplios (30 minutos) para simplificar opciones
- Feedback mediante SnackBar cuando se selecciona
- Label e icono localizados y temáticos

### Example 4: Multiple Time Selectors (Start and End Times)

```dart
class AvailabilityWindow extends StatefulWidget {
  @override
  _AvailabilityWindowState createState() => _AvailabilityWindowState();
}

class _AvailabilityWindowState extends State<AvailabilityWindow> {
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Ventana de disponibilidad', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 16),

        // Start time selector
        RecurrenceTimeSelector(
          initialTime: startTime,
          startHour: 0,
          endHour: 23,
          minuteInterval: 30,
          label: 'Hora de inicio',
          icon: Icons.play_arrow,
          onSelected: (time) {
            setState(() {
              startTime = time;
              // Validar que end time sea después de start time
              if (endTime != null && _isTimeBefore(endTime!, time)) {
                endTime = null; // Resetear end time si es inválido
              }
            });
          },
        ),

        SizedBox(height: 16),

        // End time selector (condicionado a que exista start time)
        if (startTime != null)
          RecurrenceTimeSelector(
            initialTime: endTime,
            startHour: startTime!.hour,
            endHour: 23,
            minuteInterval: 30,
            label: 'Hora de fin',
            icon: Icons.stop,
            onSelected: (time) {
              setState(() {
                endTime = time;
              });
            },
          ),

        if (startTime != null && endTime != null)
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Disponible de ${_formatTime(startTime!)} a ${_formatTime(endTime!)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  bool _isTimeBefore(TimeOfDay time1, TimeOfDay time2) {
    if (time1.hour < time2.hour) return true;
    if (time1.hour > time2.hour) return false;
    return time1.minute < time2.minute;
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
```

**Características:**
- Dos selectores coordinados (inicio y fin)
- `endHour` del segundo selector se ajusta dinámicamente basado en `startTime`
- Validación para prevenir ventanas de tiempo inválidas
- El segundo selector solo aparece después de seleccionar el primero
- Intervalos de 30 minutos para simplificar

### Example 5: Integration with Form Validation

```dart
class RecurringEventForm extends StatefulWidget {
  @override
  _RecurringEventFormState createState() => _RecurringEventFormState();
}

class _RecurringEventFormState extends State<RecurringEventForm> {
  final _formKey = GlobalKey<FormState>();
  TimeOfDay? eventTime;
  String? eventName;

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

          // Wrapper para validar selección de tiempo
          FormField<TimeOfDay>(
            initialValue: eventTime,
            validator: (value) {
              if (value == null) {
                return 'Por favor selecciona una hora';
              }
              return null;
            },
            builder: (FormFieldState<TimeOfDay> field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecurrenceTimeSelector(
                    initialTime: field.value,
                    minuteInterval: 5,
                    label: 'Hora del evento',
                    icon: Icons.event,
                    onSelected: (time) {
                      field.didChange(time);
                      setState(() {
                        eventTime = time;
                      });
                    },
                  ),
                  if (field.hasError)
                    Padding(
                      padding: EdgeInsets.only(left: 12, top: 8),
                      child: Text(
                        field.errorText!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                      ),
                    ),
                ],
              );
            },
          ),

          SizedBox(height: 24),

          ElevatedButton(
            onPressed: _submitForm,
            child: Text('Crear evento recurrente'),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Crear evento recurrente
      print('Creando evento "$eventName" a las ${eventTime!.hour}:${eventTime!.minute}');

      // Navegar o mostrar confirmación
      PlatformDialogHelpers.showSnackBar(
        context: context,
        message: 'Evento recurrente creado exitosamente',
      );
    }
  }
}
```

**Características:**
- Integración con `Form` y `FormField` para validación
- Validación requerida: el usuario debe seleccionar un tiempo
- Mensajes de error consistentes con otros campos del formulario
- Estado sincronizado entre `FormField` y widget padre
- Validación ejecutada antes de submit

### Example 6: Persisting Selection to SharedPreferences

```dart
class DailyNotificationSettings extends StatefulWidget {
  @override
  _DailyNotificationSettingsState createState() => _DailyNotificationSettingsState();
}

class _DailyNotificationSettingsState extends State<DailyNotificationSettings> {
  TimeOfDay? notificationTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedTime();
  }

  Future<void> _loadSavedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHour = prefs.getInt('notification_hour');
    final savedMinute = prefs.getInt('notification_minute');

    if (mounted) {
      setState(() {
        if (savedHour != null && savedMinute != null) {
          notificationTime = TimeOfDay(hour: savedHour, minute: savedMinute);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_hour', time.hour);
    await prefs.setInt('notification_minute', time.minute);

    if (mounted) {
      PlatformDialogHelpers.showSnackBar(
        context: context,
        message: 'Hora de notificación guardada',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Text('Notificaciones diarias', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 16),
        RecurrenceTimeSelector(
          initialTime: notificationTime,
          startHour: 6,
          endHour: 23,
          minuteInterval: 15,
          label: 'Hora de notificación',
          icon: Icons.alarm,
          onSelected: (time) async {
            setState(() {
              notificationTime = time;
            });
            await _saveTime(time);
            // Programar notificación local
            await _scheduleLocalNotification(time);
          },
        ),
      ],
    );
  }

  Future<void> _scheduleLocalNotification(TimeOfDay time) async {
    // Implementación usando flutter_local_notifications o similar
    print('Notificación programada para las ${time.hour}:${time.minute} cada día');
  }
}
```

**Características:**
- Persistencia de selección usando `SharedPreferences`
- Carga inicial asíncrona con loading state
- Mounted check después de operaciones async
- Integración con sistema de notificaciones locales
- Auto-guardado cuando el usuario selecciona un tiempo

## 11. Testing Recommendations

### 11.1. Unit Tests

```dart
void main() {
  group('RecurrenceTimeSelector Unit Tests', () {

    test('generates correct number of options for default configuration', () {
      final widget = RecurrenceTimeSelector(
        onSelected: (time) {},
      );

      // Default: 0-23 hours, 5-minute intervals
      // Expected: 24 hours × 12 options per hour = 288 options
      final options = widget._generateTimeOptions();
      expect(options.length, equals(288));
    });

    test('generates correct number of options for custom range', () {
      final widget = RecurrenceTimeSelector(
        onSelected: (time) {},
        startHour: 9,
        endHour: 17,
        minuteInterval: 15,
      );

      // 9 hours (9-17 inclusive) × 4 options per hour = 36 options
      final options = widget._generateTimeOptions();
      expect(options.length, equals(36));
    });

    test('marks correct option as selected when initialTime is provided', () {
      final initialTime = TimeOfDay(hour: 14, minute: 30);
      final widget = RecurrenceTimeSelector(
        onSelected: (time) {},
        initialTime: initialTime,
        minuteInterval: 15,
      );

      final options = widget._generateTimeOptions();
      final selectedOptions = options.where((opt) => opt.isSelected).toList();

      expect(selectedOptions.length, equals(1));
      expect(selectedOptions.first.value.hour, equals(14));
      expect(selectedOptions.first.value.minute, equals(30));
    });

    test('formats time correctly with padding', () {
      final widget = RecurrenceTimeSelector(onSelected: (time) {});

      expect(widget._formatTime24Hour(TimeOfDay(hour: 9, minute: 5)), equals('09:05'));
      expect(widget._formatTime24Hour(TimeOfDay(hour: 14, minute: 30)), equals('14:30'));
      expect(widget._formatTime24Hour(TimeOfDay(hour: 0, minute: 0)), equals('00:00'));
      expect(widget._formatTime24Hour(TimeOfDay(hour: 23, minute: 59)), equals('23:59'));
    });

    test('all generated options are enabled', () {
      final widget = RecurrenceTimeSelector(
        onSelected: (time) {},
        startHour: 10,
        endHour: 12,
      );

      final options = widget._generateTimeOptions();
      expect(options.every((opt) => opt.isEnabled), isTrue);
    });

    test('generates options at correct minute intervals', () {
      final widget = RecurrenceTimeSelector(
        onSelected: (time) {},
        startHour: 10,
        endHour: 10, // Solo una hora
        minuteInterval: 20,
      );

      final options = widget._generateTimeOptions();
      expect(options.length, equals(3)); // 00, 20, 40
      expect(options[0].value.minute, equals(0));
      expect(options[1].value.minute, equals(20));
      expect(options[2].value.minute, equals(40));
    });
  });

  group('RecurrenceTimeSelector Assertions', () {

    test('throws assertion error when minuteInterval is 0', () {
      expect(
        () => RecurrenceTimeSelector(
          onSelected: (time) {},
          minuteInterval: 0,
        ),
        throwsAssertionError,
      );
    });

    test('throws assertion error when minuteInterval > 60', () {
      expect(
        () => RecurrenceTimeSelector(
          onSelected: (time) {},
          minuteInterval: 61,
        ),
        throwsAssertionError,
      );
    });

    test('throws assertion error when startHour > endHour', () {
      expect(
        () => RecurrenceTimeSelector(
          onSelected: (time) {},
          startHour: 15,
          endHour: 10,
        ),
        throwsAssertionError,
      );
    });

    test('throws assertion error when startHour < 0', () {
      expect(
        () => RecurrenceTimeSelector(
          onSelected: (time) {},
          startHour: -1,
        ),
        throwsAssertionError,
      );
    });

    test('throws assertion error when endHour > 23', () {
      expect(
        () => RecurrenceTimeSelector(
          onSelected: (time) {},
          endHour: 24,
        ),
        throwsAssertionError,
      );
    });
  });
}
```

### 11.2. Widget Tests

```dart
void main() {
  group('RecurrenceTimeSelector Widget Tests', () {

    testWidgets('renders HorizontalSelectorWidget with correct parameters', (tester) async {
      TimeOfDay? selectedTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrenceTimeSelector(
              initialTime: TimeOfDay(hour: 10, minute: 30),
              onSelected: (time) {
                selectedTime = time;
              },
              label: 'Test Label',
              icon: Icons.access_time,
            ),
          ),
        ),
      );

      // Verify HorizontalSelectorWidget is rendered
      expect(find.byType(HorizontalSelectorWidget<TimeOfDay>), findsOneWidget);

      // Verify label is displayed
      expect(find.text('Test Label'), findsOneWidget);

      // Verify icon is displayed
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('calls onSelected callback when time is selected', (tester) async {
      TimeOfDay? selectedTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrenceTimeSelector(
              onSelected: (time) {
                selectedTime = time;
              },
              startHour: 10,
              endHour: 10,
              minuteInterval: 30,
            ),
          ),
        ),
      );

      // Simulate selecting a time option
      // Note: This depends on HorizontalSelectorWidget implementation
      // Assuming it renders selectable items

      await tester.pump();

      // Verify initial state
      expect(selectedTime, isNull);
    });

    testWidgets('uses default label when not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrenceTimeSelector(
              onSelected: (time) {},
            ),
          ),
        ),
      );

      // Should use 'Hora' as default
      expect(find.text('Hora'), findsOneWidget);
    });

    testWidgets('uses default icon when not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrenceTimeSelector(
              onSelected: (time) {},
            ),
          ),
        ),
      );

      // Should use Icons.access_time as default
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('rebuilds with new initialTime', (tester) async {
      TimeOfDay? selectedTime;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    RecurrenceTimeSelector(
                      initialTime: selectedTime,
                      onSelected: (time) {
                        setState(() {
                          selectedTime = time;
                        });
                      },
                      minuteInterval: 30,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedTime = TimeOfDay(hour: 15, minute: 30);
                        });
                      },
                      child: Text('Set Time'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Tap button to change selectedTime
      await tester.tap(find.text('Set Time'));
      await tester.pumpAndSettle();

      // Verify widget rebuilt with new initialTime
      expect(selectedTime, isNotNull);
      expect(selectedTime!.hour, equals(15));
      expect(selectedTime!.minute, equals(30));
    });
  });
}
```

### 11.3. Integration Tests

```dart
void main() {
  group('RecurrenceTimeSelector Integration Tests', () {

    testWidgets('complete workflow: select time and save', (tester) async {
      TimeOfDay? savedTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    RecurrenceTimeSelector(
                      initialTime: savedTime,
                      onSelected: (time) {
                        setState(() {
                          savedTime = time;
                        });
                      },
                      startHour: 9,
                      endHour: 17,
                      minuteInterval: 15,
                    ),
                    if (savedTime != null)
                      Text('Selected: ${savedTime!.hour}:${savedTime!.minute}'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initially no time selected
      expect(find.text('Selected: 9:0'), findsNothing);

      // Simulate selecting a time
      // (Implementation depends on HorizontalSelectorWidget)

      await tester.pumpAndSettle();

      // Verify time was saved
      // expect(savedTime, isNotNull);
    });

    testWidgets('integration with form validation', (tester) async {
      final formKey = GlobalKey<FormState>();
      TimeOfDay? eventTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      FormField<TimeOfDay>(
                        initialValue: eventTime,
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a time';
                          }
                          return null;
                        },
                        builder: (field) {
                          return Column(
                            children: [
                              RecurrenceTimeSelector(
                                initialTime: field.value,
                                onSelected: (time) {
                                  field.didChange(time);
                                  setState(() {
                                    eventTime = time;
                                  });
                                },
                              ),
                              if (field.hasError)
                                Text(field.errorText!, style: TextStyle(color: Colors.red)),
                            ],
                          );
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          formKey.currentState!.validate();
                        },
                        child: Text('Validate'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap validate without selecting time
      await tester.tap(find.text('Validate'));
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.text('Please select a time'), findsOneWidget);
    });
  });
}
```

## 12. Comparison with Similar Widgets

### vs. Standard Flutter TimePicker

| Característica | RecurrenceTimeSelector | showTimePicker() |
|----------------|------------------------|------------------|
| **UI Style** | Selector horizontal scrollable | Dialog modal con reloj visual |
| **Selección** | Tap en lista de opciones | Tap/drag en reloj circular |
| **Intervalos** | Configurable (5, 15, 30 min, etc.) | Solo 1 minuto |
| **Rango horario** | Configurable (ej: 9-17) | Siempre 0-23 |
| **Formato** | Solo 24 horas | 12/24 horas según configuración |
| **Plataforma** | Mismo en iOS y Android | Diferente en iOS (Cupertino) y Android (Material) |
| **Opciones visibles** | Todas visibles con scroll | Solo una hora visible |
| **Mejor para** | Horarios recurrentes con intervalos específicos | Selección general de tiempo sin restricciones |

**Cuándo usar `RecurrenceTimeSelector`:**
- Eventos recurrentes con horarios específicos
- Necesidad de restringir opciones (ej: solo horario laboral)
- Intervalos estándar (15 min, 30 min)
- UI consistente entre plataformas

**Cuándo usar `showTimePicker`:**
- Selección de tiempo único/no recurrente
- Necesidad de precisión al minuto
- Preferencia por UI nativa de la plataforma

### vs. CupertinoTimerPicker

| Característica | RecurrenceTimeSelector | CupertinoTimerPicker |
|----------------|------------------------|----------------------|
| **Plataforma** | Cross-platform | Solo iOS style |
| **Modo** | Lista de opciones discretas | Rueda continua |
| **Configuración** | Intervalos, rangos horarios | Solo modo (hms, ms, etc.) |
| **Mejor para** | Opciones predefinidas | Selección continua estilo iOS |

### vs. Custom DropdownButton

| Característica | RecurrenceTimeSelector | DropdownButton |
|----------------|------------------------|----------------|
| **UI** | Selector horizontal scrollable | Dropdown vertical |
| **Selección inicial** | Auto-scroll a selección | Solo muestra seleccionado |
| **Opciones grandes** | Scroll horizontal eficiente | Puede requerir mucho scroll vertical |
| **UX** | Todas las opciones visibles con scroll mínimo | Requiere tap para ver opciones |

## 13. Possible Improvements

1. **Localización del label por defecto**
   - **Problema actual:** Label por defecto 'Hora' está hardcodeado en español
   - **Mejora:** `label: label ?? context.l10n.hour`
   - **Beneficio:** Soporte multi-idioma consistente

2. **Cacheo de opciones generadas**
   - **Problema actual:** `_generateTimeOptions()` se ejecuta en cada build
   - **Mejora:** Usar `useMemoized` (si se usa hooks) o cacheo manual
   ```dart
   late final List<SelectorOption<TimeOfDay>> _cachedOptions = _generateTimeOptions();
   ```
   - **Beneficio:** Mejora performance para rangos grandes o rebuilds frecuentes
   - **Trade-off:** Widget ya no puede ser `const`

3. **Validación de initialTime dentro del rango**
   - **Problema actual:** Si `initialTime` está fuera de `startHour`-`endHour`, simplemente no se selecciona nada
   - **Mejora:** Assertion o warning en debug mode
   ```dart
   assert(
     initialTime == null ||
     (initialTime!.hour >= startHour && initialTime!.hour <= endHour),
     'initialTime must be within startHour and endHour range'
   );
   ```
   - **Beneficio:** Detecta errores de configuración más rápido

4. **Soporte para formato de tiempo localizado**
   - **Problema actual:** Separador `:` siempre es fijo
   - **Mejora:** Usar `MaterialLocalizations.of(context).formatTimeOfDay(time)`
   - **Beneficio:** Respeta preferencias regionales del usuario
   - **Trade-off:** Requiere `BuildContext` en `_formatTime24Hour`

5. **Opción de paso adaptativo (smart intervals)**
   - **Problema actual:** Intervalo es fijo para todo el rango
   - **Mejora:** Intervalos más pequeños cerca de la hora actual, más grandes lejos
   ```dart
   final int Function(int hour)? adaptiveIntervalFunction;
   ```
   - **Ejemplo:** 5 min de 9-12, 15 min de 12-18, 30 min después de 18
   - **Beneficio:** Balance entre precisión y número de opciones

6. **Soporte para minutos de inicio personalizados**
   - **Problema actual:** Cada hora siempre empieza en :00
   - **Mejora:** Parámetro `startMinute` para casos especiales
   ```dart
   final int startMinute;
   ```
   - **Ejemplo:** Iniciar en :15 para eventos que siempre son a :15 o :45
   - **Beneficio:** Mayor flexibilidad para casos específicos

7. **Callback de validación de tiempo**
   - **Problema actual:** Todas las opciones generadas son siempre `isEnabled: true`
   - **Mejora:** Callback para determinar si un tiempo es válido
   ```dart
   final bool Function(TimeOfDay time)? isTimeValid;
   ```
   - **Uso:** Deshabilitar tiempos ya ocupados, fuera de horario de negocio dinámico, etc.
   - **Beneficio:** Prevención de selecciones inválidas sin regenerar opciones

8. **Indicador visual de tiempo actual**
   - **Problema actual:** No hay distinción visual para la hora actual del día
   - **Mejora:** Marcar o resaltar la opción que corresponde a la hora actual
   - **Beneficio:** Contexto adicional para el usuario (ej: "no selecciones tiempo en el pasado")

9. **Agrupación por hora con headers**
   - **Problema actual:** Para muchas opciones (ej: 288 con intervalos de 5 min), puede ser difícil navegar
   - **Mejora:** Headers agrupando por hora
   ```
   09:00
   ├─ 09:00
   ├─ 09:15
   ├─ 09:30
   └─ 09:45
   10:00
   ├─ 10:00
   ...
   ```
   - **Beneficio:** Navegación más fácil en listas largas

10. **Modo de selector doble (rango de tiempo)**
    - **Problema actual:** Solo soporta selección de tiempo único
    - **Mejora:** Modo que permite seleccionar inicio y fin en el mismo widget
    - **Callback modificado:** `onRangeSelected(TimeOfDay start, TimeOfDay end)`
    - **Beneficio:** UX mejorada para definir ventanas de disponibilidad

11. **Accesibilidad mejorada**
    - **Problema actual:** No hay semántica explícita para lectores de pantalla
    - **Mejora:** Añadir `Semantics` widgets con labels descriptivos
    ```dart
    Semantics(
      label: 'Select recurring event time between ${startHour}:00 and ${endHour}:00',
      child: HorizontalSelectorWidget(...)
    )
    ```
    - **Beneficio:** Mejor experiencia para usuarios con discapacidades visuales

12. **Presets comunes**
    - **Problema actual:** Usuario debe scrollear para encontrar tiempos comunes
    - **Mejora:** Botones de acceso rápido para tiempos comunes (9 AM, 12 PM, 6 PM, etc.)
    - **Beneficio:** Selección más rápida para casos comunes

## 14. Real-World Usage Context

### En el contexto de la aplicación EventyPop

`RecurrenceTimeSelector` se utiliza principalmente para configurar horarios de eventos recurrentes. Su integración típica es:

**1. Creación de eventos recurrentes:**
```dart
// En una pantalla de creación de evento
RecurrenceTimeSelector(
  initialTime: _selectedTime,
  startHour: 6,
  endHour: 23,
  minuteInterval: 5,
  onSelected: (time) {
    setState(() {
      _selectedTime = time;
    });
  },
)
```

**2. Edición de patrones de recurrencia:**
Usado en `PatternEditDialog` (widget 21 documentado previamente) para seleccionar el horario específico de cada patrón de recurrencia semanal.

**3. Configuración de recordatorios:**
Para eventos que requieren notificaciones a horas específicas cada día/semana.

### Flujo de datos típico

```
Usuario selecciona tiempo
    ↓
onSelected callback invocado
    ↓
Widget padre actualiza estado
    ↓
RecurrenceTimeSelector se reconstruye con nuevo initialTime
    ↓
HorizontalSelectorWidget hace auto-scroll a la nueva selección
    ↓
Usuario ve confirmación visual
```

### Patrones de integración comunes

1. **Con PatternEditDialog:** Selección de horario para patrón de recurrencia
2. **Con Form validation:** Asegurar que el usuario selecciona un tiempo antes de submit
3. **Con API calls:** Convertir `TimeOfDay` a formato de string "HH:mm:ss" para envío al backend
4. **Con persistencia local:** Guardar preferencias de usuario en SharedPreferences

## 15. Performance Considerations

### Generación de opciones

**Coste computacional:**
- **Operación:** Nested loops generando opciones
- **Complejidad:** O(h × m) donde h = número de horas, m = opciones por hora
- **Caso típico:** 24 horas × 12 opciones (intervalo 5 min) = 288 opciones
- **Tiempo estimado:** < 1ms en dispositivos modernos
- **Memoria:** ~10-20 KB para 288 opciones (aproximado)

**Cuándo puede ser un problema:**
- Intervalos muy pequeños (ej: `minuteInterval: 1` → 1440 opciones)
- Rebuilds muy frecuentes del widget padre
- Dispositivos muy antiguos o de gama baja

**Soluciones si hay problemas de performance:**
1. Cacheo de opciones generadas (ver mejora #2)
2. Lazy loading (generar opciones solo cuando son visibles)
3. Aumentar `minuteInterval` para reducir opciones

### Scroll performance

El scroll es manejado por `HorizontalSelectorWidget`, que usa componentes optimizados de Flutter (`ListView.builder` probablemente), por lo que el performance de scroll debería ser bueno incluso con muchas opciones.

### Rebuilding

Al ser un `StatelessWidget`, los rebuilds son eficientes. Flutter puede hacer optimizaciones como reutilizar widgets que no han cambiado.

**Cuándo se reconstruye:**
- Cuando cambia cualquier parámetro (`initialTime`, `minuteInterval`, etc.)
- Cuando el widget padre se reconstruye y decide reconstruir este hijo

**Optimización:** Si el widget padre se reconstruye frecuentemente pero los parámetros de `RecurrenceTimeSelector` no cambian, considerar extraerlo a un widget separado o usar `const` constructor cuando sea posible.

## 16. Security and Privacy Considerations

### Validación de input

**Protecciones actuales:**
- Assertions en constructor validan rangos de parámetros
- Previene configuraciones inválidas que podrían causar crashes

**Consideraciones:**
- Las assertions solo funcionan en debug mode
- En producción, parámetros inválidos podrían causar comportamiento inesperado

**Recomendación:** Validar parámetros en el widget padre antes de pasar a `RecurrenceTimeSelector`, especialmente si vienen de input del usuario o API.

### Datos sensibles

**Privacidad de horarios:**
- Los horarios seleccionados podrían revelar patrones de comportamiento del usuario
- Ejemplo: Reuniones recurrentes a horas específicas pueden indicar rutinas

**Recomendaciones:**
- Si los horarios se envían a un servidor, usar HTTPS
- Si se guardan localmente, considerar cifrado si la app maneja datos sensibles
- Implementar políticas de retención de datos apropiadas

### Inyección y sanitización

**No hay riesgo directo:**
- El widget solo maneja tipos seguros (`TimeOfDay`, `int`, `String`)
- No hay input de usuario directo (no `TextField`)
- Los valores generados internamente son siempre seguros

**Punto de atención:**
- Si `label` o traducciones vienen de una API externa, asegurar que están sanitizadas antes de mostrar

## 17. Code Quality and Maintainability

### Fortalezas

1. **Código conciso:** 51 líneas totales, fácil de entender completamente
2. **Separación de responsabilidades:** Delegación clara a `HorizontalSelectorWidget`
3. **Type safety:** Uso apropiado de genéricos y tipado explícito
4. **Validación proactiva:** Assertions capturan errores de configuración temprano
5. **Inmutabilidad:** Widget stateless con parámetros finales

### Áreas de mejora

1. **Hardcoded string:** 'Hora' debería ser localizado
2. **Falta de documentación inline:** No hay comentarios explicando la lógica
3. **Separador no localizado:** `:` en formato de tiempo es fijo
4. **Sin tests incluidos:** El widget no viene con suite de tests
5. **Cacheo de opciones:** Performance podría mejorar con memoization

### Métricas de calidad

- **Complejidad ciclomática:** Baja (solo loops simples y condicionales básicos)
- **Acoplamiento:** Medio (depende de `HorizontalSelectorWidget`, `SelectorOption`, `TimeOfDay`)
- **Cohesión:** Alta (todas las funciones están relacionadas con generación de opciones de tiempo)
- **Testabilidad:** Alta (fácil de testear por ser stateless con funciones puras)

---

**Última actualización:** 2025-11-03
**Widget documentado:** 23 de 26
