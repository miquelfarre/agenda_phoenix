# PlatformTheme - Documentación Detallada

## 1. Información General

**Ubicación**: `/lib/widgets/adaptive/platform_theme.dart`

**Propósito**: Clase de datos que encapsula la información de tema adaptativo según la plataforma (iOS vs Android) y el modo de apariencia (claro vs oscuro). Proporciona valores de diseño específicos de cada plataforma para mantener la consistencia visual con las guías de diseño nativas.

**Tipo de archivo**: Data class con factory constructor y computed properties

**Líneas de código**: 85

---

## 2. Clase PlatformTheme

### 2.1. Propósito

Clase inmutable que almacena información de tema y proporciona valores de diseño específicos de la plataforma. Utilizada por los widgets adaptativos para aplicar estilos consistentes con las convenciones de cada plataforma (iOS Human Interface Guidelines vs Material Design).

### 2.2. Propiedades (Líneas 6-11)

```dart
final bool isIOS;
final bool isDark;
final Color primaryColor;
final Color backgroundColor;
final TextStyle textStyle;
final EdgeInsets defaultPadding;
```

**Propiedades finales**:

1. **`isIOS`** (línea 6): `bool`
   - Indica si la plataforma es iOS
   - Determina qué valores de diseño usar en los getters

2. **`isDark`** (línea 7): `bool`
   - Indica si el modo oscuro está activo
   - Usado para seleccionar colores según el tema

3. **`primaryColor`** (línea 8): `Color`
   - Color principal del tema
   - iOS: 0xFF007AFF (azul iOS)
   - Android: 0xFF2196F3 (azul Material)

4. **`backgroundColor`** (línea 9): `Color`
   - Color de fondo base
   - Varía según plataforma y modo (4 combinaciones posibles)

5. **`textStyle`** (línea 10): `TextStyle`
   - Estilo de texto base con fuente específica de plataforma
   - iOS: '.SF Pro Text'
   - Android: 'Roboto'

6. **`defaultPadding`** (línea 11): `EdgeInsets`
   - Padding predeterminado según plataforma
   - iOS: 16.0 en todos los lados
   - Android: 12.0 en todos los lados

---

## 3. Constructor Principal (Línea 13)

```dart
const PlatformTheme({
  required this.isIOS,
  required this.isDark,
  required this.primaryColor,
  required this.backgroundColor,
  required this.textStyle,
  required this.defaultPadding
});
```

**Características**:
- Constructor `const` para optimización
- Todos los parámetros son `required`
- Named parameters para claridad
- Permite creación manual del tema (usado por copyWith y factory)

**Uso**: Raramente usado directamente; normalmente se usa el factory constructor `adaptive()`

---

## 4. Factory Constructor `adaptive()` (Líneas 15-33)

```dart
factory PlatformTheme.adaptive(BuildContext? context) {
  final isIOS = _isIOSPlatform();
  final brightness = context != null
      ? Theme.of(context).brightness
      : WidgetsBinding.instance.platformDispatcher.platformBrightness;
  final isDark = brightness == Brightness.dark;

  if (context != null) {
    final theme = Theme.of(context);
    return PlatformTheme(
      isIOS: isIOS,
      isDark: isDark,
      primaryColor: theme.primaryColor,
      backgroundColor: theme.cardColor,
      textStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
      defaultPadding: _getDefaultPadding(isIOS)
    );
  }

  return PlatformTheme(
    isIOS: isIOS,
    isDark: isDark,
    primaryColor: isIOS ? const Color(0xFF007AFF) : const Color(0xFF2196F3),
    backgroundColor: isDark
        ? (isIOS ? const Color(0xFF1C1C1E) : const Color(0xFF121212))
        : (isIOS ? const Color(0xFFF2F2F7) : const Color(0xFFFFFFFF)),
    textStyle: TextStyle(
      fontSize: 16,
      color: isDark ? Colors.white : Colors.black,
      fontFamily: isIOS ? '.SF Pro Text' : 'Roboto'
    ),
    defaultPadding: _getDefaultPadding(isIOS)
  );
}
```

