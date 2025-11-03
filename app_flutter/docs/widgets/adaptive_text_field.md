# AdaptiveTextField - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/adaptive/adaptive_text_field.dart`
**Líneas**: 303
**Tipo**: Múltiples clases (StatefulWidget, State, Config, Enums, Interfaces)
**Propósito**: Sistema completo de campos de texto adaptativos con validación en tiempo real, múltiples variantes (standard, email, password, phone, multiline, limited), formatters y control de caracteres

## 2. CLASES CONTENIDAS

Este archivo contiene:
1. **AdaptiveTextField** (líneas 6-51): Widget principal StatefulWidget
2. **_AdaptiveTextFieldState** (líneas 53-238): Estado del widget con validación
3. **AdaptiveTextFieldConfig** (líneas 240-259): Clase de configuración
4. **TextFieldVariant** (línea 261): Enum con 6 variantes
5. **ValidationMode** (línea 263): Enum con 4 modos de validación
6. **ValidationState** (líneas 265-287): Clase de estado de validación
7. **TextFieldValidator** (líneas 289-292): Abstract class para validadores
8. **ITextFieldWidget** (líneas 294-302): Interface para text fields

---

## 3. CLASE: AdaptiveTextField

### Información
**Líneas**: 6-51
**Tipo**: StatefulWidget implements IAdaptiveWidget, ITextFieldWidget
**Propósito**: Widget de campo de texto con estado que maneja validación, formateo y múltiples variantes

### Implements
- `IAdaptiveWidget`: Interface base para widgets adaptativos
- `ITextFieldWidget`: Interface específica para campos de texto

### Propiedades (líneas 7-22)
Todas con `@override`:

- `config` (AdaptiveTextFieldConfig, required, línea 8): Configuración del campo
- `controller` (TextEditingController?, línea 10): Controller opcional del texto
- `placeholder` (String?, línea 12): Texto placeholder opcional
- `validators` (List<TextFieldValidator>, línea 14): Lista de validadores
- `validationState` (ValidationState, línea 16): Estado de validación actual
- `onValidationChanged` (void Function(ValidationState)?, línea 18): Callback de cambio de validación
- `onTextChanged` (void Function(String)?, línea 20): Callback de cambio de texto
- `enabled` (bool, línea 22): Si el campo está habilitado

### Constructor (línea 24)
```dart
const AdaptiveTextField({
  super.key,
  required this.config,
  this.controller,
  this.placeholder,
  this.validators = const [],
  this.validationState = const ValidationState(isValid: true, characterCount: 0),
  this.onValidationChanged,
  this.onTextChanged,
  this.enabled = true
})
```

**Valores por defecto**:
- `validators = const []`: Sin validadores por defecto
- `validationState = ValidationState(isValid: true, characterCount: 0)`: Válido inicialmente
- `enabled = true`: Habilitado por defecto

### Método createState (líneas 26-27)
**Tipo de retorno**: `State<AdaptiveTextField>`

Retorna: `_AdaptiveTextFieldState()`

### Getter theme (líneas 29-30)
**Tipo de retorno**: `PlatformTheme`
**Anotación**: `@override`

```dart
PlatformTheme get theme => PlatformTheme.adaptive(null);
```

**Nota**: Mismo patrón que otros widgets adaptativos

### Método build (líneas 32-35)
**Tipo de retorno**: `Widget`
**Anotación**: `@override`

**Propósito**: Método dummy, el build real está en el State

```dart
Widget build(BuildContext context) {
  return const SizedBox();
}
```

**Nota**: Retorna SizedBox vacío porque el StatefulWidget no construye directamente

### Método validate (líneas 37-50)
**Tipo de retorno**: `ValidationResult`
**Anotación**: `@override`

**Propósito**: Valida la configuración del widget

**Lógica**:

1. **Inicializa lista de issues** (línea 39):
   - `issues = <ValidationIssue>[]`

