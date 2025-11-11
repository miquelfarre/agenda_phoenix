# TimezoneHorizontalSelector - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/timezone_horizontal_selector.dart`
**Líneas**: 98
**Tipo**: StatefulWidget con State privado
**Propósito**: Selector dual (país y zona horaria) que muestra primero países con banderas, luego zonas horarias del país seleccionado con offset GMT

## 2. CLASES CONTENIDAS

1. **TimezoneHorizontalSelector** (líneas 9-22): StatefulWidget público
2. **_TimezoneHorizontalSelectorState** (líneas 24-97): State privado con lógica

---

## 3. CLASE: TimezoneHorizontalSelector

### 3.1. Información General

**Líneas**: 9-22
**Tipo**: StatefulWidget
**Propósito**: Widget con estado para selección de país y zona horaria con inicialización

### 3.2. Propiedades (líneas 10-16)

- `initialCountry` (Country?, línea 10): País inicialmente seleccionado
- `initialCity` (String?, línea 12): Ciudad inicialmente seleccionada (no usado actualmente)
- `initialTimezone` (String?, línea 14): Zona horaria inicialmente seleccionada
- `onChanged` (Function(Country, String, String?), required, línea 16): Callback con país, timezone y ciudad

### 3.3. Constructor (línea 18)

```dart
const TimezoneHorizontalSelector({
  super.key,
  this.initialCountry,
  this.initialCity,
  this.initialTimezone,
  required this.onChanged
})
```

**Único required**: onChanged

**Callback signature**:
```dart
void Function(Country country, String timezone, String? city)
```

### 3.4. Método createState (líneas 20-21)

```dart
@override
State<TimezoneHorizontalSelector> createState() =>
  _TimezoneHorizontalSelectorState();
```

---

## 4. CLASE: _TimezoneHorizontalSelectorState

### 4.1. Información General

**Líneas**: 24-97
**Tipo**: State<TimezoneHorizontalSelector>
**Visibilidad**: Privada

### 4.2. Variables de estado (líneas 25-27)

```dart
Country? _selectedCountry;
String? _selectedTimezone;
List<Country> _allCountries = [];
```

**_selectedCountry**: País actualmente seleccionado (nullable)
**_selectedTimezone**: Timezone actualmente seleccionado (nullable)
**_allCountries**: Lista de todos los países disponibles (inicializado vacío)

### 4.3. Método initState (líneas 29-35)

```dart
@override
void initState() {
  super.initState();
  _selectedCountry = widget.initialCountry;
  _selectedTimezone = widget.initialTimezone;
  _loadCountries();
}
```

**Propósito**: Inicializa el estado con valores iniciales

**Lógica**:
1. Llama super.initState()
2. Asigna país inicial a _selectedCountry
3. Asigna timezone inicial a _selectedTimezone
4. Carga lista de países

**Nota**: initialCity se proporciona pero NO se usa en el estado

### 4.4. Método _loadCountries (líneas 37-39)

```dart
void _loadCountries() {
  _allCountries = CountryService.getAllCountries();
}
```

**Propósito**: Carga todos los países desde CountryService

**CountryService.getAllCountries()**:
- Método estático
- Probablemente retorna lista hardcoded o desde assets
- Sin async: Carga síncrona

### 4.5. Método _getCountryOptions (líneas 41-45)

**Tipo de retorno**: `List<SelectorOption<Country>>`
**Visibilidad**: Privado

**Propósito**: Transforma lista de países en opciones para HorizontalSelectorWidget

```dart
List<SelectorOption<Country>> _getCountryOptions() {
  return _allCountries.map((country) {
    return SelectorOption<Country>(
      value: country,
      displayText: '${country.flag} ${country.name}',
      isSelected: _selectedCountry?.code == country.code,
      isEnabled: true
    );
  }).toList();
}
```

**Lógica detallada**:

**Itera sobre _allCountries** con `.map()`

**Para cada país**, crea `SelectorOption<Country>`:

**value** (línea 43):
- El objeto Country completo

**displayText** (línea 43):
- `'${country.flag} ${country.name}'`
- **Formato**: "🇪🇸 España", "🇺🇸 United States"
- Flag emoji + espacio + nombre

**isSelected** (línea 43):
- `_selectedCountry?.code == country.code`
- Null-safe: Si _selectedCountry es null, retorna null (falsy)
- Compara por código de país

