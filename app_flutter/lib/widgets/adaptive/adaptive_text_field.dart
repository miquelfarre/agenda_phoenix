import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'platform_theme.dart';
import 'adaptive_card.dart';

class AdaptiveTextField extends StatefulWidget implements IAdaptiveWidget, ITextFieldWidget {
  @override
  final AdaptiveTextFieldConfig config;
  @override
  final TextEditingController? controller;
  @override
  final String? placeholder;
  @override
  final List<TextFieldValidator> validators;
  @override
  final ValidationState validationState;
  @override
  final void Function(ValidationState state)? onValidationChanged;
  @override
  final void Function(String text)? onTextChanged;
  @override
  final bool enabled;

  const AdaptiveTextField({super.key, required this.config, this.controller, this.placeholder, this.validators = const [], this.validationState = const ValidationState(isValid: true, characterCount: 0), this.onValidationChanged, this.onTextChanged, this.enabled = true});

  @override
  State<AdaptiveTextField> createState() => _AdaptiveTextFieldState();

  @override
  PlatformTheme get theme => PlatformTheme.adaptive(null);

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }

  @override
  ValidationResult validate() {
    final issues = <ValidationIssue>[];

    if (config.maxLength != null && config.maxLength! <= 0) {
      issues.add(const ValidationIssue(message: 'Max length should be positive', severity: ValidationSeverity.error));
    }

    if (config.variant == TextFieldVariant.email && validators.isEmpty) {
      issues.add(const ValidationIssue(message: 'Email fields should have email validation', severity: ValidationSeverity.warning, suggestion: 'Add email validator'));
    }

    return ValidationResult(isValid: issues.where((i) => i.severity == ValidationSeverity.error).isEmpty, issues: issues, severity: issues.isEmpty ? ValidationSeverity.none : issues.map((i) => i.severity).reduce((a, b) => a.index > b.index ? a : b));
  }
}

class _AdaptiveTextFieldState extends State<AdaptiveTextField> {
  late TextEditingController _controller;
  bool _obscureText = false;
  ValidationState _currentValidationState = const ValidationState(isValid: true, characterCount: 0);

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _obscureText = widget.config.obscureText;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    _validateText(text);
    widget.onTextChanged?.call(text);
  }

  void _validateText(String text) {
    if (widget.config.validationMode == ValidationMode.none) return;

    final characterCount = text.length;
    bool isValid = true;
    String? errorMessage;

    if (widget.config.maxLength != null && characterCount > widget.config.maxLength!) {
      isValid = false;
      errorMessage = 'Text exceeds maximum length of ${widget.config.maxLength}';
    }

    for (final validator in widget.validators) {
      final result = validator.validate(text);
      if (!result.isValid) {
        isValid = false;
        errorMessage = result.issues.isNotEmpty ? result.issues.first.message : 'Validation failed';
        break;
      }
    }

    final newState = ValidationState(isValid: isValid, errorMessage: errorMessage, characterCount: characterCount);

    if (newState != _currentValidationState) {
      setState(() {
        _currentValidationState = newState;
      });
      widget.onValidationChanged?.call(newState);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = PlatformTheme.adaptive(context);

    switch (widget.config.variant) {
      case TextFieldVariant.standard:
        return _buildStandardTextField(theme);
      case TextFieldVariant.limited:
        return _buildLimitedTextField(theme);
      case TextFieldVariant.multiline:
        return _buildMultilineTextField(theme);
      case TextFieldVariant.email:
        return _buildEmailTextField(theme);
      case TextFieldVariant.phone:
        return _buildPhoneTextField(theme);
      case TextFieldVariant.password:
        return _buildPasswordTextField(theme);
    }
  }

  Widget _buildStandardTextField(PlatformTheme theme) {
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      decoration: _buildInputDecoration(theme),
      keyboardType: widget.config.inputType,
      obscureText: _obscureText,
      autocorrect: widget.config.autocorrect,
      enableSuggestions: widget.config.enableSuggestions,
      inputFormatters: _buildInputFormatters(),
    );
  }

  Widget _buildLimitedTextField(PlatformTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(controller: _controller, enabled: widget.enabled, decoration: _buildInputDecoration(theme), keyboardType: widget.config.inputType, maxLength: widget.config.maxLength, inputFormatters: _buildInputFormatters()),
        if (widget.config.showCounter) _buildCharacterCounter(theme),
      ],
    );
  }

  Widget _buildMultilineTextField(PlatformTheme theme) {
    return TextFormField(controller: _controller, enabled: widget.enabled, decoration: _buildInputDecoration(theme), keyboardType: TextInputType.multiline, maxLines: null, minLines: 3, inputFormatters: _buildInputFormatters());
  }

  Widget _buildEmailTextField(PlatformTheme theme) {
    return TextFormField(controller: _controller, enabled: widget.enabled, decoration: _buildInputDecoration(theme), keyboardType: TextInputType.emailAddress, autocorrect: false, enableSuggestions: false, inputFormatters: _buildInputFormatters());
  }

  Widget _buildPhoneTextField(PlatformTheme theme) {
    return TextFormField(controller: _controller, enabled: widget.enabled, decoration: _buildInputDecoration(theme), keyboardType: TextInputType.phone, inputFormatters: _buildInputFormatters());
  }

  Widget _buildPasswordTextField(PlatformTheme theme) {
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      decoration: _buildInputDecoration(theme).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      obscureText: _obscureText,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: _buildInputFormatters(),
    );
  }

  InputDecoration _buildInputDecoration(PlatformTheme theme) {
    return InputDecoration(
      hintText: widget.placeholder,
      errorText: _currentValidationState.errorMessage,
      border: OutlineInputBorder(borderRadius: theme.defaultBorderRadius),
      enabledBorder: OutlineInputBorder(
        borderRadius: theme.defaultBorderRadius,
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: theme.defaultBorderRadius,
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: theme.defaultBorderRadius,
        borderSide: BorderSide(color: theme.errorColor),
      ),
      filled: true,
      fillColor: theme.surfaceColor,
    );
  }

  Widget _buildCharacterCounter(PlatformTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text('${_currentValidationState.characterCount}${widget.config.maxLength != null ? '/${widget.config.maxLength}' : ''}', style: theme.textStyle.copyWith(fontSize: 12, color: theme.secondaryColor)),
    );
  }

  List<TextInputFormatter> _buildInputFormatters() {
    final formatters = <TextInputFormatter>[];

    if (widget.config.maxLength != null) {
      formatters.add(LengthLimitingTextInputFormatter(widget.config.maxLength));
    }

    switch (widget.config.variant) {
      case TextFieldVariant.phone:
        formatters.add(FilteringTextInputFormatter.digitsOnly);
        break;
      case TextFieldVariant.email:
        formatters.add(FilteringTextInputFormatter.deny(RegExp(r'\s')));
        break;
      default:
        break;
    }

    return formatters;
  }
}

