# StyledContainer - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/styled_container.dart`
**Líneas**: 24
**Tipo**: StatelessWidget
**Propósito**: Container básico estilizado con padding, color, borderRadius, sombra y borde personalizables, con valores por defecto de AppStyles

## 2. CLASE Y PROPIEDADES

### StyledContainer (líneas 5-23)

**Propiedades**:
- `child` (Widget, required, línea 6): Contenido del container
- `padding` (EdgeInsets?, línea 7): Padding interno (default: AppStyles.cardPadding)
- `color` (Color?, línea 8): Color de fondo (default: AppStyles.cardBackgroundColor)
- `borderRadius` (BorderRadius?, línea 9): Radio de borde (default: AppStyles.cardRadius)
- `boxShadow` (List<BoxShadow>?, línea 10): Sombras (default: AppStyles.cardDecoration.boxShadow)
- `border` (BoxBorder?, línea 11): Borde (default: null)

## 3. CONSTRUCTOR

```dart
const StyledContainer({
  super.key,
  required this.child,
  this.padding,
  this.color,
  this.borderRadius,
  this.boxShadow,
  this.border
})
```

**Tipo**: Constructor const
**Único parámetro required**: child

## 4. MÉTODO BUILD (líneas 15-22)

```dart
@override
Widget build(BuildContext context) {
  return Container(
    padding: padding ?? AppStyles.cardPadding,
    decoration: BoxDecoration(
      color: color ?? AppStyles.cardBackgroundColor,
      borderRadius: borderRadius ?? AppStyles.cardRadius,
      boxShadow: boxShadow ?? AppStyles.cardDecoration.boxShadow,
      border: border
    ),
    child: child,
  );
}
```

**Estructura**: `Container` simple con BoxDecoration

**Lógica de defaults**:
- **padding**: Si null → `AppStyles.cardPadding` (probablemente EdgeInsets.all(16))
- **color**: Si null → `AppStyles.cardBackgroundColor` (blanco o gris claro)
- **borderRadius**: Si null → `AppStyles.cardRadius` (BorderRadius.circular(12))
- **boxShadow**: Si null → `AppStyles.cardDecoration.boxShadow` (sombra sutil)
- **border**: Si null → null (sin borde)

**Nota**: `border` no tiene default de AppStyles, es el único opcional sin fallback

## 5. CARACTERÍSTICAS TÉCNICAS

### 5.1. Cascading defaults con ??

Todos los parámetros usan el operador `??` para proporcionar defaults de AppStyles:

```dart
padding ?? AppStyles.cardPadding
```

Si el usuario proporciona valor → usa ese valor
Si el usuario pasa null o no proporciona → usa default de AppStyles

### 5.2. Constructor const

Permite crear instancias constantes cuando todos los parámetros son const:

```dart
const StyledContainer(
  child: Text('Static content'),
)
```

### 5.3. Widget base reutilizable

Este widget es usado como base por otros widgets:
- `ConfigurableStyledContainer` lo usa internamente
- `BaseCard` podría usarlo (aunque actualmente no)

**Patrón**: Componente base simple que otros wrappers especializan

### 5.4. BoxDecoration single-line

La decoración está en una sola línea larga (línea 19):
- Menos legible pero más compacto
- Todos los valores usan ?? operator

## 6. COMPARACIÓN CON OTROS CONTAINERS

### vs BaseCard:
- **StyledContainer**: Más simple, solo styling básico
- **BaseCard**: Incluye GestureDetector, margin adaptativo, key derivada

### vs AdaptiveContainer:
- **StyledContainer**: No es adaptativo, misma decoración en todas las plataformas
- **AdaptiveContainer**: Selecciona decoración según plataforma (iOS vs Android)

### vs ConfigurableStyledContainer:
- **StyledContainer**: Base simple, un solo estilo
- **ConfigurableStyledContainer**: Usa StyledContainer internamente, añade variantes (header, card, info)

## 7. DEPENDENCIAS

**Imports**:
```dart
import 'package:flutter/widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
```

**AppStyles usados**:
- `AppStyles.cardPadding`: EdgeInsets para padding
- `AppStyles.cardBackgroundColor`: Color de fondo
- `AppStyles.cardRadius`: BorderRadius
- `AppStyles.cardDecoration.boxShadow`: List<BoxShadow>

## 8. CASOS DE USO

### 8.1. Container con defaults

```dart
StyledContainer(
  child: Text('Contenido con styling por defecto'),
)
```

Resultado: Card con padding, color, borderRadius y sombra de AppStyles

### 8.2. Container con color personalizado

```dart
StyledContainer(
  color: Colors.blue.shade50,
  child: Text('Container azul claro'),
)
```

### 8.3. Container con borde

```dart
StyledContainer(
  border: Border.all(color: Colors.red, width: 2),
  child: Text('Container con borde rojo'),
)
```

### 8.4. Container sin sombra

```dart
StyledContainer(
  boxShadow: [],
  child: Text('Sin sombra'),
)
```

### 8.5. Container completamente personalizado

```dart
StyledContainer(
  padding: EdgeInsets.all(24),
  color: Colors.amber.shade100,
  borderRadius: BorderRadius.circular(20),
  boxShadow: [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 10,
      offset: Offset(0, 5),
    ),
  ],
  border: Border.all(color: Colors.amber, width: 3),
  child: Text('Completamente custom'),
)
```

## 9. TESTING

```dart
testWidgets('uses default styles when not provided', (tester) async {
  await tester.pumpWidget(
    StyledContainer(
      child: Text('Test'),
    ),
  );

  final container = tester.widget<Container>(
    find.byType(Container),
  );

  expect(container.padding, AppStyles.cardPadding);
});
```

## 10. RESUMEN

**Propósito**: Container base estilizado con defaults de AppStyles

**Características**:
- Padding, color, borderRadius, boxShadow, border personalizables
- Todos opcionales con defaults sensatos de AppStyles
- Constructor const
- Widget simple (solo 24 líneas)

**Uso**: Base para otros containers, wrapper simple para contenido estilizado

**Patrón**: Primitive component / building block

---

**Fin de la documentación de styled_container.dart**
