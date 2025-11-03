# Text Field Config - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/adaptive/configs/text_field_config.dart`
**Líneas**: 125
**Tipo**: Extension + Builder + Constantes
**Propósito**: Proporciona métodos de conveniencia, builder pattern y configuraciones predefinidas para crear AdaptiveTextFieldConfig de forma fácil y consistente, específicas para diferentes tipos de entrada de texto

## 2. CLASES CONTENIDAS

Este archivo contiene:
1. **AdaptiveTextFieldConfigExtended** (líneas 4-29): Extension con factory methods
2. **TextFieldConfigBuilder** (líneas 31-84): Clase builder pattern
3. **TextFieldConfigs** (líneas 86-124): Clase con 19 configuraciones constantes predefinidas

---

## 3. EXTENSION: AdaptiveTextFieldConfigExtended

### Información
**Líneas**: 4-29
**Tipo**: Extension on AdaptiveTextFieldConfig
**Propósito**: Añade métodos estáticos factory para crear configuraciones comunes

**Declaración**:
```dart
extension AdaptiveTextFieldConfigExtended on AdaptiveTextFieldConfig { ... }
```

### Métodos estáticos (líneas 5-28)

Todos los métodos son estáticos y retornan `AdaptiveTextFieldConfig`:

#### 1. name() (línea 5)
```dart
static AdaptiveTextFieldConfig name() => const AdaptiveTextFieldConfig(
  variant: TextFieldVariant.standard,
  validationMode: ValidationMode.onChanged,
  showCounter: false,
  inputType: TextInputType.name,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Campos de nombre
**Características**: TextInputType.name (teclado optimizado para nombres), autocorrect y suggestions activos

#### 2. search() (línea 7)
```dart
static AdaptiveTextFieldConfig search() => const AdaptiveTextFieldConfig(
  variant: TextFieldVariant.standard,
  validationMode: ValidationMode.none,
  showCounter: false,
  inputType: TextInputType.text,
  obscureText: false,
  autocorrect: false,
  enableSuggestions: true
)
```
**Uso**: Campos de búsqueda
**Características**: Sin validación (none), sin autocorrect, con suggestions

#### 3. url() (línea 9)
```dart
static AdaptiveTextFieldConfig url() => const AdaptiveTextFieldConfig(
  variant: TextFieldVariant.standard,
  validationMode: ValidationMode.onSubmitted,
  showCounter: false,
  inputType: TextInputType.url,
  obscureText: false,
  autocorrect: false,
  enableSuggestions: false
)
```
**Uso**: Campos de URL
**Características**: TextInputType.url (teclado con .com, etc.), validación onSubmitted, sin autocorrect ni suggestions

#### 4. number() (línea 11)
```dart
static AdaptiveTextFieldConfig number() => const AdaptiveTextFieldConfig(
  variant: TextFieldVariant.standard,
  validationMode: ValidationMode.onChanged,
  showCounter: false,
  inputType: TextInputType.number,
  obscureText: false,
  autocorrect: false,
  enableSuggestions: false
)
```
**Uso**: Campos numéricos
**Características**: TextInputType.number (teclado numérico), sin autocorrect ni suggestions

#### 5. description() (línea 13)
```dart
static AdaptiveTextFieldConfig description() => const AdaptiveTextFieldConfig(
  variant: TextFieldVariant.multiline,
  validationMode: ValidationMode.none,
  showCounter: true,
  maxLength: 500,
  inputType: TextInputType.multiline,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Campos de descripción
**Características**: Multiline, 500 caracteres máximo, contador visible, autocorrect activo

#### 6. comment() (línea 15)
```dart
static AdaptiveTextFieldConfig comment() => const AdaptiveTextFieldConfig(
  variant: TextFieldVariant.multiline,
  validationMode: ValidationMode.none,
  showCounter: true,
  maxLength: 1000,
  inputType: TextInputType.multiline,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Campos de comentario
**Características**: Multiline, 1000 caracteres máximo (más que description), contador visible

#### 7. limitedText(int maxLength) (línea 17)
```dart
static AdaptiveTextFieldConfig limitedText(int maxLength) => AdaptiveTextFieldConfig(
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
**Uso**: Campos de texto con límite personalizado
**Parámetro requerido**: maxLength (especifica el límite)
**Características**: Variante limited, contador visible, valida en cada cambio
**Nota**: No es const (porque acepta parámetro)

#### 8. custom() (líneas 19-28)
```dart
static AdaptiveTextFieldConfig custom({
  TextFieldVariant variant = TextFieldVariant.standard,
  ValidationMode validationMode = ValidationMode.onChanged,
  bool showCounter = false,
  int? maxLength,
  TextInputType inputType = TextInputType.text,
  bool obscureText = false,
  bool autocorrect = true,
  bool enableSuggestions = true,
}) => AdaptiveTextFieldConfig(
  variant: variant,
  validationMode: validationMode,
  showCounter: showCounter,
  maxLength: maxLength,
  inputType: inputType,
  obscureText: obscureText,
  autocorrect: autocorrect,
  enableSuggestions: enableSuggestions
)
```
**Uso**: Crear configuración personalizada con valores por defecto razonables
**Valores por defecto**:
- variant: TextFieldVariant.standard
- validationMode: ValidationMode.onChanged
- showCounter: false
- inputType: TextInputType.text
- obscureText: false
- autocorrect: true
- enableSuggestions: true

### Patrones de configuración

**Por tipo de contenido**:
- name: nombres con autocorrect
- url: URLs sin autocorrect, teclado especial
- number: números, teclado numérico
- search: búsquedas sin autocorrect
- description/comment: multilínea con límites diferentes

**Autocorrect patterns**:
- **Con autocorrect**: name, description, comment, limitedText (contenido natural)
- **Sin autocorrect**: url, number, search (datos técnicos/precisos)

**Validation patterns**:
- **onChanged**: name, number, limitedText (feedback inmediato)
- **onSubmitted**: url (valida al enviar)
- **none**: search, description, comment (sin validación automática)

---

## 4. CLASE: TextFieldConfigBuilder

### Información
**Líneas**: 31-84
**Tipo**: Builder pattern class
**Propósito**: Construir AdaptiveTextFieldConfig usando fluent API (method chaining)

### Variables privadas (líneas 32-39)
- `_variant` (TextFieldVariant, línea 32): Default `TextFieldVariant.standard`
- `_validationMode` (ValidationMode, línea 33): Default `ValidationMode.onChanged`
- `_showCounter` (bool, línea 34): Default `false`
- `_maxLength` (int?, línea 35): Default `null`
- `_inputType` (TextInputType, línea 36): Default `TextInputType.text`
- `_obscureText` (bool, línea 37): Default `false`
- `_autocorrect` (bool, línea 38): Default `true`
- `_enableSuggestions` (bool, línea 39): Default `true`

**Valores por defecto**: Standard variant, validación onChanged, texto visible, con autocorrect y suggestions

### Métodos builder (líneas 41-79)

Todos los métodos retornan `this` para permitir chaining:

#### variant(TextFieldVariant variant) (líneas 41-44)
```dart
TextFieldConfigBuilder variant(TextFieldVariant variant) {
  _variant = variant;
  return this;
}
```

#### validationMode(ValidationMode mode) (líneas 46-49)
```dart
TextFieldConfigBuilder validationMode(ValidationMode mode) {
  _validationMode = mode;
  return this;
}
```

#### showCounter([bool show = true]) (líneas 51-54)
```dart
TextFieldConfigBuilder showCounter([bool show = true]) {
  _showCounter = show;
  return this;
}
```
**Parámetro opcional**: Default true, permite `.showCounter()` o `.showCounter(false)`

#### maxLength(int length) (líneas 56-59)
```dart
TextFieldConfigBuilder maxLength(int length) {
  _maxLength = length;
  return this;
}
```

#### inputType(TextInputType type) (líneas 61-64)
```dart
TextFieldConfigBuilder inputType(TextInputType type) {
  _inputType = type;
  return this;
}
```

#### obscureText([bool obscure = true]) (líneas 66-69)
```dart
TextFieldConfigBuilder obscureText([bool obscure = true]) {
  _obscureText = obscure;
  return this;
}
```
**Parámetro opcional**: Default true para passwords

#### autocorrect([bool correct = true]) (líneas 71-74)
```dart
TextFieldConfigBuilder autocorrect([bool correct = true]) {
  _autocorrect = correct;
  return this;
}
```
**Parámetro opcional**: Default true

#### enableSuggestions([bool enable = true]) (líneas 76-79)
```dart
TextFieldConfigBuilder enableSuggestions([bool enable = true]) {
  _enableSuggestions = enable;
  return this;
}
```
**Parámetro opcional**: Default true

### Método build() (líneas 81-83)
```dart
AdaptiveTextFieldConfig build() {
  return AdaptiveTextFieldConfig(
    variant: _variant,
    validationMode: _validationMode,
    showCounter: _showCounter,
    maxLength: _maxLength,
    inputType: _inputType,
    obscureText: _obscureText,
    autocorrect: _autocorrect,
    enableSuggestions: _enableSuggestions
  );
}
```

### Uso del builder

```dart
// Ejemplo de uso con chaining
final config = TextFieldConfigBuilder()
    .variant(TextFieldVariant.limited)
    .maxLength(100)
    .showCounter()
    .inputType(TextInputType.text)
    .build();

// Password field con builder
final passwordConfig = TextFieldConfigBuilder()
    .variant(TextFieldVariant.password)
    .obscureText()
    .autocorrect(false)
    .enableSuggestions(false)
    .build();
```

---

## 5. CLASE: TextFieldConfigs

### Información
**Líneas**: 86-124
**Tipo**: Clase con constantes estáticas
**Propósito**: Biblioteca de configuraciones predefinidas para casos de uso específicos de la app

**Total de configuraciones**: 19

### Configuraciones de autenticación (líneas 87-91)

#### username (línea 87)
```dart
static const username = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.standard,
  validationMode: ValidationMode.onChanged,
  showCounter: false,
  inputType: TextInputType.text,
  obscureText: false,
  autocorrect: false,
  enableSuggestions: false
)
```
**Uso**: Campo de nombre de usuario
**Características**: Sin autocorrect ni suggestions (nombres de usuario precisos)

#### passwordField (línea 89)
```dart
static const passwordField = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.password,
  validationMode: ValidationMode.onChanged,
  showCounter: false,
  inputType: TextInputType.visiblePassword,
  obscureText: true,
  autocorrect: false,
  enableSuggestions: false
)
```
**Uso**: Campo de contraseña
**Características**: Variante password (con botón show/hide), obscureText true

#### confirmPassword (línea 91)
```dart
static const confirmPassword = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.password,
  validationMode: ValidationMode.onChanged,
  showCounter: false,
  inputType: TextInputType.visiblePassword,
  obscureText: true,
  autocorrect: false,
  enableSuggestions: false
)
```
**Uso**: Campo de confirmar contraseña
**Características**: Idéntico a passwordField

### Configuraciones de nombre (líneas 93-95)

#### firstName (línea 93)
```dart
static const firstName = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.standard,
  validationMode: ValidationMode.onChanged,
  showCounter: false,
  inputType: TextInputType.name,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Campo de nombre
**Características**: TextInputType.name, con autocorrect y suggestions

#### lastName (línea 95)
```dart
static const lastName = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.standard,
  validationMode: ValidationMode.onChanged,
  showCounter: false,
  inputType: TextInputType.name,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Campo de apellido
**Características**: Idéntico a firstName

### Configuraciones de contacto (línea 97)

#### phoneNumber (línea 97)
```dart
static const phoneNumber = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.phone,
  validationMode: ValidationMode.onChanged,
  showCounter: false,
  inputType: TextInputType.phone,
  obscureText: false,
  autocorrect: false,
  enableSuggestions: false
)
```
**Uso**: Campo de teléfono
**Características**: Variante phone (solo dígitos), TextInputType.phone (teclado telefónico)

### Configuraciones de eventos (líneas 99-103)

#### eventTitle (línea 99)
```dart
static const eventTitle = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.limited,
  validationMode: ValidationMode.onChanged,
  showCounter: true,
  maxLength: 100,
  inputType: TextInputType.text,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Título de evento
**Características**: Limited con 100 caracteres, contador visible

#### eventDescription (línea 101)
```dart
static const eventDescription = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.multiline,
  validationMode: ValidationMode.none,
  showCounter: true,
  maxLength: 500,
  inputType: TextInputType.multiline,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Descripción de evento
**Características**: Multiline, 500 caracteres, contador visible

#### eventLocation (línea 103)
```dart
static const eventLocation = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.standard,
  validationMode: ValidationMode.none,
  showCounter: false,
  inputType: TextInputType.streetAddress,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Ubicación de evento
**Características**: TextInputType.streetAddress (teclado optimizado para direcciones)

### Configuraciones de búsqueda (líneas 105-107)

#### searchEvents (línea 105)
```dart
static const searchEvents = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.standard,
  validationMode: ValidationMode.none,
  showCounter: false,
  inputType: TextInputType.text,
  obscureText: false,
  autocorrect: false,
  enableSuggestions: true
)
```
**Uso**: Búsqueda de eventos
**Características**: Sin validación, sin autocorrect, con suggestions

#### searchContacts (línea 107)
```dart
static const searchContacts = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.standard,
  validationMode: ValidationMode.none,
  showCounter: false,
  inputType: TextInputType.name,
  obscureText: false,
  autocorrect: false,
  enableSuggestions: true
)
```
**Uso**: Búsqueda de contactos
**Características**: TextInputType.name (optimizado para nombres), sin autocorrect

### Configuraciones de mensajes (líneas 109-111)

#### messageText (línea 109)
```dart
static const messageText = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.multiline,
  validationMode: ValidationMode.none,
  showCounter: true,
  maxLength: 1000,
  inputType: TextInputType.multiline,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Texto de mensaje
