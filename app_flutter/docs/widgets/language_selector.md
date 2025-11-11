# LanguageSelector - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/language_selector.dart`
**Líneas**: 90
**Tipo**: ConsumerWidget (Riverpod)
**Propósito**: Selector de idioma que muestra lista de idiomas disponibles con banderas, marca el seleccionado y cambia el idioma de la app con loading dialog y feedback

## 2. CLASE Y PROPIEDADES

### LanguageSelector (líneas 11-89)
Widget que extiende `ConsumerWidget` para acceso a Riverpod state

**Propiedades**: Ninguna (sin props)

## 3. CONSTRUCTOR (línea 12)

```dart
const LanguageSelector({super.key});
```

**Tipo**: Constructor const sin parámetros

**Uso típico**:
```dart
LanguageSelector() // En pantalla de settings
```

## 4. MÉTODO BUILD (líneas 14-51)

### build(BuildContext context, WidgetRef ref) (líneas 15-51)

**Tipo de retorno**: Widget
**Parámetros**: BuildContext context, WidgetRef ref
**Anotación**: @override

**Estructura del widget tree**:
```
Column (crossAxisAlignment: start)
├── Padding (header con "Idioma")
│   └── Text (label)
├── ...availableLanguages.map (spread de ListTiles)
│   └── PlatformListTile por cada idioma
│       ├── leading: Text (flag emoji)
│       ├── title: Text (nombre del idioma)
│       └── trailing: if (selected) Icon (check)
└── PlatformDivider
```

**Lógica detallada**:

1. **Detección de plataforma** (línea 16):
   ```dart
   final isIOS = PlatformDetection.isIOS;
   ```
   - Usado para determinar color del check icon

2. **Obtener localeNotifier** (línea 17):
   ```dart
   final localeNotifier = ref.read(localeNotifierProvider.notifier);
   ```
   - `ref.read()`: Acceso de solo lectura al notifier
   - No reacciona a cambios (solo queremos el notifier)

3. **Obtener l10n** (línea 18):
   ```dart
   final l10n = context.l10n;
   ```
   - Localizaciones actuales

4. **Obtener idiomas disponibles** (línea 20):
   ```dart
   final availableLanguages = localeNotifier.getAvailableLanguages();
   ```

   **localeNotifier.getAvailableLanguages()**:
   - Probablemente retorna: `List<Map<String, dynamic>>`
   - Cada map contiene:
     - `'locale'`: Locale object
     - `'name'`: String (nombre del idioma)
     - `'flag'`: String (emoji de bandera)

   **Ejemplo**:
   ```dart
   [
     {'locale': Locale('es'), 'name': 'Español', 'flag': '🇪🇸'},
     {'locale': Locale('en'), 'name': 'English', 'flag': '🇬🇧'},
     {'locale': Locale('ca'), 'name': 'Català', 'flag': '🏴'},
   ]
   ```

5. **Column container** (líneas 22-23):
   ```dart
   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [...]
   )
   ```
   - Alinea hijos a la izquierda

6. **Header con label** (líneas 25-31):
   ```dart
   Padding(
     padding: const EdgeInsets.symmetric(
       horizontal: 16.0,
       vertical: 8.0
     ),
     child: Text(
       l10n.language,
       style: AppStyles.cardTitle.copyWith(
         fontWeight: FontWeight.bold,
         color: AppStyles.grey700
       ),
     ),
   )
   ```

   **Padding**: 16px horizontal, 8px vertical
   **Text**: "Idioma" / "Language" / "Idioma"
   **Style**: cardTitle bold en gris oscuro