**isEnabled** (línea 43):
- true para todos
- Todos los países son seleccionables

**Nota**: subtitle no se proporciona (null)

### 4.6. Método _getTimezoneOptions (líneas 47-62)

**Tipo de retorno**: `List<SelectorOption<String>>`
**Visibilidad**: Privado

**Propósito**: Transforma zonas horarias del país seleccionado en opciones

```dart
List<SelectorOption<String>> _getTimezoneOptions() {
  if (_selectedCountry == null) return [];

  return _selectedCountry!.timezones.map((timezone) {
    String gmtOffset = '';
    try {
      gmtOffset = TimezoneService.getCurrentOffset(timezone);
    } catch (e) {
      gmtOffset = '';
    }

    String cityName = timezone.split('/').last.replaceAll('_', ' ');

    return SelectorOption<String>(
      value: timezone,
      displayText: cityName,
      subtitle: gmtOffset,
      isSelected: _selectedTimezone == timezone,
      isEnabled: true
    );
  }).toList();
}
```

**Lógica detallada**:

1. **Check de país seleccionado** (línea 48):
   ```dart
   if (_selectedCountry == null) return [];
   ```
   - Si no hay país: retorna lista vacía
   - **Efecto**: Selector de timezone no se muestra hasta que se selecciona país

2. **Itera sobre timezones del país** (línea 50):
   ```dart
   return _selectedCountry!.timezones.map((timezone) { ... })
   ```
   - `!` force unwrap: Seguro porque ya verificamos null
   - **timezone**: String con formato IANA (ej: "Europe/Madrid", "America/New_York")

3. **Calcular GMT offset** (líneas 51-56):
   ```dart
   String gmtOffset = '';
   try {
     gmtOffset = TimezoneService.getCurrentOffset(timezone);
   } catch (e) {
     gmtOffset = '';
   }
   ```

   **TimezoneService.getCurrentOffset(timezone)**:
   - Calcula offset actual considerando DST
   - **Ejemplo retorno**: "GMT+1", "GMT-5", "GMT+0"
   - Puede lanzar excepción si timezone inválido

   **Try-catch defensivo**:
   - Si falla: gmtOffset = '' (string vacío)
   - No crashea, muestra timezone sin offset

4. **Extraer nombre de ciudad** (línea 58):
   ```dart
   String cityName = timezone.split('/').last.replaceAll('_', ' ');
   ```

   **Transformación**:
   - `timezone.split('/')`: ["Europe", "Madrid"] o ["America", "New_York"]
   - `.last`: "Madrid" o "New_York"
   - `.replaceAll('_', ' ')`: "Madrid" o "New York"

   **Ejemplos**:
   - "Europe/Madrid" → "Madrid"
   - "America/New_York" → "New York"
   - "America/Argentina/Buenos_Aires" → "Buenos Aires"

5. **Crear SelectorOption** (líneas 60-61):
   ```dart
   return SelectorOption<String>(
     value: timezone,
     displayText: cityName,
     subtitle: gmtOffset,
     isSelected: _selectedTimezone == timezone,
     isEnabled: true
   );
   ```

   **value**: Timezone completo ("Europe/Madrid")
   **displayText**: Nombre de ciudad ("Madrid")
   **subtitle**: Offset GMT ("GMT+1")
   **isSelected**: Comparación de strings
   **isEnabled**: true

### 4.7. Método _onCountrySelected (líneas 64-70)

**Tipo de retorno**: void
**Visibilidad**: Privado
**Parámetros**: Country country

**Propósito**: Maneja selección de país y auto-selecciona timezone primario

```dart
void _onCountrySelected(Country country) {
  setState(() {
    _selectedCountry = country;
    _selectedTimezone = country.primaryTimezone;
  });
  widget.onChanged(country, country.primaryTimezone, null);
}
```

**Lógica**:

1. **setState** (líneas 65-68):
   - Actualiza _selectedCountry con el país seleccionado
   - Actualiza _selectedTimezone con primaryTimezone del país
   - **Auto-selección**: Selecciona automáticamente el timezone principal

2. **Notificar cambio** (línea 69):
   - Llama widget.onChanged con:
     - country: País seleccionado
     - timezone: primaryTimezone
     - city: null (no se determina aún)

**country.primaryTimezone**:
- Propiedad del modelo Country
- Timezone principal/capital del país
- Ejemplo: España → "Europe/Madrid"

