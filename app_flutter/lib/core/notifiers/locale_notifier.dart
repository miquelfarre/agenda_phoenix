import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return const Locale('es', 'ES');
  }

  void setLocale(Locale locale) {
    state = locale;
  }

  List<Map<String, dynamic>> getAvailableLanguages() {
    return [
      {'locale': const Locale('en', 'US'), 'name': 'English', 'flag': '🇺🇸'},
      {'locale': const Locale('es', 'ES'), 'name': 'Español', 'flag': '🇪🇸'},
    ];
  }
}

final localeNotifierProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});