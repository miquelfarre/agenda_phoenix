# AdaptiveCard - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/adaptive/adaptive_card.dart`
**Líneas**: 168
**Tipo**: Múltiples clases (StatelessWidget, Config, Enums, Interfaces, Validation)
**Propósito**: Sistema completo de tarjetas adaptativas con soporte para selección, estados enabled/disabled, sombras, márgenes y validación. Incluye el framework de validación usado por todos los widgets adaptativos

## 2. CLASES CONTENIDAS

Este archivo contiene:
1. **AdaptiveCard** (líneas 4-103): Widget principal de tarjeta adaptativa
2. **AdaptiveCardConfig** (líneas 105-127): Clase de configuración de tarjetas
3. **CardVariant** (línea 129): Enum con 6 variantes de tarjeta
4. **IAdaptiveWidget** (líneas 131-136): Interface base para widgets adaptativos
5. **ICardWidget** (líneas 138-145): Interface específica para tarjetas
6. **ValidationResult** (líneas 147-157): Clase para resultados de validación
7. **ValidationIssue** (líneas 159-165): Clase para issues de validación
8. **ValidationSeverity** (línea 167): Enum con 4 niveles de severidad

---

## 3. CLASE: AdaptiveCard

### Información
**Líneas**: 4-103
**Tipo**: StatelessWidget implements IAdaptiveWidget, ICardWidget
**Propósito**: Tarjeta adaptativa con soporte para selección, gestos tap, estados enabled/disabled, sombras y animaciones

### Implements
- `IAdaptiveWidget`: Interface base para widgets adaptativos (definida en este archivo)
- `ICardWidget`: Interface específica para tarjetas (definida en este archivo)

### Propiedades (líneas 5-18)
Todas las propiedades tienen `@override` porque vienen de las interfaces:

- `config` (AdaptiveCardConfig, required, línea 6): Configuración de la tarjeta (variante, margen, colores, etc.)
- `child` (Widget, required, línea 8): Contenido de la tarjeta
- `onTap` (VoidCallback?, línea 10): Callback opcional cuando se toca la tarjeta
- `selectable` (bool, línea 12): Si la tarjeta es seleccionable
- `selected` (bool, línea 14): Si la tarjeta está seleccionada
- `onSelectionChanged` (void Function(bool)?, línea 16): Callback cuando cambia selección
- `enabled` (bool, línea 18): Si la tarjeta está habilitada

### Constructor (línea 20)
```dart
const AdaptiveCard({
  super.key,
  required this.config,
  required this.child,
  this.onTap,
  this.selectable = false,
  this.selected = false,
  this.onSelectionChanged,
  this.enabled = true
})
```

**Valores por defecto**:
- `selectable = false`: No seleccionable por defecto
- `selected = false`: No seleccionada por defecto
- `enabled = true`: Habilitada por defecto

### Método build (líneas 22-30)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la tarjeta con detección de gestos y animación

**Lógica**:

1. **Obtiene el tema** (línea 24):
   - `PlatformTheme.adaptive(context)` para obtener tema adaptativo

2. **Retorna GestureDetector** (líneas 26-29):
   - **onTap** (línea 27):
     - `enabled ? _handleTap : null`
     - Si no está enabled, no responde a taps

   - **child** (línea 28): `AnimatedContainer` con:
     - duration: 200 milisegundos (animación rápida)
     - margin: `config.margin` (espaciado exterior)
     - decoration: `_buildDecoration(theme)` (fondo, sombra, borde)
     - child: `_buildContent()` (contenido de la tarjeta)

**Características**:
- GestureDetector para capturar taps
- AnimatedContainer para transiciones suaves (selección, enabled/disabled)
- Se deshabilita completamente si enabled es false

### Método _handleTap (líneas 32-37)
**Tipo de retorno**: `void`

**Propósito**: Maneja el tap en la tarjeta, gestionando selección y callback onTap

**Lógica**:

1. **Maneja selección** (líneas 33-35):
   - Condición: `selectable && onSelectionChanged != null`
   - Llama a `onSelectionChanged!(!selected)` (invierte el estado)
   - Force unwrap `!` porque ya se verificó que no es null

2. **Llama callback onTap** (línea 36):
   - `onTap?.call()` (null-safe call)
   - Se ejecuta siempre, independiente de selección

**Orden**: Primero maneja selección, luego llama onTap

