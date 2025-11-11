# CreateEditEventScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/create_edit_event_screen.dart`
**Líneas**: 756
**Tipo**: BaseFormScreen (hereda de clase base de formularios)
**Propósito**: Pantalla de formulario para crear o editar eventos con soporte para eventos recurrentes, cumpleaños, calendarios y timezones personalizados

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **CustomDateTimeWidget**
**Archivo**: `lib/widgets/custom_datetime_widget.dart`
**Documentación**: Pendiente
**Propósito**: Selector de fecha y hora personalizado con scroll

#### **CalendarHorizontalSelector**
**Archivo**: `lib/widgets/calendar_horizontal_selector.dart`
**Documentación**: Pendiente
**Propósito**: Selector horizontal de calendarios disponibles

#### **TimezoneHorizontalSelector**
**Archivo**: `lib/widgets/timezone_horizontal_selector.dart`
**Documentación**: Pendiente
**Propósito**: Selector horizontal de zona horaria con país y ciudad

#### **RecurrenceTimeSelector**
**Archivo**: `lib/widgets/recurrence_time_selector.dart`
**Documentación**: Pendiente
**Propósito**: Selector de patrones de recurrencia (diario, semanal, mensual)

### 2.2. Resumen de Dependencias de Widgets

```
CreateEditEventScreen (BaseFormScreen)
└── SafeArea
    └── Form
        ├── CupertinoTextField (título)
        ├── CupertinoTextField (descripción)
        ├── CalendarHorizontalSelector
        ├── CustomDateTimeWidget (inicio)
        ├── CustomDateTimeWidget (fin)
        ├── TimezoneHorizontalSelector
        ├── RecurrenceTimeSelector
        ├── CupertinoTextField (ubicación)
        └── Botones de acción
```

**Total de widgets propios**: 4 widgets custom especializados para formulario de eventos

---

## 3. CLASE Y PROPIEDADES

### CreateEditEventScreen (líneas 23-31)
Widget principal que extiende `BaseFormScreen`

**Propiedades**:
- `eventToEdit` (Event?, optional): Evento a editar (null si es creación)
- `isRecurring` (bool, default: false): Si el evento será recurrente al crearlo

### CreateEditEventScreenState (líneas 33-755)
Estado del widget que extiende `BaseFormScreenState<CreateEditEventScreen>`

**Propiedades de instancia - Controllers**:
- `_titleController` (TextEditingController): Controller para el título del evento
- `_descriptionController` (TextEditingController): Controller para la descripción

**Propiedades de instancia - Keys**:
- `_startDateKey` (GlobalKey): Key para el widget de fecha, permite llamar a `scrollToToday()`

**Propiedades de instancia - Timezone**:
- `_selectedCountry` (Country?): País seleccionado para timezone
- `_selectedTimezone` (String): Timezone seleccionada (default: 'Europe/Madrid')
- `_defaultCity` (String): Ciudad por defecto del usuario (default: 'Madrid')
- `_customCity` (String?): Ciudad personalizada seleccionada
- `_useCustomTimezone` (bool): Si usa timezone personalizada (default: false)

**Propiedades de instancia - Calendario**:
- `_useCustomCalendar` (bool): Si asocia el evento a un calendario (default: false)

**Getters computados** (acceden a valores del formulario base):
- `_selectedDate` (DateTime): Fecha seleccionada, normalizada a intervalos de 5 minutos
- `_isRecurringEvent` (bool): Si el evento es recurrente
- `_patterns` (List<RecurrencePattern>): Patrones de recurrencia configurados
- `_isBirthday` (bool): Si el evento es un cumpleaños
- `_selectedCalendarId` (String?): ID del calendario seleccionado

## 3. CICLO DE VIDA

### initState() (líneas 59-62)
1. Llama a `super.initState()`
2. Llama a `_loadDefaultTimezone()` para cargar configuración del usuario

### dispose() (líneas 98-102)
1. Limpia `_titleController.dispose()`
2. Limpia `_descriptionController.dispose()`
3. Llama a `super.dispose()`

### initializeFormData() (líneas 78-95)
**Propósito**: Inicializa los campos del formulario (override de BaseFormScreen)

