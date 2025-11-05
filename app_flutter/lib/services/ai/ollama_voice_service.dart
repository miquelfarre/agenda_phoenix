import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import '../../config/debug_config.dart';
import '../api_client.dart';
import '../config_service.dart';
import 'base_voice_service.dart';

/// Servicio que procesa comandos de voz usando Ollama (LLM local)
/// Compatible con la API de Ollama: https://github.com/ollama/ollama/blob/main/docs/api.md
class OllamaVoiceService implements BaseVoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final String _ollamaBaseUrl;
  final String _ollamaModel;

  OllamaVoiceService({
    required String ollamaBaseUrl,
    required String ollamaModel,
  })  : _ollamaBaseUrl = ollamaBaseUrl,
        _ollamaModel = ollamaModel;

  /// Sistema prompt - debe coincidir con GeminiVoiceService
  String get _systemPrompt => '''
Eres un asistente de voz para una aplicación de agenda/calendario llamada EventyPop.
Tu trabajo es interpretar comandos de voz del usuario y convertirlos en acciones estructuradas.

ACCIONES DISPONIBLES EN LA API:

1. CREATE_EVENT - Crear un evento nuevo
   Parámetros requeridos:
   - name: string (nombre del evento)
   - start_date: ISO 8601 (ej: "2024-03-15T14:30:00")
   Parámetros opcionales:
   - description: string
   - calendar_id: integer (si no se especifica, se crea en el calendario principal)
   - event_type: string ("regular" o "recurring", default: "regular")

2. UPDATE_EVENT - Modificar un evento existente
   Parámetros:
   - event_id: integer (requerido)
   - name: string (opcional)
   - start_date: ISO 8601 (opcional)
   - description: string (opcional)

3. DELETE_EVENT - Eliminar un evento
   Parámetros:
   - event_id: integer (requerido)
   - confirmation: boolean (debe ser true)

4. LIST_EVENTS - Listar eventos
   Parámetros opcionales:
   - calendar_id: integer
   - date_from: ISO 8601 date
   - date_to: ISO 8601 date

5. CREATE_CALENDAR - Crear un calendario nuevo
   Parámetros:
   - name: string (requerido)
   - description: string (opcional) - Descripción detallada del calendario
   - is_discoverable: boolean (opcional) - Si es público, ¿puede aparecer en búsquedas?

6. INVITE_TO_CALENDAR - Suscribir usuarios a un calendario (verán TODOS los eventos del calendario)
   Parámetros:
   - calendar_id: integer (requerido)
   - contact_names: array de strings (nombres de contactos, ej: ["Miquel", "Ada", "Sara"])
   - role: string (opcional: "owner", "editor", "member", default: "member")
   - message: string (opcional)

7. INVITE_USER - Invitar usuario a un evento específico (solo verá ESE evento)
   Parámetros:
   - event_id: integer (requerido)
   - user_id: integer o email: string (requerido)
   - message: string (opcional) - Nota o mensaje personal para el invitado

8. ADD_EVENT_NOTE - Añadir/actualizar nota personal al evento (para el creador/owner)
   Parámetros:
   - event_id: integer (requerido)
   - note: string (requerido) - Nota personal para recordar algo sobre el evento
   Nota: Si el owner ya tiene una nota en este evento, se actualizará con la nueva

FORMATO DE RESPUESTA:
Debes responder ÚNICAMENTE con un objeto JSON válido, sin texto adicional, sin markdown.

IMPORTANTE: Si el usuario pide MÚLTIPLES ACCIONES en un solo comando (ej: "crea un calendario Y crea un evento Y invita a usuarios"),
debes devolver un array "actions" con todas las acciones en secuencia.

Estructura del JSON para UNA acción:
{
  "action": "NOMBRE_ACCION",
  "parameters": {
    // parámetros específicos de la acción
  },
  "confidence": 0.0-1.0,
  "user_confirmation_needed": boolean,
  "clarification_message": "mensaje opcional si necesitas más info del usuario",
  "suggestions": [
    "¿Quieres añadir una descripción al evento?",
    "¿Prefieres que el calendario sea público?"
  ]
}

Estructura del JSON para MÚLTIPLES acciones:
{
  "actions": [
    {
      "action": "PRIMERA_ACCION",
      "parameters": { ... },
      "depends_on_previous": false
    },
    {
      "action": "SEGUNDA_ACCION",
      "parameters": {
        // Usa "{{previous_result.id}}" para referenciar el resultado de la acción anterior
        "calendar_id": "{{previous_result.id}}"
      },
      "depends_on_previous": true
    }
  ],
  "confidence": 0.0-1.0,
  "user_confirmation_needed": boolean,
  "suggestions": [
    "¿Quieres añadir una descripción a alguno de los eventos?",
    "¿El calendario debe ser público o privado?",
    "¿Quieres configurar recordatorios para estos eventos?"
  ]
}

REGLAS:
- Si el usuario usa conectores como "Y", "luego", "después", "también", identifica MÚLTIPLES ACCIONES
- Usa el formato "actions" array cuando hay más de una acción
- Marca "depends_on_previous": true si una acción necesita el resultado de la anterior
- Para fechas relativas ("mañana", "el viernes", "la próxima semana"), calcula la fecha exacta
- La fecha de hoy es: ${DateTime.now().toIso8601String().split('T')[0]}
- Si no entiendes el comando, usa action: "UNKNOWN"
- Mantén confidence alto (>0.8) solo si estás seguro
- IMPORTANTE: Si hay múltiples contactos para invitar (ej: "Miquel, Ada y Sara"), crea UNA ACCIÓN POR CADA CONTACTO con contact_names: ["nombre"]
- IMPORTANTE: Incluye un campo "suggestions" con preguntas útiles para que el usuario mejore/ajuste las acciones antes de ejecutarlas

IMPORTANTE - Diferencia entre INVITE_TO_CALENDAR e INVITE_USER:
- "Invita a X al calendario" / "Suscribe a X al calendario" / "Comparte el calendario con X" → INVITE_TO_CALENDAR
- "Invita a X al evento" / "Añade a X al evento" → INVITE_USER
- Si el usuario dice "invita a X" sin especificar, y hay un calendario recién creado → INVITE_TO_CALENDAR
''';

  @override
  Future<Map<String, dynamic>> interpretWithAI(String transcribedText, {String? customPrompt}) async {
    print('🤖 ===== LLAMANDO A OLLAMA API =====');
    try {
      DebugConfig.info('Enviando a Ollama: $transcribedText', tag: 'VoiceService');

      final fullPrompt = customPrompt ?? '$_systemPrompt\n\nComando del usuario: "$transcribedText"';

      print('🤖 URL: $_ollamaBaseUrl/api/generate');
      print('🤖 Model: $_ollamaModel');
      print('🤖 Enviando request a Ollama...');

      final response = await http.post(
        Uri.parse('$_ollamaBaseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _ollamaModel,
          'prompt': fullPrompt,
          'stream': false,
          'format': 'json',
        }),
      ).timeout(
        const Duration(minutes: 5), // Timeout de 5 minutos para modelos pesados
        onTimeout: () {
          throw Exception('Timeout: El modelo de Ollama tardó más de 5 minutos en responder. '
              'Considera usar un modelo más ligero.');
        },
      );

      print('🤖 Respuesta recibida de Ollama. Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('❌ Error Ollama API: ${response.statusCode}');
        print(response.body);
        DebugConfig.error('Error Ollama API: ${response.statusCode} - ${response.body}',
            tag: 'VoiceService');
        throw Exception('Error al llamar a Ollama API: ${response.statusCode}');
      }

      // Parsear respuesta de Ollama
      final jsonResponse = jsonDecode(response.body);
      final textResponse = jsonResponse['response'] as String?;

      if (textResponse == null || textResponse.isEmpty) {
        throw Exception('No se recibió respuesta de Ollama');
      }

      print('🤖 Respuesta de Ollama (raw):');
      print(textResponse);

      DebugConfig.info('Respuesta de Ollama: $textResponse', tag: 'VoiceService');

      // Limpiar la respuesta (eliminar markdown si lo hay)
      String cleanedResponse = textResponse.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      // Parsear la respuesta JSON del LLM
      final interpretation = jsonDecode(cleanedResponse) as Map<String, dynamic>;

      print('✅ Interpretación exitosa: ${interpretation['action']}');
      return interpretation;

    } catch (e, stackTrace) {
      print('❌ Error al interpretar con Ollama: $e');
      print(stackTrace);
      DebugConfig.error('Error al interpretar con Ollama: $e', tag: 'VoiceService');
      rethrow;
    }
  }

  @override
  Future<dynamic> executeAction(Map<String, dynamic> interpretation) async {
    print('🔧 ===== EJECUTANDO ACCIÓN EN API =====');
    try {
      final action = interpretation['action'] as String;
      final parameters = interpretation['parameters'] as Map<String, dynamic>;
      final apiClient = ApiClient();

      print('🔧 Acción: $action');
      print('🔧 Parámetros: $parameters');
      DebugConfig.info('Ejecutando acción: $action con parámetros: $parameters',
                      tag: 'VoiceService');

      switch (action) {
        case 'CREATE_EVENT':
          print('📝 Llamando a apiClient.createEvent()...');
          final result = await apiClient.createEvent(parameters);
          print('✅ Evento creado: $result');
          return result;

        case 'UPDATE_EVENT':
          print('✏️ Llamando a apiClient.updateEvent()...');
          final eventId = parameters['event_id'] as int;
          parameters.remove('event_id');
          final result = await apiClient.updateEvent(eventId, parameters);
          print('✅ Evento actualizado: $result');
          return result;

        case 'DELETE_EVENT':
          print('🗑️ Llamando a apiClient.deleteEvent()...');
          final eventId = parameters['event_id'] as int;
          await apiClient.deleteEvent(eventId);
          print('✅ Evento eliminado');
          return {'success': true, 'message': 'Evento eliminado'};

        case 'CREATE_CALENDAR':
          print('📅 Llamando a apiClient.createCalendar()...');
          final result = await apiClient.createCalendar(parameters);
          print('✅ Calendario creado: $result');
          return result;

        case 'INVITE_USER':
          print('✉️ Llamando a apiClient.createInteraction()...');
          final eventId = parameters['event_id'] as int;
          final userId = parameters['user_id'] as int?;
          final message = parameters['message'] as String?;
          final interactionData = {
            'event_id': eventId,
            'user_id': userId,
            'interaction_type': 'invited',
            'status': 'pending',
          };
          // Añadir nota/mensaje si existe
          if (message != null && message.isNotEmpty) {
            interactionData['note'] = message;
          }
          final result = await apiClient.createInteraction(interactionData);
          print('✅ Usuario invitado: $result');
          return result;

        case 'ADD_EVENT_NOTE':
          print('📝 Añadiendo nota personal al evento...');
          final eventId = parameters['event_id'] as int;
          final note = parameters['note'] as String;

          // Obtener el ID del usuario actual (owner) desde ConfigService
          final currentUserId = ConfigService.instance.currentUserId;

          // Verificar si ya existe una interacción del owner para este evento
          print('🔍 Verificando si ya existe interacción del owner...');
          final existingInteractions = await apiClient.fetchInteractions(
            eventId: eventId,
            userId: currentUserId,
          );

          if (existingInteractions.isNotEmpty) {
            // Ya existe una interacción - actualizar la nota
            print('♻️ Interacción existente encontrada, actualizando nota...');
            final existingInteraction = existingInteractions.first;
            final interactionId = existingInteraction['id'] as int;
            final result = await apiClient.patchInteraction(
              interactionId,
              {'note': note},
            );
            print('✅ Nota personal actualizada: $result');
            return result;
          } else {
            // No existe - crear nueva interacción tipo 'joined' para el owner con la nota
            print('➕ No existe interacción, creando nueva...');
            final interactionData = {
              'event_id': eventId,
              'user_id': currentUserId,
              'interaction_type': 'joined',
              'status': 'accepted',
              'note': note,
              'invited_by_user_id': currentUserId, // El owner se añade a sí mismo
            };
            final result = await apiClient.createInteraction(interactionData);
            print('✅ Nota personal añadida: $result');
            return result;
          }

        case 'UNKNOWN':
          print('❓ Comando UNKNOWN');
          return {
            'success': false,
            'message': interpretation['clarification_message'] ??
                      'No entendí el comando. Por favor, intenta de nuevo.'
          };

        default:
          throw Exception('Acción no reconocida: $action');
      }

    } catch (e) {
      print('❌ ERROR al ejecutar acción: $e');
      DebugConfig.error('Error al ejecutar acción: $e', tag: 'VoiceService');
      rethrow;
    }
  }

  @override
  Future<String> transcribeAudioOnDevice({
    Function(int secondsElapsed)? onProgress,
    Future<void> Function()? waitForStopSignal,
  }) async {
    print('🎤 INICIO transcribeAudioOnDevice()');
    DebugConfig.info('🎤 Inicializando speech-to-text...', tag: 'VoiceService');

    try {
      // Inicializar speech-to-text si no está ya inicializado
      if (!_speechToText.isAvailable) {
        final available = await _speechToText.initialize(
          onError: (error) {
            print('❌ Error en speech-to-text: ${error.errorMsg}');
            DebugConfig.error('Error en speech-to-text: ${error.errorMsg}', tag: 'VoiceService');
          },
          onStatus: (status) {
            print('📊 Estado speech-to-text: $status');
          },
        );

        if (!available) {
          throw Exception('Speech-to-text no está disponible en este dispositivo');
        }
      }

      print('✅ Speech-to-text inicializado correctamente');
      DebugConfig.info('Speech-to-text inicializado', tag: 'VoiceService');

      String transcribedText = '';
      bool shouldStop = false;
      int secondsElapsed = 0;
      const maxSeconds = 30;

      // Callback para capturar texto en tiempo real
      await _speechToText.listen(
        onResult: (result) {
          transcribedText = result.recognizedWords;
          print('🎤 Transcripción en progreso: "$transcribedText"');
        },
        localeId: 'es_ES',
        listenFor: const Duration(seconds: 30), // Máximo 30 segundos
        pauseFor: const Duration(seconds: 30), // No parar por silencio
      );

      // Timer para actualizar el progreso
      final progressTimer = Future(() async {
        while (!shouldStop && secondsElapsed < maxSeconds) {
          await Future.delayed(const Duration(seconds: 1));
          secondsElapsed++;
          onProgress?.call(secondsElapsed);
        }
      });

      // Esperar señal del usuario o timeout
      if (waitForStopSignal != null) {
        await Future.any([
          waitForStopSignal.call().then((_) {
            shouldStop = true;
          }),
          progressTimer,
        ]);
      } else {
        await progressTimer;
      }

      // Detener la escucha
      await _speechToText.stop();

      print('✅ Transcripción completada: "$transcribedText"');
      DebugConfig.info('Texto transcrito: $transcribedText', tag: 'VoiceService');

      if (transcribedText.isEmpty) {
        throw Exception('No se pudo transcribir el audio');
      }

      return transcribedText;

    } catch (e) {
      print('❌ Error en transcripción: $e');
      DebugConfig.error('Error en transcripción: $e', tag: 'VoiceService');
      rethrow;
    }
  }

  @override
  Future<VoiceCommandResult> processVoiceCommand() async {
    DebugConfig.info('🚀 ===== INICIANDO processVoiceCommand() =====', tag: 'VoiceService');
    try {
      // 1. Transcribir audio (on-device)
      print('🎤 PASO 1/2: Transcribiendo audio...');
      final transcribedText = await transcribeAudioOnDevice();

      // 2. Interpretar con Ollama
      print('🤖 PASO 2/2: Interpretando con Ollama...');
      final interpretation = await interpretWithAI(transcribedText);

      // Retornar resultado
      return VoiceCommandResult(
        success: true,
        transcribedText: transcribedText,
        interpretation: interpretation,
        needsConfirmation: interpretation['user_confirmation_needed'] ?? true,
      );

    } catch (e) {
      print('❌ ERROR en processVoiceCommand: $e');
      DebugConfig.error('Error al procesar comando de voz: $e', tag: 'VoiceService');
      return VoiceCommandResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }
}
