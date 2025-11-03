# ContactCard - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/contact_card.dart`
**Líneas**: 63
**Tipo**: StatelessWidget
**Propósito**: Card interactiva que muestra información de un contacto/usuario con avatar, nombre, subtítulo y chevron de navegación, con margin adaptativo según plataforma

## 2. CLASE Y PROPIEDADES

### ContactCard (líneas 9-62)
Widget que extiende `StatelessWidget` para mostrar un contacto en formato card

**Propiedades**:
- `contact` (User, required, línea 10): Usuario/contacto a mostrar
- `onTap` (VoidCallback, required, línea 11): Callback ejecutado cuando se toca la card

## 3. CONSTRUCTOR

### ContactCard (línea 13)
```dart
const ContactCard({
  super.key,
  required this.contact,
  required this.onTap
})
```

**Tipo**: Constructor const

**Parámetros**:
- `super.key`: Key? (opcional)
- `contact`: User (required)
- `onTap`: VoidCallback (required)

**Uso típico**:
```dart
ContactCard(
  contact: userContact,
  onTap: () => Navigator.push(
    context,
    ContactDetailScreen(contact: userContact),
  ),
)
```

## 4. MÉTODO BUILD

### build(BuildContext context) (líneas 15-61)
**Tipo de retorno**: Widget
**Anotación**: @override

**Propósito**: Construye la card del contacto con layout horizontal (avatar + información + chevron)

**Estructura del widget tree**:
```
Container (margin + decoration)
└── GestureDetector (onTap)
    └── Padding (12px)
        └── Row
            ├── UserAvatar (radius 32.5)
            ├── SizedBox (width 12)
            ├── Expanded
            │   └── Column
            │       ├── Text (displayName)
            │       ├── SizedBox (height 4)
            │       └── if (displaySubtitle)
            │           └── Text (displaySubtitle)
            ├── SizedBox (width 8)
            └── Icon (chevron_right)
```

**Lógica detallada**:

1. **Detección de plataforma** (línea 17):
   ```dart
   final isIOS = PlatformDetection.isIOS;
   ```
   - Detecta si la plataforma es iOS
   - Se usa para calcular el margin adaptativo

2. **Container exterior** (líneas 19-21):
   ```dart
   return Container(
     margin: EdgeInsets.symmetric(
       horizontal: isIOS ? 16.0 : 8.0,
       vertical: 4.0
     ),
     decoration: AppStyles.cardDecoration,
     ...
   )
   ```

   **margin** (línea 20):
   - **Adaptativo según plataforma**:
     - iOS: horizontal 16.0, vertical 4.0
     - Android/otros: horizontal 8.0, vertical 4.0
   - **Motivo**: iOS HIG prefiere más espacio horizontal

   **decoration** (línea 21):
   - `AppStyles.cardDecoration`
   - Probablemente incluye:
     - Color de fondo (blanco/gris claro)
     - BorderRadius redondeado
     - BoxShadow sutil

3. **GestureDetector** (líneas 22-25):
   ```dart
   child: GestureDetector(
     key: Key('contact_card_tap_${contact.id}'),
     onTap: onTap,
     behavior: HitTestBehavior.opaque,
     ...
   )
   ```

   **key** (línea 23):
   - `Key('contact_card_tap_${contact.id}')`
   - Key única basada en el ID del contacto
   - **Propósito**: Facilita testing y debugging
   - **Patrón**: `contact_card_tap_<id>`

   **onTap** (línea 24):
   - Pasa directamente el callback proporcionado
   - Required: Siempre interactiva

   **behavior** (línea 25):
   - `HitTestBehavior.opaque`
   - **Efecto**: Toda el área de la card (incluyendo espacios vacíos) es tappable
   - **Alternativa**: `deferToChild` solo haría tappable las áreas con widgets