**Lógica**:
1. Si `widget.eventToEdit` NO es null (modo edición):
   - Carga título en el controller
   - Carga descripción en el controller (o string vacío)
   - Carga fecha normalizada con `setFieldValue('startDate', ...)`
   - Carga si es recurrente con `setFieldValue('isRecurring', ...)`
   - Carga patrones con `setFieldValue('patterns', ...)`
   - Carga si es cumpleaños con `setFieldValue('isBirthday', ...)`
   - Carga ID de calendario con `setFieldValue('calendarId', ...)`
2. Si `widget.eventToEdit` ES null (modo creación):
   - Fecha: ahora normalizado
   - isRecurring: valor del parámetro `widget.isRecurring`
   - patterns: lista vacía
   - isBirthday: false
   - calendarId: null

## 4. MÉTODOS AUXILIARES

### _normalizeToFiveMinutes(DateTime dateTime) (líneas 53-56)
**Tipo de retorno**: `DateTime`
**Modificador**: static

**Parámetros**:
- `dateTime`: Fecha a normalizar

**Propósito**: Redondea los minutos al múltiplo de 5 más cercano

**Lógica**:
1. Divide minutos por 5
2. Redondea el resultado (`round()`)
3. Multiplica por 5
4. Retorna nuevo DateTime con año, mes, día, hora, y minuto normalizado

**Ejemplo**: 14:23 → 14:25, 14:27 → 14:25, 14:28 → 14:30

### _loadDefaultTimezone() (líneas 64-75)
**Tipo de retorno**: `void`

**Propósito**: Carga la timezone por defecto de la configuración del usuario

**Lógica**:
1. Lee `settingsNotifierProvider` con `ref.read()`
2. Usa `whenData()` para manejar el AsyncValue
3. Si hay datos, actualiza estado con:
   - `_selectedTimezone` = settings.defaultTimezone
   - `_defaultCity` = settings.defaultCity
   - `_customCity` = settings.defaultCity
   - `_selectedCountry` = país obtenido por código con `CountryService.getCountryByCode()`

## 5. MÉTODOS DE BASEFORMSCREEN (OVERRIDES)

### screenTitle (líneas 105)
**Tipo**: getter String

**Retorna**:
- "Crear evento" si `eventToEdit` es null
- "Editar evento" si `eventToEdit` NO es null

### submitButtonText (líneas 108)
**Tipo**: getter String

**Retorna**:
- "Crear evento" si `eventToEdit` es null
- "Guardar" si `eventToEdit` NO es null

### showSaveInNavBar (líneas 111)
**Tipo**: getter bool

**Retorna**: false (no muestra botón de guardar en la navbar)

### validateForm() (líneas 114-130)
**Tipo de retorno**: `Future<bool>`

**Propósito**: Valida el formulario antes de enviarlo

**Lógica**:
1. Verifica que el título NO esté vacío (con trim):
   - Si está vacío: establece error en campo 'title' y retorna false
2. Si es evento recurrente:
   - Verifica que haya al menos un patrón configurado
   - Si no hay: establece error en campo 'patterns' y retorna false
3. Si todas las validaciones pasan: retorna true

### submitForm() (líneas 133-172)
**Tipo de retorno**: `Future<bool>`

**Propósito**: Envía el formulario al backend para crear/actualizar

**Lógica**:
1. En bloque try-catch:
2. Construye objeto `eventData` con:
   - 'id': ID del evento o -1 si es nuevo
   - 'title': título con trim
   - 'description': descripción con trim
   - 'start_date': fecha en formato ISO8601
   - 'owner_id': ID del usuario actual desde ConfigService
   - 'is_recurring': si es recurrente
   - 'event_type': 'parent' si es recurrente, 'standalone' si no
   - 'location': 'Madrid' (hardcoded)
   - 'recurrence_pattern': null
   - 'is_birthday': si es cumpleaños
   - 'calendar_id': ID del calendario seleccionado
   - 'timezone': timezone seleccionada
   - 'city': ciudad personalizada si usa custom timezone, sino ciudad por defecto
   - 'country_code': código del país o 'ES' por defecto
3. Si es recurrente:
   - Añade 'patterns' al eventData con patrones en formato JSON