2. **Validación 1: maxLength no positivo** (líneas 41-43):
   - Condición: `config.maxLength != null && config.maxLength! <= 0`
   - Añade: ValidationIssue con:
     - message: 'Max length should be positive'
     - severity: ValidationSeverity.error

3. **Validación 2: Email sin validador** (líneas 45-47):
   - Condición: `config.variant == TextFieldVariant.email && validators.isEmpty`
   - Añade: ValidationIssue con:
     - message: 'Email fields should have email validation'
     - severity: ValidationSeverity.warning
     - suggestion: 'Add email validator'

4. **Retorna ValidationResult** (línea 49):
   - isValid: true si no hay errores
   - issues: lista completa
   - severity: más alta con reduce

**Issues detectados**:
- Error: maxLength <= 0
- Warning: Email field sin validadores

---

## 4. CLASE: _AdaptiveTextFieldState

### Información
**Líneas**: 53-238
**Tipo**: State<AdaptiveTextField>
**Propósito**: Maneja el estado del campo de texto, validación en tiempo real y construcción de UI

### Variables de estado (líneas 54-56)
- `_controller` (TextEditingController, late, línea 54): Controller del texto (propio o del widget)
- `_obscureText` (bool, línea 55): Si el texto está oculto (para passwords)
- `_currentValidationState` (ValidationState, línea 56): Estado actual de validación

**Inicialización de _currentValidationState**:
```dart
ValidationState(isValid: true, characterCount: 0)
```

### Método initState (líneas 58-64)
**Tipo de retorno**: `void`
**Anotación**: `@override`

**Propósito**: Inicializa el estado al montar el widget

**Lógica**:

1. **Llama super.initState()** (línea 60)

2. **Inicializa controller** (línea 61):
   - `_controller = widget.controller ?? TextEditingController()`
   - Usa controller del widget si existe, sino crea uno nuevo

3. **Inicializa _obscureText** (línea 62):
   - `_obscureText = widget.config.obscureText`
   - Toma valor de la configuración

4. **Añade listener** (línea 63):
   - `_controller.addListener(_onTextChanged)`
   - Escucha cambios en el texto

### Método dispose (líneas 66-74)
**Tipo de retorno**: `void`
**Anotación**: `@override`

**Propósito**: Limpia recursos al desmontar el widget

**Lógica**:

1. **Si controller es propio** (líneas 68-69):
   - Condición: `widget.controller == null`
   - Acción: `_controller.dispose()` (libera el controller)

2. **Si controller es externo** (líneas 70-72):
   - Condición: `widget.controller != null`
   - Acción: `_controller.removeListener(_onTextChanged)` (solo quita listener)

3. **Llama super.dispose()** (línea 73)

**Importante**: Solo dispone el controller si fue creado internamente

### Método _onTextChanged (líneas 76-80)
**Tipo de retorno**: `void`

**Propósito**: Callback cuando cambia el texto, dispara validación y notifica

**Lógica**:

1. **Obtiene texto** (línea 77):
   - `text = _controller.text`

2. **Valida texto** (línea 78):
   - `_validateText(text)`

3. **Notifica callback** (línea 79):
   - `widget.onTextChanged?.call(text)` (null-safe call)

**Orden**: Validación antes de notificación

### Método _validateText (líneas 82-111)
**Tipo de retorno**: `void`
**Parámetros**: `String text`

**Propósito**: Valida el texto contra maxLength y validadores, actualiza estado

**Lógica**:

1. **Verifica modo de validación** (línea 83):
   - Condición: `widget.config.validationMode == ValidationMode.none`
   - Si none: retorna sin validar

2. **Inicializa variables** (líneas 85-87):
   - `characterCount = text.length`
   - `isValid = true`
   - `errorMessage = null`

3. **Validación de longitud máxima** (líneas 89-92):
   - Condición: `widget.config.maxLength != null && characterCount > widget.config.maxLength!`
   - Si excede:
     - `isValid = false`
     - `errorMessage = 'Text exceeds maximum length of ${widget.config.maxLength}'`

