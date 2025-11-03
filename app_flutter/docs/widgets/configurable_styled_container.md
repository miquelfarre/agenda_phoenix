# ConfigurableStyledContainer y SectionHeader - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/common/configurable_styled_container.dart`
**Líneas**: 118
**Tipo**: Multi-class widget file (2 StatelessWidgets + 1 enum)
**Propósito**: Proporciona contenedores estilizados con múltiples variantes (header con gradiente, card simple, info con color primario) y un widget de header de sección con icono y texto

## 2. CLASES CONTENIDAS

Este archivo contiene:
1. **ConfigurableStyledContainer** (líneas 6-78): Contenedor con 3 variantes de estilo
2. **SectionHeader** (líneas 80-115): Header de sección con icono, título y subtítulo
3. **ConfigurableContainerStyle** (línea 117): Enum con 3 estilos de contenedor

---

## 3. CLASE: ConfigurableStyledContainer

### 3.1. Información General

**Líneas**: 6-78
**Tipo**: StatelessWidget
**Propósito**: Contenedor configurable que cambia su apariencia visual (colores, gradientes, bordes) según el estilo seleccionado, con soporte opcional para interacción táctil

### 3.2. Propiedades (líneas 7-10)

- `child` (Widget, required, línea 7): Contenido del contenedor
- `padding` (EdgeInsetsGeometry?, línea 8): Padding interno opcional (cada estilo tiene su default)
- `style` (ConfigurableContainerStyle, default: card, línea 9): Estilo visual del contenedor
- `onTap` (VoidCallback?, línea 10): Callback opcional para hacer el contenedor interactivo

### 3.3. Constructor Principal (línea 12)

```dart
const ConfigurableStyledContainer({
  super.key,
  required this.child,
  this.padding,
  this.style = ConfigurableContainerStyle.card,
  this.onTap
})
```

**Tipo**: Constructor const

**Parámetros**:
- `super.key`: Key? (opcional)
- `child`: Widget (required)
- `padding`: EdgeInsetsGeometry? (opcional)
- `style`: ConfigurableContainerStyle (opcional, default: card)
- `onTap`: VoidCallback? (opcional)

**Uso típico**:
```dart
ConfigurableStyledContainer(
  style: ConfigurableContainerStyle.info,
  child: Text('Info container'),
)
```

### 3.4. Named Constructors (líneas 14-18)

#### 3.4.1. ConfigurableStyledContainer.header (línea 14)

```dart
const ConfigurableStyledContainer.header({
  super.key,
  required this.child,
  this.padding = const EdgeInsets.all(20),
  this.onTap
}) : style = ConfigurableContainerStyle.header
```

**Características**:
- Inicializa `style = ConfigurableContainerStyle.header` (initializer list)
- **Padding default**: EdgeInsets.all(20)
- **Uso**: Headers con gradiente de color primario

**Ejemplo**:
```dart
ConfigurableStyledContainer.header(
  child: SectionHeader(...),
)
```

#### 3.4.2. ConfigurableStyledContainer.card (línea 16)

```dart
const ConfigurableStyledContainer.card({
  super.key,
  required this.child,
  this.padding = const EdgeInsets.all(20),
  this.onTap
}) : style = ConfigurableContainerStyle.card
```

**Características**:
- Inicializa `style = ConfigurableContainerStyle.card`
- **Padding default**: EdgeInsets.all(20)
- **Uso**: Cards simples con fondo blanco/gris y borde sutil

**Ejemplo**:
```dart
ConfigurableStyledContainer.card(
  child: Column(...),
)
```

#### 3.4.3. ConfigurableStyledContainer.info (línea 18)

```dart
const ConfigurableStyledContainer.info({
  super.key,
  required this.child,
  this.padding = const EdgeInsets.all(20),
  this.onTap
}) : style = ConfigurableContainerStyle.info
```

**Características**:
- Inicializa `style = ConfigurableContainerStyle.info`
- **Padding default**: EdgeInsets.all(20)
- **Uso**: Contenedores de información con fondo azul claro

**Ejemplo**:
```dart
ConfigurableStyledContainer.info(
  child: Text('Información importante'),
)
```

**Nota sobre named constructors**:
- Todos tienen el mismo padding default (EdgeInsets.all(20))
- Todos fijan el estilo via initializer list
- No permiten cambiar el `style` parameter (se sobreescribe)
- Sintaxis más limpia que pasar el style manualmente