4. Si es edición (`eventToEdit` NO es null):
   - Llama a `eventServiceProvider.updateEvent()` con ID y datos
   - Incluye comentario: Realtime maneja el refresh automáticamente
5. Si es creación:
   - Llama a `eventServiceProvider.createEvent()` con datos
   - Incluye comentario: Realtime maneja el refresh automáticamente
6. Retorna true si tiene éxito
7. En catch:
   - Si está montado: establece error general con `setError()`
   - Retorna false

### onFormSubmitSuccess() (líneas 175-182)
**Tipo de retorno**: `void`

**Propósito**: Callback que se ejecuta después de submit exitoso

**Lógica**:
1. Muestra snackbar con:
   - "Evento actualizado" si es edición
   - "Evento creado" si es creación
2. Si está montado: navega atrás con `Navigator.pop()`

### buildFormFields() (líneas 185-430)
**Tipo de retorno**: `List<Widget>`

**Propósito**: Construye todos los campos del formulario (override de BaseFormScreen)

**Estructura de widgets retornados**:

1. **Row de tipo de evento** (líneas 188-287): 3 botones para seleccionar tipo
   - **Botón evento normal** (calendario):
     - Si se presiona: desactiva recurrente y cumpleaños
     - Color azul si activo, gris si no
   - **Botón evento recurrente** (repeat):
     - Si se presiona: activa/desactiva recurrente
     - Si se activa: desactiva cumpleaños
     - Si se desactiva: limpia patrones
   - **Botón cumpleaños** (emoji 🎂):
     - Si se presiona: activa/desactiva cumpleaños
     - Si se activa: desactiva recurrente, limpia patrones, ajusta fecha a solo día (sin hora), activa calendar, busca calendario "Cumpleaños"/"Birthdays"
     - Si se desactiva: limpia calendario

2. **Espaciador**: 24px

3. **Campo de título** (línea 291): `buildTextField()`
   - fieldName: 'title'
   - required: true

4. **Campo de descripción** (línea 293): Si NO es cumpleaños
   - fieldName: 'description'
   - maxLines: 3

5. **Sección de timezone** (líneas 295-360): Si NO es cumpleaños
   - **Switch**: "Usar timezone personalizada"
     - Si se desactiva: recarga timezone por defecto
   - **Si está activado**:
     - Muestra `TimezoneHorizontalSelector` con país, timezone y ciudad
     - Callback onChanged actualiza `_selectedCountry`, `_selectedTimezone`, `_customCity`
   - **Si NO está activado**:
     - Muestra Container con información de timezone por defecto
     - Icono de globo + ciudad + timezone + offset actual

6. **Espaciador**: 24px

7. **Sección de fecha/hora** (líneas 364-421): Container con padding
   - Si NO es cumpleaños:
     - Header con icono de calendario + "Fecha de inicio"
     - Botón "Hoy" que llama a `scrollToToday()` en el widget
   - `CustomDateTimeWidget`:
     - showTimePicker: false si es cumpleaños
     - showTodayButton: false
     - onDateTimeChanged: actualiza 'startDate'

8. **Sección de patrones** (línea 423): Si es recurrente
   - Llama a `_buildPatternsSection()`

9. **Sección de calendario** (línea 425): Si NO es cumpleaños
   - Llama a `_buildCalendarSection()`

10. **Mensajes de error** (líneas 427-428):
    - Si hay error en 'title': muestra texto de error
    - Si hay error en 'patterns': muestra texto de error

## 6. MÉTODOS DE CONSTRUCCIÓN DE UI

### _buildErrorText(String error) (líneas 432-437)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `error`: Mensaje de error a mostrar

**Estructura**:
- Padding superior de 8px
- Text en rojo (systemRed), tamaño 14

### _buildPatternsSection() (líneas 439-538)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la sección de patrones de recurrencia

**Estructura**:
Column con:
1. **Título**: "Patrones de recurrencia"
2. **Espaciador**: 8px
3. **Botón de añadir** (ancho completo):
   - Color azul primario
   - Icono add + texto:
     - "Añadir primer patrón" si no hay patrones
     - "Añadir otro patrón" si ya hay patrones
   - onPressed: llama a `_addPattern()`
4. **Estado vacío** (si no hay patrones):
   - Container con fondo gris
   - Icono de calendario + "No hay patrones de recurrencia"
   - Subtitle: "Pulsa añadir patrón para empezar"
