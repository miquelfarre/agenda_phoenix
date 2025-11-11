import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai/base_voice_service.dart';
import '../services/ai/voice_conversation_context.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';

/// Pantalla conversacional para recolectar datos faltantes por voz
class VoiceConversationScreen extends ConsumerStatefulWidget {
  final VoiceConversationContext context;
  final BaseVoiceService voiceService;
  final Function(VoiceConversationContext) onContextUpdated;

  const VoiceConversationScreen({
    super.key,
    required this.context,
    required this.voiceService,
    required this.onContextUpdated,
  });

  @override
  ConsumerState<VoiceConversationScreen> createState() =>
      _VoiceConversationScreenState();
}

class _VoiceConversationScreenState
    extends ConsumerState<VoiceConversationScreen>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String? _currentQuestion;
  late AnimationController _pulseController;
  int _recordingSeconds = 0;
  bool _shouldStopRecording = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Determinar la primera pregunta
    _currentQuestion = _getNextQuestion();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String? _getNextQuestion() {
    if (widget.context.missingFields.isEmpty) {
      return null;
    }
    final nextField = widget.context.missingFields.first;
    return RequiredFields.generateQuestion(widget.context.action, nextField);
  }

  Future<void> _handleVoiceResponse() async {
    if (_currentQuestion == null) return;

    setState(() {
      _isListening = true;
      _shouldStopRecording = false;
      _recordingSeconds = 0;
    });

    try {
      // Transcribir la respuesta del usuario con control manual
      final userResponse = await widget.voiceService.transcribeAudioOnDevice(
        onProgress: (seconds) {
          if (mounted) {
            setState(() => _recordingSeconds = seconds);
          }
        },
        waitForStopSignal: () async {
          // Esperar hasta que el usuario presione el botón de detener
          while (!_shouldStopRecording && mounted) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        },
      );

      setState(() {
        _isListening = false;
        _recordingSeconds = 0;
      });

      if (userResponse.isEmpty) {
        _showError('No detecté ninguna respuesta. Intenta de nuevo.');
        return;
      }

      // Enviar el contexto completo + nueva respuesta a Gemini para que lo interprete
      final updatedInterpretation = await _interpretResponseWithContext(
        userResponse,
      );

      // Crear nuevo contexto con los datos actualizados
      final newContext = widget.context.addTurn(
        _currentQuestion!,
        userResponse,
        updatedInterpretation,
      );

      // Si todavía faltan campos, actualizar la pregunta
      if (!newContext.isComplete) {
        setState(() {
          _currentQuestion = _getNextQuestion();
        });
        widget.onContextUpdated(newContext);
      } else {
        // ¡Conversación completa! Cerrar el diálogo
        if (mounted) {
          Navigator.of(context).pop(newContext);
        }
      }
    } catch (e) {
      setState(() {
        _isListening = false;
        _recordingSeconds = 0;
      });
      _showError('Error al procesar tu respuesta: ${e.toString()}');
    }
  }

  void _stopRecording() {
    setState(() => _shouldStopRecording = true);
  }

  /// Envía el contexto completo + nueva respuesta a Gemini para que actualice los parámetros
  Future<Map<String, dynamic>> _interpretResponseWithContext(
    String userResponse,
  ) async {
    // Obtener el nombre del campo que estamos recolectando
    final currentField = widget.context.missingFields.first;

    final contextualPrompt =
        '''
${widget.context.conversationSummary}

Sistema preguntó: "$_currentQuestion"
Usuario respondió: "$userResponse"

Por favor, extrae SOLO el nuevo parámetro de la respuesta del usuario y devuélvelo en formato JSON.
No repitas parámetros que ya tenemos. Solo el nuevo.

IMPORTANTE: El campo que necesitamos se llama exactamente "$currentField".
Usa EXACTAMENTE este nombre en el JSON, sin cambiarlo ni traducirlo.

Ejemplo si el campo es "title" y el usuario dijo "Reunión con el equipo":
{"title": "Reunión con el equipo"}

Ejemplo si el campo es "name" y el usuario dijo "Mi calendario":
{"name": "Mi calendario"}

Ejemplo si el campo es "start_datetime" y el usuario dijo "mañana a las 3":
{"start_datetime": "2025-11-05T15:00:00"}

CRÍTICO: Devuelve SOLO el JSON con el campo "$currentField", sin texto adicional.
''';

    try {
      final interpretation = await widget.voiceService.interpretWithAI(
        userResponse,
        customPrompt: contextualPrompt,
      );
      // Gemini debería devolver solo el parámetro nuevo
      // Pero si devuelve toda la estructura, extraer solo 'parameters'
      if (interpretation.containsKey('parameters')) {
        return interpretation['parameters'] as Map<String, dynamic>;
      }
      return interpretation;
    } catch (e) {
      rethrow;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = PlatformDetection.isIOS;

    return Scaffold(
      backgroundColor: isIOS ? CupertinoColors.systemBackground : null,
      appBar: AppBar(
        title: Text(context.l10n.completeInformation),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Historial de conversación (compacto)
              if (widget.context.history.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conversación anterior:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.context.history.map(
                        (turn) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '❓ ${turn.question}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                '💬 ${turn.answer}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Pregunta actual
              if (_currentQuestion != null) ...[
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                Text(
                  _currentQuestion!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 48),

                // Botón de micrófono grande
                GestureDetector(
                  onTap: _isListening ? null : _handleVoiceResponse,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.red : Colors.blue,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : Colors.blue)
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: _isListening
                        ? AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.2),
                                child: const Icon(
                                  Icons.mic,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                        : const Icon(Icons.mic, size: 60, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),

                // Indicador de tiempo y botón de detener
                if (_isListening) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.red.shade200, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_recordingSeconds}s / 30s',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _recordingSeconds / 30,
                          backgroundColor: Colors.grey.shade300,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop),
                    label: Text(context.l10n.stop),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Toca el micrófono para responder',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ] else ...[
                const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡Información completa!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ],

              const Spacer(),

              // Botón para cancelar
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.cancelAndEditManually),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
