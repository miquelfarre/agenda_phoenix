# HorizontalSelectorWidget - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/horizontal_selector_widget.dart`
**Líneas**: 165
**Tipo**: StatefulWidget con State privado, genérico \<T\>
**Propósito**: Widget genérico reutilizable de selector horizontal con scroll, auto-scroll a seleccionado, label opcional, estados enabled/disabled, highlight personalizable y soporte para subtítulos

## 2. CLASES CONTENIDAS

1. **HorizontalSelectorWidget\<T\>** (líneas 5-45): StatefulWidget genérico público
2. **_HorizontalSelectorWidgetState\<T\>** (líneas 47-164): State genérico privado

---

## 3. CLASE: HorizontalSelectorWidget\<T\>

### 3.1. Información General

**Líneas**: 5-45
**Tipo**: StatefulWidget genérico
**Genérico**: \<T\> - Tipo del valor de las opciones (Country, String, int, etc.)
**Propósito**: Widget configurable para selección horizontal con scroll

### 3.2. Propiedades (líneas 6-26)

- `options` (List<SelectorOption\<T\>>, required, línea 6): Lista de opciones a mostrar
- `onSelected` (Function(T value), required, línea 8): Callback al seleccionar con el valor de tipo T
- `label` (String?, línea 10): Label opcional encima del selector
- `icon` (IconData?, línea 12): Icono opcional junto al label
- `itemHeight` (double, default: 55.0, línea 14): Altura de cada item
- `itemPadding` (EdgeInsets, default: symmetric(h:14, v:10), línea 16): Padding interno de cada item
- `itemMargin` (EdgeInsets, default: only(right:8), línea 18): Margen entre items
- `listPadding` (EdgeInsets, default: only(left:16, right:16), línea 20): Padding del ListView
- `scrollPhysics` (ScrollPhysics, default: ClampingScrollPhysics(), línea 22): Física del scroll
- `emptyMessage` (String?, línea 24): Mensaje cuando no hay opciones
- `autoScrollToSelected` (bool, default: false, línea 26): Si auto-scroll al item seleccionado al iniciar

### 3.3. Constructor (líneas 28-41)

```dart
const HorizontalSelectorWidget({
  super.key,
  required this.options,
  required this.onSelected,
  this.label,
  this.icon,
  this.itemHeight = 55.0,
  this.itemPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  this.itemMargin = const EdgeInsets.only(right: 8),
  this.listPadding = const EdgeInsets.only(left: 16, right: 16),
  this.scrollPhysics = const ClampingScrollPhysics(),
  this.emptyMessage,
  this.autoScrollToSelected = false,
})
```

**Tipo**: Constructor const
**Required**: options, onSelected
**Optional**: Todos los demás con defaults

**Defaults destacables**:
- itemHeight: 55.0
- itemPadding: 14px horizontal, 10px vertical
- itemMargin: 8px derecha (spacing entre items)
- listPadding: 16px izquierda y derecha (márgenes de la lista)
- scrollPhysics: ClampingScrollPhysics() (scroll Android-style, sin bounce)
- autoScrollToSelected: false

### 3.4. Método createState (líneas 43-44)

```dart
@override
State<HorizontalSelectorWidget<T>> createState() =>
  _HorizontalSelectorWidgetState<T>();
```

**Preserva tipo genérico**: \<T\> se pasa al State

---

## 4. CLASE: _HorizontalSelectorWidgetState\<T\>

### 4.1. Información General

**Líneas**: 47-164
**Tipo**: State<HorizontalSelectorWidget\<T\>>
**Genérico**: \<T\>
**Visibilidad**: Privada

### 4.2. Variables de estado (línea 48)

```dart
late ScrollController _scrollController;
```

**_scrollController**: ScrollController para el ListView
- late: Inicializado en initState
- Usado para auto-scroll programático

### 4.3. Método initState (líneas 50-60)

```dart
@override
void initState() {
  super.initState();
  _scrollController = ScrollController();

  if (widget.autoScrollToSelected && widget.options.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }
}
```

**Lógica**:

1. **Crear ScrollController** (línea 53):
   - Inicializa _scrollController

2. **Auto-scroll condicional** (línea 55):
   - **Condición**: autoScrollToSelected Y options no vacío
   - **Timing**: Post-frame callback (después del primer frame)
   - **Motivo**: Necesita que el ListView esté construido antes de scroll

**addPostFrameCallback**:
- Ejecuta después del frame actual
- Garantiza que el layout está completo

