# SubscriptionCard - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/subscription_card.dart`
**Líneas**: 146
**Tipo**: ConsumerWidget (Riverpod)
**Propósito**: Card interactiva para mostrar usuarios/calendarios suscritos con avatar de iniciales, estadísticas (nuevos eventos, total, suscriptores), y acción de eliminar opcional

## 2. CLASE Y PROPIEDADES

### SubscriptionCard (líneas 9-145)
Widget que extiende `ConsumerWidget` para acceso a Riverpod providers

**Propiedades**:
- `user` (User, required, línea 10): Usuario/calendario suscrito
- `onTap` (VoidCallback, required, línea 11): Callback al tocar la card
- `onDelete` (VoidCallback?, línea 12): Callback opcional para eliminar suscripción
- `customAvatar` (Widget?, línea 13): Avatar personalizado (override del avatar de iniciales)
- `customTitle` (String?, línea 14): Título personalizado (override de user.displayName)
- `customSubtitle` (String?, línea 15): Subtítulo personalizado (override de estadísticas)

## 3. CONSTRUCTOR (línea 17)

```dart
const SubscriptionCard({
  super.key,
  required this.user,
  required this.onTap,
  this.onDelete,
  this.customAvatar,
  this.customTitle,
  this.customSubtitle
})
```

**Tipo**: Constructor const
**Required**: user, onTap
**Optional**: onDelete, customAvatar, customTitle, customSubtitle

## 4. MÉTODO BUILD (líneas 19-69)

### build(BuildContext context, WidgetRef ref) (líneas 20-69)

**Tipo de retorno**: Widget
**Parámetros**: BuildContext context, WidgetRef ref (de ConsumerWidget)
**Anotación**: @override

**Estructura del widget tree**:
```
GestureDetector (onTap)
└── Container (padding 10, decoration custom)
    └── Row
        ├── _buildAvatar() (65x65 con iniciales)
        ├── SizedBox (width 12)
        ├── Expanded
        │   └── Column
        │       ├── Text (title)
        │       ├── SizedBox (height 4)
        │       └── Text (subtitle con estadísticas)
        ├── SizedBox (width 8)
        └── _buildTrailingActions() (delete button o chevron)
```

**Lógica detallada**:

1. **Obtener localizaciones** (línea 21):
   ```dart
   final l10n = context.l10n;
   ```
   - Necesario para _buildDefaultSubtitle()

2. **GestureDetector** (líneas 23-24):
   ```dart
   return GestureDetector(
     onTap: onTap,
     ...
   )
   ```
   - Toda la card es tappable
   - No usa key derivada (diferente de ContactCard/SelectableCard)

3. **Container con decoración personalizada** (líneas 25-31):
   ```dart
   child: Container(
     padding: const EdgeInsets.all(10),
     decoration: BoxDecoration(
       color: AppStyles.colorWithOpacity(AppStyles.white, 1.0),
       borderRadius: BorderRadius.circular(12),
       boxShadow: [
         BoxShadow(
           color: AppStyles.colorWithOpacity(AppStyles.black87, 0.03),
           blurRadius: 6,
           offset: const Offset(0, 2)
         )
       ],
     ),
     ...
   )
   ```

   **Detalles de la decoración**:

   **padding** (línea 26):
   - EdgeInsets.all(10)
   - Más compacto que ContactCard (12) y SelectableCard (12)

   **color** (línea 28):
   - `AppStyles.colorWithOpacity(AppStyles.white, 1.0)`
   - Blanco con 100% opacidad (equivalente a AppStyles.white)
   - Uso de colorWithOpacity para consistencia de API

   **borderRadius** (línea 29):
   - BorderRadius.circular(12)
   - Esquinas redondeadas estándar

   **boxShadow** (línea 30):
   - Color: `AppStyles.colorWithOpacity(AppStyles.black87, 0.03)` (negro con 3% opacidad)
   - blurRadius: 6 (sombra difusa)
   - offset: Offset(0, 2) (sombra hacia abajo)
   - **Sombra muy sutil**: 3% es apenas perceptible

   **Nota**: No usa `AppStyles.cardDecoration` como otros cards, define su propia decoración

