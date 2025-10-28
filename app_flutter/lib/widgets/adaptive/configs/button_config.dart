import 'package:flutter/material.dart';
import '../adaptive_button.dart';

extension AdaptiveButtonConfigExtended on AdaptiveButtonConfig {
  static AdaptiveButtonConfig destructive() => const AdaptiveButtonConfig(variant: ButtonVariant.primary, size: ButtonSize.medium, backgroundColor: Color(0xFFFF3B30), textColor: Colors.white, fullWidth: false, iconPosition: IconPosition.leading);

  static AdaptiveButtonConfig submit() => const AdaptiveButtonConfig(variant: ButtonVariant.primary, size: ButtonSize.medium, fullWidth: true, iconPosition: IconPosition.leading);

  static AdaptiveButtonConfig cancel() => const AdaptiveButtonConfig(variant: ButtonVariant.secondary, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.leading);

  static AdaptiveButtonConfig small() => const AdaptiveButtonConfig(variant: ButtonVariant.secondary, size: ButtonSize.small, fullWidth: false, iconPosition: IconPosition.leading);

  static AdaptiveButtonConfig large() => const AdaptiveButtonConfig(variant: ButtonVariant.primary, size: ButtonSize.large, fullWidth: true, iconPosition: IconPosition.leading);

  static AdaptiveButtonConfig iconOnly() => const AdaptiveButtonConfig(variant: ButtonVariant.icon, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.only);

  static AdaptiveButtonConfig floatingAction() => const AdaptiveButtonConfig(variant: ButtonVariant.fab, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.only);

  static AdaptiveButtonConfig link() => const AdaptiveButtonConfig(variant: ButtonVariant.text, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.trailing);

  static AdaptiveButtonConfig custom({ButtonVariant variant = ButtonVariant.primary, ButtonSize size = ButtonSize.medium, Color? backgroundColor, Color? textColor, bool fullWidth = false, IconPosition iconPosition = IconPosition.leading, double? borderRadius}) =>
      AdaptiveButtonConfig(variant: variant, size: size, backgroundColor: backgroundColor, textColor: textColor, fullWidth: fullWidth, iconPosition: iconPosition, borderRadius: borderRadius);
}

class ButtonConfigBuilder {
  ButtonVariant _variant = ButtonVariant.primary;
  ButtonSize _size = ButtonSize.medium;
  Color? _backgroundColor;
  Color? _textColor;
  bool _fullWidth = false;
  IconPosition _iconPosition = IconPosition.leading;
  double? _borderRadius;

  ButtonConfigBuilder variant(ButtonVariant variant) {
    _variant = variant;
    return this;
  }

  ButtonConfigBuilder size(ButtonSize size) {
    _size = size;
    return this;
  }

  ButtonConfigBuilder backgroundColor(Color color) {
    _backgroundColor = color;
    return this;
  }

  ButtonConfigBuilder textColor(Color color) {
    _textColor = color;
    return this;
  }

  ButtonConfigBuilder fullWidth([bool fullWidth = true]) {
    _fullWidth = fullWidth;
    return this;
  }

  ButtonConfigBuilder iconPosition(IconPosition position) {
    _iconPosition = position;
    return this;
  }

  ButtonConfigBuilder borderRadius(double radius) {
    _borderRadius = radius;
    return this;
  }

  AdaptiveButtonConfig build() {
    return AdaptiveButtonConfig(variant: _variant, size: _size, backgroundColor: _backgroundColor, textColor: _textColor, fullWidth: _fullWidth, iconPosition: _iconPosition, borderRadius: _borderRadius);
  }
}

class ButtonConfigs {
  static const saveButton = AdaptiveButtonConfig(variant: ButtonVariant.primary, size: ButtonSize.medium, fullWidth: true, iconPosition: IconPosition.leading);

  static const createButton = AdaptiveButtonConfig(variant: ButtonVariant.primary, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.leading);

  static const continueButton = AdaptiveButtonConfig(variant: ButtonVariant.primary, size: ButtonSize.large, fullWidth: true, iconPosition: IconPosition.trailing);

  static const editButton = AdaptiveButtonConfig(variant: ButtonVariant.secondary, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.leading);

  static const shareButton = AdaptiveButtonConfig(variant: ButtonVariant.secondary, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.leading);

  static const viewButton = AdaptiveButtonConfig(variant: ButtonVariant.text, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.trailing);

  static const deleteButton = AdaptiveButtonConfig(variant: ButtonVariant.primary, size: ButtonSize.medium, backgroundColor: Color(0xFFFF3B30), textColor: Colors.white, fullWidth: false, iconPosition: IconPosition.leading);

  static const removeButton = AdaptiveButtonConfig(variant: ButtonVariant.secondary, size: ButtonSize.small, textColor: Color(0xFFFF3B30), fullWidth: false, iconPosition: IconPosition.leading);

  static const cancelButton = AdaptiveButtonConfig(variant: ButtonVariant.text, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.leading);

  static const closeButton = AdaptiveButtonConfig(variant: ButtonVariant.icon, size: ButtonSize.small, fullWidth: false, iconPosition: IconPosition.only);

  static const backButton = AdaptiveButtonConfig(variant: ButtonVariant.icon, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.only);

  static const nextButton = AdaptiveButtonConfig(variant: ButtonVariant.primary, size: ButtonSize.medium, fullWidth: true, iconPosition: IconPosition.trailing);

  static const addFAB = AdaptiveButtonConfig(variant: ButtonVariant.fab, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.only);

  static const composeFAB = AdaptiveButtonConfig(variant: ButtonVariant.fab, size: ButtonSize.large, fullWidth: false, iconPosition: IconPosition.only);

  static const loginButton = AdaptiveButtonConfig(variant: ButtonVariant.primary, size: ButtonSize.large, fullWidth: true, iconPosition: IconPosition.leading);

  static const registerButton = AdaptiveButtonConfig(variant: ButtonVariant.secondary, size: ButtonSize.large, fullWidth: true, iconPosition: IconPosition.leading);

  static const forgotPasswordButton = AdaptiveButtonConfig(variant: ButtonVariant.text, size: ButtonSize.small, fullWidth: false, iconPosition: IconPosition.trailing);

  static const likeButton = AdaptiveButtonConfig(variant: ButtonVariant.icon, size: ButtonSize.medium, textColor: Color(0xFFFF3B30), fullWidth: false, iconPosition: IconPosition.only);

  static const shareIconButton = AdaptiveButtonConfig(variant: ButtonVariant.icon, size: ButtonSize.medium, fullWidth: false, iconPosition: IconPosition.only);

  static const commentButton = AdaptiveButtonConfig(variant: ButtonVariant.text, size: ButtonSize.small, fullWidth: false, iconPosition: IconPosition.leading);
}
