import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../ui/styles/app_styles.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';

class BaseTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsets? contentPadding;
  final BoxBorder? border;
  final TextStyle? textStyle;
  final bool autofocus;
  final String? initialValue;

  const BaseTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIcon,
    this.suffixIcon,
    this.contentPadding,
    this.border,
    this.textStyle,
    this.autofocus = false,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    Widget textField = CupertinoTextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines ?? 1,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onTap: onTap,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      autofocus: autofocus,
      placeholder: hintText,
      placeholderStyle: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
      style: textStyle ?? const TextStyle(fontSize: 16, color: AppStyles.textColor),
      padding: contentPadding ?? AppStyles.buttonPadding,
      decoration: BoxDecoration(
        border: border ?? Border.all(color: errorText != null ? AppStyles.errorColor : AppStyles.grey300, width: errorText != null ? 2 : 1),
        borderRadius: AppStyles.smallRadius,
        color: enabled ? CupertinoColors.white : AppStyles.grey100,
      ),
      prefix: prefixIcon != null ? Padding(padding: const EdgeInsets.only(left: 8), child: prefixIcon) : null,
      suffix: suffixIcon != null ? Padding(padding: const EdgeInsets.only(right: 8), child: suffixIcon) : null,
    );

    if (labelText != null || helperText != null || errorText != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText != null) ...[
            Text(
              labelText!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppStyles.textColor),
            ),
            const SizedBox(height: 4),
          ],
          textField,
          if (helperText != null || errorText != null) ...[const SizedBox(height: 4), Text(errorText ?? helperText!, style: TextStyle(fontSize: 12, color: errorText != null ? AppStyles.errorColor : AppStyles.grey600))],
        ],
      );
    }

    return textField;
  }
}

class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SearchTextField({super.key, this.controller, this.hintText, this.onChanged, this.onClear});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CupertinoSearchTextField(
      controller: controller,
      placeholder: hintText ?? l10n.search,
      onChanged: onChanged,
      onSuffixTap: onClear,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppStyles.grey100, borderRadius: AppStyles.smallRadius),
      prefixIcon: const Icon(CupertinoIcons.search, color: AppStyles.grey600, size: 20),
      suffixIcon: const Icon(CupertinoIcons.clear_circled_solid, color: AppStyles.grey600, size: 18),
      style: const TextStyle(fontSize: 16),
    );
  }
}
