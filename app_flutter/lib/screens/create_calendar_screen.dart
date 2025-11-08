import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../widgets/adaptive_scaffold.dart';
import '../core/state/app_state.dart';
import '../utils/error_message_parser.dart';
import '../ui/helpers/platform/dialog_helpers.dart';

class CreateCalendarScreen extends ConsumerStatefulWidget {
  const CreateCalendarScreen({super.key});

  @override
  ConsumerState<CreateCalendarScreen> createState() =>
      _CreateCalendarScreenState();
}

class _CreateCalendarScreenState extends ConsumerState<CreateCalendarScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isPublic = false;
  bool _deleteAssociatedEvents = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCalendar() async {
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
      await ref
          .read(calendarRepositoryProvider)
          .createCalendar(
            name: name,
            description: description.isEmpty ? null : description,
            isPublic: _isPublic,
          );

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
}
