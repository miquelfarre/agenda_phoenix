# Card Config - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/adaptive/configs/card_config.dart`
**Líneas**: 94
**Tipo**: Extension + Builder + Constantes
**Propósito**: Proporciona métodos de conveniencia, builder pattern y configuraciones predefinidas para crear AdaptiveCardConfig de forma fácil y consistente

## 2. CLASES CONTENIDAS

Este archivo contiene:
1. **AdaptiveCardConfigExtended** (líneas 4-25): Extension con factory methods
2. **CardConfigBuilder** (líneas 27-70): Clase builder pattern
3. **CardConfigs** (líneas 72-93): Clase con 8 configuraciones constantes predefinidas

---

## 3. EXTENSION: AdaptiveCardConfigExtended

### Información
**Líneas**: 4-25
**Tipo**: Extension on AdaptiveCardConfig
**Propósito**: Añade métodos estáticos factory para crear configuraciones comunes

**Declaración**:
```dart
extension AdaptiveCardConfigExtended on AdaptiveCardConfig { ... }
```

### Métodos estáticos (líneas 5-24)

Todos los métodos son estáticos y retornan `AdaptiveCardConfig`:

#### 1. floating() (línea 5)
```dart
static AdaptiveCardConfig floating() => const AdaptiveCardConfig(
  variant: CardVariant.elevated,
  margin: EdgeInsets.all(16.0),
  borderRadius: BorderRadius.all(Radius.circular(16.0)),
  showShadow: true,
  selectable: false,
  elevation: 8.0
)
```
**Uso**: Tarjetas flotantes prominentes
**Características**: Elevation alta (8.0), margen grande (16px), radio grande (16px)

#### 2. compact() (línea 7)
```dart
static AdaptiveCardConfig compact() => const AdaptiveCardConfig(
  variant: CardVariant.listItem,
  margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
  borderRadius: BorderRadius.all(Radius.circular(6.0)),
  showShadow: false,
  selectable: false
)
```
**Uso**: Tarjetas compactas para listas densas
**Características**: Margen vertical pequeño (2px), sin sombra, radio pequeño (6px)

#### 3. action() (línea 9)
```dart
static AdaptiveCardConfig action() => const AdaptiveCardConfig(
  variant: CardVariant.elevated,
  margin: EdgeInsets.all(12.0),
  borderRadius: BorderRadius.all(Radius.circular(12.0)),
  showShadow: true,
  selectable: false,
  elevation: 4.0
)
```
**Uso**: Tarjetas de acción (botones grandes, CTAs)
**Características**: Elevation media (4.0), margen medio (12px), radio medio (12px)

#### 4. modal() (línea 11)
```dart
static AdaptiveCardConfig modal() => const AdaptiveCardConfig(
  variant: CardVariant.elevated,
  margin: EdgeInsets.all(24.0),
  borderRadius: BorderRadius.all(Radius.circular(20.0)),
  showShadow: true,
  selectable: false,
  elevation: 12.0
)
```
**Uso**: Tarjetas para modales
**Características**: Elevation máxima (12.0), margen máximo (24px), radio máximo (20px)

#### 5. subtle() (línea 13)
```dart
static AdaptiveCardConfig subtle() => const AdaptiveCardConfig(
  variant: CardVariant.simple,
  margin: EdgeInsets.all(4.0),
  borderRadius: BorderRadius.all(Radius.circular(4.0)),
  showShadow: false,
  selectable: false
)
```
**Uso**: Tarjetas sutiles, poco prominentes
**Características**: Sin sombra, margen mínimo (4px), radio mínimo (4px), variante simple

#### 6. media() (línea 15)
```dart
static AdaptiveCardConfig media() => const AdaptiveCardConfig(
  variant: CardVariant.elevated,
  margin: EdgeInsets.all(8.0),
  borderRadius: BorderRadius.all(Radius.circular(8.0)),
  showShadow: true,
  selectable: false,
  elevation: 2.0
)
```
**Uso**: Tarjetas con contenido media (imágenes, videos)
**Características**: Elevation baja (2.0), márgenes estándar (8px), radio estándar (8px)