### Método _buildDecoration (líneas 39-41)
**Tipo de retorno**: `BoxDecoration`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye la decoración de la tarjeta con color, sombra y borde

**Lógica**:

Retorna `BoxDecoration` con:
- **color** (línea 40): `_getBackgroundColor(theme)` (calcula color según estado)
- **borderRadius** (línea 40): `config.borderRadius` (esquinas redondeadas)
- **boxShadow** (línea 40): `config.showShadow ? _buildShadow() : null` (sombra condicional)
- **border** (línea 40): `_buildBorder(theme)` (borde si está seleccionada)

**Nota**: Todo en una sola línea, muy compacto

### Método _getBackgroundColor (líneas 43-51)
**Tipo de retorno**: `Color`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Calcula el color de fondo según el estado de la tarjeta

**Lógica con prioridad**:

1. **Deshabilitada** (líneas 44-46):
   - Condición: `!enabled`
   - Retorna: `theme.backgroundColor.withValues(alpha: 0.5)` (50% opacidad)
   - **Prioridad más alta**

2. **Seleccionada y seleccionable** (líneas 47-49):
   - Condición: `selected && selectable`
   - Retorna: `theme.primaryColor.withValues(alpha: 0.1)` (color primario con 10% opacidad)
   - **Segunda prioridad**

3. **Normal** (línea 50):
   - Retorna: `config.backgroundColor ?? theme.backgroundColor`
   - Usa config si existe, sino tema

**Orden de prioridad**: disabled > selected > normal

### Método _buildShadow (líneas 53-57)
**Tipo de retorno**: `List<BoxShadow>?`

**Propósito**: Construye la sombra de la tarjeta si está configurada

**Lógica**:

1. **Sin sombra** (línea 54):
   - Condición: `!config.showShadow`
   - Retorna: `null`

2. **Con sombra** (línea 56):
   - Retorna: lista con un `BoxShadow`:
     - color: negro con 10% opacidad
     - blurRadius: `config.elevation ?? 2.0` (usa elevation de config o 2.0 por defecto)
     - offset: `Offset(0, config.elevation ?? 2.0)` (desplazamiento vertical)

**Características**:
- Sombra siempre negra con 10% opacidad
- BlurRadius y offset Y son iguales (ambos usan elevation)
- Offset X siempre 0 (sombra solo hacia abajo)

### Método _buildBorder (líneas 59-64)
**Tipo de retorno**: `Border?`
**Parámetros**: `PlatformTheme theme`

**Propósito**: Construye el borde de la tarjeta si está seleccionada

**Lógica**:

1. **Seleccionada y seleccionable** (líneas 60-62):
   - Condición: `selectable && selected`
   - Retorna: `Border.all(color: theme.primaryColor, width: 2.0)`
   - Borde de 2px del color primario en todos los lados

2. **No seleccionada o no seleccionable** (línea 63):
   - Retorna: `null` (sin borde)

**Características**:
- Solo muestra borde cuando está seleccionada
- Borde de 2px en todos los lados
- Color del tema (primaryColor)

### Método _buildContent (líneas 66-77)
**Tipo de retorno**: `Widget`

**Propósito**: Construye el contenido de la tarjeta, añadiendo indicador de selección si es necesario

**Lógica**:

1. **No seleccionable** (líneas 67-69):
   - Condición: `!selectable`
   - Retorna: `child` directamente (sin modificaciones)

2. **Seleccionable** (líneas 71-76):
   - Retorna: `Row` con:
     - children:
       - **Indicador de selección condicional** (línea 73):
         - `if (selectable) _buildSelectionIndicator()`
         - Aunque siempre es true aquí (porque ya se filtró !selectable)
       - **Contenido expandido** (línea 74):
         - `Expanded(child: child)` para que ocupe espacio disponible

**Nota**: La condición `if (selectable)` en línea 73 es redundante porque ya se verificó en línea 67

### Método _buildSelectionIndicator (líneas 79-84)
**Tipo de retorno**: `Widget`

**Propósito**: Construye el indicador visual de selección (checkbox)

**Lógica**:

Retorna `Padding` con:
- padding: `EdgeInsets.only(right: 12.0)` (espacio a la derecha)
- child: `Icon` con:
  - icono: `selected ? Icons.check_circle : Icons.radio_button_unchecked`
    - Seleccionado: círculo con check
    - No seleccionado: círculo vacío
  - color: `selected ? Colors.green : Colors.grey`
    - Seleccionado: verde
    - No seleccionado: gris
  - size: 20