### 3.5. Método build (líneas 20-41)

**Tipo de retorno**: Widget
**Anotación**: @override

**Propósito**: Construye el contenedor según el estilo seleccionado y opcionalmente lo envuelve en GestureDetector

**Estructura del widget tree**:
```
GestureDetector (si onTap != null)
└── Container (según style)
    └── child
```

**Lógica detallada**:

1. **Declaración de variable** (línea 22):
   ```dart
   Widget container;
   ```
   - Variable mutable para almacenar el contenedor construido
   - Se asigna en el switch

2. **Switch por style** (líneas 24-34):
   ```dart
   switch (style) {
     case ConfigurableContainerStyle.header:
       container = _buildHeaderContainer();
       break;
     case ConfigurableContainerStyle.card:
       container = _buildCardContainer();
       break;
     case ConfigurableContainerStyle.info:
       container = _buildInfoContainer();
       break;
   }
   ```

   **Mapeo de estilos a builders**:
   - `header` → `_buildHeaderContainer()` (gradiente + shadow)
   - `card` → `_buildCardContainer()` (fondo simple + borde)
   - `info` → `_buildInfoContainer()` (fondo azul + borde)

   **Nota**: Switch exhaustivo, no necesita default case

3. **Wrapper condicional para interactividad** (líneas 36-38):
   ```dart
   if (onTap != null) {
     return GestureDetector(onTap: onTap, child: container);
   }
   ```

   - **Si onTap es proporcionado**: Envuelve container en GestureDetector
   - **Si onTap es null**: Retorna container directamente (sin capa adicional)
   - **Optimización**: No añade GestureDetector innecesario cuando no es interactivo

4. **Retorno final** (línea 40):
   ```dart
   return container;
   ```
   - Retorna el container sin wrapper si no es interactivo

### 3.6. Método _buildHeaderContainer (líneas 43-57)

**Tipo de retorno**: Widget
**Visibilidad**: Privado

**Propósito**: Construye contenedor estilo header con gradiente de color primario y sombra

**Estructura del widget tree**:
```
StyledContainer (shadow + transparent background)
└── DecoratedBox (gradiente)
    └── Padding (20px fijo)
        └── child
```

**Código**:
```dart
Widget _buildHeaderContainer() {
  return StyledContainer(
    padding: (padding ?? const EdgeInsets.all(20)) as EdgeInsets,
    borderRadius: AppStyles.largeRadius,
    color: AppStyles.transparent,
    boxShadow: [BoxShadow(
      color: AppStyles.primary200,
      blurRadius: 12,
      offset: const Offset(0, 4)
    )],
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppStyles.primary500, AppStyles.primary600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight
        ),
        borderRadius: AppStyles.largeRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child
      ),
    ),
  );
}
```

**Análisis detallado**:

1. **StyledContainer exterior** (líneas 44-48):
   - **padding** (línea 45):
     - `(padding ?? const EdgeInsets.all(20)) as EdgeInsets`
     - Usa padding proporcionado o default EdgeInsets.all(20)
     - **Cast a EdgeInsets**: StyledContainer requiere EdgeInsets, no EdgeInsetsGeometry
   - **borderRadius** (línea 46): `AppStyles.largeRadius` (probablemente BorderRadius.circular(16))
   - **color** (línea 47): `AppStyles.transparent` (Color.transparent, para que solo se vea el gradiente)
   - **boxShadow** (línea 48):
     - Color: `AppStyles.primary200` (sombra con color primario claro)
     - blurRadius: 12 (sombra difusa)
     - offset: Offset(0, 4) (sombra hacia abajo)

2. **DecoratedBox con gradiente** (líneas 49-55):
   - **gradient** (líneas 51):
     - Tipo: LinearGradient
     - colors: [primary500, primary600] (de más claro a más oscuro)
     - begin: Alignment.topLeft (esquina superior izquierda)
     - end: Alignment.bottomRight (esquina inferior derecha)
     - **Efecto**: Gradiente diagonal de arriba-izquierda a abajo-derecha
   - **borderRadius** (línea 52): `AppStyles.largeRadius` (mismo que container)

