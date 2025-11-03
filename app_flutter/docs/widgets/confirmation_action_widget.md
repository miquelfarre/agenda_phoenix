# ConfirmationActionWidget - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/confirmation_action_widget.dart`
**Líneas**: 42
**Tipo**: StatefulWidget con State privado
**Propósito**: Widget wrapper que añade confirmación mediante diálogo antes de ejecutar una acción, envolviendo cualquier widget child con un GestureDetector

## 2. CLASES CONTENIDAS

Este archivo contiene:
1. **ConfirmationActionWidget** (líneas 4-21): StatefulWidget público
2. **_ConfirmationActionWidgetState** (líneas 23-41): State privado que maneja la lógica

---

## 3. CLASE: ConfirmationActionWidget

### 3.1. Información General

**Líneas**: 4-21
**Tipo**: StatefulWidget
**Propósito**: Widget wrapper que intercepta taps en su child, muestra un diálogo de confirmación y ejecuta una acción async si el usuario confirma

### 3.2. Propiedades (líneas 5-15)

- `dialogTitle` (String, required, línea 5): Título del diálogo de confirmación
- `dialogMessage` (String, required, línea 7): Mensaje explicativo en el diálogo
- `actionText` (String, required, línea 9): Texto del botón de confirmación (ej: "Eliminar", "Confirmar")
- `child` (Widget, required, línea 11): Widget que será envuelto y al que se añadirá interactividad
- `onAction` (Future<void> Function(), required, línea 13): Función asíncrona ejecutada si el usuario confirma
- `isDestructive` (bool, default: false, línea 15): Indica si la acción es destructiva (afecta el estilo del diálogo)

### 3.3. Constructor (línea 17)

```dart
const ConfirmationActionWidget({
  super.key,
  required this.dialogTitle,
  required this.dialogMessage,
  required this.actionText,
  required this.child,
  required this.onAction,
  this.isDestructive = false
})
```

**Tipo**: Constructor const

**Parámetros**:
- Todos required excepto `isDestructive`
- `isDestructive`: default false

**Uso típico**:
```dart
ConfirmationActionWidget(
  dialogTitle: 'Eliminar evento',
  dialogMessage: '¿Estás seguro de que quieres eliminar este evento?',
  actionText: 'Eliminar',
  isDestructive: true,
  onAction: () async {
    await deleteEvent();
  },
  child: Icon(Icons.delete),
)
```

### 3.4. Método createState (líneas 19-20)

```dart
@override
State<ConfirmationActionWidget> createState() =>
  _ConfirmationActionWidgetState();
```

**Propósito**: Crea la instancia del State asociado

**Retorno**: Instancia de _ConfirmationActionWidgetState

---

## 4. CLASE: _ConfirmationActionWidgetState

### 4.1. Información General

**Líneas**: 23-41
**Tipo**: State<ConfirmationActionWidget>
**Visibilidad**: Privada (prefijo `_`)
**Propósito**: Maneja la lógica de interacción, muestra el diálogo de confirmación y ejecuta la acción

### 4.2. Método build (líneas 24-27)

**Tipo de retorno**: Widget
**Anotación**: @override

**Propósito**: Construye un GestureDetector que envuelve el child

**Código**:
```dart
@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: _showConfirmationDialog,
    child: widget.child
  );
}
```

**Estructura del widget tree**:
```
GestureDetector (onTap: _showConfirmationDialog)
└── child (widget proporcionado por el usuario)
```

**Lógica**:
1. Envuelve `widget.child` en GestureDetector
2. Al tocar: ejecuta `_showConfirmationDialog`
3. El child se mantiene intacto visualmente

**Características**:
- No modifica la apariencia del child
- Solo añade comportamiento de tap
- Toda el área del child es tappable

### 4.3. Método _showConfirmationDialog (líneas 29-36)

**Tipo de retorno**: Future<void>
**Visibilidad**: Privado
**Anotación**: async

**Propósito**: Orquesta el flujo completo: mostrar diálogo → esperar confirmación → ejecutar acción

**Código**:
```dart
Future<void> _showConfirmationDialog() async {
  final callback = widget.onAction;
  final confirmed = await _showDialog();
  if (confirmed) {
    if (!mounted) return;
    await callback();
  }
}
```

**Lógica detallada**:

1. **Guardar callback** (línea 30):
   ```dart
   final callback = widget.onAction;
   ```
   - Guarda la referencia al callback en variable local
   - Previene posibles cambios durante la ejecución async
   - **Nota**: En este caso es redundante (widget.onAction es final), pero es una práctica defensiva

2. **Mostrar diálogo y esperar respuesta** (línea 31):
   ```dart
   final confirmed = await _showDialog();
   ```
   - Llama a `_showDialog()` que retorna `Future<bool>`
   - `await` pausa la ejecución hasta que el usuario responda
   - `confirmed`: true si el usuario confirmó, false si canceló

3. **Verificar confirmación** (línea 32):
   ```dart
   if (confirmed) {
   ```
   - Solo procede si el usuario confirmó
   - Si cancelled (confirmed = false), termina sin hacer nada

4. **Mounted check** (línea 33):
   ```dart
   if (!mounted) return;
   ```
   - **Crítico**: Verifica que el widget sigue en el árbol
   - Previene errores si el usuario navegó a otra pantalla mientras el diálogo estaba abierto
   - Después de un `await`, siempre verificar `mounted`

5. **Ejecutar acción** (línea 34):
   ```dart
   await callback();
   ```
   - Ejecuta la función onAction proporcionada por el usuario
   - `await`: Espera a que complete (puede ser una operación de red, DB, etc.)
   - Maneja el Future retornado por callback

**Flujo de ejecución**:
```
User taps child
    ↓
_showConfirmationDialog() llamado
    ↓
_showDialog() → muestra diálogo
    ↓
Usuario interactúa con diálogo
    ↓
confirmed = true/false
    ↓
if confirmed && mounted
    ↓
Ejecuta callback (onAction)
```

**Safety features**:
- Mounted check previene crashes
- Confirmación explícita antes de acción
- Manejo de async operations correcto

### 4.4. Método _showDialog (líneas 38-40)

**Tipo de retorno**: Future<bool>
**Visibilidad**: Privado
**Anotación**: async

**Propósito**: Muestra el diálogo de confirmación adaptativo (iOS/Android) y retorna el resultado

**Código**:
```dart
Future<bool> _showDialog() async {
  return await PlatformDialogHelpers.showPlatformConfirmDialog(
    context,
    title: widget.dialogTitle,
    message: widget.dialogMessage,
    confirmText: widget.actionText,
    isDestructive: widget.isDestructive
  ) ?? false;
}
```

**Análisis detallado**:

1. **PlatformDialogHelpers.showPlatformConfirmDialog** (línea 39):
   - Función helper que muestra diálogo adaptativo según plataforma
   - iOS: CupertinoAlertDialog
   - Android: AlertDialog (Material)

2. **Parámetros pasados**:
   - **context** (línea 39): BuildContext del widget (primer parámetro posicional)
   - **title** (línea 39): `widget.dialogTitle`
   - **message** (línea 39): `widget.dialogMessage`
   - **confirmText** (línea 39): `widget.actionText` (texto del botón de confirmación)
   - **isDestructive** (línea 39): `widget.isDestructive`
     - En iOS: Botón rojo si true
     - En Android: Puede afectar el color del botón

3. **Retorno y null safety** (línea 39):
   ```dart
   ) ?? false
   ```
   - `showPlatformConfirmDialog` retorna `Future<bool?>`
   - Puede ser null si el diálogo se cierra sin selección (ej: tap fuera, back button)
   - `?? false`: Operador null-coalescing
   - **Si null → false** (se trata como cancelación)
   - **Si bool → retorna ese valor**

4. **await doble**:
   ```dart
   return await PlatformDialogHelpers...
   ```
   - El `await` es necesario porque showPlatformConfirmDialog retorna Future<bool?>
   - El `return await` podría simplificarse a solo `return` en este caso, pero es explícito

**Retorno**:
- `true`: Usuario confirmó (presionó botón de confirmación)
- `false`: Usuario canceló o cerró el diálogo

**Ejemplo de diálogo mostrado**:

iOS:
```
┌──────────────────────────────┐
│   Eliminar evento            │
├──────────────────────────────┤
│ ¿Estás seguro de que quieres │
│ eliminar este evento?        │
├──────────────────────────────┤
│ [Cancelar] [Eliminar] (rojo) │
└──────────────────────────────┘
```

Android:
```
┌──────────────────────────────┐
│ Eliminar evento              │
│                              │
│ ¿Estás seguro de que quieres │
│ eliminar este evento?        │
│                              │
│        [CANCELAR] [ELIMINAR] │
└──────────────────────────────┘
```

