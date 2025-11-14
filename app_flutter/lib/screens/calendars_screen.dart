import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../ui/helpers/platform/platform_detection.dart';
import '../ui/helpers/platform/dialog_helpers.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/adaptive/adaptive_button.dart';
import '../core/state/app_state.dart';
import '../models/domain/calendar.dart';
import 'calendar_detail_screen.dart';
import '../utils/error_message_parser.dart';
import '../utils/calendar_operations.dart';
import '../utils/calendar_permissions.dart';

// Helper class to store calendar data with filter counts
class CalendarsData {
  final List<Calendar> calendars;
  final int myPrivateCount;
  final int myPublicCount;
  final int subscribedCount;
  final int allCount;

  CalendarsData({
    required this.calendars,
    required this.myPrivateCount,
    required this.myPublicCount,
    required this.subscribedCount,
    required this.allCount,
  });
}

class CalendarsScreen extends ConsumerStatefulWidget {
  const CalendarsScreen({super.key});

  @override
  ConsumerState<CalendarsScreen> createState() => _CalendarsScreenState();
}

class _CalendarsScreenState extends ConsumerState<CalendarsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchingByHash = false;
  bool _loadingHashSearch = false;
  Calendar? _hashSearchResult;
  String? _hashSearchError;
  String _currentFilter = 'all'; // 'all', 'my_private', 'my_public', 'subscribed'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _hashSearchResult = null;
      _hashSearchError = null;

      if (value.startsWith('#')) {
        _searchingByHash = true;
        final hash = value.substring(1).trim();

        if (hash.length >= 3) {
          _searchByHash(hash);
        }
      } else {
        _searchingByHash = false;
        _loadingHashSearch = false;
      }
    });
  }

  Future<void> _searchByHash(String hash) async {
    if (_loadingHashSearch) return;

    setState(() {
      _loadingHashSearch = true;
      _hashSearchError = null;
    });

    try {
      final repository = ref.read(calendarRepositoryProvider);
      final calendar = await repository.searchByShareHash(hash);

      if (mounted) {
        setState(() {
          _loadingHashSearch = false;
          if (calendar != null) {
            _hashSearchResult = calendar;
          } else {
            _hashSearchError = context.l10n.calendarNotFoundByHash;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingHashSearch = false;
          _hashSearchError = context.l10n.error;
        });
      }
    }
  }

  Future<void> _subscribeToCalendar(Calendar calendar) async {
    if (calendar.shareHash == null) return;

    try {
      final repository = ref.read(calendarRepositoryProvider);
      await repository.subscribeByShareHash(calendar.shareHash!);

      if (mounted) {
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: context.l10n.subscribedTo(calendar.name),
        );
        _searchController.clear();
        setState(() {
          _searchingByHash = false;
          _hashSearchResult = null;
        });

        // Realtime will automatically update the calendars list
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = ErrorMessageParser.parse(e, context);
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: errorMessage,
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteOrLeaveCalendar(Calendar calendar) async {
    await CalendarOperations.deleteOrLeaveCalendar(
      calendar: calendar,
      repository: ref.read(calendarRepositoryProvider),
      context: context,
      shouldNavigate: false,
      showSuccessMessage: true,
    );
    // Realtime will automatically update the calendars list
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isIOS = PlatformDetection.isIOS;

    Widget body = _buildCalendarsView();

    if (isIOS) {
      body = Stack(
        children: [
          body,
          Positioned(
            bottom: 100,
            right: 20,
            child: AdaptiveButton(
              config: const AdaptiveButtonConfig(
                variant: ButtonVariant.fab,
                size: ButtonSize.medium,
                fullWidth: false,
                iconPosition: IconPosition.only,
              ),
              icon: CupertinoIcons.add,
              onPressed: () => context.push('/calendars/create'),
            ),
          ),
        ],
      );
    }

    return AdaptivePageScaffold(title: l10n.calendars, body: body);
  }

  Widget _buildCalendarsView() {
    return SafeArea(
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildSearchBar()),
          if (_searchingByHash)
            ..._buildHashSearchResults()
          else
            ..._buildMyCalendarsList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoSearchTextField(
            controller: _searchController,
            placeholder: l10n.searchByNameOrCode,
            onChanged: _onSearchChanged,
          ),
          if (_searchController.text.startsWith('#')) ...[
            const SizedBox(height: 8),
            Text(
              l10n.enterCodePrecededByHash,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildHashSearchResults() {
    final l10n = context.l10n;

    if (_loadingHashSearch) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CupertinoActivityIndicator()),
        ),
      ];
    }

    if (_hashSearchError != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: CupertinoIcons.search,
            message: _hashSearchError!,
          ),
        ),
      ];
    }

    if (_hashSearchResult != null) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHashResultCard(_hashSearchResult!),
            ]),
          ),
        ),
      ];
    }

    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: CupertinoIcons.search,
          message: l10n.enterCodePrecededByHash,
        ),
      ),
    ];
  }

  Widget _buildHashResultCard(Calendar calendar) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      calendar.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (calendar.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        calendar.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                CupertinoIcons.person_2,
                size: 16,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Text(
                '${calendar.subscriberCount} ${calendar.subscriberCount == 1 ? l10n.subscriber : l10n.subscriber}s',
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () => _subscribeToCalendar(calendar),
              child: Text(l10n.subscribe),
            ),
          ),
        ],
      ),
    );
  }

  // Process calendars and calculate filter counts
  CalendarsData _processCalendars(List<Calendar> calendars) {
    int myPrivateCount = 0;
    int myPublicCount = 0;
    int subscribedCount = 0;

    for (final calendar in calendars) {
      // My private calendars: owned + private
      if (calendar.accessType == 'owned' && !calendar.isPublic) {
        myPrivateCount++;
      }
      // My public calendars: owned + public
      else if (calendar.accessType == 'owned' && calendar.isPublic) {
        myPublicCount++;
      }
      // Subscribed calendars (both private and public users)
      else if (calendar.accessType == 'subscription') {
        subscribedCount++;
      }
    }

    return CalendarsData(
      calendars: calendars,
      myPrivateCount: myPrivateCount,
      myPublicCount: myPublicCount,
      subscribedCount: subscribedCount,
      allCount: calendars.length,
    );
  }

  // Apply calendar type filter
  List<Calendar> _applyCalendarTypeFilter(CalendarsData data) {
    switch (_currentFilter) {
      case 'my_private':
        return data.calendars
            .where((cal) => cal.accessType == 'owned' && !cal.isPublic)
            .toList();
      case 'my_public':
        return data.calendars
            .where((cal) => cal.accessType == 'owned' && cal.isPublic)
            .toList();
      case 'subscribed':
        return data.calendars
            .where((cal) => cal.accessType == 'subscription')
            .toList();
      case 'all':
      default:
        return data.calendars;
    }
  }

  // Build filter chips widget
  Widget _buildCalendarTypeFilters(CalendarsData data) {
    final l10n = context.l10n;

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            label: l10n.allCalendars,
            count: data.allCount,
            isSelected: _currentFilter == 'all',
            onTap: () => setState(() => _currentFilter = 'all'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: l10n.myPrivateCalendars,
            count: data.myPrivateCount,
            isSelected: _currentFilter == 'my_private',
            onTap: () => setState(() => _currentFilter = 'my_private'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: l10n.myPublicCalendars,
            count: data.myPublicCount,
            isSelected: _currentFilter == 'my_public',
            onTap: () => setState(() => _currentFilter = 'my_public'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: l10n.subscribedCalendars,
            count: data.subscribedCount,
            isSelected: _currentFilter == 'subscribed',
            onTap: () => setState(() => _currentFilter = 'subscribed'),
          ),
        ],
      ),
    );
  }

  // Build individual filter chip
  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.systemBlue
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? CupertinoColors.white
                    : CupertinoColors.black,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? CupertinoColors.white.withValues(alpha: 0.3)
                    : CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected
                      ? CupertinoColors.white
                      : CupertinoColors.systemGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMyCalendarsList() {
    final calendarsAsync = ref.watch(calendarsStreamProvider);
    final searchQuery = _searchController.text.toLowerCase();

    return calendarsAsync.when(
      data: (calendars) {
        if (calendars.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: CupertinoIcons.calendar,
                message: context.l10n.noCalendarsYet,
                subtitle: context.l10n.noCalendarsSearchByCode,
                actionLabel: context.l10n.createCalendar,
                onAction: () => context.push('/calendars/create'),
              ),
            ),
          ];
        }

        // Process calendars to calculate counts
        final calendarsData = _processCalendars(calendars);

        // Apply calendar type filter
        var filteredCalendars = _applyCalendarTypeFilter(calendarsData);

        // Apply search filter if present
        if (searchQuery.isNotEmpty) {
          filteredCalendars = filteredCalendars
              .where((cal) => cal.name.toLowerCase().contains(searchQuery))
              .toList();
        }

        return [
          // Filter chips
          SliverToBoxAdapter(
            child: _buildCalendarTypeFilters(calendarsData),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Empty state if no results after filtering
          if (filteredCalendars.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: searchQuery.isNotEmpty
                    ? CupertinoIcons.search
                    : CupertinoIcons.calendar,
                message: searchQuery.isNotEmpty
                    ? context.l10n.noCalendarsFound
                    : context.l10n.noCalendarsYet,
              ),
            )
          else
            // Calendar list
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final calendarIndex = index ~/ 2;
                if (index.isOdd) {
                  return Container(
                    height: 0.5,
                    margin: const EdgeInsets.only(left: 72),
                    color: CupertinoColors.separator,
                  );
                }
                return _buildCalendarItem(filteredCalendars[calendarIndex]);
              }, childCount: filteredCalendars.length * 2 - 1),
            ),
        ];
      },
      loading: () => [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CupertinoActivityIndicator()),
        ),
      ],
      error: (error, stack) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: CupertinoIcons.exclamationmark_triangle,
              message: error.toString(),
            ),
          ),
        ];
      },
    );
  }

  Widget _buildCalendarItem(Calendar calendar) {
    final l10n = context.l10n;
    final isOwner = CalendarPermissions.isOwner(calendar);

    return CupertinoListTile(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => CalendarDetailScreen(
              calendarId: calendar.id,
              calendarName: calendar.name,
            ),
          ),
        );
      },
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBlue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          calendar.isPublic ? CupertinoIcons.globe : CupertinoIcons.lock,
          color: CupertinoColors.white,
          size: 20,
        ),
      ),
      title: Text(calendar.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (calendar.description != null)
            Text(
              calendar.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            isOwner
                ? l10n.owner
                : (calendar.shareHash != null ? l10n.subscriber : l10n.member),
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.trash,
          color: CupertinoColors.systemRed,
          size: 20,
        ),
        onPressed: () => _deleteOrLeaveCalendar(calendar),
      ),
    );
  }
}
