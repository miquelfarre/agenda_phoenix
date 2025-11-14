import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain/event.dart';
import '../models/domain/user.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/user_avatar.dart';
import '../ui/styles/app_styles.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import 'contact_detail_screen.dart';
import 'subscription_detail_screen.dart';

class EventAttendeesScreen extends ConsumerStatefulWidget {
  final Event event;

  const EventAttendeesScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<EventAttendeesScreen> createState() =>
      _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends ConsumerState<EventAttendeesScreen> {
  List<User> get _attendeeUsers {
    final List<User> users = [];
    for (final a in widget.event.attendees) {
      if (a is User) {
        users.add(a);
      } else if (a is Map<String, dynamic>) {
        try {
          final user = User.fromJson(a);
          users.add(user);
        } catch (e) {
          // Intentionally ignore malformed user data
        }
      }
    }
    return users;
  }

  List<User> get _contactAttendees {
    return _attendeeUsers.where((u) => !u.isPublic).toList();
  }

  List<User> get _publicAttendees {
    return _attendeeUsers.where((u) => u.isPublic).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allAttendees = _attendeeUsers;

    return AdaptivePageScaffold(
      title: l10n.attendees,
      body: allAttendees.isEmpty
          ? EmptyState(
              icon: CupertinoIcons.person_3,
              message: l10n.noAttendees,
            )
          : _buildAttendeesList(context, l10n),
    );
  }

  Widget _buildAttendeesList(BuildContext context, dynamic l10n) {
    final contacts = _contactAttendees;
    final publics = _publicAttendees;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        // Contacts section
        if (contacts.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Contactos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.grey700,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = contacts[index];
                  return _buildContactAttendeeItem(user);
                },
                childCount: contacts.length,
              ),
            ),
          ),
        ],

        // Public users section
        if (publics.isNotEmpty) ...[
          SliverPadding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: contacts.isNotEmpty ? 24 : 16,
              bottom: 8,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Usuarios públicos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.grey700,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = publics[index];
                  return _buildPublicAttendeeItem(user);
                },
                childCount: publics.length,
              ),
            ),
          ),
        ],

        // Bottom spacing
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  Widget _buildContactAttendeeItem(User user) {
    return GestureDetector(
      onTap: () => _navigateToContactDetail(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: AppStyles.cardDecoration,
        child: CupertinoListTile(
          leading: UserAvatar(user: user, radius: 24),
          title: Text(
            user.displayName.isNotEmpty ? user.displayName : 'Usuario',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: user.displaySubtitle?.isNotEmpty == true
              ? Text(
                  user.displaySubtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppStyles.grey600,
                  ),
                )
              : null,
          trailing: Icon(
            CupertinoIcons.chevron_right,
            size: 18,
            color: AppStyles.grey400,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPublicAttendeeItem(User user) {
    return GestureDetector(
      onTap: () => _navigateToSubscriptionDetail(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: AppStyles.cardDecoration,
        child: CupertinoListTile(
          leading: UserAvatar(user: user, radius: 24),
          title: Text(
            user.displayName.isNotEmpty ? user.displayName : 'Usuario',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: user.displaySubtitle?.isNotEmpty == true
              ? Text(
                  user.displaySubtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppStyles.grey600,
                  ),
                )
              : null,
          trailing: Icon(
            CupertinoIcons.chevron_right,
            size: 18,
            color: AppStyles.grey400,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _navigateToContactDetail(User user) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ContactDetailScreen(contact: user),
      ),
    );
  }

  void _navigateToSubscriptionDetail(User user) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => SubscriptionDetailScreen(publicUser: user),
      ),
    );
  }
}