**Características**:
- Usa iconos de Material Design
- Verde cuando seleccionado (no usa color del tema)
- Gris cuando no seleccionado
- Tamaño fijo de 20px

### Getter theme (líneas 86-87)
**Tipo de retorno**: `PlatformTheme`
**Anotación**: `@override` (viene de IAdaptiveWidget)

**Propósito**: Retorna el tema adaptativo

**Implementación**:
```dart
PlatformTheme get theme => PlatformTheme.adaptive(null);
```

**Nota**: Pasa `null` como context, mismo patrón que AdaptiveButton

### Método validate (líneas 89-102)
**Tipo de retorno**: `ValidationResult`
**Anotación**: `@override` (viene de IAdaptiveWidget)

**Propósito**: Valida la configuración de la tarjeta

**Lógica**:

1. **Inicializa lista de issues** (línea 91):
   - `issues = <ValidationIssue>[]`

2. **Validación 1: Márgenes negativos** (líneas 93-95):
   - Condición: `config.margin.left < 0 || config.margin.top < 0 || config.margin.right < 0 || config.margin.bottom < 0`
   - Añade: ValidationIssue con:
     - message: 'Margin values should not be negative'
     - severity: ValidationSeverity.warning (no es error, solo warning)

3. **Validación 2: Seleccionable sin callback** (líneas 97-99):
   - Condición: `selectable && onSelectionChanged == null`
   - Añade: ValidationIssue con:
     - message: 'Selectable cards should have onSelectionChanged handler'
     - severity: ValidationSeverity.error
     - suggestion: 'Add onSelectionChanged callback'

4. **Retorna ValidationResult** (línea 101):
   - isValid: true si no hay errores
   - issues: lista completa
   - severity: más alta de todos los issues (usando reduce)

**Issues detectados**:
- Warning: Márgenes negativos
- Error: Seleccionable sin onSelectionChanged

---

## 4. CLASE: AdaptiveCardConfig

### Información
**Líneas**: 105-127
**Tipo**: Clase de configuración (inmutable)
**Propósito**: Almacena la configuración visual de la tarjeta

### Propiedades (líneas 106-112)
- `variant` (CardVariant, required): Variante de la tarjeta
- `margin` (EdgeInsets, required): Margen exterior
- `borderRadius` (BorderRadius, required): Radio de las esquinas
- `backgroundColor` (Color?): Color de fondo opcional
- `showShadow` (bool, required): Si muestra sombra
- `selectable` (bool, required): Si es seleccionable
- `elevation` (double?): Elevación de la sombra (opcional)

### Constructor principal (línea 114)
```dart
const AdaptiveCardConfig({
  required this.variant,
  required this.margin,
  required this.borderRadius,
  this.backgroundColor,
  required this.showShadow,
  required this.selectable,
  this.elevation
})
```

### Factory constructors (líneas 116-126)

Proporcionan configuraciones predefinidas para diferentes usos:

1. **AdaptiveCardConfig.simple()** (línea 116):
   ```dart
   const AdaptiveCardConfig(
     variant: CardVariant.simple,
     margin: EdgeInsets.all(8.0),
     borderRadius: BorderRadius.all(Radius.circular(8.0)),
     showShadow: false,
     selectable: false
   )
   ```
   - Sin sombra, margen uniforme de 8px, radio 8px

2. **AdaptiveCardConfig.listItem()** (línea 118):
   ```dart
   const AdaptiveCardConfig(
     variant: CardVariant.listItem,
     margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
     borderRadius: BorderRadius.all(Radius.circular(8.0)),
     showShadow: true,
     selectable: false,
     elevation: 1.0
   )
   ```
   - Con sombra, margen horizontal 16px y vertical 4px, elevation 1.0

3. **AdaptiveCardConfig.selectable()** (línea 120):
   ```dart
   const AdaptiveCardConfig(
     variant: CardVariant.selectable,
     margin: EdgeInsets.all(8.0),
     borderRadius: BorderRadius.all(Radius.circular(8.0)),
     showShadow: false,
     selectable: true
   )
   ```
   - Seleccionable, sin sombra

4. **AdaptiveCardConfig.elevated()** (línea 122):
   ```dart
   const AdaptiveCardConfig(
     variant: CardVariant.elevated,
     margin: EdgeInsets.all(12.0),
     borderRadius: BorderRadius.all(Radius.circular(12.0)),
     showShadow: true,
     selectable: false,
     elevation: 4.0
   )
   ```
   - Máximo elevation (4.0), márgenes grandes, radio grande

