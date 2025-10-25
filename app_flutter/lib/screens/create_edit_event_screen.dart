import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/event.dart';
import '../models/recurrence_pattern.dart';
import '../models/calendar.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../core/state/app_state.dart';
import '../widgets/custom_datetime_widget.dart';
import '../widgets/calendar_horizontal_selector.dart';
import '../widgets/timezone_horizontal_selector.dart';
import '../widgets/recurrence_time_selector.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import '../models/country.dart';
import '../services/country_service.dart';
import '../services/timezone_service.dart';
import '../services/config_service.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'base/base_form_screen.dart';
import '../core/providers/settings_provider.dart';

class CreateEditEventScreen extends BaseFormScreen {
  final Event? eventToEdit;
  final bool isRecurring;

  const CreateEditEventScreen({
    super.key,
    this.eventToEdit,
    this.isRecurring = false,
  });

  @override
  CreateEditEventScreenState createState() => CreateEditEventScreenState();
}

class CreateEditEventScreenState
    extends BaseFormScreenState<CreateEditEventScreen> {
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
  bool get _isRecurringEvent => getFieldValue<bool>('isRecurring') ?? false;
  List<RecurrencePattern> get _patterns =>
      getFieldValue<List<RecurrencePattern>>('patterns') ?? [];
  bool get _isBirthday => getFieldValue<bool>('isBirthday') ?? false;
  String? get _selectedCalendarId => getFieldValue<String?>('calendarId');

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
    if (widget.eventToEdit != null) {
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      setFieldValue('startDate', _normalizeToFiveMinutes(event.startDate));
      setFieldValue('isRecurring', event.isRecurringEvent);
      setFieldValue('patterns', event.recurrencePatterns.toList());
      setFieldValue('isBirthday', event.isBirthday);
      setFieldValue('calendarId', event.calendarId);
    } else {
      setFieldValue('startDate', _normalizeToFiveMinutes(DateTime.now()));
      setFieldValue('isRecurring', widget.isRecurring);
      setFieldValue('patterns', <RecurrencePattern>[]);
      setFieldValue('isBirthday', false);
      setFieldValue('calendarId', null);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  String get screenTitle => widget.eventToEdit == null
      ? context.l10n.createEvent
      : context.l10n.editEvent;

  @override
  String get submitButtonText =>
      widget.eventToEdit == null ? context.l10n.createEvent : context.l10n.save;

  @override
  bool get showSaveInNavBar => false;

  @override
  Future<bool> validateForm() async {
    final l10n = context.l10n;

    if (_titleController.text.trim().isEmpty) {
      setFieldError('title', l10n.fieldRequired(l10n.eventTitle));
      return false;
    }

    if (_isRecurringEvent) {
      if (_patterns.isEmpty) {
        setFieldError('patterns', l10n.addAtLeastOnePattern);
        return false;
      }
    }

    return true;
  }

  @override
  Future<bool> submitForm() async {
    try {
      final eventData = <String, dynamic>{
        'id': widget.eventToEdit?.id ?? -1,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'start_date': _selectedDate.toIso8601String(),
        'owner_id': ConfigService.instance.currentUserId,
        'is_recurring': _isRecurringEvent,
        'event_type': _isRecurringEvent ? 'parent' : 'standalone',
        'location': 'Madrid',
        'recurrence_pattern': null,
        'is_birthday': _isBirthday,
        'calendar_id': _selectedCalendarId,
        'timezone': _selectedTimezone,
        'city': _useCustomTimezone ? _customCity : _defaultCity,
        'country_code': _selectedCountry?.code ?? 'ES',
      };

      if (_isRecurringEvent) {
        eventData['patterns'] = _patterns.map((p) => p.toJson()).toList();
      }

      if (widget.eventToEdit != null) {
        await ref
            .read(eventServiceProvider)
            .updateEvent(
              eventId: widget.eventToEdit!.id!,
              name: eventData['title'],
              description: eventData['description'],
              startDate: eventData['start_date'] is DateTime
                  ? eventData['start_date']
                  : (eventData['start_date'] != null
                        ? DateTime.parse(eventData['start_date'].toString())
                        : null),
              eventType: eventData['is_recurring'] == true
                  ? 'recurring'
                  : 'regular',
              calendarId: eventData['calendar_id'],
            );
        // Realtime handles refresh automatically via EventRepository
      } else {
        await ref
            .read(eventServiceProvider)
            .createEvent(
              name: eventData['title'] ?? '',
              description: eventData['description'],
              startDate: eventData['start_date'] is DateTime
                  ? eventData['start_date']
                  : DateTime.parse(eventData['start_date'].toString()),
              eventType: eventData['is_recurring'] == true
                  ? 'recurring'
                  : 'regular',
              calendarId: eventData['calendar_id'],
            );
        // Realtime handles refresh automatically via EventRepository
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
    PlatformDialogHelpers.showSnackBar(
      message: widget.eventToEdit != null
          ? l10n.eventUpdated
          : l10n.eventCreated,
    );

    if (mounted) {
      Navigator.of(context).pop();
    } else {}
  }

  @override
  List<Widget> buildFormFields() {
    final l10n = context.l10n;
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () {
              setState(() {
                if (_isRecurringEvent) {
                  setFieldValue('isRecurring', false);
                  setFieldValue('patterns', <RecurrencePattern>[]);
                }
                if (_isBirthday) {
                  setFieldValue('isBirthday', false);
                  setFieldValue('calendarId', null);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (!_isRecurringEvent && !_isBirthday)
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
                border: (_isRecurringEvent || _isBirthday)
                    ? Border.all(color: CupertinoColors.systemGrey4, width: 1.5)
                    : null,
              ),
              child: Icon(
                CupertinoIcons.calendar,
                size: 28,
                color: (!_isRecurringEvent && !_isBirthday)
                    ? CupertinoColors.white
                    : CupertinoColors.systemGrey2,
              ),
            ),
          ),

          const SizedBox(width: 16),

          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () {
              setState(() {
                final willBeRecurring = !_isRecurringEvent;

                setFieldValue('isRecurring', willBeRecurring);

                if (willBeRecurring) {
                  if (_isBirthday) {
                    setFieldValue('isBirthday', false);
                    setFieldValue('calendarId', null);
                  }
                } else {
                  setFieldValue('patterns', <RecurrencePattern>[]);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isRecurringEvent
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.repeat,
                size: 28,
                color: _isRecurringEvent
                    ? CupertinoColors.white
                    : CupertinoColors.systemGrey,
              ),
            ),
          ),

          const SizedBox(width: 16),

          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () async {
              final willBeBirthday = !_isBirthday;
              setState(() {
                setFieldValue('isBirthday', willBeBirthday);

                if (willBeBirthday) {
                  if (_isRecurringEvent) {
                    setFieldValue('isRecurring', false);
                    setFieldValue('patterns', <RecurrencePattern>[]);
                  }

                  final dateOnly = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                  );
                  setFieldValue('startDate', dateOnly);

                  _useCustomCalendar = true;

                  final calendarsAsync = ref.read(calendarsStreamProvider);
                  calendarsAsync.whenData((calendars) {
                    try {
                      final birthdayCalendar = calendars.firstWhere(
                        (cal) =>
                            cal.name == 'Cumpleaños' || cal.name == 'Birthdays',
                      );
                      setFieldValue('calendarId', birthdayCalendar.id);
                    } catch (e) {
                      if (calendars.isNotEmpty) {
                        setFieldValue('calendarId', calendars.first.id);
                      }
                    }
                  });
                } else {
                  setFieldValue('calendarId', null);
                  _useCustomCalendar = false;
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isBirthday
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🎂',
                style: TextStyle(
                  fontSize: 28,
                  color: _isBirthday
                      ? CupertinoColors.white
                      : CupertinoColors.systemGrey,
                ),
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 24),

      buildTextField(
        fieldName: 'title',
        label: l10n.title,
        placeholder: l10n.eventNamePlaceholder,
        controller: _titleController,
        required: true,
      ),

      if (!_isBirthday) ...[
        const SizedBox(height: 16),
        buildTextField(
          fieldName: 'description',
          label: l10n.description,
          placeholder: l10n.addDetailsPlaceholder,
          controller: _descriptionController,
          maxLines: 3,
        ),
      ],

      if (!_isBirthday) ...[
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
              'Usar zona horaria personalizada',
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
            if (!_isBirthday) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.calendar, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Fecha de inicio',
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
                        Icon(Icons.today, size: 16),
                        SizedBox(width: 4),
                        Text(l10n.today, style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            CustomDateTimeWidget(
              key: _startDateKey,
              initialDateTime: _selectedDate,
              timezone: _selectedTimezone,
              locale: 'es',
              showTimePicker: !_isBirthday,
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

      if (_isRecurringEvent) ...[
        const SizedBox(height: 24),
        _buildPatternsSection(),
      ],

      if (!_isBirthday) ...[
        const SizedBox(height: 24),
        _buildCalendarSection(),
      ],

      if (getFieldError('title') != null)
        _buildErrorText(getFieldError('title')!),
      if (getFieldError('patterns') != null)
        _buildErrorText(getFieldError('patterns')!),
    ];
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        error,
        style: const TextStyle(fontSize: 14, color: CupertinoColors.systemRed),
      ),
    );
  }

  Widget _buildPatternsSection() {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recurrencePatterns,
          style: CupertinoTheme.of(
            context,
          ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          child: CupertinoButton(
            key: const Key('add_pattern_button'),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            color: AppStyles.primaryColor,
            borderRadius: BorderRadius.circular(12),
            onPressed: _addPattern,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _patterns.isEmpty
                      ? l10n.addFirstPattern
                      : l10n.addAnotherPattern,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_patterns.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.systemGrey4.resolveFrom(context),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  CupertinoIcons.calendar_badge_plus,
                  size: 32,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.noRecurrencePatterns,
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tapAddPatternToStart,
                  style: TextStyle(
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...List.generate(_patterns.length, (index) {
            final pattern = _patterns[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.systemGrey4.resolveFrom(context),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey
                        .resolveFrom(context)
                        .withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppStyles.colorWithOpacity(
                        AppStyles.primaryColor,
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.repeat,
                      color: AppStyles.primaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatPatternDisplay(pattern),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    key: Key(
                      'remove_pattern_${pattern.dayOfWeek}_${pattern.time}',
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _removePattern(index);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppStyles.colorWithOpacity(
                          AppStyles.errorColor,
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        CupertinoIcons.delete,
                        color: AppStyles.errorColor,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _addPattern() {
    _showPatternPicker();
  }

  void _removePattern(int index) {
    final currentPatterns = List<RecurrencePattern>.from(_patterns);
    currentPatterns.removeAt(index);
    setFieldValue('patterns', currentPatterns);
  }

  void _showPatternPicker() {
    final l10n = context.l10n;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        int selectedDay = 0;
        TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 0);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 450,
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: CupertinoColors.separator.resolveFrom(context),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          key: const Key('pattern_picker_cancel_button'),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(l10n.cancel),
                        ),
                        Text(
                          l10n.addFirstPattern,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        CupertinoButton(
                          key: const Key('pattern_picker_add_button'),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            final timeString =
                                "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00";

                            final newPattern = RecurrencePattern(
                              eventId: widget.eventToEdit?.id ?? -1,
                              dayOfWeek: selectedDay,
                              time: timeString,
                            );

                            final currentPatterns =
                                List<RecurrencePattern>.from(_patterns);
                            currentPatterns.add(newPattern);
                            setFieldValue('patterns', currentPatterns);

                            Navigator.of(context).pop();
                          },
                          child: Text(l10n.add),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.selectDayOfWeek,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedDay = index;
                              });
                            },
                            children: [
                              Text(l10n.monday),
                              Text(l10n.tuesday),
                              Text(l10n.wednesday),
                              Text(l10n.thursday),
                              Text(l10n.friday),
                              Text(l10n.saturday),
                              Text(l10n.sunday),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        SizedBox(
                          height: 80,
                          child: RecurrenceTimeSelector(
                            initialTime: selectedTime,
                            onSelected: (time) {
                              setModalState(() {
                                selectedTime = time;
                              });
                            },
                            minuteInterval: 5,
                            label: l10n.selectTime,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatPatternDisplay(RecurrencePattern pattern) {
    final l10n = context.l10n;
    final dayNames = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];

    final dayName = pattern.isValidDayOfWeek
        ? dayNames[pattern.dayOfWeek]
        : l10n.unknownError;
    return '$dayName @ ${pattern.time}';
  }

  Widget _buildCalendarSection() {
    final calendarsAsync = ref.watch(calendarsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildCalendarWidget(calendarsAsync)],
    );
  }

  Widget _buildCalendarWidget(AsyncValue<List<dynamic>> calendarsAsync) {
    if (calendarsAsync.isLoading) {
      return const CupertinoActivityIndicator();
    }

    if (calendarsAsync.hasError) {
      return Text(
        'Error loading calendars: ${calendarsAsync.error}',
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
        if (!_isBirthday) ...[
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
                'Asociar con calendario',
                style: AppStyles.bodyText.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        if (_useCustomCalendar || _isBirthday) ...[
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
                  isDisabled: _isBirthday,
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
                      await context.push('/communities/create');

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
}
