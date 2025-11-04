# AdaptiveButton - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/adaptive/adaptive_button.dart`
**Líneas**: 222
**Tipo**: Múltiples clases (StatelessWidget, Config, Enums, Interfaces)
**Propósito**: Sistema completo de botones adaptativos con múltiples variantes (primary, secondary, text, icon, FAB), tamaños, estados de carga y validación

## 2. CLASES CONTENIDAS

Este archivo contiene:
1. **AdaptiveButton** (líneas 5-184): Widget principal de botón adaptativo
2. **AdaptiveButtonConfig** (líneas 186-206): Clase de configuración del botón
3. **ButtonVariant** (línea 208): Enum con 5 variantes de botón
4. **ButtonSize** (línea 210): Enum con 3 tamaños
5. **IconPosition** (línea 212): Enum con 3 posiciones de icono
6. **IButtonWidget** (líneas 214-221): Interface abstracta para botones

---

## 3. CLASE: AdaptiveButton

### Información
**Líneas**: 5-184
**Tipo**: StatelessWidget implements IAdaptiveWidget, IButtonWidget
**Propósito**: Widget de botón adaptativo que cambia su apariencia según variante, tamaño, estado de carga y plataforma

### Implements
- `IAdaptiveWidget`: Interface para widgets adaptativos (definida en este archivo)
- `IButtonWidget`: Interface específica para botones (definida en este archivo)

### Propiedades (líneas 6-19)
Todas las propiedades tienen `@override` porque vienen de las interfaces:

- `config` (AdaptiveButtonConfig, required, línea 7): Configuración del botón (variante, tamaño, colores, etc.)
- `onPressed` (VoidCallback?, línea 9): Callback cuando se presiona el botón
- `text` (String?, línea 11): Texto del botón (opcional)
- `icon` (IconData?, línea 13): Icono del botón (opcional)
- `isLoading` (bool, línea 15): Indica si el botón está en estado de carga
- `onLoadingChanged` (void Function(bool)?, línea 17): Callback cuando cambia el estado de carga
- `enabled` (bool, línea 19): Indica si el botón está habilitado, default true

### Constructor (línea 21)
```dart
const AdaptiveButton({
  super.key,
  required this.config,
  this.onPressed,
  this.text,
  this.icon,
  this.isLoading = false,
  this.onLoadingChanged,
  this.enabled = true
})
```

**Valores por defecto**:
- `isLoading = false`: No está cargando por defecto
- `enabled = true`: Está habilitado por defecto

### Método build (líneas 23-43)
**Tipo de retorno**: `Widget`

**Propósito**: Construye el botón apropiado según configuración y estado

**Lógica**:

1. **Obtiene el tema** (línea 25):
   - `PlatformTheme.adaptive(context)` para obtener tema adaptativo

2. **Estado de carga** (líneas 27-29):
   - Condición: `isLoading`
   - Retorna: `_buildLoadingButton(theme)`
   - Tiene prioridad sobre todo, si está cargando muestra spinner

3. **Switch por variante** (líneas 31-42):
   - `ButtonVariant.primary`: `_buildPrimaryButton(theme)`
   - `ButtonVariant.secondary`: `_buildSecondaryButton(theme)`
   - `ButtonVariant.text`: `_buildTextButton(theme)`
   - `ButtonVariant.icon`: `_buildIconButton(theme)`
   - `ButtonVariant.fab`: `_buildFAB(theme)`

**Orden de prioridad**: isLoading > variant

### Método _buildPrimaryButton (líneas 45-60)
**Tipo de retorno**: `Widget`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye botón primary (elevado, color sólido)

**Lógica**:

1. **SizedBox** (líneas 46-48):
   - width: `double.infinity` si `config.fullWidth`, sino `null` (ajusta a contenido)
   - height: `_getButtonHeight(theme)` (calcula según size)

2. **ElevatedButton** (líneas 49-58):
   - **onPressed** (línea 50):
     - `enabled ? onPressed : null`
     - Si no está enabled, pasa null → botón deshabilitado

   - **style** (líneas 51-56):
     - backgroundColor: `config.backgroundColor ?? theme.primaryColor`
     - foregroundColor: `config.textColor ?? Colors.white`
     - shape: `RoundedRectangleBorder` con borderRadius:
       - Usa `config.borderRadius` si existe
       - Sino usa `theme.defaultBorderRadius.topLeft.x`
     - elevation:
       - `0` si `theme.isIOS` (sin sombra en iOS)
       - `2` si no es iOS (sombra en otras plataformas)

   - **child** (línea 57):
     - `_buildButtonContent()` para construir contenido (texto/icono)