### 4.8. Método _onTimezoneSelected (líneas 72-81)

**Tipo de retorno**: void
**Visibilidad**: Privado
**Parámetros**: String timezone

**Propósito**: Maneja selección de timezone específico y extrae nombre de ciudad

```dart
void _onTimezoneSelected(String timezone) {
  if (_selectedCountry != null) {
    String cityName = timezone.split('/').last.replaceAll('_', ' ');

    setState(() {
      _selectedTimezone = timezone;
    });
    widget.onChanged(_selectedCountry!, timezone, cityName);
  }
}
```

**Lógica**:

1. **Verificar país seleccionado** (línea 73):
   - Guard clause: Solo procede si hay país seleccionado
   - **Defensivo**: No debería ser null porque selector solo aparece con país

2. **Extraer nombre de ciudad** (línea 74):
   ```dart
   String cityName = timezone.split('/').last.replaceAll('_', ' ');
   ```
   - Misma lógica que en _getTimezoneOptions

3. **setState** (líneas 76-78):
   - Actualiza _selectedTimezone
   - **Solo timezone**: No cambia _selectedCountry

4. **Notificar cambio** (línea 79):
   - Llama widget.onChanged con:
     - country: _selectedCountry! (force unwrap seguro)
     - timezone: timezone seleccionado
     - city: cityName extraído

### 4.9. Método build (líneas 83-96)

**Tipo de retorno**: Widget
**Anotación**: @override

**Propósito**: Construye UI con dos selectores apilados verticalmente

```dart
@override
Widget build(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      HorizontalSelectorWidget<Country>(
        options: _getCountryOptions(),
        onSelected: _onCountrySelected,
        label: context.l10n.country,
        icon: Icons.flag,
        emptyMessage: context.l10n.noCountriesAvailable
      ),

      const SizedBox(height: 12),

      if (_selectedCountry != null) ...[
        HorizontalSelectorWidget<String>(
          options: _getTimezoneOptions(),
          onSelected: _onTimezoneSelected,
          label: context.l10n.cityOrTimezone,
          icon: Icons.location_city,
          emptyMessage: context.l10n.noTimezonesAvailable
        )
      ],
    ],
  );
}
```

**Estructura**:
```
Column (mainAxisSize.min, start)
├── HorizontalSelectorWidget<Country> (países)
├── SizedBox (12px spacing)
└── if (país seleccionado)
    └── HorizontalSelectorWidget<String> (timezones)
```

**Análisis detallado**:

1. **Column** (líneas 85-87):
   - **mainAxisSize.min**: Ocupa solo espacio necesario
   - **crossAxisAlignment.start**: Alinea hijos a la izquierda

2. **Selector de países** (líneas 89):
   ```dart
   HorizontalSelectorWidget<Country>(
     options: _getCountryOptions(),
     onSelected: _onCountrySelected,
     label: context.l10n.country,
     icon: Icons.flag,
     emptyMessage: context.l10n.noCountriesAvailable
   )
   ```

   **Tipo genérico**: Country
   **options**: Lista de SelectorOption<Country> con banderas
   **onSelected**: Callback _onCountrySelected
   **label**: Localizado "País" o "Country"
   **icon**: Icons.flag (bandera)
   **emptyMessage**: "No hay países disponibles" (no debería ocurrir)

3. **Spacing** (línea 91):
   ```dart
   const SizedBox(height: 12)
   ```
   - 12px de espacio vertical entre selectores

4. **Selector de timezones (condicional)** (líneas 93):
   ```dart
   if (_selectedCountry != null) ...[
     HorizontalSelectorWidget<String>(...)
   ]
   ```

   **Condicional**: Solo si hay país seleccionado
   **Spread operator** `...[]`: Inserta widget en children

   **HorizontalSelectorWidget<String>**:
   ```dart
   HorizontalSelectorWidget<String>(
     options: _getTimezoneOptions(),
     onSelected: _onTimezoneSelected,
     label: context.l10n.cityOrTimezone,
     icon: Icons.location_city,
     emptyMessage: context.l10n.noTimezonesAvailable
   )
   ```

   **Tipo genérico**: String (timezone IANA)
   **options**: Lista de SelectorOption<String> con ciudades y GMT offset
   **onSelected**: Callback _onTimezoneSelected
   **label**: "Ciudad o zona horaria"
   **icon**: Icons.location_city (edificios de ciudad)
   **emptyMessage**: "No hay zonas horarias disponibles"

