import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai/gemini_voice_service.dart';
import '../services/ai/ai_config_service.dart';
import '../services/ai/voice_conversation_context.dart';
import '../screens/voice_command_confirmation_screen.dart';
import '../screens/voice_conversation_screen.dart';
import '../config/debug_config.dart';
import 'voice_recording_dialog.dart';

/// Provider para el servicio de voz de Gemini
final geminiVoiceServiceProvider = FutureProvider<GeminiVoiceService?>((ref) async {
  print('🔄 ===== INICIALIZANDO PROVIDER DE VOZ =====');
  DebugConfig.info('🔄 ===== INICIALIZANDO PROVIDER DE VOZ =====', tag: 'VoiceButton');
  try {
    print('📋 Obteniendo AIConfigService...');
    DebugConfig.info('📋 Obteniendo AIConfigService...', tag: 'VoiceButton');
    final config = await AIConfigService.getInstance();

    print('🔍 Verificando API key y configuración...');
    print('   - hasApiKey: ${config.hasApiKey}');
    print('   - voiceCommandsEnabled: ${config.voiceCommandsEnabled}');
    DebugConfig.info('🔍 Verificando API key y configuración...', tag: 'VoiceButton');
    DebugConfig.info('   - hasApiKey: ${config.hasApiKey}', tag: 'VoiceButton');
    DebugConfig.info('   - voiceCommandsEnabled: ${config.voiceCommandsEnabled}', tag: 'VoiceButton');

    if (!config.hasApiKey || !config.voiceCommandsEnabled) {
      print('⚠️ Gemini API no configurada o deshabilitada');
      DebugConfig.info('⚠️ Gemini API no configurada o deshabilitada', tag: 'VoiceButton');
      return null;
    }

    final apiKey = config.geminiApiKey!;
    print('✅ API key disponible (${apiKey.length} chars), creando GeminiVoiceService...');
    DebugConfig.info('✅ API key disponible, creando GeminiVoiceService...', tag: 'VoiceButton');
    return GeminiVoiceService(geminiApiKey: apiKey);
  } catch (e) {
    print('❌ Error al inicializar GeminiVoiceService: $e');
    DebugConfig.error('❌ Error al inicializar GeminiVoiceService: $e', tag: 'VoiceButton');
    return null;
  }
});

/// Botón flotante para activar comandos de voz
class VoiceCommandButton extends ConsumerStatefulWidget {
  /// Callback cuando se ejecuta exitosamente un comando
  final Function(dynamic result)? onCommandExecuted;

  /// Color del botón
  final Color? backgroundColor;

  /// Icono del botón
  final IconData? icon;

  const VoiceCommandButton({
    super.key,
    this.onCommandExecuted,
    this.backgroundColor,
    this.icon,
  });

  @override
  ConsumerState<VoiceCommandButton> createState() => _VoiceCommandButtonState();
}

class _VoiceCommandButtonState extends ConsumerState<VoiceCommandButton>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isProcessing = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleVoiceCommand() async {
    print('🎤 ===== BOTÓN DE VOZ PRESIONADO ===== ${DateTime.now()}');
    DebugConfig.info('🎤 ===== BOTÓN DE VOZ PRESIONADO =====', tag: 'VoiceButton');

    // Mostrar un diálogo visual para confirmar que el botón funciona
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎤 Botón presionado - Iniciando...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final voiceServiceAsync = ref.read(geminiVoiceServiceProvider);

    final voiceService = voiceServiceAsync.when(
      data: (service) {
        print('✅ Servicio de voz disponible: ${service != null}');
        DebugConfig.info('✅ Servicio de voz disponible', tag: 'VoiceButton');
        return service;
      },
      loading: () {
        print('⏳ Servicio de voz cargando...');
        DebugConfig.info('⏳ Servicio de voz cargando...', tag: 'VoiceButton');
        return null;
      },
      error: (error, stack) {
        print('❌ Error en servicio de voz: $error');
        DebugConfig.error('❌ Error en servicio de voz: $error', tag: 'VoiceButton');
        return null;
      },
    );