**Características**:
- Fondo de color sólido
- Texto blanco por defecto
- Sin sombra en iOS, con sombra en otras plataformas
- Puede ser fullWidth

### Método _buildSecondaryButton (líneas 62-76)
**Tipo de retorno**: `Widget`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye botón secondary (outline, sin fondo)

**Lógica**:

1. **SizedBox** (líneas 63-65):
   - Igual que primary

2. **OutlinedButton** (líneas 66-74):
   - **onPressed** (línea 67):
     - `enabled ? onPressed : null`

   - **style** (líneas 68-72):
     - foregroundColor: `config.textColor ?? theme.primaryColor`
     - side: `BorderSide(color: theme.primaryColor)` (borde del color primario)
     - shape: `RoundedRectangleBorder` con borderRadius igual que primary

   - **child** (línea 73):
     - `_buildButtonContent()`

**Características**:
- Sin fondo, solo borde
- Texto del color primario por defecto
- Borde del color primario
- Puede ser fullWidth

### Método _buildTextButton (líneas 78-84)
**Tipo de retorno**: `Widget`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye botón de texto (sin fondo ni borde)

**Lógica**:

1. **TextButton** (líneas 79-83):
   - **onPressed** (línea 80):
     - `enabled ? onPressed : null`

   - **style** (línea 81):
     - foregroundColor: `config.textColor ?? theme.primaryColor`

   - **child** (línea 82):
     - `_buildButtonContent()`

**Características**:
- Sin fondo, sin borde
- Solo texto/icono con color
- No usa SizedBox (no controla width/height)
- Ajusta a contenido

### Método _buildIconButton (líneas 86-92)
**Tipo de retorno**: `Widget`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye botón de solo icono

**Lógica**:

1. **IconButton** (líneas 87-91):
   - **onPressed** (línea 88):
     - `enabled ? onPressed : null`

   - **icon** (línea 89):
     - Icon con `icon ?? Icons.star` (fallback a estrella)
     - color: `config.textColor ?? theme.primaryColor`

   - **iconSize** (línea 90):
     - `_getIconSize()` (calcula según size)

**Características**:
- Solo icono, sin texto
- Icono circular con efecto ripple
- Fallback a Icons.star si no se proporciona icono

### Método _buildFAB (líneas 94-100)
**Tipo de retorno**: `Widget`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye Floating Action Button

**Lógica**:

1. **FloatingActionButton** (líneas 95-99):
   - **onPressed** (línea 96):
     - `enabled ? onPressed : null`

   - **backgroundColor** (línea 97):
     - `config.backgroundColor ?? theme.primaryColor`

   - **child** (línea 98):
     - Icon con `icon ?? Icons.add` (fallback a plus)
     - color: `config.textColor ?? Colors.white`

**Características**:
- Botón circular flotante
- Fondo de color sólido
- Solo icono
- Fallback a Icons.add (icono de más)

### Método _buildLoadingButton (líneas 102-115)
**Tipo de retorno**: `Widget`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye botón en estado de carga con spinner

**Lógica**:

1. **SizedBox** (líneas 103-105):
   - width: `double.infinity` si fullWidth, sino null
   - height: `_getButtonHeight(theme)`

2. **ElevatedButton** (líneas 106-113):
   - **onPressed** (línea 107):
     - `null` (siempre deshabilitado durante carga)

   - **style** (líneas 108-111):
     - backgroundColor: Color con 60% de opacidad:
       - `(config.backgroundColor ?? theme.primaryColor).withValues(alpha: 0.6)`
     - shape: RoundedRectangleBorder igual que otros

   - **child** (línea 112):
     - SizedBox de 20x20 con:
       - `CircularProgressIndicator` con:
         - strokeWidth: 2 (línea delgada)
         - valueColor: blanco siempre

**Características**:
- Botón deshabilitado (onPressed null)
- Fondo con 60% opacidad
- Spinner blanco centrado
- Tamaño del spinner: 20x20

### Método _buildButtonContent (líneas 117-125)
**Tipo de retorno**: `Widget`

**Propósito**: Construye el contenido del botón (texto, icono, o ambos)

**Lógica**:

1. **Icono y texto** (líneas 118-119):
   - Condición: `icon != null && text != null`
   - Retorna: `_buildIconTextContent()` (maneja posición del icono)

2. **Solo icono** (líneas 120-121):
   - Condición: `icon != null` (y text es null)
   - Retorna: `Icon(icon, size: _getIconSize())`