5. **Lista de patrones** (si hay patrones):
   - Para cada patrón: Container con:
     - Fondo blanco, borde gris, sombra ligera
     - Row con:
       - Icono de repeat en círculo azul claro
       - Texto del patrón formateado (ej: "Lunes @ 18:00:00")
       - Botón de delete con icono rojo

### _buildCalendarSection() (líneas 658-662)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la sección de selección de calendario

**Lógica**:
1. Observa `calendarsStreamProvider` con `ref.watch`
2. Retorna Column con `_buildCalendarWidget(calendarsAsync)`

### _buildCalendarWidget(AsyncValue<List<dynamic>> calendarsAsync) (líneas 664-754)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `calendarsAsync`: AsyncValue con lista de calendarios

**Propósito**: Renderiza el selector de calendario según el estado async

**Lógica**:
1. **Si está loading**: retorna `CupertinoActivityIndicator`
2. **Si hay error**: retorna Text rojo con el error
3. **Si no hay valor**: retorna `SizedBox.shrink()`
4. **Si la lista está vacía**: retorna `SizedBox.shrink()`
5. **Si hay calendarios**: retorna Column con:
   - **Si NO es cumpleaños**:
     - Switch: "Asociar con calendario"
     - Si se desactiva: limpia calendarId
   - **Si usa calendario o es cumpleaños**:
     - Row con:
       - `CalendarHorizontalSelector` expandido:
         - Lista de calendarios
         - calendarId seleccionado
         - Callback onSelected
         - isDisabled si es cumpleaños (no se puede cambiar)
       - Espaciador de 12px
       - Botón de añadir calendario (+):
         - Navega a '/communities/create'
         - Invalida provider después para recargar

## 7. MÉTODOS DE GESTIÓN DE PATRONES

### _addPattern() (líneas 540-542)
**Tipo de retorno**: `void`

**Propósito**: Inicia el proceso de añadir un patrón

**Lógica**:
- Llama a `_showPatternPicker()`

### _removePattern(int index) (líneas 544-548)
**Tipo de retorno**: `void`

**Parámetros**:
- `index`: Índice del patrón a eliminar

**Propósito**: Elimina un patrón de la lista

**Lógica**:
1. Crea copia de la lista actual de patrones
2. Elimina el patrón en el índice especificado
3. Actualiza el campo 'patterns' con la nueva lista

### _showPatternPicker() (líneas 550-648)
**Tipo de retorno**: `void`

**Propósito**: Muestra modal para seleccionar día y hora del patrón

**Lógica**:
1. Muestra `showCupertinoModalPopup` con altura 450
2. Usa `StatefulBuilder` para estado interno del modal
3. Variables de estado interno:
   - `selectedDay` (int): Día seleccionado (0-6, Lunes-Domingo)
   - `selectedTime` (TimeOfDay): Hora seleccionada (default: 18:00)

**Estructura del modal**:
- **Header** (líneas 566-601):
  - Botón "Cancelar": cierra el modal
  - Título: "Añadir primer patrón"
  - Botón "Añadir":
    - Formatea hora a string "HH:MM:SS"
    - Crea `RecurrencePattern` con eventId, día, y hora
    - Añade a lista de patrones con `setFieldValue()`
    - Cierra el modal
- **Body** (líneas 603-640):
  - Label: "Selecciona día de la semana"
  - `CupertinoPicker` con:
    - Lista de días traducidos (Lunes-Domingo)
    - itemExtent: 40
    - onSelectedItemChanged: actualiza `selectedDay`
  - Espaciador de 16px
  - `RecurrenceTimeSelector`:
    - Altura: 80px
    - initialTime: selectedTime
    - onSelected: actualiza `selectedTime`
    - minuteInterval: 5 (intervalos de 5 minutos)
    - label: "Seleccionar hora"
  - Espaciador de 16px

### _formatPatternDisplay(RecurrencePattern pattern) (líneas 650-656)
**Tipo de retorno**: `String`

**Parámetros**:
- `pattern`: Patrón a formatear

**Propósito**: Convierte patrón a texto legible