#### 7. notification() (línea 17)
```dart
static AdaptiveCardConfig notification() => const AdaptiveCardConfig(
  variant: CardVariant.elevated,
  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  borderRadius: BorderRadius.all(Radius.circular(12.0)),
  showShadow: true,
  selectable: false,
  elevation: 3.0
)
```
**Uso**: Tarjetas de notificación
**Características**: Elevation media-baja (3.0), márgenes horizontal 16px vertical 8px

#### 8. dashboard() (línea 19)
```dart
static AdaptiveCardConfig dashboard() => const AdaptiveCardConfig(
  variant: CardVariant.elevated,
  margin: EdgeInsets.all(16.0),
  borderRadius: BorderRadius.all(Radius.circular(12.0)),
  showShadow: true,
  selectable: false,
  elevation: 2.0
)
```
**Uso**: Tarjetas de dashboard/widgets
**Características**: Elevation baja (2.0), márgenes grandes (16px), radio medio (12px)

#### 9. settings() (línea 21)
```dart
static AdaptiveCardConfig settings() => const AdaptiveCardConfig(
  variant: CardVariant.simple,
  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
  borderRadius: BorderRadius.all(Radius.circular(8.0)),
  showShadow: false,
  selectable: false
)
```
**Uso**: Tarjetas en pantallas de configuración
**Características**: Sin sombra, variante simple, márgenes horizontal 16px vertical 4px

#### 10. custom() (líneas 23-24)
```dart
static AdaptiveCardConfig custom({
  CardVariant variant = CardVariant.simple,
  EdgeInsets? margin,
  BorderRadius? borderRadius,
  Color? backgroundColor,
  bool showShadow = false,
  bool selectable = false,
  double? elevation
}) => AdaptiveCardConfig(
  variant: variant,
  margin: margin ?? const EdgeInsets.all(8.0),
  borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(8.0)),
  backgroundColor: backgroundColor,
  showShadow: showShadow,
  selectable: selectable,
  elevation: elevation
)
```
**Uso**: Crear configuración personalizada con valores por defecto razonables
**Valores por defecto**:
- variant: CardVariant.simple
- margin: EdgeInsets.all(8.0)
- borderRadius: BorderRadius.all(Radius.circular(8.0))
- showShadow: false
- selectable: false

**Parámetros opcionales con defaults**:
- margin y borderRadius usan `??` operator con defaults
- Otros son opcionales normales

### Comparación de elevations

Ordenadas de menor a mayor:
1. **subtle, compact, settings**: Sin sombra (0.0)
2. **media, dashboard**: 2.0 (sombra sutil)
3. **notification**: 3.0 (sombra notable)
4. **action**: 4.0 (sombra media)
5. **floating**: 8.0 (sombra alta)
6. **modal**: 12.0 (sombra máxima)

### Comparación de márgenes

Ordenadas de menor a mayor:
1. **subtle**: 4px (todos los lados)
2. **compact**: horizontal 12px, vertical 2px
3. **media**: 8px (todos los lados)
4. **settings**: horizontal 16px, vertical 4px
5. **notification**: horizontal 16px, vertical 8px
6. **action**: 12px (todos los lados)
7. **dashboard, floating**: 16px (todos los lados)
8. **modal**: 24px (todos los lados)

### Comparación de borderRadius

Ordenadas de menor a mayor:
1. **subtle**: 4px
2. **compact**: 6px
3. **media, settings, custom default**: 8px
4. **action, dashboard, notification**: 12px
5. **floating**: 16px
6. **modal**: 20px

---

## 4. CLASE: CardConfigBuilder

### Información
**Líneas**: 27-70
**Tipo**: Builder pattern class
**Propósito**: Construir AdaptiveCardConfig usando fluent API (method chaining)

### Variables privadas (líneas 28-34)
- `_variant` (CardVariant, línea 28): Default `CardVariant.simple`
- `_margin` (EdgeInsets, línea 29): Default `EdgeInsets.all(8.0)`
- `_borderRadius` (BorderRadius, línea 30): Default `BorderRadius.all(Radius.circular(8.0))`
- `_backgroundColor` (Color?, línea 31): Default `null`
- `_showShadow` (bool, línea 32): Default `false`
- `_selectable` (bool, línea 33): Default `false`
- `_elevation` (double?, línea 34): Default `null`