---

## 5. DEPENDENCIAS

**Imports**:
```dart
import 'package:flutter/widgets.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
```

### 5.1. Dependencias externas

1. **flutter/widgets.dart** (línea 1):
   - StatefulWidget, State
   - Widget, BuildContext
   - GestureDetector
   - **Nota**: No importa material.dart ni cupertino.dart
   - Usa solo widgets base de Flutter

### 5.2. Dependencias internas

2. **dialog_helpers.dart** (línea 2):
   - PlatformDialogHelpers.showPlatformConfirmDialog
   - Helper que abstrae la diferencia entre diálogos iOS y Android

**Función esperada en dialog_helpers.dart**:
```dart
class PlatformDialogHelpers {
  static Future<bool?> showPlatformConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    if (Platform.isIOS) {
      // Mostrar CupertinoAlertDialog
    } else {
      // Mostrar Material AlertDialog
    }
  }
}
```

---

## 6. FLUJO DE DATOS Y CONTROL

### 6.1. Diagrama de flujo completo

```
┌─────────────────────────────────────────────────────┐
│ ConfirmationActionWidget                            │
│                                                     │
│ ┌─────────────────────────────────────────────────┐ │
│ │ build()                                         │ │
│ │   ↓                                             │ │
│ │ GestureDetector(onTap: _showConfirmationDialog) │ │
│ │   └── child                                     │ │
│ └─────────────────────────────────────────────────┘ │
│                                                     │
│         User taps child                             │
│              ↓                                      │
│ ┌─────────────────────────────────────────────────┐ │
│ │ _showConfirmationDialog()                       │ │
│ │   1. Guardar callback                           │ │
│ │   2. final confirmed = await _showDialog()      │ │
│ │   3. if (confirmed && mounted)                  │ │
│ │   4. await callback()                           │ │
│ └─────────────────────────────────────────────────┘ │
│              ↓                                      │
│ ┌─────────────────────────────────────────────────┐ │
│ │ _showDialog()                                   │ │
│ │   → PlatformDialogHelpers.showPlatformConfirmDialog│
│ │   → return bool (true/false)                    │ │
│ └─────────────────────────────────────────────────┘ │
│              ↓                                      │
│         Platform dialog shown                       │
│              ↓                                      │
│         User confirms or cancels                    │
│              ↓                                      │
│    confirmed = true → execute callback              │
│    confirmed = false → do nothing                   │
└─────────────────────────────────────────────────────┘
```

### 6.2. Casos de uso

#### Caso 1: Usuario confirma
```
1. User taps child
2. Dialog shown
3. User taps "Confirm" button
4. confirmed = true
5. mounted check passes
6. onAction() executed
7. Done
```

#### Caso 2: Usuario cancela
```
1. User taps child
2. Dialog shown
3. User taps "Cancel" button
4. confirmed = false
5. onAction() NOT executed
6. Done
```

#### Caso 3: Widget unmounted durante diálogo
```
1. User taps child
2. Dialog shown
3. User navigates away (pop)
4. Widget unmounted
5. confirmed = true (or false)
6. mounted check fails
7. onAction() NOT executed (previene crash)
8. Done
```

#### Caso 4: Usuario cierra diálogo sin botones
```
1. User taps child
2. Dialog shown
3. User taps outside dialog (Android) or back button
4. Dialog returns null
5. null ?? false → confirmed = false
6. onAction() NOT executed
7. Done
```

---

## 7. CARACTERÍSTICAS TÉCNICAS

### 7.1. Mounted check pattern

**Problema**: Después de un `await`, el widget puede haber sido removido del árbol

**Solución**:
```dart
final confirmed = await _showDialog();  // await aquí
if (confirmed) {
  if (!mounted) return;  // check después del await
  await callback();
}
```

**Previene**:
- Errors: "setState() called after dispose()"
- Crashes por acceso a BuildContext inválido
- Memory leaks

**Patrón estándar en Flutter**: Siempre verificar `mounted` después de operaciones async

### 7.2. Null-coalescing operator

```dart
PlatformDialogHelpers.showPlatformConfirmDialog(...) ?? false
```

**Tipo de retorno**: Future<bool?>

**Posibles valores**:
- `true`: Usuario confirmó
- `false`: Usuario canceló
- `null`: Diálogo cerrado sin selección

