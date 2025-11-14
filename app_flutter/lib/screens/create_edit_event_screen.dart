import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/domain/event.dart';
import '../models/domain/calendar.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../core/state/app_state.dart';
import '../widgets/custom_datetime_widget.dart';
import '../widgets/calendar_horizontal_selector.dart';
import '../widgets/timezone_horizontal_selector.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import '../models/ui/country.dart';
import '../services/country_service.dart';
import '../services/timezone_service.dart';
import '../services/config_service.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'base/base_form_screen.dart';
import '../core/providers/settings_provider.dart';
import '../widgets/create_tabs_selector.dart';
import 'create_edit_recurring_event_screen.dart';
import 'create_edit_calendar_screen.dart';
import 'create_edit_birthday_event_screen.dart';

class CreateEditEventScreen extends BaseFormScreen {
  final Event? eventToEdit;
  final int? preselectedCalendarId;

  const CreateEditEventScreen({
    super.key,
    this.eventToEdit,
    this.preselectedCalendarId,
  });

  @override
  CreateEditEventScreenState createState() => CreateEditEventScreenState();
}

class CreateEditEventScreenState
    extends BaseFormScreenState<CreateEditEventScreen> {
  bool get _isEditMode => widget.eventToEdit != null;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _startDateKey = GlobalKey();

  Country? _selectedCountry;
  String _selectedTimezone = 'Europe/Madrid';
  String _defaultCity = 'Madrid';
  String? _customCity;
  bool _useCustomTimezone = false;

  bool _useCustomCalendar = false;

  DateTime get _selectedDate =>
      getFieldValue<DateTime>('startDate') ??
      _normalizeToFiveMinutes(DateTime.now());

  int? get _selectedCalendarId => getFieldValue<int?>('calendarId');

  static DateTime _normalizeToFiveMinutes(DateTime dateTime) {
    final normalizedMinute = (dateTime.minute / 5).round() * 5;
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      normalizedMinute,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDefaultTimezone();
  }

  void _loadDefaultTimezone() {
    final settingsAsync = ref.read(settingsNotifierProvider);
    settingsAsync.whenData((settings) {
      setState(() {
        _selectedTimezone = settings.defaultTimezone;
        _defaultCity = settings.defaultCity;
        _customCity = settings.defaultCity;

        _selectedCountry = CountryService.getCountryByCode(
          settings.defaultCountryCode,
        );
      });
    });
  }

  @override
  void initializeFormData() {
    if (_isEditMode) {
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      setFieldValue('startDate', _normalizeToFiveMinutes(event.startDate));
      setFieldValue('calendarId', event.calendarId);
      _selectedTimezone = event.timezone;
      _useCustomTimezone = event.timezone != 'Europe/Madrid';

      if (event.calendarId != null) {
        _useCustomCalendar = true;
      }
    } else {
      setFieldValue('startDate', _normalizeToFiveMinutes(DateTime.now()));

      // If calendar was preselected (from calendar detail screen), use it
      if (widget.preselectedCalendarId != null) {
        setFieldValue('calendarId', widget.preselectedCalendarId);
        _useCustomCalendar = true;
      } else {
        setFieldValue('calendarId', null);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  String get screenTitle =>
      _isEditMode ? context.l10n.editEvent : context.l10n.createEvent;

  @override
  String get submitButtonText =>
      _isEditMode ? context.l10n.save : context.l10n.createEvent;

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
        'description': _descriptionController.text.trim(),
        'start_date': _selectedDate.toIso8601String(),
        'timezone': _selectedTimezone,
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
  void onFormSubmitSuccess() async {
    final l10n = context.l10n;
    final eventName = _titleController.text.trim();
    PlatformDialogHelpers.showSnackBar(
      context: context,
      message: _isEditMode
          ? '${l10n.eventUpdated.replaceAll(' exitosamente', '')}: "$eventName"'
          : '${l10n.eventCreated.replaceAll(' exitosamente', '')}: "$eventName"',
    );

    if (mounted) {
      // Wait a bit for the stream to propagate to other screens
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _onOptionSelected(CreateOptionType option) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) {
          switch (option) {
            case CreateOptionType.recurring:
              return const CreateEditRecurringEventScreen();
            case CreateOptionType.birthday:
              return const CreateEditBirthdayEventScreen();
            case CreateOptionType.calendar:
              return const CreateEditCalendarScreen();
          }
        },
      ),
    );
  }

  @override
  List<Widget> buildFormFields() {
    final l10n = context.l10n;
    return [
      if (!_isEditMode) ...[
        CreateOptionsSelector(onOptionSelected: _onOptionSelected),
        const SizedBox(height: 32),
        Text(
          l10n.createEvent,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
      ],
      buildTextField(
        fieldName: 'title',
        label: l10n.title,
        placeholder: l10n.eventNamePlaceholder,
        controller: _titleController,
        required: true,
      ),

      const SizedBox(height: 16),
      buildTextField(
        fieldName: 'description',
        label: l10n.description,
        placeholder: l10n.addDetailsPlaceholder,
        controller: _descriptionController,
        maxLines: 3,
      ),

      const SizedBox(height: 24),

      Row(
        children: [
          CupertinoSwitch(
            value: _useCustomTimezone,
            onChanged: (value) {
              setState(() {
                _useCustomTimezone = value;
                if (!value) {
                  _loadDefaultTimezone();
                }
              });
            },
          ),
          const SizedBox(width: 12),
          Text(
            l10n.useCustomTimezone,
            style: AppStyles.bodyText.copyWith(fontSize: 16),
          ),
        ],
      ),
      const SizedBox(height: 16),

      if (_useCustomTimezone) ...[
        TimezoneHorizontalSelector(
          initialCountry: _selectedCountry,
          initialTimezone: _selectedTimezone,
          initialCity: _customCity,
          onChanged: (country, timezone, city) {
            setState(() {
              _selectedCountry = country;
              _selectedTimezone = timezone;
              _customCity = city;
            });
          },
        ),
      ] else ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CupertinoColors.systemGrey5, width: 1),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.globe, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _defaultCity,
                      style: AppStyles.bodyText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedTimezone,
                      style: AppStyles.bodyText.copyWith(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                TimezoneService.getCurrentOffset(_selectedTimezone),
                style: AppStyles.bodyText.copyWith(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.calendar, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.startDate,
                      style: AppStyles.bodyText.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  onPressed: () {
                    final state = _startDateKey.currentState as dynamic;
                    state?.scrollToToday();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.today, size: 16),
                      const SizedBox(width: 4),
                      Text(l10n.today, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomDateTimeWidget(
              key: _startDateKey,
              initialDateTime: _selectedDate,
              timezone: _selectedTimezone,
              locale: 'es',
              showTimePicker: true,
              showTodayButton: false,
              onDateTimeChanged: (selection) {
                setState(() {
                  setFieldValue('startDate', selection.selectedDate);
                });
              },
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),
      _buildCalendarSection(),

      if (getFieldError('title') != null)
        _buildErrorText(getFieldError('title')!),
    ];
  }

  Widget _buildCalendarSection() {
    final calendarsAsync = ref.watch(calendarsStreamProvider);
    final l10n = context.l10n;

    if (calendarsAsync.isLoading) {
      return const CupertinoActivityIndicator();
    }

    if (calendarsAsync.hasError) {
      return Text(
        l10n.errorLoadingCalendarsDetail(calendarsAsync.error.toString()),
        style: const TextStyle(color: CupertinoColors.systemRed),
      );
    }

    if (!calendarsAsync.hasValue) {
      return const SizedBox.shrink();
    }

    final calendars = calendarsAsync.value!;

    if (calendars.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CupertinoSwitch(
              value: _useCustomCalendar,
              onChanged: (value) {
                setState(() {
                  _useCustomCalendar = value;
                  if (!value) {
                    setFieldValue('calendarId', null);
                  }
                });
              },
            ),
            const SizedBox(width: 12),
            Text(
              l10n.associateWithCalendar,
              style: AppStyles.bodyText.copyWith(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_useCustomCalendar) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CalendarHorizontalSelector(
                  calendars: calendars.cast<Calendar>(),
                  selectedCalendarId: _selectedCalendarId,
                  onSelected: (calendarId) {
                    setFieldValue('calendarId', calendarId);
                  },
                  isDisabled: false,
                ),
              ),

              const SizedBox(width: 12),

              SizedBox(
                height: 55,
                child: Center(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () async {
                      await context.push('/calendars/create');

                      ref.invalidate(calendarsStreamProvider);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CupertinoColors.systemGrey4),
                      ),
                      child: const Icon(
                        CupertinoIcons.add_circled,
                        size: 24,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
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
