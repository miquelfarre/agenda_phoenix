# BaseCard y AdaptiveContainer - Documentación Detallada

## 1. Información General

**Ubicación**: `/lib/widgets/base_card.dart`

**Propósito**: Proporciona dos widgets base para crear contenedores y cards en la aplicación con soporte adaptativo según la plataforma (iOS vs Android).

**Tipo de archivo**: Multi-class widget file (2 StatelessWidgets)

**Líneas de código**: 50

**Clases contenidas**:
1. BaseCard (líneas 5-33): Card con soporte para tap y personalización
2. AdaptiveContainer (líneas 35-49): Contenedor adaptativo según plataforma

---

## 2. Clase BaseCard (Líneas 5-33)

### 2.1. Propósito

Card base con soporte para interacción táctil (onTap), personalización de margin, padding, elevation y color de fondo. Combina Container, GestureDetector y Padding para crear una card completa.

### 2.2. Jerarquía de clases

```dart
class BaseCard extends StatelessWidget
```

**Herencia**: StatelessWidget (widget inmutable de Flutter)

### 2.3. Propiedades (Líneas 6-11)

```dart
final Widget child;
final VoidCallback? onTap;
final EdgeInsetsGeometry? margin;
final EdgeInsetsGeometry? padding;
final double? elevation;
final Color? backgroundColor;
```

**Propiedades**:

1. **`child`** (línea 6): Widget
   - **Required**: Sí
   - **Propósito**: Contenido de la card
   - **Tipo**: Cualquier widget

2. **`onTap`** (línea 7): VoidCallback?
   - **Required**: No (nullable)
   - **Propósito**: Callback ejecutado cuando se toca la card
   - **Tipo**: Función sin parámetros que retorna void
   - **Uso**: Navegación, acciones, selección

3. **`margin`** (línea 8): EdgeInsetsGeometry?
   - **Required**: No (nullable)
   - **Propósito**: Margen externo de la card
   - **Default**: Calculado según plataforma (ver build method)

4. **`padding`** (línea 9): EdgeInsetsGeometry?
   - **Required**: No (nullable)
   - **Propósito**: Padding interno de la card (entre el borde y el child)
   - **Default**: `AppStyles.cardPadding`

5. **`elevation`** (línea 10): double?
   - **Required**: No (nullable)
   - **Propósito**: Elevación de la card (sombra)
   - **Nota**: Propiedad NO utilizada en el build method actual (posible legacy code)

6. **`backgroundColor`** (línea 11): Color?
   - **Required**: No (nullable)
   - **Propósito**: Color de fondo personalizado
   - **Default**: Color de `AppStyles.cardDecoration`

### 2.4. Constructor (Línea 13)

```dart
const BaseCard({
  super.key,
  required this.child,
  this.onTap,
  this.margin,
  this.padding,
  this.elevation,
  this.backgroundColor
});
```

**Tipo**: Constructor const

**Parámetros**:
- `super.key`: Key? (opcional, para identificación de widget)
- `child`: Widget (required)
- `onTap`: VoidCallback? (opcional)
- `margin`: EdgeInsetsGeometry? (opcional)
- `padding`: EdgeInsetsGeometry? (opcional)
- `elevation`: double? (opcional, NO usado actualmente)
- `backgroundColor`: Color? (opcional)

**Uso típico**:
```dart
BaseCard(
  onTap: () => print('Card tapped'),
  margin: EdgeInsets.all(8),
  child: Text('Content'),
)
```

### 2.5. Método `build()` (Líneas 16-32)

```dart
@override
Widget build(BuildContext context) {
  final isIOS = PlatformWidgets.isIOS;

  final cardMargin = margin ?? EdgeInsets.symmetric(
    horizontal: isIOS ? 16.0 : 8.0,
    vertical: 4.0
  );

  final cardPadding = padding ?? AppStyles.cardPadding;

  return Container(
    margin: cardMargin,
    decoration: AppStyles.cardDecoration.copyWith(
      color: backgroundColor ?? AppStyles.cardDecoration.color
    ),
    child: GestureDetector(
      key: key != null ? Key('${key.toString()}_gesture') : null,
      onTap: onTap,
      child: Padding(
        padding: cardPadding,
        child: child
      ),
    ),
  );
}
```

