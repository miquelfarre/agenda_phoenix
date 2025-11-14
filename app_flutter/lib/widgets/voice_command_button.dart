import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai/gemini_voice_service.dart';
import '../services/ai/ollama_voice_service.dart';
import '../services/ai/base_voice_service.dart';
import '../services/ai/ai_config_service.dart';
import '../services/ai/voice_conversation_context.dart';
import '../screens/voice_command_confirmation_screen.dart';
import '../screens/voice_conversation_screen.dart';
import '../config/debug_config.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import 'voice_recording_dialog.dart';

/// Voice service provider (Gemini or Ollama based on configuration)
final voiceServiceProvider = FutureProvider<BaseVoiceService?>((ref) async {
  DebugConfig.info(
    '🔄 ===== INICIALIZANDO PROVIDER DE VOZ =====',
    tag: 'VoiceButton',
  );
  try {
    DebugConfig.info('📋 Obteniendo AIConfigService...', tag: 'VoiceButton');
    final config = await AIConfigService.getInstance();

    DebugConfig.info('🔍 Verificando configuración...', tag: 'VoiceButton');
    DebugConfig.info(
      '   - AI Provider: ${config.aiProvider}',
      tag: 'VoiceButton',
    );
    DebugConfig.info(
      '   - voiceCommandsEnabled: ${config.voiceCommandsEnabled}',
      tag: 'VoiceButton',
    );

    if (!config.voiceCommandsEnabled) {
      DebugConfig.info('⚠️ Comandos de voz deshabilitados', tag: 'VoiceButton');
      return null;
    }

    // Create service according to configured provider
    if (config.aiProvider == AIProvider.ollama) {
      DebugConfig.info(
        '✅ Usando Ollama (${config.ollamaModel})',
        tag: 'VoiceButton',
      );

      return OllamaVoiceService(
        ollamaBaseUrl: config.ollamaBaseUrl,
        ollamaModel: config.ollamaModel,
      );
    } else {
      // Gemini
      if (!config.hasApiKey) {
        DebugConfig.info('⚠️ Gemini API no configurada', tag: 'VoiceButton');
        return null;
      }

      final apiKey = config.geminiApiKey!;
      DebugConfig.info('✅ Usando Gemini', tag: 'VoiceButton');
      return GeminiVoiceService(geminiApiKey: apiKey);
    }
  } catch (e) {
    DebugConfig.error(
      '❌ Error al inicializar servicio de voz: $e',
      tag: 'VoiceButton',
    );
    return null;
  }
});

/// Floating button to activate voice commands
class VoiceCommandButton extends ConsumerStatefulWidget {
  /// Callback when a command is successfully executed
  final Function(dynamic result)? onCommandExecuted;

  /// Button color
  final Color? backgroundColor;

  /// Button icon
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
    DebugConfig.info(
      '🎤 ===== BOTÓN DE VOZ PRESIONADO =====',
      tag: 'VoiceButton',
    );

    // Show a visual dialog to confirm button works
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.buttonPressedStarting),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    final voiceServiceAsync = ref.read(voiceServiceProvider);

    final voiceService = voiceServiceAsync.when(
      data: (service) {
        DebugConfig.info('✅ Servicio de voz disponible', tag: 'VoiceButton');
        return service;
      },
      loading: () {
        DebugConfig.info('⏳ Servicio de voz cargando...', tag: 'VoiceButton');
        return null;
      },
      error: (error, stack) {
        DebugConfig.error(
          '❌ Error en servicio de voz: $error',
          tag: 'VoiceButton',
        );
        return null;
      },
    );

    if (voiceService == null) {
      DebugConfig.error('❌ Servicio de voz no disponible', tag: 'VoiceButton');
      _showError(context.l10n.aiServiceNotConfigured);
      return;
    }

    try {
      DebugConfig.info('🔴 Iniciando grabación...', tag: 'VoiceButton');
      setState(() => _isRecording = true);

      // 1. Record audio and transcribe
      DebugConfig.info(
        '🎙️ Llamando a processVoiceCommand()...',
        tag: 'VoiceButton',
      );
      final result = await voiceService.processVoiceCommand();

      DebugConfig.info(
        '📥 Resultado recibido: success=${result.success}, needsConfirmation=${result.needsConfirmation}',
        tag: 'VoiceButton',
      );
      DebugConfig.info(
        '📝 Texto transcrito: "${result.transcribedText}"',
        tag: 'VoiceButton',
      );

      setState(() => _isRecording = false);

      if (!result.success) {
        DebugConfig.info('⚠️ Comando no exitoso', tag: 'VoiceButton');
        DebugConfig.error('❌ Error: ${result.message}', tag: 'VoiceButton');
        _showError(result.message ?? 'Error al procesar comando');
        return;
      }

      // 2. Verify if we have interpretation
      if (result.interpretation == null) {
        DebugConfig.info(
          '⚠️ No hay interpretación para mostrar',
          tag: 'VoiceButton',
        );
        _showError('No se pudo interpretar el comando');
        return;
      }

      // 3. Check if required fields are missing
      final action = result.interpretation!['action'] as String;

      final parameters =
          result.interpretation!['parameters'] as Map<String, dynamic>;

      final missingFields = RequiredFields.findMissing(action, parameters);

      if (missingFields.isNotEmpty) {
        // Missing required fields → Start conversational dialog
        DebugConfig.info(
          '🗣️ Iniciando diálogo conversacional para recolectar: $missingFields',
          tag: 'VoiceButton',
        );

        await _startConversationalDialog(
          voiceService,
          result.transcribedText!,
          action,
          parameters,
          missingFields,
        );
      } else {
        // All fields complete → Go to final confirmation
        DebugConfig.info(
          '✅ Mostrando pantalla de confirmación',
          tag: 'VoiceButton',
        );

        await _showConfirmationScreen(
          voiceService,
          result.transcribedText!,
          result.interpretation!,
        );
      }
    } catch (e, stackTrace) {
      DebugConfig.error(
        '❌ ERROR CRÍTICO en comando de voz: $e',
        tag: 'VoiceButton',
      );
      DebugConfig.error('Stack trace: $stackTrace', tag: 'VoiceButton');
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      _showError('Error: ${e.toString()}');
    }
  }

  /// Starts the conversational screen to collect missing data
  Future<void> _startConversationalDialog(
    BaseVoiceService voiceService,
    String originalCommand,
    String action,
    Map<String, dynamic> collectedParameters,
    List<String> missingFields,
  ) async {
    if (!mounted) return;

    // Create initial context
    var conversationContext = VoiceConversationContext(
      originalCommand: originalCommand,
      action: action,
      collectedParameters: collectedParameters,
      history: [],
      missingFields: missingFields,
    );

    // Open conversational screen
    final completedContext = await Navigator.of(context)
        .push<VoiceConversationContext>(
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

    // If user completed the dialog, show final confirmation
    if (completedContext != null && mounted) {
      // Create complete interpretation for confirmation screen
      final finalInterpretation = {
        'action': completedContext.action,
        'parameters': completedContext.collectedParameters,
        'confidence':
            0.95, // High confidence because user completed it manually
        'user_confirmation_needed': false,
      };

      await _showConfirmationScreen(
        voiceService,
        completedContext.originalCommand,
        finalInterpretation,
      );
    } else {}
  }

  Future<void> _showConfirmationScreen(
    BaseVoiceService voiceService,
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
          label: context.l10n.close,
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiceServiceAsync = ref.watch(voiceServiceProvider);

    final isDisabled = voiceServiceAsync.when(
      data: (service) => service == null,
      loading: () => true,
      error: (error, stackTrace) => true,
    );

    return FloatingActionButton.extended(
      onPressed: _isRecording || _isProcessing ? null : _handleVoiceCommand,
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
            child: Icon(widget.icon ?? Icons.mic, color: Colors.white),
          );
        },
      );
    }

    return Icon(widget.icon ?? Icons.mic, color: Colors.white);
  }

  String _getButtonText() {
    if (_isProcessing) {
      return context.l10n.processing;
    } else if (_isRecording) {
      return context.l10n.speakNow;
    } else {
      return context.l10n.voiceCommand;
    }
  }
}

