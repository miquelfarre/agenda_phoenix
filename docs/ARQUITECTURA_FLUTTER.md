# Principios de Arquitectura - EventyPop Flutter App

## 1. ESTRUCTURA DE DIRECTORIOS Y ORGANIZACIÓN

La aplicación sigue una **arquitectura híbrida basada en features y capas** con clara separación de responsabilidades:

```
lib/
├── config/                 # Configuración y constantes
│   ├── app_constants.dart
│   ├── app_defaults.dart
│   ├── debug_config.dart
│   └── timezone_data.dart
├── core/                   # Lógica central de la aplicación
│   ├── bootstrap/
│   ├── constants/
│   ├── exceptions/
│   ├── mixins/             # Patrones de comportamiento reutilizables
│   ├── navigation/
│   ├── providers/          # Providers centrales de estado
│   ├── services/
│   ├── state/              # Estado global de la app
│   ├── storage/            # Almacenamiento local/persistencia
│   ├── utils/
│   └── realtime_sync.dart  # Orquestación de sincronización en tiempo real
├── models/                 # Modelos de datos (API/Hive)
├── repositories/           # Capa de acceso a datos
├── services/               # Lógica de negocio e integración con API
├── screens/                # Widgets de pantallas/páginas
├── widgets/                # Componentes de UI reutilizables
├── ui/                     # Estilos y temas
│   ├── helpers/
│   ├── styles/
│   └── ...
├── utils/                  # Funciones de utilidad
├── l10n/                   # Localización/internacionalización
├── app.dart                # Widget raíz de la app
└── main.dart               # Punto de entrada
```

**Principios Organizacionales Clave:**
- **Arquitectura en capas**: Config → Core → Models → Repositories → Services → Screens → Widgets
- **Agrupación por features** dentro de screens y widgets
- **Separación de UI (widgets) de lógica (services/repositories)**
- **178 archivos Dart** indicando una base de código bien modularizada

---

## 2. GESTIÓN DE ESTADO: RIVERPOD

La aplicación usa **Flutter Riverpod** (v3.0.1) como solución principal de gestión de estado:

### Providers Clave en `/lib/core/state/app_state.dart`:

```dart
// Service providers
final eventRepositoryProvider = Provider<EventRepository>(...)
final calendarRepositoryProvider = Provider(...)
final subscriptionRepositoryProvider = Provider(...)
final eventInteractionRepositoryProvider = Provider(...)

// Notifier providers para estado mutable
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(...)
final eventStateProvider = NotifierProvider<EventStateNotifier, List<Event>>(...)
final subscriptionsProvider = NotifierProvider<SubscriptionsNotifier, AsyncValue<List<Subscription>>>(...)
final eventInteractionsProvider = NotifierProvider<EventInteractionsNotifier, AsyncValue<List<EventInteraction>>>(...)

// Stream providers para datos en tiempo real
final calendarsStreamProvider = StreamProvider<List<Calendar>>(...)
final groupsStreamProvider = StreamProvider<List<Group>>(...)
final subscriptionsStreamProvider = StreamProvider<List<User>>(...)

// UI state providers
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(...)
```

### Características del Patrón:
- **Notifiers**: Clases personalizadas que extienden `Notifier` o `AsyncNotifier` para estado mutable
- **AsyncValue**: Wrapper para estados de carga/error/éxito
- **StreamProviders**: Para actualizaciones continuas de datos en tiempo real
- **Provider watches**: Actualizaciones reactivas cuando cambian las dependencias
- **ref.listen()**: Para efectos secundarios y estado computado

### Ejemplo de SettingsNotifier:
```dart
class SettingsNotifier extends Notifier<AsyncValue<AppSettings>> {
  @override
  AsyncValue<AppSettings> build() {
    _repository = ref.watch(settingsRepositoryProvider);
    _loadSettings();
    return const AsyncValue.loading();
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = AsyncValue.data(settings);
    try {
      await _repository.saveSettings(settings);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}
```

---

## 3. ARQUITECTURA DE CAPA DE DATOS

La capa de datos sigue un **Patrón Repository** con tres niveles:

### Nivel 1: Modelos (`/lib/models/`)
- **Modelos API**: Clases Dart puras con serialización JSON (ej: `Event`, `User`, `Calendar`)
- **Modelos Hive**: Clases mapeadas a ORM para almacenamiento local con adaptadores `.g.dart` generados
- **Ejemplo**: `Event` + `EventHive`

