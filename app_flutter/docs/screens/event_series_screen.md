# EventSeriesScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/event_series_screen.dart`
**Líneas**: 111
**Tipo**: ConsumerStatefulWidget
**Propósito**: Pantalla que muestra una serie de eventos relacionados (eventos recurrentes que comparten el mismo parentRecurringEventId)

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **AdaptivePageScaffold** (línea 40)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_page_scaffold.md`

**Uso en EventSeriesScreen**:
```dart
AdaptivePageScaffold(
  title: l10n.eventSeries,
  body: SafeArea(
    child: Column(...)
  ),
)
```

**Ubicación**: Widget raíz retornado por `build()`
**Propósito**: Proporciona scaffold adaptativo (iOS/Material) para la pantalla
**Configuración específica**:
- `title`: "Serie de eventos" (traducido)
- `body`: Contiene toda la UI de la pantalla

#### **EmptyState** (línea 64)
**Archivo**: `lib/widgets/empty_state.dart`
**Documentación**: `lib/widgets_md/empty_state.md`

**Uso en EventSeriesScreen**:
```dart
EmptyState(
  message: l10n.noEventsInSeries,
  icon: CupertinoIcons.calendar
)
```

**Ubicación**: Dentro de `Expanded` cuando `sortedEvents.isEmpty` es true
**Propósito**: Mostrar estado vacío cuando la serie no tiene eventos
**Configuración específica**:
- `message`: "No hay eventos en la serie" (traducido)
- `icon`: Icono de calendario

**Renderizado condicional**: Solo se muestra si `sortedEvents.isEmpty == true`

#### **EventListItem** (líneas 72-81)
**Archivo**: `lib/widgets/event_list_item.dart`
**Documentación**: `lib/widgets_md/event_list_item.md`

**Uso en EventSeriesScreen**:
```dart
EventListItem(
  event: event,
  onTap: (event) => Navigator.of(context).push(
    CupertinoPageRoute(
      builder: (context) => EventDetailScreen(event: event)
    )
  ),
  onDelete: _deleteEvent,
  showDate: true,
  showNewBadge: false,
  hideInvitationStatus: true,
)
```

**Ubicación**: Dentro de `ListView.separated` (itemBuilder), renderizado para cada evento
**Propósito**: Renderizar cada evento de la serie en la lista ordenada
**Configuración específica**:
- `showDate: true` - Importante porque cada evento en la serie tiene fecha diferente
- `showNewBadge: false` - No es relevante marcar eventos como "nuevos" en serie
- `hideInvitationStatus: true` - Simplifica UI ocultando estado de invitación
- `onTap`: Navega a EventDetailScreen
- `onDelete`: Llama a `_deleteEvent()` que actualiza lista local

**Renderizado condicional**: Solo se muestra si `sortedEvents.isNotEmpty == true`

### 2.2. Resumen de Dependencias de Widgets

```
EventSeriesScreen
└── AdaptivePageScaffold
    └── SafeArea
        └── Column
            ├── Padding (header con nombre y contador)
            ├── Divider
            └── Expanded
                ├── EmptyState (si no hay eventos)
                └── ListView.separated (si hay eventos)
                    └── EventListItem (múltiples, uno por evento)
                        └── EventDetailScreen (navegación al tap)
