import 'package:flutter/cupertino.dart';
import 'package:eventypop/screens/events_screen.dart';
import 'package:eventypop/screens/people_groups_screen.dart';
import 'package:eventypop/screens/settings_screen.dart';
import 'package:eventypop/screens/subscriptions_screen.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import 'package:eventypop/ui/helpers/platform/platform_navigation.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/widgets/adaptive_scaffold.dart';
import 'package:eventypop/widgets/adaptive/adaptive_button.dart';

class HomeScreen extends StatefulWidget {
  final String env;

  const HomeScreen({super.key, required this.env});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<AdaptiveNavigationItem>? _navigationItems;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = context.l10n;

    _navigationItems = [
      AdaptiveNavigationItem(
        icon: CupertinoIcons.calendar,
        label: l10n.events,
        screen: const EventsScreen(),
      ),
      AdaptiveNavigationItem(
        icon: CupertinoIcons.square_stack,
        label: l10n.subscriptions,
        screen: SubscriptionsScreen(),
      ),
      AdaptiveNavigationItem(
        icon: CupertinoIcons.group,
        label: l10n.peopleAndGroups,
        screen: PeopleGroupsScreen(),
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_navigationItems == null) {
      return AdaptivePageScaffold(
        body: Center(child: PlatformWidgets.platformLoadingIndicator()),
      );
    }

    final l10n = context.l10n;
    return AdaptiveScaffold(
      title: l10n.appName,
      navigationItems: _navigationItems!,
      currentIndex: _selectedIndex,
      onNavigationChanged: _onItemTapped,
      actions: [
        AdaptiveButton(
          key: const Key('home_screen_settings_button'),
          config: const AdaptiveButtonConfig(
            variant: ButtonVariant.icon,
            size: ButtonSize.medium,
            fullWidth: false,
            iconPosition: IconPosition.only,
          ),
          icon: CupertinoIcons.ellipsis_vertical,
          onPressed: () async {
            final effectiveContext = context;
            final l10nSafe = context.l10n;

            final sheetActions = [
              PlatformAction(text: l10nSafe.settings, value: 'settings'),
            ];

            final navigator = Navigator.of(effectiveContext);

            final result =
                await PlatformDialogHelpers.showPlatformActionSheet<String>(
                  effectiveContext,
                  title: l10nSafe.options,
                  actions: sheetActions,
                );

            if (result == 'settings') {
              navigator.push(
                PlatformNavigation.platformPageRoute<void>(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            }
          },
        ),
      ],
      body: _navigationItems![_selectedIndex].screen,
    );
  }
}
