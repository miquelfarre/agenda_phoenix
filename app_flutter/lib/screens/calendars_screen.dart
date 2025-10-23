import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/calendar.dart';
import '../core/state/app_state.dart';
import '../core/providers/calendar_provider.dart';
import 'calendar_events_screen.dart';
import 'create_calendar_screen.dart';
import '../ui/styles/app_styles.dart';

class CalendarsScreen extends ConsumerStatefulWidget {
  const CalendarsScreen({super.key});

  @override
  ConsumerState<CalendarsScreen> createState() => _CalendarsScreenState();
}

class _CalendarsScreenState extends ConsumerState<CalendarsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCalendars);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCalendars() {
    if (mounted) setState(() {});
  }

  List<Calendar> _applySearchFilter(List<Calendar> calendars) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return calendars;

    return calendars.where((calendar) {
      return calendar.name.toLowerCase().contains(query) ||
          (calendar.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Color _parseCalendarColor(String colorHex) {
    try {
      String hexColor = colorHex.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return AppStyles.blue600;
    }
  }

  int _getEventCountForCalendar(int calendarId) {
    final allEvents = ref.watch(eventStateProvider);
    return allEvents.where((event) => event.calendarId == calendarId).length;
  }

  @override
  Widget build(BuildContext context) {
    final calendarsAsync = ref.watch(calendarsNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        middle: Text(
          AppLocalizations.of(context)!.calendars,
          style: const TextStyle(fontSize: 16),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => const CreateCalendarScreen(),
              ),
            );
          },
          child: const Icon(CupertinoIcons.add, size: 28),
        ),
      ),
      child: SafeArea(
        child: calendarsAsync.when(
          data: (calendars) => _buildContent(calendars),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) => Center(
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
                  AppLocalizations.of(context)!.errorLoadingData,
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Calendar> calendars) {
    final calendarsToShow = _applySearchFilter(calendars);

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: AppLocalizations.of(context)!.searchCalendars,
              backgroundColor: CupertinoColors.systemGrey6.resolveFrom(context),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '${calendarsToShow.length} ${calendarsToShow.length == 1 ? AppLocalizations.of(context)!.calendar : AppLocalizations.of(context)!.calendars}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppStyles.grey600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        if (calendarsToShow.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 64,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isNotEmpty
                        ? AppLocalizations.of(context)!.noCalendarsFound
                        : AppLocalizations.of(context)!.noCalendars,
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final calendar = calendarsToShow[index];
              final eventCount = _getEventCountForCalendar(
                int.parse(calendar.id),
              );
              final calendarColor = _parseCalendarColor(calendar.color);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => CalendarEventsScreen(
                          calendarId: int.parse(calendar.id),
                          calendarName: calendar.name,
                          calendarColor: calendar.color,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground.resolveFrom(
                        context,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemGrey5.resolveFrom(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: calendarColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: calendarColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      calendar.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.label,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (calendar.isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppStyles.blue600.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.defaultCalendar,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppStyles.blue600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$eventCount ${eventCount == 1 ? AppLocalizations.of(context)!.event : AppLocalizations.of(context)!.events}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppStyles.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          CupertinoIcons.chevron_right,
                          color: CupertinoColors.systemGrey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }, childCount: calendarsToShow.length),
          ),
      ],
    );
  }
}