## 5. COMPONENTES EXTERNOS

### HorizontalSelectorWidget (líneas 7, 89, 93)
**Archivo**: `horizontal_selector_widget.dart`
**Tipo genérico**: `<T>` (Country o String en este caso)
**Props utilizadas**:
- options: List<SelectorOption<T>>
- onSelected: Function(T)
- label: String
- icon: IconData
- emptyMessage: String

**Propósito**: Widget genérico de selector horizontal reutilizable

### CountryService (línea 5)
**Archivo**: `../services/country_service.dart`
**Método usado**: `getAllCountries()`
**Propósito**: Servicio para obtener lista de países

### TimezoneService (línea 6)
**Archivo**: `../services/timezone_service.dart`
**Método usado**: `getCurrentOffset(String timezone)`
**Propósito**: Calcula offset GMT actual de un timezone

## 6. MODELOS UTILIZADOS

### Country (línea 3)
**Archivo**: `../models/country.dart`
**Propiedades usadas**:
- `code`: String - Código ISO del país (ej: "ES", "US")
- `name`: String - Nombre del país
- `flag`: String - Emoji de bandera
- `timezones`: List<String> - Lista de timezones IANA
- `primaryTimezone`: String - Timezone principal/capital

### SelectorOption\<T\> (línea 4)
**Archivo**: `../models/selector_option.dart`
**Propiedades usadas**:
- `value`: T - Valor del option (Country o String)
- `displayText`: String - Texto a mostrar
- `subtitle`: String? - Texto secundario (GMT offset)
- `isSelected`: bool - Si está seleccionado
- `isEnabled`: bool - Si está habilitado

## 7. LOCALIZACIÓN

### Strings localizados usados:

**Para selector de países** (línea 89):
- `context.l10n.country`: "País" / "Country" / "País"
- `context.l10n.noCountriesAvailable`: "No hay países disponibles"

**Para selector de timezones** (línea 93):
- `context.l10n.cityOrTimezone`: "Ciudad o zona horaria" / "City or timezone"
- `context.l10n.noTimezonesAvailable`: "No hay zonas horarias disponibles"

## 8. FLUJO DE INTERACCIÓN

### 8.1. Flujo inicial

```
1. Widget se monta
   ↓
2. initState()
   - Asigna initialCountry y initialTimezone
   - Carga países con _loadCountries()
   ↓
3. build()
   - Muestra selector de países
   - Si hay initialCountry: muestra selector de timezones
```

### 8.2. Flujo de selección de país

```
1. Usuario toca país en selector
   ↓
2. HorizontalSelectorWidget llama onSelected con Country
   ↓
3. _onCountrySelected(country)
   - setState: _selectedCountry = country
   - setState: _selectedTimezone = country.primaryTimezone
   - widget.onChanged(country, primaryTimezone, null)
   ↓
4. Rebuild
   - Selector de países actualiza selección visual
   - Selector de timezones aparece (si estaba oculto)
   - Timezone primario seleccionado automáticamente
```

### 8.3. Flujo de selección de timezone

```
1. Usuario toca timezone en segundo selector
   ↓
2. HorizontalSelectorWidget llama onSelected con String
   ↓
3. _onTimezoneSelected(timezone)
   - Extrae cityName de timezone
   - setState: _selectedTimezone = timezone
   - widget.onChanged(_selectedCountry!, timezone, cityName)
   ↓
4. Rebuild
   - Selector de timezones actualiza selección visual
```

### 8.4. Ejemplo completo

```
// Usuario selecciona
1. Toca "🇪🇸 España" en selector de países
   → _selectedCountry = España
   → _selectedTimezone = "Europe/Madrid" (auto)
   → onChanged(España, "Europe/Madrid", null)
   → Aparece selector de timezones con: Madrid, Barcelona, Canarias

2. Toca "Barcelona" en selector de timezones
   → cityName = "Barcelona" (de "Europe/Barcelona")
   → _selectedTimezone = "Europe/Barcelona"
   → onChanged(España, "Europe/Barcelona", "Barcelona")
```

## 9. CARACTERÍSTICAS TÉCNICAS

### 9.1. Selector dual dependiente

**Pattern**: Segundo selector depende del primero