4. **Validación con validadores personalizados** (líneas 94-101):
   - Loop: para cada validator en `widget.validators`:
     - Llama a `validator.validate(text)`
     - Si `!result.isValid`:
       - `isValid = false`
       - `errorMessage` = primer mensaje de issues o 'Validation failed'
       - `break` (para en el primer error)

5. **Crea nuevo estado** (línea 103):
   - `newState = ValidationState(isValid, errorMessage, characterCount)`

6. **Actualiza si cambió** (líneas 105-110):
   - Condición: `newState != _currentValidationState`
   - Compara con operador == sobrecargado
   - Si cambió:
     - Llama a `setState()` para actualizar `_currentValidationState`
     - Llama a `widget.onValidationChanged?.call(newState)`

**Orden de validación**: maxLength > validadores personalizados (se para en el primer error)

### Método build (líneas 113-131)
**Tipo de retorno**: `Widget`
**Anotación**: `@override`

**Propósito**: Construye el campo de texto según la variante

**Lógica**:

1. **Obtiene tema** (línea 115):
   - `theme = PlatformTheme.adaptive(context)`

2. **Switch por variante** (líneas 117-130):
   - `TextFieldVariant.standard`: `_buildStandardTextField(theme)`
   - `TextFieldVariant.limited`: `_buildLimitedTextField(theme)`
   - `TextFieldVariant.multiline`: `_buildMultilineTextField(theme)`
   - `TextFieldVariant.email`: `_buildEmailTextField(theme)`
   - `TextFieldVariant.phone`: `_buildPhoneTextField(theme)`
   - `TextFieldVariant.password`: `_buildPasswordTextField(theme)`

### Método _buildStandardTextField (líneas 133-144)
**Tipo de retorno**: `Widget`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye campo de texto estándar

**Retorna**: `TextFormField` con:
- controller: `_controller` (línea 135)
- enabled: `widget.enabled` (línea 136)
- decoration: `_buildInputDecoration(theme)` (línea 137)
- keyboardType: `widget.config.inputType` (línea 138)
- obscureText: `_obscureText` (línea 139)
- autocorrect: `widget.config.autocorrect` (línea 140)
- enableSuggestions: `widget.config.enableSuggestions` (línea 141)
- inputFormatters: `_buildInputFormatters()` (línea 142)

### Método _buildLimitedTextField (líneas 146-154)
**Tipo de retorno**: `Widget`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye campo con límite de caracteres y contador

**Retorna**: `Column` con:
- crossAxisAlignment: CrossAxisAlignment.start (línea 148)
- children (líneas 149-152):
  1. **TextFormField** (línea 150):
     - controller, enabled, decoration, keyboardType
     - maxLength: `widget.config.maxLength`
     - inputFormatters: `_buildInputFormatters()`
  2. **Contador condicional** (línea 151):
     - `if (widget.config.showCounter) _buildCharacterCounter(theme)`

### Método _buildMultilineTextField (líneas 156-158)
**Tipo de retorno**: `Widget`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye campo multilínea

**Retorna**: `TextFormField` con:
- controller, enabled, decoration
- keyboardType: `TextInputType.multiline`
- maxLines: `null` (sin límite)
- minLines: `3` (mínimo 3 líneas visibles)
- inputFormatters: `_buildInputFormatters()`

**Características**: Expandible, mínimo 3 líneas

### Método _buildEmailTextField (líneas 160-162)
**Tipo de retorno**: `Widget`
**Parámetros**: `PlatformTheme theme`

**Retorna**: `TextFormField` con:
- controller, enabled, decoration
- keyboardType: `TextInputType.emailAddress`
- autocorrect: `false` (sin autocorrección para emails)
- enableSuggestions: `false` (sin sugerencias)
- inputFormatters: `_buildInputFormatters()`

**Características**: Teclado de email, sin autocorrect

