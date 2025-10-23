import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../widgets/adaptive_scaffold.dart';
import '../core/providers/calendar_provider.dart';
import '../models/calendar.dart';

class EditCalendarScreen extends ConsumerStatefulWidget {
  final String calendarId;

  const EditCalendarScreen({super.key, required this.calendarId});

  @override
  ConsumerState<EditCalendarScreen> createState() => _EditCalendarScreenState();
}

class _EditCalendarScreenState extends ConsumerState<EditCalendarScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedColor = '#2196F3';
  bool _isPublic = false;
  bool _deleteAssociatedEvents = false;
  bool _isLoading = true;
  Calendar? _calendar;

  final List<String> _colors = [
    '#2196F3',
    '#4CAF50',
    '#FF5722',
    '#FFC107',
    '#9C27B0',
    '#00BCD4',
    '#FF9800',
    '#795548',
  ];

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
      final calendarService = ref.read(calendarServiceProvider);
      final calendar = calendarService.getLocalCalendar(widget.calendarId);

      if (calendar == null) {
        if (!mounted) return;
        _showError('Calendar not found');
        context.pop();
        return;
      }

      setState(() {
        _calendar = calendar;
        _nameController.text = calendar.name;
        _descriptionController.text = calendar.description ?? '';
        _selectedColor = calendar.color;
        _isPublic = calendar.isShared;
        _deleteAssociatedEvents = calendar.deleteAssociatedEvents;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to load calendar');
      context.pop();
    }
  }

  Future<void> _updateCalendar() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showError('Calendar name is required');
      return;
    }

    if (name.length > 100) {
      _showError('Calendar name must be 100 characters or less');
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.length > 500) {
      _showError('Description must be 500 characters or less');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final calendarNotifier = ref.read(calendarsNotifierProvider.notifier);

      await calendarNotifier.updateCalendar(
        widget.calendarId,
        name: name,
        description: description.isEmpty ? null : description,
        color: _selectedColor,
      );

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;

      final errorMessage = _parseErrorMessage(e, 'update');
      _showError(errorMessage);
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
      final calendarNotifier = ref.read(calendarsNotifierProvider.notifier);
      await calendarNotifier.deleteCalendar(widget.calendarId);

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;

      final errorMessage = _parseErrorMessage(e, 'delete');
      _showError(errorMessage);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(context.l10n.deleteCalendar),
        content: Text(
          _deleteAssociatedEvents
              ? 'This will delete the calendar and all associated events. This action cannot be undone.'
              : 'This will delete the calendar but keep the events. This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _parseErrorMessage(dynamic error, String operation) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socket') ||
        errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorStr.contains('500') || errorStr.contains('server error')) {
      return 'Server error. Please try again later.';
    }

    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Session expired. Please login again.';
    }

    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return 'You don\'t have permission to $operation this calendar.';
    }

    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return 'Calendar not found. It may have been deleted.';
    }

    if (errorStr.contains('conflict') || errorStr.contains('409')) {
      if (operation == 'delete') {
        return 'Cannot delete calendar with associated events. Please remove events first or enable cascade delete.';
      }
    }

    return 'Failed to $operation calendar. Please try again.';
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          children: const [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.systemRed,
              size: 20,
            ),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
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
        child: const Text('Cancel'),
      ),
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : _updateCalendar,
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : const Text('Save'),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CupertinoTextField(
            controller: _nameController,
            placeholder: l10n.calendarName,
            maxLength: 100,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),

          CupertinoTextField(
            controller: _descriptionController,
            placeholder: l10n.calendarDescription,
            maxLines: 3,
            maxLength: 500,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 24),

          Text(
            l10n.calendarColor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map((color) {
              final isSelected = color == _selectedColor;
              return GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _parseColor(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          CupertinoListTile(
            title: const Text('Public Calendar'),
            subtitle: Text(_isPublic ? 'Visible to others' : 'Private'),
            trailing: CupertinoSwitch(value: _isPublic, onChanged: null),
          ),

          CupertinoListTile(
            title: Text(l10n.deleteAssociatedEvents),
            subtitle: Text(
              _deleteAssociatedEvents
                  ? 'Events will be deleted with calendar'
                  : 'Events will be kept when calendar is deleted',
            ),
            trailing: CupertinoSwitch(
              value: _deleteAssociatedEvents,
              onChanged: null,
            ),
          ),

          const SizedBox(height: 32),

          CupertinoButton.filled(
            onPressed: _isLoading ? null : _deleteCalendar,
            child: Text(l10n.deleteCalendar),
          ),
        ],
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
}
