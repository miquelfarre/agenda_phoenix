# EventDetailActions - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/event_detail_actions.dart`
**Líneas**: 45
**Tipo**: StatelessWidget
**Propósito**: Botones de acción (Invitar/Editar) en pantalla de detalle de evento

## 2. CLASE Y PROPIEDADES

### EventDetailActions (líneas 5-44)

**Propiedades**:

| Propiedad | Tipo | Default | Required | Descripción |
|-----------|------|---------|----------|-------------|
| `isEventOwner` | bool | - | Sí | Si el usuario es propietario del evento |
| `canInvite` | bool? | null | No | Si el usuario puede invitar (null = usa isEventOwner) |
| `onEdit` | VoidCallback? | null | No | Callback al editar evento |
| `onInvite` | VoidCallback? | null | No | Callback al invitar usuarios |

## 3. MÉTODO BUILD

### build(BuildContext context) (líneas 14-43)

**Lógica de permisos** (línea 16):
```dart
final bool shouldShowInvite = canInvite ?? isEventOwner;
```
- Si `canInvite` es null → usa `isEventOwner`
- Si `canInvite` tiene valor → usa ese valor

**Estructura** (líneas 18-42):
```
Column
├── [Condicional] if (shouldShowInvite)
│   └── SizedBox(width: infinity)
│       └── AdaptiveButton("Invitar usuarios")
│           - config: primary()
│           - icon: person_add
│           - onPressed: onInvite?.call()
├── [Condicional] if (shouldShowInvite && isEventOwner)
│   └── SizedBox(height: 12)  // Spacing
└── [Condicional] if (isEventOwner)
    └── SizedBox(width: infinity)
        └── AdaptiveButton("Editar evento")
            - config: primary()
            - icon: pencil
            - onPressed: onEdit
            - key: 'event_detail_edit_button'
```

## 4. LÓGICA DE VISUALIZACIÓN

### Casos según permisos:

**Caso 1: Owner** (isEventOwner=true, canInvite=null):
```
Column
├── Botón "Invitar usuarios"
├── SizedBox(height: 12)
└── Botón "Editar evento"
```

**Caso 2: Admin/Puede invitar** (isEventOwner=false, canInvite=true):
```
Column
└── Botón "Invitar usuarios"
```
(No hay spacing ni botón editar)

**Caso 3: Usuario normal** (isEventOwner=false, canInvite=false):
```
Column
(vacío)
```

**Caso 4: Owner con canInvite=false** (isEventOwner=true, canInvite=false):
```
Column
└── Botón "Editar evento"
```
(No hay spacing porque solo hay 1 botón)

## 5. BOTONES

### Botón "Invitar usuarios" (líneas 21-32):

**Configuración**:
- **Width**: double.infinity (full width)
- **Config**: AdaptiveButtonConfig.primary() (botón principal)
- **Text**: l10n.inviteUsers
- **Icon**: CupertinoIcons.person_add
- **onPressed**: Llama a `onInvite?.call()` con print de debug

**Debug log** (línea 28):
```dart
print('🟢 [EventDetailActions] Invite button pressed');
```

### Botón "Editar evento" (líneas 36-39):

**Configuración**:
- **Width**: double.infinity (full width)
- **Config**: AdaptiveButtonConfig.primary()
- **Text**: l10n.editEvent
- **Icon**: CupertinoIcons.pencil
- **onPressed**: onEdit directamente (sin wrapper)
- **Key**: 'event_detail_edit_button' (para testing)

## 6. SPACING

### Spacing condicional (línea 34):
```dart
if (shouldShowInvite && isEventOwner) const SizedBox(height: 12)
```

**Lógica**:
- Solo añade spacing si AMBOS botones se muestran
- Si solo uno se muestra → no spacing
- Height: 12px

## 7. LOCALIZACIÓN

Strings localizados:
- `l10n.inviteUsers`: "Invitar usuarios", "Invite users"
- `l10n.editEvent`: "Editar evento", "Edit event"

## 8. DEPENDENCIAS

**Imports**:
- flutter/cupertino.dart
- helpers/l10n_helpers.dart
- adaptive/adaptive_button.dart (AdaptiveButton, AdaptiveButtonConfig)

## 9. USO TÍPICO

### En EventActionSection:
```dart
EventDetailActions(
  isEventOwner: true,
  canInvite: true,
  onEdit: () => _navigateToEdit(),
  onInvite: () => _navigateToInvite(),
)
```

### Para admins:
```dart
EventDetailActions(
  isEventOwner: false,
  canInvite: true,  // Admin puede invitar
  onInvite: () => _navigateToInvite(),
)
```

### Para usuarios normales:
```dart
EventDetailActions(
  isEventOwner: false,
  canInvite: false,
  // No se muestra ningún botón
)
```

## 10. NOTAS ADICIONALES

- **StatelessWidget**: Sin estado, puramente presentacional
- **Nullable callbacks**: Usa `?.call()` para seguridad
- **Full width buttons**: Todos los botones ocupan ancho completo
- **Primary style**: Ambos botones usan estilo primario (azul)
- **Test key**: Solo el botón edit tiene key para testing
- **Debug logging**: Solo el botón invite tiene print de debug
- **Fallback logic**: canInvite null → usa isEventOwner como fallback
- **Simple widget**: Sin lógica compleja, solo condicionales de UI
- **Usado en**: EventActionSection (event_detail/event_action_section.dart)