**Lógica**:
1. Obtiene array de nombres de días traducidos
2. Obtiene nombre del día según `pattern.dayOfWeek`
3. Si el día es válido: usa nombre, sino usa "Error desconocido"
4. Retorna string formato: "{Día} @ {hora}" (ej: "Lunes @ 18:00:00")

## 8. DEPENDENCIAS

### Providers utilizados:
- `settingsNotifierProvider`: Configuración del usuario (read)
- `calendarsStreamProvider`: Stream de calendarios (watch, invalidate)
- `eventServiceProvider`: Servicio de eventos (read)

### Services:
- `CountryService.getCountryByCode()`: Obtiene país por código
- `TimezoneService.getCurrentOffset()`: Obtiene offset de timezone
- `ConfigService.instance.currentUserId`: ID del usuario actual

### Widgets externos:
- `CupertinoSwitch`: Switch de iOS
- `CupertinoButton`: Botón de iOS
- `CupertinoPicker`: Picker de rueda de iOS
- `CupertinoActivityIndicator`: Indicador de carga de iOS
- `CupertinoModalPopup`: Modal de iOS (para pattern picker)
- `StatefulBuilder`: Para estado interno en modal

### Widgets internos:
- `BaseFormScreen`: Clase base para formularios
- `CustomDateTimeWidget`: Selector de fecha y hora personalizado
- `CalendarHorizontalSelector`: Selector horizontal de calendarios
- `TimezoneHorizontalSelector`: Selector de timezone con país, zona y ciudad
- `RecurrenceTimeSelector`: Selector de hora para patrones

### Helpers:
- `PlatformDialogHelpers.showSnackBar()`: Muestra snackbars adaptativos
- `context.l10n`: Acceso a localizaciones
- `buildTextField()`: Método heredado de BaseFormScreen para construir campos

### Navegación:
- `Navigator.of(context).pop()`: Para volver atrás
- `context.push()`: GoRouter para navegación

### Models:
- `Event`: Modelo de evento
- `RecurrencePattern`: Modelo de patrón de recurrencia
- `Calendar`: Modelo de calendario
- `Country`: Modelo de país

## 9. FLUJO DE DATOS

### Al abrir en modo creación:
1. `initState()` se ejecuta
2. Carga timezone por defecto del usuario
3. `initializeFormData()` inicializa campos vacíos
4. Si `isRecurring` es true: activa modo recurrente
5. Renderiza formulario vacío

### Al abrir en modo edición:
1. `initState()` se ejecuta
2. Carga timezone por defecto del usuario
3. `initializeFormData()` carga datos del evento a editar
4. Renderiza formulario con datos precargados

### Al cambiar tipo de evento:
- **Normal → Recurrente**: Limpia cumpleaños, activa recurrente
- **Normal → Cumpleaños**: Limpia recurrente y patrones, activa cumpleaños, ajusta fecha a solo día, busca calendario de cumpleaños
- **Recurrente → Normal**: Desactiva recurrente, limpia patrones
- **Recurrente → Cumpleaños**: Similar a Normal → Cumpleaños
- **Cumpleaños → Normal**: Desactiva cumpleaños, limpia calendario

### Al añadir patrón:
1. Usuario presiona "Añadir patrón"
2. Se abre modal con picker de día y hora
3. Usuario selecciona día (lunes-domingo) y hora
4. Presiona "Añadir"
5. Se crea `RecurrencePattern` y se añade a la lista
6. Modal se cierra
7. Patrón aparece en la lista

### Al enviar formulario:
1. Usuario presiona botón de submit
2. `validateForm()` valida campos:
   - Título no vacío
   - Si recurrente: mínimo 1 patrón
3. Si válido: `submitForm()` se ejecuta:
   - Construye objeto `eventData`
   - Llama a API (create o update)
4. Si exitoso: `onFormSubmitSuccess()` se ejecuta:
   - Muestra snackbar de confirmación
   - Navega atrás
5. Realtime actualiza automáticamente la lista de eventos

## 10. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Crear evento nuevo**: Formulario vacío para crear evento
2. **Editar evento existente**: Precarga datos del evento
3. **Tipos de evento**:
   - Normal: Evento estándar de una vez
   - Recurrente: Evento que se repite en días/horas específicos
   - Cumpleaños: Evento especial sin hora, asignado a calendario de cumpleaños
