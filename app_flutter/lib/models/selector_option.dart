import 'package:flutter/material.dart';

class SelectorOption<T> {
  final T value;

  final String displayText;

  final bool isSelected;

  final Color? highlightColor;

  final bool isEnabled;

  final String? subtitle;

  const SelectorOption({
    required this.value,
    required this.displayText,
    this.isSelected = false,
    this.highlightColor,
    this.isEnabled = true,
    this.subtitle,
  }) : assert(displayText != ''),
       assert(value != null);

  SelectorOption<T> copyWith({
    T? value,
    String? displayText,
    bool? isSelected,
    Color? highlightColor,
    bool? isEnabled,
    String? subtitle,
  }) {
    return SelectorOption<T>(
      value: value ?? this.value,
      displayText: displayText ?? this.displayText,
      isSelected: isSelected ?? this.isSelected,
      highlightColor: highlightColor ?? this.highlightColor,
      isEnabled: isEnabled ?? this.isEnabled,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectorOption<T> &&
        other.value == value &&
        other.displayText == displayText &&
        other.isSelected == isSelected &&
        other.highlightColor == highlightColor &&
        other.isEnabled == isEnabled &&
        other.subtitle == subtitle;
  }

  @override
  int get hashCode {
    return Object.hash(
      value,
      displayText,
      isSelected,
      highlightColor,
      isEnabled,
      subtitle,
    );
  }

  @override
  String toString() {
    return 'SelectorOption<$T>(value: $value, displayText: $displayText, isSelected: $isSelected, isEnabled: $isEnabled)';
  }
}
