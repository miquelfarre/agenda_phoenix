/// Contexto de una conversación de voz multi-turno
/// Mantiene el estado de la conversación para repreguntar datos faltantes
class VoiceConversationContext {
  /// Comando original del usuario
  final String originalCommand;

  /// Acción que se quiere ejecutar (CREATE_EVENT, UPDATE_EVENT, etc.)
  final String action;

  /// Parámetros que ya se han recolectado
  final Map<String, dynamic> collectedParameters;

  /// Historial de preguntas y respuestas
  final List<ConversationTurn> history;

  /// Campos que aún faltan por recolectar
  final List<String> missingFields;

  VoiceConversationContext({
    required this.originalCommand,
    required this.action,
    required this.collectedParameters,
    required this.history,
    required this.missingFields,
  });

  /// Crea un nuevo contexto añadiendo un turno de conversación
  VoiceConversationContext addTurn(String question, String answer, Map<String, dynamic> newParameters) {
    return VoiceConversationContext(
      originalCommand: originalCommand,
      action: action,
      collectedParameters: {...collectedParameters, ...newParameters},
      history: [...history, ConversationTurn(question: question, answer: answer)],
      missingFields: missingFields.where((field) => !newParameters.containsKey(field)).toList(),
    );
  }

  /// Verifica si la conversación está completa (tiene todos los campos necesarios)
  bool get isComplete => missingFields.isEmpty;

  /// Genera un resumen de la conversación para enviar a Gemini
  String get conversationSummary {
    final buffer = StringBuffer();
    buffer.writeln('Comando original: "$originalCommand"');
    buffer.writeln('Acción: $action');
    buffer.writeln('Parámetros recolectados: $collectedParameters');

    if (history.isNotEmpty) {
      buffer.writeln('\nConversación previa:');
      for (var turn in history) {
        buffer.writeln('Sistema: ${turn.question}');
        buffer.writeln('Usuario: ${turn.answer}');
      }
    }

    return buffer.toString();
  }
}

/// Representa un turno de pregunta-respuesta en la conversación
class ConversationTurn {
  final String question;
  final String answer;

  ConversationTurn({
    required this.question,
    required this.answer,
  });
}

/// Define los campos obligatorios para cada acción
class RequiredFields {
  static const Map<String, List<String>> byAction = {
    'CREATE_EVENT': ['title', 'start_datetime'],
    'UPDATE_EVENT': ['event_id', 'title'], // Necesita al menos el ID y un campo a actualizar
    'DELETE_EVENT': ['event_id'],
    'CREATE_CALENDAR': ['name'],
    'INVITE_USER': ['event_id', 'user_id'],
    'LIST_EVENTS': [], // No requiere campos obligatorios
  };

  /// Obtiene los campos obligatorios para una acción
  static List<String> forAction(String action) {
    return byAction[action] ?? [];
  }

  /// Encuentra los campos que faltan en los parámetros proporcionados
  static List<String> findMissing(String action, Map<String, dynamic> parameters) {
    final required = forAction(action);
    return required.where((field) =>
      !parameters.containsKey(field) ||
      parameters[field] == null ||
      (parameters[field] is String && (parameters[field] as String).isEmpty)
    ).toList();
  }

  /// Genera una pregunta amigable para un campo faltante
  static String generateQuestion(String action, String fieldName) {
    switch (fieldName) {
      case 'title':
        return action == 'CREATE_EVENT'
          ? '¿Cuál es el título o nombre del evento?'
          : '¿Cuál es el nuevo título?';
      case 'start_datetime':
        return '¿Cuándo empieza el evento? Por favor indica fecha y hora.';
      case 'end_datetime':
        return '¿Cuándo termina el evento?';
      case 'event_id':
        return '¿Cuál es el ID del evento? Por favor dímelo.';
      case 'name':
        return action == 'CREATE_CALENDAR'
          ? '¿Qué nombre quieres para el calendario?'
          : '¿Qué nombre quieres usar?';
      case 'user_id':
        return '¿A qué usuario quieres invitar? Dime su ID o email.';
      case 'description':
        return action == 'CREATE_CALENDAR'
          ? '¿Quieres añadir una descripción al calendario?'
          : '¿Quieres añadir una descripción?';
      case 'location':
        return '¿Dónde será el evento?';
      case 'is_public':
        return '¿Quieres que el calendario sea público o privado?';
      default:
        return '¿Cuál es el valor para $fieldName?';
    }
  }
}