    if (voiceService == null) {
      print('❌ Servicio de voz es NULL');
      DebugConfig.error('❌ Servicio de voz no disponible', tag: 'VoiceButton');
      _showError('Gemini API key no configurada. '
                'Ve a Configuración para añadir tu API key.');
      return;
    }

    try {
      print('🔴 Iniciando grabación...');
      DebugConfig.info('🔴 Iniciando grabación...', tag: 'VoiceButton');
      setState(() => _isRecording = true);

      // 1. Grabar audio y transcribir
      print('🎙️ Llamando a processVoiceCommand()...');
      DebugConfig.info('🎙️ Llamando a processVoiceCommand()...', tag: 'VoiceButton');
      final result = await voiceService.processVoiceCommand();
      print('📥 Resultado recibido!');

      DebugConfig.info('📥 Resultado recibido: success=${result.success}, needsConfirmation=${result.needsConfirmation}', tag: 'VoiceButton');
      DebugConfig.info('📝 Texto transcrito: "${result.transcribedText}"', tag: 'VoiceButton');

      setState(() => _isRecording = false);

      if (!result.success) {
        print('❌ result.success = false');
        DebugConfig.info('⚠️ Comando no exitoso', tag: 'VoiceButton');
        DebugConfig.error('❌ Error: ${result.message}', tag: 'VoiceButton');
        _showError(result.message ?? 'Error al procesar comando');
        return;
      }

      print('✅ result.success = true, continuando...');
      print('🔍 DEBUG: result.interpretation = ${result.interpretation}');
      print('🔍 DEBUG: result.transcribedText = ${result.transcribedText}');

      // 2. Verificar si tenemos interpretación
      if (result.interpretation == null) {
        print('❌ result.interpretation es NULL');
        DebugConfig.info('⚠️ No hay interpretación para mostrar', tag: 'VoiceButton');
        _showError('No se pudo interpretar el comando');
        return;
      }

      print('✅ Tenemos interpretación, extrayendo datos...');

      // 3. Verificar si faltan campos obligatorios
      final action = result.interpretation!['action'] as String;
      print('🔍 DEBUG: action extraída = $action');

      final parameters = result.interpretation!['parameters'] as Map<String, dynamic>;
      print('🔍 DEBUG: parameters extraídos = $parameters');
      print('🔍 DEBUG: parameters.isEmpty = ${parameters.isEmpty}');

      final missingFields = RequiredFields.findMissing(action, parameters);

      print('📊 Acción: $action');
      print('📊 Parámetros actuales: $parameters');
      print('📊 Campos faltantes: $missingFields');
      print('📊 missingFields.isNotEmpty: ${missingFields.isNotEmpty}');
      print('📊 missingFields.length: ${missingFields.length}');

      if (missingFields.isNotEmpty) {
        // Faltan campos obligatorios → Iniciar diálogo conversacional
        print('🗣️ Faltan campos obligatorios, iniciando diálogo conversacional...');
        DebugConfig.info('🗣️ Iniciando diálogo conversacional para recolectar: $missingFields', tag: 'VoiceButton');

        await _startConversationalDialog(
          voiceService,
          result.transcribedText!,
          action,
          parameters,
          missingFields,
        );
      } else {
        // Todos los campos están completos → Ir a confirmación final
        print('✅ Todos los campos completos, mostrando confirmación final');
        DebugConfig.info('✅ Mostrando pantalla de confirmación', tag: 'VoiceButton');

        await _showConfirmationScreen(
          voiceService,
          result.transcribedText!,
          result.interpretation!,
        );
      }

    } catch (e, stackTrace) {
      DebugConfig.error('❌ ERROR CRÍTICO en comando de voz: $e', tag: 'VoiceButton');
      DebugConfig.error('Stack trace: $stackTrace', tag: 'VoiceButton');
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      _showError('Error: ${e.toString()}');
    }
  }

  /// Inicia la pantalla conversacional para recolectar datos faltantes
  Future<void> _startConversationalDialog(
    GeminiVoiceService voiceService,
    String originalCommand,
    String action,
    Map<String, dynamic> collectedParameters,
    List<String> missingFields,
  ) async {
    if (!mounted) return;

    print('🗣️ Iniciando diálogo conversacional');
    print('   - Comando original: "$originalCommand"');
    print('   - Acción: $action');
    print('   - Parámetros ya recolectados: $collectedParameters');
    print('   - Campos faltantes: $missingFields');

    // Crear contexto inicial
    var conversationContext = VoiceConversationContext(
      originalCommand: originalCommand,
      action: action,
      collectedParameters: collectedParameters,
      history: [],
      missingFields: missingFields,
    );

    // Abrir la pantalla conversacional
    final completedContext = await Navigator.of(context).push<VoiceConversationContext>(
      MaterialPageRoute(
        builder: (ctx) => VoiceConversationScreen(
          context: conversationContext,
          voiceService: voiceService,
          onContextUpdated: (updatedContext) {
            conversationContext = updatedContext;
          },
        ),
      ),
    );

    // Si el usuario completó el diálogo, mostrar confirmación final
    if (completedContext != null && mounted) {
      print('✅ Diálogo conversacional completado');
      print('   - Parámetros finales: ${completedContext.collectedParameters}');

      // Crear interpretación completa para la pantalla de confirmación
      final finalInterpretation = {
        'action': completedContext.action,
        'parameters': completedContext.collectedParameters,
        'confidence': 0.95, // Alta confianza porque el usuario lo completó manualmente
        'user_confirmation_needed': false,
      };

      await _showConfirmationScreen(
        voiceService,
        completedContext.originalCommand,
        finalInterpretation,
      );
    } else {
      print('⚠️ Diálogo conversacional cancelado por el usuario');
    }
  }

  Future<void> _showConfirmationScreen(
    GeminiVoiceService voiceService,
    String transcribedText,
    Map<String, dynamic> interpretation,
  ) async {
    if (!mounted) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VoiceCommandConfirmationScreen(
          transcribedText: transcribedText,
          interpretation: interpretation,
          voiceService: voiceService,
        ),
      ),
    );

    if (result != null && widget.onCommandExecuted != null) {
      widget.onCommandExecuted!(result);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Cerrar',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiceServiceAsync = ref.watch(geminiVoiceServiceProvider);

    final isDisabled = voiceServiceAsync.when(
      data: (service) => service == null,
      loading: () => true,
      error: (_, __) => true,
    );

    return FloatingActionButton.extended(
      onPressed: _isRecording || _isProcessing
          ? null
          : _handleVoiceCommand,
      backgroundColor: _isRecording
          ? Colors.red
          : isDisabled
              ? Colors.grey
              : (widget.backgroundColor ?? Theme.of(context).primaryColor),
      icon: _buildIcon(),
      label: Text(_getButtonText()),
      heroTag: 'voice_command_button',
    );
  }

  Widget _buildIcon() {
    if (_isProcessing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_isRecording) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.3),
            child: Icon(
              widget.icon ?? Icons.mic,
              color: Colors.white,
            ),
          );
        },
      );
    }

    return Icon(
      widget.icon ?? Icons.mic,
      color: Colors.white,
    );
  }

  String _getButtonText() {
    if (_isProcessing) {
      return 'Procesando...';
    } else if (_isRecording) {
      return 'HABLA AHORA... (para en 3s de silencio)';
    } else {
      return 'Comando de Voz';
    }
  }
}