### 4.4. Método dispose (líneas 62-66)

```dart
@override
void dispose() {
  _scrollController.dispose();
  super.dispose();
}
```

**Propósito**: Liberar recursos del ScrollController

**Orden**:
1. Dispose del controller primero
2. Llama super.dispose()

### 4.5. Método _scrollToSelected (líneas 68-76)

**Tipo de retorno**: void
**Visibilidad**: Privado

**Propósito**: Scroll animado al item seleccionado

```dart
void _scrollToSelected() {
  final selectedIndex = widget.options.indexWhere((option) => option.isSelected);
  if (selectedIndex != -1 && _scrollController.hasClients) {
    const estimatedItemWidth = 100.0;
    final scrollOffset = selectedIndex * estimatedItemWidth;

    _scrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut
    );
  }
}
```

**Lógica detallada**:

1. **Encontrar índice seleccionado** (línea 69):
   ```dart
   final selectedIndex = widget.options.indexWhere((option) => option.isSelected);
   ```
   - Busca el primer item con isSelected == true
   - Retorna -1 si no encuentra

2. **Verificaciones** (línea 70):
   ```dart
   if (selectedIndex != -1 && _scrollController.hasClients)
   ```
   - **selectedIndex != -1**: Hay item seleccionado
   - **_scrollController.hasClients**: ListView está attachado
   - **hasClients**: Previene error si ScrollController no está conectado

3. **Calcular offset** (líneas 71-72):
   ```dart
   const estimatedItemWidth = 100.0;
   final scrollOffset = selectedIndex * estimatedItemWidth;
   ```

   **Estimación**:
   - estimatedItemWidth: 100px (aproximado)
   - scrollOffset: índice × 100
   - **Limitación**: Asume items de ancho fijo, puede no ser preciso

   **Por qué estimación**:
   - Items tienen ancho variable (depende del displayText)
   - Calcular ancho real requeriría GlobalKey o RenderBox
   - Estimación es suficiente para scroll aproximado

4. **Animar scroll** (líneas 74):
   ```dart
   _scrollController.animateTo(
     scrollOffset,
     duration: const Duration(milliseconds: 300),
     curve: Curves.easeInOut
   );
   ```

   **Parámetros**:
   - **offset**: scrollOffset calculado
   - **duration**: 300ms (animación suave)
   - **curve**: easeInOut (aceleración suave al inicio y final)

**Mejora potencial**: Calcular ancho real de items para scroll preciso

### 4.6. Método _buildLabel (líneas 78-90)

**Tipo de retorno**: Widget
**Visibilidad**: Privado

**Propósito**: Construye label opcional con icono

```dart
Widget _buildLabel() {
  if (widget.label == null) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 20),
          const SizedBox(width: 8)
        ],
        Text(
          widget.label!,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
        ),
      ],
    ),
  );
}
```

**Lógica**:

1. **Verificar si hay label** (línea 79):
   - Si label es null: retorna SizedBox.shrink() (widget invisible de 0x0)

2. **Padding** (línea 81):
   - 16px horizontal
   - Alinea con listPadding default

3. **Row con icon y texto** (líneas 83-87):

   **Icon condicional** (línea 85):
   ```dart
   if (widget.icon != null) ...[
     Icon(widget.icon, size: 20),
     const SizedBox(width: 8)
   ]
   ```
   - Solo si hay icon
   - Spread operator para insertar Icon + SizedBox
   - size: 20px
   - Spacing: 8px entre icon y texto

   **Text del label** (línea 86):
   - fontSize: 16
   - fontWeight: w500 (medium)
   - Force unwrap: seguro porque ya verificamos null

### 4.7. Método _buildEmptyState (líneas 92-100)

**Tipo de retorno**: Widget
**Visibilidad**: Privado

**Propósito**: Muestra mensaje cuando no hay opciones

```dart
Widget _buildEmptyState() {
  return Container(
    height: widget.itemHeight,
    padding: const EdgeInsets.all(16),
    child: Center(
      child: Text(
        widget.emptyMessage ?? context.l10n.noItemsAvailable,
        style: const TextStyle(color: Colors.grey)
      ),
    ),
  );
}
```

**Lógica**:

**Container** (líneas 93-95):
- **height**: Mismo que itemHeight (consistencia visual)
- **padding**: 16px todo alrededor

**Text centrado** (líneas 96-97):
- **message**: emptyMessage custom o l10n.noItemsAvailable
- **style**: Gris (color secundario)

