import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/styles/app_styles.dart';

class LimitedTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final TextEditingController controller;
  final int maxLength;
  final int? maxLines;
  final int? minLines;
  final String? Function(String?)? validator;
  final bool showCounter;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final EdgeInsets? contentPadding;
  final dynamic border;
  final dynamic enabledBorder;
  final dynamic focusedBorder;
  final dynamic errorBorder;
  final Color? fillColor;
  final bool filled;
  final TextStyle? style;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextAlign textAlign;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool isRequired;
  final String? requiredFieldName;

  const LimitedTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.helperText,
    required this.controller,
    required this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.validator,
    this.showCounter = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.contentPadding,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.fillColor,
    this.filled = false,
    this.style,
    this.labelStyle,
    this.hintStyle,
    this.textAlign = TextAlign.start,
    this.focusNode,
    this.autofocus = false,
    this.isRequired = false,
    this.requiredFieldName,
  });

  @override
  State<LimitedTextField> createState() => _LimitedTextFieldState();
}

class _LimitedTextFieldState extends State<LimitedTextField> {
  String? _validationError;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;

    String? error;

    if (widget.isRequired && text.trim().isEmpty) {
      final fieldName = widget.requiredFieldName ?? widget.labelText ?? 'Field';
      error = context.l10n.fieldRequired(fieldName);
    }

    if (error == null && text.length > widget.maxLength) {
      error = context.l10n.textTooLong(widget.maxLength);
    }

    if (error == null && widget.validator != null) {
      error = widget.validator!(text);
    }

    if (_validationError != error) {
      setState(() {
        _validationError = error;
      });
    }

    if (widget.onChanged != null) {
      widget.onChanged!(text);
    }
  }

  String _buildCounterText() {
    if (!widget.showCounter) return '';

    final currentLength = widget.controller.text.length;
    final maxLength = widget.maxLength;

    final isNearLimit = currentLength > (maxLength * 0.8);
    final isAtLimit = currentLength >= maxLength;

    if (isAtLimit) {
      return '$currentLength/$maxLength';
    } else if (isNearLimit) {
      return '$currentLength/$maxLength';
    } else {
      return '$currentLength/$maxLength';
    }
  }

  Color _getCounterColor() {
    if (!widget.showCounter) return AppStyles.grey600;

    final currentLength = widget.controller.text.length;
    final maxLength = widget.maxLength;

    if (currentLength >= maxLength) {
      return AppStyles.red600;
    } else if (currentLength > (maxLength * 0.8)) {
      return AppStyles.orange600;
    } else {
      return AppStyles.grey600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = PlatformDetection.isIOS;

    if (isIOS) {
      return _buildCupertinoTextField(context);
    } else {
      return _buildMaterialTextField(context);
    }
  }

  Widget _buildMaterialTextField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: widget.controller,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onEditingComplete: widget.onEditingComplete,
          onSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          textAlign: widget.textAlign,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          style:
              widget.style ??
              AppStyles.bodyText.copyWith(fontSize: AppConstants.bodyFontSize),
          placeholder: widget.hintText,
          padding:
              widget.contentPadding ??
              const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
          decoration: BoxDecoration(
            color: widget.filled
                ? (widget.fillColor ??
                      CupertinoColors.tertiarySystemFill.resolveFrom(context))
                : null,
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
            border: _validationError != null
                ? Border.all(
                    color: CupertinoColors.destructiveRed.resolveFrom(context),
                  )
                : Border.all(
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
          ),
        ),
        if (_validationError != null) ...[
          const SizedBox(height: 4),
          Text(
            _validationError!,
            style: AppStyles.bodyTextSmall.copyWith(
              fontSize: AppConstants.captionFontSize,
              color: CupertinoColors.destructiveRed.resolveFrom(context),
            ),
          ),
        ],
        if (widget.showCounter) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _buildCounterText(),
                style: AppStyles.bodyTextSmall.copyWith(
                  fontSize: AppConstants.captionFontSize,
                  color: _getCounterColor(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCupertinoTextField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style:
                widget.labelStyle?.copyWith(decoration: TextDecoration.none) ??
                AppStyles.bodyText.copyWith(
                  fontSize: AppConstants.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
          ),
          const SizedBox(height: AppConstants.smallPadding / 2),
        ],
        CupertinoTextField(
          controller: widget.controller,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onEditingComplete: widget.onEditingComplete,
          onSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          textAlign: widget.textAlign,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          style:
              widget.style ??
              AppStyles.bodyText.copyWith(fontSize: AppConstants.bodyFontSize),
          placeholder: widget.hintText,
          prefix: widget.prefixIcon,
          suffix: widget.suffixIcon,
          padding:
              widget.contentPadding ??
              const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
          decoration: BoxDecoration(
            color:
                widget.fillColor ??
                CupertinoColors.tertiarySystemFill.resolveFrom(context),
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
            border: _validationError != null
                ? Border.all(
                    color: CupertinoColors.destructiveRed.resolveFrom(context),
                    width: 1,
                  )
                : Border.all(
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
          ),
        ),
        if (_validationError != null) ...[
          const SizedBox(height: 4),
          Text(
            _validationError!,
            style: AppStyles.bodyTextSmall.copyWith(
              fontSize: AppConstants.captionFontSize,
              color: CupertinoColors.destructiveRed.resolveFrom(context),
            ),
          ),
        ],
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: AppStyles.bodyTextSmall.copyWith(
              fontSize: AppConstants.captionFontSize,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
        if (widget.showCounter) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _buildCounterText(),
                style: AppStyles.bodyTextSmall.copyWith(
                  fontSize: AppConstants.captionFontSize,
                  color: _getCounterColor(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class EventTitleField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const EventTitleField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LimitedTextField(
      labelText: context.l10n.eventTitle,
      controller: controller,
      maxLength: AppConstants.maxEventTitleLength,
      validator: validator,
      onChanged: onChanged,
      isRequired: true,
      requiredFieldName: context.l10n.eventTitle,
      textInputAction: TextInputAction.next,
    );
  }
}

class EventDescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const EventDescriptionField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LimitedTextField(
      labelText: context.l10n.eventDescription,
      controller: controller,
      maxLength: AppConstants.maxEventDescriptionLength,
      maxLines: 3,
      minLines: 2,
      validator: validator,
      onChanged: onChanged,
      textInputAction: TextInputAction.newline,
    );
  }
}

class GroupNameField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const GroupNameField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LimitedTextField(
      labelText: context.l10n.groupName,
      controller: controller,
      maxLength: AppConstants.maxGroupNameLength,
      validator: validator,
      onChanged: onChanged,
      isRequired: true,
      requiredFieldName: context.l10n.groupName,
      textInputAction: TextInputAction.next,
    );
  }
}

class FullNameField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const FullNameField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LimitedTextField(
      labelText: context.l10n.fullName,
      controller: controller,
      maxLength: AppConstants.maxFullNameLength,
      validator: validator,
      onChanged: onChanged,
      isRequired: true,
      requiredFieldName: context.l10n.fullName,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.name,
    );
  }
}

class NotificationMessageField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const NotificationMessageField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LimitedTextField(
      labelText: context.l10n.notificationMessage,
      controller: controller,
      maxLength: AppConstants.maxNotificationMessageLength,
      maxLines: 3,
      minLines: 2,
      validator: validator,
      onChanged: onChanged,
      isRequired: true,
      requiredFieldName: context.l10n.notificationMessage,
      textInputAction: TextInputAction.newline,
    );
  }
}
