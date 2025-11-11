# EventCardHeader y EventCardAttendeesRow - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/event_card/event_card_header.dart`
**Líneas**: 228
**Tipo**: ConsumerWidget (ambos widgets)
**Propósito**: Componentes para el header del EventCard (banner de invitación, info del owner) y la fila de asistentes

## 2. CLASES Y PROPIEDADES

### EventCardHeader (líneas 16-165)

**Propiedades**:
- `event` (Event, required): El evento a mostrar
- `config` (EventCardConfig, required): Configuración de visualización

### EventCardAttendeesRow (líneas 168-227)

**Propiedades**:
- `event` (Event, required): El evento a mostrar

## 3. EventCardHeader - MÉTODO BUILD

### build(BuildContext context, WidgetRef ref) (líneas 23-41)

**Retorna**: Column con CrossAxisAlignment.start

**Lógica**:
1. Inicializa lista vacía de widgets: `List<Widget> widgets = []`
2. **Conditional: Invitation Banner** (líneas 28-30)
   - Si `config.showInvitationStatus == true`
   - Y `config.invitationStatus != null`
   - Y `config.invitationStatus.toLowerCase() == 'pending'`
   - Entonces: agrega `_buildInvitationBanner(l10n)` a widgets
3. **Conditional: Owner Info** (líneas 32-38)
   - Calcula `hasOwner = config.showOwner && event.owner?.isPublic == true && event.owner?.fullName != null`
   - Si hasOwner:
     - Agrega `_buildOwnerInfo(ref)` a widgets
     - Agrega `SizedBox(height: 6)` a widgets
4. Retorna Column con todos los widgets

**Estructura condicional**:
```
Column
├── [Condicional] InvitationBanner (solo si pending)
├── [Condicional] OwnerInfo (solo si owner público con nombre)
└── [Condicional] SizedBox(6) (spacing después de owner)
```

## 4. EventCardHeader - MÉTODOS PRIVADOS

### _buildInvitationBanner(AppLocalizations l10n) (líneas 43-68)
**Retorna**: Container con banner de invitación pendiente

**Lógica del inviter name** (líneas 44-53):
1. Inicializa `inviterText = ''`
2. Si `event.invitedByUserId != null`:
   - Busca en `event.attendees` el primero que sea Map y tenga `id == invitedByUserId`
   - Usa `orElse: () => null` para no fallar si no encuentra
   - Si encuentra inviter:
     - Extrae `inviterName = inviter['full_name'] ?? inviter['name']`
     - Si inviterName != null: `inviterText = ' • $inviterName'`

**Estructura del Container** (líneas 55-67):
- Padding: horizontal 10, vertical 4
- Margin: bottom 6
- Decoration:
  - Color: Orange 600 con 12% opacidad
  - BorderRadius: 8px
  - Border: Orange 600 con 35% opacidad, width 1
- Child: Text
  - Contenido: `'{l10n.pendingInvitationBanner}{inviterText}'`
  - Ejemplo: "Invitación pendiente • Juan Pérez"
  - Style: fontSize 12, orange 600, fontWeight w600

### _buildOwnerInfo(WidgetRef ref) (líneas 70-88)
**Retorna**: Container con avatar e info del owner

**Estructura**:
```
Container (padding: h8 v4, transparent background, borderRadius 6)
└── Row
    ├── _buildSmallOwnerAvatar(ref) - 18x18
    ├── SizedBox(width: 6)
    └── Expanded
        └── Text(owner.fullName)
            - blue 600, fontSize 13, fontWeight w600
            - overflow: ellipsis
```

### _buildSmallOwnerAvatar(WidgetRef ref) (líneas 90-143)
**Retorna**: Widget de avatar pequeño 18x18 del owner

**Lógica en cascada**:

1. **Validación inicial** (líneas 92-95):
   - Si `owner?.isPublic != true` → retorna SizedBox.shrink()

2. **Prioridad 1: Logo local** (líneas 97-108):
   - Obtiene `logoPath` de `logoPathProvider(owner.id)`
   - Si logoPath != null:
     - Retorna Container 18x18
     - BorderRadius: 4
     - Borde: Blue 600 con 25% opacidad, width 1
     - Imagen: FileImage(File(logoPath)), fit: cover

3. **Prioridad 2: Profile picture URL** (líneas 110-135):
   - Si `url != null && url.isNotEmpty`:
     - **Fix para placehold.co** (líneas 112-116):
       - Si URL contiene 'placehold.co' y NO contiene '.png'
       - Parsea URI y añade '.png' al path si no lo tiene
     - Retorna ClipRRect (borderRadius 4)
       - CachedNetworkImage 18x18
       - errorWidget: fallback a `_buildSmallInitials(name)` o SizedBox.shrink()

4. **Prioridad 3: Iniciales** (líneas 137-142):
   - Si `name != null && name.isNotEmpty`:
     - Retorna `_buildSmallInitials(name)`
   - Sino: SizedBox.shrink()

### _buildSmallInitials(String name) (líneas 145-164)
**Retorna**: Container 18x18 con iniciales del owner

**Lógica de iniciales** (línea 146):
```dart
name.trim()
  .split(RegExp(r"\s+"))        // Split por espacios
  .where((p) => p.isNotEmpty)   // Filtrar vacíos
  .take(2)                      // Máximo 2 palabras
  .map((p) => p[0])             // Primera letra de cada palabra
  .join()                       // Unir
  .toUpperCase()                // Mayúsculas
```
- Si initials.isEmpty → initials = '?'
- Ejemplo: "Juan Pérez" → "JP"

**Estructura del Container**:
- Tamaño: 18x18
- Color: Blue 600 con 12% opacidad
- BorderRadius: 4
- Borde: Blue 600 con 25% opacidad, width 1
- Child: Center > Text(initials)
  - fontSize: 10
  - fontWeight: w600
  - color: blue 600
  - letterSpacing: 0.2