**Uso**: Se muestra cuando options.isEmpty

### 4.8. Método _buildHorizontalList (líneas 102-158)

**Tipo de retorno**: Widget
**Visibilidad**: Privado

**Propósito**: Construye ListView horizontal con items

```dart
Widget _buildHorizontalList() {
  final hasSubtitles = widget.options.any((opt) => opt.subtitle != null);
  final effectiveHeight = hasSubtitles ? widget.itemHeight + 8 : widget.itemHeight;

  return SizedBox(
    height: effectiveHeight,
    child: ListView.builder(
      physics: widget.scrollPhysics,
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: widget.options.length,
      padding: widget.listPadding,
      itemBuilder: (context, index) {
        final option = widget.options[index];
        final isSelected = option.isSelected;

        return GestureDetector(
          onTap: option.isEnabled ? () => widget.onSelected(option.value) : null,
          child: Opacity(
            opacity: option.isEnabled ? 1.0 : 0.5,
            child: Container(
              margin: widget.itemMargin,
              padding: widget.itemPadding,
              decoration: BoxDecoration(
                color: isSelected
                  ? (option.highlightColor ?? Theme.of(context).primaryColor).withValues(alpha: 0.1)
                  : null,
                border: Border.all(
                  color: isSelected
                    ? (option.highlightColor ?? Theme.of(context).primaryColor)
                    : Colors.grey.shade300,
                  width: isSelected ? 2 : 1
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.displayText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                        ? (option.highlightColor ?? Theme.of(context).primaryColor)
                        : null
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (option.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                          ? (option.highlightColor ?? Theme.of(context).primaryColor)
                          : Colors.grey
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
```

**Lógica detallada**:

1. **Detectar si hay subtítulos** (línea 103):
   ```dart
   final hasSubtitles = widget.options.any((opt) => opt.subtitle != null);
   ```
   - Verifica si al menos una opción tiene subtitle
   - Usado para ajustar altura

2. **Calcular altura efectiva** (línea 104):
   ```dart
   final effectiveHeight = hasSubtitles ? widget.itemHeight + 8 : widget.itemHeight;
   ```
   - **Sin subtítulos**: itemHeight normal
   - **Con subtítulos**: itemHeight + 8px extra
   - **Motivo**: Espacio adicional para segunda línea

3. **SizedBox container** (línea 106):
   - Limita altura del ListView

4. **ListView.builder** (líneas 108-156):

   **Propiedades** (líneas 109-114):
   - **physics**: Usa scrollPhysics configurado
   - **controller**: _scrollController para control programático
   - **scrollDirection**: Axis.horizontal (scroll horizontal)
   - **itemCount**: Cantidad de opciones
   - **padding**: listPadding configurado

5. **itemBuilder** (líneas 114-155):

   **Variables locales** (líneas 115-116):
   ```dart
   final option = widget.options[index];
   final isSelected = option.isSelected;
   ```

   a) **GestureDetector** (líneas 118-119):
      ```dart
      GestureDetector(
        onTap: option.isEnabled ? () => widget.onSelected(option.value) : null,
        ...
      )
      ```

      **onTap condicional**:
      - Si enabled: llama onSelected con option.value (tipo T)
      - Si disabled: null (no responde a taps)

   b) **Opacity** (líneas 120-121):
      ```dart
      Opacity(
        opacity: option.isEnabled ? 1.0 : 0.5,
        ...
      )
      ```

      **Feedback visual de disabled**:
      - Enabled: 100% opacidad (normal)
      - Disabled: 50% opacidad (apagado)

   c) **Container del item** (líneas 122-129):

      **margin** (línea 123): itemMargin configurado

      **padding** (línea 124): itemPadding configurado

      **decoration** (líneas 125-129):

      **color** (línea 126):
      ```dart
      color: isSelected
        ? (option.highlightColor ?? Theme.of(context).primaryColor).withValues(alpha: 0.1)
        : null
      ```
      - **Si selected**: highlightColor con 10% alpha (fondo sutil)
      - **highlightColor** puede venir del option o default a primaryColor del theme
      - **Si no selected**: sin color (transparente)

      **border** (líneas 127):
      ```dart
      border: Border.all(
        color: isSelected
          ? (option.highlightColor ?? Theme.of(context).primaryColor)
          : Colors.grey.shade300,
        width: isSelected ? 2 : 1
      )
      ```
      - **Si selected**:
        - Color: highlightColor o primaryColor (sólido)
        - Width: 2px (prominente)
      - **Si no selected**:
        - Color: grey.shade300 (gris claro)
        - Width: 1px (sutil)

      **borderRadius** (línea 128):
      - 8px (esquinas redondeadas)

   d) **Column del contenido** (líneas 130-150):

      **Propiedades** (líneas 131-133):
      - mainAxisSize.min: Ocupa mínimo necesario
      - mainAxisAlignment.center: Centra verticalmente
      - crossAxisAlignment.start: Alinea textos a izquierda

      **Text del displayText** (líneas 135-143):
      ```dart
      Text(
        option.displayText,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
            ? (option.highlightColor ?? Theme.of(context).primaryColor)
            : null
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      )
      ```

      **style**:
      - fontSize: 15
      - **fontWeight**:
        - Selected: bold
        - No selected: normal
      - **color**:
        - Selected: highlightColor o primaryColor
        - No selected: null (default del tema)

      **overflow**: ellipsis
      **maxLines**: 1

      **Text del subtitle (condicional)** (líneas 141-149):
      ```dart
      if (option.subtitle != null) ...[
        const SizedBox(height: 2),
        Text(
          option.subtitle!,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
              ? (option.highlightColor ?? Theme.of(context).primaryColor)
              : Colors.grey
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ]
      ```

      **Spacing**: 2px entre displayText y subtitle

      **style**:
      - fontSize: 12 (más pequeño)
      - **color**:
        - Selected: highlightColor o primaryColor
        - No selected: Colors.grey

