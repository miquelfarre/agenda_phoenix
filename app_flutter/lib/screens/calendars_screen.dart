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
import '../models/calendar.dart';
import 'calendar_events_screen.dart';
import '../utils/error_message_parser.dart';
import '../utils/calendar_operations.dart';
import '../utils/calendar_permissions.dart';

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

    return AdaptivePageScaffold(
      title: isIOS ? null : l10n.calendars,
      body: body,
    );
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

  List<Widget> _buildMyCalendarsList() {
    final calendarsAsync = ref.watch(calendarsStreamProvider);
    final searchQuery = _searchController.text.toLowerCase();

    return calendarsAsync.when(
      data: (calendars) {
        // Filtrar calendarios por nombre si hay búsqueda
        final filteredCalendars = searchQuery.isEmpty
            ? calendars
            : calendars
                  .where((cal) => cal.name.toLowerCase().contains(searchQuery))
                  .toList();

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

        if (filteredCalendars.isEmpty && searchQuery.isNotEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: CupertinoIcons.search,
                message: context.l10n.noCalendarsFound,
              ),
            ),
          ];
        }

        return [
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
            builder: (context) => CalendarEventsScreen(
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