**Estructura del widget tree**:
```
Container (margin + decoration + backgroundColor)
└── GestureDetector (onTap)
    └── Padding (cardPadding)
        └── child
```

#### 2.5.1. Detección de plataforma (Línea 17)

```dart
final isIOS = PlatformWidgets.isIOS;
```

**Propósito**: Determinar si la plataforma es iOS para adaptar el margin

**Fuente**: `PlatformWidgets.isIOS` (clase de utilidad del proyecto)

**Uso**: Solo usado para calcular el margin horizontal por defecto

#### 2.5.2. Cálculo de margin (Líneas 19)

```dart
final cardMargin = margin ?? EdgeInsets.symmetric(
  horizontal: isIOS ? 16.0 : 8.0,
  vertical: 4.0
);
```

**Lógica**:
- Si `margin` fue proporcionado: usa ese valor
- Si `margin` es null: usa margin adaptativo

**Valores por defecto adaptativos**:

| Plataforma | Horizontal | Vertical |
|------------|------------|----------|
| iOS | 16.0 | 4.0 |
| Android | 8.0 | 4.0 |

**Motivo**: iOS Human Interface Guidelines prefiere más espacio horizontal (16) que Material Design (8)

**Vertical**: Constante 4.0 en ambas plataformas (spacing entre cards en una lista)

#### 2.5.3. Cálculo de padding (Línea 21)

```dart
final cardPadding = padding ?? AppStyles.cardPadding;
```

**Lógica**:
- Si `padding` fue proporcionado: usa ese valor
- Si `padding` es null: usa `AppStyles.cardPadding`

**AppStyles.cardPadding**: Valor definido en `/ui/styles/app_styles.dart` (probablemente EdgeInsets.all(16) o similar)

**Diferencia con margin**:
- margin: Espacio EXTERNO (entre cards)
- padding: Espacio INTERNO (entre borde de card y contenido)

#### 2.5.4. Container (Líneas 23-31)

```dart
return Container(
  margin: cardMargin,
  decoration: AppStyles.cardDecoration.copyWith(
    color: backgroundColor ?? AppStyles.cardDecoration.color
  ),
  child: GestureDetector(...),
);
```

**Propiedades del Container**:

1. **`margin`** (línea 24):
   - Usa `cardMargin` calculado (adaptativo o custom)

2. **`decoration`** (línea 25):
   - Base: `AppStyles.cardDecoration` (probablemente incluye borderRadius, border, shadow)
   - Modificación: `.copyWith(color: backgroundColor ?? AppStyles.cardDecoration.color)`
   - Si `backgroundColor` fue proporcionado: usa ese color
   - Si no: mantiene el color original de `AppStyles.cardDecoration`

**Nota sobre elevation**: La propiedad `elevation` del constructor NO se usa aquí
- Posible legacy code de una versión anterior
- La elevación/shadow se maneja probablemente en `AppStyles.cardDecoration`

#### 2.5.5. GestureDetector (Líneas 26-30)

```dart
child: GestureDetector(
  key: key != null ? Key('${key.toString()}_gesture') : null,
  onTap: onTap,
  child: Padding(...)
),
```

**Propiedades**:

1. **`key`** (línea 27):
   ```dart
   key: key != null ? Key('${key.toString()}_gesture') : null
   ```
   - Si el BaseCard tiene una key: crea una key derivada con sufijo `_gesture`
   - Si no tiene key: GestureDetector tampoco tiene key
   - **Propósito**: Útil para testing (encontrar el GestureDetector específico)
   - **Ejemplo**: Si BaseCard tiene `Key('event_card_1')`, GestureDetector tendrá `Key('event_card_1_gesture')`