### 4.9. Método build (líneas 160-163)

```dart
@override
Widget build(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildLabel(),
      if (widget.label != null) const SizedBox(height: 6),
      widget.options.isEmpty ? _buildEmptyState() : _buildHorizontalList()
    ]
  );
}
```

**Estructura**:
```
Column (min, start)
├── _buildLabel() (si hay label)
├── SizedBox(6) (si hay label)
└── _buildEmptyState() o _buildHorizontalList() (según isEmpty)
```

**Lógica**:

1. **Column** (líneas 161-162):
   - mainAxisSize.min: Ocupa mínimo
   - crossAxisAlignment.start: Alinea a izquierda

2. **Label** (línea 163):
   - Siempre llama _buildLabel() (retorna shrink si no hay)

3. **Spacing** (línea 163):
   - 6px solo si hay label

4. **Contenido** (línea 163):
   - **Si options.isEmpty**: _buildEmptyState()
   - **Si options tiene items**: _buildHorizontalList()

**Nota**: Todo en una línea (162), poco legible pero funcional

## 5. MODELOS UTILIZADOS

### SelectorOption\<T\> (línea 2)
**Archivo**: `../models/selector_option.dart`
**Genérico**: \<T\>
**Propiedades usadas**:
- `value`: T - Valor de la opción
- `displayText`: String - Texto principal
- `subtitle`: String? - Texto secundario opcional
- `isSelected`: bool - Si está seleccionada
- `isEnabled`: bool - Si está habilitada
- `highlightColor`: Color? - Color de resaltado personalizado

## 6. CARACTERÍSTICAS TÉCNICAS

### 6.1. Widget genérico \<T\>

**Declaración**:
```dart
class HorizontalSelectorWidget<T> extends StatefulWidget
class _HorizontalSelectorWidgetState<T> extends State<HorizontalSelectorWidget<T>>
```

**Uso**:
```dart
HorizontalSelectorWidget<Country>(...)
HorizontalSelectorWidget<String>(...)
HorizontalSelectorWidget<int>(...)
```

**Beneficio**: Reutilizable con cualquier tipo, type-safe

### 6.2. Callback tipado

```dart
final Function(T value) onSelected;
```

**Signature**: void Function(T)
**Type-safe**: El valor retornado es del tipo T configurado

### 6.3. Auto-scroll con estimación

**Limitación**: Usa ancho estimado (100px) en lugar de real

**Por qué**:
- Items tienen ancho variable
- Calcular ancho real requiere:
  ```dart
  final RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
  final width = box?.size.width;
  ```

**Trade-off**: Scroll aproximado vs complejidad adicional

### 6.4. hasClients check

```dart
if (_scrollController.hasClients) { ... }
```

**Propósito**: Verificar que ScrollController está conectado a un Scrollable

**Sin check**: Error "ScrollController not attached to any scroll views"

### 6.5. withValues para alpha

```dart
color.withValues(alpha: 0.1)
```

