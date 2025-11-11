# GroupDetailScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/group_detail_screen.dart`
**Líneas**: ~500
**Tipo**: ConsumerStatefulWidget with WidgetsBindingObserver
**Propósito**: Pantalla para ver detalles de un grupo y gestionar miembros. Permite ver información del grupo, lista de miembros con roles, y realizar acciones de administración (añadir/eliminar miembros, cambiar roles).

**Características principales**:
- **Actualización en tiempo real** vía Supabase Realtime
- Gestión de permisos basada en roles (creador/admin/miembro)
- Acciones contextuales según el rol del usuario

---

## 2. PARÁMETROS DEL CONSTRUCTOR

```dart
const GroupDetailScreen({
  super.key,
  required this.groupId,
  this.initialGroup,
})
```

- `groupId` (int): ID del grupo a mostrar (requerido)
- `initialGroup` (Group?): Grupo inicial para UI optimista (opcional)

---

## 3. INTEGRACIÓN REALTIME

### 3.1. Provider Utilizado
```dart
final groupsAsync = ref.watch(groupsStreamProvider);
```

**Comportamiento**:
- Escucha el stream de **todos** los grupos del usuario
- Filtra por `groupId` para obtener el grupo específico
- Se actualiza automáticamente cuando:
  - Se añaden/eliminan miembros
  - Se cambian roles (admin ↔ member)
  - Se edita el grupo
  - Se elimina el grupo

### 3.2. Manejo del Ciclo de Vida
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed && mounted) {
    ref.invalidate(groupsStreamProvider);
  }
}
```

**Propósito**: Refrescar datos cuando la app vuelve del background

### 3.3. Flujo de Actualización
```
Usuario realiza acción (ej: promover a admin)
  ↓
Llamada al repositorio (grantAdminPermission)
  ↓
API de Supabase actualiza la base de datos
  ↓
Supabase Realtime emite evento de cambio
  ↓
GroupRepository recibe evento y actualiza caché
  ↓
groupsStreamProvider emite nuevo estado
  ↓
ref.watch() detecta cambio
  ↓
Widget se reconstruye automáticamente
  ↓
UI muestra datos actualizados
```

**Sin intervención manual**: No se requiere `setState()` después de mutaciones

---

## 4. WIDGETS UTILIZADOS

### 4.1. Widgets Propios de la App

#### **AdaptivePageScaffold**
```dart
AdaptivePageScaffold(
  key: const Key('group_detail_screen_scaffold'),
  title: _currentGroup?.name ?? context.l10n.groupDetails,
  
  actions: [
    if (_currentGroup != null && _currentGroup!.canManageGroup(currentUserId))
      CupertinoButton(
        onPressed: () => _navigateToEdit(_currentGroup!),
        child: Icon(CupertinoIcons.pencil),
      ),
  ],
  body: ...
)
```

**Configuración**:
- Título dinámico (nombre del grupo)
- Botón de editar solo visible para creadores/admins
- Botón de retroceso siempre visible

#### **UserAvatar**
```dart
UserAvatar(user: member, radius: 20)
```

**Uso**: Mostrar avatar de cada miembro en la lista

#### **EmptyState**
```dart
EmptyState(
  icon: CupertinoIcons.exclamationmark_triangle,
  message: context.l10n.groupNotFound,
)
```

**Uso**: Mostrar cuando el grupo no existe o no se encuentra

#### **AdaptiveButton**
```dart
// Botón añadir miembros (creador/admin)
AdaptiveButton(
  config: AdaptiveButtonConfig.primary(),
  text: l10n.addMembers,
  icon: CupertinoIcons.person_add,
  onPressed: () => _navigateToAddMembers(group),
)

// Botón salir del grupo (miembros no creadores)
AdaptiveButton(
  config: AdaptiveButtonConfig.secondary(),
  text: l10n.leaveGroup,
  icon: CupertinoIcons.arrow_right_square,
  onPressed: () => _leaveGroup(group),
)
```

---

## 5. ESTRUCTURA DE LA UI

### 5.1. Secciones Principales

```
AdaptivePageScaffold
└── SingleChildScrollView
    └── Column
        ├── Info Card (nombre, descripción, contador de miembros)
        ├── Members Section (lista de todos los miembros)
        ├── Add Members Button (solo creador/admin)
        └── Leave Group Button (solo miembros no creadores)
