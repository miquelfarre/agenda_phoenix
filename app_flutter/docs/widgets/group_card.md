# GroupCard - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/group_card.dart`
**Líneas**: 82
**Tipo**: StatelessWidget
**Propósito**: Card interactiva para mostrar grupos de contactos con estado de selección, información de miembros, y badge opcional para invitaciones parciales

## 2. CLASE Y PROPIEDADES

### GroupCard (líneas 5-81)

**Propiedades**:
- `group` (Group, required, línea 6): Grupo a mostrar
- `partiallyInvitedCount` (int?, línea 7): Cantidad de miembros parcialmente invitados (para badge)
- `onTap` (VoidCallback?, línea 8): Callback opcional al tocar la card
- `isSelected` (bool, default: false, línea 9): Estado de selección de la card

## 3. CONSTRUCTOR (línea 11)

```dart
const GroupCard({
  super.key,
  required this.group,
  this.partiallyInvitedCount,
  this.onTap,
  this.isSelected = false
})
```

**Tipo**: Constructor const
**Required**: group
**Optional**: partiallyInvitedCount, onTap, isSelected (default: false)

## 4. MÉTODO BUILD (líneas 13-80)

### build(BuildContext context) (líneas 14-80)

**Estructura del widget tree**:
```
if (isPartiallyInvited)
  Badge
  └── Card
else
  Card

Card structure:
Card (elevation variable según isSelected)
└── InkWell (onTap con ripple)
    └── Padding (12px)
        └── Row
            ├── CircleAvatar (icon group)
            ├── SizedBox (12px)
            ├── Expanded
            │   └── Column
            │       ├── Text (group.name)
            │       ├── if (description) Text (description)
            │       └── Text (memberCountText)
            └── if (isSelected) Icon (check_circle)
```

**Lógica detallada**:

1. **Obtener theme** (línea 15):
   ```dart
   final theme = Theme.of(context);
   ```
   - Accede al tema de Material Design
   - **Diferencia con AppStyles**: Usa theme nativo de Flutter en lugar de AppStyles custom

2. **Calcular isPartiallyInvited** (línea 16):
   ```dart
   final isPartiallyInvited = partiallyInvitedCount != null && partiallyInvitedCount! > 0;
   ```
   - Determina si hay invitaciones parciales
   - Requiere: count no null Y mayor que 0

3. **Construir card base** (líneas 18-62):

   **Variable local card** (línea 18):
   ```dart
   Widget card = Card(...);
   ```
   - Se construye primero, luego se envuelve en Badge si necesario

   a) **Card widget** (líneas 18-19):
      ```dart
      Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
        ...
      )
      ```

      **elevation**:
      - **Si selected**: 4 (elevación alta, más sombra)
      - **Si no selected**: 1 (elevación baja, sombra sutil)
      - **Feedback visual**: Card "levantada" cuando seleccionada

      **color**:
      - **Si selected**: primaryContainer con 30% alpha (fondo azul claro)
      - **Si no selected**: null (usa default del tema)

      **withValues(alpha: 0.3)**:
      - API moderna de Flutter para opacidad
      - Equivalente a `.withOpacity(0.3)`

   b) **InkWell** (líneas 21-23):
      ```dart
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        ...
      )
      ```

      **onTap**: Callback proporcionado (puede ser null)
      **borderRadius**: 12px
      - **Propósito**: Limita el efecto ripple a las esquinas redondeadas del Card
      - Sin borderRadius: Ripple sería rectangular

   c) **Padding** (línea 24):
      ```dart
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        ...
      )
      ```
      - 12px en todos los lados

   d) **Row principal** (líneas 26):
      ```dart
      child: Row(
        children: [...]
      )
      ```
      - **crossAxisAlignment**: No especificado (default: center)

   e) **CircleAvatar** (líneas 28-31):
      ```dart
      CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          Icons.group,
          color: theme.colorScheme.onSecondaryContainer,
          size: 28
        ),
      )
      ```

      **Dimensiones**:
      - radius: 24 → diameter 48px
      - size del icon: 28px

      **Colores**:
      - backgroundColor: theme.colorScheme.secondaryContainer
      - icon color: theme.colorScheme.onSecondaryContainer
      - **Material 3 colors**: Usa color scheme del tema

      **Icon**: Icons.group (icono de grupo de personas)

   f) **Expanded con textos** (líneas 35-54):

      **Column** (líneas 36-37):
      ```dart
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [...]
      )
      ```

      **Text del nombre** (líneas 39-43):
      ```dart
      Text(
        group.name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      )
      ```

      **style**:
      - Base: theme.textTheme.titleMedium
      - **Uso de `?.`**: Null-aware porque textTheme puede ser null
      - fontWeight: FontWeight.w600 (semi-bold)

      **maxLines**: 1

      **Text de descripción (condicional)** (líneas 45-50):
      ```dart
      if (group.description.isNotEmpty)
        Text(
          group.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )
      ```

      **Condicional**: Solo si description no está vacío
      **color**: onSurfaceVariant (color secundario del tema)

      **Text de member count** (línea 52):
      ```dart
      Text(
        group.memberCountText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant
        )
      )
      ```

      **group.memberCountText**: Propiedad computed del modelo Group
      - Probablemente retorna: "X miembros" o "X members"

   g) **Check icon (condicional)** (línea 57):
      ```dart
      if (isSelected)
        Icon(
          Icons.check_circle,
          color: theme.colorScheme.primary,
          size: 28
        )
      ```

      **Condicional**: Solo si isSelected == true
      **Icon**: check_circle (círculo con check)
      **color**: primary (color primario del tema)
      **size**: 28px (mismo que icon del avatar)

