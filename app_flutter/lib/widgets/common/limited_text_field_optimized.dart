import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import '../../ui/styles/app_styles.dart';
import 'base_text_field.dart';

class LimitedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final int maxLength;
  final int? maxLines;
  final bool showCounter;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool isRequired;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const LimitedTextField({
    super.key,
    required this.controller,
    required this.maxLength,
    this.labelText,
    this.hintText,
    this.helperText,
    this.maxLines = 1,
    this.showCounter = true,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.enabled = true,
    this.isRequired = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<LimitedTextField> createState() => _LimitedTextFieldState();
}

class _LimitedTextFieldState extends State<LimitedTextField> {
  String? _errorText;

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
    if (mounted) {
      setState(() {
        _errorText = _validateText(widget.controller.text);
      });
      widget.onChanged?.call(widget.controller.text);
    }
  }

  String? _validateText(String text) {
    if (widget.isRequired && text.trim().isEmpty) {
      final l10n = context.l10n;
      return l10n.fieldRequired(widget.labelText ?? l10n.untitled);
    }

    if (widget.validator != null) {
      return widget.validator!(text);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentLength = widget.controller.text.length;
    final isOverLimit = currentLength > widget.maxLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BaseTextField(
          controller: widget.controller,
          labelText: widget.labelText,
          hintText: widget.hintText,
          helperText: widget.helperText,
          errorText: _errorText,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          enabled: widget.enabled,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          inputFormatters: [
            LengthLimitingTextInputFormatter(widget.maxLength + 50),
          ],
          border: Border.all(
            color: isOverLimit ? AppStyles.errorColor : AppStyles.grey300,
          ),
        ),

        if (widget.showCounter) ...[
          const SizedBox(height: AppStyles.spacingXS),
          Padding(
            padding: AppStyles.smallPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$currentLength/${widget.maxLength}',
                  style: AppStyles.bodyTextSmall.copyWith(
                    color: isOverLimit
                        ? AppStyles.errorColor
                        : AppStyles.grey500,
                    fontWeight: isOverLimit
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class LimitedTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final int maxLength;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const LimitedTextArea({
    super.key,
    required this.controller,
    required this.maxLength,
    this.labelText,
    this.hintText,
    this.minLines = 3,
    this.maxLines = 6,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return LimitedTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: TextInputType.multiline,
    );
  }
}