3. **Padding interno adicional** (línea 54):
   - EdgeInsets.all(20) fijo
   - **Nota**: Este padding es adicional al del StyledContainer
   - **Total padding**: padding del StyledContainer + 20px internos

**Características visuales**:
- Fondo transparente en container
- Gradiente de primary500 a primary600 diagonal
- Sombra azul claro (primary200) difusa hacia abajo
- BorderRadius grande (esquinas redondeadas)
- Doble padding (exterior e interior)

**Uso**: Headers de sección, cards destacadas, paneles importantes

### 3.7. Método _buildCardContainer (líneas 59-67)

**Tipo de retorno**: Widget
**Visibilidad**: Privado

**Propósito**: Construye contenedor estilo card con fondo simple y borde sutil

**Estructura del widget tree**:
```
StyledContainer
└── child
```

**Código**:
```dart
Widget _buildCardContainer() {
  return StyledContainer(
    padding: (padding ?? const EdgeInsets.all(20)) as EdgeInsets,
    borderRadius: AppStyles.largeRadius,
    color: AppStyles.cardBackgroundColor,
    border: Border.all(color: AppStyles.grey300),
    child: child,
  );
}
```

**Análisis detallado**:

1. **StyledContainer único** (líneas 60-66):
   - **padding** (línea 61):
     - `(padding ?? const EdgeInsets.all(20)) as EdgeInsets`
     - Default: EdgeInsets.all(20)
     - Cast a EdgeInsets requerido
   - **borderRadius** (línea 62): `AppStyles.largeRadius`
   - **color** (línea 63):
     - `AppStyles.cardBackgroundColor`
     - Probablemente blanco o gris muy claro
   - **border** (línea 64):
     - `Border.all(color: AppStyles.grey300)`
     - Borde sutil gris claro
     - Grosor default (1px probablemente)
   - **child** (línea 65): Directamente el child sin wrappers adicionales

**Características visuales**:
- Fondo claro (blanco/gris claro)
- Borde gris sutil
- BorderRadius grande
- Sin sombra
- Sin gradiente
- Estructura simple (1 widget)

**Diferencia con header**:
- No tiene gradiente
- No tiene sombra
- No tiene DecoratedBox adicional
- No tiene Padding interno adicional

**Uso**: Cards simples, contenedores de formulario, paneles informativos básicos

### 3.8. Método _buildInfoContainer (líneas 69-77)

**Tipo de retorno**: Widget
**Visibilidad**: Privado

**Propósito**: Construye contenedor estilo info con fondo azul claro y borde azul

**Estructura del widget tree**:
```
StyledContainer
└── child
```

**Código**:
```dart
Widget _buildInfoContainer() {
  return StyledContainer(
    padding: (padding ?? const EdgeInsets.all(20)) as EdgeInsets,
    borderRadius: AppStyles.largeRadius,
    color: AppStyles.primary50,
    border: Border.all(color: AppStyles.primary200),
    child: child,
  );
}
```

**Análisis detallado**:

1. **StyledContainer único** (líneas 70-76):
   - **padding** (línea 71):
     - `(padding ?? const EdgeInsets.all(20)) as EdgeInsets`
     - Default: EdgeInsets.all(20)
     - Cast a EdgeInsets
   - **borderRadius** (línea 72): `AppStyles.largeRadius`
   - **color** (línea 73):
     - `AppStyles.primary50`
     - Azul muy claro (probablemente #E3F2FD o similar)
   - **border** (línea 74):
     - `Border.all(color: AppStyles.primary200)`
     - Borde azul claro (más oscuro que el fondo)
     - Grosor default (1px)
   - **child** (línea 75): Directamente el child

**Características visuales**:
- Fondo azul muy claro (primary50)
- Borde azul claro (primary200)
- BorderRadius grande
- Sin sombra
- Sin gradiente
- Estructura simple (1 widget)

**Comparación con card**:
- Similar en estructura
- Diferencia: Usa colores de la paleta primaria en lugar de gris
- Más llamativo visualmente (color vs neutral)

**Uso**: Mensajes informativos, tips, notas importantes, avisos no críticos

---

## 4. CLASE: SectionHeader

### 4.1. Información General

**Líneas**: 80-115
**Tipo**: StatelessWidget
**Propósito**: Header de sección con icono en container redondeado, título y subtítulo, diseñado para uso dentro de ConfigurableStyledContainer.header

### 4.2. Propiedades (líneas 81-85)

- `icon` (IconData, required, línea 81): Icono a mostrar en el header
- `title` (String, required, línea 82): Título principal del header
- `subtitle` (String, required, línea 83): Subtítulo o descripción
- `iconColor` (Color?, línea 84): Color personalizado para el icono (default: blanco)
- `textColor` (Color?, línea 85): Color personalizado para título y subtítulo (default: blanco)

### 4.3. Constructor (línea 87)

```dart
const SectionHeader({
  super.key,
  required this.icon,
  required this.title,
  required this.subtitle,
  this.iconColor,
  this.textColor
})
```

**Tipo**: Constructor const

**Parámetros**:
- `icon`, `title`, `subtitle`: required
- `iconColor`, `textColor`: optional (nullable)

**Uso típico**:
```dart
SectionHeader(
  icon: Icons.event,
  title: 'Próximos Eventos',
  subtitle: 'Eventos programados para esta semana',
)
```

### 4.4. Método build (líneas 89-114)

**Tipo de retorno**: Widget
**Anotación**: @override

**Propósito**: Construye un header de sección con icono en container, título y subtítulo

**Estructura del widget tree**:
```
Row
├── Container (icono con background)
│   └── Icon
├── SizedBox (spacing 16px)
└── Expanded
    └── Column
        ├── Text (title)
        ├── SizedBox (spacing 4px)
        └── Text (subtitle)
```

**Lógica detallada**:

1. **Colores efectivos** (líneas 91-92):
   ```dart
   final effectiveIconColor = iconColor ?? AppStyles.white;
   final effectiveTextColor = textColor ?? AppStyles.white;
   ```
   - **iconColor**: Si no se proporciona, usa blanco
   - **textColor**: Si no se proporciona, usa blanco
   - **Motivo**: Diseñado para usarse con fondo oscuro (gradiente en header)

2. **Row principal** (líneas 94-113):
   - **mainAxisAlignment**: No especificado (default: start)
   - **crossAxisAlignment**: No especificado (default: center)

3. **Container del icono** (líneas 96-100):
   ```dart
   Container(
     padding: const EdgeInsets.all(12),
     decoration: BoxDecoration(
       color: AppStyles.colorWithOpacity(AppStyles.white, 0.2),
       borderRadius: AppStyles.cardRadius
     ),
     child: PlatformWidgets.platformIcon(
       icon,
       color: effectiveIconColor,
       size: 24
     ),
   )
   ```

   **Propiedades**:
   - **padding** (línea 97): EdgeInsets.all(12) (espacio alrededor del icono)
   - **decoration** (línea 98):
     - **color** (línea 98):
       - `AppStyles.colorWithOpacity(AppStyles.white, 0.2)`
       - Blanco con 20% de opacidad
       - Efecto: Fondo semi-transparente sobre el gradiente
     - **borderRadius** (línea 98): `AppStyles.cardRadius` (esquinas redondeadas)
   - **child** (línea 99):
     - `PlatformWidgets.platformIcon`: Icono adaptativo según plataforma
     - color: effectiveIconColor (blanco por default)
     - size: 24px

   **Características visuales**:
   - Container cuadrado con padding 12 alrededor del icono 24px
   - Tamaño total del container: 24 + 12*2 = 48px
   - Fondo blanco semi-transparente (20% opacity)
   - Icono blanco por default
   - Esquinas redondeadas

4. **SizedBox spacing** (línea 101):
   ```dart
   const SizedBox(width: 16)
   ```
   - Espacio horizontal de 16px entre icono y textos

5. **Expanded con Column de textos** (líneas 102-111):
   ```dart
   Expanded(
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(title, style: AppStyles.headlineSmall.copyWith(
           color: effectiveTextColor
         )),
         const SizedBox(height: 4),
         Text(subtitle, style: AppStyles.bodyTextSmall.copyWith(
           color: AppStyles.colorWithOpacity(effectiveTextColor, 0.9)
         )),
       ],
     ),
   )
   ```

   **Expanded**:
   - Ocupa todo el espacio horizontal restante
   - Permite que los textos se expandan sin overflow

   **Column** (línea 103):
   - **crossAxisAlignment.start**: Alinea textos a la izquierda
   - **mainAxisAlignment**: No especificado (default: start)

   a) **Text del título** (línea 106):
      - **text**: `title`
      - **style**: `AppStyles.headlineSmall.copyWith(color: effectiveTextColor)`
      - Estilo de headline (probablemente 18-20px, bold)
      - Color personalizable, default blanco
      - **maxLines**: No especificado (puede ser multilínea)

   b) **SizedBox spacing** (línea 107):
      - height: 4px (espacio vertical pequeño entre título y subtítulo)

   c) **Text del subtítulo** (línea 108):
      - **text**: `subtitle`
      - **style**: `AppStyles.bodyTextSmall.copyWith(color: ...)`
      - **color**: `AppStyles.colorWithOpacity(effectiveTextColor, 0.9)`
      - Color con 90% de opacidad para diferenciarlo del título
      - Estilo de body text small (probablemente 12-14px, regular)
      - **maxLines**: No especificado (puede ser multilínea)