3. **Solo texto** (líneas 122-123):
   - Condición: icon es null
   - Retorna: `Text(text ?? '')` (string vacío si text es null)

**Orden de decisión**: ambos > solo icono > solo texto

### Método _buildIconTextContent (líneas 127-139)
**Tipo de retorno**: `Widget`

**Propósito**: Construye contenido cuando hay icono y texto, respetando posición del icono

**Lógica**:

1. **Prepara widgets** (líneas 128-129):
   - `iconWidget = Icon(icon, size: _getIconSize())`
   - `textWidget = Text(text ?? '')`

2. **Switch por iconPosition** (líneas 131-138):

   a) **IconPosition.leading** (línea 132-133):
      - Retorna: Row con:
        - mainAxisSize: MainAxisSize.min
        - children: [iconWidget, SizedBox(width: 8), textWidget]
      - Icono a la izquierda, texto a la derecha

   b) **IconPosition.trailing** (línea 134-135):
      - Retorna: Row con:
        - mainAxisSize: MainAxisSize.min
        - children: [textWidget, SizedBox(width: 8), iconWidget]
      - Texto a la izquierda, icono a la derecha

   c) **IconPosition.only** (línea 136-137):
      - Retorna: `iconWidget`
      - Ignora el texto, solo muestra icono

**Espaciado**: 8px entre icono y texto

### Método _getButtonHeight (líneas 141-150)
**Tipo de retorno**: `double`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Calcula la altura del botón según su tamaño configurado

**Lógica**:

Switch por `config.size`:
- **ButtonSize.small** (línea 143-144):
  - Retorna: `theme.buttonHeight * 0.8` (80% de altura normal)

- **ButtonSize.medium** (línea 145-146):
  - Retorna: `theme.buttonHeight` (altura normal)

- **ButtonSize.large** (línea 147-148):
  - Retorna: `theme.buttonHeight * 1.2` (120% de altura normal)

**Escalado**: small 80%, medium 100%, large 120%

### Método _getIconSize (líneas 152-161)
**Tipo de retorno**: `double`

**Propósito**: Calcula el tamaño del icono según el tamaño del botón

**Lógica**:

Switch por `config.size`:
- **ButtonSize.small** (línea 154-155):
  - Retorna: `16.0`

- **ButtonSize.medium** (línea 156-157):
  - Retorna: `20.0`

- **ButtonSize.large** (línea 158-159):
  - Retorna: `24.0`

**Tamaños fijos**: small 16, medium 20, large 24

### Getter theme (líneas 163-164)
**Tipo de retorno**: `PlatformTheme`
**Anotación**: `@override` (viene de IAdaptiveWidget)

**Propósito**: Retorna el tema adaptativo

**Implementación**:
```dart
PlatformTheme get theme => PlatformTheme.adaptive(null);
```

**Nota**: Pasa `null` como context, puede causar problemas si el tema depende del contexto

### Método validate (líneas 166-183)
**Tipo de retorno**: `ValidationResult`
**Anotación**: `@override` (viene de IAdaptiveWidget)

**Propósito**: Valida la configuración del botón y retorna resultado con issues

**Lógica**:

1. **Inicializa lista de issues** (línea 168):
   - `issues = <ValidationIssue>[]`

2. **Validación 1: Icon button sin icono** (líneas 170-172):
   - Condición: `config.variant == ButtonVariant.icon && icon == null`
   - Añade: ValidationIssue con:
     - message: 'Icon buttons must have an icon'
     - severity: ValidationSeverity.error
     - suggestion: 'Provide an icon property'

3. **Validación 2: Botón sin contenido** (líneas 174-176):
   - Condición: `config.variant != ButtonVariant.icon && text == null && icon == null`
   - Añade: ValidationIssue con:
     - message: 'Buttons should have either text or icon content'
     - severity: ValidationSeverity.warning
     - suggestion: 'Provide text or icon property'

4. **Validación 3: FAB fullWidth** (líneas 178-180):
   - Condición: `config.fullWidth && config.variant == ButtonVariant.fab`
   - Añade: ValidationIssue con:
     - message: 'FAB buttons should not be full width'
     - severity: ValidationSeverity.warning
     - No tiene suggestion

5. **Retorna ValidationResult** (línea 182):
   - isValid: true si no hay errores (filtra solo severity == error)
   - issues: lista completa de issues
   - severity: severity más alta de todos los issues (reduce comparando índices)
     - Si no hay issues: ValidationSeverity.none