### Método _buildPhoneTextField (líneas 164-166)
**Tipo de retorno**: `Widget`
**Parámetros**: `PlatformTheme theme`

**Retorna**: `TextFormField` con:
- controller, enabled, decoration
- keyboardType: `TextInputType.phone`
- inputFormatters: `_buildInputFormatters()` (incluye digitsOnly)

**Características**: Teclado numérico de teléfono

### Método _buildPasswordTextField (líneas 168-187)
**Tipo de retorno**: `Widget`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye campo de contraseña con botón para mostrar/ocultar

**Retorna**: `TextFormField` con:
- controller, enabled (líneas 170-171)
- **decoration** (líneas 172-181): `_buildInputDecoration(theme).copyWith()` con:
  - suffixIcon: `IconButton` (líneas 173-180):
    - icon: `_obscureText ? Icons.visibility : Icons.visibility_off`
    - onPressed: toggle de `_obscureText` con setState
- obscureText: `_obscureText` (línea 182)
- autocorrect: `false` (línea 183)
- enableSuggestions: `false` (línea 184)
- inputFormatters: `_buildInputFormatters()` (línea 185)

**Características**: Botón para mostrar/ocultar contraseña, sin autocorrect

### Método _buildInputDecoration (líneas 189-209)
**Tipo de retorno**: `InputDecoration`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye la decoración del input con bordes y colores del tema

**Retorna**: `InputDecoration` con:
- **hintText** (línea 191): `widget.placeholder`
- **errorText** (línea 192): `_currentValidationState.errorMessage`
- **border** (línea 193): `OutlineInputBorder` con borderRadius del tema
- **enabledBorder** (líneas 194-197): OutlineInputBorder con:
  - borderRadius: `theme.defaultBorderRadius`
  - borderSide: `theme.dividerColor` (color del divisor)
- **focusedBorder** (líneas 198-201): OutlineInputBorder con:
  - borderRadius: `theme.defaultBorderRadius`
  - borderSide: `theme.primaryColor`, width 2 (más grueso cuando enfocado)
- **errorBorder** (líneas 202-205): OutlineInputBorder con:
  - borderRadius: `theme.defaultBorderRadius`
  - borderSide: `theme.errorColor`
- **filled** (línea 206): `true` (fondo de color)
- **fillColor** (línea 207): `theme.surfaceColor` (color de superficie)

**Estados visuales**:
- Normal: borde gris (dividerColor)
- Enfocado: borde azul grueso (primaryColor, width 2)
- Error: borde rojo (errorColor)

### Método _buildCharacterCounter (líneas 211-216)
**Tipo de retorno**: `Widget`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye contador de caracteres

**Retorna**: `Padding` con:
- padding: `EdgeInsets.only(top: 4.0)` (espacio arriba)
- child: `Text` con:
  - text: `'${_currentValidationState.characterCount}${widget.config.maxLength != null ? '/${widget.config.maxLength}' : ''}'`
    - Formato: "10/100" si hay maxLength, "10" si no hay
  - style: `theme.textStyle` modificado con:
    - fontSize: 12 (pequeño)
    - color: `theme.secondaryColor`

**Formato dinámico**: Muestra "X/Y" o solo "X" según configuración

### Método _buildInputFormatters (líneas 218-237)
**Tipo de retorno**: `List<TextInputFormatter>`

**Propósito**: Construye lista de formatters según variante y configuración

**Lógica**:

1. **Inicializa lista** (línea 219):
   - `formatters = <TextInputFormatter>[]`

2. **Añade limitador de longitud** (líneas 221-223):
   - Condición: `widget.config.maxLength != null`
   - Añade: `LengthLimitingTextInputFormatter(widget.config.maxLength)`

3. **Switch por variante** (líneas 225-234):

   a) **TextFieldVariant.phone** (líneas 226-228):
      - Añade: `FilteringTextInputFormatter.digitsOnly`
      - Solo permite dígitos

   b) **TextFieldVariant.email** (líneas 229-231):
      - Añade: `FilteringTextInputFormatter.deny(RegExp(r'\s'))`
      - Niega espacios en blanco

   c) **default** (líneas 232-233):
      - No añade formatters adicionales