4. **Gestión de patrones de recurrencia**:
   - Añadir múltiples patrones
   - Cada patrón: día de la semana + hora
   - Eliminar patrones individuales
5. **Timezone personalizada**:
   - Usar timezone por defecto del usuario, O
   - Seleccionar país, timezone y ciudad personalizados
6. **Asociación con calendario**:
   - Opcional: asociar evento a un calendario
   - Crear nuevo calendario desde el formulario
   - Auto-asociación para cumpleaños
7. **Validación**:
   - Título requerido
   - Mínimo 1 patrón si es recurrente
8. **Normalización de hora**: Redondea minutos a múltiplos de 5

### Estados manejados:
- Modo creación vs edición
- Tipo de evento (normal/recurrente/cumpleaños)
- Lista de patrones (vacía/con elementos)
- Timezone (por defecto/personalizada)
- Calendario (sin asociar/asociado)
- Loading de calendarios
- Errores de validación
- Errores de submit

### Restricciones:
- **Recurrente y cumpleaños**: mutuamente excluyentes
- **Cumpleaños**: calendario obligatorio (auto-seleccionado)
- **Cumpleaños**: sin descripción, sin hora, sin timezone personalizada
- **Recurrente**: mínimo 1 patrón requerido
- **Minutos**: normalizados a múltiplos de 5

## 11. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 756
**Métodos públicos**: 7 (overrides de BaseFormScreen)
**Métodos privados**: 9
**Getters**: 6 (5 computados + 2 overrides)

**Distribución aproximada**:
- Declaración de clase y propiedades: ~52 líneas (6.9%)
- Ciclo de vida: ~38 líneas (5.0%)
- Normalización de fecha: ~4 líneas (0.5%)
- Carga de timezone: ~12 líneas (1.6%)
- Overrides de BaseFormScreen: ~68 líneas (9.0%)
- buildFormFields principal: ~245 líneas (32.4%)
  - Botones de tipo: ~100 líneas
  - Campos de texto: ~3 líneas
  - Sección timezone: ~66 líneas
  - Sección fecha: ~58 líneas
  - Otras secciones: ~18 líneas
- Construcción de patrones: ~99 líneas (13.1%)
- Gestión de patrones: ~109 líneas (14.4%)
- Pattern picker modal: ~99 líneas (13.1%)
- Formato de patrón: ~7 líneas (0.9%)
- Sección de calendario: ~97 líneas (12.8%)
- Imports: ~22 líneas (2.9%)

## 12. CARACTERÍSTICAS TÉCNICAS

### Herencia de BaseFormScreen:
- Utiliza sistema de campos con `getFieldValue()` / `setFieldValue()`
- Sistema de errores con `setFieldError()` / `getFieldError()`
- Métodos template: `validateForm()`, `submitForm()`, `onFormSubmitSuccess()`
- Helper `buildTextField()` para campos de texto

### Normalización de fechas:
- Todas las fechas se normalizan a múltiplos de 5 minutos
- Evita minutos "raros" como 14:23 → se convierte en 14:25
- Mejora UX al trabajar con selectores de tiempo

### Gestión de estado compleja:
- Campos interdependientes (recurrente ↔ cumpleaños)
- Auto-selección de calendario para cumpleaños
- Limpieza automática de campos relacionados

### Modal con estado interno:
- Pattern picker usa `StatefulBuilder`
- Mantiene estado temporal (selectedDay, selectedTime)
- Solo actualiza formulario principal al confirmar

### Integración con servicios:
- Configuración del usuario (timezone, ciudad, país)
- Lista de países y timezones
- Lista de calendarios en tiempo real

### Realtime updates:
- Después de crear/editar: NO recarga manualmente
- Confía en Realtime para actualizar listas automáticamente
- Invalida provider después de crear calendario

### Accesibilidad con Keys:
- Keys para testing: 'add_pattern_button', 'remove_pattern_{day}_{time}', etc.
- GlobalKey para acceder a métodos del widget de fecha (`scrollToToday()`)

### Validación progresiva:
- Muestra errores solo después de intentar submit
- Errores se limpian automáticamente al corregir campos
- Errores visuales en rojo debajo de secciones relevantes
