# Button Config - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/adaptive/configs/button_config.dart`
**Líneas**: 115
**Tipo**: Extension + Builder + Constantes
**Propósito**: Proporciona métodos de conveniencia, builder pattern y configuraciones predefinidas para crear AdaptiveButtonConfig de forma fácil y consistente

## 2. CLASES CONTENIDAS

Este archivo contiene:
1. **AdaptiveButtonConfigExtended** (líneas 4-23): Extension con factory methods
2. **ButtonConfigBuilder** (líneas 25-72): Clase builder pattern
3. **ButtonConfigs** (líneas 74-114): Clase con 20 configuraciones constantes predefinidas

---

## 3. EXTENSION: AdaptiveButtonConfigExtended

### Información
**Líneas**: 4-23
**Tipo**: Extension on AdaptiveButtonConfig
**Propósito**: Añade métodos estáticos factory para crear configuraciones comunes

**Declaración**:
```dart
extension AdaptiveButtonConfigExtended on AdaptiveButtonConfig { ... }
```

### Métodos estáticos (líneas 5-22)

Todos los métodos son estáticos y retornan `AdaptiveButtonConfig`:

#### 1. destructive() (línea 5)
```dart
static AdaptiveButtonConfig destructive() => const AdaptiveButtonConfig(
  variant: ButtonVariant.primary,
  size: ButtonSize.medium,
  backgroundColor: Color(0xFFFF3B30), // Rojo
  textColor: Colors.white,
  fullWidth: false,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones de acciones destructivas (eliminar, cancelar suscripción, etc.)
**Color**: Rojo (#FF3B30) - color de alerta de iOS

#### 2. submit() (línea 7)
```dart
static AdaptiveButtonConfig submit() => const AdaptiveButtonConfig(
  variant: ButtonVariant.primary,
  size: ButtonSize.medium,
  fullWidth: true,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones de envío de formularios
**Característica**: fullWidth true (ocupa todo el ancho)

#### 3. cancel() (línea 9)
```dart
static AdaptiveButtonConfig cancel() => const AdaptiveButtonConfig(
  variant: ButtonVariant.secondary,
  size: ButtonSize.medium,
  fullWidth: false,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones de cancelar
**Variante**: secondary (outline, sin fondo)

#### 4. small() (línea 11)
```dart
static AdaptiveButtonConfig small() => const AdaptiveButtonConfig(
  variant: ButtonVariant.secondary,
  size: ButtonSize.small,
  fullWidth: false,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones pequeños secundarios
**Tamaño**: small (80% del tamaño normal)

#### 5. large() (línea 13)
```dart
static AdaptiveButtonConfig large() => const AdaptiveButtonConfig(
  variant: ButtonVariant.primary,
  size: ButtonSize.large,
  fullWidth: true,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones grandes principales
**Características**: large size + fullWidth

#### 6. iconOnly() (línea 15)
```dart
static AdaptiveButtonConfig iconOnly() => const AdaptiveButtonConfig(
  variant: ButtonVariant.icon,
  size: ButtonSize.medium,
  fullWidth: false,
  iconPosition: IconPosition.only
)
```
**Uso**: Botones de solo icono
**Variante**: icon (circular con ripple)

#### 7. floatingAction() (línea 17)
```dart
static AdaptiveButtonConfig floatingAction() => const AdaptiveButtonConfig(
  variant: ButtonVariant.fab,
  size: ButtonSize.medium,
  fullWidth: false,
  iconPosition: IconPosition.only
)
```
**Uso**: Floating Action Buttons
**Variante**: fab (botón flotante circular)

#### 8. link() (línea 19)
```dart
static AdaptiveButtonConfig link() => const AdaptiveButtonConfig(
  variant: ButtonVariant.text,
  size: ButtonSize.medium,
  fullWidth: false,
  iconPosition: IconPosition.trailing
)
```
**Uso**: Botones que parecen links
**Variante**: text (sin fondo ni borde)
**Icono**: trailing (a la derecha) para indicar navegación

#### 9. custom() (líneas 21-22)
```dart
static AdaptiveButtonConfig custom({
  ButtonVariant variant = ButtonVariant.primary,
  ButtonSize size = ButtonSize.medium,
  Color? backgroundColor,
  Color? textColor,
  bool fullWidth = false,
  IconPosition iconPosition = IconPosition.leading,
  double? borderRadius
}) => AdaptiveButtonConfig(
  variant: variant,
  size: size,
  backgroundColor: backgroundColor,
  textColor: textColor,
  fullWidth: fullWidth,
  iconPosition: iconPosition,
  borderRadius: borderRadius
)
```
**Uso**: Crear configuración personalizada con valores por defecto razonables
**Valores por defecto**:
- variant: ButtonVariant.primary
- size: ButtonSize.medium
- fullWidth: false
- iconPosition: IconPosition.leading

### Uso de la extension

```dart
// Usando extension methods
final button1 = AdaptiveButton(
  config: AdaptiveButtonConfigExtended.destructive(),
  text: 'Delete',
  onPressed: () {}
);

// Usando custom con overrides
final button2 = AdaptiveButton(
  config: AdaptiveButtonConfigExtended.custom(
    variant: ButtonVariant.secondary,
    size: ButtonSize.large
  ),
  text: 'Custom',
  onPressed: () {}
);
```

---

## 4. CLASE: ButtonConfigBuilder

### Información
**Líneas**: 25-72
**Tipo**: Builder pattern class
**Propósito**: Construir AdaptiveButtonConfig usando fluent API (method chaining)

### Variables privadas (líneas 26-32)
- `_variant` (ButtonVariant, línea 26): Default `ButtonVariant.primary`
- `_size` (ButtonSize, línea 27): Default `ButtonSize.medium`
- `_backgroundColor` (Color?, línea 28): Default `null`
- `_textColor` (Color?, línea 29): Default `null`
- `_fullWidth` (bool, línea 30): Default `false`
- `_iconPosition` (IconPosition, línea 31): Default `IconPosition.leading`
- `_borderRadius` (double?, línea 32): Default `null`

**Valores por defecto**: Primary, medium, no fullWidth, icono leading

### Métodos builder (líneas 34-67)

Todos los métodos retornan `this` para permitir chaining:

#### variant(ButtonVariant variant) (líneas 34-37)
```dart
ButtonConfigBuilder variant(ButtonVariant variant) {
  _variant = variant;
  return this;
}
```
**Propósito**: Establece la variante del botón

#### size(ButtonSize size) (líneas 39-42)
```dart
ButtonConfigBuilder size(ButtonSize size) {
  _size = size;
  return this;
}
```
**Propósito**: Establece el tamaño del botón

#### backgroundColor(Color color) (líneas 44-47)
```dart
ButtonConfigBuilder backgroundColor(Color color) {
  _backgroundColor = color;
  return this;
}
```
**Propósito**: Establece el color de fondo

#### textColor(Color color) (líneas 49-52)
```dart
ButtonConfigBuilder textColor(Color color) {
  _textColor = color;
  return this;
}
```
**Propósito**: Establece el color del texto

#### fullWidth([bool fullWidth = true]) (líneas 54-57)
```dart
ButtonConfigBuilder fullWidth([bool fullWidth = true]) {
  _fullWidth = fullWidth;
  return this;
}
```
**Propósito**: Establece si el botón ocupa todo el ancho
**Parámetro opcional**: Default true, permite `.fullWidth()` o `.fullWidth(false)`

#### iconPosition(IconPosition position) (líneas 59-62)
```dart
ButtonConfigBuilder iconPosition(IconPosition position) {
  _iconPosition = position;
  return this;
}
```
**Propósito**: Establece la posición del icono

#### borderRadius(double radius) (líneas 64-67)
```dart
ButtonConfigBuilder borderRadius(double radius) {
  _borderRadius = radius;
  return this;
}
```
**Propósito**: Establece el radio del borde

### Método build() (líneas 69-71)
```dart
AdaptiveButtonConfig build() {
  return AdaptiveButtonConfig(
    variant: _variant,
    size: _size,
    backgroundColor: _backgroundColor,
    textColor: _textColor,
    fullWidth: _fullWidth,
    iconPosition: _iconPosition,
    borderRadius: _borderRadius
  );
}
```
**Propósito**: Construye el AdaptiveButtonConfig final con los valores configurados

### Uso del builder

```dart
// Ejemplo de uso con chaining
final config = ButtonConfigBuilder()
    .variant(ButtonVariant.primary)
    .size(ButtonSize.large)
    .backgroundColor(Colors.red)
    .fullWidth()
    .iconPosition(IconPosition.trailing)
    .borderRadius(12.0)
    .build();

// Uso con AdaptiveButton
final button = AdaptiveButton(
  config: ButtonConfigBuilder()
      .variant(ButtonVariant.secondary)
      .size(ButtonSize.small)
      .build(),
  text: 'Cancel',
  onPressed: () {}
);
```

**Ventajas del builder**:
- Sintaxis fluida y legible
- Solo especifica lo que necesita cambiar
- Type-safe en tiempo de compilación
- Fácil de extender

---

## 5. CLASE: ButtonConfigs

### Información
**Líneas**: 74-114
**Tipo**: Clase con constantes estáticas
**Propósito**: Biblioteca de configuraciones predefinidas para casos de uso comunes

**Total de configuraciones**: 20

### Configuraciones generales (líneas 75-79)

#### saveButton (línea 75)
```dart
static const saveButton = AdaptiveButtonConfig(
  variant: ButtonVariant.primary,
  size: ButtonSize.medium,
  fullWidth: true,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones de guardar en formularios

#### createButton (línea 77)
```dart
static const createButton = AdaptiveButtonConfig(
  variant: ButtonVariant.primary,
  size: ButtonSize.medium,
  fullWidth: false,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones de crear nuevo item

#### continueButton (línea 79)
```dart
static const continueButton = AdaptiveButtonConfig(
  variant: ButtonVariant.primary,
  size: ButtonSize.large,
  fullWidth: true,
  iconPosition: IconPosition.trailing
)
```
**Uso**: Botones de continuar en flujos multi-paso
**Características**: Large + fullWidth + icono trailing (flecha derecha típicamente)

### Configuraciones de edición (líneas 81-83)

#### editButton (línea 81)
```dart
static const editButton = AdaptiveButtonConfig(
  variant: ButtonVariant.secondary,
  size: ButtonSize.medium,
  fullWidth: false,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones de editar

#### shareButton (línea 83)
```dart
static const shareButton = AdaptiveButtonConfig(
  variant: ButtonVariant.secondary,
  size: ButtonSize.medium,
  fullWidth: false,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones de compartir

### Configuraciones de visualización (línea 85)

#### viewButton (línea 85)
```dart
static const viewButton = AdaptiveButtonConfig(
  variant: ButtonVariant.text,
  size: ButtonSize.medium,
  fullWidth: false,
  iconPosition: IconPosition.trailing
)
```
**Uso**: Botones de ver detalles
**Variante**: text (link-style)

### Configuraciones destructivas (líneas 87-89)

#### deleteButton (línea 87)
```dart
static const deleteButton = AdaptiveButtonConfig(
  variant: ButtonVariant.primary,
  size: ButtonSize.medium,
  backgroundColor: Color(0xFFFF3B30), // Rojo iOS
  textColor: Colors.white,
  fullWidth: false,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones de eliminar
**Color**: Rojo (#FF3B30) - color destructivo de iOS

#### removeButton (línea 89)
```dart
static const removeButton = AdaptiveButtonConfig(
  variant: ButtonVariant.secondary,
  size: ButtonSize.small,
  textColor: Color(0xFFFF3B30), // Texto rojo
  fullWidth: false,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones de remover (menos destructivo que delete)
**Características**: Small + secondary + texto rojo

### Configuraciones de navegación (líneas 91-98)

#### cancelButton (línea 91)
```dart
static const cancelButton = AdaptiveButtonConfig(
  variant: ButtonVariant.text,
  size: ButtonSize.medium,
  fullWidth: false,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones de cancelar
**Variante**: text (menos prominente)

#### closeButton (línea 93)
```dart
static const closeButton = AdaptiveButtonConfig(
  variant: ButtonVariant.icon,
  size: ButtonSize.small,
  fullWidth: false,
  iconPosition: IconPosition.only
)
```
**Uso**: Botones de cerrar (X)
**Características**: Icon only + small

#### backButton (línea 95)
```dart
static const backButton = AdaptiveButtonConfig(
  variant: ButtonVariant.icon,
  size: ButtonSize.medium,
  fullWidth: false,
  iconPosition: IconPosition.only
)
```
**Uso**: Botones de retroceder
**Características**: Icon only + medium

#### nextButton (línea 97)
```dart
static const nextButton = AdaptiveButtonConfig(
  variant: ButtonVariant.primary,
  size: ButtonSize.medium,
  fullWidth: true,
  iconPosition: IconPosition.trailing
)
```
**Uso**: Botones de siguiente en flujos
**Características**: Primary + fullWidth + trailing icon

### Configuraciones de FAB (líneas 99-101)

#### addFAB (línea 99)
```dart
static const addFAB = AdaptiveButtonConfig(
  variant: ButtonVariant.fab,
  size: ButtonSize.medium,
  fullWidth: false,
  iconPosition: IconPosition.only
)
```
**Uso**: FAB para añadir items

#### composeFAB (línea 101)
```dart
static const composeFAB = AdaptiveButtonConfig(
  variant: ButtonVariant.fab,
  size: ButtonSize.large,
  fullWidth: false,
  iconPosition: IconPosition.only
)
```
**Uso**: FAB para componer/crear (correos, posts, etc.)
**Características**: Large (más prominente)

### Configuraciones de autenticación (líneas 103-107)

#### loginButton (línea 103)
```dart
static const loginButton = AdaptiveButtonConfig(
  variant: ButtonVariant.primary,
  size: ButtonSize.large,
  fullWidth: true,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones de iniciar sesión
**Características**: Large + fullWidth (botón prominente)

#### registerButton (línea 105)
```dart
static const registerButton = AdaptiveButtonConfig(
  variant: ButtonVariant.secondary,
  size: ButtonSize.large,
  fullWidth: true,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones de registro
**Características**: Secondary (menos prominente que login) + large + fullWidth

#### forgotPasswordButton (línea 107)
```dart
static const forgotPasswordButton = AdaptiveButtonConfig(
  variant: ButtonVariant.text,
  size: ButtonSize.small,
  fullWidth: false,
  iconPosition: IconPosition.trailing
)
```
**Uso**: Botones de olvidé contraseña
**Características**: Text + small (discreto, link-style)

### Configuraciones sociales (líneas 109-113)

#### likeButton (línea 109)
```dart
static const likeButton = AdaptiveButtonConfig(
  variant: ButtonVariant.icon,
  size: ButtonSize.medium,
  textColor: Color(0xFFFF3B30), // Rojo (corazón)
  fullWidth: false,
  iconPosition: IconPosition.only
)
```
**Uso**: Botones de like/favorito
**Características**: Icon only + color rojo (típico para corazón)

#### shareIconButton (línea 111)
```dart
static const shareIconButton = AdaptiveButtonConfig(
  variant: ButtonVariant.icon,
  size: ButtonSize.medium,
  fullWidth: false,
  iconPosition: IconPosition.only
)
```
**Uso**: Botones de compartir como icono

#### commentButton (línea 113)
```dart
static const commentButton = AdaptiveButtonConfig(
  variant: ButtonVariant.text,
  size: ButtonSize.small,
  fullWidth: false,
  iconPosition: IconPosition.leading
)
```
**Uso**: Botones de comentar
**Características**: Text + small

### Uso de ButtonConfigs

```dart
// Uso directo de constantes
final saveBtn = AdaptiveButton(
  config: ButtonConfigs.saveButton,
  text: 'Save',
  onPressed: () {}
);

// Múltiples botones con configs predefinidas
Row(
  children: [
    AdaptiveButton(
      config: ButtonConfigs.cancelButton,
      text: 'Cancel',
      onPressed: () {}
    ),
    AdaptiveButton(
      config: ButtonConfigs.saveButton,
      text: 'Save',
      onPressed: () {}
    ),
  ]
)
```

---

## 6. DEPENDENCIAS

### Packages externos:
- `flutter/material.dart`: Colors, Color

### Imports internos:
- `../adaptive_button.dart`: AdaptiveButtonConfig, ButtonVariant, ButtonSize, IconPosition

---

## 7. CARACTERÍSTICAS TÉCNICAS

### Extension methods:
- Usa extension para añadir métodos estáticos a AdaptiveButtonConfig
- No modifica la clase original
- Sintaxis: `AdaptiveButtonConfigExtended.destructive()`

### Constantes const:
- Todas las configuraciones en ButtonConfigs son const
- Todas las configs en extension (excepto custom) son const
- Optimización de compilación
- No se crean nuevas instancias en cada uso

### Color hardcoded:
- Rojo destructivo: `Color(0xFFFF3B30)` (rojo de iOS)
- Usado en: destructive(), deleteButton, removeButton, likeButton
- Consistencia visual con guidelines de iOS

### Builder pattern:
- Fluent API con method chaining
- Cada método retorna `this`
- Método `build()` final retorna el objeto
- Valores por defecto sensibles

### fullWidth opcional:
- `.fullWidth()` equivale a `.fullWidth(true)`
- `.fullWidth(false)` para desactivar
- Sintaxis conveniente para caso común (true)

### Configuraciones por categoría:
- Generales: save, create, continue
- Edición: edit, share, view
- Destructivas: delete, remove
- Navegación: cancel, close, back, next
- FAB: addFAB, composeFAB
- Autenticación: login, register, forgotPassword
- Sociales: like, shareIcon, comment

### Patrones de diseño identificables:
- **Primary + large + fullWidth**: Acciones principales prominentes (login, continue, large)
- **Secondary + medium**: Acciones secundarias (edit, share, cancel config)
- **Text + small**: Acciones terciarias discretas (forgotPassword, comment)
- **Icon + only**: Acciones de icono (close, back, like)
- **FAB**: Acciones flotantes principales

### iconPosition patterns:
- **leading**: Mayoría de botones (estándar)
- **trailing**: Botones de navegación hacia adelante (continue, next, link)
- **only**: Botones de solo icono (icon variant, FAB)

### Consistencia de naming:
- Sufijo "Button" para mayoría
- Sufijo "FAB" para floating action buttons
- Verbos de acción: save, create, edit, delete, etc.

### Custom method con defaults:
- Todos los parámetros opcionales excepto ninguno
- Defaults match los valores más comunes
- Permite overrides selectivos
- No es const (porque acepta parámetros)

### Static const vs static method:
- **ButtonConfigs**: static const (constantes inmutables)
- **Extension**: static methods (factories que retornan const)
- Extension permite custom() no-const

### Ventajas de este archivo:
1. **Consistencia**: Mismas configs en toda la app
2. **Mantenibilidad**: Cambiar un color cambia todas las instancias
3. **Descubribilidad**: Autocompletado muestra todas las opciones
4. **Type safety**: No strings mágicos, todo type-checked
5. **Flexibilidad**: Extension + Builder + Constantes cubren todos los casos

### Uso recomendado:
- **ButtonConfigs**: Para casos comunes ya definidos (save, delete, etc.)
- **Extension methods**: Para patrones comunes no en ButtonConfigs (destructive, submit)
- **Builder**: Para casos únicos que necesitan customización
- **custom()**: Para customización rápida con defaults