4. **Retorna formatters** (línea 236)

**Formatters aplicados**:
- Todos: LengthLimitingTextInputFormatter (si maxLength existe)
- Phone: digitsOnly
- Email: sin espacios

---

## 5. CLASE: AdaptiveTextFieldConfig

### Información
**Líneas**: 240-259
**Tipo**: Clase de configuración (inmutable)
**Propósito**: Almacena configuración del campo de texto

### Propiedades (líneas 241-248)
- `variant` (TextFieldVariant, required): Variante del campo
- `validationMode` (ValidationMode, required): Modo de validación
- `showCounter` (bool, required): Si muestra contador de caracteres
- `maxLength` (int?): Longitud máxima opcional
- `inputType` (TextInputType, required): Tipo de teclado
- `obscureText` (bool, required): Si oculta el texto
- `autocorrect` (bool, required): Si autocorrige
- `enableSuggestions` (bool, required): Si muestra sugerencias

### Constructor principal (línea 250)
```dart
const AdaptiveTextFieldConfig({
  required this.variant,
  required this.validationMode,
  required this.showCounter,
  this.maxLength,
  required this.inputType,
  required this.obscureText,
  required this.autocorrect,
  required this.enableSuggestions
})
```

### Factory constructors (líneas 252-258)

1. **AdaptiveTextFieldConfig.standard()** (línea 252):
   ```dart
   const AdaptiveTextFieldConfig(
     variant: TextFieldVariant.standard,
     validationMode: ValidationMode.onChanged,
     showCounter: false,
     inputType: TextInputType.text,
     obscureText: false,
     autocorrect: true,
     enableSuggestions: true
   )
   ```

2. **AdaptiveTextFieldConfig.limited(int maxLength)** (línea 254):
   ```dart
   AdaptiveTextFieldConfig(
     variant: TextFieldVariant.limited,
     validationMode: ValidationMode.onChanged,
     showCounter: true,
     maxLength: maxLength,
     inputType: TextInputType.text,
     obscureText: false,
     autocorrect: true,
     enableSuggestions: true
   )
   ```
   - Requiere maxLength como parámetro
   - showCounter: true por defecto

3. **AdaptiveTextFieldConfig.email()** (línea 256):
   ```dart
   const AdaptiveTextFieldConfig(
     variant: TextFieldVariant.email,
     validationMode: ValidationMode.onSubmitted,
     showCounter: false,
     inputType: TextInputType.emailAddress,
     obscureText: false,
     autocorrect: false,
     enableSuggestions: false
   )
   ```
   - validationMode: onSubmitted (valida al enviar)
   - autocorrect y enableSuggestions: false

4. **AdaptiveTextFieldConfig.password()** (línea 258):
   ```dart
   const AdaptiveTextFieldConfig(
     variant: TextFieldVariant.password,
     validationMode: ValidationMode.onChanged,
     showCounter: false,
     inputType: TextInputType.visiblePassword,
     obscureText: true,
     autocorrect: false,
     enableSuggestions: false
   )
   ```
   - obscureText: true
   - autocorrect y enableSuggestions: false

---

## 6. ENUM: TextFieldVariant

**Línea**: 261
**Valores**:
```dart
enum TextFieldVariant { standard, limited, multiline, email, phone, password }
```

1. **standard**: Campo estándar de una línea
2. **limited**: Campo con límite de caracteres y contador
3. **multiline**: Campo multilínea expandible
4. **email**: Campo para emails
5. **phone**: Campo para teléfonos
6. **password**: Campo de contraseña con botón mostrar/ocultar

---

## 7. ENUM: ValidationMode

**Línea**: 263
**Valores**:
```dart
enum ValidationMode { none, onChanged, onSubmitted, onFocusLost }
```

