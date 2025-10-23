import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import '../ui/styles/app_styles.dart';
import '../services/calendar_service.dart';

class AppInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const AppInitializer({super.key, required this.child});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    DateTime.now();

    try {
      await _ensureBirthdayCalendar();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _ensureBirthdayCalendar() async {
    try {
      final calendarService = CalendarService();

      final calendars = calendarService.getLocalCalendars();
      final hasBirthdayCalendar = calendars.any(
        (cal) => cal.name == 'Cumpleaños' || cal.name == 'Birthdays',
      );

      if (!hasBirthdayCalendar) {
        await calendarService.createCalendar(
          name: 'Cumpleaños',
          description: 'Calendario para cumpleaños',
          color: '#FF5733',
          isPublic: false,
          isShareable: false,
        );
      } else {}
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      if (PlatformDetection.isIOS) {
        return CupertinoApp(
          debugShowCheckedModeBanner: false,
          home: CupertinoPageScaffold(
            child: Center(child: PlatformWidgets.platformLoadingIndicator()),
          ),
        );
      }

      return WidgetsApp(
        color: AppStyles.white,
        builder: (context, child) =>
            Center(child: PlatformWidgets.platformLoadingIndicator()),
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
            PageRouteBuilder<T>(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  builder(context),
            ),
      );
    }

    return widget.child;
  }
}
