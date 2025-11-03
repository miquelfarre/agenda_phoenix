# BirthdaysScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/birthdays_screen.dart`
**Líneas**: 191
**Tipo**: ConsumerStatefulWidget
**Propósito**: Pantalla que muestra eventos de cumpleaños ordenados por proximidad (próximos primero), con funcionalidad de búsqueda

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **EventCard** (líneas 175-181)
**Archivo**: `lib/widgets/event_card.dart`
**Documentación**: `lib/widgets_md/event_card.md`

**Uso en BirthdaysScreen**:
```dart
EventCard(
  event: event,
  onTap: () {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => EventDetailScreen(event: event)
      )
    );
  },
  config: EventCardConfig.readOnly().copyWith(
    customStatus: DateTimeUtils.formatBirthdayDate(
      event.startDate,
      Localizations.localeOf(context).languageCode
    )
  ),
)
```

**Ubicación**: Dentro de `SliverList` (delegate builder), renderizado para cada cumpleaños
**Propósito**: Renderizar cada cumpleaños con información completa en modo solo lectura
**Configuración específica**:
- `config: EventCardConfig.readOnly()` - Modo solo lectura (sin acciones de edición)
- `customStatus`: Fecha formateada especialmente para cumpleaños
- `onTap`: Navega a EventDetailScreen para ver detalles completos

**Características especiales**:
- Usa `DateTimeUtils.formatBirthdayDate()` para formato de fecha apropiado
- Se adapta al idioma del usuario con `languageCode`
- Cada tarjeta va precedida por una etiqueta de proximidad ("Hoy", "Mañana", "En X días")

**Renderizado condicional**: Solo se muestra si `eventsToShow.isNotEmpty == true`

### 2.2. Configuración y Utilities

#### **EventCardConfig** (línea 180)
**Archivo**: `lib/widgets/event_card/event_card_config.dart`
**Documentación**: `lib/widgets_md/event_card_config.md`

**Uso**:
```dart
EventCardConfig.readOnly().copyWith(
  customStatus: DateTimeUtils.formatBirthdayDate(...)
)
```

**Propósito**: Configurar EventCard en modo solo lectura con estado personalizado
**Factory constructor usado**: `EventCardConfig.readOnly()` - deshabilita todas las acciones
**Modificación**: `copyWith(customStatus: ...)` para mostrar fecha formateada de cumpleaños

### 2.3. Resumen de Dependencias de Widgets

```
BirthdaysScreen
└── CupertinoPageScaffold
    └── SafeArea
        └── CustomScrollView
            ├── SliverToBoxAdapter (campo de búsqueda)
            ├── SliverToBoxAdapter (contador de cumpleaños)
            ├── SliverToBoxAdapter (espaciador)
            ├── SliverFillRemaining (estado vacío si no hay cumpleaños)
            │   └── Icon + Text (mensaje vacío)
            └── SliverList (si hay cumpleaños)
                └── Column (por cada cumpleaños)
                    ├── Text (etiqueta de proximidad)
                    └── EventCard
                        └── EventDetailScreen (navegación al tap)
```

**Total de widgets propios**: 2 (EventCard, EventCardConfig)
**Nota**: Esta pantalla usa widgets nativos de Cupertino para la mayoría de la UI

---

## 3. CLASE Y PROPIEDADES

### BirthdaysScreen (líneas 12-17)
Widget principal que extiende `ConsumerStatefulWidget`

**Propiedades**: Ninguna (constructor solo con key)

### _BirthdaysScreenState (líneas 19-190)
Estado del widget que gestiona la lógica de la pantalla

**Propiedades de instancia**:
- `_searchController` (TextEditingController): Controlador para el campo de búsqueda

## 3. CICLO DE VIDA

### initState() (líneas 23-26)
1. Llama a `super.initState()`
2. Añade listener al `_searchController` que llama a `_filterBirthdays()`

### dispose() (líneas 28-32)
1. Limpia `_searchController.dispose()`
2. Llama a `super.dispose()`

