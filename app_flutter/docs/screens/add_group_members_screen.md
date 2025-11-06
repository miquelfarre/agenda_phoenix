# AddGroupMembersScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/add_group_members_screen.dart`
**Líneas**: ~280
**Tipo**: ConsumerStatefulWidget
**Propósito**: Pantalla para seleccionar y añadir múltiples contactos a un grupo. Permite búsqueda, selección múltiple, y añadir todos los seleccionados de una vez.

**Características principales**:
- Selección múltiple de contactos
- Búsqueda en tiempo real
- Filtrado automático (excluye miembros existentes y usuarios públicos)
- Contador de seleccionados
- Operación batch (añadir todos de una vez)

---

## 2. PARÁMETROS DEL CONSTRUCTOR

```dart
const AddGroupMembersScreen({
  super.key,
  required this.group,
})
```

- `group` (Group): Grupo al que se añadirán miembros (requerido)

---

## 3. ESTADO Y VARIABLES

### 3.1. Listas y Conjuntos
```dart
List<User> _contacts = [];                // Todos los contactos disponibles
final Set<int> _selectedUserIds = {};     // IDs de usuarios seleccionados
```

**Por qué Set para seleccionados**:
- Búsqueda O(1) para verificar si está seleccionado
- No permite duplicados

### 3.2. Estados de Carga
```dart
bool _isLoadingContacts = false;  // Cargando lista de contactos
bool _isAdding = false;           // Añadiendo miembros seleccionados
String? _errorMessage;            // Error a mostrar
```

### 3.3. Controladores
```dart
final TextEditingController _searchController = TextEditingController();
```

### 3.4. Getters
```dart
int get currentUserId => ConfigService.instance.currentUserId;
```

---

## 4. CICLO DE VIDA

### 4.1. Inicialización
```dart
@override
void initState() {
  super.initState();
  _loadContacts();  // Cargar contactos inmediatamente
}
```

### 4.2. Limpieza
```dart
@override
void dispose() {
  _searchController.dispose();
  super.dispose();
}
```

---

## 5. CARGA DE CONTACTOS

### 5.1. _loadContacts()
```dart
Future<void> _loadContacts() async {
  setState(() {
    _isLoadingContacts = true;
    _errorMessage = null;
  });

  try {
    final contactsData = await ref.read(userRepositoryProvider).fetchContacts(currentUserId);

    setState(() {
      _contacts = contactsData
          .map((c) => User.fromJson(c))
          .where((user) {
            // Filtrar:
            // 1. Usuarios ya en el grupo
            final isAlreadyMember =
                widget.group.members.any((m) => m.id == user.id) ||
                widget.group.admins.any((a) => a.id == user.id) ||
                widget.group.creatorId == user.id;

            // 2. Usuarios públicos (no pueden estar en grupos)
            final isPublic = user.isPublic;

            return !isAlreadyMember && !isPublic;
          })
          .toList();
      _isLoadingContacts = false;
    });
  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
      _isLoadingContacts = false;
    });
  }
}
```

**Lógica de filtrado**:
1. **Excluir miembros existentes**: Busca en `members`, `admins` y verifica si es el `creatorId`
2. **Excluir usuarios públicos**: Los usuarios de Instagram (públicos) no pueden ser miembros de grupos (restricción del backend)

### 5.2. Sin Realtime
**Importante**: Esta pantalla NO usa Realtime porque:
- Es una pantalla temporal/modal
- Los contactos no cambian frecuentemente durante la sesión
- Se carga una vez al abrir la pantalla

---

## 6. LÓGICA DE SELECCIÓN

### 6.1. Toggle de Selección
```dart
onTap: () {
  setState(() {
    if (isSelected) {
      _selectedUserIds.remove(contact.id);
    } else {
      _selectedUserIds.add(contact.id);
    }
  });
}
```

**Comportamiento**:
- Tap en contacto → toggle selección
- No hay límite de selección
- Set maneja automáticamente duplicados

### 6.2. Limpiar Selección
```dart
CupertinoButton(
  onPressed: () => setState(() => _selectedUserIds.clear()),
  child: Text(l10n.clearSelection),
)
```

**Ubicación**: En banner de "X seleccionados"

---

## 7. AÑADIR MIEMBROS