4. **Padding interno** (línea 27):
   ```dart
   child: Padding(
     padding: const EdgeInsets.all(12.0),
     ...
   )
   ```
   - Padding uniforme de 12px en todos los lados
   - Espacio entre el borde de la card y el contenido

5. **Row principal** (líneas 28-29):
   ```dart
   child: Row(
     crossAxisAlignment: CrossAxisAlignment.center,
     children: [...]
   )
   ```
   - **crossAxisAlignment.center**: Centra verticalmente todos los hijos
   - **mainAxisAlignment**: No especificado (default: start)

6. **UserAvatar** (línea 31):
   ```dart
   UserAvatar(
     user: contact,
     radius: 32.5,
     showOnlineIndicator: false
   )
   ```

   **Propiedades**:
   - **user**: El contacto a mostrar
   - **radius**: 32.5
     - Diámetro total: 65px (32.5 * 2)
     - Tamaño consistente para todos los contactos
   - **showOnlineIndicator**: false
     - No muestra indicador de online/offline
     - **Motivo**: Contexto de lista de contactos, no chat

7. **SizedBox spacing** (línea 32):
   ```dart
   const SizedBox(width: 12)
   ```
   - Espacio horizontal de 12px entre avatar y textos

8. **Expanded con Column de información** (líneas 33-52):
   ```dart
   Expanded(
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [...]
     ),
   )
   ```

   **Expanded**:
   - Ocupa todo el espacio horizontal disponible
   - Previene overflow si los textos son largos

   **Column** (línea 34):
   - **crossAxisAlignment.start**: Alinea textos a la izquierda
   - **mainAxisAlignment**: No especificado (default: start)

   a) **Text del displayName** (líneas 37-42):
      ```dart
      Text(
        contact.displayName.isNotEmpty
          ? contact.displayName
          : context.l10n.unknownUser,
        style: AppStyles.cardTitle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.bold
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      )
      ```

      **text** (líneas 38-39):
      - **Lógica condicional**:
        - Si `contact.displayName.isNotEmpty` → muestra displayName
        - Si está vacío → muestra `context.l10n.unknownUser` (localizado)
      - **Fallback**: Previene mostrar string vacío

      **style** (líneas 39-40):
      - Base: `AppStyles.cardTitle`
      - Modificaciones:
        - fontSize: 16 (override)
        - fontWeight: FontWeight.bold

      **maxLines**: 2
      - Permite hasta 2 líneas para nombres largos

      **overflow**: TextOverflow.ellipsis
      - Si el nombre excede 2 líneas: muestra "..."

   b) **SizedBox spacing** (línea 43):
      ```dart
      const SizedBox(height: 4)
      ```
      - Espacio vertical de 4px entre nombre y subtítulo

   c) **Text del displaySubtitle (condicional)** (líneas 44-50):
      ```dart
      if (contact.displaySubtitle?.isNotEmpty == true)
        Text(
          contact.displaySubtitle ?? '',
          style: AppStyles.cardSubtitle.copyWith(
            color: AppStyles.grey600
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )
      ```

      **Condicional** (línea 44):
      - `contact.displaySubtitle?.isNotEmpty == true`
      - **Verificaciones**:
        1. displaySubtitle no es null (`?` null-aware)
        2. displaySubtitle no está vacío (`isNotEmpty`)
        3. Comparación explícita con `== true` (previene null)
      - Solo muestra subtítulo si hay contenido

      **text** (línea 46):
      - `contact.displaySubtitle ?? ''`
      - Null-safety: Usa string vacío si es null (redundante por el if, pero defensivo)

      **style** (líneas 47):
      - Base: `AppStyles.cardSubtitle`
      - Modificación: color: `AppStyles.grey600` (gris medio)

      **maxLines**: 2
      - Permite hasta 2 líneas para subtítulos largos

      **overflow**: TextOverflow.ellipsis
      - Trunca con "..." si excede 2 líneas