**Características visuales**:
- Icono en container semi-transparente a la izquierda
- Título grande y subtítulo pequeño a la derecha
- Colores por default en blanco (para fondos oscuros)
- Subtítulo con opacidad 90% para jerarquía visual
- Spacing de 16px entre icono y textos, 4px entre título y subtítulo

---

## 5. ENUM: ConfigurableContainerStyle

**Línea**: 117
**Valores**:
```dart
enum ConfigurableContainerStyle { header, card, info }
```

1. **header**: Contenedor con gradiente de color primario y sombra
2. **card**: Contenedor simple con fondo claro y borde gris
3. **info**: Contenedor con fondo azul claro y borde azul

---

## 6. COMPARACIÓN DE ESTILOS

### 6.1. Tabla comparativa de características visuales

| Característica | header | card | info |
|----------------|--------|------|------|
| **Color de fondo** | Transparent (gradiente interno) | cardBackgroundColor (claro) | primary50 (azul claro) |
| **Gradiente** | Sí (primary500 → primary600) | No | No |
| **Borde** | No | Sí (grey300) | Sí (primary200) |
| **Sombra** | Sí (primary200, blur 12) | No | No |
| **Estructura** | Container + DecoratedBox + Padding | Container simple | Container simple |
| **Padding default** | 20px (+ 20px interno adicional) | 20px | 20px |
| **BorderRadius** | largeRadius | largeRadius | largeRadius |
| **Complejidad** | Alta (3 widgets) | Baja (1 widget) | Baja (1 widget) |

### 6.2. Tabla comparativa de uso

| Estilo | Uso recomendado | Ejemplos |
|--------|-----------------|----------|
| **header** | Headers de sección, cards destacadas | Encabezados de pantalla, paneles importantes |
| **card** | Cards simples, contenedores generales | Formularios, listas de información |
| **info** | Mensajes informativos, tips | Avisos, notas, información contextual |

### 6.3. Visual hierarchy

**Orden de prominencia visual**:
1. **header**: Más prominente (gradiente + sombra)
2. **info**: Medianamente prominente (color de marca)
3. **card**: Menos prominente (neutral)

---

## 7. DEPENDENCIAS

**Imports**:
```dart
import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import '../styled_container.dart';
```

### 7.1. Dependencias externas

1. **flutter/cupertino.dart** (línea 1):
   - StatelessWidget, Widget, BuildContext
   - Container, Row, Column, Expanded, SizedBox
   - EdgeInsets, EdgeInsetsGeometry
   - BoxDecoration, Border, BorderRadius, BoxShadow
   - LinearGradient, Alignment, Offset
   - Color, IconData
   - Text, Padding, DecoratedBox, GestureDetector

### 7.2. Dependencias internas

2. **app_styles.dart** (línea 2):
   - AppStyles.largeRadius: BorderRadius para esquinas grandes
   - AppStyles.cardRadius: BorderRadius para esquinas de card
   - AppStyles.transparent: Color transparente
   - AppStyles.primary50/200/500/600: Colores de la paleta primaria
   - AppStyles.grey300: Color gris claro
   - AppStyles.cardBackgroundColor: Color de fondo de cards
   - AppStyles.white: Color blanco
   - AppStyles.headlineSmall: TextStyle para títulos
   - AppStyles.bodyTextSmall: TextStyle para cuerpo
   - AppStyles.colorWithOpacity(Color, double): Función helper para opacidad