**Issues detectados**:
- Error: Icon button sin icono
- Warning: Botón sin texto ni icono
- Warning: FAB con fullWidth

---

## 4. CLASE: AdaptiveButtonConfig

### Información
**Líneas**: 186-206
**Tipo**: Clase de configuración (inmutable)
**Propósito**: Almacena la configuración visual y de comportamiento del botón

### Propiedades (líneas 187-193)
- `variant` (ButtonVariant, required): Variante del botón (primary, secondary, etc.)
- `size` (ButtonSize, required): Tamaño del botón (small, medium, large)
- `backgroundColor` (Color?): Color de fondo opcional
- `textColor` (Color?): Color del texto opcional
- `fullWidth` (bool, required): Si el botón ocupa todo el ancho disponible
- `iconPosition` (IconPosition, required): Posición del icono (leading, trailing, only)
- `borderRadius` (double?): Radio de borde opcional

### Constructor principal (línea 195)
```dart
const AdaptiveButtonConfig({
  required this.variant,
  required this.size,
  this.backgroundColor,
  this.textColor,
  required this.fullWidth,
  required this.iconPosition,
  this.borderRadius
})
```

### Factory constructors (líneas 197-205)

Proporcionan configuraciones predefinidas para cada variante:

1. **AdaptiveButtonConfig.primary()** (línea 197):
   ```dart
   const AdaptiveButtonConfig(
     variant: ButtonVariant.primary,
     size: ButtonSize.medium,
     fullWidth: false,
     iconPosition: IconPosition.leading
   )
   ```

2. **AdaptiveButtonConfig.secondary()** (línea 199):
   ```dart
   const AdaptiveButtonConfig(
     variant: ButtonVariant.secondary,
     size: ButtonSize.medium,
     fullWidth: false,
     iconPosition: IconPosition.leading
   )
   ```

3. **AdaptiveButtonConfig.text()** (línea 201):
   ```dart
   const AdaptiveButtonConfig(
     variant: ButtonVariant.text,
     size: ButtonSize.medium,
     fullWidth: false,
     iconPosition: IconPosition.leading
   )
   ```

4. **AdaptiveButtonConfig.icon()** (línea 203):
   ```dart
   const AdaptiveButtonConfig(
     variant: ButtonVariant.icon,
     size: ButtonSize.medium,
     fullWidth: false,
     iconPosition: IconPosition.only
   )
   ```
   **Nota**: iconPosition es `only` por defecto

5. **AdaptiveButtonConfig.fab()** (línea 205):
   ```dart
   const AdaptiveButtonConfig(
     variant: ButtonVariant.fab,
     size: ButtonSize.medium,
     fullWidth: false,
     iconPosition: IconPosition.only
   )
   ```
   **Nota**: iconPosition es `only` por defecto

**Valores por defecto comunes**:
- size: ButtonSize.medium
- fullWidth: false
- iconPosition: IconPosition.leading (excepto icon y fab que usan only)

---

## 5. ENUM: ButtonVariant

**Línea**: 208
**Valores**:
```dart
enum ButtonVariant { primary, secondary, text, icon, fab }
```

1. **primary**: Botón elevado con fondo de color
2. **secondary**: Botón con borde, sin fondo
3. **text**: Botón de solo texto/icono, sin fondo ni borde
4. **icon**: Botón de solo icono circular
5. **fab**: Floating Action Button

---

## 6. ENUM: ButtonSize

**Línea**: 210
**Valores**:
```dart
enum ButtonSize { small, medium, large }
```

1. **small**: 80% del tamaño normal, icono 16px
2. **medium**: 100% del tamaño normal, icono 20px
3. **large**: 120% del tamaño normal, icono 24px

---

## 7. ENUM: IconPosition

**Línea**: 212
**Valores**:
```dart
enum IconPosition { leading, trailing, only }
```

1. **leading**: Icono a la izquierda del texto
2. **trailing**: Icono a la derecha del texto
3. **only**: Solo icono, ignora el texto

---

## 8. INTERFACE: IButtonWidget

**Líneas**: 214-221
**Tipo**: Abstract class extends IAdaptiveWidget
**Propósito**: Define el contrato que deben cumplir los widgets de botón

### Getters abstractos:
- `AdaptiveButtonConfig get config`: Configuración del botón
- `VoidCallback? get onPressed`: Callback de presión
- `String? get text`: Texto del botón
- `IconData? get icon`: Icono del botón
- `bool get isLoading`: Estado de carga
- `void Function(bool loading)? get onLoadingChanged`: Callback de cambio de loading

