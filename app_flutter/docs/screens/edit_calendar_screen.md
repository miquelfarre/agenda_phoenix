# EditCalendarScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/edit_calendar_screen.dart`
**Líneas**: 389
**Tipo**: ConsumerStatefulWidget
**Propósito**: Pantalla para editar un calendario existente, incluyendo nombre, descripción, visibilidad, y opción de eliminación con confirmación

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **AdaptivePageScaffold** (usado como scaffold principal)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_scaffold.md`

**Uso**:
```dart
AdaptivePageScaffold(
  title: calendar?.name ?? l10n.editCalendar,
  body: [formulario de edición],
)
```
**Propósito**: Scaffold adaptativo con back button

### 2.2. Resumen de Dependencias de Widgets

```
EditCalendarScreen
└── AdaptivePageScaffold (scaffold principal)
    └── SafeArea
        └── SingleChildScrollView
            └── Padding
                └── Column (formulario)
                    ├── CupertinoTextField (nombre)
                    ├── CupertinoTextField (descripción)
                    ├── CupertinoSwitch (público/privado)
                    ├── CupertinoSwitch (puede eliminar eventos)
                    ├── Sección de código compartir (custom)
                    └── CupertinoButton (guardar + eliminar)
```

**Total de widgets propios**: 1 (AdaptivePageScaffold)
**Nota**: Similar a CreateCalendarScreen pero con carga de datos existentes y opción de eliminar

---

## 3. CLASE Y PROPIEDADES

### EditCalendarScreen (líneas 13-20)
Widget principal que extiende `ConsumerStatefulWidget`

**Propiedades**:
- `calendarId` (String, required): ID del calendario a editar como String

**Constructor**:
```dart
const EditCalendarScreen({super.key, required this.calendarId})
```

### _EditCalendarScreenState (líneas 22-388)
Estado del widget que extiende `ConsumerState<EditCalendarScreen>`

**Controllers**:
- `_nameController` (TextEditingController, línea 23): Controla el campo de nombre del calendario
- `_descriptionController` (TextEditingController, línea 24): Controla el campo de descripción del calendario

**Variables de estado**:
- `_isDiscoverable` (bool, línea 26): Indica si el calendario es descubrible en búsquedas, inicializada en true
- `_deleteAssociatedEvents` (bool, línea 27): Indica si se eliminarán eventos asociados al borrar, inicializada en false
- `_isLoading` (bool, línea 28): Indica si se está procesando una operación, inicializada en true (porque carga datos al inicio)
- `_calendar` (Calendar?, línea 29): Almacena el objeto calendario cargado, inicializada en null

## 3. CICLO DE VIDA

### initState() (líneas 31-35)
**Tipo de retorno**: `void`

**Propósito**: Inicializa el estado del widget y carga el calendario al montar la pantalla

**Lógica**:
1. Llama a `super.initState()`
2. Llama a `_loadCalendar()` para cargar los datos del calendario

**Momento de ejecución**: Se ejecuta una sola vez cuando el widget se monta

### dispose() (líneas 37-42)
**Tipo de retorno**: `void`

**Propósito**: Limpia los recursos cuando el widget se desmonta

**Lógica**:
1. Llama a `_nameController.dispose()` para liberar recursos del controller de nombre
2. Llama a `_descriptionController.dispose()` para liberar recursos del controller de descripción
3. Llama a `super.dispose()` para completar el dispose del widget

**Importancia**: Previene memory leaks al liberar los TextEditingControllers

## 4. MÉTODOS PRINCIPALES

### Future<void> _loadCalendar() (líneas 44-82)
**Tipo de retorno**: `Future<void>`
**Es async**: Sí

**Propósito**: Carga el calendario desde el repositorio y verifica que el usuario tenga permisos para editarlo

**Lógica detallada**:

1. **Bloque try** (líneas 45-76):

   a) **Obtiene el repositorio** (línea 46):
      - `calendarRepository = ref.read(calendarRepositoryProvider)`

   b) **Busca el calendario** (línea 47):
      - Llama a `calendarRepository.getCalendarById(int.parse(widget.calendarId))`
      - Convierte el calendarId de String a int

   c) **Verifica si existe** (líneas 49-54):
      - Condición: `calendar == null`
      - Verifica `mounted` antes de continuar
      - Muestra error con `DialogHelpers.showErrorDialogWithIcon()`
      - Mensaje: `l10n.calendarNotFound`
      - Cierra la pantalla con `context.pop()`
      - Retorna sin continuar

   d) **Verifica permisos de edición** (líneas 56-67):
      - Comentario en línea 56: "Verify user has permission to edit (owner OR admin)"
      - Llama a `await CalendarPermissions.canEdit()` con:
        - `calendar`: el calendario cargado
        - `repository`: el repositorio de calendarios
      - Si `!canEdit` (línea 62):
        - Verifica `mounted`
        - Muestra error con `DialogHelpers.showErrorDialogWithIcon()`
        - Mensaje: `l10n.noPermission`
        - Cierra la pantalla con `context.pop()`
        - Retorna sin continuar

   e) **Actualiza el estado con los datos** (líneas 69-76):
      - Llama a `setState()`
      - Establece `_calendar = calendar`
      - Establece `_nameController.text = calendar.name`
      - Establece `_descriptionController.text = calendar.description ?? ''`
      - Establece `_isDiscoverable = calendar.isDiscoverable`
      - Establece `_deleteAssociatedEvents = calendar.deleteAssociatedEvents`
      - Establece `_isLoading = false`

2. **Bloque catch** (líneas 77-81):
   - Verifica `mounted` antes de continuar
   - Muestra error con `DialogHelpers.showErrorDialogWithIcon()`
   - Mensaje: `l10n.failedToLoadCalendar`
   - Cierra la pantalla con `context.pop()`

**Casos manejados**:
- Calendario no encontrado: muestra error y cierra
- Sin permisos de edición: muestra error y cierra
- Error al cargar: muestra error y cierra
- Carga exitosa: llena los campos con los datos actuales

### Future<void> _updateCalendar() (líneas 84-131)
**Tipo de retorno**: `Future<void>`
**Es async**: Sí

**Propósito**: Valida los datos del formulario y actualiza el calendario en el backend

**Lógica detallada**:

1. **Obtiene y valida el nombre** (línea 85):
   - Obtiene texto con `_nameController.text.trim()`

2. **Validación: nombre vacío** (líneas 87-90):
   - Condición: `name.isEmpty`
   - Muestra diálogo de error
   - Mensaje: `l10n.calendarNameRequired`
   - Retorna sin continuar

3. **Validación: nombre muy largo** (líneas 92-95):
   - Condición: `name.length > 100`
   - Muestra diálogo de error
   - Mensaje: `l10n.calendarNameTooLong`
   - Retorna sin continuar

4. **Obtiene y valida la descripción** (línea 97):
   - Obtiene texto con `_descriptionController.text.trim()`

5. **Validación: descripción muy larga** (líneas 98-101):
   - Condición: `description.length > 500`
   - Muestra diálogo de error
   - Mensaje: `l10n.calendarDescriptionTooLong`
   - Retorna sin continuar

6. **Establece estado de loading** (líneas 103-105):
   - Llama a `setState()`
   - Establece `_isLoading = true`

7. **Bloque try** (líneas 107-118):
   - **Prepara datos de actualización** (líneas 108-112):
     - Crea `Map<String, dynamic>` con:
       - `'name'`: nombre trimmed
       - `'description'`: descripción (null si vacía)
       - `'is_discoverable'`: valor de `_isDiscoverable`

   - **Actualiza el calendario** (línea 113):
     - Llama a `ref.read(calendarRepositoryProvider).updateCalendar()`
     - Parámetros:
       - `int.parse(widget.calendarId)`: ID convertido a int
       - `updateData`: mapa con los datos

   - **Comentario** (línea 115):
     - "Realtime handles refresh automatically via CalendarRepository"

   - **Verifica mounted** (línea 117):
     - Si `!mounted`, retorna

   - **Cierra la pantalla** (línea 118):
     - Llama a `context.pop()` para volver

8. **Bloque catch** (líneas 119-124):
   - Verifica `mounted` (línea 120)
   - Parsea error con `ErrorMessageParser.parse(e, context)` (línea 122)
   - Muestra diálogo de error con mensaje parseado (línea 123)

9. **Bloque finally** (líneas 124-130):
   - Verifica `mounted` (línea 125)
   - Establece `_isLoading = false` con setState (líneas 126-128)

**Nota importante**: No envía `_deleteAssociatedEvents` en el update, solo se usa al eliminar

### Future<void> _deleteCalendar() (líneas 133-163)
**Tipo de retorno**: `Future<void>`
**Es async**: Sí

**Propósito**: Muestra confirmación y elimina el calendario del backend

**Lógica detallada**:

1. **Muestra diálogo de confirmación** (líneas 134-135):
   - Llama a `await _showDeleteConfirmation()`
   - Obtiene resultado booleano
   - Si `!confirmed`, retorna sin continuar

2. **Establece estado de loading** (líneas 137-139):
   - Llama a `setState()`
   - Establece `_isLoading = true`

3. **Bloque try** (líneas 141-150):
   - **Elimina el calendario** (líneas 142-145):
     - Llama a `ref.read(calendarRepositoryProvider).deleteCalendar()`
     - Parámetros:
       - `int.parse(widget.calendarId)`: ID convertido a int
       - `deleteAssociatedEvents`: valor de `_deleteAssociatedEvents`
     - Usa named parameter para claridad

   - **Comentario** (línea 147):
     - "Realtime handles refresh automatically via CalendarRepository"

   - **Verifica mounted** (línea 149):
     - Si `!mounted`, retorna

   - **Cierra la pantalla** (línea 150):
     - Llama a `context.pop()` para volver
     - El calendario desaparecerá de la lista por Realtime

4. **Bloque catch** (líneas 151-162):
   - **Verifica mounted** (línea 152):
     - Si `!mounted`, retorna

   - **Parsea y muestra error** (líneas 154-155):
     - Usa `ErrorMessageParser.parse(e, context)`
     - Muestra diálogo con el mensaje

   - **Restaura estado si montado** (líneas 157-161):
     - Verifica `mounted`
     - Establece `_isLoading = false` con setState

**Nota**: No usa `finally` porque solo restaura loading en caso de error (si tiene éxito, cierra la pantalla)

### Future<bool> _showDeleteConfirmation() (líneas 165-190)
**Tipo de retorno**: `Future<bool>`
**Es async**: Sí (implícitamente por await)

**Propósito**: Muestra un diálogo de confirmación antes de eliminar el calendario

**Lógica detallada**:

1. **Obtiene localizaciones** (línea 166):
   - `l10n = context.l10n`

2. **Muestra diálogo** (líneas 167-188):
   - Usa `showCupertinoDialog<bool>()` con:
     - `context`: contexto actual
     - `builder`: función que retorna `CupertinoAlertDialog` con:

       a) **Título** (línea 170):
          - Text con `l10n.deleteCalendar`

       b) **Contenido** (líneas 171-175):
          - Text dinámico basado en `_deleteAssociatedEvents`:
            - Si true: `l10n.confirmDeleteCalendarWithEvents`
            - Si false: `l10n.confirmDeleteCalendarKeepEvents`

       c) **Acciones** (líneas 176-186):
          - **Botón Cancelar** (líneas 177-180):
            - Text: `l10n.cancel`
            - onPressed: `Navigator.of(context).pop(false)`
            - Retorna false (no confirma)

          - **Botón Eliminar** (líneas 181-185):
            - `isDestructiveAction: true` (estilo rojo)
            - Text: `l10n.delete`
            - onPressed: `Navigator.of(context).pop(true)`
            - Retorna true (confirma)

3. **Retorna resultado** (línea 189):
   - `return result ?? false`
   - Si el usuario cierra el diálogo sin elegir, retorna false

**Casos manejados**:
- Usuario confirma: retorna true
- Usuario cancela: retorna false
- Usuario cierra diálogo: retorna false

## 5. MÉTODOS DE CONSTRUCCIÓN DE UI

### Widget build(BuildContext context, WidgetRef ref) (líneas 192-219)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `context`: BuildContext para acceso al contexto
- `ref`: WidgetRef para acceso a providers

**Propósito**: Construye la UI principal de la pantalla con scaffold y manejo de loading inicial

**Lógica detallada**:

1. **Obtiene localizaciones** (línea 194):
   - `l10n = context.l10n`

2. **Estado: Cargando calendario inicial** (líneas 196-201):
   - Condición: `_isLoading && _calendar == null`
   - Significa: está cargando y aún no tiene datos
   - Retorna: `AdaptivePageScaffold` con:
     - title: `l10n.editCalendar`
     - body: `Center` con `CupertinoActivityIndicator`

3. **Estado: Datos cargados** (líneas 203-218):
   - Condición: tiene calendario cargado
   - Retorna: `AdaptivePageScaffold` con:

     - **Título** (línea 204):
       - `l10n.editCalendar`

     - **Botón leading** (líneas 205-209):
       - `CupertinoButton` con:
         - padding: EdgeInsets.zero
         - onPressed: `context.pop()`
         - child: Text con `l10n.cancel`

     - **Botón de acción** (líneas 210-216):
       - `CupertinoButton` con:
         - padding: EdgeInsets.zero
         - onPressed: `_updateCalendar` (null si loading)
         - child: `CupertinoActivityIndicator` si loading, sino Text con `l10n.save`

     - **Body** (línea 217):
       - Llama a `_buildContent()` para construir el contenido

### Widget _buildContent() (líneas 221-239)
**Tipo de retorno**: `Widget`

**Propósito**: Construye el contenido scrollable con las secciones del formulario

**Lógica detallada**:

1. **SafeArea** (línea 222):
   - Envuelve todo el contenido

2. **SingleChildScrollView** (líneas 223-237):
   - padding: 16px en todos los lados
   - child: `Column` con:

     - **crossAxisAlignment** (línea 226):
       - `CrossAxisAlignment.start` para alinear a la izquierda

     - **children** (líneas 227-236):

       a) **Sección de información básica** (línea 228):
          - Llama a `_buildBasicInfoSection()`

       b) **Espaciador** (línea 229): 16px

       c) **Sección de visibilidad condicional** (líneas 230-233):
          - Condición: `_calendar!.isPublic`
          - Solo se muestra si el calendario es público
          - Contiene:
            - Llamada a `_buildVisibilitySection()`
            - Espaciador de 16px

       d) **Sección de eliminación** (línea 234):
          - Llama a `_buildDeleteSection()`

**Estructura condicional**: La sección de visibilidad solo aparece para calendarios públicos

### Widget _buildBasicInfoSection() (líneas 241-290)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la sección con información básica del calendario (nombre, descripción, tipo)

**Lógica detallada**:

1. **Obtiene localizaciones** (línea 242):
   - `l10n = context.l10n`

2. **Container** (líneas 244-289):
   - margin: EdgeInsets.zero
   - decoration: `AppStyles.cardDecoration` (estilo de tarjeta)
   - padding: 16px en todos los lados
   - child: `Column` con:

     a) **Título de sección** (líneas 251-254):
        - Text: `l10n.calendarInformation`
        - Estilo: fontSize 16, fontWeight 600, color gris700

     b) **Espaciador** (línea 255): 16px

     c) **Campo de nombre** (líneas 256-266):
        - `CupertinoTextField` con:
          - controller: `_nameController`
          - placeholder: `l10n.calendarName`
          - maxLength: 100
          - enabled: `!_isLoading`
          - decoration: BoxDecoration con:
            - border: gris300
            - borderRadius: 8
          - padding: 12px en todos los lados

     d) **Espaciador** (línea 267): 12px

     e) **Campo de descripción** (líneas 268-279):
        - `CupertinoTextField` con:
          - controller: `_descriptionController`
          - placeholder: `l10n.calendarDescription`
          - maxLines: 3 (multilinea)
          - maxLength: 500
          - enabled: `!_isLoading`
          - decoration: igual que nombre
          - padding: 12px

     f) **Espaciador** (línea 280): 16px

     g) **Indicador de tipo público/privado** (líneas 281-286):
        - `CupertinoListTile` con:
          - title: `l10n.publicCalendar`
          - subtitle: Dinámico basado en `_calendar!.isPublic`:
            - Si true: `l10n.visibleToOthers`
            - Si false: `l10n.private`
          - trailing: `CupertinoSwitch`:
            - value: `_calendar!.isPublic`
            - onChanged: null (deshabilitado, no se puede cambiar)
          - padding: EdgeInsets.zero

**Nota**: El switch de público/privado está deshabilitado, solo muestra el estado actual sin permitir cambios

### Widget _buildVisibilitySection() (líneas 292-327)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la sección de visibilidad para calendarios públicos, permitiendo cambiar si es descubrible

**Lógica detallada**:

1. **Obtiene localizaciones** (línea 293):
   - `l10n = context.l10n`

2. **Container** (líneas 295-326):
   - margin: EdgeInsets.zero
   - decoration: `AppStyles.cardDecoration`
   - padding: 16px en todos los lados
   - child: `Column` con:

     a) **Título de sección** (líneas 302-305):
        - Text: `l10n.visibility`
        - Estilo: fontSize 16, fontWeight 600, color gris700

     b) **Espaciador** (línea 306): 16px

     c) **Switch de descubrible** (líneas 307-323):
        - `CupertinoListTile` con:
          - title: `l10n.discoverableCalendar`
          - subtitle: Dinámico basado en `_isDiscoverable`:
            - Si true: `l10n.appearsInSearch`
            - Si false: `l10n.onlyViaShareLink`
          - trailing: `CupertinoSwitch` con:
            - value: `_isDiscoverable`
            - onChanged:
              - null si `_isLoading`
              - Callback que actualiza `_isDiscoverable` con setState
          - padding: EdgeInsets.zero

**Función**: Permite controlar si el calendario público aparece en búsquedas o solo es accesible por link

### Widget _buildDeleteSection() (líneas 329-387)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la sección de eliminación del calendario con estilo visual distintivo (rojo) y confirmación

**Lógica detallada**:

1. **Obtiene localizaciones** (línea 330):
   - `l10n = context.l10n`

2. **Container** (líneas 332-386):
   - margin: EdgeInsets.zero
   - **decoration** (líneas 334-338): BoxDecoration personalizada con estilo de alerta:
     - color: Rojo con 5% de opacidad (fondo rojo muy suave)
     - borderRadius: 12
     - border: Rojo con 20% de opacidad, width 1
   - padding: 16px en todos los lados
   - child: `Column` con:

     a) **Header con icono** (líneas 343-352):
        - Row con:
          - **Icono** (línea 345):
            - `CupertinoIcons.delete`
            - color: CupertinoColors.systemRed
            - size: 20
          - **Espaciador** (línea 346): 8px
          - **Título** (líneas 347-350):
            - Text: `l10n.deleteCalendar`
            - Estilo: fontSize 16, fontWeight 600, color negro87

     b) **Espaciador** (línea 353): 12px

     c) **Descripción** (líneas 354-357):
        - Text: `l10n.chooseWhatHappensToEvents`
        - Estilo: fontSize 14, color gris600

     d) **Espaciador** (línea 358): 16px

     e) **Switch de eliminar eventos** (líneas 359-375):
        - `CupertinoListTile` con:
          - title: `l10n.deleteAssociatedEvents`
          - subtitle: Dinámico basado en `_deleteAssociatedEvents`:
            - Si true: `l10n.eventsWillBeDeleted`
            - Si false: `l10n.eventsWillBeKept`
          - trailing: `CupertinoSwitch` con:
            - value: `_deleteAssociatedEvents`
            - onChanged:
              - null si `_isLoading`
              - Callback que actualiza `_deleteAssociatedEvents` con setState
          - padding: EdgeInsets.zero

     f) **Espaciador** (línea 376): 16px

     g) **Botón de eliminar** (líneas 377-383):
        - `SizedBox` con width: double.infinity (ocupa todo el ancho)
        - `CupertinoButton.filled` (botón con relleno) con:
          - onPressed: `_deleteCalendar` (null si loading)
          - child: Text con `l10n.deleteCalendar`

**Diseño visual**: El fondo rojo suave y el borde rojo alertan visualmente sobre la naturaleza destructiva de esta sección

## 6. DEPENDENCIAS

### Packages externos:
- `flutter/cupertino.dart`: Widgets de estilo iOS
- `flutter_riverpod`: Estado con Riverpod (ConsumerStatefulWidget, ConsumerState, WidgetRef)
- `go_router`: Navegación (context.pop())

### Imports internos - Helpers:
- `../ui/helpers/l10n/l10n_helpers.dart`: Extensión `context.l10n` para localizaciones
- `../ui/helpers/platform/dialog_helpers.dart`: `DialogHelpers.showErrorDialogWithIcon()` para diálogos de error

### Imports internos - Styles:
- `../ui/styles/app_styles.dart`: Estilos de la aplicación
  - `AppStyles.cardDecoration`: Decoración de tarjeta
  - `AppStyles.grey300`, `grey600`, `grey700`: Colores
  - `AppStyles.black87`: Color negro
  - `AppStyles.colorWithOpacity()`: Helper para opacidad

### Imports internos - Widgets:
- `../widgets/adaptive_scaffold.dart`: `AdaptivePageScaffold` para scaffold adaptativo

### Imports internos - Models:
- `../models/calendar.dart`: Modelo `Calendar`

### Imports internos - State:
- `../core/state/app_state.dart`: Providers, incluye `calendarRepositoryProvider`

### Imports internos - Utils:
- `../utils/calendar_permissions.dart`: `CalendarPermissions.canEdit()` para verificar permisos
- `../utils/error_message_parser.dart`: `ErrorMessageParser.parse()` para convertir excepciones en mensajes legibles

### Providers utilizados:
- `calendarRepositoryProvider`: Repository de calendarios
  - Métodos usados:
    - `getCalendarById(id)`: Obtiene calendario por ID
    - `updateCalendar(id, data)`: Actualiza calendario
    - `deleteCalendar(id, deleteAssociatedEvents)`: Elimina calendario

### Métodos de CalendarPermissions:
- `canEdit(calendar, repository)`: Verifica si el usuario puede editar el calendario (owner o admin)

### Widgets de Flutter:
- `CupertinoTextField`: Campo de texto de estilo iOS
- `CupertinoButton`: Botón de estilo iOS
- `CupertinoButton.filled`: Botón con relleno de estilo iOS
- `CupertinoActivityIndicator`: Indicador de carga de iOS
- `CupertinoSwitch`: Switch de estilo iOS
- `CupertinoListTile`: Elemento de lista con trailing
- `CupertinoAlertDialog`: Diálogo de alerta de iOS
- `CupertinoDialogAction`: Acción en diálogo
- `SingleChildScrollView`: Scroll simple
- `SafeArea`: Área segura sin overlays
- `Container`: Contenedor con decoración
- `Row`, `Column`: Layouts
- `SizedBox`: Espaciador

### Funciones de diálogos:
- `showCupertinoDialog<T>()`: Muestra diálogo de Cupertino con tipo de retorno

### Localización:
Strings usados:
- `editCalendar`: "Editar calendario" (título)
- `cancel`: "Cancelar" (botón leading)
- `save`: "Guardar" (botón de acción)
- `calendarNotFound`: Error si no se encuentra el calendario
- `noPermission`: Error si no tiene permisos
- `failedToLoadCalendar`: Error genérico de carga
- `calendarInformation`: "Información del calendario" (título sección)
- `calendarName`: Placeholder para nombre
- `calendarDescription`: Placeholder para descripción
- `publicCalendar`: "Calendario público" (label)
- `visibleToOthers`: "Visible para otros" (subtitle si público)
- `private`: "Privado" (subtitle si privado)
- `visibility`: "Visibilidad" (título sección)
- `discoverableCalendar`: "Calendario descubrible" (label)
- `appearsInSearch`: "Aparece en búsquedas" (subtitle si descubrible)
- `onlyViaShareLink`: "Solo por enlace" (subtitle si no descubrible)
- `deleteCalendar`: "Eliminar calendario" (título y botón)
- `chooseWhatHappensToEvents`: "Elige qué pasa con los eventos" (descripción)
- `deleteAssociatedEvents`: "Eliminar eventos asociados" (label)
- `eventsWillBeDeleted`: "Los eventos serán eliminados" (subtitle si true)
- `eventsWillBeKept`: "Los eventos se mantendrán" (subtitle si false)
- `confirmDeleteCalendarWithEvents`: Confirmación de eliminar con eventos
- `confirmDeleteCalendarKeepEvents`: Confirmación de eliminar sin eventos
- `delete`: "Eliminar" (botón de confirmación)
- `calendarNameRequired`: Error si nombre vacío
- `calendarNameTooLong`: Error si nombre > 100 caracteres
- `calendarDescriptionTooLong`: Error si descripción > 500 caracteres

## 7. FLUJO DE DATOS

### Al abrir la pantalla:
1. Usuario navega a EditCalendarScreen con `calendarId`
2. Constructor recibe el ID como String
3. `initState()` se ejecuta
4. Llama a `_loadCalendar()`
5. `_isLoading = true` (valor inicial)
6. UI muestra scaffold con spinner centrado (build detecta `_isLoading && _calendar == null`)
7. Obtiene `calendarRepository` del provider
8. Llama a `getCalendarById(int.parse(calendarId))`
9. Si no existe:
   - Muestra error "calendario no encontrado"
   - Cierra la pantalla con `context.pop()`
10. Si existe, verifica permisos:
    - Llama a `CalendarPermissions.canEdit(calendar, repository)`
    - Si `!canEdit`:
      - Muestra error "sin permisos"
      - Cierra la pantalla
11. Si tiene permisos:
    - Actualiza `_calendar` con el objeto
    - Llena `_nameController.text` con nombre actual
    - Llena `_descriptionController.text` con descripción actual (o vacío)
    - Establece `_isDiscoverable` con valor actual
    - Establece `_deleteAssociatedEvents` con valor actual
    - Establece `_isLoading = false`
12. UI reconstruye mostrando el formulario con datos

### Al escribir en campos:
1. Usuario escribe en CupertinoTextField
2. TextEditingController actualiza automáticamente su texto
3. No hay setState, los controllers mantienen el valor
4. Usuario puede editar libremente

### Al cambiar switch de descubrible:
1. Usuario toca el CupertinoSwitch de "Calendario descubrible"
2. Solo disponible si el calendario es público
3. Callback `onChanged(value)` se ejecuta
4. Llama a `setState(() { _isDiscoverable = value; })`
5. UI reconstruye:
   - Switch muestra nuevo estado
   - Subtitle cambia entre "Aparece en búsquedas" / "Solo por enlace"

### Al cambiar switch de eliminar eventos:
1. Usuario toca el CupertinoSwitch de "Eliminar eventos asociados"
2. Callback `onChanged(value)` se ejecuta
3. Llama a `setState(() { _deleteAssociatedEvents = value; })`
4. UI reconstruye:
   - Switch muestra nuevo estado
   - Subtitle cambia entre "Los eventos serán eliminados" / "Los eventos se mantendrán"

### Al presionar "Guardar":
1. Usuario presiona el botón "Guardar"
2. Llama a `_updateCalendar()`
3. Valida nombre:
   - Si vacío: muestra error y retorna
   - Si > 100 caracteres: muestra error y retorna
4. Valida descripción:
   - Si > 500 caracteres: muestra error y retorna
5. Establece `_isLoading = true`
6. UI reconstruye:
   - Botón muestra CupertinoActivityIndicator
   - Campos y switches se deshabilitan
7. Prepara `updateData` con:
   - name: nombre trimmed
   - description: descripción trimmed (null si vacía)
   - is_discoverable: valor de `_isDiscoverable`
8. Llama a `calendarRepository.updateCalendar(id, updateData)`
9. Espera respuesta del backend:

   **Caso éxito**:
   - Backend actualiza el calendario
   - Realtime notifica el cambio
   - Lista de calendarios se actualiza automáticamente
   - Verifica `mounted`
   - Llama a `context.pop()` para cerrar la pantalla
   - Usuario vuelve a la pantalla anterior con cambios visibles

   **Caso error**:
   - Backend retorna error
   - Catch captura la excepción
   - Verifica `mounted`
   - Parsea el error con `ErrorMessageParser.parse()`
   - Muestra diálogo de error
   - Usuario ve el mensaje

10. **Finally** (siempre):
    - Verifica `mounted`
    - Establece `_isLoading = false`
    - UI reconstruye habilitando el formulario nuevamente

### Al presionar "Eliminar calendario":
1. Usuario presiona el botón rojo "Eliminar calendario"
2. Llama a `_deleteCalendar()`
3. Llama a `_showDeleteConfirmation()`
4. Muestra `CupertinoAlertDialog` con:
   - Título: "Eliminar calendario"
   - Contenido dinámico basado en `_deleteAssociatedEvents`:
     - Si true: "Confirmar eliminar calendario con eventos"
     - Si false: "Confirmar eliminar calendario manteniendo eventos"
   - Botón "Cancelar": retorna false
   - Botón "Eliminar" (rojo): retorna true
5. Usuario elige:

   **Si cancela**:
   - Diálogo retorna false
   - `_deleteCalendar()` retorna sin hacer nada
   - Formulario permanece abierto

   **Si confirma**:
   - Diálogo retorna true
   - Establece `_isLoading = true`
   - UI reconstruye deshabilitando todo
   - Llama a `calendarRepository.deleteCalendar(id, deleteAssociatedEvents: _deleteAssociatedEvents)`
   - Espera respuesta del backend:

     **Caso éxito**:
     - Backend elimina el calendario (y eventos si corresponde)
     - Realtime notifica la eliminación
     - Lista de calendarios se actualiza automáticamente
     - Verifica `mounted`
     - Llama a `context.pop()` para cerrar la pantalla
     - Usuario vuelve a lista sin el calendario eliminado

     **Caso error**:
     - Backend retorna error (ej: sin permisos, calendario no existe)
     - Catch captura la excepción
     - Verifica `mounted`
     - Parsea el error con `ErrorMessageParser.parse()`
     - Muestra diálogo de error
     - Verifica `mounted` nuevamente
     - Establece `_isLoading = false`
     - UI reconstruye habilitando el formulario
     - Usuario puede reintentar

### Al presionar "Cancelar":
1. Usuario presiona botón "Cancelar" en leading
2. Llama a `context.pop()`
3. Cierra la pantalla sin guardar cambios
4. Vuelve a la pantalla anterior

## 8. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Cargar calendario**: Carga datos del calendario desde el repositorio
2. **Verificar permisos**: Verifica que el usuario pueda editar (owner o admin)
3. **Editar información**: Permite cambiar nombre y descripción
4. **Cambiar visibilidad**: Permite cambiar si es descubrible (solo calendarios públicos)
5. **Eliminar calendario**: Permite eliminar con confirmación y elección de qué hacer con los eventos
6. **Validación de campos**: Valida longitud de nombre y descripción
7. **Feedback de loading**: Muestra indicadores mientras procesa operaciones

### Campos editables:
1. **Nombre**:
   - Requerido
   - Máximo 100 caracteres
   - Validación: no vacío, longitud máxima
   - Se hace trim antes de enviar
   - TextField con borde gris y border radius

2. **Descripción**:
   - Opcional
   - Máximo 500 caracteres
   - Multilinea (3 líneas visibles)
   - Validación: longitud máxima
   - Se hace trim antes de enviar
   - Se envía null si está vacía
   - TextField con borde gris y border radius

3. **Calendario descubrible** (solo si es público):
   - Switch booleano
   - Determina si aparece en búsquedas o solo por link
   - Solo se muestra si `_calendar.isPublic == true`

4. **Eliminar eventos asociados**:
   - Switch booleano en sección de eliminación
   - Determina qué pasa con los eventos al eliminar el calendario
   - Afecta el mensaje de confirmación

### Campos no editables:
1. **Tipo público/privado**:
   - Switch deshabilitado (`onChanged: null`)
   - Solo muestra el estado actual
   - No se puede cambiar después de crear el calendario

### Permisos requeridos:
- Usuario debe ser owner o admin del calendario
- Verificado con `CalendarPermissions.canEdit()`
- Si no tiene permisos, muestra error y cierra la pantalla

### Estados visuales:
1. **Cargando inicial**: Spinner centrado mientras carga calendario
2. **Normal**: Formulario habilitado, botón "Guardar" activo
3. **Loading operación**: Formulario deshabilitado, botón muestra spinner
4. **Error**: Diálogo modal con mensaje de error

### Interacciones disponibles:
1. **Escribir en campos**: Actualiza texto en controllers
2. **Cambiar switch descubrible**: Actualiza visibilidad (solo públicos)
3. **Cambiar switch eliminar eventos**: Actualiza comportamiento de eliminación
4. **Presionar "Guardar"**: Valida y actualiza el calendario
5. **Presionar "Eliminar calendario"**: Muestra confirmación y elimina
6. **Presionar "Cancelar"**: Cierra sin guardar

### Secciones condicionales:
- **Sección de visibilidad**: Solo se muestra si `_calendar.isPublic == true`
- Permite estructura flexible según tipo de calendario

## 9. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 389
**Métodos**: 9 (1 initState + 1 dispose + 1 loadCalendar + 1 updateCalendar + 1 deleteCalendar + 1 showDeleteConfirmation + 1 build + 1 buildContent + 3 builders de secciones)
**Tipo**: ConsumerStatefulWidget con estado local

**Distribución aproximada**:
- Imports: ~11 líneas (2.8%)
- Declaración de clase ConsumerStatefulWidget: ~8 líneas (2.1%)
- Variables de estado y controllers: ~7 líneas (1.8%)
- initState method: ~5 líneas (1.3%)
- dispose method: ~6 líneas (1.5%)
- _loadCalendar method: ~39 líneas (10.0%)
- _updateCalendar method: ~48 líneas (12.3%)
- _deleteCalendar method: ~31 líneas (8.0%)
- _showDeleteConfirmation method: ~26 líneas (6.7%)
- build method: ~28 líneas (7.2%)
- _buildContent method: ~19 líneas (4.9%)
- _buildBasicInfoSection method: ~50 líneas (12.9%)
- _buildVisibilitySection method: ~36 líneas (9.3%)
- _buildDeleteSection method: ~59 líneas (15.2%)
- Resto (espacios, llaves): ~16 líneas (4.1%)

**Complejidad por método**:
- `_loadCalendar()`: Complejidad media-alta (try-catch, verificaciones múltiples, mounted checks)
- `_updateCalendar()`: Complejidad media-alta (validaciones, try-catch-finally, mounted checks)
- `_deleteCalendar()`: Complejidad media-alta (confirmación, try-catch, mounted checks)
- `_showDeleteConfirmation()`: Complejidad baja (solo muestra diálogo)
- `build()`: Complejidad baja (maneja 2 estados: loading inicial y normal)
- `_buildContent()`: Complejidad baja (estructura simple con condicional)
- Builders de secciones: Complejidad media (UI compleja pero sin lógica)

## 10. CARACTERÍSTICAS TÉCNICAS

### ConsumerStatefulWidget:
- Usa `ConsumerStatefulWidget` para acceso a Riverpod y estado local
- `WidgetRef ref` se usa en múltiples métodos para acceder al repository provider

### TextEditingControllers:
- 2 controllers: `_nameController` y `_descriptionController`
- Se disponen en `dispose()` para evitar memory leaks
- Se llenan en `_loadCalendar()` con datos actuales del calendario
- Se hace `.trim()` al obtener los valores para validación y envío

### Carga inicial con loading:
- `_isLoading` inicia en true
- `_calendar` inicia en null
- `build()` detecta `_isLoading && _calendar == null` para mostrar spinner inicial
- Diferencia entre "cargando datos" y "procesando operación"

### Verificación de permisos:
- Usa `CalendarPermissions.canEdit(calendar, repository)`
- Verifica que el usuario sea owner o admin
- Si no tiene permisos, muestra error y cierra
- Previene ediciones no autorizadas

### Validaciones en cliente:
- **Nombre vacío**: Verifica antes de enviar al backend
- **Nombre muy largo**: Máximo 100 caracteres
- **Descripción muy larga**: Máximo 500 caracteres
- Muestra diálogos de error con `DialogHelpers.showErrorDialogWithIcon()`
- Previene llamadas innecesarias al backend

### Bloque try-catch-finally:
- `_updateCalendar()` usa try-catch-finally:
  - **try**: Actualiza el calendario
  - **catch**: Muestra error
  - **finally**: Restaura `_isLoading = false`
- `_deleteCalendar()` usa try-catch (sin finally):
  - Si tiene éxito, cierra la pantalla
  - Si falla, restaura `_isLoading` en el catch

### Mounted checks:
- Verifica `mounted` 11 veces en total:
  - 4 veces en `_loadCalendar()`
  - 2 veces en `_updateCalendar()`
  - 3 veces en `_deleteCalendar()`
- Previene errores de llamar setState o navegar en widget desmontado

### Descripción opcional:
- Si la descripción está vacía, se envía `null` al backend
- Lógica: `description.isEmpty ? null : description`
- Permite diferenciar entre "sin descripción" y "descripción vacía"

### Realtime automático:
- Comentarios en líneas 115 y 147: "Realtime handles refresh automatically via CalendarRepository"
- No necesita llamar manualmente a refresh después de update o delete
- La lista de calendarios se actualiza automáticamente por suscripción Realtime
- Simplifica el flujo de datos

### ErrorMessageParser:
- Convierte excepciones del backend en mensajes legibles para el usuario
- Uso: `ErrorMessageParser.parse(e, context)`
- Toma el error y el contexto para localizar el mensaje
- Mejora UX con mensajes claros

### DialogHelpers:
- Usa `DialogHelpers.showErrorDialogWithIcon()` para todos los errores
- Diálogos consistentes con icono de error
- 6 tipos de errores:
  1. Calendario no encontrado
  2. Sin permisos
  3. Error al cargar calendario
  4. Validación de nombre vacío
  5. Validación de longitud de nombre
  6. Validación de longitud de descripción
  7. Errores del backend (update/delete)

### Diálogo de confirmación personalizado:
- `_showDeleteConfirmation()` retorna `Future<bool>`
- Usa `showCupertinoDialog<bool>()` con tipo específico
- Contenido dinámico según `_deleteAssociatedEvents`
- Botón eliminar con `isDestructiveAction: true` (estilo rojo)
- Retorna `result ?? false` para manejar cierre sin selección

### Conversión de ID:
- `calendarId` se recibe como String
- Se convierte a int con `int.parse(widget.calendarId)` antes de cada llamada al repositorio
- Usado en: `getCalendarById()`, `updateCalendar()`, `deleteCalendar()`

### Map de datos de actualización:
- Usa `Map<String, dynamic>` para `updateData` (líneas 108-112)
- Incluye: name, description, is_discoverable
- **No incluye** `deleteAssociatedEvents` (solo se usa al eliminar)
- Claves en snake_case para el backend

### Named parameter en delete:
- `deleteCalendar(id, deleteAssociatedEvents: _deleteAssociatedEvents)`
- Usa named parameter para claridad
- Hace explícito qué hace el parámetro

### Switch deshabilitado para público/privado:
- `CupertinoSwitch(value: _calendar!.isPublic, onChanged: null)`
- `onChanged: null` deshabilita el switch
- Solo muestra el estado actual
- No permite cambiar de público a privado o viceversa después de crear

### Sección condicional:
- `if (_calendar!.isPublic) ...[]` en líneas 230-233
- Usa spread operator para insertar widgets condicionalmente
- Sección de visibilidad solo aparece para calendarios públicos
- Estructura limpia sin wrapping en Visibility o condicionales complejos

### Estilo visual para sección de eliminación:
- Container con decoración personalizada (líneas 334-338)
- Fondo: Rojo con 5% de opacidad
- Borde: Rojo con 20% de opacidad
- `AppStyles.colorWithOpacity()` helper para crear colores con transparencia
- Diseño visual alerta sobre acción destructiva

### CupertinoButton.filled:
- Usa `CupertinoButton.filled` para botón de eliminar (línea 379)
- Botón con fondo sólido (en lugar de solo texto)
- Más prominente para acción importante
- Se deshabilita durante loading (`onPressed: null`)

### SizedBox con width infinity:
- `SizedBox(width: double.infinity, child: CupertinoButton.filled(...))`
- Hace que el botón ocupe todo el ancho disponible
- Mejora UX al hacer el botón más fácil de presionar
- Común en formularios

### BoxDecoration para TextFields:
- TextFields tienen decoración personalizada (líneas 261-264, 274-277)
- border: `Border.all(color: AppStyles.grey300)`
- borderRadius: 8
- Estilo consistente más sofisticado que el default de iOS

### Padding personalizado en TextFields:
- `padding: const EdgeInsets.all(12)`
- Aumenta el área táctil interna
- Mejora legibilidad del texto
- Más cómodo para escribir

### Card decoration reutilizable:
- Usa `AppStyles.cardDecoration` para contenedores de secciones
- Estilo consistente en toda la app
- Mantiene diseño unificado

### CupertinoListTile con padding zero:
- `padding: EdgeInsets.zero` en todos los `CupertinoListTile`
- Evita padding extra dentro de los containers
- Da más control sobre espaciado

### Subtítulos dinámicos:
- Subtítulos cambian según el valor de los switches:
  - Público: "Visible para otros" / "Privado"
  - Descubrible: "Aparece en búsquedas" / "Solo por enlace"
  - Eliminar eventos: "Los eventos serán eliminados" / "Los eventos se mantendrán"
- Feedback visual inmediato del significado de cada opción

### SafeArea y SingleChildScrollView:
- SafeArea evita overlays del sistema
- SingleChildScrollView permite scroll si el contenido es largo
- Especialmente útil cuando aparece el teclado
- Padding de 16px para márgenes consistentes

### Column con crossAxisAlignment.start:
- `crossAxisAlignment: CrossAxisAlignment.start` en _buildContent
- Alinea todo el contenido a la izquierda
- Consistencia visual en todas las secciones

### Espaciadores consistentes:
- 16px entre secciones principales
- 12px dentro de secciones entre elementos relacionados
- 8px para separaciones mínimas (icono-texto)
- Jerarquía visual clara

### Estado de loading durante operaciones:
- Durante update o delete:
  - Botón "Guardar" muestra spinner
  - Botón se deshabilita
  - Campos se deshabilitan
  - Switches se deshabilitan
- Previene ediciones y múltiples envíos
- Feedback visual claro de que se está procesando
