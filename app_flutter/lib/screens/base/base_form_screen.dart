import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'base_screen_state.dart';

abstract class BaseFormScreen extends ConsumerStatefulWidget {
  const BaseFormScreen({super.key});
}

abstract class BaseFormScreenState<W extends BaseFormScreen>
    extends ConsumerState<W>
    with BaseScreenState<W> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  final Map<String, String?> _fieldErrors = {};
  Map<String, String?> get fieldErrors => _fieldErrors;

  final Map<String, dynamic> _formData = {};
  Map<String, dynamic> get formData => _formData;

  bool _isFormDirty = false;
  bool get isFormDirty => _isFormDirty;

  @override
  void initState() {
    super.initState();
    initializeFormData();
  }

  void initializeFormData();

  Future<bool> validateForm();

  Future<bool> submitForm();

  List<Widget> buildFormFields();

  String get screenTitle => context.l10n.form;

  String get submitButtonText => context.l10n.save;

  String get cancelButtonText => context.l10n.cancel;

  bool get showCancelButton => true;

  bool get showSaveInNavBar => true;

  bool get confirmCancelIfDirty => false;

  String get unsavedChangesMessage => context.l10n.unsavedChangesWarning;

  void setFieldValue(String fieldName, dynamic value) {
    if (_formData[fieldName] != value) {
      setState(() {
        _formData[fieldName] = value;
        _isFormDirty = true;

        _fieldErrors.remove(fieldName);
      });
    }
  }

  T? getFieldValue<T>(String fieldName) {
    return _formData[fieldName] as T?;
  }

  void setFieldError(String fieldName, String? error) {
    setState(() {
      if (error != null) {
        _fieldErrors[fieldName] = error;
      } else {
        _fieldErrors.remove(fieldName);
      }
    });
  }

  String? getFieldError(String fieldName) {
    return _fieldErrors[fieldName];
  }

  void clearFieldErrors() {
    setState(() {
      _fieldErrors.clear();
    });
  }

  String? validateField(String fieldName, dynamic value) {
    return null;
  }

  Future<void> handleSubmit() async {
    if (_isSubmitting) return;

    clearFieldErrors();

    final isValid = await validateForm();
    if (!isValid) {
      if (!mounted) return;
      showErrorDialog(context.l10n.pleaseCorrectErrors);
      return;
    }

    _isSubmitting = true;
    setState(() {});

    try {
      final success = await submitForm();
      if (success) {
        _isFormDirty = false;
        onFormSubmitSuccess();
      }
    } catch (e) {
      if (!mounted) return;
      setError('${context.l10n.failedToSubmitForm}: $e');
    } finally {
      _isSubmitting = false;
      if (mounted) setState(() {});
    }
  }

  void onFormSubmitSuccess() {
    showSuccessMessage(context.l10n.formSubmittedSuccessfully);
    goBack();
  }

  Future<void> handleCancel() async {
    if (_isFormDirty && confirmCancelIfDirty) {
      final shouldCancel = await showCancelConfirmationDialog();
      if (shouldCancel != true) {
        return;
      }
    }

    goBack();
  }

  Future<bool?> showCancelConfirmationDialog() {
    final l10n = context.l10n;
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text(unsavedChangesMessage),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.leave),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.stay),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: buildNavigationBar(),
      child: buildBody(),
    );
  }

  CupertinoNavigationBar buildNavigationBar() {
    return CupertinoNavigationBar(
      leading: showCancelButton
          ? CupertinoNavigationBarBackButton(
              onPressed: handleCancel,
            )
          : null,
      middle: Text(screenTitle),
      trailing: showSaveInNavBar
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _isSubmitting ? null : handleSubmit,
              child: _isSubmitting
                  ? const CupertinoActivityIndicator()
                  : Text(submitButtonText),
            )
          : null,
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return buildLoadingWidget(message: context.l10n.loadingForm);
    }

    if (errorMessage != null) {
      return buildErrorWidget(
        message: errorMessage,
        onRetry: () {
          clearError();
          initializeFormData();
        },
      );
    }

    return SafeArea(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...buildFormFields(),
                    const SizedBox(height: 32),
                    if (!showSaveInNavBar) buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSubmitButton() {
    return CupertinoButton.filled(
      onPressed: _isSubmitting ? null : handleSubmit,
      child: _isSubmitting
          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
          : Text(submitButtonText),
    );
  }

  Widget buildTextField({
    required String fieldName,
    required String label,
    String? placeholder,
    bool required = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextEditingController? controller,
  }) {
    final error = getFieldError(fieldName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        CupertinoTextFormFieldRow(
          controller: controller,
          placeholder: placeholder ?? label,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Border.all(
              color: error != null
                  ? CupertinoColors.systemRed
                  : CupertinoColors.separator,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          validator: (value) {
            final fieldError =
                validator?.call(value) ?? validateField(fieldName, value);
            if (fieldError != null) {
              setFieldError(fieldName, fieldError);
            }
            return fieldError;
          },
          onChanged: (value) {
            setFieldValue(fieldName, value);
            onChanged?.call(value);
          },
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemRed,
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildPickerField<T>({
    required String fieldName,
    required String label,
    required List<T> options,
    required String Function(T) getOptionLabel,
    bool required = false,
    String? placeholder,
  }) {
    final value = getFieldValue<T>(fieldName);
    final error = getFieldError(fieldName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showPicker(fieldName, options, getOptionLabel),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: error != null
                    ? CupertinoColors.systemRed
                    : CupertinoColors.separator,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value != null
                      ? getOptionLabel(value)
                      : (placeholder ?? context.l10n.selectLabel(label)),
                  style: TextStyle(
                    color: value != null
                        ? CupertinoColors.label
                        : CupertinoColors.placeholderText,
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_down,
                  color: CupertinoColors.separator,
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemRed,
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  void _showPicker<T>(
    String fieldName,
    List<T> options,
    String Function(T) getOptionLabel,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SizedBox(
        height: 250,
        child: CupertinoPicker(
          itemExtent: 32,
          scrollController: FixedExtentScrollController(),
          onSelectedItemChanged: (index) {
            setFieldValue(fieldName, options[index]);
          },
          children: options
              .map((option) => Center(child: Text(getOptionLabel(option))))
              .toList(),
        ),
      ),
    );
  }

  Widget buildSwitchField({
    required String fieldName,
    required String label,
    String? description,
  }) {
    final value = getFieldValue<bool>(fieldName) ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: (newValue) {
                setFieldValue(fieldName, newValue);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