7. **Map sobre availableLanguages** (líneas 32-46):
   ```dart
   ...availableLanguages.map((lang) {
     final locale = lang['locale'] as Locale;
     final name = lang['name'] as String;
     final flag = lang['flag'] as String;
     final isSelected = ref.watch(localeNotifierProvider) == locale;

     return PlatformWidgets.platformListTile(...);
   })
   ```

   **Spread operator** `...`: Inserta todos los widgets mapeados en children

   a) **Extraer datos del map** (líneas 33-35):
      ```dart
      final locale = lang['locale'] as Locale;
      final name = lang['name'] as String;
      final flag = lang['flag'] as String;
      ```
      - Cast explícito desde dynamic

   b) **Determinar si está seleccionado** (línea 36):
      ```dart
      final isSelected = ref.watch(localeNotifierProvider) == locale;
      ```

      **ref.watch(localeNotifierProvider)**:
      - Observa cambios en el locale actual
      - Reactivo: Rebuild cuando cambia
      - Compara con locale de este idioma

   c) **PlatformListTile** (líneas 38-46):
      ```dart
      return PlatformWidgets.platformListTile(
        leading: Text(
          flag,
          style: AppStyles.headlineSmall.copyWith(fontSize: 24)
        ),
        title: Text(
          name,
          style: AppStyles.cardTitle.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: AppStyles.black87
          ),
        ),
        trailing: isSelected
          ? PlatformWidgets.platformIcon(
              CupertinoIcons.check_mark,
              color: isIOS
                ? CupertinoColors.activeBlue.resolveFrom(context)
                : AppStyles.blue600,
              size: 20
            )
          : null,
        onTap: () => _changeLanguage(context, ref, locale),
      );
      ```

      **leading** (líneas 39):
      - Text con flag emoji
      - fontSize: 24 (grande)

      **title** (líneas 40-43):
      - Text con nombre del idioma
      - **fontWeight**:
        - Si selected: FontWeight.w600 (semi-bold)
        - Si no: FontWeight.normal
      - **Feedback visual**: Bold cuando seleccionado

      **trailing** (líneas 44):
      - **Si selected**: Check icon
        - CupertinoIcons.check_mark
        - **Color**:
          - iOS: `CupertinoColors.activeBlue.resolveFrom(context)` (azul nativo iOS)
          - Android: `AppStyles.blue600`
        - size: 20
      - **Si no selected**: null (no muestra nada)

      **onTap** (línea 45):
      - Llama `_changeLanguage(context, ref, locale)`

8. **Divider** (línea 48):
   ```dart
   PlatformWidgets.platformDivider(),
   ```
   - Línea divisoria al final

## 5. MÉTODO _changeLanguage (líneas 53-88)

**Tipo de retorno**: Future<void>
**Visibilidad**: Privado
**Parámetros**: BuildContext context, WidgetRef ref, Locale locale
**Anotación**: async

**Propósito**: Cambia el idioma de la app con loading dialog y manejo de errores

```dart
void _changeLanguage(BuildContext context, WidgetRef ref, Locale locale) async {
  final localeNotifier = ref.read(localeNotifierProvider.notifier);
  final l10n = context.l10n;

  try {
    PlatformDialogHelpers.showPlatformLoadingDialog(context, message: l10n.updating);
  } catch (e) {
    return;
  }

  try {
    localeNotifier.setLocale(locale);

    if (context.mounted) {
      try {
        Navigator.of(context, rootNavigator: true).pop();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            final newL10n = context.l10n;
            PlatformDialogHelpers.showSnackBar(
              context: context,
              message: newL10n.settingsUpdated
            );
          } else {}
        });
      } catch (_) {}
    } else {}
  } catch (e) {
    if (context.mounted) {
      try {
        Navigator.of(context, rootNavigator: true).pop();

        final errL10n = context.l10n;
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: errL10n.errorUpdatingSettings,
          isError: true
        );
      } catch (_) {}
    } else {}
  }
}
```

**Lógica detallada**:

1. **Setup inicial** (líneas 54-55):
   ```dart
   final localeNotifier = ref.read(localeNotifierProvider.notifier);
   final l10n = context.l10n;
   ```
   - Obtiene notifier para cambiar locale
   - Guarda l10n actual (antes del cambio)

