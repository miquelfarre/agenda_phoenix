import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import '../models/event.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../core/state/app_state.dart';
import '../services/api_client.dart';
import '../utils/app_exceptions.dart';
import 'adaptive/adaptive_button.dart';
import 'adaptive/configs/button_config.dart';

class PersonalNoteWidget extends ConsumerStatefulWidget {
  final Event event;
  final ValueChanged<Event> onEventUpdated;

  const PersonalNoteWidget({
    super.key,
    required this.event,
    required this.onEventUpdated,
  });

  @override
  ConsumerState<PersonalNoteWidget> createState() => _PersonalNoteWidgetState();
}

class _PersonalNoteWidgetState extends ConsumerState<PersonalNoteWidget> {
  late Event _event;
  bool _isEditing = false;
  bool _isSaving = false;
  final TextEditingController _controller = TextEditingController();
  String? _currentNote;
  bool _preventOverwrite = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _currentNote = _event.personalNote;
    if (_currentNote != null && _currentNote!.isNotEmpty) {
      _controller.text = _currentNote!;
    }
  }

  @override
  void didUpdateWidget(covariant PersonalNoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.event.id != widget.event.id ||
        oldWidget.event.personalNote != widget.event.personalNote) {
      _event = widget.event;

      if (!_isSaving && !_preventOverwrite) {
        _currentNote = _event.personalNote;
        _controller.text = _currentNote ?? '';
        _isEditing = false;
      } else {}
    } else {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNote(String note) async {
    final l10n = context.l10n;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      if (note.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _isEditing = false;
            _controller.text = _currentNote ?? '';
          });
        }
        return;
      }

      await ApiClientFactory.instance.post(
        '/api/v1/users/me/event-note',
        body: {'event_id': _event.id!, 'note': note},
      );

      if (mounted) {
        setState(() {
          _currentNote = note;
          _isEditing = false;
        });

        final updatedEvent = _event.copyWith(personalNote: note);
        _event = updatedEvent;
        widget.onEventUpdated(updatedEvent);

        await ref.read(eventStateProvider.notifier).refresh();

        PlatformWidgets.showGlobalPlatformMessage(
          message: l10n.personalNoteUpdated,
        );
      }
    } catch (e) {
      if (mounted) {
        PlatformWidgets.showGlobalPlatformMessage(
          message: l10n.errorSavingNote,
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteNote() async {
    final l10n = context.l10n;
    if (_isSaving) return;

    setState(() => _isSaving = true);
    _preventOverwrite = true;

    try {
      await ApiClientFactory.instance.delete(
        '/api/v1/users/me/event-note/${_event.id}',
      );

      await ref.read(eventStateProvider.notifier).refresh();

      _currentNote = null;
      _controller.clear();

      final updatedEvent = _event.copyWith(personalNote: null);
      _event = updatedEvent;
      widget.onEventUpdated(updatedEvent);

      if (mounted) {
        setState(() {
          _isEditing = false;
        });

        PlatformWidgets.showGlobalPlatformMessage(
          message: l10n.personalNoteDeleted,
        );
      }
    } on ApiException catch (apiErr) {
      if (apiErr.statusCode == 404) {
        await ref.read(eventStateProvider.notifier).refresh();

        _currentNote = null;
        _controller.clear();

        final updatedEvent = _event.copyWith(personalNote: null);
        _event = updatedEvent;
        widget.onEventUpdated(updatedEvent);

        if (mounted) {
          setState(() {
            _isEditing = false;
          });

          PlatformWidgets.showGlobalPlatformMessage(
            message: l10n.personalNoteDeleted,
          );
        }
      } else {
        if (mounted) {
          PlatformWidgets.showGlobalPlatformMessage(
            message: l10n.errorSavingNote,
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        PlatformWidgets.showGlobalPlatformMessage(
          message: l10n.errorSavingNote,
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);

        Future.delayed(Duration(milliseconds: 500), () {
          _preventOverwrite = false;
        });
      }
    }
  }

  Future<void> _confirmAndDelete() async {
    final l10n = context.l10n;
    final shouldDelete = await PlatformWidgets.showPlatformConfirmDialog(
      context,
      title: l10n.deleteNote,
      message: l10n.deleteNoteConfirmation,
      confirmText: l10n.delete,
      cancelText: l10n.cancel,
      isDestructive: true,
    );

    if (shouldDelete == true) {
      await _deleteNote();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isIOS = PlatformWidgets.isIOS;
    final hasNote = _currentNote != null && _currentNote!.isNotEmpty;

    return Container(
      margin: EdgeInsets.zero,
      decoration: AppStyles.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppStyles.blueShade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PlatformWidgets.platformIcon(
                    isIOS ? CupertinoIcons.doc_text : CupertinoIcons.doc,
                    color: AppStyles.blue600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.personalNote,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (!hasNote && !_isEditing)
              _buildAddButton(l10n)
            else if (hasNote && !_isEditing)
              _buildViewCard(l10n)
            else if (_isEditing)
              _buildEditForm(l10n, isIOS),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(dynamic l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.privateNoteHint,
          style: TextStyle(fontSize: 14, color: AppStyles.grey600),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AdaptiveButton(
            config: AdaptiveButtonConfigExtended.submit(),
            text: l10n.addPersonalNote,
            icon: CupertinoIcons.add,
            onPressed: () => setState(() => _isEditing = true),
          ),
        ),
      ],
    );
  }

  Widget _buildViewCard(dynamic l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppStyles.blueShade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppStyles.blueShade100),
          ),
          child: Text(
            _currentNote!,
            style: TextStyle(fontSize: 14, color: AppStyles.black87),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AdaptiveButton(
                config: AdaptiveButtonConfig.primary(),
                text: l10n.editPersonalNote,
                icon: CupertinoIcons.pencil,
                onPressed: _isSaving
                    ? null
                    : () => setState(() {
                        _isEditing = true;
                        _controller.text = _currentNote ?? '';
                      }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdaptiveButton(
                config: AdaptiveButtonConfigExtended.destructive(),
                text: l10n.delete,
                icon: CupertinoIcons.trash,
                onPressed: _isSaving ? null : _confirmAndDelete,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm(dynamic l10n, bool isIOS) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: _controller,
          placeholder: l10n.addPersonalNoteHint,
          maxLines: 4,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppStyles.grey300),
            borderRadius: BorderRadius.circular(8),
          ),
          enabled: !_isSaving,
        ),

        const SizedBox(height: 16),

        if (_isSaving)
          Center(child: PlatformWidgets.platformLoadingIndicator())
        else
          Row(
            children: [
              Expanded(
                child: AdaptiveButton(
                  config: AdaptiveButtonConfigExtended.cancel(),
                  text: l10n.cancel,
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _controller.text = _currentNote ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdaptiveButton(
                  config: AdaptiveButtonConfigExtended.submit(),
                  text: l10n.save,
                  onPressed: () async {
                    final note = _controller.text.trim();
                    await _saveNote(note);
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}