4. **Wrapper Badge (condicional)** (líneas 64-77):

   ```dart
   if (isPartiallyInvited) {
     final totalMembers = group.members.length;
     return Badge(
       label: Text(
         context.l10n.partiallyInvited(partiallyInvitedCount!, totalMembers),
         style: theme.textTheme.labelSmall?.copyWith(
           color: theme.colorScheme.onSecondaryContainer,
           fontWeight: FontWeight.w600
         ),
       ),
       backgroundColor: theme.colorScheme.secondaryContainer,
       textColor: theme.colorScheme.onSecondaryContainer,
       offset: const Offset(12, -12),
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       child: card,
     );
   }
   ```

   **Condicional**: Solo si isPartiallyInvited == true

   **Cálculo de totalMembers** (línea 65):
   ```dart
   final totalMembers = group.members.length;
   ```

   **Badge properties**:

   **label** (líneas 67-70):
   - **Text**: `context.l10n.partiallyInvited(partiallyInvitedCount!, totalMembers)`
   - **Localización con parámetros**: Función que recibe 2 argumentos
   - **Ejemplo**: "3 de 10 invitados" o "3 of 10 invited"
   - **style**: labelSmall con color onSecondaryContainer y bold

   **backgroundColor** (línea 71):
   - theme.colorScheme.secondaryContainer
   - Match con el avatar

   **textColor** (línea 72):
   - theme.colorScheme.onSecondaryContainer

   **offset** (línea 73):
   - Offset(12, -12)
   - x: 12 (derecha)
   - y: -12 (arriba)
   - **Posición**: Esquina superior derecha del card

   **padding** (línea 74):
   - horizontal: 8, vertical: 4
   - Padding interno del badge

   **child** (línea 75):
   - card (la card construida previamente)

5. **Retorno final** (línea 79):
   ```dart
   return card;
   ```
   - Si no hay badge: retorna card directamente
   - Si hay badge: el return del bloque if (línea 76)

## 5. MODELOS UTILIZADOS

### Group (línea 2)
**Propiedades usadas**:
- `name`: String - Nombre del grupo
- `description`: String - Descripción del grupo
- `members`: List (length usado para totalMembers)
- `memberCountText`: String (computed property) - Texto de cantidad de miembros

## 6. LOCALIZACIÓN

### Strings localizados:

**context.l10n.partiallyInvited(int partial, int total)** (línea 68):
- Función de localización con parámetros
- **Posible implementación en ARB**:
  ```json
  {
    "partiallyInvited": "{partial} de {total} invitados",
    "@partiallyInvited": {
      "placeholders": {
        "partial": {"type": "int"},
        "total": {"type": "int"}
      }
    }
  }
  ```

**Ejemplo de salida**:
- ES: "3 de 10 invitados"
- EN: "3 of 10 invited"
- CA: "3 de 10 convitats"

## 7. CARACTERÍSTICAS TÉCNICAS

### 7.1. Material Design 3 (Material You)

**Uso completo del theme**:
- `theme.colorScheme.*`: Sistema de colores M3
- `theme.textTheme.*`: Estilos de texto M3
- **Beneficio**: Adaptación automática a temas dark/light

**Color scheme usado**:
- `primaryContainer`: Fondo de card seleccionada
- `onPrimaryContainer`: (no usado aquí)
- `secondaryContainer`: Fondo de avatar y badge
- `onSecondaryContainer`: Color de texto en avatar y badge
- `primary`: Color del check icon
- `onSurfaceVariant`: Color de textos secundarios

### 7.2. InkWell con borderRadius

**Pattern**:
```dart
Card(
  child: InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: content,
  ),
)
```

**Propósito**: Ripple effect limitado a las esquinas del Card

**Sin borderRadius**:
- Ripple sería rectangular
- Overflow visual en las esquinas