**Características**: Multiline, 1000 caracteres (más largo), contador visible

#### invitationMessage (línea 111)
```dart
static const invitationMessage = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.multiline,
  validationMode: ValidationMode.none,
  showCounter: true,
  maxLength: 300,
  inputType: TextInputType.multiline,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Mensaje de invitación
**Características**: Multiline, 300 caracteres (más corto que messageText)

### Configuraciones de perfil (líneas 113-115)

#### displayName (línea 113)
```dart
static const displayName = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.limited,
  validationMode: ValidationMode.onChanged,
  showCounter: true,
  maxLength: 50,
  inputType: TextInputType.name,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Nombre para mostrar en perfil
**Características**: Limited 50 caracteres, contador visible

#### bioText (línea 115)
```dart
static const bioText = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.multiline,
  validationMode: ValidationMode.none,
  showCounter: true,
  maxLength: 200,
  inputType: TextInputType.multiline,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Biografía de usuario
**Características**: Multiline, 200 caracteres, contador visible

### Configuraciones de grupos (líneas 117-119)

#### groupName (línea 117)
```dart
static const groupName = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.limited,
  validationMode: ValidationMode.onChanged,
  showCounter: true,
  maxLength: 80,
  inputType: TextInputType.text,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Nombre de grupo
**Características**: Limited 80 caracteres, contador visible