2. **Mostrar loading dialog** (líneas 57-61):
   ```dart
   try {
     PlatformDialogHelpers.showPlatformLoadingDialog(
       context,
       message: l10n.updating
     );
   } catch (e) {
     return;
   }
   ```

   **showPlatformLoadingDialog**:
   - Muestra dialog con spinner
   - message: "Actualizando..." (localizado en idioma actual)

   **Try-catch**:
   - Si falla mostrar dialog: return early
   - **Posible causa**: Context inválido, dialog ya abierto

3. **Cambiar locale** (líneas 63-77):

   **Try principal** (línea 63):
   ```dart
   try {
     localeNotifier.setLocale(locale);
     // ... success handling
   } catch (e) {
     // ... error handling
   }
   ```

   a) **Ejecutar cambio** (línea 64):
      ```dart
      localeNotifier.setLocale(locale);
      ```
      - Cambia el locale de la app
      - Trigger rebuild de toda la app con nuevo idioma
      - **Síncrono**: No es await

   b) **Mounted check** (línea 66):
      ```dart
      if (context.mounted) { ... }
      ```
      - Verifica que context sigue válido
      - **Importante**: Después de cambio de locale, context puede invalidarse

   c) **Cerrar loading dialog** (líneas 67-69):
      ```dart
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      ```

      **rootNavigator: true**:
      - Pop del navigator raíz (el dialog está en overlay global)
      - **Sin rootNavigator**: Intentaría pop de navigator local

      **Try-catch defensivo**:
      - Si falla pop: ignora (dialog ya cerrado posiblemente)

   d) **Post-frame callback para snackbar** (líneas 70-76):
      ```dart
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final newL10n = context.l10n;
          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: newL10n.settingsUpdated
          );
        } else {}
      });
      ```

      **addPostFrameCallback**:
      - Ejecuta después del siguiente frame
      - **Propósito**: Esperar a que la app se reconstruya con nuevo idioma

      **Mounted check interno**:
      - Doble verificación antes de mostrar snackbar

      **newL10n**:
      - `context.l10n` después del cambio
      - **Texto en nuevo idioma**: "Configuración actualizada" en el idioma nuevo

      **showSnackBar**:
      - Feedback de éxito
      - message: Localizado en nuevo idioma

      **Empty else**:
      - `else {}` vacío
      - **Code smell**: Podría omitirse

4. **Manejo de errores** (líneas 78-87):
   ```dart
   catch (e) {
     if (context.mounted) {
       try {
         Navigator.of(context, rootNavigator: true).pop();

         final errL10n = context.l10n;
         PlatformDialogHelpers.showSnackBar(
           context: context,
           message: errL10n.errorUpdatingSettings,
           isError: true
         );
       } catch (_) {}
     } else {}
   }
   ```

   **Mounted check** (línea 79):
   - Verifica context antes de cerrar dialog

   **Cerrar loading dialog** (líneas 80-81):
   - Mismo pattern que en success

   **errL10n** (línea 83):
   - context.l10n actual (idioma no cambió si falló)

   **showSnackBar error** (líneas 84-87):
   - message: "Error al actualizar configuración"
   - **isError: true**: Estilo de error (rojo)

   **Try-catch exterior** (línea 80):
   - Protege contra fallos al cerrar dialog o mostrar snackbar

## 6. PROVIDERS UTILIZADOS

### localeNotifierProvider (líneas 17, 36, 54)
**Tipo**: StateNotifierProvider<LocaleNotifier, Locale>
**Propósito**: Gestiona el locale actual de la app

**Acceso al notifier** (línea 17, 54):
```dart
ref.read(localeNotifierProvider.notifier)
```
- Solo lectura del notifier (no reactivo)

**Watch del state** (línea 36):
```dart
ref.watch(localeNotifierProvider)
```
- Observa cambios en el locale
- Reactivo: Rebuild cuando cambia

**Métodos del notifier**:
- `getAvailableLanguages()`: List<Map<String, dynamic>>
- `setLocale(Locale)`: void

## 7. LOCALIZACIÓN

### Strings localizados:

**Header** (línea 28):
- `l10n.language`: "Idioma" / "Language" / "Idioma"