```dart
@immutable
class Event {
  final int? id;
  final String name;
  final DateTime startDate;
  final int ownerId;
  final Map<String, dynamic>? interactionData;
  // ... más campos

  factory Event.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
  Event copyWith({ ... }) { ... }
}
```

### Nivel 2: Repositories (`/lib/repositories/`)
- **Arquitectura híbrida**: REST API + Real-time Supabase + Caché local Hive
- **Responsabilidades clave:**
  - Obtener datos de API/Supabase
  - Mantener caché local (Hive)
  - Suscribirse a actualizaciones en tiempo real
  - Emitir datos vía Dart Streams

**Ejemplo: EventRepository**
```dart
class EventRepository {
  Box<EventHive>? _box;
  RealtimeChannel? _realtimeChannel;
  final StreamController<List<Event>> _eventsStreamController =
    StreamController<List<Event>>.broadcast();

  Stream<List<Event>> get eventsStream => _eventsStreamController.stream;

  Future<void> initialize() async {
    _box = await Hive.openBox<EventHive>(_boxName);
    _loadEventsFromHive();
    await fetchAndSyncEvents();
    await _startRealtimeSubscription();
    _emitCurrentEvents();
  }

  Future<List<Event>> fetchAndSyncEvents() async {
    final apiData = await ApiClient().fetchUserEvents(userId);
    _cachedEvents = apiData.map((json) => Event.fromJson(json)).toList();
    await _updateLocalCache(_cachedEvents);
    return _cachedEvents;
  }
}
```

### Nivel 3: Services (`/lib/services/`)
- **Capa de lógica de negocio** entre repositories y screens
- **Servicios especializados:**
  - `EventService`: Operaciones CRUD de eventos
  - `CalendarService`: Gestión de calendarios
  - `SubscriptionService`: Suscripciones de usuarios
  - `SyncService`: Orquestación de sincronización compuesta
  - `ApiClient`: Cliente HTTP con headers/auth
  - `SupabaseService`: Wrapper del cliente Supabase
  - `ConfigService`: Gestión de configuración

**Patrón Service (Singleton):**
```dart
class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  Future<Event> createEvent({required String name, ...}) async {
    final response = await _client.createEvent({...});
    return Event.fromJson(response);
  }
}
```

---

## 4. PATRONES DE INYECCIÓN DE DEPENDENCIAS

La app usa **múltiples patrones de DI**:

### Patrón 1: Riverpod Providers (Preferido)
```dart
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final repository = EventRepository();
  repository.initialize();
  ref.onDispose(() => repository.dispose());
  return repository;
});
```

### Patrón 2: Singleton Mixin
```dart
mixin SingletonMixin {
  static final Map<Type, dynamic> _instances = {};

  static T getInstance<T>(T Function() factory) {
    if (!_instances.containsKey(T)) {
      _instances[T] = factory();
    }
    return _instances[T] as T;
  }
}

class ConfigService with SingletonMixin {
  factory ConfigService() => SingletonMixin.getInstance(() => ConfigService._internal());
  static ConfigService get instance => ConfigService();
}
```

### Patrón 3: Service Locator Factory
```dart
abstract class ApiClientFactory {
  static IApiClient? _instance;

  static IApiClient get instance {
    if (_instance == null) {
      throw StateError('ApiClient not initialized');
    }
    return _instance!;
  }

  static void initialize(IApiClient implementation) {
    _instance = implementation;
  }
}
```

### Inicialización en `main.dart`:
```dart
await _initializeSupabase();
await _initializeApiClient();
await Hive.initFlutter();
// Registrar todos los adaptadores Hive...
await SyncService.init();
await ConfigService.instance.initialize();
await GroupService().initialize();
await CalendarService().initialize();

runApp(ProviderScope(child: MyApp(env: env)));
```

---

## 5. PATRONES DE NAVEGACIÓN

Usa **GoRouter** (v16.2.4) para routing declarativo:

### Estructura de Rutas (`/lib/core/navigation/app_router.dart`):
```dart
class AppRouter {
  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: _redirect,
    routes: [
      GoRoute(path: '/splash', name: 'splash', builder: (...) => SplashScreen()),
      GoRoute(path: '/login', name: 'login', builder: (...) => PhoneLoginScreen()),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          GoRoute(path: '/events', name: 'events', builder: (...) => EventsScreen(),
            routes: [
              GoRoute(path: 'create', name: 'event-create', ...),
              GoRoute(path: ':eventId', name: 'event-detail', ...),
            ]
          ),
          GoRoute(path: '/subscriptions', name: 'subscriptions', ...),
          GoRoute(path: '/communities', name: 'communities', ...),
          GoRoute(path: '/settings', name: 'settings', ...),
        ]
      ),
    ]
  );
}
```

**Características:**
- **ShellRoute** para persistencia de navegación inferior
- **Rutas anidadas** para navegación jerárquica
- **Lógica de redirección de rutas** para guards de autenticación
- **Parámetros de ruta type-safe** con parsing
- **Rutas nombradas** para referencia fácil

### Lógica de Auth Guard:
```dart
static String? _redirect(BuildContext context, GoRouterState state) {
  final configService = ConfigService.instance;
  final isSupabaseAuthenticated = SupabaseAuthService.currentUser != null;
  final isAuthenticated = _checkAuthentication(configService.isTestMode, isSupabaseAuthenticated);

  if (['/splash', '/login', '/access-denied'].contains(state.uri.path)) {
    return null;
  }

  if (!isAuthenticated) {
    return '/login';
  }

  return null;
}
```

---

## 6. ENFOQUE DE INTEGRACIÓN API/BACKEND

### Arquitectura Multi-Fuente:

**1. REST API (`/lib/services/api_client.dart`)**
```dart
class ApiClient implements IApiClient {
  final http.Client _client = http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    // Modo test: usar header X-Test-User-Id
    if (configService.isTestMode && configService.currentUserId != 0) {
      headers['X-Test-User-Id'] = configService.currentUserId.toString();
    }

    // Producción: usar JWT de Supabase
    final session = SupabaseService.instance.client.auth.currentSession;
    if (session != null && session.accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    return headers;
  }

  Uri _buildUri(String path, {Map<String, dynamic>? queryParams}) {
    final normalizedPath = path.startsWith('/api/v1') ? path : '/api/v1$path';
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$normalizedPath');
    if (queryParams != null) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }
}
```

**2. Supabase Real-time (`/lib/services/supabase_service.dart`)**
```dart
class SupabaseService {
  static SupabaseClient? _client;

  static Future<void> initialize({required String supabaseUrl, required String supabaseAnonKey}) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 10),
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client { ... }
}
```

**3. Suscripciones Real-time con Change Data Capture (CDC)**
```dart
// En SubscriptionRepository
Future<void> _startRealtimeSubscription() async {
  _realtimeChannel = RealtimeUtils.subscribeTable(
    client: _supabaseService.client,
    schema: 'public',
    table: 'event_interactions',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: userId.toString()
    ),
    onChange: _handleSubscriptionChange,
  );
}

void _handleSubscriptionChange(PostgresChangePayload payload) {
  if (payload.eventType == PostgresChangeEvent.delete) {
    if (_rt.shouldProcessDelete()) {
      _fetchAndSync().then((_) => _emitCurrentSubscriptions());
    }
  } else if (payload.eventType == PostgresChangeEvent.insert ||
             payload.eventType == PostgresChangeEvent.update) {
    if (_rt.shouldProcessInsertOrUpdate(commitTsUtc)) {
      _fetchAndSync().then((_) => _emitCurrentSubscriptions());
    }
  }
}
```

**4. Configuración de Base URL (Consciente del entorno)**
```dart
static String get apiBaseUrl {
  switch (currentEnvironment) {
    case Environment.development:
      return 'http://localhost:8001';
    case Environment.staging:
      return 'https://staging-api.eventypop.com';
    case Environment.production:
      return 'https://api.eventypop.com';
  }
}
```

---

## 7. PATRONES DE DISEÑO NOTABLES

### Patrón 1: Repository Pattern con Streams
Los repositorios exponen **Stream<T>** para actualizaciones reactivas de UI:
```dart
class EventRepository {
  final StreamController<List<Event>> _eventsStreamController =
    StreamController<List<Event>>.broadcast();

  Stream<List<Event>> get eventsStream => _eventsStreamController.stream;

  void _emitCurrentEvents() {
    if (!_eventsStreamController.isClosed) {
      _eventsStreamController.add(List.from(_cachedEvents));
    }
  }
}
```