## 4. MÉTODOS DE FILTRADO Y BÚSQUEDA

### _filterBirthdays() (líneas 34-36)
**Tipo de retorno**: `void`

**Propósito**: Callback que se ejecuta cuando cambia el texto de búsqueda

**Lógica**:
- Verifica que esté montado
- Llama a `setState(() {})` para forzar rebuild

### _applySearchFilter(List<Event> birthdays) (líneas 38-45)
**Tipo de retorno**: `List<Event>`

**Parámetros**:
- `birthdays`: Lista de cumpleaños a filtrar

**Propósito**: Filtra cumpleaños según query de búsqueda

**Lógica**:
1. Obtiene query del controller (trim + lowercase)
2. Si query vacía: retorna todos los cumpleaños
3. Si hay query: filtra eventos donde:
   - Título contiene la query, O
   - Descripción contiene la query (si existe)
4. Retorna lista filtrada

## 5. MÉTODOS DE ORDENACIÓN

### _sortByUpcomingBirthdays(List<Event> birthdays) (líneas 47-61)
**Tipo de retorno**: `List<Event>`

**Parámetros**:
- `birthdays`: Lista de cumpleaños a ordenar

**Propósito**: Ordena cumpleaños por proximidad (próximos primero)

**Lógica**:
1. Obtiene mes y día actuales
2. Crea copia de la lista con `.toList()`
3. Ordena con `.sort()`:
   - Calcula días hasta próximo cumpleaños de A
   - Calcula días hasta próximo cumpleaños de B
   - Compara: el que tenga menos días va primero
   - Si empatan en días: ordena alfabéticamente por título
4. Retorna lista ordenada

### _daysUntilNextBirthday(int birthdayMonth, int birthdayDay, int currentMonth, int currentDay) (líneas 63-73)
**Tipo de retorno**: `int`

**Parámetros**:
- `birthdayMonth`: Mes del cumpleaños (1-12)
- `birthdayDay`: Día del cumpleaños (1-31)
- `currentMonth`: Mes actual (actualmente no se usa)
- `currentDay`: Día actual (actualmente no se usa)

**Propósito**: Calcula cuántos días faltan para el próximo cumpleaños

**Lógica**:
1. Obtiene fecha actual
2. Crea `thisYearBirthday` con el año actual
3. Si el cumpleaños de este año es futuro O es hoy:
   - Retorna diferencia en días entre cumpleaños y hoy
4. Si el cumpleaños de este año ya pasó:
   - Crea `nextYearBirthday` con año siguiente
   - Retorna diferencia en días

**Resultado**: Número de días hasta el próximo cumpleaños (0 = hoy)

### _getBirthdayLabel(Event event) (líneas 75-94)
**Tipo de retorno**: `String`

**Parámetros**:
- `event`: Evento de cumpleaños

**Propósito**: Obtiene etiqueta legible de proximidad del cumpleaños

**Lógica**:
1. Calcula días hasta próximo cumpleaños
2. Según la cantidad de días:
   - **0 días**: "Hoy"
   - **1 día**: "Mañana"
   - **2-6 días**: "En X días"
   - **7-29 días** (< 30):
     - Si es 1 semana: "En 1 semana"
     - Si son varias: "En X semanas"
   - **30-364 días** (< 365):
     - Si es 1 mes: "En 1 mes"
     - Si son varios: "En X meses"
   - **365+ días**: "En 1 año"

**Nota**: Los cálculos de semanas y meses son aproximados (semana = 7 días, mes = 30 días)

## 6. MÉTODO BUILD

### build(BuildContext context, WidgetRef ref) (líneas 97-114)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la UI principal de la pantalla

**Lógica**:
1. Observa `eventsStreamProvider` con `ref.watch`
2. Extrae eventos con `.when()` (data → eventos, loading/error → lista vacía)
3. Filtra solo eventos de cumpleaños: `where((event) => event.isBirthday)`
4. Ordena por proximidad con `_sortByUpcomingBirthdays()`
5. Aplica filtro de búsqueda con `_applySearchFilter()`
6. Retorna `CupertinoPageScaffold` con:
   - **NavigationBar**:
     - Fondo con color del sistema
     - Middle: "Cumpleaños" (traducido)
   - **Child**: SafeArea con `_buildContent(eventsToShow)`