**Valores por defecto**: Simple variant, sin sombra, margen 8px, radio 8px

### Métodos builder (líneas 36-66)

Todos los métodos retornan `this` para permitir chaining:

#### variant(CardVariant variant) (líneas 36-39)
```dart
CardConfigBuilder variant(CardVariant variant) {
  _variant = variant;
  return this;
}
```
**Propósito**: Establece la variante de la tarjeta

#### margin(EdgeInsets margin) (líneas 41-44)
```dart
CardConfigBuilder margin(EdgeInsets margin) {
  _margin = margin;
  return this;
}
```
**Propósito**: Establece el margen exterior

#### borderRadius(BorderRadius borderRadius) (líneas 46-49)
```dart
CardConfigBuilder borderRadius(BorderRadius borderRadius) {
  _borderRadius = borderRadius;
  return this;
}
```
**Propósito**: Establece el radio de los bordes

#### backgroundColor(Color color) (líneas 51-54)
```dart
CardConfigBuilder backgroundColor(Color color) {
  _backgroundColor = color;
  return this;
}
```
**Propósito**: Establece el color de fondo

#### shadow(bool show, {double? elevation}) (líneas 56-60)
```dart
CardConfigBuilder shadow(bool show, {double? elevation}) {
  _showShadow = show;
  _elevation = elevation;
  return this;
}
```
**Propósito**: Establece si muestra sombra y opcionalmente la elevation
**Parámetros**:
- `show` (required): Si muestra sombra
- `elevation` (optional): Nivel de elevation

**Uso**:
```dart
.shadow(true, elevation: 4.0)  // Con elevation específica
.shadow(true)                   // Con elevation por defecto
.shadow(false)                  // Sin sombra
```

#### selectable([bool selectable = true]) (líneas 62-65)
```dart
CardConfigBuilder selectable([bool selectable = true]) {
  _selectable = selectable;
  return this;
}
```
**Propósito**: Establece si la tarjeta es seleccionable
**Parámetro opcional**: Default true, permite `.selectable()` o `.selectable(false)`

### Método build() (líneas 67-69)
```dart
AdaptiveCardConfig build() {
  return AdaptiveCardConfig(
    variant: _variant,
    margin: _margin,
    borderRadius: _borderRadius,
    backgroundColor: _backgroundColor,
    showShadow: _showShadow,
    selectable: _selectable,
    elevation: _elevation
  );
}
```
**Propósito**: Construye el AdaptiveCardConfig final con los valores configurados

### Uso del builder

```dart
// Ejemplo de uso con chaining
final config = CardConfigBuilder()
    .variant(CardVariant.elevated)
    .margin(EdgeInsets.all(16.0))
    .borderRadius(BorderRadius.circular(12.0))
    .shadow(true, elevation: 4.0)
    .selectable()
    .build();

// Uso con AdaptiveCard
final card = AdaptiveCard(
  config: CardConfigBuilder()
      .variant(CardVariant.listItem)
      .shadow(true, elevation: 2.0)
      .build(),
  child: ListTile(title: Text('Item'))
);
```

---

## 5. CLASE: CardConfigs

### Información
**Líneas**: 72-93
**Tipo**: Clase con constantes estáticas
**Propósito**: Biblioteca de configuraciones predefinidas para casos de uso específicos de la app

**Total de configuraciones**: 8

### Configuraciones de lista (líneas 73-77)

#### eventListItem (línea 73)
```dart
static const eventListItem = AdaptiveCardConfig(
  variant: CardVariant.event,
  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
  borderRadius: BorderRadius.all(Radius.circular(12.0)),
  showShadow: true,
  selectable: false,
  elevation: 2.0
)
```
**Uso**: Items de lista de eventos
**Características**: Variante event, margen vertical 6px, elevation 2.0

#### contactListItem (línea 75)
```dart
static const contactListItem = AdaptiveCardConfig(
  variant: CardVariant.contact,
  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
  borderRadius: BorderRadius.all(Radius.circular(8.0)),
  showShadow: true,
  selectable: false,
  elevation: 1.0
)
```
**Uso**: Items de lista de contactos
**Características**: Variante contact, margen vertical 4px, elevation 1.0 (sutil)

