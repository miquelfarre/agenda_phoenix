# Adaptive Scaffold - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Líneas**: 226
**Tipo**: Múltiples widgets (StatelessWidget)
**Propósito**: Proporciona scaffolds adaptativos que cambian su apariencia según la plataforma (iOS vs otras), incluyendo navegación bottom, app bars y páginas simples

## 2. CLASES CONTENIDAS

Este archivo contiene:
1. **AdaptiveScaffold** (líneas 6-106): Scaffold con navegación bottom
2. **AdaptiveNavigationItem** (líneas 110-117): Clase de datos para items de navegación
3. **AdaptiveAppBar** (líneas 119-166): AppBar adaptativo standalone
4. **AdaptivePageScaffold** (líneas 168-225): Scaffold simple sin navegación bottom
5. **_kToolbarHeight** (línea 108): Constante para altura de toolbar

---

## 3. CLASE: AdaptiveScaffold

### Información
**Líneas**: 6-106
**Tipo**: StatelessWidget
**Propósito**: Scaffold principal con navegación bottom que se adapta entre CupertinoPageScaffold (iOS) y Column con navegación custom (otras plataformas)

### Propiedades (líneas 7-14)
- `body` (Widget, required): Contenido principal de la pantalla
- `title` (String?): Título opcional para la navigation bar
- `navigationItems` (List<AdaptiveNavigationItem>, required): Lista de items de navegación bottom
- `currentIndex` (int, required): Índice del item actualmente seleccionado
- `onNavigationChanged` (ValueChanged<int>, required): Callback cuando cambia la navegación
- `actions` (List<Widget>?): Lista opcional de widgets de acciones (máximo 2 se muestran)
- `floatingActionButton` (Widget?): Botón flotante opcional (solo en no-iOS)
- `leading` (Widget?): Widget leading opcional en la navigation bar

### Constructor (línea 16)
```dart
const AdaptiveScaffold({
  super.key,
  required this.body,
  this.title,
  required this.navigationItems,
  required this.currentIndex,
  required this.onNavigationChanged,
  this.actions,
  this.floatingActionButton,
  this.leading
})
```

### Método build (líneas 18-105)

#### iOS (líneas 20-51)
**Condición**: `PlatformDetection.isIOS`

Retorna `CupertinoPageScaffold` con:

1. **navigationBar** (líneas 22-29):
   - Condición: `title != null`
   - Si hay título: `CupertinoNavigationBar` con:
     - `transitionBetweenRoutes: false` (sin animación entre rutas)
     - `middle`: Text con el título
     - `leading`: widget leading si existe
     - `trailing`: Row con máximo 2 actions (usa `.take(2)`)
   - Si no hay título: null (sin navigation bar)

2. **child** (líneas 30-50): `SafeArea` con:
   - `top`: `title == null` (solo aplica safeArea top si no hay título)
   - child: `Column` con:
     - **Expanded(body)** (línea 34): Contenido principal expansible
     - **CupertinoTabBar** (líneas 35-47): Navegación bottom con:
       - items: Mapea cada `navigationItems` a `BottomNavigationBarItem`:
         - icon: `platformIcon` con color gris600
         - activeIcon: `platformIcon` con `activeIcon ?? icon`, color azul600
         - label: label del item
       - currentIndex: índice actual
       - onTap: callback `onNavigationChanged`

#### Otras plataformas (líneas 52-103)
Retorna `SafeArea` con `Column` que contiene:

1. **Header condicional** (líneas 56-69):
   - Condición: `title != null`
   - `Container` con:
     - padding: horizontal 16, vertical 12
     - color: azul600
     - child: Row con:
       - leading (si existe)
       - Expanded: Text con título (estilo headlineSmall, blanco)
       - Row con máximo 2 actions (si existen)

2. **Body expandido** (línea 70):
   - `Expanded(child: body)`

3. **Navegación bottom condicional** (líneas 71-99):
   - Condición: `navigationItems.isNotEmpty`
   - `Container` con:
     - decoration: fondo blanco, sombra sutil
     - child: Row con `mainAxisAlignment.spaceAround`:
       - Mapea cada item a `GestureDetector`:
         - key: `'adaptive_scaffold_nav_item_{label_lowercase}'`
         - onTap: llama a `onNavigationChanged(index)`
         - child: Padding con Column:
           - platformIcon (color según selected)
           - SizedBox height 4
           - Text con label (color según selected)

