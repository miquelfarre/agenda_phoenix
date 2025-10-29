
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event.dart';
import '../../models/user.dart';
import '../../models/group.dart';
import '../../models/calendar.dart';
import '../../models/event_interaction.dart';
import '../../services/navigation_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/config_service.dart';
import '../../services/api_client.dart';
import '../../services/logo_service.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/subscription_repository.dart';
import '../../repositories/group_repository.dart';
import '../../repositories/calendar_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/user_blocking_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import '../notifiers/locale_notifier.dart';

// --- Authentication --- //

final authServiceProvider = Provider<SupabaseAuthService>((ref) {
  final authService = SupabaseAuthService();
  // ref.onDispose(() => authService.dispose()); // SupabaseAuthService does not have a dispose method
  return authService;
});

final authStateProvider = StreamProvider<supabase_flutter.AuthState>((ref) {
  return SupabaseAuthService.authStateChanges;
});

// --- Services ---

final configServiceProvider = Provider<ConfigService>((ref) => ConfigService.instance);
final navigationServiceProvider = Provider<NavigationService>((ref) => NavigationService());
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// --- Repositories ---

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final repository = EventRepository();
  ref.onDispose(() => repository.dispose());
  repository.initialize();
  return repository;
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final repository = SubscriptionRepository();
  ref.onDispose(() => repository.dispose());
  repository.initialize();
  return repository;
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final repository = GroupRepository();
  ref.onDispose(() => repository.dispose());
  repository.initialize();
  return repository;
});

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final repository = CalendarRepository();
  ref.onDispose(() => repository.dispose());
  repository.initialize();
  return repository;
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final repository = UserRepository();
  ref.onDispose(() => repository.dispose());
  repository.initialize();
  return repository;
});

final userBlockingRepositoryProvider = Provider<UserBlockingRepository>((ref) {
  final repository = UserBlockingRepository();
  ref.onDispose(() => repository.dispose());
  repository.initialize();
  return repository;
});

// --- Locale Provider ---

final localeProvider = localeNotifierProvider;

// --- Logo Provider ---

final logoPathProvider = FutureProvider.family<String?, int>((ref, userId) async {
  return await LogoService.instance.getLogoPath(userId);
});


// --- Data Streams ---

final eventsStreamProvider = StreamProvider<List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.eventsStream;
});

final subscriptionsStreamProvider = StreamProvider<List<User>>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.subscriptionsStream;
});

final groupsStreamProvider = StreamProvider<List<Group>>((ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.groupsStream;
});

final calendarsStreamProvider = StreamProvider<List<Calendar>>((ref) {
  final repository = ref.watch(calendarRepositoryProvider);
  return repository.calendarsStream;
});

final currentUserStreamProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.currentUserStream;
});

final blockedUsersStreamProvider = StreamProvider<List<User>>((ref) {
  final repository = ref.watch(userBlockingRepositoryProvider);
  return repository.blockedUsersStream;
});

final eventInteractionsStreamProvider = StreamProvider<List<EventInteraction>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.interactionsStream;
});

// Alias for backwards compatibility
final eventInteractionsProvider = eventInteractionsStreamProvider;
final subscriptionsProvider = subscriptionsStreamProvider;
final eventServiceProvider = eventRepositoryProvider;
final eventInteractionRepositoryProvider = eventRepositoryProvider;


// --- Notifications (example, might need its own repository) ---

// final notificationsProvider = StateNotifierProvider<NotificationNotifier, List<Notification>>((ref) {
//   return NotificationNotifier();
// });

// class NotificationNotifier extends StateNotifier<List<Notification>> {
//   NotificationNotifier() : super([]);

//   void add(Notification notification) {
//     state = [...state, notification];
//   }

//   void remove(String id) {
//     state = state.where((n) => n.id != id).toList();
//   }

//   void markAsRead(String id) {
//     state = [
//       for (final notification in state)
//         if (notification.id == id)
//           notification.copyWith(isRead: true)
//         else
//           notification,
//     ];
//   }
// }