3. **platform_widgets.dart** (línea 3):
   - PlatformWidgets.platformIcon: Icono adaptativo según plataforma

4. **styled_container.dart** (línea 4):
   - StyledContainer: Widget base para contenedores estilizados

---

## 8. CARACTERÍSTICAS TÉCNICAS

### 8.1. Named constructors convenientes

**Beneficios**:
- Sintaxis más limpia: `.header()` vs `(style: ConfigurableContainerStyle.header)`
- Padding default incluido (20px)
- Previene errores (no puedes cambiar el style accidentalmente)
- Autodocumentado (el nombre indica el estilo)

**Uso**:
```dart
// Con named constructor (preferido)
ConfigurableStyledContainer.info(
  child: Text('Info'),
)

// Sin named constructor (más verboso)
ConfigurableStyledContainer(
  style: ConfigurableContainerStyle.info,
  padding: const EdgeInsets.all(20),
  child: Text('Info'),
)
```

### 8.2. Cast de EdgeInsetsGeometry a EdgeInsets

**Problema**:
- Propiedad acepta EdgeInsetsGeometry (interfaz abstracta)
- StyledContainer requiere EdgeInsets (clase concreta)

**Solución**:
```dart
(padding ?? const EdgeInsets.all(20)) as EdgeInsets
```

**Nota**: Cast puede fallar si se pasa un EdgeInsetsDirectional (caso raro)

**Alternativa más segura** (no implementada):
```dart
padding is EdgeInsets ? padding : EdgeInsets.all(20)
```

### 8.3. Interactividad condicional

**Optimización**:
- Si `onTap == null`: No añade GestureDetector
- Si `onTap != null`: Envuelve en GestureDetector

**Beneficio**: Evita nodos innecesarios en el widget tree cuando no es interactivo

**Comparación con alternativas**:
```dart
// Implementación actual (óptima)
if (onTap != null) {
  return GestureDetector(onTap: onTap, child: container);
}
return container;

// Alternativa menos eficiente (siempre añade GestureDetector)
return GestureDetector(
  onTap: onTap, // puede ser null
  child: container,
);
```

### 8.4. Doble padding en header

**Estructura**:
1. Padding del StyledContainer: `padding ?? EdgeInsets.all(20)`
2. Padding interno adicional: `EdgeInsets.all(20)` fijo

**Total**: 40px de padding (20 + 20) si se usa el default

**Motivo**: El gradiente está en el DecoratedBox interno, necesita padding adicional para no llegar al borde

**Diagrama**:
```
┌─────────────────────────────────────┐
│ StyledContainer (padding 20)       │
│  ┌───────────────────────────────┐ │
│  │ DecoratedBox (gradiente)      │ │
│  │  ┌─────────────────────────┐  │ │
│  │  │ Padding (20)            │  │ │
│  │  │  ┌───────────────────┐  │  │ │
│  │  │  │ child             │  │  │ │
│  │  │  └───────────────────┘  │  │ │
│  │  └─────────────────────────┘  │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

### 8.5. Gradiente diagonal

**Configuración**:
```dart
LinearGradient(
  colors: [AppStyles.primary500, AppStyles.primary600],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight
)
```

**Efecto**: Gradiente de esquina superior izquierda a inferior derecha

**Alternativas**:
- Vertical: begin: Alignment.topCenter, end: Alignment.bottomCenter
- Horizontal: begin: Alignment.centerLeft, end: Alignment.centerRight

### 8.6. PlatformWidgets.platformIcon

**Propósito**: Renderiza icono adaptativo según plataforma
- iOS: CupertinoIcons
- Android/otros: Material Icons

**Uso**:
```dart
PlatformWidgets.platformIcon(icon, color: color, size: 24)
```

### 8.7. colorWithOpacity helper

**Uso en el código**:
```dart
// Fondo semi-transparente del icono
AppStyles.colorWithOpacity(AppStyles.white, 0.2) // 20% opacity