## 5. EventCardAttendeesRow - MÉTODO BUILD

### build(BuildContext context, WidgetRef ref) (líneas 174-226)

**Retorna**: Fila con avatares de asistentes (excluye usuario actual)

**Lógica de parsing** (líneas 175-189):
1. Obtiene `currentUserId` de ConfigService
2. **Parse attendees** (líneas 178-185):
   - Inicializa `attendeeData = []`
   - Itera sobre `event.attendees`:
     - Si es User → convierte a Map con id, full_name, profile_picture
     - Si es Map<String, dynamic> → lo añade directamente
3. **Filtrado** (línea 188):
   - Filtra `otherAttendees` donde `id != currentUserId`
4. **Validación**:
   - Si otherAttendees.isEmpty → retorna SizedBox.shrink()

**Estructura del widget** (líneas 192-225):
```
Padding(top: 8)
└── Row(crossAxisAlignment: center)
    ├── Text("Asistentes")
    │   - grey 700, fontSize 13, fontWeight w600
    ├── SizedBox(width: 8)
    └── Flexible
        └── Wrap(spacing: 6, runSpacing: 4)
            └── [hasta 6 avatares circulares]
```

**Lógica de avatares** (líneas 206-220):
- Usa `take(6)` para mostrar máximo 6 asistentes
- Mapea cada attendee a:
  - Container circular 26x26
  - Color: Blue 600
  - Extrae nombre: `a['full_name'] ?? a['name'] ?? ''`
  - Extrae iniciales: primera letra del primer nombre (trim, split, toUpperCase)
  - Si nombre vacío → iniciales = '?'
  - Text: iniciales blancas, fontWeight w700, fontSize 12

## 6. PROVIDERS UTILIZADOS

### logoPathProvider(int userId) (línea 97)
**Tipo**: AsyncValue<String?>
**Propósito**: Obtener la ruta local del logo del usuario público
**Usado en**: EventCardHeader._buildSmallOwnerAvatar

## 7. SERVICIOS UTILIZADOS

### ConfigService.instance.currentUserId (línea 175)
**Tipo**: int
**Propósito**: Obtener el ID del usuario actual
**Usado en**: EventCardAttendeesRow para filtrar asistentes

## 8. ESTILOS Y CONSTANTES

### AppStyles utilizados:
- `bodyText`: Base para textos
- `cardSubtitle`: Subtítulos y labels
- Colores:
  - `orange600`: Banner de invitación
  - `blue600`: Owner info y avatares de asistentes
  - `grey700`: Label "Asistentes"
  - `white`: Textos sobre fondos de color

### AppConstants utilizados:
- `statusPending`: Constante para comparar estado de invitación

## 9. LOCALIZACIÓN

### EventCardHeader:
- `l10n.pendingInvitationBanner`: Texto del banner de invitación
  - Ejemplo: "Invitación pendiente"

### EventCardAttendeesRow:
- `context.l10n.attendees`: Label de la sección de asistentes
  - Ejemplo: "Asistentes"

## 10. COMPORTAMIENTO ESPECIAL

### Invitation Banner:
- **Solo se muestra si**:
  1. `config.showInvitationStatus == true`
  2. `invitationStatus` es 'pending' (case-insensitive)
- **Incluye nombre del inviter** si está disponible en attendees
- **Formato**: "Invitación pendiente • {nombre}" o solo "Invitación pendiente"

### Owner Avatar:
- **Prioridad en cascada**:
  1. Logo local (vía provider)
  2. Profile picture URL (con fix para placehold.co)
  3. Iniciales generadas
  4. SizedBox.shrink() si no hay nada
- **Solo para owners públicos**: Verifica `owner.isPublic == true`

### Attendees Row:
- **Excluye usuario actual**: Filtra por currentUserId
- **Máximo 6 avatares**: Usa `take(6)`
- **No muestra si vacío**: Retorna SizedBox.shrink()
- **Soporta Users y Maps**: Parsing flexible de attendees

## 11. FIX ESPECIALES

### Fix para placehold.co (líneas 112-116):
**Problema**: URLs de placehold.co sin extensión .png fallan en CachedNetworkImage
**Solución**:
```dart
if (url.contains('placehold.co') && !url.contains('.png')) {
  final uri = Uri.parse(url);
  final path = uri.path.endsWith('.png') ? uri.path : '${uri.path}.png';
  url = uri.replace(path: path).toString();
}
```

## 12. DEPENDENCIAS

**Imports principales**:
- dart:io (para FileImage)
- flutter/cupertino.dart
- flutter_riverpod (ConsumerWidget, WidgetRef)
- cached_network_image (para avatares remotos)
- Models: Event, User
- Providers: app_state (logoPathProvider)
- Services: config_service (currentUserId)
- Helpers: l10n_helpers
- Styles: app_styles
- Constants: app_constants
- event_card_config (EventCardConfig)

## 13. NOTAS ADICIONALES

- **Dos widgets en un archivo**: EventCardHeader y EventCardAttendeesRow son componentes relacionados pero independientes
- **ConfigService usado directamente**: EventCardAttendeesRow usa ConfigService.instance directamente (podría refactorizarse a provider)
- **Parsing defensivo**: Attendees soporta tanto User objects como Maps
- **Regex para iniciales**: Usa `RegExp(r"\s+")` para split por cualquier tipo de espacio
- **FirstWhere con orElse**: Previene excepciones al buscar inviter
- **Type checking robusto**: Verifica tipo con `is User` y `is Map<String, dynamic>`
- **Máximo de avatares hardcoded**: El límite de 6 avatares está hardcoded (no configurable)
