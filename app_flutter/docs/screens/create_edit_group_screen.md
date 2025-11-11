# CreateEditGroupScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/create_edit_group_screen.dart`
**Líneas**: ~260
**Tipo**: ConsumerStatefulWidget
**Propósito**: Pantalla para crear nuevos grupos o editar grupos existentes. Permite gestionar nombre, descripción y eliminar el grupo (solo para creadores/admins).

**Modos de operación**:
- **Modo Crear**: Cuando `widget.group == null`
- **Modo Editar**: Cuando `widget.group != null`

---

## 2. PARÁMETROS DEL CONSTRUCTOR

```dart
const CreateEditGroupScreen({
  super.key,
  this.group, // null = create mode, non-null = edit mode
})
```

- `group` (Group?): Grupo a editar. Si es null, la pantalla funciona en modo creación.

---

## 3. WIDGETS UTILIZADOS

### 3.1. Widgets Propios de la App

#### **AdaptivePageScaffold**
**Uso**:
```dart
AdaptivePageScaffold(
  key: Key(isEditMode ? 'edit_group_screen_scaffold' : 'create_group_screen_scaffold'),
  title: isEditMode ? l10n.editGroup : l10n.createGroup,
  body: ...
)
```

**Configuración**:
- `title`: "Crear Grupo" o "Editar Grupo" según el modo
- El botón de retroceso se muestra automáticamente por el scaffold adaptativo

#### **AdaptiveButton** (para guardar)
```dart
AdaptiveButton(
  config: AdaptiveButtonConfig.primary(),
  text: isEditMode ? l10n.saveChanges : l10n.createGroup,
  icon: isEditMode ? CupertinoIcons.checkmark : CupertinoIcons.plus,
  onPressed: _isLoading || !_isValid ? null : _save,
  isLoading: _isLoading,
)
```

**Configuración**:
- Usa configuración `.primary()` (botón primario azul)
- Texto e icono cambian según el modo
- Se deshabilita si está cargando o los datos no son válidos
- Parámetro `isLoading` muestra indicador de carga

#### **AdaptiveButton** (para eliminar - solo en modo edición)
```dart
if (isEditMode && widget.group!.canManageGroup(currentUserId))
  AdaptiveButton(
    config: AdaptiveButtonConfig.secondary(),
    text: l10n.deleteGroup,
    icon: CupertinoIcons.trash,
    onPressed: _isLoading ? null : _showDeleteConfirmation,
  )
```

**Configuración**:
- Usa configuración `.secondary()` (botón secundario)
- Solo visible si:
  - Está en modo edición
  - El usuario puede gestionar el grupo (creador o admin)

---

## 4. ESTADO Y VARIABLES

### 4.1. Controladores de Texto
```dart
late TextEditingController _nameController;
late TextEditingController _descriptionController;
```

**Inicialización**:
- Se inicializan en `initState()` con los valores del grupo (si existe) o vacíos

### 4.2. Estado de la UI
```dart
bool _isLoading = false;      // Indica si hay una operación en progreso
String? _errorMessage;         // Mensaje de error a mostrar
```

### 4.3. Getters Computados
```dart
bool get isEditMode => widget.group != null;
int get currentUserId => ConfigService.instance.currentUserId;
bool get _isValid => _nameController.text.trim().isNotEmpty;
```

---

## 5. MÉTODOS PRINCIPALES

### 5.1. _save()
**Propósito**: Guardar cambios (crear o actualizar grupo)

**Flujo**:
1. Valida que el nombre no esté vacío
2. Llama a `ApiClient().createGroup()` o `ApiClient().updateGroup()` según el modo
3. Invalida `groupsStreamProvider` para refrescar lista
4. Regresa a la pantalla anterior con `context.pop(true)`

**Integración Realtime**:
```dart
ref.invalidate(groupsStreamProvider);
```
- Después de crear/actualizar, invalida el provider
- Esto fuerza un refresh desde el API
- Realtime mantiene la sincronización automática

### 5.2. _showDeleteConfirmation()
**Propósito**: Mostrar diálogo de confirmación antes de eliminar

**Flujo**:
1. Muestra `CupertinoAlertDialog` con opción de confirmar/cancelar
2. Si se confirma, llama a `_deleteGroup()`

### 5.3. _deleteGroup()
**Propósito**: Eliminar el grupo

**Flujo**:
1. Llama a `ApiClient().deleteGroup()`
2. Invalida `groupsStreamProvider`
3. Regresa a la pantalla anterior
4. Muestra feedback al usuario

---

## 6. VALIDACIONES

### 6.1. Validación de Formulario
- **Nombre del grupo**: Required (mínimo 1 carácter después de trim)
- **Descripción**: Opcional (max 500 caracteres)

### 6.2. Validación de Permisos
- **Botón eliminar**: Solo visible si `widget.group!.canManageGroup(currentUserId)`
  - Esta función verifica si el usuario es creador O admin del grupo

---

## 7. NAVEGACIÓN