2. **`onTap`** (línea 28):
   - Usa el callback proporcionado en el constructor
   - Puede ser null (card no interactiva)

3. **`child`** (línea 29):
   - Padding con el contenido final

**Motivo del GestureDetector**:
- Maneja el tap en toda la card
- Alternativa a InkWell/InkResponse (sin efecto de ripple)

#### 2.5.6. Padding (Línea 29)

```dart
child: Padding(
  padding: cardPadding,
  child: child
)
```

**Propósito**: Agregar espacio interno entre el borde de la card y el contenido

**padding**: Usa `cardPadding` calculado (AppStyles.cardPadding o custom)

**child**: El widget hijo proporcionado en el constructor

---

## 3. Clase AdaptiveContainer (Líneas 35-49)

### 3.1. Propósito

Contenedor simple que adapta su decoración según la plataforma (iOS vs Android). Más simple que BaseCard: no tiene soporte para tap ni elevation.

### 3.2. Jerarquía de clases

```dart
class AdaptiveContainer extends StatelessWidget
```

**Herencia**: StatelessWidget

### 3.3. Propiedades (Líneas 36-39)

```dart
final Widget child;
final EdgeInsetsGeometry? padding;
final EdgeInsetsGeometry? margin;
final Color? backgroundColor;
```

**Propiedades**:

1. **`child`** (línea 36): Widget
   - **Required**: Sí
   - **Propósito**: Contenido del contenedor

2. **`padding`** (línea 37): EdgeInsetsGeometry?
   - **Required**: No (nullable)
   - **Propósito**: Padding interno
   - **Default**: `AppStyles.cardPadding`

3. **`margin`** (línea 38): EdgeInsetsGeometry?
   - **Required**: No (nullable)
   - **Propósito**: Margen externo
   - **Default**: null (sin margin)

4. **`backgroundColor`** (línea 39): Color?
   - **Required**: No (nullable)
   - **Propósito**: Color de fondo (NO usado actualmente en build method)
   - **Nota**: Legacy code, no tiene efecto

**Diferencias con BaseCard**:
- NO tiene `onTap` (no interactivo)
- NO tiene `elevation` (ni siquiera como legacy)
- `backgroundColor` está definido pero NO se usa

### 3.4. Constructor (Línea 41)

```dart
const AdaptiveContainer({
  super.key,
  required this.child,
  this.padding,
  this.margin,
  this.backgroundColor
});
```

**Tipo**: Constructor const

**Parámetros**:
- `super.key`: Key? (opcional)
- `child`: Widget (required)
- `padding`: EdgeInsetsGeometry? (opcional)
- `margin`: EdgeInsetsGeometry? (opcional)
- `backgroundColor`: Color? (opcional, NO usado)

**Uso típico**:
```dart
AdaptiveContainer(
  padding: EdgeInsets.all(16),
  child: Text('Content'),
)
```

### 3.5. Método `build()` (Líneas 44-48)

```dart
@override
Widget build(BuildContext context) {
  final isIOS = PlatformWidgets.isIOS;

  return Container(
    padding: padding ?? AppStyles.cardPadding,
    margin: margin,
    decoration: isIOS ? AppStyles.iOSCardDecoration : AppStyles.cardDecoration,
    child: child
  );
}
```

**Estructura del widget tree**:
```
Container (padding + margin + decoration adaptativa)
└── child
```

#### 3.5.1. Detección de plataforma (Línea 45)

```dart
final isIOS = PlatformWidgets.isIOS;
```

**Propósito**: Determinar qué decoración usar

**Uso**: Solo para seleccionar entre `iOSCardDecoration` y `cardDecoration`

#### 3.5.2. Container (Líneas 47)

```dart
return Container(
  padding: padding ?? AppStyles.cardPadding,
  margin: margin,
  decoration: isIOS ? AppStyles.iOSCardDecoration : AppStyles.cardDecoration,
  child: child
);
```

**Propiedades**:

1. **`padding`** (línea 47):
   - Si `padding` fue proporcionado: usa ese valor
   - Si no: usa `AppStyles.cardPadding`
   - **Nota**: Mismo default que BaseCard

2. **`margin`** (línea 47):
   - Usa el margin proporcionado (puede ser null)
   - **Diferencia con BaseCard**: NO hay margin por defecto adaptativo
   - Si es null: Container no tiene margin

3. **`decoration`** (línea 47):
   ```dart
   decoration: isIOS ? AppStyles.iOSCardDecoration : AppStyles.cardDecoration
   ```

   **Decoraciones adaptativas**:
   - **iOS**: `AppStyles.iOSCardDecoration`
   - **Android**: `AppStyles.cardDecoration`

   **Diferencia probable entre decoraciones**:
   - iOS: Sin elevación, border más prominente, borderRadius mayor
   - Android: Con elevación (shadow), borderRadius menor

4. **`child`** (línea 47):
   - Widget hijo proporcionado directamente (sin GestureDetector ni Padding adicional)

**Nota sobre backgroundColor**: La propiedad `backgroundColor` del constructor NO se usa
- Probablemente legacy code
- El color viene de la decoración seleccionada

---

## 4. Comparación entre BaseCard y AdaptiveContainer

### 4.1. Tabla comparativa de propiedades

| Propiedad | BaseCard | AdaptiveContainer | Notas |
|-----------|----------|-------------------|-------|
| child | ✓ (required) | ✓ (required) | Ambas lo requieren |
| onTap | ✓ (nullable) | ✗ | Solo BaseCard es interactiva |
| margin | ✓ (nullable) | ✓ (nullable) | BaseCard tiene default adaptativo, AdaptiveContainer no |
| padding | ✓ (nullable) | ✓ (nullable) | Ambas usan AppStyles.cardPadding como default |
| elevation | ✓ (nullable) | ✗ | BaseCard la define pero NO la usa (legacy) |
| backgroundColor | ✓ (nullable) | ✓ (nullable) | BaseCard la usa, AdaptiveContainer NO (legacy) |

### 4.2. Tabla comparativa de comportamiento

| Aspecto | BaseCard | AdaptiveContainer |
|---------|----------|-------------------|
| **Decoración** | Usa `AppStyles.cardDecoration` | Usa decoración adaptativa (iOSCardDecoration vs cardDecoration) |
| **Interactividad** | Sí (GestureDetector) | No |
| **Margin por defecto** | Adaptativo (iOS: 16/8, Android: 8/8) | Sin margin por defecto |
| **Padding por defecto** | AppStyles.cardPadding | AppStyles.cardPadding |
| **Estructura** | Container > GestureDetector > Padding > child | Container > child |
| **Key derivada** | Sí (para GestureDetector) | No |

### 4.3. Casos de uso recomendados

**BaseCard**:
- Cards interactivas (tap para navegar o ejecutar acción)
- Cards en listas o grids con margin automático
- Cuando necesitas personalizar backgroundColor
- Event cards, contact cards, subscription cards

**AdaptiveContainer**:
- Contenedores estáticos (sin interacción)
- Cuando quieres decoración específica de plataforma
- Secciones de pantalla que no necesitan tap
- Headers, separadores estilizados, paneles informativos

### 4.4. Uso combinado

```dart
// BaseCard con AdaptiveContainer interno (posible, pero redundante)
BaseCard(
  onTap: () => print('Tapped'),
  child: AdaptiveContainer(
    child: Text('Content')
  )
)

// Mejor: Usar solo BaseCard
BaseCard(
  onTap: () => print('Tapped'),
  child: Text('Content')
)
```

---

## 5. Dependencias (Líneas 1-3)

```dart
import 'package:flutter/widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
```

### 5.1. Importaciones

1. **`package:flutter/widgets.dart`** (línea 1):
   - Proporciona: StatelessWidget, Widget, BuildContext, Container, GestureDetector, Padding, EdgeInsetsGeometry, EdgeInsets, VoidCallback, Key
   - Widget base de Flutter