### 4.1. Parámetros

- **`context`** (línea 15): `BuildContext?` (nullable)
  - Si se proporciona: usa Theme de Flutter existente
  - Si es null: usa valores predeterminados específicos de plataforma

### 4.2. Lógica (líneas 16-32)

**Paso 1 - Detección de plataforma** (línea 16):
```dart
final isIOS = _isIOSPlatform();
```
- Llama al método privado que verifica si es iOS

**Paso 2 - Detección de brightness** (líneas 17-18):
```dart
final brightness = context != null
    ? Theme.of(context).brightness
    : WidgetsBinding.instance.platformDispatcher.platformBrightness;
final isDark = brightness == Brightness.dark;
```
- Con context: usa el brightness del Theme de Flutter
- Sin context: obtiene brightness del sistema operativo directamente
- Convierte Brightness a bool isDark

**Paso 3a - Con context** (líneas 20-23):
```dart
if (context != null) {
  final theme = Theme.of(context);
  return PlatformTheme(...);
}
```
- Extrae valores del Theme de Flutter existente
- `primaryColor`: del theme
- `backgroundColor`: usa `theme.cardColor`
- `textStyle`: usa `bodyMedium` con fallback a TextStyle vacío
- `defaultPadding`: según plataforma (helper method)

**Paso 3b - Sin context** (líneas 25-32):
```dart
return PlatformTheme(
  isIOS: isIOS,
  isDark: isDark,
  primaryColor: isIOS ? const Color(0xFF007AFF) : const Color(0xFF2196F3),
  backgroundColor: isDark
      ? (isIOS ? const Color(0xFF1C1C1E) : const Color(0xFF121212))
      : (isIOS ? const Color(0xFFF2F2F7) : const Color(0xFFFFFFFF)),
  textStyle: TextStyle(...),
  defaultPadding: _getDefaultPadding(isIOS)
);
```

**Colores específicos de plataforma**:

| Propiedad | iOS Light | iOS Dark | Android Light | Android Dark |
|-----------|-----------|----------|---------------|--------------|
| primaryColor | 0xFF007AFF | 0xFF007AFF | 0xFF2196F3 | 0xFF2196F3 |
| backgroundColor | 0xFFF2F2F7 | 0xFF1C1C1E | 0xFFFFFFFF | 0xFF121212 |

**TextStyle** (líneas 30):
- fontSize: 16 (ambas plataformas)
- color: blanco en dark, negro en light
- fontFamily: '.SF Pro Text' (iOS) o 'Roboto' (Android)

---

## 5. Métodos Privados Estáticos

### 5.1. `_isIOSPlatform()` (Líneas 35-38)

```dart
static bool _isIOSPlatform() {
  if (kIsWeb) return false;
  return Platform.isIOS;
}
```

**Propósito**: Detecta si la plataforma es iOS de forma segura

**Lógica**:
1. Si es web (`kIsWeb`): retorna `false` (no hay iOS en web)
2. En plataformas nativas: retorna `Platform.isIOS`

**Importaciones necesarias**:
- `dart:io` para `Platform.isIOS`
- `package:flutter/foundation.dart` para `kIsWeb`

**Motivo**: Evita errores al acceder a `Platform.isIOS` en web (donde no está disponible)

### 5.2. `_getDefaultPadding()` (Líneas 40-42)

```dart
static EdgeInsets _getDefaultPadding(bool isIOS) {
  return isIOS
      ? const EdgeInsets.all(16.0)
      : const EdgeInsets.all(12.0);
}
```

**Propósito**: Retorna el padding predeterminado según la plataforma

**Valores**:
- **iOS**: 16.0 (Human Interface Guidelines)
- **Android**: 12.0 (Material Design)

**Retorno**: Const EdgeInsets para optimización

---

## 6. Getters Computados

### 6.1. `cardElevation` (Línea 44)

```dart
double get cardElevation => isIOS ? 0.0 : 2.0;
```

**Propósito**: Elevación para cards según plataforma

**Valores**:
- **iOS**: 0.0 (iOS usa borders, no sombras)
- **Android**: 2.0 (Material Design usa elevación)