#### groupListItem (línea 77)
```dart
static const groupListItem = AdaptiveCardConfig(
  variant: CardVariant.listItem,
  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
  borderRadius: BorderRadius.all(Radius.circular(10.0)),
  showShadow: true,
  selectable: false,
  elevation: 1.5
)
```
**Uso**: Items de lista de grupos
**Características**: Variante listItem, margen vertical 4px, elevation 1.5

### Configuraciones seleccionables (líneas 79-81)

#### selectableEvent (línea 79)
```dart
static const selectableEvent = AdaptiveCardConfig(
  variant: CardVariant.selectable,
  margin: EdgeInsets.all(8.0),
  borderRadius: BorderRadius.all(Radius.circular(8.0)),
  showShadow: false,
  selectable: true
)
```
**Uso**: Eventos seleccionables (ej: seleccionar múltiples para eliminar)
**Características**: selectable true, sin sombra, variante selectable

#### selectableContact (línea 81)
```dart
static const selectableContact = AdaptiveCardConfig(
  variant: CardVariant.selectable,
  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
  borderRadius: BorderRadius.all(Radius.circular(8.0)),
  showShadow: false,
  selectable: true
)
```
**Uso**: Contactos seleccionables
**Características**: selectable true, sin sombra

### Configuraciones de overlays (líneas 83-92)

#### bottomSheetCard (líneas 83-90)
```dart
static const bottomSheetCard = AdaptiveCardConfig(
  variant: CardVariant.elevated,
  margin: EdgeInsets.zero,
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(20.0),
    topRight: Radius.circular(20.0)
  ),
  showShadow: true,
  selectable: false,
  elevation: 8.0
)
```
**Uso**: Tarjetas para bottom sheets
**Características**:
- Sin margen (EdgeInsets.zero)
- Radio solo arriba (topLeft, topRight = 20px)
- Elevation alta (8.0)
- **Nota**: Esquinas inferiores cuadradas para adherirse a la parte inferior

#### dialogCard (línea 92)
```dart
static const dialogCard = AdaptiveCardConfig(
  variant: CardVariant.elevated,
  margin: EdgeInsets.all(24.0),
  borderRadius: BorderRadius.all(Radius.circular(16.0)),
  showShadow: true,
  selectable: false,
  elevation: 16.0
)
```
**Uso**: Tarjetas para diálogos
**Características**:
- Margen máximo (24px)
- Elevation máxima (16.0)
- Radio grande (16px)
- Más prominente que cualquier otra tarjeta

### Comparación de elevations en CardConfigs

Ordenadas de menor a mayor:
1. **selectableEvent, selectableContact**: 0.0 (sin sombra)
2. **contactListItem**: 1.0 (muy sutil)
3. **groupListItem**: 1.5 (sutil)
4. **eventListItem**: 2.0 (baja)
5. **bottomSheetCard**: 8.0 (alta)
6. **dialogCard**: 16.0 (máxima)

### Uso de CardConfigs

```dart
// Uso directo de constantes
final eventCard = AdaptiveCard(
  config: CardConfigs.eventListItem,
  child: EventWidget(event)
);

// En ListView
ListView.builder(
  itemBuilder: (context, index) => AdaptiveCard(
    config: CardConfigs.contactListItem,
    child: ContactTile(contact)
  )
)

// Bottom sheet
showModalBottomSheet(
  builder: (context) => AdaptiveCard(
    config: CardConfigs.bottomSheetCard,
    child: BottomSheetContent()
  )
)
```

---

## 6. DEPENDENCIAS

### Packages externos:
- `flutter/material.dart`: EdgeInsets, BorderRadius, Radius, Color

### Imports internos:
- `../adaptive_card.dart`: AdaptiveCardConfig, CardVariant

---

## 7. CARACTERÍSTICAS TÉCNICAS

### Extension methods:
- Usa extension para añadir métodos estáticos a AdaptiveCardConfig
- No modifica la clase original
- Sintaxis: `AdaptiveCardConfigExtended.floating()`

