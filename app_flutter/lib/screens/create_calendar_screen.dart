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

      await calendarNotifier.createCalendar(
        name: name,
        description: description.isEmpty ? null : description,
        color: _selectedColor,
        isPublic: _isPublic,
        deleteAssociatedEvents: _deleteAssociatedEvents,
      );

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

    if (errorStr.contains('duplicate') || errorStr.contains('already exists')) {
      return 'A calendar with this name already exists.';
    }

    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Session expired. Please login again.';
    }

    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return 'You don\'t have permission to perform this action.';
    }

    return 'Failed to create calendar. Please try again.';
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

    return AdaptivePageScaffold(
      title: l10n.createCalendar,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => context.pop(),
        child: const Text('Cancel'),
      ),
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : _createCalendar,
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : const Text('Create'),
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
            subtitle: const Text('Others can search and subscribe'),
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
            subtitle: const Text('Delete events when this calendar is deleted'),
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