/// Simple version of the button as circular FAB
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
    final voiceServiceAsync = ref.read(voiceServiceProvider);

    final voiceService = voiceServiceAsync.when(
      data: (service) => service,
      loading: () => null,
      error: (error, stackTrace) => null,
    );

    if (voiceService == null) {
      _showError(context.l10n.aiServiceNotConfigured);
      return;
    }

    try {
      setState(() => _isRecording = true);

      // Show recording dialog with manual control
      final recordingSecondsNotifier = ValueNotifier<int>(0);
      bool shouldStopRecording = false;

      // Show the dialog
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

      // Record with manual control
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

      // Close the dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() => _isRecording = false);

      if (transcribedText.isEmpty) {
        _showError(context.l10n.noVoiceDetected);
        return;
      }

      // Interpret with AI (Gemini or Ollama)
      final interpretation = await voiceService.interpretWithAI(
        transcribedText,
      );

      // Create result object
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
        _showError(context.l10n.couldNotInterpretCommand);
        return;
      }

      // Check if there are multiple actions or just one
      final hasMultipleActions = result.interpretation!.containsKey('actions');

      if (hasMultipleActions) {
        // Multiple actions - go directly to confirmation
        final actions = result.interpretation!['actions'] as List<dynamic>;

        for (int i = 0; i < actions.length; i++) {
          actions[i] as Map<String, dynamic>;
        }

        // Go directly to confirmation (no missing fields in complex workflows)

        if (!mounted) return;
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
        // Single action - check missing fields
        final action = result.interpretation!['action'] as String;
        final parameters =
            result.interpretation!['parameters'] as Map<String, dynamic>;
        final missingFields = RequiredFields.findMissing(action, parameters);

        if (missingFields.isNotEmpty) {
          // Missing required fields → Start conversational screen

          await _startConversationalScreen(
            voiceService,
            result.transcribedText!,
            action,
            parameters,
            missingFields,
          );
        } else {
          // All fields complete → Go to final confirmation

          if (!mounted) return;
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
      setState(() => _isRecording = false);
      _showError(e.toString());
    }
  }

  /// Starts the conversational screen to collect missing data
  Future<void> _startConversationalScreen(
    BaseVoiceService voiceService,
    String originalCommand,
    String action,
    Map<String, dynamic> collectedParameters,
    List<String> missingFields,
  ) async {
    if (!mounted) return;

    // Create initial context
    var conversationContext = VoiceConversationContext(
      originalCommand: originalCommand,
      action: action,
      collectedParameters: collectedParameters,
      history: [],
      missingFields: missingFields,
    );

    // Open conversational screen
    final completedContext = await Navigator.of(context)
        .push<VoiceConversationContext>(
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

    // If user completed the conversation, show final confirmation
    if (completedContext != null && mounted) {
      // Create complete interpretation for confirmation screen
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
    } else {}
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiceServiceAsync = ref.watch(voiceServiceProvider);

    final isDisabled = voiceServiceAsync.when(
      data: (service) => service == null,
      loading: () => true,
      error: (error, stackTrace) => true,
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
