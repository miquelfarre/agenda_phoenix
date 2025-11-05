import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/debug_config.dart';
import '../api_client.dart';
import '../config_service.dart';
import 'base_voice_service.dart';

/// Servicio que procesa comandos de voz usando Google Gemini para interpretar la intención
/// y ejecutar las acciones correspondientes en la API.
class GeminiVoiceService implements BaseVoiceService {
  final AudioRecorder _recorder = AudioRecorder();
  final SpeechToText _speechToText = SpeechToText();
  final String _geminiApiKey;

  // Configuración de Gemini API (documentación oficial: https://ai.google.dev/api/generate-content)
  // Usar v1beta con modelo gemini-2.0-flash (versión estable más reciente)
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  GeminiVoiceService({required String geminiApiKey})
      : _geminiApiKey = geminiApiKey;

  /// Sistema prompt que define todas las acciones disponibles para Gemini
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

EJEMPLOS:

Usuario: "Crear reunión con Juan mañana a las 3 de la tarde"
Respuesta:
{
  "action": "CREATE_EVENT",
  "parameters": {
    "title": "Reunión con Juan",
    "start_datetime": "${_getTomorrowDate()}T15:00:00",
    "end_datetime": "${_getTomorrowDate()}T16:00:00"
  },
  "confidence": 0.95,
  "user_confirmation_needed": false
}

Usuario: "Elimina el evento de hoy"
Respuesta:
{
  "action": "DELETE_EVENT",
  "parameters": {},
  "confidence": 0.3,
  "user_confirmation_needed": true,
  "clarification_message": "Tienes varios eventos hoy. ¿Cuál quieres eliminar? Por favor especifica el título del evento."
}

Usuario: "Qué eventos tengo esta semana"
Respuesta:
{
  "action": "LIST_EVENTS",
  "parameters": {
    "date_from": "${_getWeekStart()}",
    "date_to": "${_getWeekEnd()}"
  },
  "confidence": 1.0,
  "user_confirmation_needed": false
}

Usuario: "Crea un calendario llamado Trabajo y crea un evento de reunión mañana a las 10 en ese calendario"
Respuesta:
{
  "actions": [
    {
      "action": "CREATE_CALENDAR",
      "parameters": {
        "name": "Trabajo"
      },
      "depends_on_previous": false
    },
    {
      "action": "CREATE_EVENT",
      "parameters": {
        "title": "Reunión",
        "start_datetime": "${_getTomorrowDate()}T10:00:00",
        "calendar_id": "{{previous_result.id}}"
      },
      "depends_on_previous": true
    }
  ],
  "confidence": 0.9,
  "user_confirmation_needed": false
}

Usuario: "Invita a Sara al evento de mañana con un mensaje que diga trae la presentación"
Respuesta:
{
  "action": "INVITE_USER",
  "parameters": {
    "event_id": 123,
    "email": "sara@example.com",
    "message": "Trae la presentación"
  },
  "confidence": 0.85,
  "user_confirmation_needed": false
}

Usuario: "Crea un calendario fines de semana, crea un evento para mañana a las 8 en ese calendario, invita a Sara y Juan, y añádeme una nota para que recuerde llevar el vino"
Respuesta:
{
  "actions": [
    {
      "action": "CREATE_CALENDAR",
      "parameters": {
        "name": "Fines de semana"
      },
      "depends_on_previous": false
    },
    {
      "action": "CREATE_EVENT",
      "parameters": {
        "title": "Evento de mañana",
        "start_datetime": "${_getTomorrowDate()}T20:00:00",
        "calendar_id": "{{previous_result.id}}"
      },
      "depends_on_previous": true
    },
    {
      "action": "INVITE_USER",
      "parameters": {
        "event_id": "{{previous_result.id}}",
        "email": "sara@example.com"
      },
      "depends_on_previous": true
    },
    {
      "action": "INVITE_USER",
      "parameters": {
        "event_id": "{{previous_result.id}}",
        "email": "juan@example.com"
      },
      "depends_on_previous": true
    },
    {
      "action": "ADD_EVENT_NOTE",
      "parameters": {
        "event_id": "{{previous_result.id}}",
        "note": "Llevar el vino"
      },
      "depends_on_previous": true
    }
  ],
  "confidence": 0.9,
  "user_confirmation_needed": false
}
''';

  String _getTomorrowDate() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return tomorrow.toIso8601String().split('T')[0];
  }

  String _getWeekStart() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return weekStart.toIso8601String().split('T')[0];
  }

  String _getWeekEnd() {
    final now = DateTime.now();
    final weekEnd = now.add(Duration(days: 7 - now.weekday));
    return weekEnd.toIso8601String().split('T')[0];
  }

  /// Graba audio desde el micrófono
  Future<String?> recordAudio({Duration? maxDuration}) async {
    try {
      // Verificar y solicitar permisos
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        DebugConfig.error('Permiso de micrófono denegado', tag: 'VoiceService');
        throw Exception('Permiso de micrófono denegado');
      }

      // Verificar si el dispositivo puede grabar
      if (!await _recorder.hasPermission()) {
        throw Exception('No hay permiso para grabar');
      }

      // Crear directorio temporal para el audio
      final tempDir = await getTemporaryDirectory();
      final audioPath = '${tempDir.path}/voice_command_${DateTime.now().millisecondsSinceEpoch}.m4a';

      DebugConfig.info('Iniciando grabación: $audioPath', tag: 'VoiceService');

      // Configurar y comenzar grabación
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _recorder.start(config, path: audioPath);

      // Esperar hasta que se detenga manualmente o se alcance el máximo
      if (maxDuration != null) {
        await Future.delayed(maxDuration);
        await _recorder.stop();
      }

      DebugConfig.info('Grabación completada: $audioPath', tag: 'VoiceService');
      return audioPath;

    } catch (e) {
      DebugConfig.error('Error al grabar audio: $e', tag: 'VoiceService');
      rethrow;
    }
  }

  /// Detiene la grabación de audio
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      DebugConfig.info('Grabación detenida: $path', tag: 'VoiceService');
      return path;
    } catch (e) {
      DebugConfig.error('Error al detener grabación: $e', tag: 'VoiceService');
      rethrow;
    }
  }

  /// Transcribe audio a texto usando speech_to_text (on-device)
  /// Por defecto usa control manual con límite de 30 segundos
  @override
  Future<String> transcribeAudioOnDevice({
    Function(int secondsElapsed)? onProgress,
    Future<void> Function()? waitForStopSignal,
  }) async {
    print('🎤 INICIO transcribeAudioOnDevice()');
    DebugConfig.info('🎤 Inicializando speech-to-text...', tag: 'VoiceService');

    try {
      print('🎤 Llamando a _speechToText.initialize()...');
      final available = await _speechToText.initialize(
        onError: (error) {
          print('❌ Speech error: $error');
          DebugConfig.error('❌ Speech error: $error', tag: 'VoiceService');
        },
        onStatus: (status) {
          print('📊 Speech status: $status');
          DebugConfig.info('📊 Speech status: $status', tag: 'VoiceService');
        },
      );

      print('🎤 Initialize completado. Available: $available');

      if (!available) {
        print('❌ Speech-to-text NO DISPONIBLE');
        DebugConfig.error('❌ Speech-to-text no disponible en este dispositivo', tag: 'VoiceService');
        throw Exception('Speech to text no disponible');
      }

      print('✅ Speech-to-text inicializado correctamente');
      String recognizedText = '';
      bool shouldStop = false;
      int secondsElapsed = 0;
      const maxSeconds = 30;

      // Iniciar escucha (duración máxima 30 segundos)
      print('🎙️ Iniciando escucha (máx 30s)');
      DebugConfig.info('🎙️ Iniciando escucha (habla ahora, máx 30s)...', tag: 'VoiceService');
      await _speechToText.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
          print('🗣️ Texto reconocido: "$recognizedText" (final=${result.finalResult})');
          DebugConfig.info('🗣️ Texto reconocido: "$recognizedText"', tag: 'VoiceService');
        },
        localeId: 'es_ES',
        listenFor: const Duration(seconds: 30), // Máximo 30 segundos
        pauseFor: const Duration(seconds: 30), // No parar por silencio
      );

      // Timer para actualizar el progreso y verificar límite de tiempo
      final progressTimer = Future(() async {
        while (!shouldStop && secondsElapsed < maxSeconds) {
          await Future.delayed(const Duration(seconds: 1));
          secondsElapsed++;
          onProgress?.call(secondsElapsed);
          print('⏱️ Tiempo transcurrido: ${secondsElapsed}s / ${maxSeconds}s');
        }
      });

      // Si se proporciona waitForStopSignal, esperar señal del usuario
      // Si no, esperar solo el timeout
      if (waitForStopSignal != null) {
        await Future.any([
          waitForStopSignal.call().then((_) {
            shouldStop = true;
            print('🛑 Usuario detuvo la grabación');
          }),
          progressTimer,
        ]);
      } else {
        await progressTimer;
      }

      // Detener la escucha
      print('🛑 Deteniendo speech-to-text...');
      await _speechToText.stop();

      if (secondsElapsed >= maxSeconds) {
        print('⚠️ Límite de 30 segundos alcanzado');
        DebugConfig.info('⚠️ Límite de 30s alcanzado', tag: 'VoiceService');
      }

      print('✅ Escucha finalizada. Texto final: "$recognizedText"');
      DebugConfig.info('✅ Escucha finalizada. Texto: "$recognizedText"', tag: 'VoiceService');
      return recognizedText;

    } catch (e) {
      DebugConfig.error('❌ Error en transcripción on-device: $e', tag: 'VoiceService');
      rethrow;
    }
  }


  /// Envía el texto a Gemini para que lo interprete
  /// Si [customPrompt] se proporciona, se usa en lugar del system prompt por defecto
  @override
  Future<Map<String, dynamic>> interpretWithAI(String transcribedText, {String? customPrompt}) async {
    print('🤖 ===== LLAMANDO A GEMINI API =====');
    try {
      print('🤖 Texto a interpretar: "$transcribedText"');
      DebugConfig.info('Enviando a Gemini: $transcribedText', tag: 'VoiceService');

      // Crear el prompt completo
      final fullPrompt = customPrompt ?? '$_systemPrompt\n\nComando del usuario: "$transcribedText"';
      print('🤖 Usando prompt ${customPrompt != null ? "personalizado" : "estándar"}');
      print('🤖 URL: $_geminiApiUrl');
      print('🤖 API Key length: ${_geminiApiKey.length} chars');
      print('🤖 Enviando request a Gemini API...');

      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topP': 0.95,
            'topK': 40,
            'maxOutputTokens': 1024,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE'
            }
          ]
        }),
      );

      print('🤖 Respuesta recibida de Gemini. Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('❌ Error Gemini API: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        DebugConfig.error('Error Gemini API: ${response.statusCode} - ${response.body}',
                         tag: 'VoiceService');
        throw Exception('Error al llamar a Gemini API: ${response.statusCode}');
      }

      print('✅ Status 200 OK, parseando respuesta...');
      final responseData = jsonDecode(response.body);

      // Extraer el texto de la respuesta de Gemini
      final candidates = responseData['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        print('❌ No hay candidates en la respuesta');
        throw Exception('No se recibió respuesta de Gemini');
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List;
      final textResponse = parts[0]['text'] as String;

      print('🤖 Respuesta de Gemini (raw):');
      print('---START---');
      print(textResponse);
      print('---END---');
      DebugConfig.info('Respuesta de Gemini: $textResponse', tag: 'VoiceService');

      // Limpiar la respuesta (por si viene con markdown)
      String cleanedResponse = textResponse.trim();
      if (cleanedResponse.startsWith('```json')) {
        print('🧹 Limpiando markdown json...');
        cleanedResponse = cleanedResponse.replaceFirst('```json', '').replaceFirst('```', '').trim();
      } else if (cleanedResponse.startsWith('```')) {
        print('🧹 Limpiando markdown...');
        cleanedResponse = cleanedResponse.replaceFirst('```', '').replaceFirst('```', '').trim();
      }

      print('🧹 Respuesta limpia:');
      print(cleanedResponse);

      // Parsear la respuesta JSON de Gemini
      print('📋 Parseando JSON...');
      final interpretation = jsonDecode(cleanedResponse) as Map<String, dynamic>;

      print('✅ JSON parseado correctamente:');
      print('   - action: ${interpretation['action']}');
      print('   - confidence: ${interpretation['confidence']}');
      print('   - parameters: ${interpretation['parameters']}');
      print('   - user_confirmation_needed: ${interpretation['user_confirmation_needed']}');

      return interpretation;

    } catch (e) {
      DebugConfig.error('Error al interpretar con Gemini: $e', tag: 'VoiceService');
      rethrow;
    }
  }

  /// Ejecuta la acción interpretada por Gemini usando ApiClient
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

        case 'LIST_EVENTS':
          print('📋 Llamando a apiClient.fetchEvents()...');
          final result = await apiClient.fetchEvents(
            calendarId: parameters['calendar_id'] as int?,
          );
          print('✅ Eventos obtenidos: ${result.length} eventos');
          return result;

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

  /// Método principal que orquesta todo el flujo
  @override
  Future<VoiceCommandResult> processVoiceCommand() async {
    DebugConfig.info('🚀 ===== INICIANDO processVoiceCommand() =====', tag: 'VoiceService');
    try {
      // 1. Transcribir audio (on-device)
      DebugConfig.info('🎙️ PASO 1: Iniciando transcripción on-device...', tag: 'VoiceService');
      final transcribedText = await transcribeAudioOnDevice();
      DebugConfig.info('✅ Transcripción completada: "$transcribedText" (${transcribedText.length} chars)', tag: 'VoiceService');

      if (transcribedText.isEmpty) {
        DebugConfig.info('⚠️ Texto vacío, abortando', tag: 'VoiceService');
        return VoiceCommandResult(
          success: false,
          message: 'No se detectó ningún comando de voz',
        );
      }

      // 2. Interpretar con Gemini
      DebugConfig.info('🤖 PASO 2: Enviando a Gemini para interpretación...', tag: 'VoiceService');
      final interpretation = await interpretWithAI(transcribedText);
      DebugConfig.info('✅ Interpretación recibida: ${interpretation['action']}', tag: 'VoiceService');
      DebugConfig.info('📊 Confidence: ${interpretation['confidence']}', tag: 'VoiceService');
      DebugConfig.info('📋 Parameters: ${interpretation['parameters']}', tag: 'VoiceService');

      // 3. SIEMPRE devolver success=true con la interpretación
      // El botón decidirá si falta información y abrirá el diálogo conversacional
      print('✅ Interpretación completada, devolviendo resultado al botón');
      return VoiceCommandResult(
        success: true,
        message: 'Interpretación completada',
        interpretation: interpretation,
        transcribedText: transcribedText,
        needsConfirmation: interpretation['user_confirmation_needed'] == true,
      );

    } catch (e) {
      print('❌ ERROR en processVoiceCommand: $e');
      DebugConfig.error('Error en processVoiceCommand: $e', tag: 'VoiceService');
      return VoiceCommandResult(
        success: false,
        message: 'Error al procesar comando: ${e.toString()}',
      );
    }
  }

  /// Libera recursos
  void dispose() {
    _recorder.dispose();
    _speechToText.stop();
  }
}

/// Resultado del procesamiento del comando de voz
// VoiceCommandResult ahora está definido en base_voice_service.dart
