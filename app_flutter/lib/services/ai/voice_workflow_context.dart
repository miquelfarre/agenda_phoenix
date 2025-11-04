/// Contexto de un flujo de trabajo de voz que puede incluir múltiples acciones
/// Ejemplo: Crear calendario → Hacerlo público → Añadir evento → Invitar usuario
class VoiceWorkflowContext {
  /// Comando original del usuario
  final String originalCommand;

  /// Lista de acciones completadas
  final List<CompletedAction> completedActions;

  /// Acción actual que se está procesando
  final WorkflowAction? currentAction;

  /// Acciones pendientes sugeridas por el sistema
  final List<SuggestedAction> suggestedActions;

  /// Parámetros globales del flujo (ej: calendar_id después de crear)
  final Map<String, dynamic> globalContext;

  VoiceWorkflowContext({
    required this.originalCommand,
    required this.completedActions,
    this.currentAction,
    required this.suggestedActions,
    required this.globalContext,
  });

  /// Crea un nuevo workflow inicial
  factory VoiceWorkflowContext.initial(String command) {
    return VoiceWorkflowContext(
      originalCommand: command,
      completedActions: [],
      currentAction: null,
      suggestedActions: [],
      globalContext: {},
    );
  }

  /// Marca la acción actual como completada y guarda resultados
  VoiceWorkflowContext completeCurrentAction(Map<String, dynamic> result) {
    if (currentAction == null) return this;

    return VoiceWorkflowContext(
      originalCommand: originalCommand,
      completedActions: [
        ...completedActions,
        CompletedAction(
          action: currentAction!.action,
          parameters: currentAction!.parameters,
          result: result,
        ),
      ],
      currentAction: null,
      suggestedActions: suggestedActions,
      globalContext: {...globalContext, ...result},
    );
  }

  /// Inicia una nueva acción en el workflow
  VoiceWorkflowContext startAction(WorkflowAction action) {
    return VoiceWorkflowContext(
      originalCommand: originalCommand,
      completedActions: completedActions,
      currentAction: action,
      suggestedActions: suggestedActions,
      globalContext: globalContext,
    );
  }

  /// Actualiza las acciones sugeridas
  VoiceWorkflowContext updateSuggestions(List<SuggestedAction> newSuggestions) {
    return VoiceWorkflowContext(
      originalCommand: originalCommand,
      completedActions: completedActions,
      currentAction: currentAction,
      suggestedActions: newSuggestions,
      globalContext: globalContext,
    );
  }

  /// Actualiza el contexto global con nuevos datos
  VoiceWorkflowContext updateGlobalContext(Map<String, dynamic> updates) {
    return VoiceWorkflowContext(
      originalCommand: originalCommand,
      completedActions: completedActions,
      currentAction: currentAction,
      suggestedActions: suggestedActions,
      globalContext: {...globalContext, ...updates},
    );
  }

  /// Verifica si el workflow está completo (no hay acciones pendientes)
  bool get isComplete => currentAction == null && suggestedActions.isEmpty;
}

/// Representa una acción que está en proceso
class WorkflowAction {
  final String action;
  final Map<String, dynamic> parameters;
  final List<String> missingFields;

  WorkflowAction({
    required this.action,
    required this.parameters,
    required this.missingFields,
  });

  /// Actualiza los parámetros con nueva información
  WorkflowAction updateParameters(Map<String, dynamic> newParams) {
    final updated = {...parameters, ...newParams};
    final stillMissing = RequiredFields.findMissing(action, updated);

    return WorkflowAction(
      action: action,
      parameters: updated,
      missingFields: stillMissing,
    );
  }

  /// Verifica si la acción está lista para ejecutar
  bool get isReady => missingFields.isEmpty;
}

/// Representa una acción que ya fue ejecutada
class CompletedAction {
  final String action;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic> result;

  CompletedAction({
    required this.action,
    required this.parameters,
    required this.result,
  });
}

/// Representa una acción sugerida por el sistema
class SuggestedAction {
  final String action;
  final String question;
  final Map<String, dynamic> defaultParameters;

  SuggestedAction({
    required this.action,
    required this.question,
    required this.defaultParameters,
  });
}

/// Define acciones relacionadas que se pueden sugerir después de cada acción principal
class WorkflowSuggestions {
  /// Genera sugerencias basadas en la acción completada
  static List<SuggestedAction> afterAction(
    String completedAction,
    Map<String, dynamic> result,
  ) {
    switch (completedAction) {
      case 'CREATE_CALENDAR':
        return _afterCreateCalendar(result);
      case 'CREATE_EVENT':
        return _afterCreateEvent(result);
      default:
        return [];
    }
  }