### 7.1. _addSelectedMembers()
```dart
Future<void> _addSelectedMembers() async {
  if (_selectedUserIds.isEmpty) return;

  setState(() {
    _isAdding = true;
    _errorMessage = null;
  });

  try {
    final repo = ref.read(groupRepositoryProvider);

    // Añadir cada usuario (batch)
    for (final userId in _selectedUserIds) {
      await repo.addMemberToGroup(
        groupId: widget.group.id,
        userId: userId,
      );
    }

    if (mounted) {
      context.pop(true); // Indicar éxito
      PlatformWidgets.showSnackBar(
        message: '${_selectedUserIds.length} ${l10n.membersAdded}',
        isError: false,
      );
    }
  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
      _isAdding = false;
    });
  }
}
```

**Flujo**:
1. Validar que hay seleccionados
2. Iterar sobre cada ID seleccionado
3. Llamar a `addMemberToGroup()` para cada uno
4. Mostrar feedback al usuario
5. Regresar a pantalla anterior
6. GroupDetailScreen se actualiza automáticamente vía Realtime

### 7.2. Operación Batch
**Nota**: Se hace un `await` por cada usuario (secuencial), no en paralelo.

**Razón**:
- Evitar saturar el servidor
- Facilita manejo de errores
- Las operaciones son rápidas (~50-100ms cada una)

**Mejora futura**: Implementar endpoint batch en el backend para añadir múltiples miembros con una sola llamada

---

## 8. BÚSQUEDA

### 8.1. Filtrado en Tiempo Real
```dart
final filteredContacts = _searchController.text.isEmpty
    ? _contacts
    : _contacts.where((contact) {
        final name = contact.displayName.toLowerCase();
        final searchLower = _searchController.text.toLowerCase();
        return name.contains(searchLower);
      }).toList();
```

**Comportamiento**:
- Búsqueda case-insensitive
- Busca en `displayName` (nombre completo)
- Filtrado instantáneo (cada keystroke)
- Si búsqueda vacía → muestra todos

### 8.2. Estado Vacío en Búsqueda
```dart
if (filteredContacts.isEmpty) {
  return EmptyState(
    icon: CupertinoIcons.search,
    message: l10n.noContactsFoundWithSearch,
  );
}
```

---

## 9. ESTRUCTURA DE LA UI

### 9.1. Layout Principal
```
AdaptivePageScaffold
└── Column
    ├── Search Bar (siempre visible)
    ├── Selected Count Banner (condicional)
    ├── Error Message (condicional)
    ├── Contacts List (Expanded)
    └── Add Button (sticky bottom, condicional)
```

### 9.2. Search Bar
```dart
Container(
  padding: const EdgeInsets.all(16),
  child: PlatformWidgets.platformTextField(
    controller: _searchController,
    placeholder: l10n.searchContacts,
    prefixIcon: PlatformWidgets.platformIcon(CupertinoIcons.search),
    onChanged: (_) => setState(() {}),
  ),
)
```

**Propósito**: Búsqueda instantánea de contactos

### 9.3. Selected Count Banner
```dart
if (_selectedUserIds.isNotEmpty)
  Container(
    color: AppStyles.blue600.withOpacity(0.1),
    child: Row(
      - Checkmark icon
      - "X seleccionado(s)"
      - Botón "Limpiar"
    )
  )
```

**Visibilidad**: Solo cuando `_selectedUserIds.isNotEmpty`

### 9.4. Contact Tile
```dart
Container(
  decoration: AppStyles.cardDecoration,
  child: CupertinoListTile(
    leading: UserAvatar(user: contact, radius: 24),
    title: Text(contact.displayName),
    trailing: isSelected
        ? Icon(CupertinoIcons.checkmark_circle_fill, color: blue)
        : Icon(CupertinoIcons.circle, color: grey),
    onTap: () => toggleSelection(),
  ),
)
```

**Estados visuales**:
- No seleccionado: círculo outline gris
- Seleccionado: círculo relleno azul con checkmark

### 9.5. Add Button (Sticky Bottom)
```dart
if (_selectedUserIds.isNotEmpty)
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: background,
      border: Border(top: BorderSide(color: grey)),
    ),
    child: SafeArea(
      top: false,
      child: AdaptiveButton(
        config: AdaptiveButtonConfig.primary(),
        text: '${l10n.addMembers} (${_selectedUserIds.length})',
        icon: CupertinoIcons.person_add,
        onPressed: _isAdding ? null : _addSelectedMembers,
        isLoading: _isAdding,
      ),
    ),
  )
```

