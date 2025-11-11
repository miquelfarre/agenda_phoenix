# SelectableCard - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/selectable_card.dart`
**Líneas**: 78
**Tipo**: StatelessWidget
**Propósito**: Card interactiva con checkbox personalizado para selección múltiple, mostrando icono coloreable, título, subtítulo opcional y estado de selección

## 2. CLASE Y PROPIEDADES

### SelectableCard (líneas 6-77)

**Propiedades**:
- `title` (String, required, línea 7): Título principal de la card
- `subtitle` (String?, línea 8): Subtítulo opcional
- `icon` (IconData, required, línea 9): Icono a mostrar en el avatar
- `color` (Color, required, línea 10): Color del icono/avatar
- `selected` (bool, required, línea 11): Estado de selección actual
- `onTap` (VoidCallback, required, línea 12): Callback al tocar la card
- `onChanged` (ValueChanged<bool?>?, required, línea 13): Callback al cambiar el checkbox

## 3. CONSTRUCTOR (línea 15)

```dart
const SelectableCard({
  super.key,
  required this.title,
  this.subtitle,
  required this.icon,
  required this.color,
  required this.selected,
  required this.onTap,
  required this.onChanged
})
```

**Todos required excepto**: `subtitle`

## 4. MÉTODO BUILD (líneas 17-76)

**Estructura**:
```
Container (margin adaptativo)
└── GestureDetector (onTap card)
    └── Padding (12px)
        └── Row
            ├── UserGroupAvatar (icon, color)
            ├── SizedBox (12px)
            ├── Expanded
            │   └── Column
            │       ├── Text (title)
            │       └── if (subtitle)
            │           ├── SizedBox (2px)
            │           └── Text (subtitle)
            ├── SizedBox (8px)
            └── GestureDetector (onTap checkbox)
                └── Container (checkbox custom)
                    └── if (selected) Icon(check)
```

### 4.1. Detección de plataforma (línea 19)

```dart
final isIOS = PlatformWidgets.isIOS;
```

Usado para margin adaptativo

### 4.2. Container exterior (líneas 21-23)

```dart
Container(
  margin: EdgeInsets.symmetric(
    horizontal: isIOS ? 16.0 : 8.0,
    vertical: 4.0
  ),
  decoration: AppStyles.cardDecoration,
  ...
)
```

**Margin adaptativo**:
- iOS: horizontal 16, vertical 4
- Android: horizontal 8, vertical 4

### 4.3. GestureDetector de card (líneas 24-26)

```dart
GestureDetector(
  key: key != null ? Key('${key.toString()}_card_tap') : null,
  onTap: onTap,
  ...
)
```

**Key derivada**: `<key>_card_tap` para testing
**onTap**: Toca toda la card (excepto checkbox)

### 4.4. UserGroupAvatar (línea 32)

```dart
UserGroupAvatar(icon: icon, color: color)
```

Avatar cuadrado 48x48 con icono coloreable

### 4.5. Textos (líneas 34-54)

**Title** (líneas 38-43):
```dart
Text(
  title,
  style: AppStyles.cardTitle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.bold
  ),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)
```

**Subtitle condicional** (líneas 44-52):
```dart
if (subtitle != null && subtitle!.isNotEmpty) ...[
  const SizedBox(height: 2),
  Text(
    subtitle!,
    style: AppStyles.cardSubtitle.copyWith(
      fontSize: 12,
      color: AppStyles.grey600
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
]
```

**Nota**: Usa spread operator `...[]` para insertar múltiples widgets condicionalmente

### 4.6. Checkbox personalizado (líneas 57-70)

```dart
GestureDetector(
  key: key != null ? Key('${key.toString()}_checkbox_tap') : null,
  onTap: () => onChanged?.call(!selected),
  child: Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      border: Border.all(
        color: selected ? AppStyles.primary600 : AppStyles.grey600,
        width: 2
      ),
      borderRadius: BorderRadius.circular(4),
      color: selected ? AppStyles.primary600 : AppStyles.transparent,
    ),
    child: selected
      ? PlatformWidgets.platformIcon(
          CupertinoIcons.check_mark,
          size: 16,
          color: AppStyles.white
        )
      : null,
  ),
)
```