2. **`package:eventypop/ui/styles/app_styles.dart`** (línea 2):
   - Proporciona:
     - `AppStyles.cardPadding`: EdgeInsets por defecto para cards
     - `AppStyles.cardDecoration`: BoxDecoration para Android
     - `AppStyles.iOSCardDecoration`: BoxDecoration para iOS
   - Estilos centralizados de la aplicación

3. **`package:eventypop/ui/helpers/platform/platform_widgets.dart`** (línea 3):
   - Proporciona: `PlatformWidgets.isIOS` (bool)
   - Detección de plataforma

### 5.2. Dependencias externas

**AppStyles esperado** (no visible en este archivo):
```dart
class AppStyles {
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  );

  static final BoxDecoration iOSCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
      color: Colors.grey.withOpacity(0.3),
      width: 0.5,
    ),
  );
}
```

**PlatformWidgets esperado**:
```dart
class PlatformWidgets {
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }
}
```

---

## 6. Características Técnicas

### 6.1. Inmutabilidad

**Todas las propiedades son final**:
- Ambas clases son StatelessWidget con propiedades inmutables
- Permite optimizaciones de Flutter (const constructors)

### 6.2. Constructores const

**Ambas clases tienen constructor const**:
- `const BaseCard({...})`
- `const AdaptiveContainer({...})`

**Beneficio**: Instancias pueden crearse en tiempo de compilación si todos los parámetros son const

**Ejemplo**:
```dart
const BaseCard(
  child: Text('Static content')
) // Const instance si Text también es const
```

### 6.3. Null safety

**Uso de nullables**:
- `onTap`: VoidCallback? (puede ser null para cards no interactivas)
- `margin`: EdgeInsetsGeometry? (null si se usa default)
- `padding`: EdgeInsetsGeometry? (null si se usa default)
- `elevation`: double? (null, no usado)
- `backgroundColor`: Color? (null si se usa default)

**Operador ??**:
```dart
margin ?? EdgeInsets.symmetric(...)  // Si margin es null, usa default
padding ?? AppStyles.cardPadding     // Si padding es null, usa default
backgroundColor ?? AppStyles.cardDecoration.color  // Si backgroundColor es null, usa color de decoración
```

### 6.4. Adaptatividad de plataforma

**BaseCard**:
- Solo adapta el margin horizontal (16 vs 8)
- Decoración NO adaptativa (usa solo AppStyles.cardDecoration)

**AdaptiveContainer**:
- Decoración completamente adaptativa (iOSCardDecoration vs cardDecoration)
- Margin NO adaptativo (usa el proporcionado o null)

**Inconsistencia**: BaseCard adapta margin pero no decoración, AdaptiveContainer adapta decoración pero no margin

### 6.5. Performance

**BaseCard**:
- 4 widgets en el árbol: Container > GestureDetector > Padding > child
- Costo adicional del GestureDetector (mínimo si onTap es null)

**AdaptiveContainer**:
- 2 widgets en el árbol: Container > child
- Más eficiente (menos nodos)

**Recomendación**: Si no necesitas interactividad, usa AdaptiveContainer

### 6.6. Testing

**BaseCard con key derivada**:
```dart
testWidgets('BaseCard gesture has derived key', (tester) async {
  await tester.pumpWidget(
    BaseCard(
      key: Key('my_card'),
      child: Text('Content'),
    )
  );

  expect(find.byKey(Key('my_card_gesture')), findsOneWidget);
});
```

**Beneficio**: Facilita testing de interactividad

### 6.7. Code smells (posibles problemas)

1. **Propiedad elevation no usada** en BaseCard:
   - Definida en constructor
   - Nunca usada en build()
   - Posible legacy code

2. **Propiedad backgroundColor no usada** en AdaptiveContainer:
   - Definida en constructor
   - Nunca usada en build()
   - Posible legacy code

3. **Inconsistencia en adaptatividad**:
   - BaseCard: margin adaptativo, decoración fija
   - AdaptiveContainer: decoración adaptativa, margin fijo
   - Podría ser confuso para desarrolladores