### 6.2. `defaultBorderRadius` (Línea 46)

```dart
BorderRadius get defaultBorderRadius => BorderRadius.circular(isIOS ? 10.0 : 8.0);
```

**Propósito**: Border radius predeterminado según plataforma

**Valores**:
- **iOS**: 10.0 (esquinas más redondeadas)
- **Android**: 8.0 (esquinas menos redondeadas)

### 6.3. `buttonHeight` (Línea 48)

```dart
double get buttonHeight => isIOS ? 50.0 : 48.0;
```

**Propósito**: Altura estándar de botones según plataforma

**Valores**:
- **iOS**: 50.0 (Human Interface Guidelines)
- **Android**: 48.0 (Material Design)

### 6.4. `textFieldHeight` (Línea 50)

```dart
double get textFieldHeight => isIOS ? 44.0 : 56.0;
```

**Propósito**: Altura estándar de campos de texto según plataforma

**Valores**:
- **iOS**: 44.0 (tamaño mínimo táctil iOS)
- **Android**: 56.0 (Material Design text field)

### 6.5. `secondaryColor` (Línea 52)

```dart
Color get secondaryColor => isIOS
    ? (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70))
    : (isDark ? const Color(0xFFBB86FC) : const Color(0xFF03DAC6));
```

**Propósito**: Color secundario según plataforma y tema

**Valores**:

| Plataforma | Light | Dark |
|------------|-------|------|
| iOS | 0xFF6D6D70 (gris) | 0xFF8E8E93 (gris claro) |
| Android | 0xFF03DAC6 (teal) | 0xFFBB86FC (púrpura) |

**Característica**: Android usa colores vibrantes del tema Material, iOS usa grises

### 6.6. `errorColor` (Línea 54)

```dart
Color get errorColor => isIOS
    ? const Color(0xFFFF3B30)
    : const Color(0xFFB00020);
```

**Propósito**: Color de error según plataforma

**Valores**:
- **iOS**: 0xFFFF3B30 (rojo iOS)
- **Android**: 0xFFB00020 (rojo Material)

**Nota**: No varía con isDark (los colores de error son consistentes)

### 6.7. `surfaceColor` (Línea 56)

```dart
Color get surfaceColor => isDark
    ? (isIOS ? const Color(0xFF2C2C2E) : const Color(0xFF1E1E1E))
    : (isIOS ? const Color(0xFFFFFFFF) : const Color(0xFFFAFAFA));
```

**Propósito**: Color de superficie para tarjetas y contenedores elevados

**Valores**:

| Plataforma | Light | Dark |
|------------|-------|------|
| iOS | 0xFFFFFFFF (blanco puro) | 0xFF2C2C2E (gris oscuro) |
| Android | 0xFFFAFAFA (gris muy claro) | 0xFF1E1E1E (gris muy oscuro) |

**Diferencia con backgroundColor**:
- `backgroundColor`: fondo de la pantalla
- `surfaceColor`: fondo de elementos sobre la pantalla (cards, dialogs)

### 6.8. `dividerColor` (Línea 58)

```dart
Color get dividerColor => isDark
    ? Colors.white.withValues(alpha: 0.1)
    : Colors.black.withValues(alpha: 0.1);
```

**Propósito**: Color para divisores y bordes sutiles

**Valores**:
- **Dark mode**: blanco con 10% opacidad
- **Light mode**: negro con 10% opacidad

**Método**: Usa `withValues(alpha: 0.1)` en lugar del antiguo `withOpacity(0.1)`

**Característica**: No varía por plataforma, solo por tema (dark/light)

---

## 7. Método `copyWith()` (Líneas 60-62)

```dart
PlatformTheme copyWith({
  bool? isIOS,
  bool? isDark,
  Color? primaryColor,
  Color? backgroundColor,
  TextStyle? textStyle,
  EdgeInsets? defaultPadding
}) {
  return PlatformTheme(
    isIOS: isIOS ?? this.isIOS,
    isDark: isDark ?? this.isDark,
    primaryColor: primaryColor ?? this.primaryColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    textStyle: textStyle ?? this.textStyle,
    defaultPadding: defaultPadding ?? this.defaultPadding
  );
}
```

