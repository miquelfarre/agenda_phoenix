# EmptyState - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/empty_state.dart`
**Líneas**: 60
**Tipo**: StatelessWidget
**Propósito**: Widget genérico reutilizable para mostrar estados vacíos con imagen/icono, mensaje y acción opcional

## 2. CLASE Y PROPIEDADES

### EmptyState (líneas 6-59)

**Propiedades**:

| Propiedad | Tipo | Default | Required | Descripción |
|-----------|------|---------|----------|-------------|
| `message` | String? | null | No | Mensaje principal (usa l10n.noData si null) |
| `subtitle` | String? | null | No | Subtítulo opcional |
| `imagePath` | String? | null | No | Ruta a imagen de assets |
| `icon` | IconData? | null | No | Icono alternativo (si no hay imagen) |
| `imageSize` | double? | 120 | No | Tamaño de imagen/icono |
| `onAction` | VoidCallback? | null | No | Callback de acción |
| `actionLabel` | String? | null | No | Texto del botón de acción |

## 3. MÉTODO BUILD

### build(BuildContext context) (líneas 18-58)

**Estructura**:
```
Center
└── Padding(all: 32)
    └── Column(mainAxisAlignment: center)
        ├── [Prioridad 1] if (imagePath != null)
        │   ├── Image.asset(imagePath, size, errorBuilder)
        │   └── SizedBox(height: 24)
        ├── [Prioridad 2] else if (icon != null)
        │   ├── PlatformIcon(icon, size: 64, grey400)
        │   └── SizedBox(height: 24)
        ├── Text(message ?? l10n.noData)
        │   - fontSize: 18, grey600, fontWeight w600
        │   - textAlign: center
        ├── [Condicional] if (subtitle != null)
        │   ├── SizedBox(height: 8)
        │   └── Text(subtitle)
        │       - fontSize: 14, grey500, normal
        │       - textAlign: center
        └── [Condicional] if (onAction != null && actionLabel != null)
            ├── SizedBox(height: 24)
            └── CupertinoButton.filled(onPressed, actionLabel)
```

## 4. PRIORIDADES DE VISUALIZACIÓN

### Imagen vs Icono:

**Prioridad 1: Imagen** (líneas 25-35):
- Si `imagePath != null` → muestra Image.asset
- **ErrorBuilder**: Si falla carga de imagen → fallback a icono
  - Usa `icon ?? CupertinoIcons.square_stack` (default)
  - Size: 64, color: grey400

**Prioridad 2: Icono** (líneas 36-39):
- Si `imagePath == null` Y `icon != null` → muestra icono
- Size: 64, color: grey400

**Prioridad 3: Nada**:
- Si ambos son null → no muestra imagen/icono, solo texto

### Image.asset configuración (líneas 26-34):
```dart
Image.asset(
  imagePath!,
  width: imageSize,           // Default: 120
  height: imageSize,          // Default: 120
  fit: BoxFit.contain,
  errorBuilder: (context, error, stackTrace) {
    return PlatformWidgets.platformIcon(
      icon ?? CupertinoIcons.square_stack,
      size: 64,
      color: AppStyles.grey400
    );
  },
)
```

## 5. MENSAJE Y SUBTÍTULO

### Mensaje principal (líneas 40-44):
```dart
Text(
  message ?? context.l10n.noData,
  style: AppStyles.bodyText.copyWith(
    color: AppStyles.grey600,
    fontWeight: FontWeight.w600,
    fontSize: 18
  ),
  textAlign: TextAlign.center,
)
```
- **Fallback**: Si message es null → usa `l10n.noData`
- **Estilo**: Gris 600, semi-bold, 18px

### Subtítulo (líneas 45-52):
```dart
if (subtitle != null) ...[
  const SizedBox(height: 8),
  Text(
    subtitle!,
    style: AppStyles.bodyText.copyWith(
      color: AppStyles.grey500,
      fontWeight: FontWeight.normal,
      fontSize: 14
    ),
    textAlign: TextAlign.center,
  ),
]
```
- **Condicional**: Solo se muestra si subtitle != null
- **Spacing**: 8px arriba
- **Estilo**: Gris 500, normal, 14px

## 6. BOTÓN DE ACCIÓN