**API moderna de Flutter**: Reemplaza .withOpacity()

### 6.6. Highlight color con fallback

```dart
option.highlightColor ?? Theme.of(context).primaryColor
```

**Cascading fallback**:
1. Usa highlightColor del option (si existe)
2. Fallback a primaryColor del theme

**Beneficio**: Personalizable per-option o usa default del tema

### 6.7. Padding y margin configurables

**Todas las dimensiones son configurables**:
- itemHeight
- itemPadding
- itemMargin
- listPadding

**Beneficio**: Reutilizable en diferentes contextos con distintas necesidades de spacing

### 6.8. Physics configurable

**Default**: ClampingScrollPhysics()
- Comportamiento Android (sin bounce)

**Alternativas**:
- BouncingScrollPhysics() (comportamiento iOS)
- NeverScrollableScrollPhysics() (sin scroll)

### 6.9. Opacity para disabled

**Pattern**: Opacity(opacity: enabled ? 1.0 : 0.5)

**Beneficio**: Feedback visual consistente sin cambiar colores manualmente

### 6.10. ListView.builder vs ListView

**Por qué builder**:
- Lazy loading (solo construye items visibles)
- Eficiente con listas largas
- Mejor performance

**Alternativa menos eficiente**:
```dart
ListView(
  children: options.map((opt) => buildItem(opt)).toList(),
)
```

### 6.11. addPostFrameCallback para auto-scroll

**Timing crítico**:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  _scrollToSelected();
});
```

**Por qué necesario**:
- ListView necesita estar construido antes de scroll
- Sin post-frame: hasClients es false

### 6.12. Dynamic height basada en subtítulos

```dart
final hasSubtitles = widget.options.any((opt) => opt.subtitle != null);
final effectiveHeight = hasSubtitles ? widget.itemHeight + 8 : widget.itemHeight;
```

**Adaptativo**: Ajusta altura automáticamente si hay subtítulos

## 7. CASOS DE USO

### 7.1. Selector de países (usado en TimezoneHorizontalSelector)

```dart
HorizontalSelectorWidget<Country>(
  options: countries.map((c) => SelectorOption(
    value: c,
    displayText: '${c.flag} ${c.name}',
    isSelected: c == selected,
    isEnabled: true,
  )).toList(),
  onSelected: (country) => onCountryChanged(country),
  label: 'País',
  icon: Icons.flag,
)
```

### 7.2. Selector de timezones con subtítulos

```dart
HorizontalSelectorWidget<String>(
  options: timezones.map((tz) => SelectorOption(
    value: tz,
    displayText: cityName(tz),
    subtitle: gmtOffset(tz), // "GMT+1"
    isSelected: tz == selected,
    isEnabled: true,
  )).toList(),
  onSelected: (timezone) => onTimezoneChanged(timezone),
  label: 'Zona horaria',
  icon: Icons.access_time,
  autoScrollToSelected: true,
)
```

### 7.3. Selector de colores

```dart
HorizontalSelectorWidget<Color>(
  options: colors.map((color) => SelectorOption(
    value: color,
    displayText: colorName(color),
    highlightColor: color, // Color personalizado por opción
    isSelected: color == selectedColor,
    isEnabled: true,
  )).toList(),
  onSelected: (color) => setColor(color),
  itemHeight: 60,
)
```

### 7.4. Selector con opciones deshabilitadas

```dart
HorizontalSelectorWidget<int>(
  options: [1, 2, 3, 4, 5].map((num) => SelectorOption(
    value: num,
    displayText: '$num',
    isSelected: num == selected,
    isEnabled: num <= maxAvailable, // Deshabilita números no disponibles
  )).toList(),
  onSelected: (num) => selectNumber(num),
)
```

### 7.5. Selector con physics iOS

```dart
HorizontalSelectorWidget<String>(
  options: options,
  onSelected: onSelect,
  scrollPhysics: BouncingScrollPhysics(), // Bounce iOS
)
```

### 7.6. Selector sin label

```dart
HorizontalSelectorWidget<String>(
  options: options,
  onSelected: onSelect,
  // Sin label ni icon
)
```

### 7.7. Selector con empty message custom

```dart
HorizontalSelectorWidget<String>(
  options: [], // Vacío
  onSelected: (_) {},
  emptyMessage: 'No hay opciones disponibles en este momento',
)
```

## 8. TESTING

### 8.1. Test de selección

```dart
testWidgets('calls onSelected with correct value', (tester) async {
  String? selected;

  await tester.pumpWidget(
    MaterialApp(
      home: HorizontalSelectorWidget<String>(
        options: [
          SelectorOption(value: 'A', displayText: 'Option A', isSelected: false, isEnabled: true),
          SelectorOption(value: 'B', displayText: 'Option B', isSelected: false, isEnabled: true),
        ],
        onSelected: (value) => selected = value,
      ),
    ),
  );

  await tester.tap(find.text('Option B'));
  expect(selected, 'B');
});
```

### 8.2. Test de disabled option

```dart
testWidgets('does not call onSelected when disabled', (tester) async {
  bool called = false;

  await tester.pumpWidget(
    MaterialApp(
      home: HorizontalSelectorWidget<String>(
        options: [
          SelectorOption(value: 'A', displayText: 'Disabled', isSelected: false, isEnabled: false),
        ],
        onSelected: (_) => called = true,
      ),
    ),
  );

  await tester.tap(find.text('Disabled'));
  expect(called, false);
});
```

### 8.3. Test de empty state

```dart
testWidgets('shows empty message when no options', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HorizontalSelectorWidget<String>(
        options: [],
        onSelected: (_) {},
        emptyMessage: 'No items',
      ),
    ),
  );

  expect(find.text('No items'), findsOneWidget);
});
```

### 8.4. Test de auto-scroll

```dart
testWidgets('auto scrolls to selected item', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HorizontalSelectorWidget<int>(
        options: List.generate(10, (i) => SelectorOption(
          value: i,
          displayText: '$i',
          isSelected: i == 7,
          isEnabled: true,
        )),
        onSelected: (_) {},
        autoScrollToSelected: true,
      ),
    ),
  );

  await tester.pumpAndSettle();

  // Verificar que item 7 está visible después del scroll
  expect(find.text('7'), findsOneWidget);
});
```

## 9. POSIBLES MEJORAS (NO implementadas)

### 9.1. Ancho real de items para auto-scroll preciso

```dart
final Map<int, double> _itemWidths = {};