4. **FloatingActionButton condicional** (línea 100):
   - Condición: `floatingActionButton != null`
   - Padding bottom 12 con el botón

**Diferencias clave iOS vs otras**:
- iOS usa `CupertinoTabBar` nativo, otras usan navegación custom con GestureDetectors
- iOS aplica SafeArea solo top si no hay título, otras siempre usan SafeArea
- Otras plataformas soportan floatingActionButton, iOS no
- iOS usa BottomNavigationBarItem, otras usan Column con icono y texto

---

## 4. CONSTANTE: _kToolbarHeight

**Línea**: 108
**Valor**: `56.0`
**Tipo**: double
**Propósito**: Define la altura estándar de la toolbar/appbar
**Uso**: Usada por `AdaptiveAppBar.preferredSize`

---

## 5. CLASE: AdaptiveNavigationItem

### Información
**Líneas**: 110-117
**Tipo**: Clase de datos (const)
**Propósito**: Representa un item de navegación bottom con icono, label y pantalla asociada

### Propiedades (líneas 111-114)
- `icon` (IconData, required): Icono cuando no está seleccionado
- `activeIcon` (IconData?): Icono cuando está seleccionado (opcional, usa `icon` si es null)
- `label` (String, required): Etiqueta del item
- `screen` (Widget, required): Pantalla asociada al item

### Constructor (línea 116)
```dart
const AdaptiveNavigationItem({
  required this.icon,
  this.activeIcon,
  required this.label,
  required this.screen
})
```

**Nota**: `screen` se almacena pero no se usa directamente en `AdaptiveScaffold`. El cambio de pantalla debe manejarse externamente basándose en `currentIndex`.

---

## 6. CLASE: AdaptiveAppBar

### Información
**Líneas**: 119-166
**Tipo**: StatelessWidget implements PreferredSizeWidget
**Propósito**: AppBar standalone adaptativo con soporte para botón de retroceso automático

### Implementa
`PreferredSizeWidget`: Permite que se use como appBar con tamaño preferido

### Propiedades (líneas 120-124)
- `title` (String, required): Título del appBar
- `actions` (List<Widget>?): Lista opcional de widgets de acciones (máximo 2)
- `leading` (Widget?): Widget leading opcional
- `onLeadingPressed` (VoidCallback?): Callback opcional para el botón leading
- `automaticallyImplyLeading` (bool): Si true, muestra botón de retroceso automático, default true

### Constructor (línea 126)
```dart
const AdaptiveAppBar({
  super.key,
  required this.title,
  this.actions,
  this.leading,
  this.onLeadingPressed,
  this.automaticallyImplyLeading = true
})
```

### Método build (líneas 128-162)

#### iOS (líneas 130-145)
Retorna `CupertinoNavigationBar` con:
- `middle`: Text con título
- `leading`: Widget leading personalizado o automático:
  - Si `leading` existe: usa ese widget
  - Si `automaticallyImplyLeading && Navigator.canPop(context)`:
    - Crea `CupertinoNavigationBarBackButton`
    - onPressed: `onLeadingPressed ?? Navigator.pop`
  - Sino: null
- `trailing`: Row con máximo 2 actions

#### Otras plataformas (líneas 146-161)
Retorna `Container` con:
- height: 56
- color: azul600
- padding: horizontal 12
- child: Row con:
  - leading (si existe)
  - Expanded: Text con título (headlineSmall, blanco)
  - Row con máximo 2 actions (si existen)

### Propiedad preferredSize (líneas 164-165)
```dart
Size get preferredSize => Size.fromHeight(_kToolbarHeight);
```

Retorna: Size con height de 56.0 (usando la constante `_kToolbarHeight`)

**Propósito**: Requerido por `PreferredSizeWidget`, indica la altura preferida del appBar

---

## 7. CLASE: AdaptivePageScaffold

### Información
**Líneas**: 168-225
**Tipo**: StatelessWidget
**Propósito**: Scaffold simple para páginas individuales sin navegación bottom, con navigation bar opcional

### Propiedades (líneas 169-174)
- `body` (Widget, required): Contenido principal de la pantalla
- `title` (String?): Título opcional para la navigation bar
- `actions` (List<Widget>?): Lista opcional de widgets de acciones (máximo 2)
- `leading` (Widget?): Widget leading opcional
- `automaticallyImplyLeading` (bool): Si true, muestra botón de retroceso automático, default true
- `floatingActionButton` (Widget?): Botón flotante opcional (solo en no-iOS)