/// Versión simple del botón como FAB circular
class VoiceCommandFab extends ConsumerStatefulWidget {
  final Function(dynamic result)? onCommandExecuted;
  final Color? backgroundColor;

  const VoiceCommandFab({
    super.key,
    this.onCommandExecuted,
    this.backgroundColor,
  });

  @override
  ConsumerState<VoiceCommandFab> createState() => _VoiceCommandFabState();
}

class _VoiceCommandFabState extends ConsumerState<VoiceCommandFab>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleVoiceCommand() async {
    print('🎤 ===== VoiceCommandFab PRESIONADO ===== ${DateTime.now()}');

    final voiceServiceAsync = ref.read(geminiVoiceServiceProvider);

    final voiceService = voiceServiceAsync.when(
      data: (service) => service,
      loading: () => null,
      error: (_, __) => null,
    );

    if (voiceService == null) {
      _showError('Gemini API key no configurada. Ve a Configuración → Configurar IA para añadir tu API key.');
      return;
    }

    try {
      setState(() => _isRecording = true);

      // Mostrar diálogo de grabación con control manual
      final recordingSecondsNotifier = ValueNotifier<int>(0);
      bool shouldStopRecording = false;

      // Mostrar el diálogo
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => ValueListenableBuilder<int>(
          valueListenable: recordingSecondsNotifier,
          builder: (context, seconds, child) {
            return VoiceRecordingDialog(
              recordingSeconds: seconds,
              onStop: () {
                shouldStopRecording = true;
                Navigator.of(dialogContext).pop();
              },
            );
          },
        ),
      );

