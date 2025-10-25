import 'dart:ui' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/event.dart';
import '../../models/subscription.dart';
import '../../models/event_interaction.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../services/user_blocking_service.dart';
import '../../services/event_service.dart';
import '../../services/subscription_service.dart';
import '../../services/event_interaction_service.dart';
import '../../services/sync_service.dart';
import '../../services/config_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/logo_service.dart';
import '../../services/api_client.dart';
import '../../repositories/event_repository.dart';
import '../../services/calendar_service.dart';
import '../../services/group_service.dart';
import 'dart:async';

class AuthState {
  final User? currentUser;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.currentUser,
    required this.isAuthenticated,
    this.isLoading = false,
    this.error,
  });

  String? get userLogoPath => currentUser?.id != null ? null : null;

  AuthState copyWith({
    User? currentUser,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    try {
      final configService = ConfigService.instance;
      bool isAuth;

      if (configService.isTestMode) {
        isAuth = true;
      } else {
        isAuth = SupabaseAuthService.isLoggedIn;
      }

      final user = await UserService.getCurrentUser();

      return AuthState(
        currentUser: user,
        isAuthenticated: isAuth,
        isLoading: false,
      );
    } catch (e) {
      return AuthState(
        currentUser: null,
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentState =
          state.value ?? const AuthState(isAuthenticated: false);

      final user = await UserService.getCurrentUser();

      final configService = ConfigService.instance;
      final isAuth = configService.isTestMode || SupabaseAuthService.isLoggedIn;

      return currentState.copyWith(
        currentUser: user,
        isAuthenticated: isAuth,
        isLoading: false,
      );
    });
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final repository = EventRepository();
  repository.initialize();
  ref.onDispose(() => repository.dispose());
  return repository;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final eventServiceProvider = Provider<EventService>((ref) => EventService());
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) => SubscriptionService());
final eventInteractionServiceProvider = Provider<EventInteractionService>((ref) => EventInteractionService());
final calendarServiceProvider = Provider<CalendarService>((ref) => CalendarService());
final groupServiceProvider = Provider<GroupService>((ref) => GroupService());
final userServiceProvider = Provider<UserService>((ref) => UserService());

final logoPathProvider = FutureProvider.family<String?, int>((ref, userId) {
  return LogoService.instance.getLogoPath(userId);
});

final eventStateProvider = NotifierProvider<EventStateNotifier, List<Event>>(
  EventStateNotifier.new,
);

class EventStateNotifier extends Notifier<List<Event>> {
  EventService get _eventService => ref.read(eventServiceProvider);

  @override
  List<Event> build() {
    Future.microtask(() => refresh());

    return [];
  }

  Future<void> refresh() async {
    try {
      final userId = ConfigService.instance.currentUserId;

      if (userId > 0) {
        await SyncService.syncEvents();
      } else {}

      final events = SyncService.getLocalEvents();

      events.sort((a, b) => a.startDate.compareTo(b.startDate));

      state = events;
    } catch (error) {
      final errorString = error.toString();
      if (errorString.contains('Authentication token required') ||
          errorString.contains('401') ||
          errorString.contains('Unauthorized')) {
      } else {}

      state = [];
    }
  }

  Map<DateTime, List<Event>> aggregated() {
    final grouped = <DateTime, List<Event>>{};

    for (final event in state) {
      final date = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      grouped.putIfAbsent(date, () => []).add(event);
    }

    return grouped;
  }

  Future<void> createEvent(Event event) async {
    await _eventService.createEvent(
      name: event.name,
      description: event.description,
      startDate: event.startDate,
      eventType: event.eventType,
      calendarId: event.calendarId,
    );
    await refresh();
  }

  Future<void> updateEvent(Event event) async {
    await _eventService.updateEvent(
      eventId: event.id!,
      name: event.name,
      description: event.description,
      startDate: event.startDate,
      eventType: event.eventType,
      calendarId: event.calendarId,
    );
    await refresh();
  }

  Future<void> deleteEvent(int eventId) async {
    await _eventService.deleteEvent(eventId);
    await refresh();
  }

  Future<void> refreshIfNeeded() async {
    await refresh();
  }
}

final subscriptionsProvider =
    NotifierProvider<SubscriptionsNotifier, AsyncValue<List<Subscription>>>(
      SubscriptionsNotifier.new,
    );

class SubscriptionsNotifier extends Notifier<AsyncValue<List<Subscription>>> {
  SubscriptionService get _subscriptionService => ref.read(subscriptionServiceProvider);

  @override
  AsyncValue<List<Subscription>> build() {
    _loadSubscriptions();
    return const AsyncValue.loading();
  }