### Constructor (línea 176)
```dart
const AdaptivePageScaffold({
  super.key,
  required this.body,
  this.title,
  this.actions,
  this.leading,
  this.automaticallyImplyLeading = true,
  this.floatingActionButton
})
```

### Método build (líneas 178-224)

#### iOS (líneas 180-199)
Retorna `CupertinoPageScaffold` con:

1. **navigationBar** (líneas 182-197):
   - Condición: `title != null`
   - `CupertinoNavigationBar` con:
     - `transitionBetweenRoutes: false`
     - `middle`: Text con título
     - `leading`: Widget leading personalizado o automático:
       - Si `leading` existe: usa ese widget
       - Si `automaticallyImplyLeading && Navigator.canPop(context)`:
         - Crea `CupertinoNavigationBarBackButton`
         - onPressed: `Navigator.pop`
       - Sino: null
     - `trailing`: Row con máximo 2 actions

2. **child** (línea 198):
   - Directamente el `body` sin SafeArea
   - CupertinoPageScaffold maneja SafeArea internamente

#### Otras plataformas (líneas 200-223)
Retorna `SafeArea` con `Column` que contiene:

1. **Header condicional** (líneas 204-217):
   - Condición: `title != null`
   - `Container` con:
     - padding: horizontal 16, vertical 12
     - color: azul600
     - child: Row con:
       - leading (si existe)
       - Expanded: Text con título (headlineSmall, blanco)
       - Row con máximo 2 actions (si existen)

2. **Body expandido** (línea 218):
   - `Expanded(child: body)`

3. **FloatingActionButton condicional** (línea 219):
   - Condición: `floatingActionButton != null`
   - Padding bottom 12 con el botón

**Diferencia con AdaptiveScaffold**: No tiene navegación bottom, es solo la página individual

---

## 8. DEPENDENCIAS

### Packages externos:
- `flutter/cupertino.dart`: Widgets de estilo iOS

### Imports internos:
- `eventypop/ui/helpers/platform/platform_detection.dart`: `PlatformDetection.isIOS`
- `eventypop/ui/helpers/platform/platform_widgets.dart`: `PlatformWidgets.platformIcon()`
- `eventypop/ui/styles/app_styles.dart`: Estilos y colores

### Widgets de Flutter utilizados:
- `CupertinoPageScaffold`: Scaffold de página iOS
- `CupertinoNavigationBar`: Navigation bar de iOS
- `CupertinoNavigationBarBackButton`: Botón de retroceso de iOS
- `CupertinoTabBar`: Tab bar de iOS
- `BottomNavigationBarItem`: Item de navegación bottom
- `SafeArea`: Área segura sin overlays
- `Column`, `Row`: Layouts
- `Expanded`: Widget expansible
- `Container`: Contenedor con decoración
- `GestureDetector`: Detector de gestos
- `Padding`: Espaciado
- `Text`: Texto
- `BoxDecoration`, `BoxShadow`: Decoración de containers

### Tipos utilizados:
- `ValueChanged<int>`: Callback que recibe int
- `VoidCallback`: Callback sin parámetros
- `IconData`: Datos de icono
- `PreferredSizeWidget`: Interface para widgets con tamaño preferido

---

## 9. CARACTERÍSTICAS TÉCNICAS

### AdaptiveScaffold

**Navegación bottom diferenciada**:
- **iOS**: Usa `CupertinoTabBar` nativo con `BottomNavigationBarItem`
- **Otras**: Usa `Row` con `GestureDetector` personalizado para cada item

**SafeArea condicional en iOS**:
- `top: title == null`: Solo aplica safe area top si no hay título
- CupertinoNavigationBar ya maneja safe area cuando existe

**Limit de 2 actions**:
- `.take(2)` limita las actions mostradas a máximo 2
- Previene desbordamiento visual en navigation bar

**Key para testing**:
- Items de navegación en no-iOS tienen key:
  ```dart
  Key('adaptive_scaffold_nav_item_${item.label.replaceAll(' ', '_').toLowerCase()}')
  ```
- Facilita testing e identificación de elementos

**FloatingActionButton solo en no-iOS**:
- iOS no muestra floatingActionButton
- Otras plataformas lo muestran con padding bottom 12