**Implementación**:
```dart
if (_selectedCountry != null) ...[
  // Mostrar selector de timezones
]
```

**Beneficio**: UX progresiva (primero país, luego timezone)

### 9.2. Auto-selección de timezone primario

**Comportamiento**: Al seleccionar país, auto-selecciona su timezone principal

**Motivo**:
- Evita estado intermedio sin timezone
- Siempre hay valor válido
- Usuario puede refinar después

### 9.3. Parsing de timezone IANA

**Format**: "Continente/Ciudad" o "Continente/Subcontinente/Ciudad"

**Parsing**:
```dart
timezone.split('/').last.replaceAll('_', ' ')
```

**Ejemplos**:
- "Europe/Madrid" → "Madrid"
- "America/New_York" → "New York"
- "America/Argentina/Buenos_Aires" → "Buenos Aires"
- "Pacific/Port_Moresby" → "Port Moresby"

**Limitación**: Solo toma última parte (puede perder contexto en casos ambiguos)

### 9.4. Try-catch defensivo para GMT offset

**Motivo**: `getCurrentOffset()` puede fallar con timezones inválidos

**Consecuencia del error**: Muestra timezone sin offset (degradación graceful)

**Alternativa más robusta**:
```dart
gmtOffset = TimezoneService.getCurrentOffset(timezone) ?? '';
```
(Si getCurrentOffset retornara null en lugar de lanzar)

### 9.5. Triple callback (country, timezone, city)

**Signature**:
```dart
Function(Country country, String timezone, String? city)
```

**Por qué 3 parámetros**:
- **Country**: Objeto completo con metadata
- **timezone**: String IANA para lógica de negocio
- **city**: String legible para UI

**Alternativa**:
```dart
Function(CountryTimezoneSelection selection)
```
Donde selection encapsula los 3

### 9.6. StatefulWidget para estado local

**Por qué no stateless con callbacks**:
- Necesita mantener _selectedCountry y _selectedTimezone
- Necesita cargar _allCountries
- Auto-selección de timezone requiere estado

**Sin estado**: Parent tendría que manejar todo (más complejo)

### 9.7. initialCity no usado

**Observación**: Se proporciona pero no se usa en initState

**Posible razón**: Preparación para feature futura

**Mejora potencial**:
```dart
if (widget.initialCity != null) {
  // Buscar timezone que contenga initialCity
  _selectedTimezone = findTimezoneByCity(initialCity);
}
```

## 10. CASOS DE USO

### 10.1. Selección de timezone para evento

```dart
TimezoneHorizontalSelector(
  initialCountry: userCountry,
  initialTimezone: userTimezone,
  onChanged: (country, timezone, city) {
    setState(() {
      event.country = country;
      event.timezone = timezone;
      event.city = city;
    });
  },
)
```

### 10.2. Selector sin inicialización

```dart
TimezoneHorizontalSelector(
  // Sin initial values
  onChanged: (country, timezone, city) {
    print('Selected: ${country.name} - $city ($timezone)');
  },
)
```

**Comportamiento**:
- Muestra solo selector de países
- Al seleccionar país: aparece selector de timezones con primario seleccionado

### 10.3. En formulario de perfil

```dart
Column(
  children: [
    Text('Zona horaria'),
    TimezoneHorizontalSelector(
      initialCountry: user.country,
      initialTimezone: user.timezone,
      onChanged: (country, timezone, city) {
        updateUserProfile(
          countryCode: country.code,
          timezone: timezone,
        );
      },
    ),
  ],
)
```

### 10.4. Multi-step wizard

```dart
// Step 1: Select country
// Step 2: Select timezone
// Pero usando un solo widget:
TimezoneHorizontalSelector(
  onChanged: (country, timezone, city) {
    // Progresa al siguiente step automáticamente
    if (currentStep == 1) {
      moveToNextStep();
    }
  },
)
```

## 11. TESTING

### 11.1. Test de inicialización

```dart
testWidgets('initializes with provided values', (tester) async {
  final country = Country(code: 'ES', name: 'España');
  final timezone = 'Europe/Madrid';

  await tester.pumpWidget(
    MaterialApp(
      home: TimezoneHorizontalSelector(
        initialCountry: country,
        initialTimezone: timezone,
        onChanged: (c, t, city) {},
      ),
    ),
  );

  // Verificar que muestra país seleccionado
  expect(find.textContaining('España'), findsOneWidget);
});
```

