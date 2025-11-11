# EventCardBadges - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/event_card/event_card_badges.dart`
**Líneas**: 156
**Tipo**: StatelessWidget
**Propósito**: Mostrar badges informativos en EventCard (NEW, Calendario, Cumpleaños, Recurrente)

## 2. CLASE Y PROPIEDADES

### EventCardBadges (líneas 9-155)

**Propiedades**:
- `event` (Event, required): El evento a mostrar
- `config` (EventCardConfig, required): Configuración de visualización

## 3. MÉTODO BUILD

### build(BuildContext context) (líneas 16-47)

**Retorna**: Wrap con badges o SizedBox.shrink() si no hay badges

**Lógica**:
1. Inicializa lista vacía: `List<Widget> badges = []`

2. **Badge NEW** (líneas 19-22):
   - Si `config.showNewBadge == true` Y `event.isNewInteraction == true`
   - Agrega `_buildNewBadge()`

3. **Badge Calendar** (líneas 24-27):
   - Si `event.calendarId != null` Y `event.calendarName != null`
   - Agrega `_buildCalendarBadge()`

4. **Badge Birthday** (líneas 29-32):
   - Si `event.isBirthday == true`
   - Agrega `_buildBirthdayBadge(context)`

5. **Badge Recurring** (líneas 34-37):
   - Si `event.isRecurring == true`
   - Agrega `_buildRecurringBadge(context)`

6. **Validación** (líneas 39-41):
   - Si `badges.isEmpty` → retorna SizedBox.shrink()

7. **Retorno** (líneas 43-46):
   ```
   Padding(top: 6)
   └── Wrap(spacing: 4, runSpacing: 4)
       └── [badges...]
   ```

## 4. MÉTODOS PRIVADOS DE CONSTRUCCIÓN

### _buildNewBadge() (líneas 49-69)
**Retorna**: Container con badge "NEW"

**Estructura**:
```
Container
├── Padding: h6 v2
├── Decoration:
│   ├── Color: Red 600 con 8% opacidad
│   ├── BorderRadius: 4
│   └── Border: Red 600 con 20% opacidad, width 0.5
└── Row(mainAxisSize: min)
    ├── Icon(sparkles, size 11, red 600)
    ├── SizedBox(width: 3)
    └── Text("NEW")
        - fontSize: 11
        - color: red 600
        - fontWeight: w600
```

### _buildCalendarBadge() (líneas 71-96)
**Retorna**: Container con nombre del calendario

**Estructura**:
```
Container
├── Padding: h6 v2
├── Decoration:
│   ├── Color: Blue 600 con 8% opacidad
│   ├── BorderRadius: 4
│   └── Border: Blue 600 con 20% opacidad, width 0.5
└── Row(mainAxisSize: min)
    ├── [Condicional] if (calendarColor != null)
    │   ├── Container circular 8x8
    │   │   - Color: parseColor(calendarColor)
    │   └── SizedBox(width: 4)
    └── Text(calendarName)
        - fontSize: 11
        - color: blue 600
        - fontWeight: w500
```

**Lógica del color dot**:
- Solo se muestra si `event.calendarColor != null`
- Color parseado de string hexadecimal
- Círculo pequeño (8x8) antes del nombre

### _buildBirthdayBadge(BuildContext context) (líneas 98-119)
**Retorna**: Container con badge de cumpleaños

**Estructura**:
```
Container
├── Padding: h6 v2
├── Decoration:
│   ├── Color: Orange 600 con 8% opacidad
│   ├── BorderRadius: 4
│   └── Border: Orange 600 con 20% opacidad, width 0.5
└── Row(mainAxisSize: min)
    ├── Icon(gift, size 11, orange 600)
    ├── SizedBox(width: 3)
    └── Text(l10n.isBirthday)
        - fontSize: 11
        - color: orange 600
        - fontWeight: w500
```

### _buildRecurringBadge(BuildContext context) (líneas 121-142)
**Retorna**: Container con badge de evento recurrente

**Estructura**:
```
Container
├── Padding: h6 v2
├── Decoration:
│   ├── Color: Green 600 con 8% opacidad
│   ├── BorderRadius: 4
│   └── Border: Green 600 con 20% opacidad, width 0.5
└── Row(mainAxisSize: min)
    ├── Icon(repeat, size 11, green 600)
    ├── SizedBox(width: 3)
    └── Text(l10n.recurringEvent)
        - fontSize: 11
        - color: green 600
        - fontWeight: w500
```

### _parseColor(String colorString) (líneas 144-154)
**Retorna**: Color parseado de string hexadecimal

**Parámetros**:
- `colorString`: String en formato "#RRGGBB" o "RRGGBB"

**Lógica** (try-catch):
1. Elimina '#' del string: `colorString.replaceAll('#', '')`
2. Si longitud == 6 (sin alpha):
   - Prepend 'FF': `hexColor = 'FF$hexColor'`
3. Parsea: `int.parse(hexColor, radix: 16)`
4. Retorna Color(value)
5. En catch: retorna `AppStyles.blue600` (fallback)

**Ejemplos**:
- Input: "#FF5733" → Output: Color(0xFFFF5733)
- Input: "FF5733" → Output: Color(0xFFFF5733)
- Input: "FF5733" (6 chars) → Añade alpha → Color(0xFFFF5733)
- Input: "invalid" → catch → Color(AppStyles.blue600)