5. **AdaptiveCardConfig.contact()** (línea 124):
   ```dart
   const AdaptiveCardConfig(
     variant: CardVariant.contact,
     margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
     borderRadius: BorderRadius.all(Radius.circular(10.0)),
     showShadow: true,
     selectable: false,
     elevation: 2.0
   )
   ```
   - Para contactos, elevation media (2.0), radio 10px

6. **AdaptiveCardConfig.event()** (línea 126):
   ```dart
   const AdaptiveCardConfig(
     variant: CardVariant.event,
     margin: EdgeInsets.all(8.0),
     borderRadius: BorderRadius.all(Radius.circular(12.0)),
     showShadow: true,
     selectable: false,
     elevation: 3.0
   )
   ```
   - Para eventos, elevation alta (3.0), radio grande (12px)

**Comparación de elevations**:
- listItem: 1.0 (sombra sutil)
- contact: 2.0 (sombra media)
- event: 3.0 (sombra notable)
- elevated: 4.0 (sombra máxima)

---

## 5. ENUM: CardVariant

**Línea**: 129
**Valores**:
```dart
enum CardVariant { simple, listItem, selectable, elevated, contact, event }
```

1. **simple**: Tarjeta básica sin sombra
2. **listItem**: Item de lista con sombra sutil
3. **selectable**: Tarjeta seleccionable
4. **elevated**: Tarjeta con sombra pronunciada
5. **contact**: Tarjeta para contactos
6. **event**: Tarjeta para eventos

---

## 6. INTERFACE: IAdaptiveWidget

**Líneas**: 131-136
**Tipo**: Abstract class
**Propósito**: Interface base para todos los widgets adaptativos

### Getters abstractos:
- `PlatformTheme get theme` (línea 132): Tema de la plataforma
- `bool get enabled` (línea 133): Estado habilitado/deshabilitado

### Métodos abstractos:
- `Widget build(BuildContext context)` (línea 134): Construye el widget
- `ValidationResult validate()` (línea 135): Valida el widget

**Implementado por**: AdaptiveCard, AdaptiveButton (y otros widgets adaptativos)

---

## 7. INTERFACE: ICardWidget

**Líneas**: 138-145
**Tipo**: Abstract class extends IAdaptiveWidget
**Propósito**: Interface específica para widgets de tarjeta

### Getters abstractos adicionales:
- `AdaptiveCardConfig get config` (línea 139): Configuración de la tarjeta
- `Widget get child` (línea 140): Contenido de la tarjeta
- `VoidCallback? get onTap` (línea 141): Callback de tap
- `bool get selectable` (línea 142): Si es seleccionable
- `bool get selected` (línea 143): Estado de selección
- `void Function(bool selected)? get onSelectionChanged` (línea 144): Callback de cambio

**Hereda**: theme, enabled, build(), validate() de IAdaptiveWidget

---

## 8. CLASE: ValidationResult

**Líneas**: 147-157
**Tipo**: Clase de datos (inmutable)
**Propósito**: Representa el resultado de validar un widget

### Propiedades (líneas 148-150)
- `isValid` (bool, required): Si el widget es válido (sin errores)
- `issues` (List<ValidationIssue>, required): Lista de issues encontrados
- `severity` (ValidationSeverity, required): Severidad más alta de todos los issues

### Constructor principal (línea 152)
```dart
const ValidationResult({
  required this.isValid,
  required this.issues,
  required this.severity
})
```

### Factory constructors (líneas 154-156)

1. **ValidationResult.valid()** (línea 154):
   ```dart
   const ValidationResult(
     isValid: true,
     issues: [],
     severity: ValidationSeverity.none
   )
   ```
   - Para widgets sin issues

2. **ValidationResult.invalid()** (línea 156):
   ```dart
   ValidationResult(
     isValid: false,
     issues: issues,
     severity: ValidationSeverity.error
   )
   ```
   - Para widgets con errores
   - Asume severity error

---

## 9. CLASE: ValidationIssue

**Líneas**: 159-165
**Tipo**: Clase de datos (inmutable)
**Propósito**: Representa un issue individual de validación

### Propiedades (líneas 160-162)
- `message` (String, required): Mensaje describiendo el issue
- `severity` (ValidationSeverity, required): Nivel de severidad
- `suggestion` (String?): Sugerencia opcional para resolver