**Propósito**: Crear una copia del tema con algunas propiedades modificadas

**Parámetros**: Todos opcionales y nullables

**Retorno**: Nueva instancia de PlatformTheme

**Patrón**: Standard copyWith para clases inmutables en Dart

**Uso típico**:
```dart
final newTheme = currentTheme.copyWith(
  primaryColor: Colors.red,
  isDark: true
);
```

---

## 8. Operador `==` (Líneas 65-68)

```dart
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is PlatformTheme &&
      other.isIOS == isIOS &&
      other.isDark == isDark &&
      other.primaryColor == primaryColor &&
      other.backgroundColor == backgroundColor &&
      other.textStyle == textStyle &&
      other.defaultPadding == defaultPadding;
}
```

**Propósito**: Comparar igualdad entre instancias de PlatformTheme

**Lógica**:
1. **Verificación de identidad** (línea 66): Si es la misma instancia, retorna true
2. **Type check** (línea 67): Verifica que `other` es PlatformTheme
3. **Comparación de propiedades** (líneas 67-68): Compara TODAS las 6 propiedades finales

**Característica**: Igualdad estructural (value equality) en lugar de igualdad de referencia

**Nota**: Compara todas las propiedades almacenadas, NO los getters computados

---

## 9. Método `hashCode` (Líneas 71-73)

```dart
@override
int get hashCode {
  return Object.hash(
    isIOS,
    isDark,
    primaryColor,
    backgroundColor,
    textStyle,
    defaultPadding
  );
}
```

**Propósito**: Generar hash code para uso en colecciones (Map, Set)

**Método**: Usa `Object.hash()` (Dart 2.14+) para combinar hashes de las 6 propiedades

**Consistencia**: hashCode DEBE ser consistente con el operador ==
- Si `a == b` es true, entonces `a.hashCode == b.hashCode` DEBE ser true
- Este método cumple esa regla usando las mismas 6 propiedades

**Ventaja de Object.hash()**: Mejor distribución que combinar hashes manualmente

---

## 10. Método `toString()` (Líneas 76-83)

```dart
@override
String toString() {
  return 'PlatformTheme('
      'isIOS: $isIOS, '
      'isDark: $isDark, '
      'primaryColor: $primaryColor, '
      'backgroundColor: $backgroundColor'
      ')';
}
```

**Propósito**: Representación legible para debugging

**Formato**: Muestra el nombre de la clase y 4 de las 6 propiedades

**Propiedades incluidas**:
- isIOS
- isDark
- primaryColor
- backgroundColor

**Propiedades omitidas**:
- textStyle (puede ser verbose)
- defaultPadding (menos relevante para debug rápido)

**Uso**: Útil en logs y debugging: `print(theme)` o `debugPrint('Theme: $theme')`

---

## 11. Dependencias