class AdaptiveTextFieldConfig {
  final TextFieldVariant variant;
  final ValidationMode validationMode;
  final bool showCounter;
  final int? maxLength;
  final TextInputType inputType;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;

  const AdaptiveTextFieldConfig({required this.variant, required this.validationMode, required this.showCounter, this.maxLength, required this.inputType, required this.obscureText, required this.autocorrect, required this.enableSuggestions});

  factory AdaptiveTextFieldConfig.standard() => const AdaptiveTextFieldConfig(variant: TextFieldVariant.standard, validationMode: ValidationMode.onChanged, showCounter: false, inputType: TextInputType.text, obscureText: false, autocorrect: true, enableSuggestions: true);

  factory AdaptiveTextFieldConfig.limited(int maxLength) => AdaptiveTextFieldConfig(variant: TextFieldVariant.limited, validationMode: ValidationMode.onChanged, showCounter: true, maxLength: maxLength, inputType: TextInputType.text, obscureText: false, autocorrect: true, enableSuggestions: true);

  factory AdaptiveTextFieldConfig.email() => const AdaptiveTextFieldConfig(variant: TextFieldVariant.email, validationMode: ValidationMode.onSubmitted, showCounter: false, inputType: TextInputType.emailAddress, obscureText: false, autocorrect: false, enableSuggestions: false);

  factory AdaptiveTextFieldConfig.password() => const AdaptiveTextFieldConfig(variant: TextFieldVariant.password, validationMode: ValidationMode.onChanged, showCounter: false, inputType: TextInputType.visiblePassword, obscureText: true, autocorrect: false, enableSuggestions: false);
}

enum TextFieldVariant { standard, limited, multiline, email, phone, password }

enum ValidationMode { none, onChanged, onSubmitted, onFocusLost }

class ValidationState {
  final bool isValid;
  final String? errorMessage;
  final int characterCount;
  final bool isValidating;

  const ValidationState({required this.isValid, this.errorMessage, required this.characterCount, this.isValidating = false});

  factory ValidationState.valid(int characterCount) => ValidationState(isValid: true, characterCount: characterCount);

  factory ValidationState.invalid(String errorMessage, int characterCount) => ValidationState(isValid: false, errorMessage: errorMessage, characterCount: characterCount);

  factory ValidationState.validating(int characterCount) => ValidationState(isValid: true, characterCount: characterCount, isValidating: true);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidationState && other.isValid == isValid && other.errorMessage == errorMessage && other.characterCount == characterCount && other.isValidating == isValidating;
  }

  @override
  int get hashCode => Object.hash(isValid, errorMessage, characterCount, isValidating);
}

abstract class TextFieldValidator {
  String get name;
  ValidationResult validate(String text);
}

abstract class ITextFieldWidget extends IAdaptiveWidget {
  AdaptiveTextFieldConfig get config;
  TextEditingController? get controller;
  String? get placeholder;
  List<TextFieldValidator> get validators;
  ValidationState get validationState;
  void Function(ValidationState state)? get onValidationChanged;
  void Function(String text)? get onTextChanged;
}