**Características**:
- Tamaño: 24x24px
- BorderRadius: 4 (esquinas ligeramente redondeadas)
- Border width: 2px

**Estados visuales**:

**No seleccionado**:
- Borde: grey600 (gris)
- Fondo: transparent
- Icono: null (no muestra)

**Seleccionado**:
- Borde: primary600 (azul)
- Fondo: primary600 (azul sólido)
- Icono: check_mark blanco (16px)

**Interacción**:
```dart
onTap: () => onChanged?.call(!selected)
```
- Toggle el estado: true → false, false → true
- Usa `?.call()` para null-safety

**Key derivada**: `<key>_checkbox_tap` para testing

## 5. COMPONENTES EXTERNOS

### UserGroupAvatar (línea 32)
**Archivo**: `user_group_avatar.dart`
**Props**: icon, color
**Propósito**: Avatar cuadrado 48x48 con icono

### PlatformWidgets.platformIcon (línea 68)
**Props**: IconData, size, color
**Propósito**: Icono adaptativo (check mark)

## 6. CARACTERÍSTICAS TÉCNICAS

### 6.1. Doble GestureDetector

**Dos áreas tappable separadas**:

1. **Card completa** (línea 24):
   - Ejecuta `onTap`
   - Para navegación/acción principal

2. **Checkbox** (línea 57):
   - Ejecuta `onChanged?.call(!selected)`
   - Para toggle de selección

**Beneficio**: Dos acciones independientes (tap card vs toggle checkbox)

### 6.2. Spread operator para condicionales

```dart
if (subtitle != null && subtitle!.isNotEmpty) ...[
  const SizedBox(height: 2),
  Text(subtitle!),
]
```

**Ventaja sobre**:
```dart
if (subtitle != null) SizedBox(...),
if (subtitle != null) Text(...),
```

Más limpio y agrupa widgets relacionados

### 6.3. Null-aware call

```dart
onChanged?.call(!selected)
```

- `?.call()`: Solo llama si onChanged no es null
- Previene crash si callback no se proporciona

### 6.4. Keys derivadas para testing

**Dos keys**:
- `<key>_card_tap`: Para testear tap en card
- `<key>_checkbox_tap`: Para testear tap en checkbox

**Ejemplo**:
```dart
SelectableCard(
  key: Key('calendar_1'),
  ...
)

// En tests:
await tester.tap(find.byKey(Key('calendar_1_card_tap')));
await tester.tap(find.byKey(Key('calendar_1_checkbox_tap')));
```

### 6.5. MaxLines: 1

**Diferencia con ContactCard** (maxLines: 2):
- SelectableCard: maxLines 1 para título y subtítulo
- Más compacto, ocupa menos espacio vertical

**Uso**: Listas de selección múltiple con muchos ítems

## 7. CASOS DE USO

### 7.1. Selección de calendarios

```dart
SelectableCard(
  title: 'Trabajo',
  subtitle: '23 eventos',
  icon: Icons.work,
  color: Colors.blue,
  selected: selectedCalendars.contains(calendar.id),
  onTap: () => navigateToCalendar(calendar),
  onChanged: (selected) {
    setState(() {
      if (selected == true) {
        selectedCalendars.add(calendar.id);
      } else {
        selectedCalendars.remove(calendar.id);
      }
    });
  },
)
```

### 7.2. Selección de grupos

```dart
SelectableCard(
  title: 'Familia',
  subtitle: '8 miembros',
  icon: Icons.family_restroom,
  color: Colors.orange,
  selected: isSelected,
  onTap: () => showGroupDetails(),
  onChanged: toggleSelection,
)
```

### 7.3. Sin subtítulo

```dart
SelectableCard(
  title: 'Personal',
  subtitle: null, // No se mostrará
  icon: Icons.person,
  color: Colors.green,
  selected: false,
  onTap: () {},
  onChanged: (val) {},
)
```

