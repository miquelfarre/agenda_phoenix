import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/group.dart';
import '../models/user.dart';
import '../services/config_service.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../ui/helpers/platform/platform_widgets.dart';
import '../ui/helpers/platform/platform_detection.dart';
import '../ui/styles/app_styles.dart';
import '../widgets/adaptive/adaptive_button.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/user_avatar.dart';
import '../core/state/app_state.dart';

class AddGroupMembersScreen extends ConsumerStatefulWidget {
  final Group group;

  const AddGroupMembersScreen({super.key, required this.group});

  @override
  ConsumerState<AddGroupMembersScreen> createState() => _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends ConsumerState<AddGroupMembersScreen> {
  List<User> _contacts = [];
  final Set<int> _selectedUserIds = {};
  bool _isLoadingContacts = false;
  bool _isAdding = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  int get currentUserId => ConfigService.instance.currentUserId;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoadingContacts = true;
      _errorMessage = null;
    });

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final contacts = await userRepo.fetchContacts(currentUserId);

      if (mounted) {
        setState(() {
          print('📥 [AddGroupMembers] Total contacts fetched: ${contacts.length}');
          print('📥 [AddGroupMembers] Group members: ${widget.group.members.map((m) => m.displayName).join(", ")}');
          print('📥 [AddGroupMembers] Group admins: ${widget.group.admins.map((a) => a.displayName).join(", ")}');
          print('📥 [AddGroupMembers] Group ownerId: ${widget.group.ownerId}');

          _contacts = contacts
              .where((user) {
                // Filter out:
                // 1. Users already in the group
                // 2. Public users (cannot be added to groups)
                final isAlreadyMember = widget.group.members.any((m) => m.id == user.id) ||
                    widget.group.admins.any((a) => a.id == user.id) ||
                    widget.group.ownerId == user.id;
                final isPublic = user.isPublic;

                final isFiltered = isAlreadyMember || isPublic;
                if (isFiltered) {
                  print('❌ [AddGroupMembers] Filtered out: ${user.displayName} (ID: ${user.id}) - isAlreadyMember: $isAlreadyMember, isPublic: $isPublic');
                }

                return !isAlreadyMember && !isPublic;
              })
              .toList();

          print('✅ [AddGroupMembers] Contacts available to add: ${_contacts.length}');
          for (var contact in _contacts) {
            print('  - ${contact.displayName} (ID: ${contact.id})');
          }

          _isLoadingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingContacts = false;
        });
      }
    }
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedUserIds.isEmpty) return;

    final l10n = context.l10n;

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    try {
      final groupRepo = ref.read(groupRepositoryProvider);

      // Add each selected user
      for (final userId in _selectedUserIds) {
        await groupRepo.addMemberToGroup(
          groupId: widget.group.id,
          memberUserId: userId,
        );
      }

      if (mounted) {
        context.pop(true); // Return true to indicate success
        PlatformWidgets.showSnackBar(
          message: '${_selectedUserIds.length} ${l10n.membersAdded}',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AdaptivePageScaffold(
      key: const Key('add_group_members_screen_scaffold'),
      title: l10n.addMembers,
      body: SafeArea(
        child: Column(
          children: [
          // Selected count banner
          if (_selectedUserIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppStyles.blue600.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: AppStyles.blue600.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: AppStyles.blue600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.selectedCount(_selectedUserIds.length),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppStyles.blue600,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    key: const Key('add_members_clear_selection_button'),
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _selectedUserIds.clear()),
                    child: Text(
                      l10n.clearSelection,
                      style: TextStyle(color: AppStyles.blue600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppStyles.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppStyles.errorColor.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle, color: AppStyles.errorColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(fontSize: 14, color: AppStyles.errorColor, decoration: TextDecoration.none),
                    ),
                  ),
                ],
              ),
            ),

          // Contacts list
          Expanded(
            child: _buildContactsList(l10n),
          ),

          // Add button (sticky at bottom)
          if (_selectedUserIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: Border(
                  top: BorderSide(
                    color: AppStyles.grey300,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: AdaptiveButton(
                  key: const Key('add_members_confirm_button'),
                  config: AdaptiveButtonConfig.primary(),
                  text: '${l10n.addMembers} (${_selectedUserIds.length})',
                  icon: CupertinoIcons.person_add,
                  onPressed: _isAdding ? null : _addSelectedMembers,
                  isLoading: _isAdding,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList(dynamic l10n) {
    if (_isLoadingContacts) {
      return Center(child: PlatformWidgets.platformLoadingIndicator());
    }

    if (_contacts.isEmpty) {
      return EmptyState(
        icon: CupertinoIcons.person_2,
        message: l10n.noContactsToAdd,
      );
    }

    // Filter contacts by search
    print('🔍 [AddGroupMembers] Search text: "${_searchController.text}"');
    print('🔍 [AddGroupMembers] Available contacts before search filter: ${_contacts.length}');

    final filteredContacts = _searchController.text.isEmpty
        ? _contacts
        : _contacts.where((contact) {
            final name = contact.displayName.toLowerCase();
            final searchLower = _searchController.text.toLowerCase();
            final matches = name.contains(searchLower);
            print('🔍 [AddGroupMembers] Checking "${contact.displayName}" against "$searchLower": $matches');
            return matches;
          }).toList();

    print('✅ [AddGroupMembers] Filtered contacts for display: ${filteredContacts.length}');
    for (var contact in filteredContacts) {
      print('  - ${contact.displayName} (ID: ${contact.id})');
    }

    if (filteredContacts.isEmpty) {
      return ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
        children: [
          _buildSearchField(l10n),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: EmptyState(
              icon: CupertinoIcons.search,
              message: l10n.noContactsFoundWithSearch,
            ),
          ),
        ],
      );
    }

    final isIOS = PlatformDetection.isIOS;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
      children: [
        _buildSearchField(l10n),
        if (filteredContacts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(l10n.contacts, style: AppStyles.cardTitle.copyWith(color: AppStyles.grey700)),
          ),
        ],
        ...filteredContacts.map((contact) {
          final isSelected = _selectedUserIds.contains(contact.id);

          return Container(
            margin: EdgeInsets.symmetric(horizontal: isIOS ? 16.0 : 8.0, vertical: 4.0),
            decoration: AppStyles.cardDecoration,
            child: GestureDetector(
              key: Key('add_member_contact_${contact.id}_tap'),
              onTap: _isAdding
                  ? null
                  : () {
                      setState(() {
                        if (isSelected) {
                          _selectedUserIds.remove(contact.id);
                        } else {
                          _selectedUserIds.add(contact.id);
                        }
                      });
                    },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    UserAvatar(user: contact, radius: 32.5, showOnlineIndicator: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.displayName.isNotEmpty ? contact.displayName : l10n.unknownUser,
                            style: AppStyles.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (contact.displaySubtitle?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              contact.displaySubtitle ?? '',
                              style: AppStyles.cardSubtitle.copyWith(color: AppStyles.grey600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      key: Key('add_member_contact_${contact.id}_checkbox'),
                      onTap: _isAdding
                          ? null
                          : () {
                              setState(() {
                                if (isSelected) {
                                  _selectedUserIds.remove(contact.id);
                                } else {
                                  _selectedUserIds.add(contact.id);
                                }
                              });
                            },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? AppStyles.primary600 : AppStyles.grey600,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: isSelected ? AppStyles.primary600 : AppStyles.transparent,
                        ),
                        child: isSelected
                            ? Icon(
                                CupertinoIcons.check_mark,
                                size: 16,
                                color: AppStyles.white,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSearchField(dynamic l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: l10n.searchContacts,
        onChanged: (_) => setState(() {}),
        style: TextStyle(color: AppStyles.grey700),
        backgroundColor: AppStyles.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