### _buildContent(List<Event> eventsToShow) (líneas 116-189)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `eventsToShow`: Lista de cumpleaños filtrados y ordenados

**Propósito**: Construye el contenido scrollable de la pantalla

**Estructura**:
Retorna `CustomScrollView` con física `ClampingScrollPhysics` y los siguientes slivers:

1. **SliverToBoxAdapter** (líneas 120-125): Campo de búsqueda
   - Padding de 16px
   - `CupertinoSearchTextField` con controller y placeholder "Buscar cumpleaños"

2. **SliverToBoxAdapter** (líneas 127-139): Contador
   - Padding horizontal de 16px
   - Text mostrando "{cantidad} cumpleaño(s)" con:
     - Singular si es 1
     - Plural si son múltiples
   - Estilo: tamaño 14, gris600, peso 500

3. **SliverToBoxAdapter** (línea 140): Espaciador de 8px

4. **Condicional** (líneas 142-155): Si NO hay cumpleaños
   - `SliverFillRemaining` con:
     - Icono de regalo (64px, gris)
     - Espaciador de 16px
     - Text:
       - "No se encontraron cumpleaños" si hay búsqueda
       - "No hay cumpleaños" si no hay búsqueda

5. **Condicional** (líneas 156-186): Si HAY cumpleaños
   - `SliverList` con `SliverChildBuilderDelegate`
   - Para cada cumpleaños:
     - Obtiene etiqueta de proximidad con `_getBirthdayLabel()`
     - Padding (horizontal 16px, vertical 8px)
     - Column con:
       - **Label de proximidad** (líneas 167-173):
         - Padding bottom 8px, left 4px
         - Text con la etiqueta (ej: "Hoy", "En 3 días")
         - Estilo: tamaño 12, gris600, peso 600
       - **EventCard** (líneas 175-181):
         - event: el cumpleaños
         - onTap: navega a `EventDetailScreen`
         - config: `EventCardConfig.readOnly()` con:
           - `customStatus`: fecha del cumpleaños formateada con `DateTimeUtils.formatBirthdayDate()`

## 7. DEPENDENCIAS

### Providers utilizados:
- `eventsStreamProvider`: Stream de eventos (observado con watch)

### Utilities:
- `DateTimeUtils.formatBirthdayDate()`: Formatea fecha de cumpleaños

### Widgets externos:
- `CupertinoPageScaffold`: Scaffold de iOS
- `CupertinoNavigationBar`: Barra de navegación de iOS
- `CupertinoSearchTextField`: Campo de búsqueda de iOS
- `CupertinoPageRoute`: Transición de página de iOS
- `CustomScrollView`: Vista scrollable personalizada
- `SliverToBoxAdapter`: Adapta widget a sliver
- `SliverFillRemaining`: Llena espacio restante
- `SliverList`: Lista perezosa en sliver
- `SliverChildBuilderDelegate`: Delegado para construir hijos

### Widgets internos:
- `EventCard`: Tarjeta de evento
- `EventCardConfig`: Configuración de la tarjeta
- `EventDetailScreen`: Pantalla de detalle

### Navegación:
- `Navigator.of(context).push()`: Para navegar a detalle

### Localización:
- `AppLocalizations.of(context)!`: Acceso a traducciones
- `Localizations.localeOf(context).languageCode`: Código de idioma
- Strings usados: `birthdays`, `birthday`, `searchBirthdays`, `noBirthdaysFound`, `noBirthdays`, `today`, `tomorrow`, `inDays`, `inOneWeek`, `inWeeks`, `inOneMonth`, `inMonths`, `inOneYear`

## 8. FLUJO DE DATOS