1. **none**: Sin validación automática
2. **onChanged**: Valida en cada cambio de texto
3. **onSubmitted**: Valida al enviar el formulario
4. **onFocusLost**: Valida al perder el foco

**Nota**: Actualmente solo `none` tiene efecto, los demás no están implementados

---

## 8. CLASE: ValidationState

**Líneas**: 265-287
**Tipo**: Clase de datos (inmutable)
**Propósito**: Representa el estado de validación del campo

### Propiedades (líneas 266-269)
- `isValid` (bool, required): Si el texto es válido
- `errorMessage` (String?): Mensaje de error opcional
- `characterCount` (int, required): Cantidad de caracteres
- `isValidating` (bool): Si está validando (default false)

### Constructor principal (línea 271)
```dart
const ValidationState({
  required this.isValid,
  this.errorMessage,
  required this.characterCount,
  this.isValidating = false
})
```

### Factory constructors (líneas 273-277)

1. **ValidationState.valid(int characterCount)** (línea 273):
   ```dart
   ValidationState(isValid: true, characterCount: characterCount)
   ```

2. **ValidationState.invalid(String errorMessage, int characterCount)** (línea 275):
   ```dart
   ValidationState(isValid: false, errorMessage: errorMessage, characterCount: characterCount)
   ```

3. **ValidationState.validating(int characterCount)** (línea 277):
   ```dart
   ValidationState(isValid: true, characterCount: characterCount, isValidating: true)
   ```

### Operador == (líneas 279-283)
**Tipo de retorno**: `bool`
**Anotación**: `@override`

**Propósito**: Compara dos ValidationState por valor

**Lógica**:
```dart
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is ValidationState &&
         other.isValid == isValid &&
         other.errorMessage == errorMessage &&
         other.characterCount == characterCount &&
         other.isValidating == isValidating;
}
```

**Verifica**:
1. Identidad (mismo objeto)
2. Tipo (es ValidationState)
3. Igualdad de todos los campos

### Getter hashCode (líneas 285-286)
**Tipo de retorno**: `int`
**Anotación**: `@override`

```dart
int get hashCode => Object.hash(isValid, errorMessage, characterCount, isValidating);
```

**Uso**: Necesario al sobrescribir ==, usa Object.hash de Dart 2.14+

---

## 9. INTERFACE: TextFieldValidator

**Líneas**: 289-292
**Tipo**: Abstract class
**Propósito**: Interface para validadores personalizados

### Getters abstractos:
- `String get name` (línea 290): Nombre del validador

### Métodos abstractos:
- `ValidationResult validate(String text)` (línea 291): Valida el texto

**Uso**: Implementar esta clase para crear validadores custom

---

## 10. INTERFACE: ITextFieldWidget

**Líneas**: 294-302
**Tipo**: Abstract class extends IAdaptiveWidget
**Propósito**: Interface para widgets de campo de texto

### Getters abstractos adicionales:
- `AdaptiveTextFieldConfig get config` (línea 295): Configuración
- `TextEditingController? get controller` (línea 296): Controller opcional
- `String? get placeholder` (línea 297): Placeholder
- `List<TextFieldValidator> get validators` (línea 298): Validadores
- `ValidationState get validationState` (línea 299): Estado de validación
- `void Function(ValidationState)? get onValidationChanged` (línea 300): Callback validación
- `void Function(String)? get onTextChanged` (línea 301): Callback texto

**Hereda**: theme, enabled, build(), validate() de IAdaptiveWidget

---

## 11. DEPENDENCIAS

### Packages externos:
- `flutter/material.dart`: Widgets de Material Design
- `flutter/services.dart`: TextInputFormatter, FilteringTextInputFormatter, LengthLimitingTextInputFormatter

### Imports internos:
- `platform_theme.dart`: PlatformTheme
- `adaptive_card.dart`: IAdaptiveWidget, ValidationResult, ValidationIssue, ValidationSeverity