      // Grabar con control manual
      final transcribedText = await voiceService.transcribeAudioOnDevice(
        onProgress: (seconds) {
          recordingSecondsNotifier.value = seconds;
        },
        waitForStopSignal: () async {
          while (!shouldStopRecording && mounted) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        },
      );

      recordingSecondsNotifier.dispose();

      // Cerrar el diálogo si aún está abierto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() => _isRecording = false);

      if (transcribedText.isEmpty) {
        _showError('No se detectó ningún comando de voz');
        return;
      }

      // Interpretar con Gemini
      final interpretation = await voiceService.interpretWithGemini(transcribedText);

      // Crear result object
      final result = VoiceCommandResult(
        success: true,
        message: 'Interpretación completada',
        interpretation: interpretation,
        transcribedText: transcribedText,
        needsConfirmation: interpretation['user_confirmation_needed'] == true,
      );

      if (!result.success) {
        _showError(result.message ?? 'Error');
        return;
      }

      if (result.interpretation == null) {
        _showError('No se pudo interpretar el comando');
        return;
      }

      print('✅ Tenemos interpretación en FAB, extrayendo datos...');

      // Verificar si hay múltiples acciones o una sola
      final hasMultipleActions = result.interpretation!.containsKey('actions');

      if (hasMultipleActions) {
        // Múltiples acciones - ir directamente a confirmación
        print('📊 FAB - Múltiples acciones detectadas');
        final actions = result.interpretation!['actions'] as List<dynamic>;
        print('📊 FAB - Total de acciones: ${actions.length}');

        for (int i = 0; i < actions.length; i++) {
          final action = actions[i] as Map<String, dynamic>;
          print('   ${i + 1}. ${action['action']} - Params: ${action['parameters']}');
        }

        // Ir directamente a confirmación (no hay campos faltantes en workflows complejos)
        print('✅ FAB - Mostrando confirmación de múltiples acciones');

        final executionResult = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VoiceCommandConfirmationScreen(
              transcribedText: result.transcribedText!,
              interpretation: result.interpretation!,
              voiceService: voiceService,
            ),
          ),
        );

        if (executionResult != null && widget.onCommandExecuted != null) {
          widget.onCommandExecuted!(executionResult);
        }
      } else {
        // Una sola acción - verificar campos faltantes
        final action = result.interpretation!['action'] as String;
        final parameters = result.interpretation!['parameters'] as Map<String, dynamic>;
        final missingFields = RequiredFields.findMissing(action, parameters);

        print('📊 FAB - Acción: $action');
        print('📊 FAB - Parámetros actuales: $parameters');
        print('📊 FAB - Campos faltantes: $missingFields');

        if (missingFields.isNotEmpty) {
          // Faltan campos obligatorios → Iniciar pantalla conversacional
          print('🗣️ FAB - Faltan campos, iniciando pantalla conversacional...');

          await _startConversationalScreen(
            voiceService,
            result.transcribedText!,
            action,
            parameters,
            missingFields,
          );
        } else {
          // Todos los campos completos → Ir a confirmación final
          print('✅ FAB - Todos los campos completos, mostrando confirmación final');

          final executionResult = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VoiceCommandConfirmationScreen(
                transcribedText: result.transcribedText!,
                interpretation: result.interpretation!,
                voiceService: voiceService,
              ),
            ),
          );

          if (executionResult != null && widget.onCommandExecuted != null) {
            widget.onCommandExecuted!(executionResult);
          }
        }
      }

    } catch (e) {
      print('❌ FAB - Error: $e');
      setState(() => _isRecording = false);
      _showError(e.toString());
    }
  }

  /// Inicia la pantalla conversacional para recolectar datos faltantes
  Future<void> _startConversationalScreen(
    GeminiVoiceService voiceService,
    String originalCommand,
    String action,
    Map<String, dynamic> collectedParameters,
    List<String> missingFields,
  ) async {
    if (!mounted) return;

    print('🗣️ FAB - Iniciando pantalla conversacional');
    print('   - Comando original: "$originalCommand"');
    print('   - Acción: $action');
    print('   - Parámetros ya recolectados: $collectedParameters');
    print('   - Campos faltantes: $missingFields');

    // Crear contexto inicial
    var conversationContext = VoiceConversationContext(
      originalCommand: originalCommand,
      action: action,
      collectedParameters: collectedParameters,
      history: [],
      missingFields: missingFields,
    );

    // Abrir la pantalla conversacional
    final completedContext = await Navigator.of(context).push<VoiceConversationContext>(
      MaterialPageRoute(
        builder: (ctx) => VoiceConversationScreen(
          context: conversationContext,
          voiceService: voiceService,
          onContextUpdated: (updatedContext) {
            conversationContext = updatedContext;
          },
        ),
      ),
    );

    // Si el usuario completó la conversación, mostrar confirmación final
    if (completedContext != null && mounted) {
      print('✅ FAB - Conversación completada');
      print('   - Parámetros finales: ${completedContext.collectedParameters}');

      // Crear interpretación completa para la pantalla de confirmación
      final finalInterpretation = {
        'action': completedContext.action,
        'parameters': completedContext.collectedParameters,
        'confidence': 0.95,
        'user_confirmation_needed': false,
      };

      final executionResult = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VoiceCommandConfirmationScreen(
            transcribedText: completedContext.originalCommand,
            interpretation: finalInterpretation,
            voiceService: voiceService,
          ),
        ),
      );

      if (executionResult != null && widget.onCommandExecuted != null) {
        widget.onCommandExecuted!(executionResult);
      }
    } else {
      print('⚠️ FAB - Conversación cancelada por el usuario');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiceServiceAsync = ref.watch(geminiVoiceServiceProvider);

    final isDisabled = voiceServiceAsync.when(
      data: (service) => service == null,
      loading: () => true,
      error: (_, __) => true,
    );

    return FloatingActionButton(
      onPressed: _isRecording ? null : _handleVoiceCommand,
      backgroundColor: _isRecording
          ? Colors.red
          : isDisabled
              ? Colors.grey
              : (widget.backgroundColor ?? Theme.of(context).primaryColor),
      child: _isRecording
          ? AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.4),
                  child: const Icon(Icons.mic, color: Colors.white, size: 28),
                );
              },
            )
          : const Icon(Icons.mic, color: Colors.white, size: 28),
    );
  }
}