9. **SizedBox spacing** (línea 54):
   ```dart
   const SizedBox(width: 8)
   ```
   - Espacio horizontal de 8px entre textos y chevron

10. **Chevron icon** (línea 55):
    ```dart
    PlatformWidgets.platformIcon(
      CupertinoIcons.chevron_right,
      color: AppStyles.grey400
    )
    ```

    **Propósito**: Indicador visual de navegación (card tappable)

    **Icon**: CupertinoIcons.chevron_right
    - Chevron apuntando a la derecha (→)
    - Estilo iOS pero funciona en todas las plataformas

    **color**: AppStyles.grey400
    - Gris claro (color sutil, no prominente)

    **platformIcon**: Renderiza icono adaptativo según plataforma

## 5. COMPONENTES EXTERNOS UTILIZADOS

### UserAvatar (línea 31)
**Archivo**: `user_avatar.dart`
**Props utilizadas**:
- `user`: User (contact)
- `radius`: 32.5
- `showOnlineIndicator`: false

**Propósito**: Muestra avatar circular del usuario con foto de perfil o iniciales

### PlatformWidgets.platformIcon (línea 55)
**Archivo**: `platform_widgets.dart`
**Props**:
- IconData (CupertinoIcons.chevron_right)
- color: Color

**Propósito**: Renderiza icono adaptativo según plataforma

## 6. MODELOS UTILIZADOS

### User (línea 4)
**Archivo**: `../models/user.dart`
**Propiedades usadas**:
- `id`: String (para key única)
- `displayName`: String (nombre a mostrar)
- `displaySubtitle`: String? (información adicional, ej: email, username)
- Otras propiedades: profilePicture, etc. (usadas por UserAvatar)

**Propósito**: Modelo de datos de usuario/contacto

## 7. LOCALIZACIÓN

### Strings localizados usados:
- `context.l10n.unknownUser` (línea 38): Fallback cuando displayName está vacío

**Acceso**: Mediante extension `context.l10n` de `l10n_helpers.dart`

**Ejemplo de traducción**:
- ES: "Usuario desconocido"
- EN: "Unknown user"
- CA: "Usuari desconegut"

## 8. ESTILOS Y CONSTANTES

### AppStyles utilizados:

**Decoración**:
- `AppStyles.cardDecoration` (línea 21): Decoración de card (fondo, borde, sombra)

**Estilos de texto**:
- `AppStyles.cardTitle` (línea 39): Estilo para título (modificado con fontSize 16 y bold)
- `AppStyles.cardSubtitle` (línea 47): Estilo para subtítulo (modificado con grey600)

**Colores**:
- `AppStyles.grey600` (línea 47): Gris medio para subtítulo
- `AppStyles.grey400` (línea 55): Gris claro para chevron

### Valores hardcoded:

**Spacing**:
- Padding card: 12px (línea 27)
- Spacing avatar-textos: 12px (línea 32)
- Spacing nombre-subtítulo: 4px (línea 43)
- Spacing textos-chevron: 8px (línea 54)

**Margin**:
- iOS horizontal: 16px (línea 20)
- Android horizontal: 8px (línea 20)
- Vertical: 4px (línea 20)

**Avatar**:
- radius: 32.5 → diámetro 65px (línea 31)

**Texto**:
- fontSize displayName: 16 (línea 39)
- maxLines: 2 para nombre y subtítulo (líneas 40, 48)

## 9. COMPORTAMIENTO ESPECIAL

### Margin adaptativo según plataforma:
- **iOS**: 16px horizontal (más espacioso)
- **Android**: 8px horizontal (más compacto)
- **Vertical**: 4px en ambas (consistente)

**Motivo**: Seguir las guías de diseño de cada plataforma

### Fallback para displayName vacío:
- Si `displayName.isNotEmpty` es false → muestra "Usuario desconocido"
- **Casos de uso**:
  - Usuario sin nombre configurado
  - Contacto sin información de perfil
  - Error al cargar datos