**Nota**: Extiende IAdaptiveWidget que presumiblemente tiene métodos `validate()` y getter `theme`

---

## 9. DEPENDENCIAS

### Packages externos:
- `flutter/material.dart`: Widgets de Material Design
  - ElevatedButton, OutlinedButton, TextButton, IconButton, FloatingActionButton
  - CircularProgressIndicator
  - Icon, Text
  - Colors

### Imports internos:
- `platform_theme.dart`: PlatformTheme para tema adaptativo

### Tipos personalizados:
- `PlatformTheme`: Tema adaptativo según plataforma
- `IAdaptiveWidget`: Interface para widgets adaptativos
- `ValidationResult`, `ValidationIssue`, `ValidationSeverity`: Sistema de validación

---

## 10. CARACTERÍSTICAS TÉCNICAS

### Sistema de validación integrado:
- Valida configuración del botón
- 3 validaciones implementadas:
  1. Icon button debe tener icono (error)
  2. Botones deben tener contenido (warning)
  3. FAB no debe ser fullWidth (warning)
- Retorna ValidationResult con lista de issues
- Calcula severity más alta con reduce

### Estado de carga:
- Propiedad `isLoading` controla el estado
- Cuando true: muestra spinner blanco en botón deshabilitado
- Fondo con 60% opacidad durante carga
- onLoadingChanged callback (no usado en el widget, para uso externo)

### Enabled vs disabled:
- Propiedad `enabled` controla habilitación
- Cuando false: pasa `null` a onPressed → botón deshabilitado
- Cuando isLoading: también deshabilitado (onPressed null)
- Disabled tiene estilos nativos del botón (gris, etc.)

### Adaptación a plataforma:
- iOS: elevation 0 en primary (sin sombra)
- Otras: elevation 2 en primary (con sombra)
- Usa PlatformTheme.adaptive() para obtener valores del tema

### FullWidth:
- Controlado por config.fullWidth
- Si true: SizedBox con width double.infinity
- Si false: width null (ajusta a contenido)
- Solo aplica a primary, secondary, y loading
- Text, icon y FAB no usan fullWidth

### Colores con fallback:
- backgroundColor: usa config si existe, sino theme.primaryColor
- textColor: usa config si existe, sino theme.primaryColor o Colors.white según variante
- Permite customización pero siempre tiene fallback

### BorderRadius flexible:
- Usa config.borderRadius si se proporciona
- Sino usa theme.defaultBorderRadius.topLeft.x
- Consistencia con el tema pero permite override

### Iconos con fallback:
- Icon button: fallback a Icons.star
- FAB: fallback a Icons.add
- Previene errores si no se proporciona icono

### Espaciado icono-texto:
- SizedBox de 8px entre icono y texto
- Consistente en ambas posiciones (leading/trailing)

### Row con mainAxisSize.min:
- En _buildIconTextContent
- Row se ajusta al tamaño mínimo necesario
- Evita que el Row ocupe todo el espacio disponible

### CircularProgressIndicator customizado:
- strokeWidth: 2 (línea delgada)
- valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
- Siempre blanco independiente del tema
- Tamaño 20x20 (pequeño para caber en botón)

### withValues para opacidad:
- Usa `.withValues(alpha: 0.6)` en lugar de `.withOpacity()`
- API más moderna de Flutter
- alpha entre 0.0 y 1.0

### Switch exhaustivo:
- Todos los switches (variant, size, iconPosition) cubren todos los casos
- No necesita default case
- Garantizado por el sistema de tipos

### Factory constructors convenientes:
- 5 factory constructors predefinidos
- Facilitan creación de botones comunes
- Valores por defecto sensibles

### Const constructor y config:
- Constructor const permite botones constantes
- AdaptiveButtonConfig también const
- Optimización de compilación

### Interface IButtonWidget:
- Abstrae el contrato del botón
- Permite múltiples implementaciones
- Facilita testing y mocking

### Getter theme sin contexto:
- `PlatformTheme.adaptive(null)` pasa null
- Puede no funcionar si el tema necesita contexto
- Posible bug o limitación del diseño

### ValidationResult con reduce:
- Encuentra severity más alta comparando índices
- `reduce((a, b) => a.index > b.index ? a : b)`
- Asume que enums tienen orden de severidad creciente

### isValid basado en errores:
- Solo cuenta ValidationSeverity.error
- Warnings no invalidan el botón
- Permite uso con warnings pero bloquea con errores