4. **Row principal** (líneas 32-33):
   ```dart
   child: Row(
     crossAxisAlignment: CrossAxisAlignment.center,
     children: [...]
   )
   ```
   - Centra verticalmente todos los elementos

5. **Avatar** (línea 36):
   ```dart
   _buildAvatar(),
   ```
   - Método privado que construye avatar de iniciales o usa customAvatar

6. **Textos** (líneas 40-59):

   **Column con Expanded** (líneas 40-42):
   ```dart
   Expanded(
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [...]
     ),
   )
   ```

   a) **Text del título** (líneas 44-49):
      ```dart
      Text(
        customTitle ?? user.displayName,
        style: AppStyles.cardTitle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      )
      ```

      **text** (línea 45):
      - `customTitle ?? user.displayName`
      - Prioriza customTitle si existe
      - Fallback a displayName del usuario

      **style** (líneas 46):
      - Base: AppStyles.cardTitle
      - fontSize: 16
      - fontWeight: FontWeight.w600 (semi-bold)

      **maxLines**: 1 (solo 1 línea, más compacto)

   b) **Text del subtítulo** (líneas 51-56):
      ```dart
      Text(
        customSubtitle ?? _buildDefaultSubtitle(l10n),
        style: AppStyles.cardSubtitle.copyWith(
          fontSize: 13,
          color: AppStyles.grey600
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      )
      ```

      **text** (línea 52):
      - `customSubtitle ?? _buildDefaultSubtitle(l10n)`
      - Prioriza customSubtitle si existe
      - Genera estadísticas por defecto

      **style** (líneas 53):
      - Base: AppStyles.cardSubtitle
      - fontSize: 13
      - color: AppStyles.grey600

      **maxLines**: 1

7. **Trailing actions** (línea 64):
   ```dart
   _buildTrailingActions(context),
   ```
   - Botón de delete o chevron según si onDelete existe

## 5. MÉTODO _buildAvatar (líneas 71-106)

**Tipo de retorno**: Widget
**Visibilidad**: Privado

**Propósito**: Construye avatar con iniciales o retorna customAvatar si existe

### Lógica detallada:

1. **Check de customAvatar** (líneas 72-74):
   ```dart
   if (customAvatar != null) {
     return customAvatar!;
   }
   ```
   - Si hay customAvatar: retorna ese widget directamente
   - Permite override completo del avatar

2. **Cálculo de iniciales** (líneas 77-89):

   **Variable inicial** (línea 77):
   ```dart
   String initials = '?';
   ```
   - Default: '?' si no se puede determinar iniciales

   **Prioridad 1: fullName** (líneas 78-84):
   ```dart
   if (user.fullName?.isNotEmpty == true) {
     final nameParts = user.fullName!.trim().split(' ');
     if (nameParts.length >= 2) {
       initials = nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
     } else {
       initials = nameParts[0][0].toUpperCase();
     }
   }
   ```

   **Si fullName existe y no está vacío**:
   - Trim y split por espacio
   - **Si hay 2+ partes**: Primera letra de las 2 primeras palabras (ej: "John Doe" → "JD")
   - **Si hay 1 parte**: Primera letra (ej: "John" → "J")
   - Uppercase forzado

   **Prioridad 2: instagramName** (líneas 85-86):
   ```dart
   else if (user.instagramName?.isNotEmpty == true) {
     initials = user.instagramName![0].toUpperCase();
   }
   ```
   - Si fullName no existe pero instagramName sí: primera letra del username
   - Ejemplo: "@johndoe" → "J"

   **Prioridad 3: user.id** (líneas 87-89):
   ```dart
   else if (user.id > 0) {
     initials = user.id.toString()[0];
   }
   ```
   - Si no hay nombre ni instagram: primera cifra del ID
   - Ejemplo: id 123 → "1"
   - **Fallback numérico**: Siempre habrá algo (excepto si id ≤ 0)

   **Orden de prioridad**: fullName > instagramName > id > '?'