#### groupDescription (línea 119)
```dart
static const groupDescription = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.multiline,
  validationMode: ValidationMode.none,
  showCounter: true,
  maxLength: 300,
  inputType: TextInputType.multiline,
  obscureText: false,
  autocorrect: true,
  enableSuggestions: true
)
```
**Uso**: Descripción de grupo
**Características**: Multiline, 300 caracteres

### Configuraciones numéricas (líneas 121-123)

#### ageField (línea 121)
```dart
static const ageField = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.standard,
  validationMode: ValidationMode.onChanged,
  showCounter: false,
  inputType: TextInputType.number,
  obscureText: false,
  autocorrect: false,
  enableSuggestions: false
)
```
**Uso**: Campo de edad
**Características**: TextInputType.number, sin autocorrect ni suggestions

#### capacityField (línea 123)
```dart
static const capacityField = AdaptiveTextFieldConfig(
  variant: TextFieldVariant.standard,
  validationMode: ValidationMode.onChanged,
  showCounter: false,
  inputType: TextInputType.number,
  obscureText: false,
  autocorrect: false,
  enableSuggestions: false
)
```
**Uso**: Campo de capacidad
**Características**: Idéntico a ageField

### Comparación de maxLength

Ordenadas de menor a mayor:
1. **displayName**: 50
2. **eventTitle**: 100
3. **bioText**: 200
4. **invitationMessage, groupDescription**: 300
5. **eventDescription**: 500
6. **messageText**: 1000