**Conversión a bool no-nullable**:
- `null ?? false → false`
- `true ?? false → true`
- `false ?? false → false`

**Beneficio**: Simplifica el handling de null, trata null como cancelación

### 7.3. Async/await encadenado

**Cadena de awaits**:
```
_showConfirmationDialog()
    ↓ await
_showDialog()
    ↓ await
showPlatformConfirmDialog()
    ↓ await
User interaction
```

**Cada await** pausa la función hasta que el Future se complete

**Propagación de errores**: Si cualquier Future lanza error, se propaga hacia arriba (no hay try-catch en este widget)

### 7.4. StatefulWidget sin estado interno

**Observación**: Este StatefulWidget no tiene variables de estado (no usa setState)

**¿Por qué StatefulWidget entonces?**
- Necesita acceso a `mounted` (solo disponible en State)
- Mounted check es crítico después de operaciones async
- Si fuera StatelessWidget, no podría verificar mounted

**Alternativa no viable**: StatelessWidget con callback externo para mounted check

### 7.5. GestureDetector sobre child completo

**Comportamiento**:
- Todo el área del child es tappable
- No añade área adicional de tap (hitbox = child bounds)
- No modifica la apariencia del child

**Comparación con alternativas**:
- InkWell: Añadiría efecto ripple (puede no ser deseado)
- TextButton/ElevatedButton: Cambiaría la apariencia del child

### 7.6. Callback como Future<void> Function()

**Tipo**: `Future<void> Function()`

**Características**:
- Función sin parámetros
- Retorna Future<void> (async)
- Puede ser async function o function que retorna Future

**Ejemplos válidos**:
```dart
// Async function
onAction: () async {
  await deleteEvent();
}

// Function que retorna Future
onAction: () {
  return deleteEvent();
}

// Async function con múltiples awaits
onAction: () async {
  await api.deleteEvent(id);
  await cache.invalidate();
}
```

### 7.7. Const constructor con callback

**Observación**: Constructor es const, pero acepta callback (función)

**Explicación**: Las funciones son objetos en Dart y pueden ser const si son:
- Top-level functions
- Static methods
- Constructor tear-offs

**En la práctica**: El widget se instancia como non-const porque los callbacks suelen ser closures (no const)

---

## 8. PATRONES DE DISEÑO

### 8.1. Wrapper Pattern

**ConfirmationActionWidget** envuelve cualquier widget child:
- No modifica la apariencia
- Solo añade comportamiento
- Composición transparente

**Uso**:
```dart
// Sin confirmación
IconButton(
  icon: Icon(Icons.delete),
  onPressed: deleteEvent,
)

// Con confirmación (wrapper)
ConfirmationActionWidget(
  dialogTitle: 'Eliminar',
  dialogMessage: '¿Confirmar?',
  actionText: 'Eliminar',
  onAction: deleteEvent,
  child: IconButton(
    icon: Icon(Icons.delete),
    onPressed: () {}, // Dummy, el tap lo maneja el wrapper
  ),
)
```

**Nota**: El child debe ser "inerte" (sin onPressed propio) o el wrapper interceptará el tap

### 8.2. Confirmation Dialog Pattern

**Flujo estándar de confirmación**:
1. User inicia acción
2. Mostrar diálogo de confirmación
3. Esperar respuesta del usuario
4. Si confirma: ejecutar acción
5. Si cancela: no hacer nada

**Implementado en**: Este widget encapsula todo el patrón

### 8.3. Platform Abstraction Pattern

**Delegación a helper**:
- `PlatformDialogHelpers.showPlatformConfirmDialog`
- Abstrae diferencias entre iOS y Android
- El widget no conoce detalles de plataforma

**Beneficios**:
- Código más limpio
- Reutilización de lógica de diálogos
- Fácil testing (mock del helper)

---

## 9. CASOS DE USO

### 9.1. Eliminar evento

```dart
ConfirmationActionWidget(
  dialogTitle: 'Eliminar evento',
  dialogMessage: '¿Estás seguro de que quieres eliminar este evento? Esta acción no se puede deshacer.',
  actionText: 'Eliminar',
  isDestructive: true,
  onAction: () async {
    await eventRepository.deleteEvent(eventId);
    Navigator.pop(context);
  },
  child: ListTile(
    leading: Icon(Icons.delete, color: Colors.red),
    title: Text('Eliminar evento'),
  ),
)
```