### Patrón 2: Composición basada en Mixins
Comportamiento reutilizable a través de mixins:
```dart
mixin ErrorHandlingMixin {
  Future<T> withErrorHandling<T>(
    String operationName,
    Future<T> Function() operation,
    {T? defaultValue}
  ) async {
    try {
      return await operation();
    } catch (e) {
      if (defaultValue != null) return defaultValue;
      rethrow;
    }
  }
}

class BaseService with ErrorHandlingMixin {
  Future<T> executeWhenInitialized<T>(String operationName, Future<T> Function() operation) async {
    requireInitialized();
    return await withErrorHandling(operationName, operation);
  }
}
```

### Patrón 3: Real-time Sync Guard (Filtrado Temporal)
```dart
class RealtimeSync {
  DateTime _serverSyncTs = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  void setServerSyncTs(DateTime tsUtc) {
    _serverSyncTs = tsUtc.toUtc();
  }

  bool shouldProcessInsertOrUpdate(DateTime? commitTsUtc, {Duration margin = const Duration(seconds: 1)}) {
    if (commitTsUtc == null) return true;
    return commitTsUtc.isAfter(_serverSyncTs.add(margin));
  }

  bool shouldProcessDelete() => true;
}
```
Esto previene procesamiento duplicado cuando los fetches de REST API se intercalan con actualizaciones Realtime.

### Patrón 4: Modelos Inmutables con copyWith()
```dart
@immutable
class Event {
  final int? id;
  final String name;
  final DateTime startDate;

  Event copyWith({
    int? id,
    String? name,
    DateTime? startDate,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
    );
  }
}
```

### Patrón 5: Consumer/Watcher Pattern
```dart
class EventsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventStateProvider);
    final subscriptions = ref.watch(subscriptionsProvider);

    ref.listen<List<Event>>(eventStateProvider, (previous, next) {
      if (previous?.length != next.length) {
        _refresh();
      }
    });
  }
}
```

### Patrón 6: Inicialización Asíncrona con ProviderScope
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeSupabase();
  await _initializeApiClient();
  // ... más inicialización

  runApp(ProviderScope(child: MyApp(env: env)));
}
```

### Patrón 7: UI Adaptativa a Plataforma
```dart
class AdaptiveApp extends StatelessWidget {
  final String title;

  const AdaptiveApp.router({
    required this.routerConfig,
    required this.title,
    ...
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformDetection.isIOS) {
      return CupertinoApp.router(...);
    } else if (PlatformDetection.isAndroid) {
      return MaterialApp.router(...);
    } else {
      return MaterialApp.router(...);
    }
  }
}
```

### Patrón 8: Patrón Contract/Interface
```dart
abstract class IApiClient {
  Future<List<Map<String, dynamic>>> fetchEvents();
  Future<List<Map<String, dynamic>>> searchPublicUsers(String query);
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams});
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body});
  // ... más métodos
}

class ApiClient implements IApiClient { ... }
```

---

## 8. ALMACENAMIENTO Y PERSISTENCIA

### Hive para Caché Local:
```dart
// En main.dart
await Hive.initFlutter();
Hive.registerAdapter(EventHiveAdapter());
Hive.registerAdapter(CalendarHiveAdapter());

await Hive.openBox<EventHive>('events');
await Hive.openBox<CalendarHive>('calendars');
```

### Conversión de Modelos (API <-> Hive):
```dart
class EventHive {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  Event toEvent() {
    return Event(id: id, name: name, ...);
  }
}
```

---

## 9. CONFIGURACIÓN Y GESTIÓN DE ENTORNOS

### Configuración multi-entorno:
```dart
enum Environment { development, staging, production }

class AppConfig {
  static Environment get currentEnvironment {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    // ... lógica switch
  }

  static String get apiBaseUrl { ... }
  static bool get enableDebugLogs => currentEnvironment != Environment.production;
}

class AppConstants {
  static const int maxEventTitleLength = 100;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  // ... más constantes
}
```

### Soporte de Modo Test:
```dart
class ConfigService {
  bool _isTestMode = false;
  String? _testToken;