### Constructor (línea 164)
```dart
const ValidationIssue({
  required this.message,
  required this.severity,
  this.suggestion
})
```

---

## 10. ENUM: ValidationSeverity

**Línea**: 167
**Valores**:
```dart
enum ValidationSeverity { none, info, warning, error }
```

1. **none**: Sin issues
2. **info**: Información, no afecta validez
3. **warning**: Advertencia, no invalida pero no es ideal
4. **error**: Error, invalida el widget

**Orden**: Creciente de severidad (none < info < warning < error)

---

## 11. DEPENDENCIAS

### Packages externos:
- `flutter/material.dart`: Widgets de Material Design
  - GestureDetector, AnimatedContainer
  - BoxDecoration, BoxShadow, Border
  - Icon, Colors
  - EdgeInsets, BorderRadius, Offset

### Imports internos:
- `platform_theme.dart`: PlatformTheme para tema adaptativo

### Tipos personalizados (definidos en este archivo):
- IAdaptiveWidget, ICardWidget (interfaces)
- ValidationResult, ValidationIssue, ValidationSeverity (validación)

---

## 12. CARACTERÍSTICAS TÉCNICAS

### AnimatedContainer:
- Duration de 200ms
- Anima cambios en decoration (color, borde)
- Transiciones suaves al seleccionar/deseleccionar
- Anima cambios de estado enabled/disabled

### GestureDetector:
- Captura eventos tap
- onTap null cuando disabled (no responde)
- Permite interacción táctil

### Sistema de prioridad de colores:
1. Disabled: 50% opacidad del fondo normal
2. Selected: 10% opacidad del color primario
3. Normal: color de config o tema

### Sombra parametrizada:
- Color siempre negro 10% opacidad
- BlurRadius y offset Y usan elevation
- Elevation configurable por variante:
  - simple: sin sombra
  - listItem: 1.0
  - contact: 2.0
  - event: 3.0
  - elevated: 4.0

### Borde de selección:
- Solo visible cuando seleccionada
- 2px de ancho
- Color primario del tema
- Border.all (todos los lados)

### Indicador de selección:
- check_circle cuando seleccionado (verde)
- radio_button_unchecked cuando no (gris)
- Tamaño fijo 20px
- Padding derecho 12px
- Colores hardcoded (no usa tema)

### withValues para opacidad:
- `.withValues(alpha: 0.5)` para disabled
- `.withValues(alpha: 0.1)` para selected
- `.withValues(alpha: 0.1)` para sombra
- API moderna de Flutter

### Null-safe callback:
- `onTap?.call()` en _handleTap
- Llama solo si no es null
- Sintaxis concisa

### Force unwrap seguro:
- `onSelectionChanged!(!selected)` en _handleTap
- Seguro porque se verifica null antes

### Factory constructors semánticos:
- 6 variantes predefinidas
- Nombres descriptivos (simple, listItem, contact, event, etc.)
- Valores apropiados para cada uso

### Const constructor y config:
- Constructor const permite tarjetas constantes
- AdaptiveCardConfig también const
- Optimización de compilación

### Validación de márgenes negativos:
- Verifica cada lado (left, top, right, bottom)
- Warning no error (permite pero advierte)
- Previene layouts extraños

### Validación de selección:
- Error si selectable sin onSelectionChanged
- Asegura que la selección sea funcional
- Incluye suggestion

### ValidationResult.isValid:
- Solo cuenta errores, no warnings
- Filtra issues con severity == error
- Warnings no invalidan

### Reduce para max severity:
- Compara índices de enums
- Encuentra severity más alta
- `(a, b) => a.index > b.index ? a : b`

### Row con Expanded:
- En _buildContent cuando selectable
- Expanded asegura que child ocupe espacio disponible
- Indicador a la izquierda, contenido expansible

### Condition redundante:
- `if (selectable)` en línea 73 es redundante
- Ya se filtró `!selectable` en línea 67
- Posible código legacy o defensivo

### Theme getter sin contexto:
- `PlatformTheme.adaptive(null)` pasa null
- Mismo patrón que otros widgets adaptativos
- Puede causar problemas si tema depende de contexto

### Framework de validación completo:
- Este archivo define todo el sistema de validación
- Usado por AdaptiveButton y otros widgets
- ValidationResult, ValidationIssue, ValidationSeverity
- Patrón consistente en todos los widgets adaptativos