### Patrones de inputType

**Por tipo**:
- **TextInputType.text**: username, eventTitle, searchEvents, groupName (texto genérico)
- **TextInputType.name**: firstName, lastName, searchContacts, displayName (nombres)
- **TextInputType.phone**: phoneNumber (teléfonos)
- **TextInputType.multiline**: event/group/message descriptions, bioText (multilínea)
- **TextInputType.streetAddress**: eventLocation (direcciones)
- **TextInputType.number**: ageField, capacityField (números)
- **TextInputType.visiblePassword**: passwordField, confirmPassword (passwords)

---

## 6. DEPENDENCIAS

### Packages externos:
- `flutter/material.dart`: TextInputType

### Imports internos:
- `../adaptive_text_field.dart`: AdaptiveTextFieldConfig, TextFieldVariant, ValidationMode

---

## 7. CARACTERÍSTICAS TÉCNICAS

### Parámetros opcionales con defaults:
- `.showCounter()` vs `.showCounter(false)`
- `.obscureText()` vs `.obscureText(false)`
- `.autocorrect()` vs `.autocorrect(false)`
- `.enableSuggestions()` vs `.enableSuggestions(false)`
- Sintaxis conveniente para casos comunes (true)

### limitedText non-const:
- Único método en extension que no es const
- Requiere parámetro maxLength
- No puede ser const porque acepta parámetro runtime