3. **Container del avatar** (líneas 91-105):
   ```dart
   return Container(
     width: 65,
     height: 65,
     decoration: BoxDecoration(
       color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.1),
       borderRadius: BorderRadius.circular(12),
       border: Border.all(
         color: AppStyles.colorWithOpacity(AppStyles.blue600, 0.3),
         width: 1.5
       ),
     ),
     child: Center(
       child: Text(
         initials,
         style: AppStyles.cardTitle.copyWith(
           fontSize: 18,
           fontWeight: FontWeight.bold,
           color: AppStyles.blue600,
           letterSpacing: 0.5
         ),
       ),
     ),
   );
   ```

   **Dimensiones**:
   - width: 65px
   - height: 65px
   - Cuadrado con esquinas redondeadas

   **Decoración**:
   - **color** (línea 95): blue600 con 10% opacidad (fondo azul muy claro)
   - **borderRadius** (línea 96): 12px (esquinas redondeadas)
   - **border** (líneas 97):
     - color: blue600 con 30% opacidad (borde azul claro)
     - width: 1.5px (ligeramente más grueso que 1px)

   **Texto de iniciales**:
   - **fontSize**: 18
   - **fontWeight**: FontWeight.bold
   - **color**: AppStyles.blue600 (azul sólido 100%)
   - **letterSpacing**: 0.5 (espacio entre letras para legibilidad)
   - **Center**: Centrado horizontal y verticalmente

   **Esquema de color**:
   - Fondo: azul 10%
   - Borde: azul 30%
   - Texto: azul 100%
   - **Consistente con UserGroupAvatar**

## 6. MÉTODO _buildDefaultSubtitle (líneas 108-121)

**Tipo de retorno**: String
**Visibilidad**: Privado
**Parámetros**: AppLocalizations l10n

**Propósito**: Genera subtítulo con estadísticas de eventos y suscriptores

### Lógica detallada:

1. **Verificar que existan todas las propiedades** (línea 109):
   ```dart
   if (user.newEventsCount != null &&
       user.totalEventsCount != null &&
       user.subscribersCount != null) {
   ```
   - Requiere las 3 propiedades
   - Si falta alguna: retorna fallback

2. **Extraer valores** (líneas 110-112):
   ```dart
   final newEvents = user.newEventsCount!;
   final totalEvents = user.totalEventsCount!;
   final subscribers = user.subscribersCount!;
   ```
   - Variables locales para legibilidad

3. **Caso: Hay nuevos eventos** (líneas 114-115):
   ```dart
   if (newEvents > 0) {
     return '$newEvents ${newEvents == 1 ? l10n.newEvent : l10n.newEvents} · $totalEvents total · $subscribers ${subscribers == 1 ? l10n.subscriber : l10n.subscribers}';
   }
   ```

   **Formato**: `X nuevo(s) evento(s) · Y total · Z suscriptor(es)`

   **Pluralización**:
   - newEvents == 1 → l10n.newEvent (singular)
   - newEvents != 1 → l10n.newEvents (plural)
   - subscribers == 1 → l10n.subscriber (singular)
   - subscribers != 1 → l10n.subscribers (plural)

   **Separador**: `·` (middle dot) para separar secciones

   **Ejemplo**: "3 nuevos eventos · 45 total · 120 suscriptores"

4. **Caso: No hay nuevos eventos** (líneas 116-118):
   ```dart
   else {
     return '$totalEvents ${totalEvents == 1 ? l10n.event : l10n.events} · $subscribers ${subscribers == 1 ? l10n.subscriber : l10n.subscribers}';
   }
   ```

   **Formato**: `X evento(s) · Y suscriptor(es)`

   **Diferencia**: No menciona "nuevos", solo total

   **Ejemplo**: "45 eventos · 120 suscriptores"

5. **Fallback si faltan propiedades** (línea 120):
   ```dart
   return l10n.publicUser;
   ```
   - Si alguna de las 3 propiedades es null
   - Retorna texto localizado "Usuario público"

## 7. MÉTODO _buildTrailingActions (líneas 123-144)

**Tipo de retorno**: Widget
**Visibilidad**: Privado
**Parámetros**: BuildContext context

**Propósito**: Construye botón de delete o chevron según disponibilidad de onDelete

### Estructura:

```dart
return Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    if (onDelete != null)
      // Botón de delete circular
    if (onDelete == null)
      // Chevron de navegación
  ],
);
```

**mainAxisSize.min**: Row ocupa solo el espacio necesario

### Caso 1: onDelete existe (líneas 127-140)

```dart
if (onDelete != null)
  GestureDetector(
    onTap: onDelete,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(AppStyles.red600, 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppStyles.colorWithOpacity(AppStyles.red600, 0.25),
          width: 1
        ),
      ),
      child: Center(
        child: PlatformWidgets.platformIcon(
          CupertinoIcons.delete,
          color: AppStyles.red600,
          size: 16
        )
      ),
    ),
  )
```

**GestureDetector** (líneas 128-129):
- onTap: onDelete callback
- Área tappable: todo el container circular

**Container circular** (líneas 130-132):
- width: 32px
- height: 32px
- Tamaño compacto para trailing action

**Decoración** (líneas 133-137):
- **color** (línea 134): red600 con 10% opacidad (fondo rojo muy claro)
- **shape** (línea 135): BoxShape.circle (círculo perfecto)
- **border** (líneas 136):
  - color: red600 con 25% opacidad (borde rojo claro)
  - width: 1px

**Icono delete** (líneas 138-139):
- CupertinoIcons.delete (icono de papelera)
- color: AppStyles.red600 (rojo sólido)
- size: 16px

**Esquema de color**:
- Fondo: rojo 10% (muy sutil)
- Borde: rojo 25% (claro)
- Icono: rojo 100% (prominente)
- **Indica acción destructiva**

### Caso 2: onDelete es null (línea 141)

```dart
if (onDelete == null)
  PlatformWidgets.platformIcon(
    CupertinoIcons.chevron_right,
    color: AppStyles.grey400,
    size: 20
  )
```

**Chevron simple**:
- CupertinoIcons.chevron_right (→)
- color: AppStyles.grey400 (gris claro, no prominente)
- size: 20px
- **No es interactivo**: No tiene GestureDetector
- **Indicador visual**: Sugiere que la card es tappable

**Condicional exclusivo**:
- Solo uno se muestra (delete button XOR chevron)
- Si onDelete existe → delete button
- Si onDelete es null → chevron

## 8. COMPONENTES EXTERNOS

### PlatformWidgets.platformIcon
**Usado en**:
- línea 138: Icono delete
- línea 141: Chevron

**Propósito**: Renderiza icono adaptativo según plataforma

### AppStyles
**Colores usados**:
- white: Fondo de card
- black87: Base para sombra
- blue600: Avatar (fondo, borde, texto)
- red600: Delete button (fondo, borde, icono)
- grey400: Chevron
- grey600: Subtítulo

**Estilos de texto**:
- cardTitle: Título
- cardSubtitle: Subtítulo

**Helpers**:
- colorWithOpacity(Color, double): Aplica opacidad

## 9. MODELOS UTILIZADOS

### User (línea 3)
**Propiedades usadas**:
- `displayName`: String - Nombre a mostrar
- `fullName`: String? - Nombre completo para iniciales
- `instagramName`: String? - Username de Instagram (fallback para iniciales)
- `id`: int - ID numérico (último fallback para iniciales)
- `newEventsCount`: int? - Cantidad de eventos nuevos
- `totalEventsCount`: int? - Total de eventos
- `subscribersCount`: int? - Cantidad de suscriptores

## 10. LOCALIZACIÓN

### Strings localizados:

**Para eventos** (línea 115, 117):
- `l10n.newEvent`: Singular "nuevo evento"
- `l10n.newEvents`: Plural "nuevos eventos"
- `l10n.event`: Singular "evento"
- `l10n.events`: Plural "eventos"

**Para suscriptores** (línea 115, 117):
- `l10n.subscriber`: Singular "suscriptor"
- `l10n.subscribers`: Plural "suscriptores"

**Fallback** (línea 120):
- `l10n.publicUser`: "Usuario público"

## 11. CARACTERÍSTICAS TÉCNICAS

### 11.1. ConsumerWidget (Riverpod)

**Diferencia con StatelessWidget**:
```dart
class SubscriptionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Acceso a ref
  }
}
```