  Future<void> _loadSubscriptions() async {
    try {
      state = const AsyncValue.loading();

      final userId = ConfigService.instance.currentUserId;

      final subscriptionsData = await ref.read(apiClientProvider).fetchUserSubscriptions(userId);

      final subscriptions = subscriptionsData.map((userData) {
        final user = User.fromJson(userData);
        return Subscription(
          id: user.id,
          userId: userId,
          subscribedToId: user.id,
          subscribed: user,
        );
      }).toList();

      state = AsyncValue.data(subscriptions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() => _loadSubscriptions();

  Future<void> clearCacheAndRefresh() async {
    try {
      state = const AsyncValue.loading();
      await refresh();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createSubscription(Subscription subscription) async {
    try {
      await _subscriptionService.createSubscription(
        targetUserId: subscription.subscribedToId,
        targetUser: subscription.subscribed,
      );
      await refresh();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteSubscription(int subscriptionId) async {
    try {
      await _subscriptionService.deleteSubscription(
        subscriptionId: subscriptionId,
      );
      await refresh();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeSubscription(int subscriptionId, int userId) async {
    try {
      await _subscriptionService.deleteSubscription(
        subscriptionId: subscriptionId,
      );
      await refresh();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final eventInteractionsProvider =
    NotifierProvider<
      EventInteractionsNotifier,
      AsyncValue<List<EventInteraction>>
    >(EventInteractionsNotifier.new);

class EventInteractionsNotifier
    extends Notifier<AsyncValue<List<EventInteraction>>> {
  EventInteractionService get _interactionService => ref.read(eventInteractionServiceProvider);

  @override
  AsyncValue<List<EventInteraction>> build() {
    _loadInteractions();
    return const AsyncValue.loading();
  }

  Future<void> _loadInteractions() async {
    try {
      state = const AsyncValue.loading();

      final interactions = _interactionService.getAllInteractions();
      state = AsyncValue.data(interactions);

      final userId = ConfigService.instance.currentUserId;

      if (userId > 0) {
        await SyncService.syncEventInteractions(userId);

        final updatedInteractions = _interactionService.getAllInteractions();
        state = AsyncValue.data(updatedInteractions);
      }
    } catch (error, stackTrace) {
      if (error.toString().contains('Authentication token required') ||
          error.toString().contains('401') ||
          error.toString().contains('Unauthorized')) {
        final localInteractions = _interactionService.getAllInteractions();
        state = AsyncValue.data(localInteractions);
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> refresh() => _loadInteractions();

  EventInteraction? getInteraction(int eventId) {
    if (state.value == null) return null;

    try {
      return state.value!.firstWhere((i) => i.eventId == eventId);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateParticipationStatus(
    int eventId,
    String status, {
    String? decisionMessage,
    bool? isAttending,
  }) async {
    try {
      await _interactionService.updateParticipationStatus(
        eventId,
        status,
        decisionMessage: decisionMessage,
        isAttending: isAttending,
      );
      await refresh();
      ref.read(eventStateProvider.notifier).refresh();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> markAsViewed(int eventId) async {
    try {
      await _interactionService.markAsViewed(eventId);
      await refresh();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> toggleFavorite(int eventId) async {
    try {
      await _interactionService.toggleFavorite(eventId);
      await refresh();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> setPersonalNote(int eventId, String note) async {
    try {
      await _interactionService.setPersonalNote(eventId, note);
      await refresh();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> sendInvitation(
    int eventId,
    int invitedUserId, {
    String? invitationMessage,
  }) async {
    try {
      await _interactionService.sendInvitation(
        eventId,
        invitedUserId,
        invitationMessage: invitationMessage,
      );
      await refresh();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

class BlockedUsersNotifier extends Notifier<AsyncValue<List<User>>> {
  @override
  AsyncValue<List<User>> build() {
    _loadBlockedUsers();
    return const AsyncValue.loading();
  }

  Future<void> _loadBlockedUsers() async {
    try {
      state = const AsyncValue.loading();
      final userId = ConfigService.instance.currentUserId;
      final blockedUsers = await UserBlockingService().getBlockedUsers(userId);
      state = AsyncValue.data(blockedUsers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() => _loadBlockedUsers();

  Future<void> blockUser(int userId) async {
    try {
      final currentUserId = ConfigService.instance.currentUserId;
      await UserBlockingService().blockUser(currentUserId, userId);
      await refresh();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> unblockUser(int userId) async {
    try {
      final currentUserId = ConfigService.instance.currentUserId;
      await UserBlockingService().unblockUser(currentUserId, userId);
      await refresh();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final blockedUsersProvider =
    NotifierProvider<BlockedUsersNotifier, AsyncValue<List<User>>>(
      BlockedUsersNotifier.new,
    );

final publicUsersSearchProvider =
    NotifierProvider<PublicUsersSearchNotifier, AsyncValue<List<User>>>(
      PublicUsersSearchNotifier.new,
    );

class PublicUsersSearchNotifier extends Notifier<AsyncValue<List<User>>> {
  @override
  AsyncValue<List<User>> build() {
    return const AsyncValue.data([]);
  }

  Future<void> searchPublicUsers(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final users = await UserService.searchPublicUsers(query);
      state = AsyncValue.data(users);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}

class AppState {
  final AsyncValue<List<Event>> events;
  final AsyncValue<List<Subscription>> subscriptions;

  const AppState({required this.events, required this.subscriptions});
}

final appStateProvider = Provider<AppState>((ref) {
  return AppState(
    events: AsyncValue.data(ref.watch(eventStateProvider)),
    subscriptions: ref.watch(subscriptionsProvider),
  );
});

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  static const String _languageKey = 'language_code';
  static const String _countryKey = 'country_code';

  @override
  Locale build() {
    _initialize();
    return const Locale('en', 'US');
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    final countryCode = prefs.getString(_countryKey);

    if (languageCode != null) {
      state = Locale(languageCode, countryCode ?? 'US');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;

    state = locale;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
    await prefs.setString(_countryKey, locale.countryCode ?? '');
  }

  List<Map<String, dynamic>> getAvailableLanguages() {
    return [
      {'locale': const Locale('en', 'US'), 'name': 'English', 'flag': '🇺🇸'},
      {'locale': const Locale('es', 'ES'), 'name': 'Español', 'flag': '🇪🇸'},
    ];
  }
}

final publicUserEventsProvider = FutureProvider.family<List<Event>, int>((ref, userId) async {
  try {
    final eventsData = await ref.read(apiClientProvider).fetchUserEvents(userId);
    return eventsData.map((data) => Event.fromJson(data)).toList();
  } catch (e) {
    rethrow;
  }
});

class AggregatedEventsNotifier extends Notifier<AsyncValue<List<Event>>> {
  @override
  AsyncValue<List<Event>> build() {
    _loadEvents();

    ref.listen<List<Event>>(eventStateProvider, (previous, next) {
      if (previous?.length != next.length) {
        refresh();
      }
    });

    return const AsyncValue.loading();
  }

  Future<void> _loadEvents() async {
    try {
      state = const AsyncValue.loading();
      final currentUserId = ConfigService.instance.currentUserId;
      final allEvents = <Event>{};

      final eventRepository = ref.read(eventRepositoryProvider);
      final allLocalEvents = eventRepository.getLocalEvents();

      final ownEvents = allLocalEvents.where((e) => e.ownerId == currentUserId);
      allEvents.addAll(ownEvents);

      final subscriptionsResult = ref.read(subscriptionsProvider);
      final subscriptions = subscriptionsResult.maybeWhen(
        data: (data) => data,
        orElse: () => const <Subscription>[],
      );
      final subscribedUserIds = subscriptions
          .where((sub) => sub.userId == currentUserId)
          .map((sub) => sub.subscribedToId)
          .toSet();

      for (final subscribedUserId in subscribedUserIds) {
        try {
          final userEvents = await ref.read(
            publicUserEventsProvider(subscribedUserId).future,
          );

          final newEvents = userEvents.where(
            (e) => e.ownerId == subscribedUserId && e.ownerId != currentUserId,
          );
          allEvents.addAll(newEvents);
        } catch (e) {
          // Ignore errors
        }
      }

      final sortedEvents = allEvents.toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      state = AsyncValue.data(sortedEvents);
    } catch (e, stackTrace) {
      final errorString = e.toString();
      if (errorString.contains('Authentication token required') ||
          errorString.contains('401') ||
          errorString.contains('Unauthorized')) {
      } else {}
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadEvents();
  }
}

final aggregatedEventsProvider =
    NotifierProvider<AggregatedEventsNotifier, AsyncValue<List<Event>>>(
      AggregatedEventsNotifier.new,
    );

typedef EventFilter = ({String filter, String searchQuery});

final serverFilteredEventsProvider = FutureProvider.family.autoDispose<List<Event>, EventFilter>((ref, filter) async {
  if (filter.searchQuery.isEmpty && filter.filter == 'all') {
    return [];
  }

  final allEvents = await ref.read(eventServiceProvider).fetchEvents();
  return allEvents.where((event) {
    return filter.searchQuery.isEmpty || event.name.toLowerCase().contains(filter.searchQuery.toLowerCase());
  }).toList();
});

final subscribedUserEventsProvider =
    Provider.family<AsyncValue<List<Event>>, int>((ref, subscribedUserId) {
      final events = ref.watch(eventStateProvider);

      final filtered = events
          .where((e) => e.ownerId == subscribedUserId)
          .toList();

      filtered.sort((a, b) => a.date.compareTo(b.date));
      return AsyncValue.data(filtered);
    });