**Características**:
- Fijo en la parte inferior
- SafeArea para evitar notch
- Borde superior para separación visual
- Texto dinámico: "Añadir X Miembro(s)"
- Solo visible si hay seleccionados

---

## 10. ESTADOS DE LA UI

### 10.1. Loading (Cargando Contactos)
```dart
if (_isLoadingContacts) {
  return const Center(child: CupertinoActivityIndicator());
}
```

### 10.2. Empty (Sin Contactos)
```dart
if (_contacts.isEmpty) {
  return EmptyState(
    icon: CupertinoIcons.person_2,
    message: l10n.noContactsToAdd,
  );
}
```

**Razones**:
- No hay contactos en la agenda
- Todos los contactos ya son miembros
- Todos los contactos son usuarios públicos

### 10.3. Search No Results
```dart
if (filteredContacts.isEmpty) {
  return EmptyState(
    icon: CupertinoIcons.search,
    message: l10n.noContactsFoundWithSearch,
  );
}
```

### 10.4. Error
```dart
if (_errorMessage != null)
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppStyles.red100,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      - Icon(exclamationmark_triangle, color: red)
      - Text(_errorMessage, color: red)
    )
  )
```

---

## 11. NAVEGACIÓN

### 11.1. Entrada
```
GroupDetailScreen
  ↓ Usuario toca "Añadir Miembros"
  ↓ context.push('/people/groups/:id/add-members', extra: group)
  ↓
AddGroupMembersScreen
```

### 11.2. Salida
```dart
// Éxito
context.pop(true);  // Regresa a GroupDetailScreen

// Usuario cancela (back button)
context.pop();  // Sin parámetro = null
```

### 11.3. Manejo en Pantalla Padre
```dart
// En GroupDetailScreen
await context.push('/people/groups/${group.id}/add-members', extra: group);
// No necesita verificar resultado
// Realtime actualiza automáticamente
```

---

## 12. INTEGRACIÓN CON REPOSITORIO

### 12.1. Método Utilizado
```dart
await repo.addMemberToGroup(
  groupId: int,
  memberUserId: int,
);
```

**Arquitectura**: Screen → Provider → Repository → ApiClient

**Comportamiento del repositorio**:
1. Llama a `ApiClient().createGroupMembership()`
2. Backend crea fila en `group_memberships`
3. Supabase Realtime emite evento INSERT
4. GroupRepository actualiza caché
5. groupsStreamProvider emite nuevo estado
6. GroupDetailScreen se actualiza automáticamente

### 12.2. Sin Invalidación Manual
```dart
// ❌ NO SE HACE ESTO:
await repo.addMemberToGroup(...);
ref.invalidate(groupsStreamProvider);

// ✅ SE HACE ESTO:
await repo.addMemberToGroup(...);
context.pop(true);
// Realtime se encarga del resto
```

---

## 13. VALIDACIONES Y RESTRICCIONES

### 13.1. Usuarios Públicos Bloqueados
```dart
final isPublic = user.isPublic;
return !isAlreadyMember && !isPublic;
```

**Razón**: El backend rechaza añadir usuarios públicos a grupos
**Mensaje del backend**: "Public users cannot be added to groups"

### 13.2. Miembros Existentes Filtrados
```dart
final isAlreadyMember =
    widget.group.members.any((m) => m.id == user.id) ||
    widget.group.admins.any((a) => a.id == user.id) ||
    widget.group.creatorId == user.id;
```

**Propósito**: Evitar intentar añadir miembros que ya están en el grupo

### 13.3. Selección Vacía
```dart
if (_selectedUserIds.isEmpty) return;
```

**En `_addSelectedMembers()`**: Previene llamada innecesaria al backend

---

## 14. MANEJO DE ERRORES

### 14.1. Error al Cargar Contactos
```dart
catch (e) {
  setState(() {
    _errorMessage = e.toString();
    _isLoadingContacts = false;
  });
}
```

**Visualización**: Banner rojo arriba de la lista