### 7.1. Rutas
**Entrada**:
- `/people/groups/create` - Modo crear
- `/people/groups/:groupId/edit` - Modo editar

**Salida**:
- `context.pop(true)` - Éxito (creado/actualizado/eliminado)
- `context.pop(false)` - Cancelado o error

### 7.2. Manejo de Resultados
```dart
// En la pantalla que llama
final result = await context.push('/people/groups/${group.id}/edit', extra: group);
if (result == true && mounted) {
  // Grupo fue eliminado, regresar a lista
  context.pop();
}
```

---

## 8. INTEGRACIÓN CON REPOSITORIO

### 8.1. Métodos del Repositorio Utilizados
```dart
final repo = ref.read(groupRepositoryProvider);

// Crear grupo
await repo.createGroup(
  name: String,
  description: String,
);

// Actualizar grupo
await repo.updateGroup(
  groupId: int,
  name: String,
  description: String,
);

// Eliminar grupo
await repo.deleteGroup(groupId: int);
```

### 8.2. Manejo de Errores
```dart
try {
  final repo = ref.read(groupRepositoryProvider);
  await repo.createGroup(...);
  // Éxito
} catch (e) {
  setState(() {
    _errorMessage = e.toString();
    _isLoading = false;
  });
}
```

---

## 9. INTEGRACIÓN REALTIME

**Patrón utilizado**:
```dart
// Después de cualquier mutación (create/update/delete)
ref.invalidate(groupsStreamProvider);
```

**Comportamiento**:
1. Usuario crea/edita/elimina grupo
2. API procesa la solicitud
3. Se invalida el provider
4. Se fuerza un fetch desde el API
5. Supabase Realtime mantiene sincronización automática
6. Todas las pantallas que usan `groupsStreamProvider` se actualizan automáticamente

**Sin intervención manual**:
- No se actualiza estado local manualmente
- No se llama a `setState()` después de mutaciones
- Realtime maneja todas las actualizaciones

---

## 10. FLUJO COMPLETO

### Modo Crear
```
Usuario toca FAB en PeopleGroupsScreen
→ Navega a /people/groups/create
→ CreateEditGroupScreen (mode: create)
→ Usuario ingresa nombre y descripción
→ Toca botón "Crear Grupo"
→ ApiClient.createGroup()
→ API crea grupo y devuelve grupo creado
→ ref.invalidate(groupsStreamProvider)
→ context.pop(true)
→ Usuario regresa a PeopleGroupsScreen
→ Realtime actualiza lista con nuevo grupo
```

### Modo Editar
```
Usuario toca ícono de editar en GroupDetailScreen
→ Navega a /people/groups/:id/edit
→ CreateEditGroupScreen (mode: edit)
→ Usuario modifica nombre/descripción
→ Toca botón "Guardar Cambios"
→ ApiClient.updateGroup()
→ API actualiza grupo
→ ref.invalidate(groupsStreamProvider)
→ context.pop(true)
→ GroupDetailScreen se actualiza automáticamente vía Realtime
```

### Eliminar Grupo
```
Usuario en modo editar toca "Eliminar Grupo"
→ Muestra confirmación
→ Usuario confirma
→ ApiClient.deleteGroup()
→ API elimina grupo
→ ref.invalidate(groupsStreamProvider)
→ context.pop(true)
→ GroupDetailScreen detecta que grupo no existe
→ Regresa a PeopleGroupsScreen
→ Realtime actualiza lista (grupo eliminado)
```

---

## 11. PERMISOS Y SEGURIDAD

### Backend
- Crear: Cualquier usuario autenticado
- Editar: Solo creador o admin del grupo
- Eliminar: Solo creador o admin del grupo

### Frontend
- Botón "Eliminar Grupo" solo visible si `canManageGroup()` es true
- Esta función verifica en el modelo Group si el usuario es creador O admin

---

## 12. TRADUCCIONES UTILIZADAS

```dart
l10n.createGroup        // "Crear Grupo"
l10n.editGroup          // "Editar Grupo"
l10n.groupName          // "Nombre del Grupo"
l10n.groupNamePlaceholder // "Ingresa el nombre del grupo"
l10n.groupDescription   // "Descripción del Grupo"
l10n.groupDescriptionPlaceholder // "Ingresa la descripción del grupo (opcional)"
l10n.saveChanges        // "Guardar Cambios"
l10n.deleteGroup        // "Eliminar Grupo"
l10n.deleteGroupConfirmation // "¿Estás seguro...?"
l10n.groupNameRequired  // "El nombre del grupo es obligatorio"
```

---

## 13. MEJORAS FUTURAS POTENCIALES

1. **Imagen del grupo**: Permitir subir imagen de perfil del grupo
2. **Configuración de privacidad**: Grupo público/privado
3. **Categorías**: Asignar categorías a grupos
4. **Descripción rica**: Editor de texto enriquecido para descripción
5. **Validaciones adicionales**: Longitud máxima del nombre, palabras prohibidas, etc.
