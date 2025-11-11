# CreateCalendarScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/create_calendar_screen.dart`
**Líneas**: 128
**Tipo**: ConsumerStatefulWidget
**Propósito**: Pantalla de formulario para crear un nuevo calendario con nombre, descripción, y opciones de visibilidad y eliminación de eventos

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **AdaptivePageScaffold** (usado como scaffold principal)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_scaffold.md`

**Uso**:
```dart
AdaptivePageScaffold(
  title: l10n.createCalendar,
  body: [formulario],
)
```
**Propósito**: Scaffold adaptativo con back button y navegación inferior

### 2.2. Resumen de Dependencias de Widgets

```
CreateCalendarScreen
└── AdaptivePageScaffold (scaffold principal)
    └── SafeArea
        └── SingleChildScrollView
            └── Padding
                └── Column (formulario)
                    ├── CupertinoTextField (nombre)
                    ├── CupertinoTextField (descripción)
                    ├── CupertinoSwitch (público/privado)
                    ├── CupertinoSwitch (puede eliminar eventos)
                    └── CupertinoButton (guardar)
```

**Total de widgets propios**: 1 (AdaptivePageScaffold)
**Nota**: Pantalla de formulario simple que usa principalmente widgets nativos de Cupertino

---

## 3. CLASE Y PROPIEDADES

### CreateCalendarScreen (líneas 10-15)
Widget principal que extiende `ConsumerStatefulWidget`

**Constructor**:
```dart
const CreateCalendarScreen({super.key})
```

No recibe parámetros, es una pantalla de creación desde cero.

### _CreateCalendarScreenState (líneas 17-127)
Estado del widget que extiende `ConsumerState<CreateCalendarScreen>`

**Controllers**:
- `_nameController` (TextEditingController, línea 18): Controla el campo de nombre del calendario
- `_descriptionController` (TextEditingController, línea 19): Controla el campo de descripción del calendario

**Variables de estado**:
- `_isPublic` (bool, línea 21): Indica si el calendario será público, inicializada en false
- `_deleteAssociatedEvents` (bool, línea 22): Indica si se eliminarán eventos asociados al borrar el calendario, inicializada en false
- `_isLoading` (bool, línea 23): Indica si se está procesando la creación, inicializada en false

## 3. CICLO DE VIDA

### dispose() (líneas 25-30)
**Tipo de retorno**: `void`

**Propósito**: Limpia los recursos cuando el widget se desmonta

**Lógica**:
1. Llama a `_nameController.dispose()` para liberar recursos del controller de nombre
2. Llama a `_descriptionController.dispose()` para liberar recursos del controller de descripción
3. Llama a `super.dispose()` para completar el dispose del widget

**Importancia**: Previene memory leaks al liberar los TextEditingControllers

## 4. MÉTODOS PRINCIPALES

### Future<void> _createCalendar() (líneas 32-75)
**Tipo de retorno**: `Future<void>`
**Es async**: Sí

**Propósito**: Valida los datos del formulario y crea el calendario en el backend

**Lógica detallada**:

1. **Obtiene y valida el nombre** (línea 33):
   - Obtiene texto con `_nameController.text.trim()`
   - Elimina espacios al inicio y final

2. **Validación: nombre vacío** (líneas 35-38):
   - Condición: `name.isEmpty`
   - Muestra diálogo de error con `DialogHelpers.showErrorDialogWithIcon()`
   - Mensaje: `l10n.calendarNameRequired`
   - Retorna sin continuar

3. **Validación: nombre muy largo** (líneas 40-43):
   - Condición: `name.length > 100`
   - Muestra diálogo de error
   - Mensaje: `l10n.calendarNameTooLong`
   - Retorna sin continuar

4. **Obtiene y valida la descripción** (línea 45):
   - Obtiene texto con `_descriptionController.text.trim()`

5. **Validación: descripción muy larga** (líneas 46-49):
   - Condición: `description.length > 500`
   - Muestra diálogo de error
   - Mensaje: `l10n.calendarDescriptionTooLong`
   - Retorna sin continuar

6. **Establece estado de loading** (líneas 51-53):
   - Llama a `setState()`
   - Establece `_isLoading = true`
   - Deshabilita el formulario y muestra indicador de carga

7. **Bloque try** (líneas 55-62):
   - **Crea el calendario** (línea 56):
     - Llama a `ref.read(calendarRepositoryProvider).createCalendar()`
     - Parámetros:
       - `name`: nombre del calendario
       - `description`: descripción (null si está vacía)
       - `isPublic`: valor de `_isPublic`
     - Espera con `await` a que complete

   - **Comentario importante** (línea 58):
     - "Realtime handles refresh automatically via CalendarRepository"
     - No necesita refrescar manualmente, Realtime lo hace automáticamente

   - **Verifica mounted** (línea 60):
     - Si `!mounted`, retorna sin hacer nada

   - **Cierra la pantalla** (línea 62):
     - Llama a `context.pop()` para volver a la pantalla anterior
     - La nueva calendario ya aparecerá en la lista por Realtime

8. **Bloque catch** (líneas 63-68):
   - **Verifica mounted** (línea 64):
     - Si `!mounted`, retorna sin mostrar error

   - **Parsea el mensaje de error** (línea 66):
     - Usa `ErrorMessageParser.parse(e, context)` para obtener mensaje legible

   - **Muestra diálogo de error** (línea 67):
     - Llama a `DialogHelpers.showErrorDialogWithIcon()`
     - Muestra el mensaje parseado

9. **Bloque finally** (líneas 68-74):
   - **Verifica mounted** (línea 69):
     - Solo actualiza estado si el widget está montado

   - **Restaura estado** (líneas 70-73):
     - Llama a `setState()`
     - Establece `_isLoading = false`
     - Rehabilita el formulario

**Validaciones implementadas**:
- Nombre requerido (no vacío)
- Nombre máximo 100 caracteres
- Descripción máximo 500 caracteres
- Descripción opcional (se envía null si está vacía)

### Widget build(BuildContext context, WidgetRef ref) (líneas 77-126)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `context`: BuildContext para acceso al contexto
- `ref`: WidgetRef para acceso a providers

**Propósito**: Construye la UI del formulario de creación de calendario

**Lógica detallada**:

1. **Obtiene localizaciones** (línea 79):
   - Usa `context.l10n` para acceder a traducciones

2. **Retorna AdaptivePageScaffold** (líneas 81-125) con:

   - **Título** (línea 82):
     - `l10n.createCalendar` ("Crear calendario")

   - **Botón leading** (línea 83):
     - `CupertinoButton` con texto "Cancelar"
     - padding: EdgeInsets.zero
     - onPressed: `context.pop()` para cerrar sin crear

   - **Botón de acción** (línea 84):
     - `CupertinoButton` con:
       - padding: EdgeInsets.zero
       - onPressed: `_createCalendar` (null si está loading)
       - child: `CupertinoActivityIndicator` si loading, sino texto "Crear"
     - Deshabilita el botón durante la creación
     - Muestra spinner mientras procesa

   - **Body: ListView** (líneas 85-124):
     - padding: 16px en todos los lados
     - children contiene:

       a) **Campo de nombre** (línea 88):
          - `CupertinoTextField` con:
            - controller: `_nameController`
            - placeholder: `l10n.calendarName`
            - maxLength: 100
            - enabled: `!_isLoading` (deshabilita durante creación)

       b) **Espaciador** (línea 89): 16px

       c) **Campo de descripción** (línea 91):
          - `CupertinoTextField` con:
            - controller: `_descriptionController`
            - placeholder: `l10n.calendarDescription`
            - maxLines: 3 (permite múltiples líneas)
            - maxLength: 500
            - enabled: `!_isLoading`

       d) **Espaciador** (línea 92): 24px

       e) **Switch de calendario público** (líneas 94-107):
          - `CupertinoListTile` con:
            - title: `l10n.publicCalendar`
            - subtitle: `l10n.othersCanSearchAndSubscribe` (explicación)
            - trailing: `CupertinoSwitch`:
              - value: `_isPublic`
              - onChanged: null si loading, sino callback que actualiza `_isPublic` con setState

       f) **Switch de eliminar eventos asociados** (líneas 109-122):
          - `CupertinoListTile` con:
            - title: `l10n.deleteAssociatedEvents`
            - subtitle: `l10n.deleteEventsWithCalendar` (explicación)
            - trailing: `CupertinoSwitch`:
              - value: `_deleteAssociatedEvents`
              - onChanged: null si loading, sino callback que actualiza `_deleteAssociatedEvents` con setState

**Estructura del formulario**: 2 campos de texto + 2 switches con títulos y subtítulos explicativos

## 5. DEPENDENCIAS

### Packages externos:
- `flutter/cupertino.dart`: Widgets de estilo iOS
- `flutter_riverpod`: Estado con Riverpod (ConsumerStatefulWidget, ConsumerState, WidgetRef)
- `go_router`: Navegación (context.pop())

### Imports internos - Helpers:
- `../ui/helpers/l10n/l10n_helpers.dart`: Extensión `context.l10n` para localizaciones
- `../ui/helpers/platform/dialog_helpers.dart`: `DialogHelpers.showErrorDialogWithIcon()` para diálogos de error

### Imports internos - Widgets:
- `../widgets/adaptive_scaffold.dart`: `AdaptivePageScaffold` para scaffold adaptativo

### Imports internos - State:
- `../core/state/app_state.dart`: Providers, incluye `calendarRepositoryProvider`

### Imports internos - Utils:
- `../utils/error_message_parser.dart`: `ErrorMessageParser.parse()` para convertir excepciones en mensajes legibles

### Providers utilizados:
- `calendarRepositoryProvider`: Repository de calendarios
  - Método usado: `createCalendar(name, description, isPublic)`

### Widgets de Flutter:
- `CupertinoTextField`: Campo de texto de estilo iOS
- `CupertinoButton`: Botón de estilo iOS
- `CupertinoActivityIndicator`: Indicador de carga de iOS
- `CupertinoSwitch`: Switch de estilo iOS
- `CupertinoListTile`: Elemento de lista con trailing
- `ListView`: Lista scrollable

### Localización:
Strings usados:
- `createCalendar`: "Crear calendario" (título)
- `cancel`: "Cancelar" (botón leading)
- `create`: "Crear" (botón de acción)
- `calendarName`: Placeholder para nombre
- `calendarDescription`: Placeholder para descripción
- `publicCalendar`: "Calendario público" (título switch)
- `othersCanSearchAndSubscribe`: Explicación de calendario público
- `deleteAssociatedEvents`: "Eliminar eventos asociados" (título switch)
- `deleteEventsWithCalendar`: Explicación de eliminar eventos
- `calendarNameRequired`: Error si nombre vacío
- `calendarNameTooLong`: Error si nombre > 100 caracteres
- `calendarDescriptionTooLong`: Error si descripción > 500 caracteres

## 6. FLUJO DE DATOS

### Al abrir la pantalla:
1. Usuario navega a CreateCalendarScreen
2. `initState()` no está definido, usa valores por defecto
3. Controllers se inicializan vacíos
4. `_isPublic = false` por defecto
5. `_deleteAssociatedEvents = false` por defecto
6. `_isLoading = false` por defecto
7. UI muestra formulario vacío y habilitado

### Al escribir en campos:
1. Usuario escribe en CupertinoTextField
2. TextEditingController actualiza automáticamente su texto
3. No hay setState, los controllers mantienen el valor

### Al cambiar switch de público:
1. Usuario toca el CupertinoSwitch de "Calendario público"
2. Callback `onChanged(value)` se ejecuta
3. Llama a `setState(() { _isPublic = value; })`
4. UI reconstruye mostrando nuevo estado del switch

### Al cambiar switch de eliminar eventos:
1. Usuario toca el CupertinoSwitch de "Eliminar eventos asociados"
2. Callback `onChanged(value)` se ejecuta
3. Llama a `setState(() { _deleteAssociatedEvents = value; })`
4. UI reconstruye mostrando nuevo estado del switch

### Al presionar "Crear":
1. Usuario presiona el botón "Crear"
2. Llama a `_createCalendar()`
3. Valida nombre:
   - Si vacío: muestra error y retorna
   - Si > 100 caracteres: muestra error y retorna
4. Valida descripción:
   - Si > 500 caracteres: muestra error y retorna
5. Establece `_isLoading = true`
6. UI reconstruye:
   - Botón muestra CupertinoActivityIndicator
   - Campos y switches se deshabilitan
7. Llama a `calendarRepositoryProvider.createCalendar()` con:
   - name: nombre trimmed
   - description: descripción trimmed (null si vacía)
   - isPublic: valor de `_isPublic`
8. Espera respuesta del backend:

   **Caso éxito**:
   - Backend crea el calendario
   - CalendarRepository escucha cambios por Realtime
   - Realtime notifica la nueva calendario
   - Lista de calendarios se actualiza automáticamente
   - Verifica `mounted`
   - Llama a `context.pop()` para cerrar la pantalla
   - Usuario vuelve a CalendarsScreen con la nueva calendario visible

   **Caso error**:
   - Backend retorna error (ej: nombre duplicado)
   - Catch captura la excepción
   - Verifica `mounted`
   - Parsea el error con `ErrorMessageParser.parse()`
   - Muestra diálogo con `DialogHelpers.showErrorDialogWithIcon()`
   - Usuario ve el mensaje de error

9. **Finally** (siempre se ejecuta):
   - Verifica `mounted`
   - Establece `_isLoading = false`
   - UI reconstruye:
     - Botón muestra texto "Crear" nuevamente
     - Campos y switches se habilitan

### Al presionar "Cancelar":
1. Usuario presiona botón "Cancelar" en leading
2. Llama a `context.pop()`
3. Cierra la pantalla sin crear calendario
4. Vuelve a la pantalla anterior

## 7. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Crear calendario nuevo**: Permite al usuario crear un calendario con nombre y descripción
2. **Validación de campos**: Valida longitud de nombre y descripción
3. **Configuración de visibilidad**: Permite elegir si el calendario es público o privado
4. **Configuración de eliminación**: Permite elegir si eliminar eventos al borrar el calendario (nota: este switch parece no usarse en la creación, solo se guarda el estado)
5. **Feedback de loading**: Muestra indicador mientras procesa la creación

### Campos del formulario:
1. **Nombre**:
   - Requerido
   - Máximo 100 caracteres
   - Validación: no vacío, longitud máxima
   - Se hace trim antes de enviar

2. **Descripción**:
   - Opcional
   - Máximo 500 caracteres
   - Multilinea (3 líneas visibles)
   - Validación: longitud máxima
   - Se hace trim antes de enviar
   - Se envía null si está vacía

3. **Calendario público**:
   - Switch booleano
   - Default: false (privado)
   - Permite que otros busquen y se suscriban al calendario

4. **Eliminar eventos asociados**:
   - Switch booleano
   - Default: false
   - Controla si los eventos se eliminan al borrar el calendario
   - **Nota**: Este valor se guarda pero parece no usarse en `createCalendar()`

### Estados visuales:
1. **Normal**: Formulario habilitado, botón "Crear" activo
2. **Loading**: Formulario deshabilitado, botón muestra spinner
3. **Error**: Diálogo modal con mensaje de error

### Interacciones disponibles:
1. **Escribir en campos**: Actualiza texto en controllers
2. **Cambiar switches**: Actualiza valores booleanos
3. **Presionar "Crear"**: Valida y crea el calendario
4. **Presionar "Cancelar"**: Cierra sin guardar

## 8. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 128
**Métodos**: 3 (1 dispose + 1 createCalendar + 1 build)
**Tipo**: ConsumerStatefulWidget con estado local

**Distribución aproximada**:
- Imports: ~8 líneas (6.3%)
- Declaración de clase ConsumerStatefulWidget: ~6 líneas (4.7%)
- Variables de estado y controllers: ~6 líneas (4.7%)
- dispose method: ~6 líneas (4.7%)
- _createCalendar method: ~44 líneas (34.4%)
- build method: ~50 líneas (39.1%)
- Resto (espacios, llaves): ~8 líneas (6.3%)

**Complejidad por método**:
- `dispose()`: Complejidad baja (solo limpia controllers)
- `_createCalendar()`: Complejidad media-alta (validaciones múltiples, try-catch-finally, mounted checks)
- `build()`: Complejidad media (formulario con múltiples campos y switches)

## 9. CARACTERÍSTICAS TÉCNICAS

### ConsumerStatefulWidget:
- Usa `ConsumerStatefulWidget` para acceso a Riverpod y estado local
- `WidgetRef ref` se usa en `_createCalendar()` para acceder al repository provider

### TextEditingControllers:
- 2 controllers: `_nameController` y `_descriptionController`
- Se disponen en `dispose()` para evitar memory leaks
- Permiten acceso directo al texto con `.text`
- Se hace `.trim()` al obtener los valores para eliminar espacios innecesarios

### Validaciones en cliente:
- **Nombre vacío**: Verifica antes de enviar al backend
- **Nombre muy largo**: Máximo 100 caracteres
- **Descripción muy larga**: Máximo 500 caracteres
- Muestra diálogos de error con `DialogHelpers.showErrorDialogWithIcon()`
- Previene llamadas innecesarias al backend

### Validaciones en servidor:
- El backend también valida (evidenciado por el try-catch)
- Errores del servidor se parsean con `ErrorMessageParser.parse()`
- Mensajes de error se muestran al usuario

### Estado de loading:
- `_isLoading` controla el estado de procesamiento
- Durante loading:
  - Botón "Crear" muestra `CupertinoActivityIndicator`
  - Botón "Crear" se deshabilita (`onPressed: null`)
  - Todos los campos se deshabilitan (`enabled: !_isLoading`)
  - Todos los switches se deshabilitan (`onChanged: null`)
- Previene múltiples envíos y ediciones durante procesamiento

### Bloque try-catch-finally:
- **try**: Intenta crear el calendario
- **catch**: Captura errores y muestra diálogo
- **finally**: Siempre restaura `_isLoading = false`
- Asegura que el formulario se rehabilite incluso si hay error

### Mounted checks:
- Verifica `mounted` 3 veces:
  1. Después de crear calendario exitosamente (antes de pop)
  2. En catch, antes de mostrar diálogo de error
  3. En finally, antes de actualizar `_isLoading`
- Previene errores de llamar setState en widget desmontado
- Previene navegación en widget desmontado

### Descripción opcional:
- Si la descripción está vacía, se envía `null` al backend
- Lógica: `description.isEmpty ? null : description`
- Permite diferenciar entre "sin descripción" y "descripción vacía"

### Realtime automático:
- Comentario en línea 58: "Realtime handles refresh automatically via CalendarRepository"
- No necesita llamar manualmente a refresh
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
- 3 tipos de errores:
  1. Validación de nombre vacío
  2. Validación de longitud de nombre
  3. Validación de longitud de descripción
  4. Errores del backend

### GoRouter navigation:
- Usa `context.pop()` para navegación
- Más simple que `Navigator.of(context).pop()`
- Integrado con GoRouter

### CupertinoListTile con switch:
- Usa `CupertinoListTile` para switches
- Estructura consistente: title + subtitle + trailing switch
- Subtítulos explican la funcionalidad
- Mejora la comprensión del usuario

### Deshabilitar switches durante loading:
- `onChanged: _isLoading ? null : (value) { ... }`
- Si loading, onChanged es null → switch deshabilitado
- Previene cambios durante procesamiento

### Campo multilinea:
- Campo de descripción con `maxLines: 3`
- Permite texto más largo
- Ideal para descripciones

### Límites de caracteres:
- Nombre: `maxLength: 100` en CupertinoTextField
- Descripción: `maxLength: 500` en CupertinoTextField
- TextField muestra contador de caracteres automáticamente
- Validación adicional en `_createCalendar()` por seguridad

### Switch _deleteAssociatedEvents no usado:
- El switch existe y guarda el estado
- **Pero** no se pasa como parámetro a `createCalendar()`
- Solo se pasan: name, description, isPublic
- Posible funcionalidad pendiente o código legacy
- El estado se mantiene pero no se usa en esta pantalla

### Botón adaptativo en leading y actions:
- Leading: `CupertinoButton` con texto "Cancelar"
- Actions: `CupertinoButton` con texto "Crear" o spinner
- `padding: EdgeInsets.zero` para alinear correctamente con el título
- Estilo consistente con navegación de iOS

### ListView como body:
- Usa `ListView` en lugar de `Column` para permitir scroll
- Si el teclado aparece, el formulario se puede scrollear
- Padding de 16px para márgenes consistentes
- Mejora UX en pantallas pequeñas

### Espaciadores:
- 16px entre campos de texto
- 24px entre descripción y switches
- Sin espaciador entre switches (consecutivos)
- Jerarquía visual clara