// Subtítulo con opacidad reducida
AppStyles.colorWithOpacity(effectiveTextColor, 0.9) // 90% opacity
```

**Alternativa sin helper**:
```dart
AppStyles.white.withOpacity(0.2)
```

**Beneficio del helper**: Centraliza la lógica de opacidad si hay consideraciones especiales

### 8.8. Switch exhaustivo

**Switch de estilos**:
```dart
switch (style) {
  case ConfigurableContainerStyle.header:
    container = _buildHeaderContainer();
    break;
  case ConfigurableContainerStyle.card:
    container = _buildCardContainer();
    break;
  case ConfigurableContainerStyle.info:
    container = _buildInfoContainer();
    break;
}
```

**Características**:
- Cubre todos los casos del enum
- No necesita default case
- Compilador verifica exhaustividad
- Si se añade un nuevo estilo al enum, el compilador dará error

### 8.9. Constructores const

**Ambas clases tienen constructor const**:
- Permite instancias constantes cuando todos los parámetros son const
- Optimización de compilación y runtime
- Reduce rebuilds innecesarios

**Ejemplo**:
```dart
const ConfigurableStyledContainer.info(
  child: Text('Static info'), // También debe ser const
)
```

---

## 9. PATRONES DE DISEÑO

### 9.1. Strategy Pattern

**Implementación**:
- Enum `ConfigurableContainerStyle` define las estrategias
- Método `build()` selecciona la estrategia con switch
- Cada estrategia tiene su builder privado

**Beneficio**: Fácil añadir nuevos estilos sin modificar la estructura principal

### 9.2. Builder Pattern

**Builders privados**:
- `_buildHeaderContainer()`
- `_buildCardContainer()`
- `_buildInfoContainer()`

**Separación de responsabilidades**: Cada builder construye su variante específica

### 9.3. Named Constructor Pattern

**Named constructors** como factory methods:
- `.header()`, `.card()`, `.info()`
- Facilitan creación con valores por defecto apropiados
- Autodocumentados

### 9.4. Composition over Inheritance

**ConfigurableStyledContainer** compone StyledContainer:
- No extiende StyledContainer
- Usa StyledContainer internamente
- Añade lógica de selección de estilo

**SectionHeader** es composable:
- Diseñado para usarse dentro de ConfigurableStyledContainer.header
- Pero puede usarse independientemente

---

## 10. CASOS DE USO

### 10.1. Header de sección con SectionHeader

```dart
ConfigurableStyledContainer.header(
  child: SectionHeader(
    icon: Icons.calendar_month,
    title: 'Próximos Eventos',
    subtitle: 'Eventos programados para esta semana',
  ),
)
```

**Resultado**: Header con gradiente azul, icono en container semi-transparente, título y subtítulo blancos

### 10.2. Card simple de información

```dart
ConfigurableStyledContainer.card(
  child: Column(
    children: [
      Text('Título del card'),
      SizedBox(height: 8),
      Text('Contenido del card'),
    ],
  ),
)
```

**Resultado**: Card con fondo claro, borde gris sutil, padding 20px

### 10.3. Mensaje informativo

```dart
ConfigurableStyledContainer.info(
  child: Row(
    children: [
      Icon(Icons.info_outline, color: Colors.blue),
      SizedBox(width: 12),
      Expanded(
        child: Text('Este es un mensaje informativo importante'),
      ),
    ],
  ),
)
```

**Resultado**: Container con fondo azul claro, borde azul, padding 20px

### 10.4. Container interactivo

```dart
ConfigurableStyledContainer.card(
  onTap: () => print('Card tapped'),
  child: Text('Toca para ver detalles'),
)
```

**Resultado**: Card que responde a toques

### 10.5. Padding personalizado

```dart
ConfigurableStyledContainer.info(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  child: Text('Padding personalizado'),
)
```

**Resultado**: Container info con padding custom en lugar del default 20px

### 10.6. SectionHeader con colores personalizados

```dart
SectionHeader(
  icon: Icons.star,
  title: 'Destacados',
  subtitle: 'Contenido especial',
  iconColor: Colors.yellow,
  textColor: Colors.black87,
)
```

**Resultado**: Header con icono amarillo y textos oscuros (para fondo claro)

---

## 11. TESTING

### 11.1. Test cases para ConfigurableStyledContainer

1. **Switch de estilos**:
   ```dart
   testWidgets('renders header style correctly', (tester) async {
     await tester.pumpWidget(
       ConfigurableStyledContainer.header(
         child: Text('Header'),
       ),
     );
     // Verificar presencia de DecoratedBox con gradiente
   });
   ```

2. **Interactividad condicional**:
   ```dart
   testWidgets('wraps in GestureDetector when onTap provided', (tester) async {
     bool tapped = false;
     await tester.pumpWidget(
       ConfigurableStyledContainer.card(
         onTap: () => tapped = true,
         child: Text('Tap me'),
       ),
     );
     expect(find.byType(GestureDetector), findsOneWidget);
     await tester.tap(find.byType(GestureDetector));
     expect(tapped, true);
   });
   ```

3. **Sin GestureDetector cuando no interactivo**:
   ```dart
   testWidgets('does not wrap in GestureDetector when onTap null', (tester) async {
     await tester.pumpWidget(
       ConfigurableStyledContainer.card(
         child: Text('Static'),
       ),
     );
     expect(find.byType(GestureDetector), findsNothing);
   });
   ```

### 11.2. Test cases para SectionHeader

1. **Colores por default**:
   ```dart
   testWidgets('uses white colors by default', (tester) async {
     await tester.pumpWidget(
       SectionHeader(
         icon: Icons.star,
         title: 'Title',
         subtitle: 'Subtitle',
       ),
     );
     // Verificar que icono y textos son blancos
   });
   ```

2. **Colores personalizados**:
   ```dart
   testWidgets('uses custom colors when provided', (tester) async {
     await tester.pumpWidget(
       SectionHeader(
         icon: Icons.star,
         title: 'Title',
         subtitle: 'Subtitle',
         iconColor: Colors.red,
         textColor: Colors.black,
       ),
     );
     // Verificar colores personalizados
   });
   ```

---

## 12. PERFORMANCE

### 12.1. Optimizaciones implementadas

1. **Constructor const**: Permite instancias constantes
2. **StatelessWidget**: No tiene estado interno
3. **GestureDetector condicional**: Solo se añade cuando es necesario
4. **Builders separados**: Construye solo el estilo necesario

### 12.2. Posibles mejoras

1. **Cachear decorations**:
   ```dart
   static final _headerDecoration = BoxDecoration(...);
   ```

2. **Usar const widgets donde sea posible**:
   ```dart
   const SizedBox(width: 16) // Ya implementado
   ```

---

## 13. POSIBLES MEJORAS (NO implementadas)

### 13.1. Más variantes de estilo

```dart
enum ConfigurableContainerStyle {
  header, card, info,
  warning,  // Fondo amarillo
  error,    // Fondo rojo
  success   // Fondo verde
}
```

### 13.2. Elevation configurable

```dart
final double? elevation;