### DisplaySubtitle condicional:
- Solo se muestra si existe y no está vacío
- **Posibles contenidos**:
  - Email del usuario
  - Username (@usuario)
  - Rol o cargo
  - Información adicional

### HitTestBehavior.opaque:
- **Efecto**: Toda el área de la card responde al tap
- **Incluye**: Espacios vacíos entre widgets
- **Alternativa opaque**: Solo widgets responderían al tap (mala UX)

### Key única para testing:
- Pattern: `contact_card_tap_<id>`
- Facilita encontrar y testear cards específicas
- Útil en listas largas de contactos

## 10. FLUJO DE INTERACCIÓN

### Usuario toca la card:
```
User taps anywhere in card area
    ↓
GestureDetector detecta tap (opaque behavior)
    ↓
onTap callback ejecutado
    ↓
Navegación a detalle del contacto (típicamente)
```

### Área tappable:
```
┌─────────────────────────────────────────┐
│ [Avatar] Nombre del contacto        [→] │ ← Todo tappable
│          email@example.com              │ ← Todo tappable
└─────────────────────────────────────────┘
```

## 11. CASOS DE USO

### 11.1. Lista de contactos

```dart
ListView.builder(
  itemCount: contacts.length,
  itemBuilder: (context, index) {
    final contact = contacts[index];
    return ContactCard(
      contact: contact,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContactDetailScreen(contact: contact),
        ),
      ),
    );
  },
)
```

### 11.2. Selección de invitados para evento

```dart
ContactCard(
  contact: user,
  onTap: () {
    setState(() {
      selectedContacts.add(user);
    });
  },
)
```

### 11.3. Búsqueda de contactos

```dart
Column(
  children: searchResults.map((contact) {
    return ContactCard(
      contact: contact,
      onTap: () => _selectContact(contact),
    );
  }).toList(),
)
```

### 11.4. Contacto sin nombre

```dart
ContactCard(
  contact: User(
    id: '123',
    displayName: '', // Vacío
    displaySubtitle: 'user@example.com',
  ),
  onTap: () {},
)
// Mostrará: "Usuario desconocido" + "user@example.com"
```

### 11.5. Contacto sin subtítulo

```dart
ContactCard(
  contact: User(
    id: '123',
    displayName: 'John Doe',
    displaySubtitle: null, // No se mostrará
  ),
  onTap: () {},
)
// Mostrará solo: "John Doe"
```

## 12. TESTING

### 12.1. Test cases recomendados

1. **Renderiza nombre correctamente**:
   ```dart
   testWidgets('displays contact name', (tester) async {
     final contact = User(
       id: '1',
       displayName: 'John Doe',
       displaySubtitle: null,
     );

     await tester.pumpWidget(
       ContactCard(
         contact: contact,
         onTap: () {},
       ),
     );

     expect(find.text('John Doe'), findsOneWidget);
   });
   ```

2. **Fallback para nombre vacío**:
   ```dart
   testWidgets('shows unknown user when name is empty', (tester) async {
     final contact = User(
       id: '1',
       displayName: '',
       displaySubtitle: null,
     );

     await tester.pumpWidget(
       ContactCard(
         contact: contact,
         onTap: () {},
       ),
     );

     expect(find.text('Usuario desconocido'), findsOneWidget);
   });
   ```

3. **Muestra subtítulo si existe**:
   ```dart
   testWidgets('displays subtitle when provided', (tester) async {
     final contact = User(
       id: '1',
       displayName: 'John',
       displaySubtitle: 'john@example.com',
     );

     await tester.pumpWidget(
       ContactCard(
         contact: contact,
         onTap: () {},
       ),
     );

     expect(find.text('john@example.com'), findsOneWidget);
   });
   ```

