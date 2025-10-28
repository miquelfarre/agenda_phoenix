import 'package:flutter/material.dart';
import '../adaptive_text_field.dart';

extension AdaptiveTextFieldConfigExtended on AdaptiveTextFieldConfig {
  static AdaptiveTextFieldConfig name() => const AdaptiveTextFieldConfig(variant: TextFieldVariant.standard, validationMode: ValidationMode.onChanged, showCounter: false, inputType: TextInputType.name, obscureText: false, autocorrect: true, enableSuggestions: true);

  static AdaptiveTextFieldConfig search() => const AdaptiveTextFieldConfig(variant: TextFieldVariant.standard, validationMode: ValidationMode.none, showCounter: false, inputType: TextInputType.text, obscureText: false, autocorrect: false, enableSuggestions: true);

  static AdaptiveTextFieldConfig url() => const AdaptiveTextFieldConfig(variant: TextFieldVariant.standard, validationMode: ValidationMode.onSubmitted, showCounter: false, inputType: TextInputType.url, obscureText: false, autocorrect: false, enableSuggestions: false);

  static AdaptiveTextFieldConfig number() => const AdaptiveTextFieldConfig(variant: TextFieldVariant.standard, validationMode: ValidationMode.onChanged, showCounter: false, inputType: TextInputType.number, obscureText: false, autocorrect: false, enableSuggestions: false);

  static AdaptiveTextFieldConfig description() => const AdaptiveTextFieldConfig(variant: TextFieldVariant.multiline, validationMode: ValidationMode.none, showCounter: true, maxLength: 500, inputType: TextInputType.multiline, obscureText: false, autocorrect: true, enableSuggestions: true);

  static AdaptiveTextFieldConfig comment() => const AdaptiveTextFieldConfig(variant: TextFieldVariant.multiline, validationMode: ValidationMode.none, showCounter: true, maxLength: 1000, inputType: TextInputType.multiline, obscureText: false, autocorrect: true, enableSuggestions: true);

  static AdaptiveTextFieldConfig limitedText(int maxLength) => AdaptiveTextFieldConfig(variant: TextFieldVariant.limited, validationMode: ValidationMode.onChanged, showCounter: true, maxLength: maxLength, inputType: TextInputType.text, obscureText: false, autocorrect: true, enableSuggestions: true);

  static AdaptiveTextFieldConfig custom({
    TextFieldVariant variant = TextFieldVariant.standard,
    ValidationMode validationMode = ValidationMode.onChanged,
    bool showCounter = false,
    int? maxLength,
    TextInputType inputType = TextInputType.text,
    bool obscureText = false,
    bool autocorrect = true,
    bool enableSuggestions = true,
  }) => AdaptiveTextFieldConfig(variant: variant, validationMode: validationMode, showCounter: showCounter, maxLength: maxLength, inputType: inputType, obscureText: obscureText, autocorrect: autocorrect, enableSuggestions: enableSuggestions);
}

class TextFieldConfigBuilder {
  TextFieldVariant _variant = TextFieldVariant.standard;
  ValidationMode _validationMode = ValidationMode.onChanged;
  bool _showCounter = false;
  int? _maxLength;
  TextInputType _inputType = TextInputType.text;
  bool _obscureText = false;
  bool _autocorrect = true;
  bool _enableSuggestions = true;

  TextFieldConfigBuilder variant(TextFieldVariant variant) {
    _variant = variant;
    return this;
  }

  TextFieldConfigBuilder validationMode(ValidationMode mode) {
    _validationMode = mode;
    return this;
  }

  TextFieldConfigBuilder showCounter([bool show = true]) {
    _showCounter = show;
    return this;
  }

  TextFieldConfigBuilder maxLength(int length) {
    _maxLength = length;
    return this;
  }

  TextFieldConfigBuilder inputType(TextInputType type) {
    _inputType = type;
    return this;
  }

  TextFieldConfigBuilder obscureText([bool obscure = true]) {
    _obscureText = obscure;
    return this;
  }

  TextFieldConfigBuilder autocorrect([bool correct = true]) {
    _autocorrect = correct;
    return this;
  }

  TextFieldConfigBuilder enableSuggestions([bool enable = true]) {
    _enableSuggestions = enable;
    return this;
  }

  AdaptiveTextFieldConfig build() {
    return AdaptiveTextFieldConfig(variant: _variant, validationMode: _validationMode, showCounter: _showCounter, maxLength: _maxLength, inputType: _inputType, obscureText: _obscureText, autocorrect: _autocorrect, enableSuggestions: _enableSuggestions);
  }
}

class TextFieldConfigs {
  static const username = AdaptiveTextFieldConfig(variant: TextFieldVariant.standard, validationMode: ValidationMode.onChanged, showCounter: false, inputType: TextInputType.text, obscureText: false, autocorrect: false, enableSuggestions: false);

