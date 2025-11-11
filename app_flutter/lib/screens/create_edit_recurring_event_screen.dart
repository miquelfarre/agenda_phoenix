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
import '../widgets/recurrence_time_selector.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import '../models/ui/country.dart';
import '../services/country_service.dart';
import '../services/timezone_service.dart';
import '../services/config_service.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import 'base/base_form_screen.dart';
import '../core/providers/settings_provider.dart';

class CreateEditRecurringEventScreen extends BaseFormScreen {
  final Event? eventToEdit;

  const CreateEditRecurringEventScreen({
    super.key,
    this.eventToEdit,
  });

  @override
  CreateEditRecurringEventScreenState createState() =>
      CreateEditRecurringEventScreenState();
}

class CreateEditRecurringEventScreenState
    extends BaseFormScreenState<CreateEditRecurringEventScreen> {

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

  List<Map<String, dynamic>> get _patterns =>
      getFieldValue<List<Map<String, dynamic>>>('patterns') ?? [];

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
      setFieldValue('patterns', event.recurrencePatterns.toList());
      setFieldValue('calendarId', event.calendarId);
    } else {
      setFieldValue('startDate', _normalizeToFiveMinutes(DateTime.now()));
      setFieldValue('patterns', <Map<String, dynamic>>[]);
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
  String get screenTitle => _isEditMode
      ? context.l10n.editEvent
      : context.l10n.createRecurringEvent;

  @override
  String get submitButtonText => _isEditMode
      ? context.l10n.save
      : context.l10n.createRecurringEvent;

  @override
  bool get showSaveInNavBar => false;

  @override
  Future<bool> validateForm() async {
    final l10n = context.l10n;

    if (_titleController.text.trim().isEmpty) {
      setFieldError('title', l10n.fieldRequired(l10n.eventTitle));
      return false;
    }

    if (_patterns.isEmpty) {
      setFieldError('patterns', l10n.addAtLeastOnePattern);
      return false;
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
        'is_recurring': true,
        'event_type': 'parent',
        'location': 'Madrid',
        'recurrence_pattern': null,
        'is_birthday': false,
        'calendar_id': _selectedCalendarId,
        'timezone': _selectedTimezone,
        'city': _useCustomTimezone ? _customCity : _defaultCity,
        'country_code': _selectedCountry?.code ?? 'ES',
        'patterns': _patterns,
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
      _buildPatternsSection(),

      const SizedBox(height: 24),
      _buildCalendarSection(),

      if (getFieldError('title') != null)
        _buildErrorText(getFieldError('title')!),
      if (getFieldError('patterns') != null)
        _buildErrorText(getFieldError('patterns')!),
    ];
  }

  Widget _buildPatternsSection() {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recurrencePatterns,
          style: CupertinoTheme.of(context)
              .textTheme
              .textStyle
              .copyWith(fontWeight: FontWeight.w600),
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
                      'remove_pattern_${pattern['dayOfWeek']}_${pattern['time']}',
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
    final currentPatterns = List<Map<String, dynamic>>.from(_patterns);
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

                            final newPattern = {
                              'eventId': widget.eventToEdit?.id ?? -1,
                              'dayOfWeek': selectedDay,
                              'time': timeString,
                            };

                            final currentPatterns =
                                List<Map<String, dynamic>>.from(_patterns);
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

  String _formatPatternDisplay(Map<String, dynamic> pattern) {
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

    final dayOfWeek = pattern['dayOfWeek'] as int? ?? 0;
    final time = pattern['time'] as String? ?? '00:00:00';
    final isValidDayOfWeek = dayOfWeek >= 0 && dayOfWeek < 7;

    final dayName =
        isValidDayOfWeek ? dayNames[dayOfWeek] : l10n.unknownError;
    return '$dayName @ $time';
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
        style: const TextStyle(
          color: CupertinoColors.systemRed,
          fontSize: 14,
        ),
      ),
    );
  }
}
