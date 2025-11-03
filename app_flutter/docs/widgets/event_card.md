# EventCard - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/event_card.dart`
**Líneas**: 214
**Tipo**: ConsumerWidget
**Propósito**: Componente principal para mostrar eventos en listas con soporte para múltiples variantes, badges, acciones y estados de invitación

## 2. CLASE Y PROPIEDADES

### EventCard (líneas 16-213)
Widget que extiende `ConsumerWidget` para acceso a Riverpod providers

**Propiedades**:
- `event` (Event, required): El evento a mostrar
- `onTap` (VoidCallback, required): Callback al tocar la tarjeta
- `config` (EventCardConfig, default: EventCardConfig()): Configuración de visualización

## 3. MÉTODO BUILD

### build(BuildContext context, WidgetRef ref) (líneas 24-65)

**Lógica de interactions**:
1. Obtiene interactions del `eventInteractionsProvider`
2. Busca la interaction específica para este evento por `eventId`
3. Extrae el `participationStatus` de la interaction
4. Si hay participationStatus Y config permite mostrarla → actualiza effectiveConfig

**Estructura del widget**:
```
GestureDetector(onTap)
└── Container (padding, decoration con shadow)
    └── Column
        ├── EventCardHeader (event, config)
        ├── Row principal
        │   ├── _buildLeading() - Avatar/Time
        │   ├── Expanded(_buildEventContent()) - Contenido central
        │   └── EventCardActions - Acciones trailing
        └── EventCardAttendeesRow (event)
```

**Container principal**:
- Padding: 10px todo alrededor
- Color: Blanco con opacidad 1.0
- BorderRadius: 12px
- BoxShadow: Negro 3% opacidad, blur 6, offset (0,2)

## 4. MÉTODOS PRIVADOS DE CONSTRUCCIÓN

### _buildLeading(BuildContext context) (líneas 68-78)
**Retorna**: Widget para el leading (izquierda) de la tarjeta

**Lógica condicional**:
1. Si `config.customAvatar != null` → retorna el avatar personalizado
2. Si `event.isBirthday == true` → retorna `_buildBirthdayAvatar()`
3. Default → retorna `_buildTimeContainer()`

### _buildBirthdayAvatar(BuildContext context) (líneas 80-96)
**Retorna**: Avatar circular para cumpleaños

**Estructura**:
- Container circular 65x65
- Color: Orange con 10% opacidad
- Borde: Orange 30% opacidad, 1.5px
- Contenido (ClipOval):
  - Si tiene profilePicture → CachedNetworkImage
  - Si no → _buildBirthdayIcon()

### _buildBirthdayIcon() (líneas 98-100)
**Retorna**: Icono de regalo centrado

**Detalles**:
- Icono: CupertinoIcons.gift
- Color: Orange 600
- Tamaño: 32px

### _buildTimeContainer(BuildContext context) (líneas 102-134)
**Retorna**: Container con hora y fecha del evento

**Lógica de hora**:
1. Obtiene `event.date` y `l10n.colon`
2. Formatea hora: `HH:MM` con padding de ceros
3. Ejemplo: `09:05` o `14:30`

**Estructura del Container**:
- Tamaño: 65x65
- Color: Blue 600 con 10% opacidad
- BorderRadius: 12px
- Borde: Blue 600 con 30% opacidad, 1.5px
- Contenido (Column, mainAxisAlignment.center):
  - Text(hora) - fontSize 18, bold, blue 600
  - Si `config.showDate`:
    - SizedBox(height: 2)
    - Text(fecha corta) - fontSize 10, blue 600

### _formatDateShort(DateTime date, AppLocalizations l10n) (líneas 136-153)
**Retorna**: String con formato "DD MMM" (ej: "3 Nov")

**Lógica**:
1. Crea array de meses abreviados (primeros 3 chars de cada mes localizado)
2. Retorna: `{day} {monthAbbr}`

### _buildEventContent(...) (líneas 155-186)
**Parámetros**:
- context, l10n, config, ref

**Retorna**: Column con todo el contenido central del evento

**Estructura**:
```
Column(crossAxisAlignment: start)
├── Text(title) - style: cardTitle, maxLines: 2, ellipsis
├── SizedBox(height: 4)
├── if (description.isNotEmpty)
│   └── Text(description) - style: cardSubtitle, maxLines: 2, ellipsis
├── EventCardBadges(event, config)
├── if (customStatus != null)
│   ├── SizedBox(height: 4)
│   └── Text(customStatus) - blue 600, fontSize 12
└── if (showInvitationStatus && status != 'pending')
    ├── SizedBox(height: 4)
    └── Container (status badge)
        └── Text(statusText) - fontSize 12, white, bold
```

**Prioridad de contenido**:
1. Título: `config.customTitle ?? event.title`
2. Descripción: `config.customSubtitle ?? event.description`

**Status badge** (solo si NO es pending):
- Padding: horizontal 8, vertical 2
- BorderRadius: 12
- Color de fondo según status (via _getStatusColor)
- Texto blanco centrado

### _getStatusColor(BuildContext context, String status) (líneas 188-199)
**Retorna**: Color según el estado de la invitación

