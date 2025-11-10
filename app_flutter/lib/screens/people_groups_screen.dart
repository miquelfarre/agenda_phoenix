import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/domain/group.dart' as domain;
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import '../services/config_service.dart';
import '../services/contacts_sync_service.dart';
import '../services/test_contacts_helper.dart';
import '../models/domain/user.dart';
import 'package:eventypop/l10n/app_localizations.dart';
import '../widgets/empty_state.dart';
import '../widgets/contact_card.dart';
import '../widgets/adaptive_scaffold.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/widgets/adaptive/adaptive_button.dart';
import '../core/state/app_state.dart';
import 'package:permission_handler/permission_handler.dart';

class PeopleGroupsScreen extends ConsumerStatefulWidget {
  const PeopleGroupsScreen({super.key});
  @override
  ConsumerState<PeopleGroupsScreen> createState() => _PeopleGroupsScreenState();
}

class _PeopleGroupsScreenState extends ConsumerState<PeopleGroupsScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  int _tabIndex = 0;
  TextEditingController searchController = TextEditingController();
  int get userId => ConfigService.instance.currentUserId;

  List<User> _contacts = [];
  bool _isLoadingContacts = false;
  String? _contactsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: 0);
    _checkContactsPermission();
    _loadContacts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkContactsPermission();
      _loadContacts();
      ref.invalidate(groupsStreamProvider);
    }
  }

  Future<void> _checkContactsPermission() async {
    final ContactsSyncService contactsService = ContactsSyncService();
    final hasPermission = await contactsService.checkPermission();

    if (!hasPermission) {
      // Try to request permission
      await contactsService.requestPermission();
    }
  }

  Future<void> _loadContacts() async {
    if (_isLoadingContacts) return;

    setState(() {
      _isLoadingContacts = true;
      _contactsError = null;
    });

    try {
      // Import ContactsSyncService at the top of the file
      final ContactsSyncService contactsService = ContactsSyncService();

      // Check permission first
      var hasPermission = await contactsService.checkPermission();
      print('📱 Initial permission check: $hasPermission');

      // If no permission, try to request it
      if (!hasPermission) {
        print('📱 Requesting contacts permission...');
        hasPermission = await contactsService.requestPermission();
        print('📱 Permission request result: $hasPermission');
      }

      if (!hasPermission) {
        print('📱 Permission denied, showing error');
        if (mounted) {
          setState(() {
            _contactsError = 'Contacts permission not granted';
            _isLoadingContacts = false;
          });
        }
        return;
      }

      // Sync phone contacts with backend
      print('📱 Syncing phone contacts...');
      final syncResult = await contactsService.syncPhoneContacts();
      print('📱 Sync result: $syncResult');

      // Get registered contacts from backend
      print('📱 Getting registered contacts...');
      final contactsData = await contactsService.getRegisteredContacts();
      print('📱 Registered contacts count: ${contactsData.length}');

      // Convert to User objects
      final contacts = <User>[];
      for (final contactData in contactsData) {
        if (contactData['registered_user'] != null) {
          contacts.add(User.fromJson(contactData['registered_user'] as Map<String, dynamic>));
        }
      }

      print('📱 Final contacts count: ${contacts.length}');

      if (mounted) {
        setState(() {
          _contacts = contacts.where((user) => user.id != userId).toList();
          _isLoadingContacts = false;
        });
      }
    } catch (e, stack) {
      print('📱 Error loading contacts: $e');
      print('📱 Stack trace: $stack');
      if (mounted) {
        setState(() {
          _contactsError = e.toString();
          _isLoadingContacts = false;
        });
      }
    }
  }

  Future<void> _navigateToCreateGroup() async {
    await context.push('/people/groups/create');
  }

  Widget _buildContactsTab() {
    final l10n = context.l10n;

    if (_isLoadingContacts) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_contactsError != null) {
      return _buildContactsError(l10n, _contactsError!);
    }

    return _buildContactsList(_contacts, l10n);
  }

  Widget _buildContactsError(AppLocalizations l10n, Object error) {
    final isPermissionError = error.toString().contains('permission');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PlatformWidgets.platformIcon(
            isPermissionError
                ? CupertinoIcons.person_2
                : CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: isPermissionError ? AppStyles.orange600 : AppStyles.grey500,
          ),
          const SizedBox(height: 16),
          Text(
            isPermissionError
                ? l10n.contactsPermissionRequired
                : l10n.errorLoadingFriends,
            style: AppStyles.cardTitle.copyWith(
              color: AppStyles.black87,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPermissionError
                ? l10n.contactsPermissionInstructions
                : error.toString(),
            textAlign: TextAlign.center,
            style: AppStyles.bodyText.copyWith(
              color: AppStyles.grey600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          if (isPermissionError) ...[
            AdaptiveButton(
              key: const Key('people_groups_grant_permission_button'),
              config: AdaptiveButtonConfig.primary(),
              text: l10n.allowAccess,
              icon: CupertinoIcons.person_2,
              onPressed: () async {
                final hasPermission = await FlutterContacts.requestPermission();
                if (hasPermission) {
                  await _loadContacts();
                } else {
                  await openAppSettings();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactsList(List<User> contacts, AppLocalizations l10n) {
    final filteredContacts = searchController.text.isEmpty
        ? contacts
        : contacts.where((contact) {
            final name = contact.displayName.toLowerCase();
            final searchLower = searchController.text.toLowerCase();
            return name.contains(searchLower);
          }).toList();

    if (filteredContacts.isEmpty && contacts.isNotEmpty) {
      return CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: PlatformWidgets.platformTextField(
                controller: searchController,
                placeholder: l10n.searchFriends,
                prefixIcon: PlatformWidgets.platformIcon(
                  CupertinoIcons.search,
                  color: AppStyles.grey400,
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PlatformWidgets.platformIcon(
                    CupertinoIcons.search,
                    size: 64,
                    color: AppStyles.grey400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noContactsMessage,
                    style: AppStyles.cardTitle.copyWith(
                      color: AppStyles.grey600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlatformWidgets.platformIcon(
              CupertinoIcons.person_2,
              size: 64,
              color: AppStyles.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noContactsMessage,
              style: AppStyles.cardTitle.copyWith(
                color: AppStyles.grey600,
                fontSize: 18,
              ),
            ),
            // Only show in debug mode
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              AdaptiveButton(
                config: AdaptiveButtonConfig.secondary(),
                text: 'Add Test Contacts',
                icon: CupertinoIcons.person_add,
                onPressed: () async {
                  await TestContactsHelper.addTestContacts();
                  await _loadContacts();
                },
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        top: PlatformWidgets.isIOS ? 12.0 : 8.0,
        left: 8.0,
        right: 8.0,
      ),
      itemCount: filteredContacts.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.all(16),
            child: PlatformWidgets.platformTextField(
              controller: searchController,
              placeholder: l10n.searchFriends,
              prefixIcon: PlatformWidgets.platformIcon(
                CupertinoIcons.search,
                color: AppStyles.grey400,
              ),
            ),
          );
        }

        final contactIndex = index - 1;

        // Safety check to prevent RangeError
        if (contactIndex >= filteredContacts.length) {
          return const SizedBox.shrink();
        }

        final contact = filteredContacts[contactIndex];
        return ContactCard(
          contact: contact,
          onTap: () {
            context.go('/people/contacts/${contact.id}', extra: contact);
          },
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    final l10n = context.l10n;
    final groupsAsync = ref.watch(groupsStreamProvider);

    return groupsAsync.when(
      data: (groups) {
        final userGroups = groups
            .where(
              (group) =>
                  group.ownerId == userId ||
                  group.members.any((member) => member.id == userId) ||
                  group.admins.any((admin) => admin.id == userId),
            )
            .toList();

        for (var _ in userGroups) {}

        if (userGroups.isEmpty) {
          return EmptyState(
            message: l10n.noGroupsMessage,
            icon: CupertinoIcons.group,
          );
        }

        return ListView.builder(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            top: PlatformWidgets.isIOS ? 12.0 : 8.0,
            left: 8.0,
            right: 8.0,
          ),
          itemCount: userGroups.length,
          itemBuilder: (context, index) {
            final group = userGroups[index];
            return _buildGroupCard(group, l10n);
          },
        );
      },
      loading: () {
        return const Center(child: CupertinoActivityIndicator());
      },
      error: (error, stack) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${l10n.error}: $error'),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: () {
                  ref.invalidate(groupsStreamProvider);
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupCard(domain.Group group, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        decoration: AppStyles.cardDecoration,
        child: CupertinoListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppStyles.purple600,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(CupertinoIcons.group, color: AppStyles.white, size: 24),
          ),
          title: Text(group.name, style: AppStyles.cardTitle),
          subtitle: Text(
            l10n.membersLabel(group.members.length),
            style: AppStyles.bodyText.copyWith(color: AppStyles.grey600),
          ),
          trailing: PlatformWidgets.platformIcon(
            CupertinoIcons.chevron_right,
            color: AppStyles.grey400,
          ),
          onTap: () {
            context.push('/people/groups/${group.id}', extra: group);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isIOS = PlatformWidgets.isIOS;

    return AdaptivePageScaffold(
      key: const Key('people_groups_screen_scaffold'),
      title: l10n.peopleAndGroups,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isIOS
                        ? CupertinoColors.systemGroupedBackground.resolveFrom(
                            context,
                          )
                        : AppStyles.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          key: const Key('people_groups_contacts_tab'),
                          onTap: () {
                            setState(() {
                              _tabIndex = 0;
                            });
                            _pageController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _tabIndex == 0
                                  ? AppStyles.primary600
                                  : AppStyles.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.contacts,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _tabIndex == 0
                                    ? AppStyles.white
                                    : AppStyles.grey600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          key: const Key('people_groups_groups_tab'),
                          onTap: () {
                            setState(() {
                              _tabIndex = 1;
                            });
                            _pageController.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _tabIndex == 1
                                  ? AppStyles.primary600
                                  : AppStyles.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.groups,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _tabIndex == 1
                                    ? AppStyles.white
                                    : AppStyles.grey600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _tabIndex = index;
                      });
                    },
                    children: [
                      Builder(
                        builder: (context) {
                          return _buildContactsTab();
                        },
                      ),
                      Builder(
                        builder: (context) {
                          return _buildGroupsTab();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // FAB positioned over the content
            if (_tabIndex == 1)
              Positioned(
                right: 16,
                bottom: 16,
                child: CupertinoButton.filled(
                  key: const Key('people_groups_create_group_fab'),
                  onPressed: _navigateToCreateGroup,
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    CupertinoIcons.plus,
                    color: AppStyles.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