### Al abrir la pantalla:
1. Stream emite todos los eventos
2. Filtra solo cumpleaños (`isBirthday == true`)
3. Ordena por proximidad (próximos primero)
4. Aplica filtro de búsqueda (vacío inicialmente)
5. Renderiza lista ordenada

### Al buscar:
1. Usuario escribe en campo de búsqueda
2. Listener del controller se ejecuta
3. `_filterBirthdays()` llama a `setState()`
4. `build()` se ejecuta de nuevo
5. `_applySearchFilter()` filtra por título/descripción
6. Lista se actualiza con resultados

### Cálculo de proximidad:
1. Para cada cumpleaños, calcula días hasta próximo
2. Si el cumpleaños de este año ya pasó, usa el del año siguiente
3. Ordena de menor a mayor días
4. Genera etiqueta legible según rango de días

## 9. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades principales:
1. **Lista de cumpleaños**: Muestra todos los eventos marcados como cumpleaños
2. **Ordenación por proximidad**: Los próximos cumpleaños aparecen primero
3. **Etiquetas de tiempo**: Muestra "Hoy", "Mañana", "En X días/semanas/meses"
4. **Búsqueda**: Filtra por título o descripción
5. **Navegación a detalle**: Tap en cumpleaños muestra detalle completo
6. **Contador**: Muestra cantidad total de cumpleaños
7. **Estado vacío**: Mensaje apropiado si no hay cumpleaños
8. **Configuración read-only**: EventCard en modo solo lectura

### Estados manejados:
- Lista de cumpleaños (ordenada por proximidad)
- Query de búsqueda
- Estado vacío (sin cumpleaños)
- Estado vacío de búsqueda (búsqueda sin resultados)

### Algoritmo de ordenación:
1. Calcula días hasta próximo cumpleaños para cada evento
2. Ordena ascendentemente por días
3. Si empatan, ordena alfabéticamente
4. El cumpleaños de hoy (0 días) aparece primero
5. Cumpleaños de mañana (1 día) aparece segundo
6. Y así sucesivamente hasta cubrir todo el año

### Formato de fechas:
- Usa `DateTimeUtils.formatBirthdayDate()` para mostrar fecha
- Se adapta al idioma del usuario con `languageCode`
- Formato personalizado para cumpleaños

## 10. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 191
**Métodos públicos**: 1 (build)
**Métodos privados**: 6

**Distribución aproximada**:
- Imports: ~10 líneas (5.2%)
- Declaración de clase y propiedades: ~8 líneas (4.2%)
- Ciclo de vida: ~11 líneas (5.8%)
- Filtrado y búsqueda: ~12 líneas (6.3%)
- Ordenación: ~15 líneas (7.9%)
- Cálculo de días: ~11 líneas (5.8%)
- Generación de etiquetas: ~20 líneas (10.5%)
- build method: ~18 líneas (9.4%)
- _buildContent method: ~74 líneas (38.7%)
- Resto: ~12 líneas (6.3%)

## 11. CARACTERÍSTICAS TÉCNICAS

### Ordenación inteligente:
- Considera el año actual y próximo
- Calcula días exactos hasta cada cumpleaños
- Maneja correctamente cumpleaños que ya pasaron este año

### Etiquetas relativas:
- Traducciones contextuales (hoy, mañana, en X días)
- Escalas de tiempo apropiadas (días → semanas → meses → año)
- Aproximaciones razonables para semanas (7 días) y meses (30 días)

### Modo read-only:
- Usa `EventCardConfig.readOnly()` para las tarjetas
- No permite editar o eliminar cumpleaños desde esta pantalla
- Muestra fecha personalizada con `customStatus`

### Búsqueda en memoria:
- No hace llamadas a API
- Filtra lista cargada
- Búsqueda case insensitive
- Busca en título y descripción

### Sliver performance:
- Usa `SliverList` para renderizado perezoso
- Solo construye items visibles
- Buen rendimiento con muchos cumpleaños

### Parámetros sin usar:
- `_daysUntilNextBirthday()` recibe `currentMonth` y `currentDay` pero no los usa
- Posiblemente parámetros legacy o preparados para futura optimización
