/// Resultado del procesamiento de un comando de voz
class VoiceCommandResult {
  final bool success;
  final String? message;
  final dynamic data;
  final Map<String, dynamic>? interpretation;
  final String? transcribedText;
  final bool needsConfirmation;

  VoiceCommandResult({
    required this.success,
    this.message,
    this.data,
    this.interpretation,
    this.transcribedText,
    this.needsConfirmation = false,
  });
}

/// Interfaz base para servicios de voz con IA
/// Permite cambiar entre diferentes providers (Gemini, Ollama, etc.)
abstract class BaseVoiceService {
  /// Interpreta un texto transcrito y devuelve la acción a ejecutar
  ///
  /// Retorna un Map con la estructura:
  /// ```json
  /// {
  ///   "action": "CREATE_EVENT",
  ///   "parameters": {...},
  ///   "confidence": 0.95,
  ///   "needs_confirmation": true
  /// }
  /// ```
  Future<Map<String, dynamic>> interpretWithAI(String transcribedText, {String? customPrompt});

  /// Ejecuta la acción interpretada por la IA usando ApiClient
  Future<dynamic> executeAction(Map<String, dynamic> interpretation);

  /// Transcribe audio a texto usando speech-to-text (on-device)
  Future<String> transcribeAudioOnDevice({
    Function(int secondsElapsed)? onProgress,
    Future<void> Function()? waitForStopSignal,
  });

  /// Procesa un comando de voz completo: graba, transcribe, interpreta
  Future<VoiceCommandResult> processVoiceCommand();
}