### Widgets de Flutter:
- TextFormField: Campo de texto con validación
- IconButton, Icon: Para botón de mostrar/ocultar contraseña
- Column, Padding: Layouts
- InputDecoration, OutlineInputBorder: Decoración de inputs

### Tipos:
- TextEditingController: Controller del texto
- TextInputType: Tipo de teclado
- TextInputFormatter: Formateador de entrada

---

## 12. CARACTERÍSTICAS TÉCNICAS

### Controller propio vs externo:
- Si no se pasa controller: crea uno interno y lo dispone
- Si se pasa controller: solo quita el listener, no lo dispone
- Previene dispose de controllers externos

### Validación en tiempo real:
- Listener en controller dispara validación
- _validateText se ejecuta en cada cambio
- Solo valida si validationMode != none
- **Nota**: onChanged, onSubmitted, onFocusLost no están implementados

### Orden de validación:
1. maxLength
2. Validadores personalizados (para en el primer error)

### Comparación de estados:
- Sobrecarga de == compara todos los campos
- Solo actualiza UI si el estado cambió
- Previene rebuilds innecesarios

### Late initialization:
- `late TextEditingController _controller`
- Se inicializa en initState
- Permite usar en todo el State

### Input formatters dinámicos:
- LengthLimitingTextInputFormatter si maxLength existe
- FilteringTextInputFormatter.digitsOnly para phone
- FilteringTextInputFormatter.deny(RegExp(r'\s')) para email
- Lista vacía para otras variantes

### Botón de mostrar/ocultar contraseña:
- IconButton en suffixIcon
- Toggle de _obscureText con setState
- Icons.visibility vs Icons.visibility_off
- Solo en variante password

### copyWith en decoration:
- `_buildInputDecoration(theme).copyWith(suffixIcon: ...)`
- Reutiliza decoración base y añade icono
- Evita duplicar código

### Multiline expandible:
- maxLines: null (sin límite)
- minLines: 3 (mínimo visible)
- Se expande automáticamente con el contenido

### Bordes diferenciados:
- enabledBorder: dividerColor, width normal
- focusedBorder: primaryColor, width 2
- errorBorder: errorColor
- Feedback visual claro del estado

### Filled con color:
- filled: true
- fillColor: surfaceColor del tema
- Fondo de color para mejor contraste

### Contador de caracteres:
- Solo en variante limited con showCounter
- Formato dinámico: "X/Y" o "X"
- Pequeño (fontSize 12) y secundario

### Autocorrect y suggestions configurables:
- Por defecto true en standard y limited
- False en email y password
- Configurables por variante

### Keyboard types específicos:
- TextInputType.text: standard
- TextInputType.emailAddress: email
- TextInputType.phone: phone
- TextInputType.multiline: multiline
- TextInputType.visiblePassword: password

### Validación de configuración:
- Error si maxLength <= 0
- Warning si email sin validators
- Valida antes de usar el widget

### ValidationMode enum preparado:
- Define 4 modos
- Solo none está implementado
- onChanged siempre valida (hardcoded)
- onSubmitted y onFocusLost no se usan

### Callback onTextChanged:
- Se llama después de validar
- Permite reaccionar a cambios de texto
- Null-safe call

### Callback onValidationChanged:
- Solo se llama si el estado cambió
- Recibe ValidationState completo
- Permite sincronizar validación externa

### hashCode con Object.hash:
- Usa Object.hash de Dart 2.14+
- Combina todos los campos
- Necesario al sobrescribir ==

### identical check:
- Primero verifica identidad (mismo objeto)
- Optimización común
- Retorna true inmediatamente si identical

### TextFieldValidator abstracto:
- Define contrato para validadores
- name para identificar validator
- validate retorna ValidationResult
- Permite validadores reutilizables

### StatefulWidget con build dummy:
- build() en widget retorna SizedBox vacío
- Build real está en State
- Patrón estándar de StatefulWidget
