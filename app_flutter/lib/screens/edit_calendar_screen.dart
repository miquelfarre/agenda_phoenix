import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../ui/styles/app_styles.dart';
import '../widgets/adaptive_scaffold.dart';
import '../models/calendar.dart';
import '../core/state/app_state.dart';
import '../utils/calendar_permissions.dart';
import '../utils/error_message_parser.dart';
import '../ui/helpers/platform/dialog_helpers.dart';

class EditCalendarScreen extends ConsumerStatefulWidget {
  final String calendarId;

  const EditCalendarScreen({super.key, required this.calendarId});

  @override
  ConsumerState<EditCalendarScreen> createState() => _EditCalendarScreenState();
}

class _EditCalendarScreenState extends ConsumerState<EditCalendarScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isDiscoverable = true;
  bool _deleteAssociatedEvents = false;
  bool _isLoading = true;
  Calendar? _calendar;

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCalendar() async {
    try {
      final calendarRepository = ref.read(calendarRepositoryProvider);
      final calendar = calendarRepository.getCalendarById(
        int.parse(widget.calendarId),
      );

      if (calendar == null) {
        if (!mounted) return;
        DialogHelpers.showErrorDialogWithIcon(
          context,
          context.l10n.calendarNotFound,
        );
        context.pop();
        return;
      }

      // Verify user has permission to edit (owner OR admin)
      final canEdit = await CalendarPermissions.canEdit(
        calendar: calendar,
        repository: calendarRepository,
      );

      if (!canEdit) {
        if (!mounted) return;
        DialogHelpers.showErrorDialogWithIcon(
          context,
          context.l10n.noPermission,
        );
        context.pop();
        return;
      }

      setState(() {
        _calendar = calendar;
        _nameController.text = calendar.name;
        _descriptionController.text = calendar.description ?? '';
        _isDiscoverable = calendar.isDiscoverable;
        _deleteAssociatedEvents = calendar.deleteAssociatedEvents;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      DialogHelpers.showErrorDialogWithIcon(
        context,
        context.l10n.failedToLoadCalendar,
      );
      context.pop();
    }
  }

  Future<void> _updateCalendar() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      DialogHelpers.showErrorDialogWithIcon(
        context,
        context.l10n.calendarNameRequired,
      );
      return;
    }

    if (name.length > 100) {
      DialogHelpers.showErrorDialogWithIcon(
        context,
        context.l10n.calendarNameTooLong,
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.length > 500) {
      DialogHelpers.showErrorDialogWithIcon(
        context,
        context.l10n.calendarDescriptionTooLong,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updateData = <String, dynamic>{
        'name': name,
        'description': description.isEmpty ? null : description,
        'is_discoverable': _isDiscoverable,
      };
      await ref
          .read(calendarRepositoryProvider)
          .updateCalendar(int.parse(widget.calendarId), updateData);

      // Realtime handles refresh automatically via CalendarRepository

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;

      final errorMessage = ErrorMessageParser.parse(e, context);
      DialogHelpers.showErrorDialogWithIcon(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCalendar() async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(calendarRepositoryProvider)
          .deleteCalendar(
            int.parse(widget.calendarId),
            deleteAssociatedEvents: _deleteAssociatedEvents,
          );

      // Realtime handles refresh automatically via CalendarRepository

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;

      final errorMessage = ErrorMessageParser.parse(e, context);
      DialogHelpers.showErrorDialogWithIcon(context, errorMessage);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final l10n = context.l10n;
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteCalendar),
        content: Text(
          _deleteAssociatedEvents
              ? l10n.confirmDeleteCalendarWithEvents
              : l10n.confirmDeleteCalendarKeepEvents,
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_isLoading && _calendar == null) {
      return AdaptivePageScaffold(
        title: l10n.editCalendar,
        body: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return AdaptivePageScaffold(
      title: l10n.editCalendar,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => context.pop(),
        child: Text(l10n.cancel),
      ),
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : _updateCalendar,
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : Text(l10n.save),
        ),
      ],
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 16),
            if (_calendar!.isPublic) ...[
              _buildVisibilitySection(),
              const SizedBox(height: 16),
            ],
            _buildDeleteSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final l10n = context.l10n;

    return Container(
      margin: EdgeInsets.zero,
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.calendarInformation,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppStyles.grey700,
            ),
          ),
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _nameController,
            placeholder: l10n.calendarName,
            maxLength: 100,
            enabled: !_isLoading,
            decoration: BoxDecoration(
              border: Border.all(color: AppStyles.grey300),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _descriptionController,
            placeholder: l10n.calendarDescription,
            maxLines: 3,
            maxLength: 500,
            enabled: !_isLoading,
            decoration: BoxDecoration(
              border: Border.all(color: AppStyles.grey300),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
          ),
          const SizedBox(height: 16),
          CupertinoListTile(
            title: Text(l10n.publicCalendar),
            subtitle: Text(
              _calendar!.isPublic ? l10n.visibleToOthers : l10n.private,
            ),
            trailing: CupertinoSwitch(
              value: _calendar!.isPublic,
              onChanged: null,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilitySection() {
    final l10n = context.l10n;

    return Container(
      margin: EdgeInsets.zero,
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.visibility,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppStyles.grey700,
            ),
          ),
          const SizedBox(height: 16),
          CupertinoListTile(
            title: Text(l10n.discoverableCalendar),
            subtitle: Text(
              _isDiscoverable ? l10n.appearsInSearch : l10n.onlyViaShareLink,
            ),
            trailing: CupertinoSwitch(
              value: _isDiscoverable,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _isDiscoverable = value;
                      });
                    },
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteSection() {
    final l10n = context.l10n;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(CupertinoColors.systemRed, 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppStyles.colorWithOpacity(CupertinoColors.systemRed, 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.delete,
                color: CupertinoColors.systemRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.deleteCalendar,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.chooseWhatHappensToEvents,
            style: TextStyle(fontSize: 14, color: AppStyles.grey600),
          ),
          const SizedBox(height: 16),
          CupertinoListTile(
            title: Text(l10n.deleteAssociatedEvents),
            subtitle: Text(
              _deleteAssociatedEvents
                  ? l10n.eventsWillBeDeleted
                  : l10n.eventsWillBeKept,
            ),
            trailing: CupertinoSwitch(
              value: _deleteAssociatedEvents,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _deleteAssociatedEvents = value;
                      });
                    },
            ),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _isLoading ? null : _deleteCalendar,
              child: Text(l10n.deleteCalendar),
            ),
          ),
        ],
      ),
    );
  }
}
