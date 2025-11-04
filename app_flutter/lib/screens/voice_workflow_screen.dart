import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai/gemini_voice_service.dart';
import '../services/ai/voice_workflow_context.dart';
import '../services/ai/voice_conversation_context.dart';
import '../config/debug_config.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';

/// Pantalla de flujo de trabajo inteligente por voz
/// Permite completar múltiples acciones relacionadas en secuencia
class VoiceWorkflowScreen extends ConsumerStatefulWidget {
  final VoiceWorkflowContext workflowContext;
  final GeminiVoiceService voiceService;

  const VoiceWorkflowScreen({
    super.key,
    required this.workflowContext,
    required this.voiceService,
  });

  @override
  ConsumerState<VoiceWorkflowScreen> createState() => _VoiceWorkflowScreenState();
}

class _VoiceWorkflowScreenState extends ConsumerState<VoiceWorkflowScreen>
    with SingleTickerProviderStateMixin {
  late VoiceWorkflowContext _context;
  bool _isListening = false;
  String? _currentQuestion;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _context = widget.workflowContext;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Determinar la primera pregunta
    _updateCurrentQuestion();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updateCurrentQuestion() {
    setState(() {
      if (_context.currentAction != null && _context.currentAction!.missingFields.isNotEmpty) {
        // Hay una acción en curso con campos faltantes
        final nextField = _context.currentAction!.missingFields.first;
        _currentQuestion = RequiredFields.generateQuestion(
          _context.currentAction!.action,
          nextField,
        );
      } else if (_context.suggestedActions.isNotEmpty) {
        // Ofrecer las acciones sugeridas
        _currentQuestion = WorkflowSuggestions.generateSuggestionsPrompt(
          _context.suggestedActions,
        );
      } else {
        _currentQuestion = null;
      }
    });
  }

  Future<void> _handleVoiceResponse() async {
    if (_currentQuestion == null) return;

    print('🎤 Usuario va a responder por voz a: "$_currentQuestion"');

    setState(() => _isListening = true);

    try {
      // Transcribir la respuesta del usuario
      print('🎙️ Iniciando transcripción de respuesta...');
      final userResponse = await widget.voiceService.transcribeAudioOnDevice();
      print('✅ Usuario respondió: "$userResponse"');

      setState(() => _isListening = false);

      if (userResponse.isEmpty) {
        _showError('No detecté ninguna respuesta. Intenta de nuevo.');
        return;
      }

      // Determinar si estamos recolectando campos o eligiendo acción
      if (_context.currentAction != null && _context.currentAction!.missingFields.isNotEmpty) {
        // Recolectando campos para la acción actual
        await _handleFieldCollection(userResponse);
      } else if (_context.suggestedActions.isNotEmpty) {
        // Usuario está eligiendo una acción sugerida
        await _handleActionSelection(userResponse);
      }

    } catch (e) {
      print('❌ Error al procesar respuesta de voz: $e');
      setState(() => _isListening = false);
      _showError('Error al procesar tu respuesta: ${e.toString()}');
    }
  }

  /// Maneja la recolección de un campo faltante
  Future<void> _handleFieldCollection(String userResponse) async {
    if (_context.currentAction == null) return;

    final nextField = _context.currentAction!.missingFields.first;

    print('📝 Recolectando campo: $nextField');
    print('📝 Respuesta del usuario: "$userResponse"');

    // Enviar a Gemini para interpretar la respuesta
    final contextualPrompt = '''
Contexto: El usuario está creando/actualizando algo con la acción "${_context.currentAction!.action}".

Parámetros ya recolectados: ${_context.currentAction!.parameters}
Parámetros globales disponibles: ${_context.globalContext}

Sistema preguntó: "$_currentQuestion"
Usuario respondió: "$userResponse"

Por favor, extrae SOLO el valor del campo "$nextField" de la respuesta del usuario.
Devuelve un JSON con SOLO ese campo.

Ejemplos:
- Si preguntamos "¿Cuál es el email?" y responde "juan@example.com" → {"user_email": "juan@example.com"}
- Si preguntamos "¿Quieres que sea público?" y responde "sí" → {"is_public": true}
- Si preguntamos "¿Quieres que sea público?" y responde "no" → {"is_public": false}

IMPORTANTE: Devuelve SOLO el JSON del campo "$nextField", sin texto adicional.
''';

    try {
      final newParams = await widget.voiceService.interpretWithGemini(
        userResponse,
        customPrompt: contextualPrompt,
      );

      print('✅ Parámetro extraído: $newParams');

      // Actualizar la acción actual con el nuevo parámetro
      final updatedAction = _context.currentAction!.updateParameters(newParams);

      if (updatedAction.isReady) {
        // Todos los campos completados → Ejecutar la acción
        print('✅ Acción lista para ejecutar: ${updatedAction.action}');
        await _executeCurrentAction(updatedAction);
      } else {
        // Aún faltan campos → actualizar contexto y preguntar siguiente campo
        print('📋 Aún faltan campos: ${updatedAction.missingFields}');
        setState(() {
          _context = _context.startAction(updatedAction);
        });
        _updateCurrentQuestion();
      }

    } catch (e) {
      print('❌ Error interpretando campo: $e');
      _showError('No pude entender tu respuesta. Intenta de nuevo.');
    }
  }

  /// Maneja la selección de una acción sugerida
  Future<void> _handleActionSelection(String userResponse) async {
    print('🤔 Usuario eligiendo acción sugerida...');
    print('📝 Respuesta: "$userResponse"');

    // Analizar si el usuario dijo "no", "nada", "listo", etc. para finalizar
    final lowerResponse = userResponse.toLowerCase().trim();
    if (lowerResponse == 'no' ||
        lowerResponse == 'nada' ||
        lowerResponse == 'listo' ||
        lowerResponse == 'ya está' ||
        lowerResponse == 'terminar') {
      print('✅ Usuario terminó el workflow');
      _finishWorkflow();
      return;
    }

    // Enviar a Gemini para determinar qué acción eligió
    final prompt = '''
El usuario acaba de completar: ${_context.completedActions.map((a) => a.action).join(', ')}

Contexto global: ${_context.globalContext}

Acciones disponibles:
${_context.suggestedActions.map((s) => '- ${s.action}: ${s.question}').join('\n')}

Usuario respondió: "$userResponse"

Por favor, determina qué acción quiere hacer el usuario y devuelve un JSON:
{
  "action": "NOMBRE_DE_ACCION",
  "parameters": {...parámetros que puedas extraer de su respuesta...},
  "confidence": 0.0-1.0
}

Si el usuario dijo "no" o no quiere hacer nada más, devuelve:
{"action": "NONE", "confidence": 1.0}

IMPORTANTE: Devuelve SOLO el JSON, sin texto adicional.
''';

    try {
      final interpretation = await widget.voiceService.interpretWithGemini(
        userResponse,
        customPrompt: prompt,
      );

      print('✅ Interpretación de acción: $interpretation');

      final selectedAction = interpretation['action'] as String;

      if (selectedAction == 'NONE') {
        print('✅ Usuario no quiere hacer más acciones');
        _finishWorkflow();
        return;
      }

      // Encontrar la sugerencia correspondiente
      final suggestion = _context.suggestedActions.firstWhere(
        (s) => s.action == selectedAction,
        orElse: () => _context.suggestedActions.first,
      );

      // Combinar parámetros por defecto con los extraídos
      final params = {
        ...suggestion.defaultParameters,
        ...interpretation['parameters'] as Map<String, dynamic>,
      };

      // Crear nueva acción
      final missingFields = RequiredFields.findMissing(selectedAction, params);
      final newAction = WorkflowAction(
        action: selectedAction,
        parameters: params,
        missingFields: missingFields,
      );

      print('📋 Nueva acción iniciada: $selectedAction');
      print('📋 Campos faltantes: $missingFields');

      setState(() {
        _context = _context.startAction(newAction).updateSuggestions([]);
      });
      _updateCurrentQuestion();

    } catch (e) {
      print('❌ Error seleccionando acción: $e');
      _showError('No entendí qué quieres hacer. ¿Puedes repetir?');
    }
  }

  /// Ejecuta la acción actual
  Future<void> _executeCurrentAction(WorkflowAction action) async {
    print('🚀 Ejecutando acción: ${action.action}');
    print('📋 Parámetros: ${action.parameters}');

    try {
      // Aquí ejecutarías la acción real a través del API
      // Por ahora, simulamos el resultado
      final result = await widget.voiceService.executeAction({
        'action': action.action,
        'parameters': action.parameters,
      });

      print('✅ Acción ejecutada exitosamente');
      print('📊 Resultado: $result');

      // Marcar acción como completada
      final updatedContext = _context.completeCurrentAction(result);

      // Generar sugerencias para la siguiente acción
      final suggestions = WorkflowSuggestions.afterAction(
        action.action,
        result,
      );

      setState(() {
        _context = updatedContext.updateSuggestions(suggestions);
      });

      _updateCurrentQuestion();

      // Si no hay más sugerencias, finalizar
      if (suggestions.isEmpty) {
        print('✅ No hay más acciones sugeridas, finalizando workflow');
        await Future.delayed(const Duration(seconds: 1));
        _finishWorkflow();
      }

    } catch (e) {
      print('❌ Error ejecutando acción: $e');
      _showError('Error al ejecutar la acción: ${e.toString()}');
    }
  }

  /// Finaliza el workflow y cierra la pantalla
  void _finishWorkflow() {
    print('✅ Workflow completado');
    if (mounted) {
      Navigator.of(context).pop(_context);
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
        title: const Text('Asistente de Voz'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(_context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Resumen de acciones completadas
              if (_context.completedActions.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Completado:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._context.completedActions.map((completed) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '✓ ${_actionToUserFriendly(completed.action)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Spacer(),

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
                          color: (_isListening ? Colors.red : Colors.blue).withOpacity(0.3),
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
                        : const Icon(
                            Icons.mic,
                            size: 60,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isListening
                      ? 'Escuchando... habla ahora'
                      : 'Toca el micrófono para responder',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡Todo listo!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const Spacer(),

              // Botón para terminar
              TextButton(
                onPressed: _finishWorkflow,
                child: Text(_context.suggestedActions.isNotEmpty ? 'No, terminar aquí' : 'Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _actionToUserFriendly(String action) {
    switch (action) {
      case 'CREATE_CALENDAR':
        return 'Calendario creado';
      case 'CREATE_EVENT':
        return 'Evento creado';
      case 'UPDATE_CALENDAR':
        return 'Calendario actualizado';
      case 'INVITE_TO_CALENDAR':
        return 'Usuario invitado al calendario';
      case 'ADD_CALENDAR_ADMIN':
        return 'Administrador añadido';
      case 'INVITE_USER':
        return 'Usuario invitado al evento';
      default:
        return action.replaceAll('_', ' ').toLowerCase();
    }
  }
}