4. **Oculta subtítulo si vacío o null**:
   ```dart
   testWidgets('hides subtitle when empty', (tester) async {
     final contact = User(
       id: '1',
       displayName: 'John',
       displaySubtitle: '',
     );

     await tester.pumpWidget(
       ContactCard(
         contact: contact,
         onTap: () {},
       ),
     );

     // Solo debe haber 1 Text (el nombre), no 2
     expect(find.byType(Text), findsNWidgets(1));
   });
   ```

5. **Ejecuta callback al tap**:
   ```dart
   testWidgets('calls onTap when tapped', (tester) async {
     bool tapped = false;
     final contact = User(id: '1', displayName: 'John');

     await tester.pumpWidget(
       ContactCard(
         contact: contact,
         onTap: () => tapped = true,
       ),
     );

     await tester.tap(find.byType(ContactCard));
     expect(tapped, true);
   });
   ```

6. **Key única con ID**:
   ```dart
   testWidgets('has unique key with contact id', (tester) async {
     final contact = User(id: '123', displayName: 'John');

     await tester.pumpWidget(
       ContactCard(
         contact: contact,
         onTap: () {},
       ),
     );

     expect(
       find.byKey(Key('contact_card_tap_123')),
       findsOneWidget,
     );
   });
   ```

7. **Margin adaptativo iOS vs Android**:
   ```dart
   testWidgets('uses correct margin for iOS', (tester) async {
     // Mock platform detection
     PlatformDetection.isIOS = true;

     await tester.pumpWidget(
       ContactCard(
         contact: testContact,
         onTap: () {},
       ),
     );

     final container = tester.widget<Container>(
       find.byType(Container),
     );

     expect(
       container.margin,
       EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
     );
   });
   ```

## 13. CARACTERÍSTICAS TÉCNICAS

### 13.1. HitTestBehavior.opaque

**Propósito**: Capturar taps en toda el área de la card

**Comportamientos disponibles**:
- `opaque`: Captura taps en toda el área (implementado)
- `deferToChild`: Solo captura taps en widgets hijos
- `translucent`: Captura taps pero los propaga

**Elección**: `opaque` es ideal para cards interactivas

### 13.2. Null-safety en displaySubtitle

**Triple check**:
```dart
if (contact.displaySubtitle?.isNotEmpty == true)
  Text(contact.displaySubtitle ?? '')
```

1. `contact.displaySubtitle?` → null-aware access
2. `.isNotEmpty` → verifica que no esté vacío
3. `== true` → comparación explícita (previene null)
4. `contact.displaySubtitle ?? ''` → fallback a string vacío

**Defensivo**: Múltiples niveles de protección contra null

### 13.3. Expanded para prevenir overflow

```dart
Expanded(
  child: Column(
    children: [Text(...), Text(...)],
  ),
)
```

**Propósito**: Los textos largos no causarán overflow

**Comportamiento**:
- Expanded ocupa todo el espacio disponible
- Los Text con maxLines y ellipsis se truncan si es necesario
- Sin Expanded: Overflow error si los textos son muy largos

### 13.4. MaxLines y ellipsis

**Ambos textos**:
- `maxLines: 2`
- `overflow: TextOverflow.ellipsis`

**Efecto**:
- Permite hasta 2 líneas
- Si excede: muestra "..." al final

**Ejemplo**:
```
Nombre muy largo que excede las dos líneas...
email@ejemplo-muy-largo.com
```