### 9.2. Cancelar suscripción

```dart
ConfirmationActionWidget(
  dialogTitle: 'Cancelar suscripción',
  dialogMessage: 'Dejarás de recibir actualizaciones de este calendario.',
  actionText: 'Cancelar suscripción',
  isDestructive: true,
  onAction: () async {
    await subscriptionRepository.unsubscribe(calendarId);
  },
  child: ElevatedButton(
    onPressed: null, // Inerte, el tap lo maneja el wrapper
    child: Text('Cancelar suscripción'),
  ),
)
```

### 9.3. Acción no destructiva (confirmación simple)

```dart
ConfirmationActionWidget(
  dialogTitle: 'Marcar como leído',
  dialogMessage: '¿Marcar todos los eventos como leídos?',
  actionText: 'Marcar',
  isDestructive: false, // No destructivo
  onAction: () async {
    await eventRepository.markAllAsRead();
  },
  child: TextButton(
    onPressed: null,
    child: Text('Marcar todos como leídos'),
  ),
)
```

### 9.4. Wrapper sobre icono

```dart
ConfirmationActionWidget(
  dialogTitle: 'Eliminar',
  dialogMessage: '¿Eliminar este ítem?',
  actionText: 'Eliminar',
  isDestructive: true,
  onAction: () async {
    await deleteItem();
  },
  child: Icon(Icons.delete, color: Colors.red),
)
```

**Nota**: Todo el icono será tappable

---

## 10. TESTING

### 10.1. Test cases recomendados

1. **Mostrar diálogo al tap**:
   ```dart
   testWidgets('shows dialog when tapped', (tester) async {
     await tester.pumpWidget(
       ConfirmationActionWidget(
         dialogTitle: 'Title',
         dialogMessage: 'Message',
         actionText: 'Confirm',
         onAction: () async {},
         child: Text('Tap me'),
       ),
     );

     await tester.tap(find.text('Tap me'));
     await tester.pump();

     expect(find.text('Title'), findsOneWidget);
     expect(find.text('Message'), findsOneWidget);
   });
   ```

2. **Ejecutar acción al confirmar**:
   ```dart
   testWidgets('executes action when confirmed', (tester) async {
     bool actionExecuted = false;

     await tester.pumpWidget(
       ConfirmationActionWidget(
         dialogTitle: 'Title',
         dialogMessage: 'Message',
         actionText: 'Confirm',
         onAction: () async {
           actionExecuted = true;
         },
         child: Text('Tap me'),
       ),
     );

     await tester.tap(find.text('Tap me'));
     await tester.pump();

     await tester.tap(find.text('Confirm'));
     await tester.pumpAndSettle();

     expect(actionExecuted, true);
   });
   ```

3. **No ejecutar acción al cancelar**:
   ```dart
   testWidgets('does not execute action when cancelled', (tester) async {
     bool actionExecuted = false;

     await tester.pumpWidget(
       ConfirmationActionWidget(
         dialogTitle: 'Title',
         dialogMessage: 'Message',
         actionText: 'Confirm',
         onAction: () async {
           actionExecuted = true;
         },
         child: Text('Tap me'),
       ),
     );

     await tester.tap(find.text('Tap me'));
     await tester.pump();

     await tester.tap(find.text('Cancel'));
     await tester.pumpAndSettle();

     expect(actionExecuted, false);
   });
   ```

4. **Mounted check**:
   ```dart
   testWidgets('handles unmount during dialog', (tester) async {
     await tester.pumpWidget(
       ConfirmationActionWidget(
         dialogTitle: 'Title',
         dialogMessage: 'Message',
         actionText: 'Confirm',
         onAction: () async {
           // Este no debería ejecutarse si el widget se unmountea
         },
         child: Text('Tap me'),
       ),
     );

     await tester.tap(find.text('Tap me'));
     await tester.pump();

     // Simular navegación (unmount)
     Navigator.pop(tester.element(find.byType(ConfirmationActionWidget)).context);
     await tester.pumpAndSettle();

     // No debería crashear
   });
   ```

---

## 11. PERFORMANCE

### 11.1. Consideraciones

1. **GestureDetector overhead**: Mínimo, solo un widget adicional en el árbol
2. **Dialog creation**: Bajo costo, solo se crea cuando se tappa
3. **Async operations**: Pueden ser costosas dependiendo de onAction