**Beneficio**: Acceso a providers de Riverpod (aunque no usado en este widget actualmente)

**Nota**: El widget no usa ref en el build actual, podría ser StatelessWidget

### 11.2. Decoración custom vs AppStyles.cardDecoration

**Diferencia con otros cards**:
- ContactCard, SelectableCard: Usan `AppStyles.cardDecoration`
- SubscriptionCard: Define su propia decoración inline

**Motivo posible**: Sombra más sutil (3% vs probablemente 10% en cardDecoration)

### 11.3. Prioridad de iniciales

**Orden de fallback**: fullName → instagramName → id → '?'

**Diseño defensivo**: Siempre muestra algo, nunca crashea

### 11.4. Pluralización localizada

**Pattern**:
```dart
${count} ${count == 1 ? l10n.singular : l10n.plural}
```

**Correcto para español/inglés**: Estos idiomas tienen pluralización simple (1 vs resto)

**Limitación**: Idiomas con pluralización compleja (ruso, árabe) necesitan lógica más sofisticada

### 11.5. Middle dot separator

**Separador**: `·` (U+00B7, middle dot)

**Alternativas**:
- `•` (U+2022, bullet)
- `|` (pipe)
- `-` (guión)

**Motivo**: Middle dot es sutil, visual clean

### 11.6. Tamaño de avatar: 65x65

**Comparación**:
- UserGroupAvatar: 48x48
- ContactCard UserAvatar: 65px diameter (radius 32.5)
- SubscriptionCard: 65x65

**Consistencia**: Mismo tamaño que ContactCard, más grande que UserGroupAvatar

### 11.7. MaxLines: 1

**Compacidad**: Solo 1 línea para título y subtítulo

**Trade-off**: Menos información visible vs más cards en pantalla

### 11.8. Condicional exclusivo en trailing

**Pattern**: `if (X) A` + `if (!X) B` dentro de children list

**Alternativa más idiomática**:
```dart
trailing: onDelete != null
  ? DeleteButton(onDelete: onDelete)
  : ChevronIcon()
```

**Ventaja del pattern actual**: Manejo inline, menos widgets

## 12. CASOS DE USO

### 12.1. Suscripción con estadísticas completas

```dart
SubscriptionCard(
  user: User(
    id: 1,
    displayName: 'Eventos Barcelona',
    fullName: 'Eventos Barcelona',
    newEventsCount: 3,
    totalEventsCount: 45,
    subscribersCount: 120,
  ),
  onTap: () => navigateToSubscriptionDetail(),
  onDelete: () => unsubscribe(),
)
```

**Subtítulo**: "3 nuevos eventos · 45 total · 120 suscriptores"
**Trailing**: Botón delete circular rojo

### 12.2. Suscripción sin eventos nuevos

```dart
SubscriptionCard(
  user: User(
    displayName: 'Deportes',
    fullName: 'Club Deportes',
    newEventsCount: 0,
    totalEventsCount: 20,
    subscribersCount: 50,
  ),
  onTap: () {},
  onDelete: () {},
)
```

**Subtítulo**: "20 eventos · 50 suscriptores"
**Trailing**: Botón delete

### 12.3. Sin onDelete (solo visualización)

```dart
SubscriptionCard(
  user: user,
  onTap: () => viewDetails(),
  onDelete: null, // No se puede eliminar
)
```

**Trailing**: Chevron gris (no botón delete)

### 12.4. Con custom avatar

```dart
SubscriptionCard(
  user: user,
  onTap: () {},
  customAvatar: CachedNetworkImage(
    imageUrl: user.profilePicture,
    width: 65,
    height: 65,
  ),
)
```

**Avatar**: Imagen de red en lugar de iniciales

### 12.5. Con custom title y subtitle

```dart
SubscriptionCard(
  user: user,
  onTap: () {},
  customTitle: 'Mi Calendario Favorito',
  customSubtitle: 'Actualizado hace 2 horas',
)
```

**Override completo**: Ignora displayName y estadísticas

### 12.6. Usuario sin datos de estadísticas