**Colores adaptativos**:
- Seleccionado: azul600
- No seleccionado: gris600
- Consistente entre plataformas

**Sombra sutil en navegación custom**:
- No-iOS usa BoxShadow con negro 0.06 opacity, blur 4
- Separación visual entre navegación y contenido

### AdaptiveNavigationItem

**Clase de datos inmutable**:
- Todos los campos const
- Constructor const
- Almacena tanto icono como screen

**activeIcon opcional**:
- Si no se proporciona, usa el mismo `icon` para ambos estados
- Permite diferenciación visual cuando se necesita

**screen no usado directamente**:
- Se almacena pero no se usa en AdaptiveScaffold
- El cambio de pantalla debe manejarse externamente
- Podría ser un campo legacy o para uso futuro

### AdaptiveAppBar

**Implements PreferredSizeWidget**:
- Requerido para que funcione como appBar
- Debe implementar `preferredSize` getter
- Retorna Size con height de 56.0

**Botón de retroceso automático**:
- En iOS: `CupertinoNavigationBarBackButton`
- Verifica `Navigator.canPop(context)` antes de mostrar
- Respeta `automaticallyImplyLeading` flag

**onLeadingPressed fallback**:
- Si se proporciona: usa ese callback
- Si no: usa `Navigator.of(context).pop()`
- Flexibilidad para custom behavior

**Solo standalone**:
- No forma parte de scaffold, se usa independientemente
- Puede usarse con cualquier Scaffold personalizado

### AdaptivePageScaffold

**Similar a AdaptiveScaffold sin navegación**:
- Reutiliza misma lógica de header
- No tiene `navigationItems`, `currentIndex`, `onNavigationChanged`
- Más simple para páginas individuales

**Body directo en iOS**:
- No aplica SafeArea al body en iOS
- CupertinoPageScaffold lo maneja internamente

**SafeArea en toda la Column en no-iOS**:
- Aplica SafeArea a toda la columna
- Asegura que header y body estén en área segura

**automaticallyImplyLeading**:
- Similar a AdaptiveAppBar
- Muestra botón de retroceso si puede hacer pop

### Compartido entre todos

**transitionBetweenRoutes: false**:
- En CupertinoNavigationBar
- Desactiva animación de transición del navigation bar
- Mejora UX al evitar animaciones confusas

**Máximo 2 actions**:
- Todos los widgets limitan actions a 2
- Previene desbordamiento en navigation bar
- Consistencia visual

**platformIcon wrapper**:
- Todos los iconos usan `PlatformWidgets.platformIcon()`
- Asegura iconos adaptativos según plataforma

**Color scheme consistente**:
- Header: azul600 (no-iOS)
- Texto header: blanco
- Seleccionado: azul600
- No seleccionado: gris600

**Container vs CupertinoNavigationBar**:
- iOS usa widgets nativos de Cupertino
- No-iOS usa Container con color y padding
- Recreación visual del navigation bar

**Row con mainAxisSize.min para actions**:
- En todas las navigation bars
- Evita que actions ocupen más espacio del necesario
- Alineación correcta a la derecha

**Expanded para título**:
- Título siempre usa Expanded
- Ocupa espacio disponible entre leading y actions
- Previene desbordamiento

---

## 10. CASOS DE USO

### AdaptiveScaffold
**Cuándo usar**:
- Pantalla principal con navegación bottom persistente
- Múltiples secciones navegables (ej: Home, Calendar, Settings)
- Tab bar que debe permanecer visible

**Ejemplo**: Pantalla principal de la app con 3-5 secciones

### AdaptivePageScaffold
**Cuándo usar**:
- Pantallas individuales sin navegación bottom
- Páginas de detalle o formularios
- Navegación jerárquica (push/pop)

**Ejemplo**: Pantalla de detalle de evento, formulario de crear evento

### AdaptiveAppBar
**Cuándo usar**:
- Necesitas un appBar standalone
- Scaffolds personalizados
- No usas AdaptivePageScaffold

**Ejemplo**: Scaffold personalizado con comportamiento especial

### AdaptiveNavigationItem
**Cuándo usar**:
- Definir items de navegación para AdaptiveScaffold
- Asociar icono, label y pantalla

**Ejemplo**:
```dart
AdaptiveNavigationItem(
  icon: CupertinoIcons.home,
  activeIcon: CupertinoIcons.house_fill,
  label: 'Home',
  screen: HomeScreen()
)
```