### Constantes const:
- Todas las configuraciones en CardConfigs son const
- Todas las configs en extension (excepto custom) son const
- Optimización de compilación
- No se crean nuevas instancias en cada uso

### BorderRadius asimétrico:
- bottomSheetCard usa `BorderRadius.only()`
- Solo esquinas superiores redondeadas
- Esquinas inferiores cuadradas (0px implícito)
- Permite adherir el bottom sheet a la parte inferior de la pantalla

### EdgeInsets patterns:
- **EdgeInsets.zero**: Sin margen (bottomSheetCard)
- **EdgeInsets.all()**: Margen uniforme
- **EdgeInsets.symmetric()**: Margen horizontal/vertical diferente

### Valores de elevation:
- **0.0**: Sin sombra (flat)
- **1.0-2.0**: Sombra sutil (list items)
- **3.0-4.0**: Sombra notable (notifications, actions)
- **8.0**: Sombra alta (floating, bottom sheets)
- **12.0-16.0**: Sombra máxima (modals, dialogs)

### Builder pattern con shadow:
- Método `shadow(bool, {double?})` combina dos configuraciones
- Permite: `.shadow(true, elevation: 4.0)` o `.shadow(true)`
- Named optional parameter para elevation
- Más ergonómico que dos métodos separados

### selectable con default:
- `.selectable()` equivale a `.selectable(true)`
- `.selectable(false)` para desactivar
- Sintaxis conveniente para caso común (true)

### custom con null-aware operators:
- `margin ?? const EdgeInsets.all(8.0)`
- `borderRadius ?? const BorderRadius.all(Radius.circular(8.0))`
- Proporciona defaults razonables
- Permite override selectivo

### Configuraciones por categoría en extension:
- **Elevation**: subtle (0), media (2), action (4), floating (8), modal (12)
- **Densidad**: compact (2px vert), normal (4-8px vert), spacious (16-24px)
- **Propósito**: media, notification, dashboard, settings

### Configuraciones por categoría en CardConfigs:
- **List items**: event, contact, group
- **Selectable**: selectableEvent, selectableContact
- **Overlays**: bottomSheet, dialog

### Consistencia de naming:
- Extension: nombres descriptivos del uso (floating, compact, modal)
- CardConfigs: nombres específicos de dominio (eventListItem, contactListItem)

### Elevation progresión:
- Lista (1.0-2.0) < Notificación (3.0) < Acción (4.0) < Floating (8.0) < Bottom Sheet (8.0) < Modal (12.0) < Dialog (16.0)
- Jerarquía visual clara
- Elementos más importantes tienen más elevation

### Margen patterns en CardConfigs:
- List items: horizontal 16px (consistente), vertical varía (4-6px)
- Selectables: flexible (8px all o 16px horiz)
- Overlays: extremos (0px o 24px)

### Variantes utilizadas:
- **simple**: subtle, settings (sin sombra, planos)
- **listItem**: compact, groupListItem (listas)
- **selectable**: selectableEvent, selectableContact (multi-selección)
- **elevated**: resto (con sombra)
- **event, contact**: específicos de dominio

### Builder defaults match extension custom:
- Ambos usan EdgeInsets.all(8.0) como default
- Ambos usan BorderRadius.all(Radius.circular(8.0))
- Consistencia entre métodos de creación

### Ventajas de este archivo:
1. **Consistencia**: Mismas configs para eventos/contactos en toda la app
2. **Mantenibilidad**: Cambiar elevation de eventos cambia todas las instancias
3. **Descubribilidad**: Autocompletado muestra todas las opciones predefinidas
4. **Escalabilidad**: Fácil añadir nuevas configuraciones
5. **Flexibilidad**: Extension + Builder + Constantes cubren todos los casos

### Uso recomendado:
- **CardConfigs**: Para casos específicos de la app (event, contact, group)
- **Extension methods**: Para patrones generales (floating, compact, modal)
- **Builder**: Para casos únicos que necesitan customización
- **custom()**: Para customización rápida con defaults

### Diferencias con button_config:
- Cards tienen margen, buttons no
- Cards tienen borderRadius completo, buttons solo del borde
- Cards tienen elevation explícita, buttons calculan según plataforma
- Cards más enfocados en containers, buttons en interacción