**Con borderRadius**:
- Ripple respeta las esquinas redondeadas
- UX consistente

### 7.3. Variable local para widget

**Pattern**:
```dart
Widget card = Card(...);

if (condition) {
  return Badge(child: card);
}

return card;
```

**Beneficio**: Evita duplicación de código

**Alternativa menos eficiente**:
```dart
if (condition) {
  return Badge(child: Card(...));
}
return Card(...); // Duplicación
```

### 7.4. Null-aware copyWith

**Pattern**:
```dart
theme.textTheme.titleMedium?.copyWith(...)
```

**Motivo**: textTheme puede ser null en algunos contextos

**Sin `?`**: Crash si textTheme.titleMedium es null

**Con `?`**: Si null, retorna null (Text usa default)

### 7.5. Badge offset

**Offset(12, -12)**:
- Positivo en x: Hacia la derecha
- Negativo en y: Hacia arriba
- **Resultado**: Esquina superior derecha

**Visualización**:
```
┌────────────────────────┐
│ [Badge]                │
│                        │
│  [Avatar] Grupo X  [✓] │
│           5 miembros   │
└────────────────────────┘
```

### 7.6. Elevation según estado

**isSelected = false**: elevation 1
- Sombra sutil
- Card "plana"

**isSelected = true**: elevation 4
- Sombra prominente
- Card "elevada"
- **Feedback háptico visual**: Se siente más "presionada"

### 7.7. withValues vs withOpacity

**API moderna**:
```dart
color.withValues(alpha: 0.3)
```

**API antigua**:
```dart
color.withOpacity(0.3)
```

**Diferencia**: withValues es más flexible (puede cambiar otros canales)

### 7.8. CircleAvatar vs UserGroupAvatar

**CircleAvatar** (usado aquí):
- Widget nativo de Material
- Circular
- Tamaño por radius
- Icon centrado automáticamente

**UserGroupAvatar** (usado en SelectableCard):
- Widget custom
- Cuadrado con borderRadius
- Tamaño por width/height
- Fondo y borde con opacidades custom

**Elección**: CircleAvatar es más simple para este caso

## 8. CASOS DE USO

### 8.1. Grupo normal no seleccionado

```dart
GroupCard(
  group: Group(
    name: 'Familia',
    description: 'Grupo familiar',
    members: [user1, user2, user3],
  ),
  onTap: () => selectGroup(),
)
```

**Apariencia**:
- Elevation 1
- Fondo default
- Sin check icon
- Sin badge

### 8.2. Grupo seleccionado

```dart
GroupCard(
  group: group,
  isSelected: true,
  onTap: () => deselectGroup(),
)
```

**Apariencia**:
- Elevation 4 (más elevado)
- Fondo azul claro (primaryContainer con 30% alpha)
- Check icon visible

### 8.3. Grupo con invitaciones parciales

```dart
GroupCard(
  group: Group(
    name: 'Trabajo',
    members: [user1, user2, user3, user4, user5],
  ),
  partiallyInvitedCount: 3,
  onTap: () {},
)
```

**Apariencia**:
- Badge en esquina superior derecha
- Badge text: "3 de 5 invitados"

### 8.4. Grupo sin descripción

```dart
GroupCard(
  group: Group(
    name: 'Amigos',
    description: '', // Vacío
    members: users,
  ),
  onTap: () {},
)
```

**Apariencia**:
- Solo muestra nombre y member count
- Sin línea de descripción

### 8.5. Grupo sin onTap (no interactivo)

```dart
GroupCard(
  group: group,
  onTap: null, // No interactivo
)
```

**Comportamiento**:
- InkWell con onTap: null
- No muestra ripple effect
- No responde a taps

### 8.6. Selección múltiple en lista

```dart
ListView.builder(
  itemCount: groups.length,
  itemBuilder: (context, index) {
    final group = groups[index];
    return GroupCard(
      group: group,
      isSelected: selectedGroups.contains(group.id),
      onTap: () => toggleSelection(group.id),
    );
  },
)
```

### 8.7. Invitar grupo a evento

```dart
// Mostrar grupos con info de invitaciones parciales
GroupCard(
  group: group,
  partiallyInvitedCount: alreadyInvitedFromGroup,
  isSelected: willInviteRestOfGroup,
  onTap: () => toggleGroupInvitation(),
)
```

**Uso**: Pantalla de invitar a evento, muestra cuántos del grupo ya están invitados

## 9. TESTING

### 9.1. Test de estado seleccionado