**Mapeo** (case-insensitive):
- `'pending'` → Orange 600
- `'accepted'` → Green 600
- `'rejected'` → Red 600
- Default → Grey 500

### _getStatusText(AppLocalizations l10n, String status) (líneas 201-212)
**Retorna**: String localizado del status

**Mapeo** (case-insensitive):
- `'pending'` → `l10n.pendingStatus`
- `'accepted'` → `l10n.acceptedStatus`
- `'rejected'` → `l10n.rejectedStatus`
- Default → status original

## 5. COMPONENTES EXTERNOS UTILIZADOS

### EventCardHeader (líneas 48)
**Archivo**: `event_card/event_card_header.dart`
**Props**: event, config
**Propósito**: Muestra banner de invitación y avatar del owner

### EventCardActions (líneas 57)
**Archivo**: `event_card/event_card_actions.dart`
**Props**: event, config, interaction, participationStatus
**Propósito**: Botones de acción (aceptar/rechazar, eliminar, chevron)

### EventCardAttendeesRow (líneas 61)
**Archivo**: `event_card/event_card_header.dart`
**Props**: event
**Propósito**: Fila de avatares de asistentes

### EventCardBadges (líneas 163)
**Archivo**: `event_card/event_card_badges.dart`
**Props**: event, config
**Propósito**: Badges de NEW, calendario, cumpleaños, recurrente

## 6. PROVIDERS UTILIZADOS

### eventInteractionsProvider (línea 28)
**Tipo**: AsyncValue<List<EventInteraction>>
**Propósito**: Obtener las interacciones del usuario con eventos
**Uso**: Determinar si hay invitación pendiente y su estado

## 7. CONFIGURACIÓN

### EventCardConfig
**Propiedades clave usadas**:
- `showInvitationStatus` (bool): Si mostrar el estado de invitación
- `invitationStatus` (String?): Estado actual ('pending', 'accepted', 'rejected')
- `customAvatar` (Widget?): Avatar personalizado para el leading
- `customTitle` (String?): Título personalizado
- `customSubtitle` (String?): Subtítulo personalizado
- `customStatus` (String?): Status adicional personalizado
- `showDate` (bool): Si mostrar la fecha en el time container

**Método copyWith**:
- Usado en línea 34 para actualizar config con invitationStatus dinámico

## 8. ESTILOS Y CONSTANTES

### AppStyles utilizados:
- `cardTitle`: Título del evento
- `cardSubtitle`: Descripción y subtítulos
- `bodyText`: Texto general
- Colores: blue600, orange600, green600, red600, grey400, grey500, grey700, white, black87

### AppConstants utilizados:
- `statusPending`: Constante para estado 'pending'
- `statusAccepted`: Constante para estado 'accepted'
- `statusRejected`: Constante para estado 'rejected'

## 9. LOCALIZACIÓN

Strings localizados usados:
- `l10n.colon`: Separador de hora
- `l10n.january` hasta `l10n.december`: Nombres de meses
- `l10n.pendingStatus`: Texto para estado pendiente
- `l10n.acceptedStatus`: Texto para estado aceptado
- `l10n.rejectedStatus`: Texto para estado rechazado

## 10. COMPORTAMIENTO ESPECIAL

### Estados de invitación:
1. **Pending**: Se muestra banner amarillo en header, NO se muestra badge en content
2. **Accepted**: Se muestra badge verde en content
3. **Rejected**: Se muestra badge rojo en content

### Cumpleaños:
- Se detecta con `event.isBirthday`
- Usa avatar circular con foto del owner o icono de regalo
- Color temático: Orange

### Eventos normales:
- Usa time container con hora y fecha
- Color temático: Blue

## 11. INTERACCIONES

### onTap:
- Se aplica a todo el GestureDetector
- Navega al detalle del evento (implementado por el parent)

### Acciones en EventCardActions:
- Aceptar/rechazar invitación (inline en el widget)
- Eliminar evento (via `config.onDelete`)
- Chevron de navegación (visual, el tap está en el parent)

## 12. DEPENDENCIAS

**Imports principales**:
- flutter/cupertino.dart
- flutter_riverpod (ConsumerWidget, WidgetRef)
- cached_network_image (para avatares)
- Componentes internos: EventCardConfig, EventCardBadges, EventCardActions, EventCardHeader
- Providers: app_state (eventInteractionsProvider)
- Helpers: platform_widgets, l10n_helpers
- Styles: app_styles
- Constants: app_constants

## 13. NOTAS ADICIONALES

- **Source of truth para interactions**: El provider `eventInteractionsProvider` es la única fuente de verdad
- **Config es inmutable**: Se usa copyWith para crear nuevas instancias con valores actualizados
- **Máximo 2 líneas**: Tanto título como descripción tienen `maxLines: 2` con ellipsis
- **Condicionales visuales**: Gran uso de if statements inline para mostrar/ocultar elementos
- **Cache de imágenes**: Usa CachedNetworkImage para optimizar carga de avatares
- **Localización completa**: Todos los textos visibles están localizados