  void enableTestMode() {
    final validationResult = TestModeValidator.validateTestModeActivation();
    if (!validationResult.isValid) throw Exception(...);
    _isTestMode = true;
  }
}
```

---

## 10. INTERNACIONALIZACIÓN (i18n)

### Usando formato ARB:
```dart
// l10n/app_en.arb, l10n/app_es.arb
// Auto-generado: l10n/app_localizations.dart

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(localeProvider),
    );
  }
}
```

---

## 11. ESTRUCTURA DE SCREENS/PÁGINAS

### Ejemplo: EventsScreen (Consumer Stateful Widget Complejo)
```dart
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen();

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  late StreamSubscription<List<Event>> _eventsSubscription;
  EventRepository? _eventRepository;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    _eventRepository = ref.read(eventRepositoryProvider);
    _eventsSubscription = _eventRepository!.eventsStream.listen((events) {
      _buildEventsDataFromRepository(events);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usar Consumer o ref.watch() para actualizaciones reactivas
  }
}
```

---

## 12. MANEJO DE ERRORES

### Jerarquía Centralizada de Excepciones:
```dart
// En core/exceptions/
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class ValidationException extends AppException {
  const ValidationException(String message) : super(message);
}

class AuthException extends AppException {
  const AuthException(String message) : super(message);
}
```

### Manejo de Errores en Services:
```dart
class BaseService with ErrorHandlingMixin {
  Future<T> executeWhenInitialized<T>(
    String operationName,
    Future<T> Function() operation
  ) async {
    requireInitialized();
    return await withErrorHandling(operationName, operation);
  }

  Never logAndRethrow(String context, Object error, [StackTrace? stackTrace]) {
    throw error;
  }
}
```

---

## 13. RESUMEN DE FORTALEZAS ARQUITECTÓNICAS

| Aspecto | Patrón | Beneficio |
|--------|---------|---------|
| **Gestión de Estado** | Riverpod Notifiers + Streams | UI reactiva, inyección de dependencias, testing |
| **Capa de Datos** | Repository + REST + Realtime | Offline-first, cache-aware, sincronización en tiempo real |
| **DI** | Mixto (Riverpod + Singleton + Factory) | Flexibilidad, testabilidad, acceso global |
| **Navegación** | GoRouter con ShellRoute | Declarativo, type-safe, navegación persistente |
| **Integración API** | Multi-fuente (REST + Supabase Realtime) | Redundancia, capacidades en tiempo real |
| **Organización de Código** | Por capas + Por features | Escalabilidad, mantenibilidad |
| **Modelos** | Inmutables con copyWith() | Predecibilidad, debugging |
| **Persistencia** | Hive ORM | Caché local rápida, type-safe |
| **Soporte de Plataforma** | UI Adaptativa (iOS/Android) | Consistencia cross-platform |
| **Testing** | Patrón Contract/Interface | Servicios mockables, testeables |

---

## 14. ARCHIVOS CLAVE DE REFERENCIA

| Ruta del Archivo | Propósito |
|-----------|---------|
| `/lib/main.dart` | Inicialización de app, setup Hive, init de servicios |
| `/lib/app.dart` | Widget raíz de la app con providers |
| `/lib/core/state/app_state.dart` | Providers centrales de Riverpod |
| `/lib/core/navigation/app_router.dart` | Configuración de GoRouter |
| `/lib/repositories/*` | Capa de acceso a datos (basada en Streams) |
| `/lib/services/api_client.dart` | Cliente HTTP con auth/headers |
| `/lib/services/supabase_service.dart` | Wrapper del cliente Supabase |
| `/lib/core/realtime_sync.dart` | Filtrado temporal para Realtime |
| `/lib/core/mixins/*.dart` | Patrones de comportamiento reutilizables |
| `/lib/widgets/adaptive/*` | Componentes adaptativos a plataforma |
| `/lib/screens/*` | Widgets de nivel página |

---

Esta arquitectura demuestra una **aplicación Flutter de grado de producción** con:
- Gestión de estado reactiva moderna (Riverpod)
- Capa de datos sofisticada con caché offline-first
- Sincronización en tiempo real con guards temporales
- Soporte multi-plataforma con UI adaptativa
- Fuerte separación de responsabilidades y testabilidad