```dart
testWidgets('shows elevated card when selected', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GroupCard(
        group: testGroup,
        isSelected: true,
        onTap: () {},
      ),
    ),
  );

  final card = tester.widget<Card>(find.byType(Card));
  expect(card.elevation, 4);
});

testWidgets('shows check icon when selected', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GroupCard(
        group: testGroup,
        isSelected: true,
        onTap: () {},
      ),
    ),
  );

  expect(find.byIcon(Icons.check_circle), findsOneWidget);
});

testWidgets('hides check icon when not selected', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GroupCard(
        group: testGroup,
        isSelected: false,
        onTap: () {},
      ),
    ),
  );

  expect(find.byIcon(Icons.check_circle), findsNothing);
});
```

### 9.2. Test de badge

```dart
testWidgets('shows badge when partially invited', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GroupCard(
        group: Group(members: [u1, u2, u3, u4, u5]),
        partiallyInvitedCount: 3,
        onTap: () {},
      ),
    ),
  );

  expect(find.byType(Badge), findsOneWidget);
  expect(find.textContaining('3'), findsOneWidget);
  expect(find.textContaining('5'), findsOneWidget);
});

testWidgets('hides badge when not partially invited', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GroupCard(
        group: testGroup,
        partiallyInvitedCount: 0,
        onTap: () {},
      ),
    ),
  );

  expect(find.byType(Badge), findsNothing);
});

testWidgets('hides badge when count is null', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GroupCard(
        group: testGroup,
        partiallyInvitedCount: null,
        onTap: () {},
      ),
    ),
  );

  expect(find.byType(Badge), findsNothing);
});
```

### 9.3. Test de descripción condicional

```dart
testWidgets('shows description when not empty', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GroupCard(
        group: Group(
          name: 'Test',
          description: 'Test description',
        ),
        onTap: () {},
      ),
    ),
  );

  expect(find.text('Test description'), findsOneWidget);
});

testWidgets('hides description when empty', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GroupCard(
        group: Group(
          name: 'Test',
          description: '',
        ),
        onTap: () {},
      ),
    ),
  );

  // Solo debe haber 2 Text widgets (name + memberCount), no 3
  expect(find.byType(Text), findsNWidgets(2));
});
```

### 9.4. Test de interacción

```dart
testWidgets('calls onTap when tapped', (tester) async {
  bool tapped = false;

  await tester.pumpWidget(
    MaterialApp(
      home: GroupCard(
        group: testGroup,
        onTap: () => tapped = true,
      ),
    ),
  );

  await tester.tap(find.byType(InkWell));
  expect(tapped, true);
});
```

## 10. COMPARACIÓN CON OTROS CARDS

### vs ContactCard:
- **GroupCard**: CircleAvatar con icon, member count, badge opcional
- **ContactCard**: UserAvatar con foto, subtitle, chevron

### vs SelectableCard:
- **GroupCard**: Estado selected visual (elevation + color), check icon
- **SelectableCard**: Checkbox custom, icon coloreable

### vs SubscriptionCard:
- **GroupCard**: Material theme colors, Badge widget
- **SubscriptionCard**: AppStyles colors, delete button

**Diferencia clave**: GroupCard es el único que usa Material 3 theme completamente

## 11. POSIBLES MEJORAS (NO implementadas)

### 11.1. Avatares de miembros

```dart
// Mostrar mini avatares de primeros 3 miembros
Row(
  children: group.members.take(3).map((member) =>
    CircleAvatar(
      radius: 12,
      backgroundImage: NetworkImage(member.profilePicture),
    )
  ).toList(),
)
```

### 11.2. Swipe actions

```dart
Dismissible(
  key: Key('group_${group.id}'),
  confirmDismiss: (direction) async {
    if (direction == DismissDirection.endToStart) {
      return await showDeleteConfirmation();
    }
    return false;
  },
  child: GroupCard(...),
)
```

### 11.3. Expansion para ver miembros

```dart
ExpansionTile(
  title: GroupCard(...),
  children: group.members.map((member) =>
    ListTile(title: Text(member.name))
  ).toList(),
)
```

### 11.4. Badge customizable

```dart
final Widget? customBadge;

if (customBadge != null) {
  return Badge.count(
    count: customCount,
    child: card,
  );
}
```

## 12. RESUMEN

**Propósito**: Card para mostrar grupos con estado de selección y badge de invitaciones parciales

**Características clave**:
- Material 3 theme completo (colorScheme + textTheme)
- Estado selected: elevation 4 + color + check icon
- Badge condicional para invitaciones parciales
- InkWell con ripple effect limitado a borderRadius
- CircleAvatar con icon de grupo
- Descripción condicional

**Layout**: Avatar circular + Column(nombre + descripción + member count) + check icon (si selected)

**Uso**: Selección de grupos para invitar a eventos, gestión de grupos

**Diferenciador**: Único card que usa Material 3 theme en lugar de AppStyles custom

---

**Fin de la documentación de group_card.dart**
