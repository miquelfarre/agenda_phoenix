# UserGroupAvatar - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/user_group_avatar.dart`
**Líneas**: 24
**Tipo**: StatelessWidget
**Propósito**: Avatar cuadrado con icono para representar grupos, calendarios u otras entidades, con color personalizable y fondo semi-transparente

## 2. CLASE Y PROPIEDADES

### UserGroupAvatar (líneas 5-23)

**Propiedades**:
- `icon` (IconData, required, línea 6): Icono a mostrar en el avatar
- `color` (Color, required, línea 7): Color del icono y del tema (fondo y borde derivan de este)

## 3. CONSTRUCTOR

```dart
const UserGroupAvatar({
  super.key,
  required this.icon,
  required this.color
})
```

**Tipo**: Constructor const
**Ambos parámetros required**

## 4. MÉTODO BUILD (líneas 10-22)

```dart
@override
Widget build(BuildContext context) {
  return Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: AppStyles.colorWithOpacity(color, 0.10),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppStyles.colorWithOpacity(color, 0.30),
        width: 1.2
      ),
    ),
    child: PlatformWidgets.platformIcon(icon, color: color, size: 28),
  );
}
```

**Estructura**: Container cuadrado de 48x48px con icono centrado

## 5. ANÁLISIS DETALLADO

### 5.1. Dimensiones

**Container**:
- width: 48px
- height: 48px
- Cuadrado perfecto

**Icon**:
- size: 28px
- Centrado automáticamente (por defecto en Container)

**Spacing**: (48 - 28) / 2 = 10px de margen alrededor del icono

### 5.2. Colores (basados en `color` prop)

**Fondo**:
```dart
color: AppStyles.colorWithOpacity(color, 0.10)
```
- Color proporcionado con 10% de opacidad
- Fondo muy claro, sutil

**Borde**:
```dart
color: AppStyles.colorWithOpacity(color, 0.30)
```
- Color proporcionado con 30% de opacidad
- Más oscuro que el fondo pero aún sutil

**Icono**:
```dart
color: color
```
- Color sólido (100% opacidad)
- Prominente, contrasta con el fondo

**Ejemplo con Colors.blue**:
- Fondo: Azul con 10% opacidad (muy claro)
- Borde: Azul con 30% opacidad (claro)
- Icono: Azul sólido (100%)

### 5.3. BorderRadius

```dart
borderRadius: BorderRadius.circular(12)
```

**Radio**: 12px
**Efecto**: Esquinas redondeadas, estilo moderno
**No circular**: Es cuadrado con esquinas redondeadas, no un círculo

### 5.4. Borde

```dart
border: Border.all(
  color: AppStyles.colorWithOpacity(color, 0.30),
  width: 1.2
)
```

**Width**: 1.2px (ligeramente más grueso que 1px estándar)
**Color**: 30% de opacidad del color principal

## 6. COMPONENTES EXTERNOS

### PlatformWidgets.platformIcon (línea 20)

**Propósito**: Renderiza icono adaptativo según plataforma
**Parámetros**:
- icon: IconData
- color: Color
- size: 28

## 7. CARACTERÍSTICAS TÉCNICAS

### 7.1. Color theming

Todo el esquema de color deriva de un solo `color` prop:
- Fondo: 10% opacity
- Borde: 30% opacity
- Icono: 100% opacity

**Beneficio**: Coherencia visual, fácil cambiar tema completo

### 7.2. AppStyles.colorWithOpacity

Helper function que retorna Color con opacidad especificada:

```dart
// Posible implementación
static Color colorWithOpacity(Color color, double opacity) {
  return color.withOpacity(opacity);
}
```

**Uso**: Centraliza lógica de opacidad

### 7.3. Constructor const

Permite instancias constantes:

```dart
const UserGroupAvatar(
  icon: Icons.group,
  color: Colors.blue,
)
```

### 7.4. Diferencia con UserAvatar

**UserAvatar**:
- Avatar circular
- Muestra foto de perfil o iniciales
- Para usuarios individuales

**UserGroupAvatar**:
- Avatar cuadrado con esquinas redondeadas
- Solo muestra icono
- Para grupos, calendarios, categorías

## 8. CASOS DE USO

### 8.1. Grupo de usuarios

```dart
UserGroupAvatar(
  icon: Icons.group,
  color: Colors.blue,
)
```

