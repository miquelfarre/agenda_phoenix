import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
import '../../repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final settingsProvider = FutureProvider<AppSettings>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return await repository.loadSettings();
});

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>(
      SettingsNotifier.new,
    );

class SettingsNotifier extends Notifier<AsyncValue<AppSettings>> {
  late final SettingsRepository _repository;

  @override
  AsyncValue<AppSettings> build() {
    _repository = ref.watch(settingsRepositoryProvider);
    _loadSettings();
    return const AsyncValue.loading();
  }

  Future<void> _loadSettings() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _repository.loadSettings();
      state = AsyncValue.data(settings);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = AsyncValue.data(settings);

    try {
      await _repository.saveSettings(settings);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> refresh() => _loadSettings();

  Future<void> clearCacheAndRefresh() async {
    await _loadSettings();
  }
}