```

**Total de widgets propios**: 3 (AdaptivePageScaffold, EmptyState, EventListItem)

---

## 3. CLASE Y PROPIEDADES

### EventSeriesScreen (líneas 14-22)
Widget principal que extiende `ConsumerStatefulWidget`

**Propiedades**:
- `events` (List<Event>, required): Lista de eventos de la serie a mostrar
- `seriesName` (String, required): Nombre de la serie (generalmente el título del evento parent)

### _EventSeriesScreenState (líneas 24-110)
Estado del widget que gestiona la lógica de la pantalla

**Propiedades de instancia**:
- `_events` (List<Event>, late): Copia mutable de la lista de eventos de la serie

## 3. CICLO DE VIDA

### initState() (líneas 27-31)
1. Llama a `super.initState()`
2. Crea copia de la lista de eventos: `_events = List<Event>.from(widget.events)`
   - Se hace copia para poder modificar la lista localmente al eliminar eventos

## 4. MÉTODO BUILD

### build(BuildContext context, WidgetRef ref) (líneas 33-89)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la UI principal de la pantalla

**Lógica**:
1. Obtiene `l10n` del contexto
2. Ordena eventos por fecha: `sortedEvents = List.from(_events)..sort((a, b) => a.date.compareTo(b.date))`
3. Retorna `AdaptivePageScaffold` con:
   - title: "Serie de eventos" (traducido)
   - body: SafeArea con Column que contiene:
     - **Header** (líneas 46-59): Padding de 16px con:
       - Nombre de la serie (tamaño 24, bold, gris oscuro)
       - Espaciador de 8px
       - Texto contador: "{cantidad} evento(s)" con:
         - Singular si es 1 evento
         - Plural si son múltiples eventos
     - **Divider** (línea 60): Línea separadora
     - **Contenido expandido** (líneas 61-84):
       - **Si no hay eventos** (líneas 62-65):
         - EmptyState con:
           - Mensaje: "No hay eventos en la serie"
           - Icono: calendario
       - **Si hay eventos** (líneas 66-83):
         - ListView.separated con padding 16px
         - Separator: espaciador de 12px
         - Para cada evento: `EventListItem` con:
           - event: el evento actual
           - onTap: navega a `EventDetailScreen` con el evento
           - onDelete: callback `_deleteEvent`
           - showDate: true (muestra la fecha en cada item)
           - showNewBadge: false (no muestra badge de "nuevo")
           - hideInvitationStatus: true (oculta estado de invitación)

## 5. MÉTODOS DE ACCIÓN

### _deleteEvent(Event event, {bool shouldNavigate = false}) (líneas 91-109)
**Tipo de retorno**: `Future<void>`

**Parámetros**:
- `event`: El evento a eliminar
- `shouldNavigate`: Si debe navegar después de eliminar (default: false)

**Propósito**: Delega la eliminación o abandono del evento a EventOperations y actualiza la lista local

**Lógica**:
1. Imprime log de debug: "Delegating to EventOperations"
2. Llama a `EventOperations.deleteOrLeaveEvent()` con:
   - `event`: el evento a procesar
   - `repository`: obtenido del provider
   - `context`: el contexto actual
   - `shouldNavigate`: el valor del parámetro
   - `showSuccessMessage`: false (no muestra mensaje de éxito)
3. Guarda el resultado en variable `success`
4. Si la operación fue exitosa Y el widget está montado:
   - Actualiza estado con `setState()`:
     - Elimina el evento de `_events` con `removeWhere((e) => e.id == event.id)`
   - Imprime log de éxito: "Event removed from series list. Remaining: {cantidad}"

## 6. DEPENDENCIAS

### Providers utilizados:
- `eventRepositoryProvider`: Repositorio de eventos (leído con read)

### Utilities:
- `EventOperations.deleteOrLeaveEvent()`: Maneja eliminación o abandono de evento con lógica centralizada

### Widgets externos:
- `ListView.separated`: Lista con separadores
- `Divider`: Línea divisoria

### Widgets internos:
- `AdaptivePageScaffold`: Scaffold adaptativo (iOS/Material)
- `EventListItem`: Widget personalizado para mostrar un item de evento
- `EmptyState`: Widget para estados vacíos
- `EventDetailScreen`: Pantalla de detalle de evento

### Navegación:
- `Navigator.of(context).push()`: Para navegar a EventDetailScreen con `CupertinoPageRoute`

### Localización:
- `context.l10n`: Acceso a traducciones
- Strings usados: `eventSeries`, `event`, `events`, `noEventsInSeries`

## 7. FLUJO DE DATOS

### Al abrir la pantalla:
1. Constructor recibe `events` y `seriesName`
2. `initState()` crea copia local de eventos
3. `build()` ordena eventos por fecha
4. Renderiza lista ordenada

### Al eliminar un evento:
1. Usuario presiona botón de eliminar en `EventListItem`
2. `_deleteEvent()` llama a EventOperations
3. EventOperations maneja lógica de permisos y confirmación
4. Si exitoso:
   - Actualiza lista local eliminando el evento
   - EventRepository actualiza vía Realtime (otras pantallas)
5. UI se actualiza mostrando nuevo contador y lista reducida

### Sincronización:
- Lista local: Se actualiza inmediatamente al eliminar
- Otras pantallas: Se actualizan vía Realtime
- Si el usuario vuelve atrás: la lista principal estará actualizada por Realtime

## 8. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Visualización de serie**: Muestra todos los eventos de una serie recurrente
2. **Ordenación**: Eventos ordenados cronológicamente
3. **Contador**: Muestra cantidad total de eventos en la serie
4. **Navegación a detalle**: Tap en evento lleva a pantalla de detalle
5. **Eliminación**: Permite eliminar eventos individuales de la serie
6. **Estado vacío**: Muestra mensaje apropiado si no hay eventos
7. **Actualización local**: Lista se actualiza inmediatamente al eliminar

### Estados manejados:
- Lista con eventos (ordenados por fecha)
- Lista vacía (estado vacío)
- Actualización local tras eliminación

### Configuración de EventListItem:
- `showDate: true`: Importante porque todos los eventos de la serie suelen tener fechas diferentes
- `showNewBadge: false`: No es relevante mostrar badge de "nuevo" en contexto de serie
- `hideInvitationStatus: true`: Simplifica la UI al no mostrar estado de invitación

## 9. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 111
**Métodos públicos**: 1 (build)
**Métodos privados**: 1 (_deleteEvent)

**Distribución aproximada**:
- Imports: ~12 líneas (10.8%)
- Declaración de clase: ~9 líneas (8.1%)
- initState: ~5 líneas (4.5%)
- build method: ~57 líneas (51.4%)
  - Sorting y setup: ~4 líneas
  - Scaffold y estructura: ~8 líneas
  - Header: ~14 líneas
  - Lista de eventos: ~23 líneas
  - Estado vacío: ~4 líneas
- _deleteEvent method: ~19 líneas (17.1%)

## 10. CARACTERÍSTICAS TÉCNICAS

### Copia defensiva:
- En `initState()` crea copia de la lista de eventos
- Permite modificar `_events` sin afectar `widget.events`
- Necesario para actualización local al eliminar

### Ordenación inmutable:
- En cada build: `List.from(_events)..sort(...)`
- Crea nueva lista ordenada sin modificar `_events`
- Safe approach para ordenar sin efectos secundarios

### Actualización optimista:
- Elimina de lista local inmediatamente tras éxito
- No espera a Realtime para actualizar UI
- Mejor UX con feedback instantáneo

### Integración con EventOperations:
- Delega lógica compleja a utility centralizada
- EventOperations maneja:
  - Verificación de permisos
  - Confirmación del usuario
  - Llamadas a API
  - Manejo de errores
- `showSuccessMessage: false` porque no queremos notificación por cada evento

### Logs de debug:
- Logs al delegar operación
- Logs al actualizar lista con cantidad restante
- Útil para troubleshooting

### Formato de contador:
- Singular/plural manejado correctamente
- "{cantidad} evento" si es 1
- "{cantidad} eventos" si es diferente de 1

### Pantalla simple y enfocada:
- No tiene mucha lógica compleja
- Se centra en mostrar y permitir eliminar
- Delega operaciones complejas a utilities
- UI minimalista y clara
