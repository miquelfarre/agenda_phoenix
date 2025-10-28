import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/event.dart';
import '../core/state/app_state.dart';
import '../widgets/event_card.dart';
import '../widgets/event_card/event_card_config.dart';
import 'event_detail_screen.dart';
import '../ui/styles/app_styles.dart';
import '../utils/datetime_utils.dart';

class BirthdaysScreen extends ConsumerStatefulWidget {
  const BirthdaysScreen({super.key});

  @override
  ConsumerState<BirthdaysScreen> createState() => _BirthdaysScreenState();
}

class _BirthdaysScreenState extends ConsumerState<BirthdaysScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterBirthdays);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBirthdays() {
    if (mounted) setState(() {});
  }

  List<Event> _applySearchFilter(List<Event> birthdays) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return birthdays;

    return birthdays.where((event) {
      return event.title.toLowerCase().contains(query) ||
          (event.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<Event> _sortByUpcomingBirthdays(List<Event> birthdays) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentDay = now.day;

    return birthdays.toList()..sort((a, b) {
      int daysUntilA = _daysUntilNextBirthday(
        a.startDate.month,
        a.startDate.day,
        currentMonth,
        currentDay,
      );
      int daysUntilB = _daysUntilNextBirthday(
        b.startDate.month,
        b.startDate.day,
        currentMonth,
        currentDay,
      );

      int comparison = daysUntilA.compareTo(daysUntilB);
      if (comparison != 0) return comparison;

      return a.title.compareTo(b.title);
    });
  }

  int _daysUntilNextBirthday(
    int birthdayMonth,
    int birthdayDay,
    int currentMonth,
    int currentDay,
  ) {
    final now = DateTime.now();
    final thisYearBirthday = DateTime(now.year, birthdayMonth, birthdayDay);

    if (thisYearBirthday.isAfter(now) ||
        (thisYearBirthday.year == now.year &&
            thisYearBirthday.month == now.month &&
            thisYearBirthday.day == now.day)) {
      return thisYearBirthday.difference(now).inDays;
    } else {
      final nextYearBirthday = DateTime(
        now.year + 1,
        birthdayMonth,
        birthdayDay,
      );
      return nextYearBirthday.difference(now).inDays;
    }
  }

  String _getBirthdayLabel(Event event) {
    final now = DateTime.now();
    final daysUntil = _daysUntilNextBirthday(
      event.startDate.month,
      event.startDate.day,
      now.month,
      now.day,
    );

    if (daysUntil == 0) {
      return AppLocalizations.of(context)!.today;
    } else if (daysUntil == 1) {
      return AppLocalizations.of(context)!.tomorrow;
    } else if (daysUntil < 7) {
      return AppLocalizations.of(context)!.inDays(daysUntil);
    } else if (daysUntil < 30) {
      final weeks = (daysUntil / 7).floor();
      return weeks == 1
          ? AppLocalizations.of(context)!.inOneWeek
          : AppLocalizations.of(context)!.inWeeks(weeks);
    } else if (daysUntil < 365) {
      final months = (daysUntil / 30).floor();
      return months == 1
          ? AppLocalizations.of(context)!.inOneMonth
          : AppLocalizations.of(context)!.inMonths(months);
    } else {
      return AppLocalizations.of(context)!.inOneYear;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allEventsAsync = ref.watch(eventsStreamProvider);
    final allEvents = allEventsAsync.when(
      data: (events) => events,
      loading: () => <Event>[],
      error: (_, __) => <Event>[],
    );

    final birthdayEvents = allEvents
        .where((event) => event.isBirthday)
        .toList();

    final sortedBirthdays = _sortByUpcomingBirthdays(birthdayEvents);

    final eventsToShow = _applySearchFilter(sortedBirthdays);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        middle: Text(
          AppLocalizations.of(context)!.birthdays,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      child: SafeArea(child: _buildContent(eventsToShow)),
    );
  }

  Widget _buildContent(List<Event> eventsToShow) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: AppLocalizations.of(context)!.searchBirthdays,
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
                  '${eventsToShow.length} ${eventsToShow.length == 1 ? AppLocalizations.of(context)!.birthday : AppLocalizations.of(context)!.birthdays}',
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

        if (eventsToShow.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.gift,
                    size: 64,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isNotEmpty
                        ? AppLocalizations.of(context)!.noBirthdaysFound
                        : AppLocalizations.of(context)!.noBirthdays,
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
              final event = eventsToShow[index];
              final birthdayLabel = _getBirthdayLabel(event);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                      child: Text(
                        birthdayLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppStyles.grey600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    EventCard(
                      event: event,
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (_) => EventDetailScreen(event: event),
                          ),
                        );
                      },
                      config: EventCardConfig.readOnly().copyWith(
                        customStatus: DateTimeUtils.formatBirthdayDate(
                          event.startDate,
                          Localizations.localeOf(context).languageCode,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }, childCount: eventsToShow.length),
          ),
      ],
    );
  }
}