// En itemBuilder:
return MeasureSize(
  onChange: (size) => _itemWidths[index] = size.width,
  child: itemWidget,
);

// En _scrollToSelected:
final offset = _itemWidths.entries
  .where((e) => e.key < selectedIndex)
  .fold(0.0, (sum, e) => sum + e.value);
```

### 9.2. Multi-select

```dart
final bool multiSelect;
final List<T> selectedValues;

onTap: () {
  if (multiSelect) {
    toggleSelection(option.value);
  } else {
    widget.onSelected(option.value);
  }
}
```

### 9.3. Custom item builder

```dart
final Widget Function(SelectorOption<T>, bool isSelected)? itemBuilder;

// En ListView:
itemBuilder: widget.itemBuilder != null
  ? widget.itemBuilder!(option, isSelected)
  : _buildDefaultItem(option, isSelected)
```

### 9.4. Scroll indicators

```dart
return Stack(
  children: [
    ListView(...),
    Positioned(
      left: 0,
      child: _scrollController.offset > 0
        ? Icon(Icons.chevron_left)
        : SizedBox.shrink(),
    ),
  ],
)
```

### 9.5. Pagination/Load more

```dart
final VoidCallback? onEndReached;

// En ListView:
controller: _scrollController..addListener(() {
  if (_scrollController.position.extentAfter < 100) {
    onEndReached?.call();
  }
})
```

## 10. RESUMEN

**Propósito**: Widget genérico reutilizable de selector horizontal con scroll

**Características clave**:
- Genérico \<T\> para cualquier tipo de valor
- Auto-scroll a seleccionado (opcional)
- Subtítulos opcionales con altura dinámica
- Estados enabled/disabled con opacity
- Highlight color personalizable per-option
- Label y icon opcionales
- Empty state con mensaje custom
- Configuración completa de dimensiones y spacing
- ScrollPhysics configurable

**Componentes**:
- Label (opcional): Icon + Text
- Lista horizontal: ListView.builder con items
- Empty state: Mensaje centrado

**Estados visuales**:
- Selected: Borde grueso + fondo sutil + texto bold + color de highlight
- No selected: Borde sutil gris + texto normal
- Disabled: Opacity 50% + no responde a taps

**Usado por**: CalendarHorizontalSelector, TimezoneHorizontalSelector, y otros selectores especializados

**Patrón**: Base component reutilizable, otros widgets lo componen

---

**Fin de la documentación de horizontal_selector_widget.dart**
