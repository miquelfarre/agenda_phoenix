import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_navigation.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/permission_service.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../widgets/adaptive_scaffold.dart';
import 'package:eventypop/widgets/adaptive/adaptive_button.dart';
import 'package:eventypop/widgets/adaptive/configs/button_config.dart';
import '../core/state/app_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final Widget? nextScreen;

  const SplashScreen({super.key, this.nextScreen});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  Timer? _safetyTimer;

  String _statusMessage = '';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final l10n = context.l10n;
        setState(() {
          _statusMessage = l10n.startingEventyPop;
        });
        _initializeApp();
      }
    });

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _scaleController.forward();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });

    _safetyTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        _navigateToNextScreen();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _safetyTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      final l10n = context.l10n;

      final startTime = DateTime.now();
      const minDuration = Duration(seconds: 2);

      // Real action: Initialize all repositories
      _updateStatus(l10n.loadingLocalData);
      await _initializeRepositories();

      // Real action: Check permissions
      _updateStatus(l10n.checkingContactsPermissions);
      try {
        _safetyTimer?.cancel();
        if (mounted) {
          final shouldShow =
              await PermissionService.shouldShowContactsPermissionDialog();
          if (shouldShow) {
            await PermissionService.markContactsPermissionAsked();
          }
        }
      } catch (e) {
        // Ignore error
      }

      // Real action: Data is ready
      _updateStatus(l10n.dataUpdated);

      // Ensure minimum duration for smooth UX (only if initialization was very fast)
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime < minDuration) {
        final remainingTime = minDuration - elapsedTime;
        await Future.delayed(remainingTime);
      }

      _navigateToNextScreen();
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      if (mounted) {
        final l10n = context.l10n;
        setState(() {
          _errorMessage = '${l10n.errorInitializingApp} $e';
        });
      }
    }
  }

  Future<void> _initializeRepositories() async {
    try {
      // Create all repository instances (triggers initialize() asynchronously)
      final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
      final eventRepo = ref.read(eventRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final calendarRepo = ref.read(calendarRepositoryProvider);
      final groupRepo = ref.read(groupRepositoryProvider);

      // Wait for all repositories to complete initialization in parallel
      await Future.wait([
        subscriptionRepo.initialized,
        eventRepo.initialized,
        userRepo.initialized,
        calendarRepo.initialized,
        groupRepo.initialized,
      ]);

      // Ensure birthday calendar exists (calendar repo is guaranteed to be ready)
      await _ensureBirthdayCalendar();
    } catch (e) {
      // Continue anyway, repositories may still be partially functional
    }
  }

  Future<void> _ensureBirthdayCalendar() async {
    try {
      final calendarRepository = ref.read(calendarRepositoryProvider);
      final calendars = await calendarRepository.calendarsStream.first;
      final hasBirthdayCalendar = calendars.any(
        (cal) => cal.name == 'Cumpleaños' || cal.name == 'Birthdays',
      );

      if (!hasBirthdayCalendar) {
        await calendarRepository.createCalendar(
          name: 'Cumpleaños',
          description: 'Calendario para cumpleaños',
        );
      }
    } catch (e) {
      // Ignore errors
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  void _navigateToNextScreen() {
    if (mounted) {
      try {
        context.go('/events');
      } catch (e) {
        if (widget.nextScreen != null) {
          Navigator.of(context).pushReplacement(
            PlatformNavigation.platformPageRoute(
              builder: (_) => widget.nextScreen!,
            ),
          );
        } else {}
      }
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _isLoading = true;
      final l10n = context.l10n;
      _statusMessage = l10n.retrying;
    });
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePageScaffold(
      key: const Key('splash_screen_scaffold'),
      title: null,
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        gradient: AppStyles.splashGradient,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppStyles.colorWithOpacity(
                                              AppStyles.black87,
                                              0.1,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: PlatformWidgets.platformIcon(
                                        CupertinoIcons.calendar,
                                        color: AppStyles.white,
                                        size: 60,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    Text(
                                      l10n.appTitle,
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppStyles.black87,
                                        letterSpacing: -0.5,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      l10n.yourEventsAlwaysWithYou,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppStyles.grey600,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 80),

              if (_hasError) ...[
                PlatformWidgets.platformIcon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: AppStyles.grey500,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.oopsSomethingWentWrong,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.grey700,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppStyles.grey600,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 24),
                AdaptiveButton(
                  key: const Key('splash_screen_retry_button'),
                  config: AdaptiveButtonConfigExtended.submit(),
                  text: l10n.retry,
                  onPressed: _retry,
                ),
              ] else if (_isLoading) ...[
                Center(child: PlatformWidgets.platformLoadingIndicator()),
                const SizedBox(height: 24),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppStyles.grey700,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.pleaseWait,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppStyles.grey500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
