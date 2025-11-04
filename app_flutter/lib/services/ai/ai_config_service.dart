import 'package:shared_preferences/shared_preferences.dart';
import '../../config/debug_config.dart';

/// Servicio para gestionar la configuración de AI APIs (Gemini, Claude, etc.)
class AIConfigService {
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _voiceCommandsEnabledKey = 'voice_commands_enabled';

  static AIConfigService? _instance;
  late SharedPreferences _prefs;

  AIConfigService._();

  static Future<AIConfigService> getInstance() async {
    if (_instance == null) {
      final service = AIConfigService._();
      await service._init();
      _instance = service;
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    DebugConfig.info('AIConfigService inicializado', tag: 'AIConfig');
  }

  /// Obtener la API key de Gemini
  /// Prioridad: 1) SharedPreferences (configurada por usuario)
  ///            2) dart-defines (configurada en start.sh para desarrollo)
  String? get geminiApiKey {
    print('🔑 AIConfigService.geminiApiKey getter llamado');
    // Primero verificar si el usuario configuró una manualmente
    final userKey = _prefs.getString(_geminiApiKeyKey);
    print('🔑 SharedPreferences key: ${userKey != null ? "${userKey.length} chars" : "null"}');
    if (userKey != null && userKey.isNotEmpty) {
      print('🔑 Usando API key desde SharedPreferences (${userKey.length} chars)');
      DebugConfig.info('🔑 API key cargada desde SharedPreferences (${userKey.length} chars)', tag: 'AIConfig');
      return userKey;
    }

    // Fallback: usar la del entorno si está disponible
    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    print('🔑 Environment key: ${envKey.isNotEmpty ? "${envKey.length} chars" : "vacío"}');
    if (envKey.isNotEmpty) {
      print('🔑 Usando API key desde .env (${envKey.length} chars)');
      DebugConfig.info('🔑 API key cargada desde .env (${envKey.length} chars)', tag: 'AIConfig');
      return envKey;
    }

    print('⚠️ NO SE ENCONTRÓ API KEY DE GEMINI EN NINGÚN LADO');
    DebugConfig.info('⚠️ No se encontró API key de Gemini', tag: 'AIConfig');
    return null;
  }

  /// Guardar la API key de Gemini
  Future<bool> setGeminiApiKey(String apiKey) async {
    try {
      final success = await _prefs.setString(_geminiApiKeyKey, apiKey);
      if (success) {
        DebugConfig.info('Gemini API key guardada', tag: 'AIConfig');
      }
      return success;
    } catch (e) {
      DebugConfig.error('Error al guardar API key: $e', tag: 'AIConfig');
      return false;
    }
  }

  /// Eliminar la API key de Gemini
  Future<bool> clearGeminiApiKey() async {
    try {
      final success = await _prefs.remove(_geminiApiKeyKey);
      if (success) {
        DebugConfig.info('Gemini API key eliminada', tag: 'AIConfig');
      }
      return success;
    } catch (e) {
      DebugConfig.error('Error al eliminar API key: $e', tag: 'AIConfig');
      return false;
    }
  }

  /// Verificar si la API key está configurada
  bool get hasApiKey {
    final apiKey = geminiApiKey;
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Verificar si los comandos de voz están habilitados
  bool get voiceCommandsEnabled {
    return _prefs.getBool(_voiceCommandsEnabledKey) ?? true;
  }

  /// Habilitar/deshabilitar comandos de voz
  Future<bool> setVoiceCommandsEnabled(bool enabled) async {
    try {
      final success = await _prefs.setBool(_voiceCommandsEnabledKey, enabled);
      if (success) {
        DebugConfig.info(
          'Comandos de voz ${enabled ? 'habilitados' : 'deshabilitados'}',
          tag: 'AIConfig',
        );
      }
      return success;
    } catch (e) {
      DebugConfig.error('Error al cambiar estado de comandos de voz: $e',
                       tag: 'AIConfig');
      return false;
    }
  }

  /// Validar formato de API key de Gemini
  /// Las API keys de Gemini son alfanuméricas y tienen ~39 caracteres
  bool isValidApiKeyFormat(String apiKey) {
    final trimmed = apiKey.trim();
    // Gemini keys son strings alfanuméricos, generalmente de 39 caracteres
    return trimmed.isNotEmpty &&
           trimmed.length >= 30 &&
           RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(trimmed);
  }
}