### 11.2. Test de selección de país

```dart
testWidgets('shows timezone selector after country selection', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TimezoneHorizontalSelector(
        onChanged: (c, t, city) {},
      ),
    ),
  );

  // Inicialmente solo muestra selector de países
  expect(find.byType(HorizontalSelectorWidget), findsOneWidget);

  // Simular selección de país
  // (necesita interacción con HorizontalSelectorWidget)

  await tester.pump();

  // Después de selección: debe mostrar 2 selectores
  expect(find.byType(HorizontalSelectorWidget), findsNWidgets(2));
});
```

### 11.3. Test de callback

```dart
testWidgets('calls onChanged with correct values', (tester) async {
  Country? selectedCountry;
  String? selectedTimezone;
  String? selectedCity;

  await tester.pumpWidget(
    MaterialApp(
      home: TimezoneHorizontalSelector(
        onChanged: (c, t, city) {
          selectedCountry = c;
          selectedTimezone = t;
          selectedCity = city;
        },
      ),
    ),
  );

  // Simular selección
  // ...

  expect(selectedCountry?.code, 'ES');
  expect(selectedTimezone, 'Europe/Madrid');
  expect(selectedCity, 'Madrid');
});
```

### 11.4. Test de parsing de timezone

```dart
test('correctly parses timezone to city name', () {
  final state = _TimezoneHorizontalSelectorState();

  // Simular método privado (o hacerlo público para testing)
  final city1 = 'Europe/Madrid'.split('/').last.replaceAll('_', ' ');
  expect(city1, 'Madrid');

  final city2 = 'America/New_York'.split('/').last.replaceAll('_', ' ');
  expect(city2, 'New York');

  final city3 = 'America/Argentina/Buenos_Aires'.split('/').last.replaceAll('_', ' ');
  expect(city3, 'Buenos Aires');
});
```

## 12. POSIBLES MEJORAS (NO implementadas)

### 12.1. Búsqueda de países

```dart
TextField(
  onChanged: (query) {
    setState(() {
      _filteredCountries = _allCountries
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    });
  },
)
```

### 12.2. Usar initialCity

```dart
@override
void initState() {
  super.initState();
  _selectedCountry = widget.initialCountry;

  if (widget.initialCity != null) {
    _selectedTimezone = _findTimezoneByCity(widget.initialCity!);
  } else {
    _selectedTimezone = widget.initialTimezone;
  }

  _loadCountries();
}
```

### 12.3. Detectar timezone automáticamente

```dart
void _autoDetectTimezone() async {
  final deviceTimezone = await TimezoneService.getDeviceTimezone();
  final country = CountryService.findByTimezone(deviceTimezone);

  if (country != null) {
    _onCountrySelected(country);
    _onTimezoneSelected(deviceTimezone);
  }
}
```

### 12.4. Mostrar DST info

```dart
// En subtitle del timezone option
subtitle: '$gmtOffset ${isDST ? "(DST activo)" : ""}'
```

### 12.5. Popular timezones first

```dart
List<SelectorOption<String>> _getTimezoneOptions() {
  var options = _selectedCountry!.timezones.map(...).toList();

  // Ordenar: primero capital/popular, luego alfabético
  options.sort((a, b) {
    if (a.value == _selectedCountry!.primaryTimezone) return -1;
    if (b.value == _selectedCountry!.primaryTimezone) return 1;
    return a.displayText.compareTo(b.displayText);
  });

  return options;
}
```

## 13. RESUMEN

**Propósito**: Selector dual de país y zona horaria con UI progresiva

**Características clave**:
- Selector de países con banderas
- Selector de timezones con GMT offset (aparece después de seleccionar país)
- Auto-selección de timezone primario al seleccionar país
- Parsing de timezone IANA a nombre de ciudad legible
- Try-catch defensivo para cálculo de GMT offset
- Triple callback (Country, timezone, city)

**Flujo**:
1. Muestra países
2. Usuario selecciona país → auto-selecciona timezone primario
3. Aparece selector de timezones del país
4. Usuario puede refinar selección de timezone

**Uso**: Formularios de eventos, configuración de perfil, cualquier feature que necesite timezone

**Componentes reutilizables**: HorizontalSelectorWidget (base genérica)

---

**Fin de la documentación de timezone_horizontal_selector.dart**