---

## 7. Uso en la Aplicación

### 7.1. Uso típico de BaseCard

```dart
// En una lista de eventos
ListView.builder(
  itemBuilder: (context, index) {
    final event = events[index];
    return BaseCard(
      onTap: () => Navigator.push(...),
      child: Column(
        children: [
          Text(event.title),
          Text(event.date),
        ],
      ),
    );
  },
)
```

### 7.2. Uso típico de AdaptiveContainer

```dart
// Header de una sección
AdaptiveContainer(
  margin: EdgeInsets.all(8),
  child: Row(
    children: [
      Icon(Icons.info),
      SizedBox(width: 8),
      Text('Information Section'),
    ],
  ),
)
```

### 7.3. Personalización de BaseCard

```dart
BaseCard(
  margin: EdgeInsets.all(16),  // Custom margin
  padding: EdgeInsets.all(24),  // Custom padding
  backgroundColor: Colors.blue.shade50,  // Custom color
  onTap: () => print('Custom card tapped'),
  child: Text('Custom styled card'),
)
```

### 7.4. Sin interacción

```dart
// BaseCard sin onTap (no interactiva)
BaseCard(
  child: Text('Static card'),
) // onTap es null, pero GestureDetector sigue en el árbol
```

**Nota**: Si no necesitas interactividad, mejor usar AdaptiveContainer (más eficiente)

---

## 8. Posibles Mejoras (NO implementadas)

### 8.1. Unificar BaseCard y AdaptiveContainer

```dart
// Hipotético: Card unificada con todas las características
class UnifiedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool useAdaptiveDecoration; // Nueva propiedad

  // ...

  @override
  Widget build(BuildContext context) {
    final isIOS = PlatformWidgets.isIOS;

    final decoration = useAdaptiveDecoration
        ? (isIOS ? AppStyles.iOSCardDecoration : AppStyles.cardDecoration)
        : AppStyles.cardDecoration;

    // Resto de la implementación
  }
}
```

### 8.2. Usar elevation

```dart
// Si se implementara elevation (Material)
Widget build(BuildContext context) {
  return Material(
    elevation: elevation ?? (PlatformWidgets.isIOS ? 0 : 2),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      // ...
    ),
  );
}
```

### 8.3. Feedback visual al tap

```dart
// Agregar InkWell para ripple effect
Widget build(BuildContext context) {
  return Container(
    margin: cardMargin,
    decoration: ...,
    child: Material(
      color: Colors.transparent,
      child: InkWell(  // En lugar de GestureDetector
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(...),
      ),
    ),
  );
}
```

---

## 9. Resumen

### 9.1. BaseCard

**Propósito**: Card interactiva con tap, margin adaptativo y personalización de estilo

**Características**:
- Soporte para onTap (GestureDetector)
- Margin adaptativo según plataforma (iOS: 16, Android: 8)
- Padding default de AppStyles.cardPadding
- Personalización de backgroundColor
- Key derivada para GestureDetector (testing)
- Decoración fija (AppStyles.cardDecoration)

**Estructura**: Container > GestureDetector > Padding > child

**Uso**: Cards interactivas en listas, grids, o pantallas

### 9.2. AdaptiveContainer

**Propósito**: Contenedor estático con decoración adaptativa según plataforma

**Características**:
- Sin interactividad (no onTap)
- Decoración adaptativa (iOSCardDecoration vs cardDecoration)
- Padding default de AppStyles.cardPadding
- Sin margin por defecto

**Estructura**: Container > child

**Uso**: Secciones estáticas, headers, paneles informativos

### 9.3. Elección

**Usa BaseCard si**:
- Necesitas onTap
- Quieres margin automático adaptativo
- Card en lista o grid

**Usa AdaptiveContainer si**:
- No necesitas interactividad
- Quieres decoración específica de plataforma
- Contenedor estático

---

**Fin de la documentación de base_card.dart**