  static const passwordField = AdaptiveTextFieldConfig(variant: TextFieldVariant.password, validationMode: ValidationMode.onChanged, showCounter: false, inputType: TextInputType.visiblePassword, obscureText: true, autocorrect: false, enableSuggestions: false);

  static const confirmPassword = AdaptiveTextFieldConfig(variant: TextFieldVariant.password, validationMode: ValidationMode.onChanged, showCounter: false, inputType: TextInputType.visiblePassword, obscureText: true, autocorrect: false, enableSuggestions: false);

  static const firstName = AdaptiveTextFieldConfig(variant: TextFieldVariant.standard, validationMode: ValidationMode.onChanged, showCounter: false, inputType: TextInputType.name, obscureText: false, autocorrect: true, enableSuggestions: true);

  static const lastName = AdaptiveTextFieldConfig(variant: TextFieldVariant.standard, validationMode: ValidationMode.onChanged, showCounter: false, inputType: TextInputType.name, obscureText: false, autocorrect: true, enableSuggestions: true);

  static const phoneNumber = AdaptiveTextFieldConfig(variant: TextFieldVariant.phone, validationMode: ValidationMode.onChanged, showCounter: false, inputType: TextInputType.phone, obscureText: false, autocorrect: false, enableSuggestions: false);

  static const eventTitle = AdaptiveTextFieldConfig(variant: TextFieldVariant.limited, validationMode: ValidationMode.onChanged, showCounter: true, maxLength: 100, inputType: TextInputType.text, obscureText: false, autocorrect: true, enableSuggestions: true);

  static const eventDescription = AdaptiveTextFieldConfig(variant: TextFieldVariant.multiline, validationMode: ValidationMode.none, showCounter: true, maxLength: 500, inputType: TextInputType.multiline, obscureText: false, autocorrect: true, enableSuggestions: true);

  static const eventLocation = AdaptiveTextFieldConfig(variant: TextFieldVariant.standard, validationMode: ValidationMode.none, showCounter: false, inputType: TextInputType.streetAddress, obscureText: false, autocorrect: true, enableSuggestions: true);

  static const searchEvents = AdaptiveTextFieldConfig(variant: TextFieldVariant.standard, validationMode: ValidationMode.none, showCounter: false, inputType: TextInputType.text, obscureText: false, autocorrect: false, enableSuggestions: true);

  static const searchContacts = AdaptiveTextFieldConfig(variant: TextFieldVariant.standard, validationMode: ValidationMode.none, showCounter: false, inputType: TextInputType.name, obscureText: false, autocorrect: false, enableSuggestions: true);

  static const messageText = AdaptiveTextFieldConfig(variant: TextFieldVariant.multiline, validationMode: ValidationMode.none, showCounter: true, maxLength: 1000, inputType: TextInputType.multiline, obscureText: false, autocorrect: true, enableSuggestions: true);

  static const invitationMessage = AdaptiveTextFieldConfig(variant: TextFieldVariant.multiline, validationMode: ValidationMode.none, showCounter: true, maxLength: 300, inputType: TextInputType.multiline, obscureText: false, autocorrect: true, enableSuggestions: true);

  static const displayName = AdaptiveTextFieldConfig(variant: TextFieldVariant.limited, validationMode: ValidationMode.onChanged, showCounter: true, maxLength: 50, inputType: TextInputType.name, obscureText: false, autocorrect: true, enableSuggestions: true);

  static const bioText = AdaptiveTextFieldConfig(variant: TextFieldVariant.multiline, validationMode: ValidationMode.none, showCounter: true, maxLength: 200, inputType: TextInputType.multiline, obscureText: false, autocorrect: true, enableSuggestions: true);

  static const groupName = AdaptiveTextFieldConfig(variant: TextFieldVariant.limited, validationMode: ValidationMode.onChanged, showCounter: true, maxLength: 80, inputType: TextInputType.text, obscureText: false, autocorrect: true, enableSuggestions: true);

  static const groupDescription = AdaptiveTextFieldConfig(variant: TextFieldVariant.multiline, validationMode: ValidationMode.none, showCounter: true, maxLength: 300, inputType: TextInputType.multiline, obscureText: false, autocorrect: true, enableSuggestions: true);

  static const ageField = AdaptiveTextFieldConfig(variant: TextFieldVariant.standard, validationMode: ValidationMode.onChanged, showCounter: false, inputType: TextInputType.number, obscureText: false, autocorrect: false, enableSuggestions: false);

  static const capacityField = AdaptiveTextFieldConfig(variant: TextFieldVariant.standard, validationMode: ValidationMode.onChanged, showCounter: false, inputType: TextInputType.number, obscureText: false, autocorrect: false, enableSuggestions: false);
}