```

### 5.2. Info Card
```dart
Container(
  decoration: AppStyles.cardDecoration,
  child: Column(
    - Avatar circular del grupo (ícono de grupo)
    - Nombre del grupo
    - Contador de miembros
    - Descripción (si existe)
  )
)
```

### 5.3. Members Section
```dart
Container(
  decoration: AppStyles.cardDecoration,
  child: Column(
    - Header con "Miembros" y badge de contador
    - Lista de miembros con roles:
      * Creador (primero)
      * Admins
      * Miembros regulares
    - Cada miembro muestra:
      * Avatar
      * Nombre
      * Badge de rol (Creador/Admin)
      * Botones de acción (si el usuario puede gestionar)
  )
)
```

### 5.4. Member Tile (para cada miembro)
```dart
Row(
  - UserAvatar
  - Nombre + badge de rol
  - Botón toggle admin (estrella)
  - Botón eliminar miembro (X)
)
```

**Visibilidad de botones**:
- Solo visible si `canModifyThisMember` es true
- `canModifyThisMember` = usuario es creador/admin Y miembro no es creador Y miembro no es el usuario actual

---

## 6. ESTADO Y VARIABLES

### 6.1. Estado Local
```dart
Group? _currentGroup;         // Referencia al grupo actual (para título)
bool _isProcessing = false;   // Indica si hay operación en progreso
```

### 6.2. Getters
```dart
int get currentUserId => ConfigService.instance.currentUserId;
```

---

## 7. MÉTODOS PRINCIPALES

### 7.1. Navegación

#### _navigateToEdit()
```dart
Future<void> _navigateToEdit(Group group) async {
  final result = await context.push('/people/groups/${group.id}/edit', extra: group);
  if (result == true && mounted) {
    context.pop(); // Grupo fue eliminado
  }
}
```

**Propósito**: Navegar a pantalla de edición
**Manejo de resultado**: Si devuelve true, el grupo fue eliminado → regresar a lista

#### _navigateToAddMembers()
```dart
Future<void> _navigateToAddMembers(Group group) async {
  await context.push('/people/groups/${group.id}/add-members', extra: group);
}
```

**Propósito**: Navegar a pantalla de añadir miembros
**Sin refetch manual**: Realtime actualiza automáticamente

### 7.2. Gestión de Roles

#### _grantAdmin()
```dart
Future<void> _grantAdmin(User member, Group group) async {
  // 1. Mostrar diálogo de confirmación
  final confirmed = await showCupertinoDialog<bool>(...);

  if (confirmed == true) {
    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(groupRepositoryProvider);
      await repo.grantAdminPermission(
        groupId: group.id,
        userId: member.id,
      );

      // Mostrar feedback
      PlatformWidgets.showSnackBar(
        message: l10n.memberMadeAdmin(member.displayName),
        isError: false,
      );
    } catch (e) {
      // Mostrar error
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
```

**Flujo**:
1. Confirmar con usuario
2. Llamar a repositorio
3. API actualiza role a "admin"
4. Realtime emite cambio
5. UI se actualiza automáticamente
6. Mostrar feedback

#### _removeAdmin()
Similar a `_grantAdmin()` pero llama a `repo.removeAdminPermission()`

### 7.3. Gestión de Miembros

#### _removeMember()
```dart
Future<void> _removeMember(User member, Group group) async {
  final confirmed = await showCupertinoDialog<bool>(...);

  if (confirmed == true) {
    await repo.removeMemberFromGroup(
      groupId: group.id,
      memberUserId: member.id,
    );

    PlatformWidgets.showSnackBar(
      message: l10n.memberRemovedFromGroup(member.displayName),
      isError: false,
    );
  }
}
```

**Propósito**: Eliminar un miembro del grupo
**Actualización**: Automática vía Realtime

#### _leaveGroup()
```dart
Future<void> _leaveGroup(Group group) async {
  final confirmed = await showCupertinoDialog<bool>(...);

  if (confirmed == true) {
    await repo.removeMemberFromGroup(
      groupId: group.id,
      memberUserId: currentUserId,
    );

    context.pop(); // Regresar a lista
    PlatformWidgets.showSnackBar(
      message: l10n.leftGroup(group.name),
      isError: false,
    );
  }
}
```

**Propósito**: Permitir al usuario salirse del grupo
**Comportamiento especial**: Regresa automáticamente a la lista después de salir

---

## 8. LÓGICA DE PERMISOS

### 8.1. Roles en el Sistema
```dart
- Creador: group.isCreator(userId)
- Admin: group.isAdmin(userId) - incluye creador
- Miembro: group.isMember(userId)
```

### 8.2. Permisos por Rol

| Acción | Creador | Admin | Miembro |
|--------|---------|-------|---------|
| Ver grupo | ✅ | ✅ | ✅ |
| Editar grupo | ✅ | ✅ | ❌ |
| Eliminar grupo | ✅ | ✅ | ❌ |
| Añadir miembros | ✅ | ✅ | ❌ |
| Eliminar miembros | ✅ | ✅ | ❌ |
| Promover a admin | ✅ | ✅ | ❌ |
| Quitar admin | ✅ | ✅ | ❌ |
| Salir del grupo | ❌* | ✅ | ✅ |

*El creador no puede salirse del grupo (debe eliminarlo o transferir ownership)

### 8.3. Verificación de Permisos
```dart
final canManage = group.canManageGroup(currentUserId);
// canManage = true si es creador O admin

final canModifyThisMember = canManage && !isCreator && member.id != currentUserId;
// Puede modificar si:
// - Usuario puede gestionar el grupo
// - El miembro no es el creador
// - El miembro no es el propio usuario
```

---

## 9. INTEGRACIÓN CON REPOSITORIO

### 9.1. Métodos Utilizados

```dart
// Promover a admin
await repo.grantAdminPermission(groupId: int, userId: int);

// Quitar admin
await repo.removeAdminPermission(groupId: int, userId: int);

// Eliminar miembro
await repo.removeMemberFromGroup(groupId: int, memberUserId: int);
```

### 9.2. Comportamiento del Repositorio

```dart
// Backend actualiza group_memberships table
→ Supabase Realtime detecta cambio
→ GroupRepository recibe evento
→ Actualiza _cachedGroups
→ Actualiza Hive cache
→ Emite a groupsStream
→ groupsStreamProvider notifica cambio
→ Widget se reconstruye
```

**Tiempo típico**: 100-500ms para el ciclo completo

---

## 10. MANEJO DE ESTADOS

### 10.1. AsyncValue States
```dart
return groupsAsync.when(
  data: (groups) {
    final group = groups.firstWhere(...);
    return _buildContent(group);
  },
  loading: () => Center(child: CupertinoActivityIndicator()),
  error: (error, stack) => EmptyState(
    icon: CupertinoIcons.exclamationmark_triangle,
    message: error.toString(),
  ),
);
```

### 10.2. Grupo No Encontrado
```dart
if (group == null) {
  return EmptyState(
    icon: CupertinoIcons.exclamationmark_triangle,
    message: context.l10n.groupNotFound,
  );
}
```

**Casos**:
- Grupo fue eliminado
- Usuario fue removido del grupo
- ID inválido

### 10.3. Lista de Miembros Vacía
```dart
if (allMembers.isEmpty)
  Center(
    child: Text(
      l10n.noMembers,
      style: AppStyles.bodyText.copyWith(color: AppStyles.grey500),
    ),
  )
```

---

## 11. ORDEN DE MIEMBROS

### 11.1. Algoritmo de Ordenación
```dart
final allMembers = <User>[];
final addedIds = <int>{};

// 1. Añadir creador primero
if (group.creator != null && !addedIds.contains(group.creator!.id)) {
  allMembers.add(group.creator!);
  addedIds.add(group.creator!.id);
}

// 2. Añadir admins
for (var admin in group.admins) {
  if (!addedIds.contains(admin.id)) {
    allMembers.add(admin);
    addedIds.add(admin.id);
  }
}

// 3. Añadir miembros regulares
for (var member in group.members) {
  if (!addedIds.contains(member.id)) {
    allMembers.add(member);
    addedIds.add(member.id);
  }
}
```

**Orden final**:
1. Creador
2. Admins (en orden de la lista)
3. Miembros regulares (en orden de la lista)

**Prevención de duplicados**: Set `addedIds` evita mostrar el mismo usuario múltiples veces

---

## 12. FLUJOS COMPLETOS

### 12.1. Promover Miembro a Admin
```
Usuario toca ícono de estrella en miembro
→ Muestra diálogo de confirmación
→ Usuario confirma
→ setState(_isProcessing = true)
→ repo.grantAdminPermission()
→ API actualiza role = "admin" en group_memberships
→ Supabase Realtime emite evento UPDATE
→ GroupRepository actualiza caché
→ groupsStreamProvider emite nuevo estado
→ Widget detecta cambio vía ref.watch()
→ _buildMemberTile() se reconstruye
→ Estrella cambia de outline a filled
→ Badge "Admin" aparece debajo del nombre
→ setState(_isProcessing = false)
→ Muestra snackbar de éxito
```

### 12.2. Eliminar Miembro
```
Usuario toca ícono X en miembro
→ Muestra diálogo de confirmación
→ Usuario confirma
→ repo.removeMemberFromGroup()
→ API elimina fila de group_memberships
→ Supabase Realtime emite evento DELETE
→ GroupRepository actualiza caché (elimina del array)
→ groupsStreamProvider emite nuevo estado
→ Widget se reconstruye
→ Miembro desaparece de la lista
→ Contador de miembros se actualiza
→ Muestra snackbar
```

### 12.3. Salir del Grupo
```
Usuario toca botón "Salir del Grupo"
→ Muestra confirmación
→ Usuario confirma
→ repo.removeMemberFromGroup(userId: currentUserId)
→ API elimina membership
→ Realtime actualiza
→ groupsStreamProvider emite estado sin este grupo
→ GroupDetailScreen detecta group == null
→ context.pop() - regresa a PeopleGroupsScreen
→ Muestra snackbar "Saliste de {nombre}"
→ PeopleGroupsScreen se actualiza (grupo desaparece de lista)
```

---

## 13. MANEJO DE ERRORES

### 13.1. Errores de Red
```dart
try {
  await repo.grantAdminPermission(...);
} catch (e) {
  PlatformWidgets.showSnackBar(
    message: '${l10n.error}: ${e.toString()}',
    isError: true,
  );
}
```

**Nota**: Los errores se convierten a string con `.toString()` para mostrar mensajes al usuario

### 13.2. Errores de Permisos
Si el backend rechaza la operación (403), se muestra el mensaje del servidor

### 13.3. Grupo Eliminado Durante Sesión
```dart
final group = groups.firstWhere(..., orElse: () => null);
if (group == null) {
  return EmptyState(message: l10n.groupNotFound);
}
```

---

## 14. TRADUCCIONES UTILIZADAS

```dart
l10n.groupDetails         // "Detalles del Grupo"
l10n.groupMembers         // "Miembros del Grupo"
l10n.addMembers           // "Añadir Miembros"
l10n.leaveGroup           // "Salir del Grupo"
l10n.creator              // "Creador"
l10n.groupAdmin           // "Admin del Grupo"
l10n.makeAdmin            // "Hacer Admin"
l10n.removeAdmin          // "Quitar Admin"
l10n.deleteFromGroup      // "Eliminar del Grupo"
l10n.confirmMakeAdmin(name)        // "¿Hacer admin a {name}?"
l10n.confirmRemoveAdmin(name)      // "¿Quitar admin a {name}?"
l10n.confirmRemoveFromGroup(name)  // "¿Eliminar a {name}?"
l10n.confirmLeaveGroup(name)       // "¿Salir de {name}?"
l10n.memberMadeAdmin(name)         // "{name} es ahora admin"
l10n.memberRemovedAdmin(name)      // "{name} ya no es admin"
l10n.memberRemovedFromGroup(name)  // "{name} eliminado del grupo"
l10n.leftGroup(name)               // "Saliste de {name}"
l10n.groupNotFound        // "Grupo no encontrado"
l10n.noMembers            // "No hay miembros en este grupo"
l10n.confirm              // "Confirmar"
l10n.cancel               // "Cancelar"
l10n.remove               // "Eliminar"
l10n.leave                // "Salir"
```

---

## 15. OPTIMIZACIONES

### 15.1. UI Optimista
```dart
Group? _currentGroup;

// Inicializar con initialGroup si existe
_currentGroup = widget.initialGroup;

// Actualizar cuando llega data del stream
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted && _currentGroup?.id != group.id) {
    setState(() => _currentGroup = group);
  }
});
```

**Beneficio**: El título se muestra inmediatamente sin esperar al stream

### 15.2. Prevención de Múltiples Operaciones
```dart
bool _isProcessing = false;

// En cada botón:
onPressed: _isProcessing ? null : () => _grantAdmin(...),
```

**Beneficio**: Evita doble-tap y operaciones concurrentes

---

## 16. TESTING

### 16.1. Keys para Testing
```dart
Key('group_detail_screen_scaffold')
Key('group_detail_edit_button')
Key('group_detail_add_members_button')
Key('group_detail_leave_button')
Key('group_member_${member.id}_toggle_admin_button')
Key('group_member_${member.id}_remove_button')
Key('grant_admin_confirm_button')
Key('remove_admin_confirm_button')
Key('remove_member_confirm_button')
Key('leave_group_confirm_button')
```

---

## 17. MEJORAS FUTURAS POTENCIALES

1. **Búsqueda de miembros**: Filtrar lista cuando hay muchos miembros
2. **Roles personalizados**: Más allá de admin/miembro
3. **Estadísticas**: Actividad de miembros, eventos del grupo
4. **Notificaciones**: Alertar cuando te hacen admin o te eliminan
5. **Transferir ownership**: Permitir al creador transferir el grupo a otro admin
6. **Vista de actividad**: Log de cambios en el grupo
7. **Invitaciones pendientes**: Ver usuarios invitados que aún no aceptan
