import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../widgets/adaptive_scaffold.dart';
import '../core/providers/calendar_provider.dart';

class CreateCalendarScreen extends ConsumerStatefulWidget {
  const CreateCalendarScreen({super.key});

  @override
  ConsumerState<CreateCalendarScreen> createState() =>
      _CreateCalendarScreenState();
}

class _CreateCalendarScreenState extends ConsumerState<CreateCalendarScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedColor = '#2196F3';
  bool _isPublic = false;
  bool _deleteAssociatedEvents = false;
  bool _isLoading = false;

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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCalendar() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showError(context.l10n.calendarNameRequired);
      return;
    }

    if (name.length > 100) {
      _showError(context.l10n.calendarNameTooLong);
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.length > 500) {
      _showError(context.l10n.calendarDescriptionTooLong);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(calendarServiceProvider)
          .createCalendar(
            name: name,
            description: description.isEmpty ? null : description,
            color: _selectedColor,
            isPublic: _isPublic,
          );

      // Realtime handles refresh automatically via CalendarRepository

      if (!mounted) return;

      context.pop();
    } catch (e) {
      if (!mounted) return;

      final errorMessage = _parseErrorMessage(e);
      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _parseErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    final l10n = context.l10n;

    if (errorStr.contains('socket') ||
        errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return l10n.noInternetCheckNetwork;
    }

    if (errorStr.contains('timeout')) {
      return l10n.requestTimedOut;
    }

    if (errorStr.contains('500') || errorStr.contains('server error')) {
      return l10n.serverError;
    }

    if (errorStr.contains('duplicate') || errorStr.contains('already exists')) {
      return l10n.calendarNameExists;
    }

    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return l10n.sessionExpired;
    }

    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return l10n.noPermission;
    }

    return l10n.failedToCreateCalendar;
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.systemRed,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(context.l10n.error),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(context.l10n.ok),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AdaptivePageScaffold(
      title: l10n.createCalendar,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => context.pop(),
        child: Text(l10n.cancel),
      ),
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : _createCalendar,
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : Text(l10n.create),
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
            title: Text(l10n.publicCalendar),
            subtitle: Text(l10n.othersCanSearchAndSubscribe),
            trailing: CupertinoSwitch(
              value: _isPublic,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
            ),
          ),

          CupertinoListTile(
            title: Text(l10n.deleteAssociatedEvents),
            subtitle: Text(l10n.deleteEventsWithCalendar),
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
