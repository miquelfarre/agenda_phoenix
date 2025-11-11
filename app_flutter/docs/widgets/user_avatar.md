# UserAvatar - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/user_avatar.dart`
**Líneas**: 96
**Tipo**: ConsumerWidget
**Propósito**: Avatar de usuario con múltiples fallbacks (cache local, URL, iniciales)

## 2. CLASE Y PROPIEDADES

### UserAvatar (líneas 10-95)

**Propiedades**:

| Propiedad | Tipo | Default | Required | Descripción |
|-----------|------|---------|----------|-------------|
| `user` | User | - | Sí | Usuario a mostrar |
| `radius` | double | 20 | No | Radio del avatar (diámetro = radius * 2) |
| `showOnlineIndicator` | bool | true | No | Mostrar indicador online (no implementado) |

## 3. MÉTODO BUILD

### build(BuildContext context, WidgetRef ref) (líneas 18-22)

**Lógica en cascada**:
1. Obtiene `logoPathProvider(user.id)` (cache local)
2. Si localPath != null → `_buildLocalAvatar(localPath)`
3. Sino → `_buildAvatar(context)`

**Estructura**:
```
Stack
└── [Prioridad 1] if (localPath != null)
    │   └── _buildLocalAvatar(localPath)
    └── else
        └── _buildAvatar(context)
```

## 4. MÉTODOS PRIVADOS

### _buildLocalAvatar(String path) (líneas 24-35)
**Retorna**: CircleAvatar con imagen local

```
ClipOval
└── Container(radius*2 x radius*2)
    - shape: circle
    - image: FileImage(File(path))
    - fit: cover
```

### _buildAvatar(BuildContext context) (líneas 37-59)
**Retorna**: CachedNetworkImage o iniciales

**Lógica**:
1. Si profilePicture null/empty → `_buildInitialsAvatar()`
2. Sino → CachedNetworkImage con:
   - placeholder → `_buildInitialsAvatar()`
   - errorWidget → `_buildInitialsAvatar()`

**CachedNetworkImage configuración**:
```dart
imageBuilder: (context, imageProvider) => ClipOval(
  Container(radius*2 x radius*2, circular, cover)
)
```

### _buildInitialsAvatar(BuildContext context) (líneas 61-76)
**Retorna**: CircleAvatar con iniciales y color generado

**Lógica**:
1. Genera color de `_generateColorFromName(user.displayName)`
2. Obtiene iniciales de `_getInitials(context, user.displayName)`

**Estructura**:
```
ClipOval
└── Container(radius*2 x radius*2)
    - shape: circle
    - color: generated color
    - alignment: center
    └── Text(initials)
        - fontSize: radius * 0.6
        - fontWeight: w600
        - color: white
```

### _getInitials(BuildContext context, String name) (líneas 78-83)
**Retorna**: String con iniciales

**Lógica**:
```dart
final words = name.trim().split(' ');
if (words.isEmpty) return l10n.avatarUnknownInitial;  // '?'
if (words.length == 1) return words[0][0].toUpperCase();  // 'J'
return '${words[0][0]}${words[1][0]}'.toUpperCase();  // 'JP'
```

**Ejemplos**:
- "" → "?"
- "Juan" → "J"
- "Juan Pérez" → "JP"
- "Juan Pablo Pérez" → "JP" (solo primeras 2 palabras)

### _generateColorFromName(String name) (líneas 85-94)
**Retorna**: Color basado en hash del nombre

**Paleta** (10 colores):
```dart
[blue600, green600, orange600, purple600, red600,
 teal600, indigo600, pink600, amber600, cyan600]
```

**Algoritmo de hash** (líneas 88-91):
```dart
int hash = 0;
for (int i = 0; i < name.length; i++) {
  hash = name.codeUnitAt(i) + ((hash << 5) - hash);
}
return colors[hash.abs() % colors.length];
```
- Hash determin ístico: mismo nombre → mismo color
- Distribución uniforme entre 10 colores

## 5. PRIORIDADES DE CARGA

**Cascada**:
1. **Logo local** (via provider): Si existe en cache
2. **Profile picture URL** (CachedNetworkImage): Si tiene URL
3. **Iniciales con color**: Fallback final

## 6. PROVIDERS UTILIZADOS

### logoPathProvider(int userId) (línea 19)
**Tipo**: AsyncValue<String?>
**Propósito**: Obtener ruta local del logo cacheado
**Retorna**: String? con path o null

## 7. TAMAÑOS

| Propiedad | Cálculo | Ejemplo (radius=20) |
|-----------|---------|---------------------|
| radius | Parámetro | 20 |
| Diámetro | radius * 2 | 40 |
| fontSize iniciales | radius * 0.6 | 12 |

## 8. USO TÍPICO

### Default:
```dart
UserAvatar(user: user)  // radius=20
```

### Custom size:
```dart
UserAvatar(user: user, radius: 30)  // 60x60
UserAvatar(user: user, radius: 16)  // 32x32 (pequeño)
```

### En listas:
```dart
ListTile(
  leading: UserAvatar(user: contact),
  title: Text(contact.displayName),
)
```

## 9. LOCALIZACIÓN

**String usado**:
- `l10n.avatarUnknownInitial`: "?" (cuando nombre está vacío)

## 10. DEPENDENCIAS

**Imports**:
- dart:io (FileImage)
- flutter/cupertino.dart
- flutter_riverpod (ConsumerWidget)
- cached_network_image
- models/user.dart
- core/state/app_state.dart (logoPathProvider)
- helpers/l10n_helpers.dart
- styles/app_styles.dart

## 11. NOTAS ADICIONALES

- **ConsumerWidget**: Accede a logoPathProvider
- **Circular**: Siempre circular vía ClipOval
- **Color hash**: Determin ístico y distribuido
- **Cache optimizado**: Usa CachedNetworkImage
- **Fallback robusto**: 3 niveles de fallback
- **showOnlineIndicator**: Parámetro definido pero **no implementado**
- **No loading state**: Muestra iniciales inmediatamente como placeholder
- **Text responsive**: Tamaño de texto se escala con radius
- **10 colores**: Paleta fija de colores vivos
- **Case insensitive**: toUpperCase() para iniciales
