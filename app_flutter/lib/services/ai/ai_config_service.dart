import 'package:shared_preferences/shared_preferences.dart';
import '../../config/debug_config.dart';

/// Provider de AI disponibles
enum AIProvider {
  gemini,
  ollama,
}

/// Servicio para gestionar la configuración de AI APIs (Gemini, Ollama, etc.)
class AIConfigService {
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _voiceCommandsEnabledKey = 'voice_commands_enabled';
  static const String _aiProviderKey = 'ai_provider';

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
    // Primero verificar si el usuario configuró una manualmente
    final userKey = _prefs.getString(_geminiApiKeyKey);
    if (userKey != null && userKey.isNotEmpty) {
      DebugConfig.info('🔑 API key cargada desde SharedPreferences (${userKey.length} chars)', tag: 'AIConfig');
      return userKey;
    }

    // Fallback: usar la del entorno si está disponible
    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) {
      DebugConfig.info('🔑 API key cargada desde .env (${envKey.length} chars)', tag: 'AIConfig');
      return envKey;
    }

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

  /// Obtener el provider de AI configurado
  /// Prioridad: 1) SharedPreferences (configurado por usuario)
  ///            2) dart-defines (configurado en start.sh para desarrollo)
  ///            3) Default: gemini
  AIProvider get aiProvider {
    // Primero verificar si el usuario configuró uno manualmente
    final userProvider = _prefs.getString(_aiProviderKey);
    if (userProvider != null && userProvider.isNotEmpty) {
      if (userProvider.toLowerCase() == 'ollama') {
        DebugConfig.info('🔧 AI Provider desde SharedPreferences: Ollama', tag: 'AIConfig');
        return AIProvider.ollama;
      } else if (userProvider.toLowerCase() == 'gemini') {
        DebugConfig.info('🔧 AI Provider desde SharedPreferences: Gemini', tag: 'AIConfig');
        return AIProvider.gemini;
      }
    }

    // Fallback: usar el del entorno si está disponible
    const envProvider = String.fromEnvironment('AI_PROVIDER', defaultValue: 'gemini');
    if (envProvider.toLowerCase() == 'ollama') {
      DebugConfig.info('🔧 AI Provider desde .env: Ollama', tag: 'AIConfig');
      return AIProvider.ollama;
    }

    // Default: Gemini
    DebugConfig.info('🔧 AI Provider: Gemini (default)', tag: 'AIConfig');
    return AIProvider.gemini;
  }

  /// Cambiar el provider de AI
  Future<bool> setAIProvider(AIProvider provider) async {
    try {
      final providerName = provider == AIProvider.ollama ? 'ollama' : 'gemini';
      final success = await _prefs.setString(_aiProviderKey, providerName);
      if (success) {
        DebugConfig.info('AI provider cambiado a: $providerName', tag: 'AIConfig');
      }
      return success;
    } catch (e) {
      DebugConfig.error('Error al cambiar AI provider: $e', tag: 'AIConfig');
      return false;
    }
  }

  /// Obtener configuración de Ollama desde .env
  String get ollamaBaseUrl {
    const url = String.fromEnvironment('OLLAMA_BASE_URL', defaultValue: 'http://localhost:11434');
    return url;
  }

  String get ollamaModel {
    const model = String.fromEnvironment('OLLAMA_MODEL', defaultValue: 'gpt-oss');
    return model;
  }
}