### 8.2. Calendario

```dart
UserGroupAvatar(
  icon: Icons.calendar_today,
  color: Colors.green,
)
```

### 8.3. Categoría

```dart
UserGroupAvatar(
  icon: Icons.folder,
  color: Colors.orange,
)
```

### 8.4. En SelectableCard

```dart
SelectableCard(
  title: 'Mi Grupo',
  subtitle: '15 miembros',
  icon: Icons.group,
  color: Colors.purple,
  selected: false,
  onTap: () {},
  onChanged: (selected) {},
)
// UserGroupAvatar se usa internamente en SelectableCard
```

### 8.5. Lista de calendarios

```dart
ListView.builder(
  itemBuilder: (context, index) {
    final calendar = calendars[index];
    return ListTile(
      leading: UserGroupAvatar(
        icon: Icons.calendar_today,
        color: calendar.color,
      ),
      title: Text(calendar.name),
    );
  },
)
```

## 9. VARIACIONES DE COLOR

### Paleta común:

```dart
// Trabajo
UserGroupAvatar(icon: Icons.work, color: Colors.blue)

// Personal
UserGroupAvatar(icon: Icons.person, color: Colors.green)

// Familia
UserGroupAvatar(icon: Icons.family_restroom, color: Colors.orange)

// Deportes
UserGroupAvatar(icon: Icons.sports_soccer, color: Colors.red)

// Educación
UserGroupAvatar(icon: Icons.school, color: Colors.purple)
```

## 10. TESTING

```dart
testWidgets('renders icon with correct color', (tester) async {
  await tester.pumpWidget(
    UserGroupAvatar(
      icon: Icons.group,
      color: Colors.blue,
    ),
  );

  final container = tester.widget<Container>(
    find.byType(Container),
  );

  expect(container.constraints?.minWidth, 48);
  expect(container.constraints?.minHeight, 48);
});
```

## 11. COMPARACIÓN DE TAMAÑOS

### Con UserAvatar:

```dart
// UserAvatar típico
UserAvatar(user: user, radius: 24)  // Diámetro: 48px

// UserGroupAvatar
UserGroupAvatar(...)  // Tamaño: 48x48px
```

**Mismo tamaño visual**: Consistencia en listas mixtas

### Diferentes radios:

```dart
// UserAvatar pequeño
UserAvatar(radius: 16)  // Diámetro: 32px

// UserGroupAvatar es siempre 48x48
// Para match, necesitaría una variant o prop de tamaño
```

## 12. POSIBLES MEJORAS (NO implementadas)

### 12.1. Tamaño configurable

```dart
final double size;

Container(
  width: size,
  height: size,
  ...
  child: PlatformWidgets.platformIcon(
    icon,
    size: size * 0.58, // 28/48 ≈ 0.58
  ),
)
```

### 12.2. Variante circular

```dart
final bool circular;

borderRadius: circular
  ? BorderRadius.circular(size / 2)
  : BorderRadius.circular(12)
```

### 12.3. Badge

```dart
final int? badgeCount;

Stack(
  children: [
    Container(...), // Avatar actual
    if (badgeCount != null)
      Positioned(
        top: 0,
        right: 0,
        child: Badge(count: badgeCount),
      ),
  ],
)
```

### 12.4. Custom opacity levels

```dart
final double backgroundOpacity;
final double borderOpacity;

color: AppStyles.colorWithOpacity(color, backgroundOpacity)
```

## 13. PERFORMANCE

**Muy eficiente**:
- StatelessWidget sin estado
- Constructor const
- Widget tree simple (Container → Icon)
- No carga imágenes de red

## 14. RESUMEN

**Propósito**: Avatar cuadrado con icono para representar entidades no-usuario (grupos, calendarios, categorías)

**Características**:
- Tamaño fijo: 48x48px
- Esquinas redondeadas (radius 12)
- Color theme unificado (fondo 10%, borde 30%, icono 100%)
- Icono centrado de 28px
- Constructor const

**Diferencia clave con UserAvatar**:
- Cuadrado vs circular
- Icono vs foto/iniciales
- Entidades vs usuarios

**Uso**: SelectableCard, listas de calendarios/grupos, categorías visuales

---

**Fin de la documentación de user_group_avatar.dart**