### 11.1. Importaciones (Líneas 1-3)

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
```

**Librerías**:

1. **`dart:io`** (línea 1):
   - Usada por: `Platform.isIOS` (línea 37)
   - Proporciona: Detección de plataforma en aplicaciones nativas

2. **`package:flutter/material.dart`** (línea 2):
   - Usada por: Color, TextStyle, EdgeInsets, BuildContext, Theme, Brightness, BorderRadius
   - Proporciona: Todos los tipos de Material Design y Flutter

3. **`package:flutter/foundation.dart`** (línea 3):
   - Usada por: `kIsWeb` (línea 36)
   - Proporciona: Constantes y utilidades de Flutter foundation

### 11.2. Dependencias en tiempo de uso

**Esta clase NO depende de**:
- Riverpod
- Otros widgets adaptativos
- Servicios externos

**Es usada por**:
- AdaptiveButton (para obtener valores de diseño)
- AdaptiveCard (para obtener valores de diseño)
- AdaptiveTextField (para obtener valores de diseño)
- Cualquier widget que necesite valores adaptativos

---

## 12. Características Técnicas

### 12.1. Patrón de diseño

**Tipo**: Value Object / Data Transfer Object

**Inmutabilidad**: Todas las propiedades son `final`

**Factory Pattern**: Constructor `adaptive()` para creación inteligente

### 12.2. Optimizaciones

1. **Constructor const** (línea 13): Permite crear instancias en tiempo de compilación
2. **Const colors** (líneas 28-29, 52, 54, etc.): Colores predefinidos como const
3. **Const EdgeInsets** (líneas 41-42): Padding como const
4. **Getters computados**: Calculados on-demand, no almacenados
5. **Identity check** en == (línea 66): Optimización temprana

### 12.3. Compatibilidad multiplataforma

**Soporta**:
- iOS (detectado con Platform.isIOS)
- Android (default cuando no es iOS)
- Web (detectado con kIsWeb, retorna false para isIOS)

**Valores específicos de iOS**:
- Fuente: .SF Pro Text
- Padding: 16.0
- Button height: 50.0
- TextField height: 44.0
- Card elevation: 0.0
- Border radius: 10.0
- Colores secundarios: grises

**Valores específicos de Android**:
- Fuente: Roboto
- Padding: 12.0
- Button height: 48.0
- TextField height: 56.0
- Card elevation: 2.0
- Border radius: 8.0
- Colores secundarios: vibrantes (teal, púrpura)

### 12.4. Tema claro vs oscuro

**4 combinaciones de colores**:
1. iOS Light: fondos claros (0xFFF2F2F7, 0xFFFFFFFF)
2. iOS Dark: fondos oscuros (0xFF1C1C1E, 0xFF2C2C2E)
3. Android Light: fondos claros (0xFFFFFFFF, 0xFFFAFAFA)
4. Android Dark: fondos oscuros (0xFF121212, 0xFF1E1E1E)

**Detección automática**:
- Con context: usa `Theme.of(context).brightness`
- Sin context: usa `WidgetsBinding.instance.platformDispatcher.platformBrightness`

### 12.5. Flexibilidad

**Dos modos de creación**:
1. **Con Theme de Flutter** (líneas 20-23): Integración con Theme existente
2. **Valores predeterminados** (líneas 25-32): Funciona sin Theme configurado

**Modificación**: Método copyWith permite crear variaciones

### 12.6. Uso de API moderna

- **`withValues(alpha:)`** (línea 58): API moderna de Color en lugar de `withOpacity()`
- **`Object.hash()`** (línea 72): API moderna para hash codes
- **Null safety**: Parámetros nullable explícitos (`BuildContext?`)

---

## 13. Resumen de Valores por Plataforma

### 13.1. Tabla de dimensiones

| Propiedad | iOS | Android |
|-----------|-----|---------|
| defaultPadding | 16.0 | 12.0 |
| cardElevation | 0.0 | 2.0 |
| defaultBorderRadius | 10.0 | 8.0 |
| buttonHeight | 50.0 | 48.0 |
| textFieldHeight | 44.0 | 56.0 |

### 13.2. Tabla de colores primarios

| Color | iOS | Android |
|-------|-----|---------|
| primaryColor | 0xFF007AFF | 0xFF2196F3 |
| errorColor | 0xFFFF3B30 | 0xFFB00020 |

### 13.3. Tabla de colores por tema

| Color | iOS Light | iOS Dark | Android Light | Android Dark |
|-------|-----------|----------|---------------|--------------|
| backgroundColor | 0xFFF2F2F7 | 0xFF1C1C1E | 0xFFFFFFFF | 0xFF121212 |
| surfaceColor | 0xFFFFFFFF | 0xFF2C2C2E | 0xFFFAFAFA | 0xFF1E1E1E |
| secondaryColor | 0xFF6D6D70 | 0xFF8E8E93 | 0xFF03DAC6 | 0xFFBB86FC |
| dividerColor | black 10% | white 10% | black 10% | white 10% |

### 13.4. Fuentes tipográficas

| Plataforma | Fuente | Tamaño base |
|------------|--------|-------------|
| iOS | .SF Pro Text | 16 |
| Android | Roboto | 16 |

---

**Fin de la documentación de platform_theme.dart**