**Loading dialog** (línea 58):
- `l10n.updating`: "Actualizando..." / "Updating..." / "Actualitzant..."

**Success snackbar** (línea 73):
- `newL10n.settingsUpdated`: "Configuración actualizada" (en idioma nuevo)

**Error snackbar** (línea 84):
- `errL10n.errorUpdatingSettings`: "Error al actualizar configuración"

## 8. CARACTERÍSTICAS TÉCNICAS

### 8.1. ConsumerWidget (Riverpod)

**Acceso a ref**:
```dart
class LanguageSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref disponible aquí
  }
}
```

**Diferencia con StatelessWidget**:
- ConsumerWidget: Acceso a Riverpod state
- StatelessWidget: Sin acceso a providers

### 8.2. ref.read vs ref.watch

**ref.read** (usado para notifier):
```dart
final notifier = ref.read(localeNotifierProvider.notifier);
```
- Solo lectura
- No reactivo (no causa rebuilds)
- Para acceder a métodos del notifier

**ref.watch** (usado para state):
```dart
final currentLocale = ref.watch(localeNotifierProvider);
```
- Observa cambios
- Reactivo (causa rebuilds)
- Para UI que debe actualizarse

### 8.3. Spread operator en map

```dart
...availableLanguages.map((lang) {
  return PlatformWidgets.platformListTile(...);
})
```

**Equivalente sin spread**:
```dart
children: [
  header,
  for (var lang in availableLanguages)
    PlatformWidgets.platformListTile(...),
  divider,
]
```

**Beneficio del spread**: Sintaxis funcional concisa

### 8.4. Cast explícito desde Map

```dart
final locale = lang['locale'] as Locale;
```

**Motivo**: Map es `Map<String, dynamic>`, necesita cast a tipo concreto

**Alternativa type-safe**:
```dart
// En localeNotifier.getAvailableLanguages():
List<LanguageOption> getAvailableLanguages() {
  return [
    LanguageOption(locale: Locale('es'), name: 'Español', flag: '🇪🇸'),
    // ...
  ];
}
```

### 8.5. Post-frame callback

**Pattern**:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  // Código a ejecutar después del frame
});
```

**Uso aquí**: Esperar a que la app se reconstruya con nuevo idioma antes de mostrar snackbar

**Alternativa**:
```dart
Future.delayed(Duration(milliseconds: 300), () {
  // Mostrar snackbar
});
```

### 8.6. rootNavigator: true

```dart
Navigator.of(context, rootNavigator: true).pop();
```

**Propósito**: Pop del navigator raíz

**Sin rootNavigator**:
- Pop del navigator más cercano en el árbol
- Falla si el dialog está en overlay global

**Con rootNavigator**:
- Pop del navigator global (app-level)
- Cierra dialogs mostrados con showDialog

### 8.7. Try-catch anidados múltiples

**Estructura**:
```dart
try {
  showDialog();
} catch (e) {
  return;
}

try {
  setLocale();

  if (mounted) {
    try {
      pop();
    } catch (_) {}
  }
} catch (e) {
  if (mounted) {
    try {
      pop();
      showSnackBar();
    } catch (_) {}
  }
}
```

**Defensivo**: Múltiples niveles de protección contra errores

**Code smell**: Quizás demasiado defensivo

**Alternativa más limpia**:
```dart
Future<void> _changeLanguage(...) async {
  if (!await _showLoadingDialog()) return;

  try {
    await localeNotifier.setLocale(locale);
    await _dismissDialog();
    await _showSuccessSnackbar();
  } catch (e) {
    await _dismissDialog();
    await _showErrorSnackbar(e);
  }
}
```

### 8.8. Empty else blocks

```dart
if (context.mounted) {
  // código
} else {}
```

**Code smell**: else vacío es innecesario

**Mejor omitir**:
```dart
if (context.mounted) {
  // código
}
```

### 8.9. Color adaptativo para check icon

```dart
color: isIOS
  ? CupertinoColors.activeBlue.resolveFrom(context)
  : AppStyles.blue600
