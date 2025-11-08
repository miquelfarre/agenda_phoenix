import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../ui/helpers/l10n/l10n_helpers.dart';
import '../../services/config_service.dart';
import '../../screens/splash_screen.dart';
import '../../screens/access_denied_screen.dart';
import '../../screens/login/phone_login_screen.dart';
import '../../screens/events_screen.dart';
import '../../screens/subscriptions_screen.dart';
import '../../screens/create_edit_calendar_screen.dart';
import '../../screens/calendars_screen.dart';
import '../../screens/birthdays_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/create_edit_event_screen.dart';
import '../../screens/event_detail_screen.dart';
import '../../screens/people_groups_screen.dart';
import '../../screens/group_detail_screen.dart';
import '../../screens/create_edit_group_screen.dart';
import '../../screens/add_group_members_screen.dart';
import '../../screens/contact_detail_screen.dart';
import '../../services/supabase_auth_service.dart';
import '../navigation/navigation_shell.dart';
import '../../models/event.dart';
import '../../models/group.dart';
import '../../models/user.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: _redirect,
    errorBuilder: (context, state) => _buildErrorPage(context, state),
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: '/access-denied',
        name: 'access-denied',
        builder: (context, state) => const AccessDeniedScreen(),
      ),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          GoRoute(
            path: '/events',
            name: 'events',
            builder: (context, state) => const EventsScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'event-create',
                builder: (context, state) => const CreateEditEventScreen(),
              ),

              GoRoute(
                path: ':eventId',
                name: 'event-detail',
                builder: (context, state) {
                  final eventId = int.tryParse(
                    state.pathParameters['eventId'] ?? '',
                  );
                  if (eventId == null) {
                    return _buildErrorPage(
                      context,
                      state,
                      message: 'Invalid event ID',
                    );
                  }

                  final event =
                      state.extra as Event? ??
                      Event(
                        id: eventId,
                        name: 'Loading...',
                        description: '',
                        startDate: DateTime.now(),
                        ownerId: 0,
                        eventType: 'regular',
                      );

                  return EventDetailScreen(event: event);
                },
              ),
            ],
          ),

          GoRoute(
            path: '/subscriptions',
            name: 'subscriptions',
            builder: (context, state) => SubscriptionsScreen(),
            routes: [],
          ),

          GoRoute(
            path: '/calendars',
            name: 'calendars',
            builder: (context, state) => const CalendarsScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'calendar-create',
                builder: (context, state) => const CreateEditCalendarScreen(),
              ),

              GoRoute(
                path: ':calendarId/edit',
                name: 'calendar-edit',
                builder: (context, state) {
                  final calendarId = state.pathParameters['calendarId'];
                  if (calendarId == null) {
                    return _buildErrorPage(
                      context,
                      state,
                      message: 'Invalid calendar ID',
                    );
                  }
                  return CreateEditCalendarScreen(calendarId: calendarId);
                },
              ),
            ],
          ),

          GoRoute(
            path: '/people',
            name: 'people',
            builder: (context, state) => const PeopleGroupsScreen(),
            routes: [
              GoRoute(
                path: 'contacts/:contactId',
                name: 'contact-detail',
                builder: (context, state) {
                  final contactId = int.tryParse(
                    state.pathParameters['contactId'] ?? '',
                  );
                  if (contactId == null) {
                    return _buildErrorPage(
                      context,
                      state,
                      message: 'Invalid contact ID',
                    );
                  }

                  final contact = state.extra as User?;
                  if (contact == null) {
                    return _buildErrorPage(
                      context,
                      state,
                      message: 'Contact data required',
                    );
                  }
                  return ContactDetailScreen(contact: contact);
                },
              ),
              GoRoute(
                path: 'groups/create',
                name: 'group-create',
                builder: (context, state) => const CreateEditGroupScreen(),
              ),
              GoRoute(
                path: 'groups/:groupId',
                name: 'group-detail',
                builder: (context, state) {
                  final groupId = int.tryParse(
                    state.pathParameters['groupId'] ?? '',
                  );
                  if (groupId == null) {
                    return _buildErrorPage(
                      context,
                      state,
                      message: 'Invalid group ID',
                    );
                  }

                  final group = state.extra as Group?;
                  return GroupDetailScreen(
                    groupId: groupId,
                    initialGroup: group,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'group-edit',
                    builder: (context, state) {
                      final group = state.extra as Group?;
                      if (group == null) {
                        return _buildErrorPage(
                          context,
                          state,
                          message: 'Group data required',
                        );
                      }
                      return CreateEditGroupScreen(group: group);
                    },
                  ),
                  GoRoute(
                    path: 'add-members',
                    name: 'group-add-members',
                    builder: (context, state) {
                      final group = state.extra as Group?;
                      if (group == null) {
                        return _buildErrorPage(
                          context,
                          state,
                          message: 'Group data required',
                        );
                      }
                      return AddGroupMembersScreen(group: group);
                    },
                  ),
                ],
              ),
            ],
          ),

          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                name: 'settings-profile',
                builder: (context, state) => const SettingsScreen(
                  initialSection: SettingsSection.profile,
                ),
              ),
            ],
          ),

          GoRoute(
            path: '/birthdays',
            name: 'birthdays',
            builder: (context, state) => const BirthdaysScreen(),
          ),
        ],
      ),
    ],
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final configService = ConfigService.instance;
    final isSupabaseAuthenticated = SupabaseAuthService.currentUser != null;
    final isTestMode = configService.isTestMode;
    final currentLocation = state.uri.path;

    final isAuthenticated = _checkAuthentication(
      isTestMode,
      isSupabaseAuthenticated,
    );

    if (kDebugMode) {
      if (isTestMode) {}
    }

    if (['/splash', '/login', '/access-denied'].contains(currentLocation)) {
      return null;
    }

    if (!isAuthenticated) {
      if (kDebugMode) {}
      return '/login';
    }

    if (currentLocation == '/access-denied') {
      return null;
    }

    if (currentLocation == '/') {
      return '/events';
    }

    return null;
  }

  static bool _checkAuthentication(bool isTestMode, bool isAuthenticated) {
    if (isTestMode) {
      final configService = ConfigService.instance;
      final hasTestCredentials = configService.testUserInfo != null;

      return hasTestCredentials;
    }

    return isAuthenticated;
  }

  static Widget _buildErrorPage(
    BuildContext context,
    GoRouterState state, {
    String? message,
  }) {
    final error = state.error;
    final location = state.uri.toString();

    if (kDebugMode) {}

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(context.l10n.error)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 64,
                color: CupertinoColors.systemRed,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.error,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Location: $location',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message ??
                    '${context.l10n.error}: ${error?.toString() ?? context.l10n.unknownError}',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                key: const Key('navigation_error_go_to_events_button'),
                onPressed: () {
                  try {
                    context.go('/events');
                  } catch (e) {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(context.l10n.events),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