```dart
SubscriptionCard(
  user: User(
    displayName: 'Usuario',
    fullName: 'Usuario Test',
    newEventsCount: null,
    totalEventsCount: null,
    subscribersCount: null,
  ),
  onTap: () {},
)
```

**Subtítulo**: "Usuario público" (fallback)

### 12.7. Usuario sin nombre (fallbacks)

```dart
// Solo instagramName
SubscriptionCard(
  user: User(
    id: 123,
    fullName: null,
    instagramName: '@johndoe',
  ),
  onTap: () {},
)
// Iniciales: "J"

// Solo ID
SubscriptionCard(
  user: User(
    id: 456,
    fullName: null,
    instagramName: null,
  ),
  onTap: () {},
)
// Iniciales: "4"

// Sin nada (id <= 0)
SubscriptionCard(
  user: User(
    id: 0,
    fullName: null,
    instagramName: null,
  ),
  onTap: () {},
)
// Iniciales: "?"
```

## 13. TESTING

### 13.1. Test de iniciales

```dart
group('Avatar initials', () {
  testWidgets('shows initials from fullName', (tester) async {
    await tester.pumpWidget(
      SubscriptionCard(
        user: User(fullName: 'John Doe'),
        onTap: () {},
      ),
    );

    expect(find.text('JD'), findsOneWidget);
  });

  testWidgets('shows single initial for single name', (tester) async {
    await tester.pumpWidget(
      SubscriptionCard(
        user: User(fullName: 'John'),
        onTap: () {},
      ),
    );

    expect(find.text('J'), findsOneWidget);
  });

  testWidgets('falls back to instagramName', (tester) async {
    await tester.pumpWidget(
      SubscriptionCard(
        user: User(instagramName: '@johndoe'),
        onTap: () {},
      ),
    );

    expect(find.text('J'), findsOneWidget);
  });

  testWidgets('falls back to id first digit', (tester) async {
    await tester.pumpWidget(
      SubscriptionCard(
        user: User(id: 123),
        onTap: () {},
      ),
    );

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('shows ? when no data', (tester) async {
    await tester.pumpWidget(
      SubscriptionCard(
        user: User(id: 0),
        onTap: () {},
      ),
    );

    expect(find.text('?'), findsOneWidget);
  });
});
```

### 13.2. Test de subtítulos

```dart
group('Subtitle generation', () {
  testWidgets('shows new events when present', (tester) async {
    await tester.pumpWidget(
      SubscriptionCard(
        user: User(
          newEventsCount: 3,
          totalEventsCount: 45,
          subscribersCount: 120,
        ),
        onTap: () {},
      ),
    );

    expect(
      find.textContaining('3 nuevos eventos'),
      findsOneWidget,
    );
    expect(find.textContaining('45 total'), findsOneWidget);
    expect(find.textContaining('120 suscriptores'), findsOneWidget);
  });

  testWidgets('hides new events when zero', (tester) async {
    await tester.pumpWidget(
      SubscriptionCard(
        user: User(
          newEventsCount: 0,
          totalEventsCount: 20,
          subscribersCount: 50,
        ),
        onTap: () {},
      ),
    );

    expect(find.textContaining('nuevos eventos'), findsNothing);
    expect(find.textContaining('20 eventos'), findsOneWidget);
  });

  testWidgets('shows fallback when stats missing', (tester) async {
    await tester.pumpWidget(
      SubscriptionCard(
        user: User(
          newEventsCount: null,
          totalEventsCount: null,
          subscribersCount: null,
        ),
        onTap: () {},
      ),
    );

    expect(find.text('Usuario público'), findsOneWidget);
  });

  testWidgets('uses singular forms correctly', (tester) async {
    await tester.pumpWidget(
      SubscriptionCard(
        user: User(
          newEventsCount: 1,
          totalEventsCount: 1,
          subscribersCount: 1,
        ),
        onTap: () {},
      ),
    );

    // Debe usar singular
    expect(find.textContaining('nuevo evento'), findsOneWidget);
    expect(find.textContaining('suscriptor'), findsOneWidget);
  });
});
```

### 13.3. Test de trailing actions