```

**iOS**: Usa color nativo de Cupertino (se adapta a dark mode)
**Android**: Usa color custom de AppStyles

**resolveFrom(context)**:
- Resuelve color según brightness (light/dark mode)
- API de Cupertino

## 9. CASOS DE USO

### 9.1. En pantalla de settings

```dart
Column(
  children: [
    // ... otras settings
    LanguageSelector(),
    // ... más settings
  ],
)
```

### 9.2. En drawer

```dart
Drawer(
  child: ListView(
    children: [
      // ... menu items
      LanguageSelector(),
    ],
  ),
)
```

### 9.3. En onboarding

```dart
// Step 1: Seleccionar idioma
OnboardingStep(
  title: 'Elige tu idioma',
  child: LanguageSelector(),
)
```

## 10. TESTING

### 10.1. Test de lista de idiomas

```dart
testWidgets('shows all available languages', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: LanguageSelector()),
      ),
    ),
  );

  expect(find.text('Español'), findsOneWidget);
  expect(find.text('English'), findsOneWidget);
  expect(find.text('Català'), findsOneWidget);
});
```

### 10.2. Test de selección

```dart
testWidgets('marks selected language', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeNotifierProvider.overrideWith((ref) => LocaleNotifier(Locale('es'))),
      ],
      child: MaterialApp(
        home: Scaffold(body: LanguageSelector()),
      ),
    ),
  );

  // Solo el idioma seleccionado debe tener check icon
  expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
});
```

### 10.3. Test de cambio de idioma

```dart
testWidgets('changes language on tap', (tester) async {
  final container = ProviderContainer();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(body: LanguageSelector()),
      ),
    ),
  );

  // Tap en English
  await tester.tap(find.text('English'));
  await tester.pumpAndSettle();

  // Verificar que locale cambió
  expect(
    container.read(localeNotifierProvider),
    Locale('en'),
  );
});
```

## 11. POSIBLES MEJORAS (NO implementadas)

### 11.1. Loading state durante cambio

```dart
final _isChanging = ref.watch(isChangingLocaleProvider);

return _isChanging
  ? Center(child: CircularProgressIndicator())
  : Column(...);
```

### 11.2. Confirmación antes de cambiar

```dart
onTap: () async {
  final confirmed = await showConfirmDialog(
    'Cambiar idioma a $name?',
  );
  if (confirmed) {
    _changeLanguage(context, ref, locale);
  }
}
```

### 11.3. Separar idiomas por región

```dart
'Español (España)',
'Español (México)',
'Español (Argentina)',
```

### 11.4. Preview del idioma

```dart
// Mostrar texto ejemplo en el idioma
subtitle: Text(
  'Ejemplo de texto en este idioma',
  style: TextStyle(fontStyle: FontStyle.italic),
)
```

### 11.5. Detectar idioma del sistema

```dart
FutureBuilder(
  future: _getDeviceLocale(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Badge(
        label: Text('Recomendado'),
        child: ListTile(...),
      );
    }
    return ListTile(...);
  },
)
```

## 12. RESUMEN

**Propósito**: Selector de idioma con lista de opciones disponibles, marca el seleccionado y cambia el idioma con feedback

**Características clave**:
- Lista de idiomas con banderas (emoji)
- Check icon en idioma seleccionado
- Bold en idioma seleccionado
- Color adaptativo del check (iOS vs Android)
- Loading dialog durante cambio
- Success snackbar en nuevo idioma
- Error snackbar si falla
- Post-frame callback para timing correcto
- Multiple mounted checks
- Try-catch defensivo múltiple

**Providers**:
- localeNotifierProvider (read para notifier, watch para state)

**Layout**: Header + ListTiles de idiomas + Divider

**Uso**: Settings screen, Drawer, Onboarding

**Patrón**: ConsumerWidget con ref.read/watch para Riverpod state management

---

**Fin de la documentación de language_selector.dart**
