import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain/event.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../core/state/app_state.dart';
import '../widgets/custom_datetime_widget.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import '../services/config_service.dart';
import 'base/base_form_screen.dart';
import '../core/providers/settings_provider.dart';

class CreateEditBirthdayEventScreen extends BaseFormScreen {
  final Event? eventToEdit;

  const CreateEditBirthdayEventScreen({super.key, this.eventToEdit});

  @override
  CreateEditBirthdayEventScreenState createState() =>
      CreateEditBirthdayEventScreenState();
}

class CreateEditBirthdayEventScreenState
    extends BaseFormScreenState<CreateEditBirthdayEventScreen> {
  bool get _isEditMode => widget.eventToEdit != null;
  final _titleController = TextEditingController();

  final _startDateKey = GlobalKey();

  String _selectedTimezone = 'Europe/Madrid';
  String _defaultCity = 'Madrid';

  DateTime get _selectedDate =>
      getFieldValue<DateTime>('startDate') ?? _getDateOnly(DateTime.now());

  int? get _selectedCalendarId => getFieldValue<int?>('calendarId');

  static DateTime _getDateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  @override
  void initState() {
    super.initState();
    _loadDefaultTimezone();
    _loadBirthdayCalendar();
  }

  void _loadDefaultTimezone() {
    final settingsAsync = ref.read(settingsNotifierProvider);
    settingsAsync.whenData((settings) {
      setState(() {
        _selectedTimezone = settings.defaultTimezone;
        _defaultCity = settings.defaultCity;
      });
    });
  }

  void _loadBirthdayCalendar() {
    final calendarsAsync = ref.read(calendarsStreamProvider);
    calendarsAsync.whenData((calendars) {
      try {
        final birthdayCalendar = calendars.firstWhere(
          (cal) => cal.name == 'Cumpleaños' || cal.name == 'Birthdays',
        );
        setFieldValue('calendarId', birthdayCalendar.id);
      } catch (e) {
        if (calendars.isNotEmpty) {
          setFieldValue('calendarId', calendars.first.id);
        }
      }
    });
  }

  @override
  void initializeFormData() {
    if (_isEditMode) {
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      setFieldValue('startDate', _getDateOnly(event.startDate));
      setFieldValue('calendarId', event.calendarId);
    } else {
      setFieldValue('startDate', _getDateOnly(DateTime.now()));
      setFieldValue('calendarId', null);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  String get screenTitle =>
      _isEditMode ? context.l10n.editEvent : context.l10n.createBirthday;

  @override
  String get submitButtonText =>
      _isEditMode ? context.l10n.save : context.l10n.createBirthday;

  @override
  bool get showSaveInNavBar => false;

  @override
  Future<bool> validateForm() async {
    final l10n = context.l10n;

    if (_titleController.text.trim().isEmpty) {
      setFieldError('title', l10n.fieldRequired(l10n.eventTitle));
      return false;
    }

    return true;
  }

  @override
  Future<bool> submitForm() async {
    try {
      final eventData = <String, dynamic>{
        'name': _titleController.text.trim(),
        'description': '',
        'start_date': _selectedDate.toIso8601String(),
        'owner_id': ConfigService.instance.currentUserId,
        'event_type': 'regular',
        'calendar_id': _selectedCalendarId,
      };

      if (_isEditMode) {
        await ref
            .read(eventServiceProvider)
            .updateEvent(widget.eventToEdit!.id!, eventData);
      } else {
        await ref.read(eventServiceProvider).createEvent(eventData);
      }

      return true;
    } catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        setError('${l10n.failedToSaveEvent}: $e');
      }
      return false;
    }
  }

  @override
  void onFormSubmitSuccess() {
    final l10n = context.l10n;
    final eventName = _titleController.text.trim();
    PlatformDialogHelpers.showSnackBar(
      context: context,
      message: _isEditMode
          ? '${l10n.eventUpdated.replaceAll(' exitosamente', '')}: "$eventName"'
          : '${l10n.eventCreated.replaceAll(' exitosamente', '')}: "$eventName"',
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  List<Widget> buildFormFields() {
    final l10n = context.l10n;
    return [
      buildTextField(
        fieldName: 'title',
        label: l10n.title,
        placeholder: l10n.personName,
        controller: _titleController,
        required: true,
      ),

      const SizedBox(height: 24),

      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.systemGrey5, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomDateTimeWidget(
              key: _startDateKey,
              initialDateTime: _selectedDate,
              timezone: _selectedTimezone,
              locale: 'es',
              showTimePicker: false,
              showTodayButton: false,
              onDateTimeChanged: (selection) {
                setState(() {
                  setFieldValue(
                    'startDate',
                    _getDateOnly(selection.selectedDate),
                  );
                });
              },
            ),
          ],
        ),
      ),

      if (getFieldError('title') != null)
        _buildErrorText(getFieldError('title')!),
    ];
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        error,
        style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 14),
      ),
    );
  }
}
