import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../ui/helpers/platform/platform_widgets.dart';
import '../../ui/helpers/l10n/l10n_helpers.dart';
import '../../widgets/adaptive_scaffold.dart';
import '../../screens/events_screen.dart';
import '../../screens/subscriptions_screen.dart';
import '../../screens/calendars_screen.dart';
import '../../widgets/adaptive/adaptive_button.dart';
import '../../ui/helpers/platform/dialog_helpers.dart';

class NavigationShell extends StatefulWidget {
  final Widget? child;

  const NavigationShell({super.key, this.child});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _selectedIndex = 0;

  List<AdaptiveNavigationItem>? _navigationItems;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = context.l10n;

    _navigationItems = [
      AdaptiveNavigationItem(icon: CupertinoIcons.calendar, label: l10n.events, screen: const EventsScreen()),
      AdaptiveNavigationItem(icon: CupertinoIcons.square_stack, label: l10n.subscriptions, screen: SubscriptionsScreen()),
      AdaptiveNavigationItem(icon: CupertinoIcons.rectangle_stack_person_crop, label: l10n.calendars, screen: const CalendarsScreen()),
    ];

    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/events')) {
      _selectedIndex = 0;
    } else if (location.startsWith('/subscriptions')) {
      _selectedIndex = 1;
    } else if (location.startsWith('/calendars')) {
      _selectedIndex = 2;
    }
  }

  void _onItemTapped(int index) {
    if (_navigationItems == null) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/events');
        break;
      case 1:
        context.go('/subscriptions');
        break;
      case 2:
        context.go('/calendars');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_navigationItems == null) {
      return AdaptivePageScaffold(body: Center(child: PlatformWidgets.platformLoadingIndicator()));
    }

    if (widget.child != null) {
      final l10n = context.l10n;
      return AdaptiveScaffold(
        title: l10n.appName,
        navigationItems: _navigationItems!,
        currentIndex: _selectedIndex,
        onNavigationChanged: _onItemTapped,
        actions: [
          AdaptiveButton(
            key: const Key('navigation_shell_settings_button'),
            config: const AdaptiveButtonConfig(variant: ButtonVariant.icon, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.only),
            icon: CupertinoIcons.ellipsis_vertical,
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
        body: widget.child!,
      );
    }

    return AdaptiveScaffold(
      title: 'EventyPop',
      navigationItems: _navigationItems!,
      currentIndex: _selectedIndex,
      onNavigationChanged: _onItemTapped,
      actions: [
        AdaptiveButton(
          key: const Key('navigation_shell_fallback_settings_button'),
          config: const AdaptiveButtonConfig(variant: ButtonVariant.icon, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.only),
          icon: CupertinoIcons.ellipsis_vertical,
          onPressed: () => _showSettingsMenu(context),
        ),
      ],
      body: _navigationItems![_selectedIndex].screen,
    );
  }

  Future<void> _showSettingsMenu(BuildContext context) async {
    final l10n = context.l10n;

    final sheetActions = [PlatformAction(text: l10n.settings, value: 'settings'), PlatformAction(text: l10n.calendars, value: 'calendars'), PlatformAction(text: l10n.birthdays, value: 'birthdays')];

    final result = await PlatformDialogHelpers.showPlatformActionSheet<String>(context, title: '', actions: sheetActions);

    if (!mounted) return;

    if (result != null) {
      _handleMenuResult(result);
    }
  }

  void _handleMenuResult(String result) {
    if (!mounted) return;

    switch (result) {
      case 'settings':
        context.push('/settings');
        break;
      case 'calendars':
        context.push('/calendars');
        break;
      case 'birthdays':
        context.push('/birthdays');
        break;
    }
  }
}