### CupertinoButton.filled (línea 53):
```dart
if (onAction != null && actionLabel != null) ...[
  const SizedBox(height: 24),
  CupertinoButton.filled(
    onPressed: onAction,
    child: Text(actionLabel!)
  )
]
```

**Condición**: Requiere AMBOS:
- `onAction != null`
- `actionLabel != null`

**Estilo**: CupertinoButton.filled (botón azul relleno)

**Spacing**: 24px arriba

## 7. TAMAÑOS Y SPACING

| Elemento | Tamaño/Spacing |
|----------|----------------|
| Padding exterior | 32px (all) |
| Imagen/Icono size | imageSize (default: 120) para imagen, 64 para icono |
| Spacing imagen→mensaje | 24px |
| Mensaje fontSize | 18px |
| Spacing mensaje→subtítulo | 8px |
| Subtítulo fontSize | 14px |
| Spacing subtítulo→botón | 24px |

## 8. COLORES

| Elemento | Color |
|----------|-------|
| Icono | grey400 |
| Mensaje | grey600 |
| Subtítulo | grey500 |
| Botón | Azul de Cupertino (filled) |

## 9. CASOS DE USO

### Mínimo (solo mensaje):
```dart
EmptyState(
  message: 'No hay eventos',
)
```

### Con icono:
```dart
EmptyState(
  icon: CupertinoIcons.calendar,
  message: 'No hay eventos',
  subtitle: 'Crea tu primer evento para comenzar',
)
```

### Con imagen:
```dart
EmptyState(
  imagePath: 'assets/images/empty_calendar.png',
  message: 'Tu calendario está vacío',
  imageSize: 150,
)
```

### Con acción:
```dart
EmptyState(
  icon: CupertinoIcons.calendar,
  message: 'No hay eventos',
  subtitle: 'Crea tu primer evento',
  actionLabel: 'Crear evento',
  onAction: () => _navigateToCreate(),
)
```

### Con fallback de imagen:
```dart
EmptyState(
  imagePath: 'assets/images/nonexistent.png',
  icon: CupertinoIcons.photo,  // Fallback si falla imagen
  message: 'Sin fotos',
)
```

## 10. VARIANTES COMUNES

### No hay datos:
```dart
EmptyState(
  icon: CupertinoIcons.tray,
  message: l10n.noData,
)
```

### No hay eventos:
```dart
EmptyState(
  icon: CupertinoIcons.calendar,
  message: l10n.noEvents,
  subtitle: l10n.createFirstEvent,
  actionLabel: l10n.createEvent,
  onAction: _navigateToCreate,
)
```

### Sin resultados de búsqueda:
```dart
EmptyState(
  icon: CupertinoIcons.search,
  message: l10n.noResults,
  subtitle: l10n.tryDifferentSearch,
)
```

### Sin conexión:
```dart
EmptyState(
  icon: CupertinoIcons.wifi_slash,
  message: l10n.noConnection,
  subtitle: l10n.checkInternet,
  actionLabel: l10n.retry,
  onAction: _retry,
)
```

## 11. LOCALIZACIÓN

**String default**:
- `l10n.noData`: "Sin datos", "No data"

**Uso típico**:
- Todos los strings visibles deberían ser localizados
- message, subtitle, actionLabel deben venir localizados del caller

## 12. DEPENDENCIAS

**Imports**:
- flutter/cupertino.dart
- helpers/platform_widgets.dart (PlatformWidgets)
- helpers/l10n_helpers.dart (context.l10n)
- styles/app_styles.dart (colors, bodyText)

## 13. NOTAS ADICIONALES

- **StatelessWidget**: Sin estado, puramente presentacional
- **Center y mainAxisAlignment**: Siempre centrado vertical y horizontalmente
- **Error handling**: Image.asset tiene errorBuilder robusto
- **Nullable todo**: Todas las propiedades opcionales
- **Default sensible**: imageSize = 120 es buen default
- **CupertinoButton.filled**: iOS native style para botón
- **Text align center**: Todos los textos centrados
- **Flexible**: Acepta cualquier combinación de propiedades
- **Usado extensivamente**: En EventsList, CalendarsScreen, SubscriptionsScreen, etc.
- **Icon fallback**: square_stack es el icono más genérico para "vacío"
- **Size mismatch**: Imagen usa imageSize (120), icono usa 64 hardcoded
- **No animation**: Estado estático, sin animaciones
- **No loading**: Para loading states usar otro widget