### custom con todos los defaults:
- Todos los parámetros son opcionales
- Defaults match los valores más comunes
- Permite omitir todo y usar solo defaults

### Duplicados intencionales:
- firstName == lastName (misma config, nombres semánticos diferentes)
- passwordField == confirmPassword (misma config, propósitos diferentes)
- ageField == capacityField (números genéricos)
- Facilita descubrimiento y claridad de código

### Progresión de maxLength:
- displayName (50) < eventTitle (100) < bioText (200) < invitationMessage (300) < eventDescription (500) < messageText (1000)
- Longitudes sensatas según tipo de contenido
- Mensajes más largos que titles y nombres

### TextInputType específicos:
- name: Optimizado para nombres (capitalización automática)
- phone: Teclado telefónico con símbolos +, *, #
- url: Teclado con .com, /, :
- streetAddress: Optimizado para direcciones
- visiblePassword: Evita autocorrección de passwords
- Mejora UX con teclados apropiados

### Autocorrect patterns:
- **ON**: firstName, lastName, displayName, event/group fields, messages, bio (lenguaje natural)
- **OFF**: username, password, phoneNumber, search, age, capacity (datos precisos)
- Diferenciación según tipo de contenido

### ValidationMode patterns:
- **onChanged**: username, password, firstName, lastName, phoneNumber, titles, age, capacity (feedback inmediato)
- **none**: search, descriptions, messages, bio (sin validación forzada)
- **onSubmitted**: url (extension) - valida al enviar

### showCounter patterns:
- **true**: Campos con maxLength (limited y multiline)
- **false**: Campos sin límite o donde el contador distrae
- Ayuda visual cuando hay límite

### Configuraciones por categoría:
- **Auth**: username, password, confirmPassword (3)
- **Profile**: firstName, lastName, displayName, bioText (4)
- **Events**: eventTitle, eventDescription, eventLocation (3)
- **Groups**: groupName, groupDescription (2)
- **Messages**: messageText, invitationMessage (2)
- **Search**: searchEvents, searchContacts (2)
- **Numbers**: ageField, capacityField (2)
- **Phone**: phoneNumber (1)

### Builder defaults inteligentes:
- autocorrect: true (mayoría de campos necesitan)
- enableSuggestions: true (ayuda al usuario)
- validationMode: onChanged (feedback inmediato)
- obscureText: false (solo passwords lo necesitan)
- Defaults para el caso común

### Extension vs TextFieldConfigs:
- **Extension**: Configuraciones genéricas reutilizables (name, search, url, number, description, comment)
- **TextFieldConfigs**: Configuraciones específicas de la app (eventTitle, groupName, bioText)
- **Extension**: 8 métodos (7 genéricos + 1 parametrizado + 1 custom)
- **TextFieldConfigs**: 19 constantes (específicas de dominio)

### Uso recomendado:
- **TextFieldConfigs**: Para campos específicos de la app (eventTitle, groupName)
- **Extension methods**: Para patrones genéricos (name, search, description)
- **Builder**: Para casos únicos que necesitan customización
- **custom()**: Para customización rápida con defaults