### 13.5. CrossAxisAlignment.center en Row

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  ...
)
```

**Efecto**: Centra verticalmente avatar, textos y chevron

**Resultado**:
- Avatar alineado con el centro vertical de los textos
- Chevron alineado con el centro
- Apariencia balanceada

### 13.6. Key pattern para testing

```dart
Key('contact_card_tap_${contact.id}')
```

**Pattern**: `contact_card_tap_<id>`

**Uso en tests**:
```dart
await tester.tap(find.byKey(Key('contact_card_tap_123')));
```

**Beneficio**: Testear interacción con contactos específicos en listas

### 13.7. Constructor const

**Observación**: Constructor es const

**Limitación**: En la práctica, las instancias no serán const porque:
- `onTap` callback suele ser closure (no const)
- `contact` puede cambiar

**Beneficio**: Permite const cuando sea posible (optimización)

## 14. COMPARACIÓN CON EVENT_CARD

### Similitudes:
- Ambos son cards interactivas con GestureDetector
- Ambos tienen margin adaptativo según plataforma
- Ambos usan maxLines y ellipsis para textos
- Ambos tienen chevron de navegación

### Diferencias:

| Aspecto | ContactCard | EventCard |
|---------|-------------|-----------|
| **Avatar** | UserAvatar (circular) | Puede ser avatar o time container |
| **Información** | Nombre + subtítulo | Título + descripción + badges |
| **Layout** | Simple (1 columna) | Complejo (header + badges + status) |
| **Estados** | No tiene estados | Invitación pending/accepted/rejected |
| **Tamaño** | Compacto | Más grande (más información) |
| **Acciones** | Solo tap | Tap + botones de acción |

## 15. PERFORMANCE

### 15.1. Optimizaciones implementadas

1. **Constructor const**: Permite optimización cuando sea posible
2. **StatelessWidget**: No tiene estado interno, más eficiente
3. **Const widgets**: SizedBox con const

### 15.2. Consideraciones

1. **UserAvatar**: Puede cargar imagen de red (cached_network_image)
2. **Platform detection**: Se ejecuta en cada build (mínimo overhead)
3. **ListView context**: Diseñado para listas largas (scroll performante)

## 16. POSIBLES MEJORAS (NO implementadas)

### 16.1. Badge de estado

```dart
// Indicador de online/offline, verificado, etc.
if (contact.isOnline)
  Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: Colors.green,
      shape: BoxShape.circle,
    ),
  )
```

### 16.2. Trailing widget customizable

```dart
final Widget? trailing;

// En el Row, reemplazar chevron
trailing ?? PlatformWidgets.platformIcon(...)
```

### 16.3. Swipe actions

```dart
Dismissible(
  key: Key('contact_${contact.id}'),
  background: Container(color: Colors.red),
  onDismissed: onDelete,
  child: ContactCard(...),
)
```

### 16.4. Multi-select mode

```dart
final bool isSelectable;
final bool isSelected;
final ValueChanged<bool>? onSelected;

// Mostrar checkbox si isSelectable
if (isSelectable)
  Checkbox(
    value: isSelected,
    onChanged: onSelected,
  )
```

### 16.5. Contextual actions

```dart
// Menu contextual con long press
GestureDetector(
  onTap: onTap,
  onLongPress: () => showContextMenu(context),
  ...
)
```

## 17. RESUMEN

### 17.1. Propósito
Card interactiva para mostrar contactos/usuarios en listas con información básica (avatar, nombre, subtítulo) y navegación

### 17.2. Características clave
- **Margin adaptativo**: iOS (16px) vs Android (8px)
- **Fallback de nombre**: "Usuario desconocido" si displayName vacío
- **Subtítulo condicional**: Solo si existe y no está vacío
- **HitTestBehavior.opaque**: Toda el área es tappable
- **Key única**: Para testing con ID del contacto
- **MaxLines 2**: Para nombre y subtítulo con ellipsis

### 17.3. Layout
```
[Avatar 65px] [Nombre (bold, 16px, max 2 líneas)] [→]
              [Subtítulo (grey, max 2 líneas)]
```

### 17.4. Uso principal
Listas de contactos, selección de invitados, búsqueda de usuarios, selección de participantes

### 17.5. Componentes externos
- UserAvatar: Avatar circular del usuario
- PlatformWidgets.platformIcon: Icono adaptativo
- PlatformDetection: Detección de plataforma

---

**Fin de la documentación de contact_card.dart**