```dart
group('Trailing actions', () {
  testWidgets('shows delete button when onDelete provided', (tester) async {
    bool deleted = false;

    await tester.pumpWidget(
      SubscriptionCard(
        user: testUser,
        onTap: () {},
        onDelete: () => deleted = true,
      ),
    );

    expect(find.byIcon(CupertinoIcons.delete), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.chevron_right), findsNothing);

    await tester.tap(find.byIcon(CupertinoIcons.delete));
    expect(deleted, true);
  });

  testWidgets('shows chevron when onDelete null', (tester) async {
    await tester.pumpWidget(
      SubscriptionCard(
        user: testUser,
        onTap: () {},
        onDelete: null,
      ),
    );

    expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.delete), findsNothing);
  });
});
```

### 13.4. Test de custom props

```dart
testWidgets('uses custom avatar when provided', (tester) async {
  await tester.pumpWidget(
    SubscriptionCard(
      user: testUser,
      onTap: () {},
      customAvatar: Icon(Icons.star, key: Key('custom')),
    ),
  );

  expect(find.byKey(Key('custom')), findsOneWidget);
  expect(find.text('JD'), findsNothing); // No iniciales
});

testWidgets('uses custom title and subtitle', (tester) async {
  await tester.pumpWidget(
    SubscriptionCard(
      user: User(displayName: 'Original'),
      onTap: () {},
      customTitle: 'Custom Title',
      customSubtitle: 'Custom Subtitle',
    ),
  );

  expect(find.text('Custom Title'), findsOneWidget);
  expect(find.text('Custom Subtitle'), findsOneWidget);
  expect(find.text('Original'), findsNothing);
});
```

## 14. POSIBLES MEJORAS (NO implementadas)

### 14.1. Avatar con foto de perfil

```dart
Widget _buildAvatar() {
  if (customAvatar != null) return customAvatar!;

  if (user.profilePicture?.isNotEmpty == true) {
    return CachedNetworkImage(
      imageUrl: user.profilePicture!,
      width: 65,
      height: 65,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
      ),
      placeholder: _buildInitialsAvatar(),
      errorWidget: _buildInitialsAvatar(),
    );
  }

  return _buildInitialsAvatar();
}
```

### 14.2. Confirmación antes de delete

```dart
_buildTrailingActions() {
  if (onDelete != null) {
    return ConfirmationActionWidget(
      dialogTitle: l10n.unsubscribe,
      dialogMessage: l10n.confirmUnsubscribe,
      actionText: l10n.unsubscribe,
      isDestructive: true,
      onAction: onDelete!,
      child: // ... delete button
    );
  }
}
```

### 14.3. Badge de "Nuevo"

```dart
if (user.isNew) {
  return Badge(
    label: Text('NUEVO'),
    child: cardContent,
  );
}
```

### 14.4. Loading state durante delete

```dart
bool _isDeleting = false;

_buildTrailingActions() {
  if (_isDeleting) {
    return SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
  // ... delete button normal
}
```

### 14.5. Swipe to delete

```dart
return Dismissible(
  key: Key('subscription_${user.id}'),
  direction: DismissDirection.endToStart,
  background: Container(color: Colors.red),
  onDismissed: onDelete != null ? (_) => onDelete!() : null,
  child: cardContent,
);
```

## 15. RESUMEN

**Propósito**: Card para mostrar suscripciones con avatar de iniciales, estadísticas de eventos/suscriptores y opción de eliminar

**Características clave**:
- Avatar con iniciales (fallbacks: fullName → instagramName → id → '?')
- Subtítulo con estadísticas pluralizadas y localizadas
- Delete button circular rojo o chevron según onDelete
- Custom props para avatar, title y subtitle
- Decoración custom con sombra muy sutil (3%)
- ConsumerWidget para acceso a Riverpod (no usado actualmente)

**Layout**: Avatar 65x65 + Textos (title + subtitle) + Delete button o chevron

**Diferencias con otros cards**:
- ContactCard: Foto/iniciales de usuario real, chevron siempre
- SelectableCard: Icono coloreable, checkbox para selección
- SubscriptionCard: Iniciales con fallbacks múltiples, delete button opcional

**Uso**: Lista de suscripciones a calendarios públicos o usuarios

---

**Fin de la documentación de subscription_card.dart**
