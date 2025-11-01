import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../ui/helpers/platform/platform_detection.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/adaptive/adaptive_button.dart';
import '../core/state/app_state.dart';
import '../models/calendar.dart';
import '../services/config_service.dart';
import 'calendar_events_screen.dart';

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
        _showSuccess(context.l10n.subscribedTo(calendar.name));
        _searchController.clear();
        setState(() {
          _searchingByHash = false;
          _hashSearchResult = null;
        });

        // Realtime will automatically update the calendars list
      }
    } catch (e) {
      if (mounted) {
        _showError(_parseErrorMessage(e, 'subscribe to'));
      }
    }
  }

  Future<void> _deleteOrLeaveCalendar(Calendar calendar) async {
    final l10n = context.l10n;
    final userId = ConfigService.instance.currentUserId;
    final isOwner = calendar.ownerId == userId.toString();

    // Mostrar confirmación diferente según sea owner o no
    final shouldDelete = await _showConfirmDialog(
      title: isOwner ? l10n.deleteCalendar : l10n.leaveCalendar,
      message: isOwner ? l10n.confirmDeleteCalendarWithEvents : l10n.confirmLeaveCalendar,
    );

    if (shouldDelete != true) return;

    try {
      final repository = ref.read(calendarRepositoryProvider);

      if (isOwner) {
        // Owner: eliminar el calendario completo (esto eliminará todos los eventos del calendario)
        await repository.deleteCalendar(int.parse(calendar.id));
        if (mounted) {
          _showSuccess(l10n.success);
        }
      } else {
        // No owner: dejar el calendario (unsubscribe/leave)
        if (calendar.shareHash != null) {
          // Tipo 2: Calendario público - desuscribirse por share_hash
          await repository.unsubscribeByShareHash(calendar.shareHash!);
        } else {
          // Tipo 1: Calendario privado - eliminar membresía
          await repository.unsubscribeFromCalendar(int.parse(calendar.id));
        }
        if (mounted) {
          _showSuccess(l10n.calendarLeft);
        }
      }

      // Realtime will automatically update the calendars list
    } catch (e) {
      if (mounted) {
        _showError(l10n.error);
      }
    }
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
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _searchingByHash ? _buildHashSearchResults() : _buildMyCalendarsList(),
        ),
      ],
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
              style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHashSearchResults() {
    final l10n = context.l10n;

    if (_loadingHashSearch) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_hashSearchError != null) {
      return EmptyState(
        icon: CupertinoIcons.search,
        message: _hashSearchError!,
      );
    }

    if (_hashSearchResult != null) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildHashResultCard(_hashSearchResult!),
        ],
      );
    }

    return EmptyState(
      icon: CupertinoIcons.search,
      message: l10n.enterCodePrecededByHash,
    );
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
                decoration: BoxDecoration(
                  color: _parseColor(calendar.color),
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
              const Icon(CupertinoIcons.person_2, size: 16, color: CupertinoColors.systemGrey),
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

  Widget _buildMyCalendarsList() {
    final calendarsAsync = ref.watch(calendarsStreamProvider);
    final searchQuery = _searchController.text.toLowerCase();

    return calendarsAsync.when(
      data: (calendars) {
        // Filtrar calendarios por nombre si hay búsqueda
        final filteredCalendars = searchQuery.isEmpty
            ? calendars
            : calendars.where((cal) => cal.name.toLowerCase().contains(searchQuery)).toList();

        if (calendars.isEmpty) {
          return EmptyState(
            icon: CupertinoIcons.calendar,
            message: context.l10n.noCalendarsYet,
            subtitle: context.l10n.noCalendarsSearchByCode,
            actionLabel: context.l10n.createCalendar,
            onAction: () => context.push('/calendars/create'),
          );
        }

        if (filteredCalendars.isEmpty && searchQuery.isNotEmpty) {
          return EmptyState(
            icon: CupertinoIcons.search,
            message: context.l10n.noCalendarsFound,
          );
        }

        return ListView.separated(
          physics: const ClampingScrollPhysics(),
          itemCount: filteredCalendars.length,
          itemBuilder: (context, index) {
            return _buildCalendarItem(filteredCalendars[index]);
          },
          separatorBuilder: (context, index) {
            return Container(
              height: 0.5,
              margin: const EdgeInsets.only(left: 72),
              color: CupertinoColors.separator,
            );
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) {
        return EmptyState(
          icon: CupertinoIcons.exclamationmark_triangle,
          message: error.toString(),
        );
      },
    );
  }

  Widget _buildCalendarItem(Calendar calendar) {
    final l10n = context.l10n;
    final userId = ConfigService.instance.currentUserId;
    final isOwner = calendar.ownerId == userId.toString();

    return CupertinoListTile(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => CalendarEventsScreen(
              calendarId: int.parse(calendar.id),
              calendarName: calendar.name,
              calendarColor: calendar.color,
            ),
          ),
        );
      },
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _parseColor(calendar.color),
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
            isOwner ? l10n.owner : (calendar.shareHash != null ? l10n.subscriber : l10n.member),
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

  Color _parseColor(String colorString) {
    try {
      final hex = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return CupertinoColors.systemBlue;
    }
  }

  String _parseErrorMessage(dynamic error, String operation) {
    final errorStr = error.toString().toLowerCase();
    final l10n = context.l10n;

    if (errorStr.contains('socket') || errorStr.contains('network') || errorStr.contains('connection')) {
      return l10n.noInternetConnection;
    }

    if (errorStr.contains('timeout')) {
      return l10n.requestTimedOut;
    }

    if (errorStr.contains('500') || errorStr.contains('server error')) {
      return l10n.serverError;
    }

    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return l10n.sessionExpired;
    }

    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return l10n.noPermissionToOperation(operation);
    }

    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return l10n.calendarNotFoundDeleted;
    }

    if (errorStr.contains('already subscribed')) {
      return l10n.alreadySubscribed;
    }

    if (errorStr.contains('not subscribed')) {
      return l10n.notSubscribed;
    }

    return l10n.failedToOperationCalendar(operation);
  }

  Future<bool?> _showConfirmDialog({required String title, required String message}) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.leave),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.systemRed, size: 20),
            const SizedBox(width: 8),
            Text(context.l10n.error),
          ],
        ),
        content: Padding(padding: const EdgeInsets.only(top: 8), child: Text(message)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_circle, color: CupertinoColors.systemGreen, size: 20),
            const SizedBox(width: 8),
            Text(context.l10n.success),
          ],
        ),
        content: Padding(padding: const EdgeInsets.only(top: 8), child: Text(message)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }
}