  static List<SuggestedAction> _afterCreateCalendar(Map<String, dynamic> result) {
    final calendarId = result['id'];

    return [
      SuggestedAction(
        action: 'UPDATE_CALENDAR',
        question: '¿Quieres que el calendario sea público para que otros puedan suscribirse?',
        defaultParameters: {
          'calendar_id': calendarId,
          'is_public': true,
        },
      ),
      SuggestedAction(
        action: 'CREATE_EVENT',
        question: '¿Quieres crear un evento en este calendario?',
        defaultParameters: {
          'calendar_id': calendarId,
        },
      ),
      SuggestedAction(
        action: 'INVITE_TO_CALENDAR',
        question: '¿Quieres compartir el calendario con alguien?',
        defaultParameters: {
          'calendar_id': calendarId,
        },
      ),
      SuggestedAction(
        action: 'ADD_CALENDAR_ADMIN',
        question: '¿Quieres hacer a alguien administrador del calendario?',
        defaultParameters: {
          'calendar_id': calendarId,
          'role': 'admin',
        },
      ),
    ];
  }

  static List<SuggestedAction> _afterCreateEvent(Map<String, dynamic> result) {
    final eventId = result['id'];

    return [
      SuggestedAction(
        action: 'INVITE_USER',
        question: '¿Quieres invitar a alguien a este evento?',
        defaultParameters: {
          'event_id': eventId,
        },
      ),
      SuggestedAction(
        action: 'UPDATE_EVENT',
        question: '¿Quieres añadir más detalles al evento?',
        defaultParameters: {
          'event_id': eventId,
        },
      ),
    ];
  }

  /// Genera una pregunta general para ofrecer las sugerencias
  static String generateSuggestionsPrompt(List<SuggestedAction> suggestions) {
    if (suggestions.isEmpty) return '';

    if (suggestions.length == 1) {
      return suggestions.first.question;
    }

    // Para múltiples sugerencias, crear una pregunta abierta
    return '¿Quieres hacer algo más con esto? Por ejemplo: '
        '${suggestions.map((s) => _actionToShortPhrase(s.action)).join(', ')}.';
  }

  static String _actionToShortPhrase(String action) {
    switch (action) {
      case 'UPDATE_CALENDAR':
        return 'hacerlo público';
      case 'CREATE_EVENT':
        return 'añadir un evento';
      case 'INVITE_TO_CALENDAR':
        return 'compartirlo con alguien';
      case 'ADD_CALENDAR_ADMIN':
        return 'hacer admin a alguien';
      case 'INVITE_USER':
        return 'invitar a alguien';
      case 'UPDATE_EVENT':
        return 'añadir más detalles';
      default:
        return action.toLowerCase().replaceAll('_', ' ');
    }
  }
}

/// Extensión a RequiredFields para las nuevas acciones
extension WorkflowRequiredFields on RequiredFields {
  static const Map<String, List<String>> workflowActions = {
    'INVITE_TO_CALENDAR': ['calendar_id', 'user_email'],
    'ADD_CALENDAR_ADMIN': ['calendar_id', 'user_email'],
  };

  static List<String> forWorkflowAction(String action) {
    return workflowActions[action] ?? RequiredFields.forAction(action);
  }

  static String generateWorkflowQuestion(String action, String fieldName) {
    switch (fieldName) {
      case 'user_email':
        if (action == 'INVITE_TO_CALENDAR') {
          return '¿A qué usuario quieres compartir el calendario? Dime su email.';
        }
        if (action == 'ADD_CALENDAR_ADMIN') {
          return '¿A quién quieres hacer administrador? Dime su email.';
        }
        return '¿Cuál es el email del usuario?';
      case 'calendar_id':
        return '¿En qué calendario?';
      default:
        return RequiredFields.generateQuestion(action, fieldName);
    }
  }
}

// Re-exportar RequiredFields para que esté disponible
class RequiredFields {
  static const Map<String, List<String>> byAction = {
    'CREATE_EVENT': ['title', 'start_datetime'],
    'UPDATE_EVENT': ['event_id', 'title'],
    'DELETE_EVENT': ['event_id'],
    'CREATE_CALENDAR': ['name'],
    'INVITE_USER': ['event_id', 'user_id'],
    'LIST_EVENTS': [],
    'INVITE_TO_CALENDAR': ['calendar_id', 'user_email'],
    'ADD_CALENDAR_ADMIN': ['calendar_id', 'user_email'],
  };

  static List<String> forAction(String action) {
    return byAction[action] ?? [];
  }

  static List<String> findMissing(String action, Map<String, dynamic> parameters) {
    final required = forAction(action);
    return required.where((field) =>
      !parameters.containsKey(field) ||
      parameters[field] == null ||
      (parameters[field] is String && (parameters[field] as String).isEmpty)
    ).toList();
  }

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
        return '¿Cuál es el ID del evento?';
      case 'name':
        return action == 'CREATE_CALENDAR'
          ? '¿Qué nombre quieres para el calendario?'
          : '¿Qué nombre quieres usar?';
      case 'user_id':
        return '¿A qué usuario quieres invitar? Dime su ID o email.';
      case 'user_email':
        return '¿Cuál es el email del usuario?';
      case 'description':
        return action == 'CREATE_CALENDAR'
          ? '¿Quieres añadir una descripción al calendario?'
          : '¿Quieres añadir una descripción?';
      case 'location':
        return '¿Dónde será el evento?';
      case 'is_public':
        return '¿Quieres que el calendario sea público o privado?';
      case 'calendar_id':
        return '¿En qué calendario?';
      default:
        return '¿Cuál es el valor para $fieldName?';
    }
  }
}
