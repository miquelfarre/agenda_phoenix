import 'package:flutter/material.dart';
import 'platform_theme.dart';

class AdaptiveCard extends StatelessWidget implements IAdaptiveWidget, ICardWidget {
  @override
  final AdaptiveCardConfig config;
  @override
  final Widget child;
  @override
  final VoidCallback? onTap;
  @override
  final bool selectable;
  @override
  final bool selected;
  @override
  final void Function(bool selected)? onSelectionChanged;
  @override
  final bool enabled;

  const AdaptiveCard({super.key, required this.config, required this.child, this.onTap, this.selectable = false, this.selected = false, this.onSelectionChanged, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final theme = PlatformTheme.adaptive(context);

    return GestureDetector(
      onTap: enabled ? _handleTap : null,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: config.margin, decoration: _buildDecoration(theme), child: _buildContent()),
    );
  }

  void _handleTap() {
    if (selectable && onSelectionChanged != null) {
      onSelectionChanged!(!selected);
    }
    onTap?.call();
  }

  BoxDecoration _buildDecoration(PlatformTheme theme) {
    return BoxDecoration(color: _getBackgroundColor(theme), borderRadius: config.borderRadius, boxShadow: config.showShadow ? _buildShadow() : null, border: _buildBorder(theme));
  }

  Color _getBackgroundColor(PlatformTheme theme) {
    if (!enabled) {
      return theme.backgroundColor.withValues(alpha: 0.5);
    }
    if (selected && selectable) {
      return theme.primaryColor.withValues(alpha: 0.1);
    }
    return config.backgroundColor ?? theme.backgroundColor;
  }

  List<BoxShadow>? _buildShadow() {
    if (!config.showShadow) return null;

    return [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: config.elevation ?? 2.0, offset: Offset(0, config.elevation ?? 2.0))];
  }

  Border? _buildBorder(PlatformTheme theme) {
    if (selectable && selected) {
      return Border.all(color: theme.primaryColor, width: 2.0);
    }
    return null;
  }

  Widget _buildContent() {
    if (!selectable) {
      return child;
    }

    return Row(
      children: [
        if (selectable) _buildSelectionIndicator(),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildSelectionIndicator() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, color: selected ? Colors.green : Colors.grey, size: 20),
    );
  }

  @override
  PlatformTheme get theme => PlatformTheme.adaptive(null);

  @override
  ValidationResult validate() {
    final issues = <ValidationIssue>[];

    if (config.margin.left < 0 || config.margin.top < 0 || config.margin.right < 0 || config.margin.bottom < 0) {
      issues.add(const ValidationIssue(message: 'Margin values should not be negative', severity: ValidationSeverity.warning));
    }

    if (selectable && onSelectionChanged == null) {
      issues.add(const ValidationIssue(message: 'Selectable cards should have onSelectionChanged handler', severity: ValidationSeverity.error, suggestion: 'Add onSelectionChanged callback'));
    }

    return ValidationResult(isValid: issues.where((i) => i.severity == ValidationSeverity.error).isEmpty, issues: issues, severity: issues.isEmpty ? ValidationSeverity.none : issues.map((i) => i.severity).reduce((a, b) => a.index > b.index ? a : b));
  }
}

class AdaptiveCardConfig {
  final CardVariant variant;
  final EdgeInsets margin;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final bool showShadow;
  final bool selectable;
  final double? elevation;

  const AdaptiveCardConfig({required this.variant, required this.margin, required this.borderRadius, this.backgroundColor, required this.showShadow, required this.selectable, this.elevation});

  factory AdaptiveCardConfig.simple() => const AdaptiveCardConfig(variant: CardVariant.simple, margin: EdgeInsets.all(8.0), borderRadius: BorderRadius.all(Radius.circular(8.0)), showShadow: false, selectable: false);

  factory AdaptiveCardConfig.listItem() => const AdaptiveCardConfig(variant: CardVariant.listItem, margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), borderRadius: BorderRadius.all(Radius.circular(8.0)), showShadow: true, selectable: false, elevation: 1.0);

  factory AdaptiveCardConfig.selectable() => const AdaptiveCardConfig(variant: CardVariant.selectable, margin: EdgeInsets.all(8.0), borderRadius: BorderRadius.all(Radius.circular(8.0)), showShadow: false, selectable: true);

  factory AdaptiveCardConfig.elevated() => const AdaptiveCardConfig(variant: CardVariant.elevated, margin: EdgeInsets.all(12.0), borderRadius: BorderRadius.all(Radius.circular(12.0)), showShadow: true, selectable: false, elevation: 4.0);

  factory AdaptiveCardConfig.contact() => const AdaptiveCardConfig(variant: CardVariant.contact, margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0), borderRadius: BorderRadius.all(Radius.circular(10.0)), showShadow: true, selectable: false, elevation: 2.0);

  factory AdaptiveCardConfig.event() => const AdaptiveCardConfig(variant: CardVariant.event, margin: EdgeInsets.all(8.0), borderRadius: BorderRadius.all(Radius.circular(12.0)), showShadow: true, selectable: false, elevation: 3.0);
}

enum CardVariant { simple, listItem, selectable, elevated, contact, event }

abstract class IAdaptiveWidget {
  PlatformTheme get theme;
  bool get enabled;
  Widget build(BuildContext context);
  ValidationResult validate();
}

abstract class ICardWidget extends IAdaptiveWidget {
  AdaptiveCardConfig get config;
  Widget get child;
  VoidCallback? get onTap;
  bool get selectable;
  bool get selected;
  void Function(bool selected)? get onSelectionChanged;
}

class ValidationResult {
  final bool isValid;
  final List<ValidationIssue> issues;
  final ValidationSeverity severity;

  const ValidationResult({required this.isValid, required this.issues, required this.severity});

  factory ValidationResult.valid() => const ValidationResult(isValid: true, issues: [], severity: ValidationSeverity.none);

  factory ValidationResult.invalid(List<ValidationIssue> issues) => ValidationResult(isValid: false, issues: issues, severity: ValidationSeverity.error);
}

class ValidationIssue {
  final String message;
  final ValidationSeverity severity;
  final String? suggestion;

  const ValidationIssue({required this.message, required this.severity, this.suggestion});
}

enum ValidationSeverity { none, info, warning, error }