BoxShadow? _getBoxShadow() {
  if (elevation == null) return null;
  return BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: elevation! * 2,
    offset: Offset(0, elevation!),
  );
}
```

### 13.3. Custom gradients

```dart
final List<Color>? gradientColors;
final AlignmentGeometry? gradientBegin;
final AlignmentGeometry? gradientEnd;
```

### 13.4. SectionHeader con trailing widget

```dart
class SectionHeader extends StatelessWidget {
  final Widget? trailing;  // Botón, badge, etc.

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ... icono y textos existentes
        if (trailing != null) trailing!,
      ],
    );
  }
}
```

---

## 14. RESUMEN

### 14.1. ConfigurableStyledContainer

**Propósito**: Contenedor configurable con 3 variantes de estilo visual

**Variantes**:
- **header**: Gradiente + sombra (prominente)
- **card**: Fondo claro + borde gris (neutral)
- **info**: Fondo azul claro + borde azul (informativo)

**Características**:
- Named constructors convenientes
- Interactividad opcional (onTap)
- Padding configurable
- Switch exhaustivo de estilos
- GestureDetector condicional

**Estructura típica**: Container estilizado → child

### 14.2. SectionHeader

**Propósito**: Header de sección con icono, título y subtítulo

**Características**:
- Icono en container semi-transparente
- Colores personalizables (default: blanco)
- Diseñado para fondos oscuros (gradientes)
- Layout horizontal con Expanded

**Estructura**: Row → Container(Icon) + Column(Título + Subtítulo)

### 14.3. Relación entre componentes

**Uso combinado típico**:
```dart
ConfigurableStyledContainer.header(
  child: SectionHeader(
    icon: Icons.event,
    title: 'Eventos',
    subtitle: 'Gestiona tus eventos',
  ),
)
```

---

**Fin de la documentación de configurable_styled_container.dart**