## 5. ORDEN DE BADGES

Los badges se agregan en este orden (si aplican):
1. **NEW** (rojo)
2. **Calendar** (azul)
3. **Birthday** (naranja)
4. **Recurring** (verde)

**Nota**: El orden visual será el mismo ya que se agregan secuencialmente a la lista

## 6. CONDICIONES DE VISUALIZACIÓN

| Badge | Condición | Fuente de verdad |
|-------|-----------|------------------|
| NEW | `config.showNewBadge && event.isNewInteraction` | Config + Event |
| Calendar | `event.calendarId != null && event.calendarName != null` | Event |
| Birthday | `event.isBirthday` | Event |
| Recurring | `event.isRecurring` | Event |

## 7. CONFIGURACIÓN

### EventCardConfig
**Propiedades usadas**:
- `showNewBadge` (bool): Si mostrar el badge NEW

**Nota**: Solo NEW es configurable, los demás se muestran automáticamente según el evento

## 8. ESTILOS Y CONSTANTES

### Estructura común de badges:
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: BoxDecoration(
    color: colorWithOpacity(mainColor, 0.08),     // 8% opacidad
    borderRadius: BorderRadius.circular(4),
    border: Border.all(
      color: colorWithOpacity(mainColor, 0.2),    // 20% opacidad
      width: 0.5
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: mainColor),
      SizedBox(width: 3),
      Text(label, fontSize: 11, color: mainColor, fontWeight: weightValue),
    ],
  ),
)
```

### Colores por badge:

| Badge | Color | Opacidad fondo | Opacidad borde | Icon | FontWeight |
|-------|-------|----------------|----------------|------|------------|
| NEW | Red 600 | 8% | 20% | sparkles | w600 |
| Calendar | Blue 600 | 8% | 20% | N/A | w500 |
| Birthday | Orange 600 | 8% | 20% | gift | w500 |
| Recurring | Green 600 | 8% | 20% | repeat | w500 |

### Iconos:
- **NEW**: CupertinoIcons.sparkles ✨
- **Birthday**: CupertinoIcons.gift 🎁
- **Recurring**: CupertinoIcons.repeat 🔄
- **Calendar**: No tiene icono, usa color dot

## 9. LOCALIZACIÓN

Strings localizados usados:
- `l10n.isBirthday`: Texto del badge de cumpleaños
  - Ejemplo: "Cumpleaños", "Birthday", etc.
- `l10n.recurringEvent`: Texto del badge de recurrente
  - Ejemplo: "Recurrente", "Recurring", etc.

**Nota**: El badge NEW no está localizado (siempre "NEW")

## 10. LAYOUT

### Wrap settings:
- **spacing**: 4px (espacio horizontal entre badges)
- **runSpacing**: 4px (espacio vertical si hay wrap)
- **Padding top**: 6px (separación del contenido superior)

### Badge interno:
- **Icon size**: 11px
- **Font size**: 11px
- **Spacing icon-text**: 3px
- **Padding**: horizontal 6px, vertical 2px
- **BorderRadius**: 4px
- **Border width**: 0.5px

## 11. COMPORTAMIENTO ESPECIAL

### Calendar badge:
- **Color dot condicional**: Solo se muestra si `event.calendarColor != null`
- **Dot size**: 8x8 px
- **Dot shape**: BoxShape.circle
- **Dot color**: Parseado de `event.calendarColor`

### NEW badge:
- **Controlado por config**: A diferencia de otros badges
- **Requiere dos condiciones**: Config Y event.isNewInteraction
- **No localizado**: Siempre muestra "NEW" en inglés
- **Font weight más alto**: w600 vs w500 de los demás

### Fallback en parsing:
- Si falla parsear color de calendario → usa blue 600
- No crashea, siempre retorna un Color válido

## 12. EVENTOS DE ORIGEN

### Event properties usadas:
- `isNewInteraction` (bool): Si el evento es nuevo para el usuario
- `calendarId` (int?): ID del calendario
- `calendarName` (String?): Nombre del calendario
- `calendarColor` (String?): Color del calendario en hex
- `isBirthday` (bool): Si es un cumpleaños
- `isRecurring` (bool): Si es un evento recurrente

## 13. DEPENDENCIAS

**Imports principales**:
- flutter/cupertino.dart
- Models: Event
- Helpers: platform_widgets (para iconos adaptativos)
- Styles: app_styles
- L10n: app_localizations
- event_card_config (EventCardConfig)

## 14. NOTAS ADICIONALES

- **StatelessWidget**: No mantiene estado, puramente presentacional
- **Iconos adaptativos**: Usa PlatformWidgets.platformIcon para adaptar a plataforma
- **Wrap responsive**: Los badges se ajustan automáticamente en múltiples líneas si es necesario
- **Consistencia visual**: Todos los badges siguen la misma estructura y proporciones
- **Color parsing robusto**: Try-catch previene crashes con colores inválidos
- **Badges independientes**: Cada badge puede mostrarse u ocultarse independientemente
- **No hay límite de badges**: Todos los que apliquen se mostrarán
- **Spacing uniforme**: 4px entre badges garantiza consistencia visual
- **NEW es especial**: Único badge que requiere configuración explícita
- **Sin callbacks**: Badges son puramente informativos, no interactivos