### 11.2. Optimizaciones implementadas

1. **Lazy dialog creation**: El diálogo solo se crea al tap, no en el build
2. **Mounted check**: Previene ejecución innecesaria si el widget ya no existe

### 11.3. Posibles mejoras

1. **Throttling/Debouncing**: Prevenir múltiples taps rápidos
   ```dart
   bool _isProcessing = false;

   Future<void> _showConfirmationDialog() async {
     if (_isProcessing) return;
     _isProcessing = true;
     // ... lógica existente
     _isProcessing = false;
   }
   ```

2. **Loading indicator**: Mostrar loading durante la ejecución de onAction
   ```dart
   await callback();
   // Mostrar loading dialog o indicator
   ```

---

## 12. POSIBLES MEJORAS (NO implementadas)

### 12.1. Customizable cancel text

```dart
final String? cancelText;

// En _showDialog
cancelText: widget.cancelText ?? 'Cancelar',
```

### 12.2. Callback de cancelación

```dart
final VoidCallback? onCancel;

// En _showConfirmationDialog
if (!confirmed) {
  widget.onCancel?.call();
}
```

### 12.3. Loading state

```dart
bool _isLoading = false;

Future<void> _showConfirmationDialog() async {
  // ...
  if (confirmed) {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await callback();
    if (mounted) setState(() => _isLoading = false);
  }
}

Widget build(BuildContext context) {
  if (_isLoading) {
    return Stack(
      children: [
        Opacity(opacity: 0.5, child: widget.child),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
  return GestureDetector(...);
}
```

### 12.4. Error handling

```dart
final void Function(dynamic error)? onError;

try {
  await callback();
} catch (e) {
  if (mounted) {
    widget.onError?.call(e);
    // O mostrar error dialog
  }
}
```

### 12.5. Confirmation count (double confirmation)

```dart
final int confirmationCount;

Future<void> _showConfirmationDialog() async {
  for (int i = 0; i < widget.confirmationCount; i++) {
    final confirmed = await _showDialog();
    if (!confirmed) return;
  }
  // Execute action
}
```

---

## 13. LIMITACIONES Y CONSIDERACIONES

### 13.1. Child debe ser "inerte"

**Problema**: Si el child tiene su propio onTap/onPressed, pueden conflictuar

**Ejemplo problemático**:
```dart
ConfirmationActionWidget(
  onAction: deleteEvent,
  child: ElevatedButton(
    onPressed: someOtherAction, // ⚠️ Conflicto
    child: Text('Delete'),
  ),
)
```

**Solución**: El child debe tener onPressed: null o no tener callback propio

### 13.2. Área tappable = child bounds

**Comportamiento**: Solo el área del child es tappable

**Si necesitas área mayor**: Envolver child en Padding o Container con tamaño específico

### 13.3. No hay feedback visual del tap

**Observación**: GestureDetector no proporciona feedback visual (no ripple, no highlight)

**Si necesitas feedback**: Usar InkWell en el child o envolver en Material

### 13.4. Propagación de errores

**No hay try-catch**: Si onAction lanza error, se propaga al caller

**Responsabilidad**: El caller debe manejar errores o onAction debe manejarlos internamente

---

## 14. RESUMEN

### 14.1. Propósito

Widget wrapper que añade confirmación mediante diálogo antes de ejecutar acciones, especialmente útil para acciones destructivas o irreversibles

### 14.2. Características clave

- **Wrapper transparente**: No modifica apariencia del child
- **Confirmación automática**: Muestra diálogo adaptativo (iOS/Android)
- **Async-safe**: Mounted check previene crashes
- **Destructive actions support**: isDestructive para styling especial
- **Null-safe**: Maneja correctamente diálogos cerrados sin selección

### 14.3. Flujo

Tap → Diálogo → Confirmación → Mounted check → Ejecución de acción

### 14.4. Uso principal

Envolver widgets que disparan acciones destructivas o irreversibles:
- Eliminar eventos
- Cancelar suscripciones
- Deshacer cambios importantes
- Resetear datos

### 14.5. Best practices

1. Usar para acciones destructivas o irreversibles
2. Child debe ser "inerte" (sin callback propio)
3. onAction debe manejar sus propios errores
4. isDestructive = true para acciones peligrosas

---

**Fin de la documentación de confirmation_action_widget.dart**