### 14.2. Error al Añadir Miembros
```dart
catch (e) {
  setState(() {
    _errorMessage = e.toString();
    _isAdding = false;  // NO hace pop()
  });
}
```

**Comportamiento**:
- Muestra error
- Permanece en la pantalla
- Usuario puede reintentar

### 14.3. Errores Parciales
**Situación**: Si falla añadir el 3er usuario de 5:
- Los primeros 2 ya fueron añadidos ✅
- El 3er falla ❌
- Los últimos 2 no se procesan ❌

**Mejora futura**: Implementar rollback o continuar con los restantes

---

## 15. TRADUCCIONES UTILIZADAS

```dart
l10n.addMembers                    // "Añadir Miembros"
l10n.searchContacts                // "Buscar contactos..."
l10n.selectedCount(count)          // "{count} seleccionado(s)"
l10n.clearSelection                // "Limpiar"
l10n.addSelectedMembers(count)     // "Añadir {count} Miembro(s)"
l10n.membersAdded(count)           // "{count} miembro(s) añadido(s)"
l10n.noContactsToAdd               // "No hay contactos disponibles para añadir"
l10n.noContactsFoundWithSearch     // "No se encontraron contactos con tu búsqueda"
```

---

## 16. FLUJO COMPLETO

```
Usuario en GroupDetailScreen toca "Añadir Miembros"
  ↓
Navega a AddGroupMembersScreen
  ↓
_loadContacts() se ejecuta automáticamente
  ↓
ApiClient().fetchContacts() obtiene todos los contactos del usuario
  ↓
Filtra usuarios públicos y miembros existentes
  ↓
Muestra lista de contactos disponibles
  ↓
Usuario escribe en búsqueda (opcional)
  ↓
Lista se filtra en tiempo real
  ↓
Usuario toca contactos para seleccionar
  ↓
_selectedUserIds.add(id) / .remove(id)
  ↓
Banner de "X seleccionados" aparece
  ↓
Botón "Añadir X Miembro(s)" aparece en bottom
  ↓
Usuario toca botón
  ↓
_addSelectedMembers() se ejecuta
  ↓
Por cada ID seleccionado:
  → repo.addMemberToGroup()
  → API crea group_membership
  → Realtime emite INSERT
  ↓
Todos añadidos exitosamente
  ↓
context.pop(true)
  ↓
Regresa a GroupDetailScreen
  ↓
GroupDetailScreen recibe actualización vía Realtime
  ↓
Lista de miembros se actualiza automáticamente
  ↓
Nuevos miembros aparecen en la lista
```

---

## 17. OPTIMIZACIONES

### 17.1. Búsqueda Eficiente
```dart
onChanged: (_) => setState(() {}),
```

**Costo**: Reconstruye toda la lista en cada keystroke
**Aceptable porque**:
- Lista típica: 10-50 contactos (pequeña)
- Filtrado es O(n) simple
- Flutter optimiza diffs

**Mejora futura**: Debounce para listas muy grandes

### 17.2. Set para Selección
```dart
final Set<int> _selectedUserIds = {};

// O(1) lookup
if (_selectedUserIds.contains(contact.id)) ...
```

**Beneficio**: Verificación instantánea vs List.contains() que sería O(n)

---

## 18. TESTING

### 18.1. Keys
```dart
Key('add_group_members_screen_scaffold')
Key('add_members_search_field')
Key('add_members_clear_selection_button')
Key('add_members_confirm_button')
Key('add_member_contact_${contact.id}')
```

---

## 19. MEJORAS FUTURAS POTENCIALES

1. **Endpoint batch**: Añadir todos los miembros con una sola llamada al backend
2. **Grupos de contactos**: Seleccionar todos los contactos de una categoría
3. **Contactos sugeridos**: Basado en otros grupos o interacciones
4. **Previsualización**: Ver quiénes serán añadidos antes de confirmar
5. **Roles al añadir**: Permitir seleccionar si añadir como miembro o admin
6. **Añadir con mensaje**: Enviar mensaje de bienvenida personalizado
7. **Límite de miembros**: Mostrar advertencia si el grupo alcanza cierto tamaño
8. **Paginación**: Para usuarios con miles de contactos
9. **Sincronización de contactos**: Botón para refrescar contactos del dispositivo
10. **Filtros avanzados**: Por etiquetas, grupos existentes, etc.