### 7.4. Multi-select list

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return SelectableCard(
      title: item.name,
      subtitle: item.description,
      icon: item.icon,
      color: item.color,
      selected: selectedItems.contains(item.id),
      onTap: () => viewDetails(item),
      onChanged: (selected) => toggleItem(item.id, selected),
    );
  },
)
```

## 8. TESTING

### 8.1. Test tap en card

```dart
testWidgets('calls onTap when card tapped', (tester) async {
  bool tapped = false;

  await tester.pumpWidget(
    SelectableCard(
      key: Key('test_card'),
      title: 'Test',
      icon: Icons.star,
      color: Colors.blue,
      selected: false,
      onTap: () => tapped = true,
      onChanged: (val) {},
    ),
  );

  await tester.tap(
    find.byKey(Key('test_card_card_tap')),
  );

  expect(tapped, true);
});
```

### 8.2. Test toggle checkbox

```dart
testWidgets('toggles selection when checkbox tapped', (tester) async {
  bool? newValue;

  await tester.pumpWidget(
    SelectableCard(
      key: Key('test_card'),
      title: 'Test',
      icon: Icons.star,
      color: Colors.blue,
      selected: false,
      onTap: () {},
      onChanged: (val) => newValue = val,
    ),
  );

  await tester.tap(
    find.byKey(Key('test_card_checkbox_tap')),
  );

  expect(newValue, true); // De false a true
});
```

### 8.3. Test visual de checkbox

```dart
testWidgets('shows check icon when selected', (tester) async {
  await tester.pumpWidget(
    SelectableCard(
      title: 'Test',
      icon: Icons.star,
      color: Colors.blue,
      selected: true,
      onTap: () {},
      onChanged: (val) {},
    ),
  );

  expect(
    find.byIcon(CupertinoIcons.check_mark),
    findsOneWidget,
  );
});

testWidgets('hides check icon when not selected', (tester) async {
  await tester.pumpWidget(
    SelectableCard(
      title: 'Test',
      icon: Icons.star,
      color: Colors.blue,
      selected: false,
      onTap: () {},
      onChanged: (val) {},
    ),
  );

  expect(
    find.byIcon(CupertinoIcons.check_mark),
    findsNothing,
  );
});
```

## 9. COMPARACIÓN CON ContactCard

### Similitudes:
- Margin adaptativo (iOS 16, Android 8)
- GestureDetector con key derivada
- UserGroupAvatar vs UserAvatar (ambos 48px)
- Padding 12px
- Row layout con avatar + textos + trailing

### Diferencias:

| Aspecto | SelectableCard | ContactCard |
|---------|----------------|-------------|
| **Avatar** | UserGroupAvatar (icon) | UserAvatar (foto/iniciales) |
| **Trailing** | Checkbox custom | Chevron |
| **MaxLines** | 1 línea | 2 líneas |
| **Interacción** | 2 áreas (card + checkbox) | 1 área (toda la card) |
| **Propósito** | Multi-select | Navegación |
| **Subtitle** | Opcional con spread | Condicional if |
| **Callbacks** | onTap + onChanged | Solo onTap |

## 10. POSIBLES MEJORAS (NO implementadas)

### 10.1. Native checkbox option

```dart
final bool useNativeCheckbox;

// En trailing:
useNativeCheckbox
  ? Checkbox(value: selected, onChanged: onChanged)
  : CustomCheckbox(...)
```

### 10.2. Disabled state

```dart
final bool enabled;

onTap: enabled ? onTap : null,
onChanged: enabled ? onChanged : null,
```

### 10.3. Tristate checkbox

```dart
final bool? selected; // null, true, false

// Mostrar estado intermedio
```

### 10.4. Custom checkbox size

```dart
final double checkboxSize;

Container(
  width: checkboxSize,
  height: checkboxSize,
  ...
)
```

## 11. RESUMEN

**Propósito**: Card de selección múltiple con avatar de icono, textos y checkbox personalizado

**Características clave**:
- Doble interacción (card tap + checkbox toggle)
- Checkbox personalizado (no nativo)
- Margin adaptativo (iOS/Android)
- Keys derivadas para testing
- Subtitle condicional con spread operator
- MaxLines 1 para compacidad

**Uso**: Listas de selección múltiple (calendarios, grupos, categorías)

**Diferencia con ContactCard**: Selección vs navegación, icon vs foto, checkbox vs chevron

---

**Fin de la documentación de selectable_card.dart**
