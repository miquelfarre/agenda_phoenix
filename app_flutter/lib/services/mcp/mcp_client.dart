import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../config/debug_config.dart';

/// Cliente MCP para comunicarse con el servidor eventypop_mcp
/// Proporciona acceso a schemas de operaciones, validaciones y workflows
class MCPClient {
  Process? _process;
  StreamSubscription? _stdoutSubscription;
  StreamSubscription? _stderrSubscription;
  final _responseController = StreamController<Map<String, dynamic>>.broadcast();
  final _pendingRequests = <String, Completer<Map<String, dynamic>>>{};
  int _requestIdCounter = 0;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Conecta al servidor MCP
  /// Intenta conectarse al contenedor Docker primero, si falla usa modo local
  Future<void> connect() async {
    if (_isConnected) {
      DebugConfig.info('MCP client ya está conectado', tag: 'MCP');
      return;
    }

    try {
      DebugConfig.info('Iniciando servidor MCP...', tag: 'MCP');

      // Intentar conectar al contenedor Docker primero
      final dockerRunning = await _isDockerMCPRunning();

      if (dockerRunning) {
        DebugConfig.info('Usando servidor MCP en Docker (puerto 8002)', tag: 'MCP');
        await _connectToDockerMCP();
      } else {
        DebugConfig.info('Docker MCP no disponible, iniciando en modo local', tag: 'MCP');
        await _connectToLocalMCP();
      }

      _isConnected = true;
      DebugConfig.info('Cliente MCP conectado exitosamente', tag: 'MCP');

      // Enviar mensaje de inicialización
      await _sendRequest('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {},
        'clientInfo': {
          'name': 'eventypop-flutter',
          'version': '1.0.0',
        },
      });

    } catch (e, stackTrace) {
      DebugConfig.error('Error conectando al servidor MCP: $e', tag: 'MCP');
      DebugConfig.error('Stack trace: $stackTrace', tag: 'MCP');
      _isConnected = false;
      rethrow;
    }
  }

  /// Verifica si el servidor MCP en Docker está corriendo
  Future<bool> _isDockerMCPRunning() async {
    try {
      final result = await Process.run('docker', [
        'exec',
        'agenda_phoenix_mcp',
        'python',
        '-c',
        'import sys; sys.exit(0)',
      ]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Conecta al servidor MCP en Docker
  Future<void> _connectToDockerMCP() async {
    // Iniciar proceso que se conecta al contenedor Docker via docker exec
    _process = await Process.start(
      'docker',
      ['exec', '-i', 'agenda_phoenix_mcp', 'python', 'server.py'],
    );

    DebugConfig.info('Conectado a servidor MCP en Docker', tag: 'MCP');

    // Escuchar stdout
    _stdoutSubscription = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleStdout, onError: _handleError);

    // Escuchar stderr
    _stderrSubscription = _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleStderr, onError: _handleError);
  }

  /// Conecta al servidor MCP en modo local (desarrollo)
  Future<void> _connectToLocalMCP() async {
    final mcpServerPath = '/Users/miquelfarre/development/agenda_phoenix/eventypop_mcp';
    final serverScript = '$mcpServerPath/server.py';

    // Verificar que el servidor existe
    if (!await File(serverScript).exists()) {
      throw Exception('MCP server not found at $serverScript');
    }

    // Iniciar el proceso del servidor MCP en modo local
    _process = await Process.start(
      'python3',
      [serverScript],
      workingDirectory: mcpServerPath,
    );

    DebugConfig.info('Servidor MCP iniciado en modo local, PID: ${_process!.pid}', tag: 'MCP');

    // Escuchar stdout
    _stdoutSubscription = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleStdout, onError: _handleError);

    // Escuchar stderr
    _stderrSubscription = _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleStderr, onError: _handleError);
  }

  /// Desconecta del servidor MCP
  Future<void> disconnect() async {
    if (!_isConnected) return;

    DebugConfig.info('Desconectando cliente MCP...', tag: 'MCP');

    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _process?.kill();

    _isConnected = false;
    DebugConfig.info('Cliente MCP desconectado', tag: 'MCP');
  }

  /// Maneja mensajes de stdout del servidor
  void _handleStdout(String line) {
    if (line.trim().isEmpty) return;

    try {
      final message = jsonDecode(line) as Map<String, dynamic>;
      DebugConfig.info('MCP <- $line', tag: 'MCP');

      // Si es una respuesta a una solicitud
      if (message.containsKey('id')) {
        final id = message['id'].toString();
        if (_pendingRequests.containsKey(id)) {
          _pendingRequests[id]!.complete(message);
          _pendingRequests.remove(id);
        }
      }

      _responseController.add(message);
    } catch (e) {
      DebugConfig.error('Error parseando respuesta MCP: $e', tag: 'MCP');
      DebugConfig.error('Línea: $line', tag: 'MCP');
    }
  }

  /// Maneja mensajes de stderr del servidor
  void _handleStderr(String line) {
    if (line.trim().isEmpty) return;
    DebugConfig.error('MCP stderr: $line', tag: 'MCP');
  }

  /// Maneja errores del stream
  void _handleError(dynamic error) {
    DebugConfig.error('MCP stream error: $error', tag: 'MCP');
  }

  /// Envía una solicitud al servidor MCP
  Future<Map<String, dynamic>> _sendRequest(String method, Map<String, dynamic> params) async {
    if (!_isConnected) {
      throw Exception('MCP client not connected');
    }

    final id = '${_requestIdCounter++}';
    final request = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    };

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    final requestJson = jsonEncode(request);
    DebugConfig.info('MCP -> $requestJson', tag: 'MCP');

    _process!.stdin.writeln(requestJson);
    await _process!.stdin.flush();

    // Timeout de 30 segundos
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pendingRequests.remove(id);
        throw TimeoutException('MCP request timed out after 30 seconds');
      },
    );
  }

  /// Llama a una herramienta del servidor MCP
  Future<Map<String, dynamic>> callTool(String toolName, Map<String, dynamic> arguments) async {
    final response = await _sendRequest('tools/call', {
      'name': toolName,
      'arguments': arguments,
    });

    if (response.containsKey('error')) {
      throw Exception('MCP tool error: ${response['error']}');
    }

    // Extraer el contenido de la respuesta
    final result = response['result'] as Map<String, dynamic>;
    final content = result['content'] as List<dynamic>;

    if (content.isEmpty) {
      throw Exception('MCP tool returned empty content');
    }

    final textContent = content[0] as Map<String, dynamic>;
    final text = textContent['text'] as String;

    return jsonDecode(text) as Map<String, dynamic>;
  }

  /// Obtiene el schema de una operación
  Future<OperationSchema> getOperationSchema(String operation, {String language = 'es'}) async {
    DebugConfig.info('Obteniendo schema para operación: $operation', tag: 'MCP');

    final response = await callTool('get_operation_schema', {
      'operation': operation,
      'language': language,
    });

    return OperationSchema.fromJson(response);
  }

  /// Obtiene sugerencias de workflow
  Future<WorkflowSuggestions> getWorkflowSuggestions({
    required String completedAction,
    Map<String, dynamic>? result,
    Map<String, dynamic>? parameters,
    String language = 'es',
  }) async {
    DebugConfig.info('Obteniendo sugerencias para: $completedAction', tag: 'MCP');

    final response = await callTool('get_workflow_suggestions', {
      'completed_action': completedAction,
      'result': result ?? {},
      'parameters': parameters ?? {},
      'language': language,
    });

    return WorkflowSuggestions.fromJson(response);
  }

  /// Valida parámetros antes de enviar al backend
  Future<ValidationResult> validateParameters(String operation, Map<String, dynamic> parameters) async {
    DebugConfig.info('Validando parámetros para: $operation', tag: 'MCP');

    final response = await callTool('validate_parameters', {
      'operation': operation,
      'parameters': parameters,
    });

    return ValidationResult.fromJson(response);
  }

  /// Lista todas las operaciones disponibles
  Future<List<OperationInfo>> listOperations() async {
    final response = await callTool('list_operations', {});
    final operations = response['operations'] as List<dynamic>;

    return operations.map((op) => OperationInfo.fromJson(op as Map<String, dynamic>)).toList();
  }

  /// Obtiene solo los campos obligatorios de una operación
  Future<List<String>> getRequiredFields(String operation) async {
    final response = await callTool('get_required_fields', {'operation': operation});
    return List<String>.from(response['required_fields'] as List<dynamic>);
  }
}

/// Schema de una operación
class OperationSchema {
  final String operation;
  final String description;
  final EndpointInfo endpoint;
  final bool confirmationRequired;
  final Map<String, FieldSchema> fields;

  OperationSchema({
    required this.operation,
    required this.description,
    required this.endpoint,
    required this.confirmationRequired,
    required this.fields,
  });

  factory OperationSchema.fromJson(Map<String, dynamic> json) {
    final fieldsJson = json['fields'] as Map<String, dynamic>;
    final fields = <String, FieldSchema>{};

    fieldsJson.forEach((key, value) {
      fields[key] = FieldSchema.fromJson(value as Map<String, dynamic>);
    });

    return OperationSchema(
      operation: json['operation'] as String,
      description: json['description'] as String? ?? '',
      endpoint: EndpointInfo.fromJson(json['endpoint'] as Map<String, dynamic>),
      confirmationRequired: json['confirmation_required'] as bool? ?? false,
      fields: fields,
    );
  }
}

/// Información de un endpoint
class EndpointInfo {
  final String method;
  final String path;

  EndpointInfo({required this.method, required this.path});

  factory EndpointInfo.fromJson(Map<String, dynamic> json) {
    return EndpointInfo(
      method: json['method'] as String,
      path: json['path'] as String,
    );
  }
}

/// Schema de un campo
class FieldSchema {
  final String type;
  final bool required;
  final dynamic defaultValue;
  final bool autoFromContext;
  final int? maxLength;
  final String? format;
  final List<String>? options;
  final String? question;
  final Map<String, dynamic>? validation;
  final Map<String, dynamic>? dependsOn;
  final Map<String, dynamic>? valueMapping;

  FieldSchema({
    required this.type,
    required this.required,
    this.defaultValue,
    required this.autoFromContext,
    this.maxLength,
    this.format,
    this.options,
    this.question,
    this.validation,
    this.dependsOn,
    this.valueMapping,
  });

  factory FieldSchema.fromJson(Map<String, dynamic> json) {
    return FieldSchema(
      type: json['type'] as String,
      required: json['required'] as bool? ?? false,
      defaultValue: json['default'],
      autoFromContext: json['auto_from_context'] as bool? ?? false,
      maxLength: json['max_length'] as int?,
      format: json['format'] as String?,
      options: json['options'] != null ? List<String>.from(json['options'] as List<dynamic>) : null,
      question: json['question'] as String?,
      validation: json['validation'] as Map<String, dynamic>?,
      dependsOn: json['depends_on'] as Map<String, dynamic>?,
      valueMapping: json['value_mapping'] as Map<String, dynamic>?,
    );
  }
}

/// Sugerencias de workflow
class WorkflowSuggestions {
  final List<ActionSuggestion> suggestions;

  WorkflowSuggestions({required this.suggestions});

  factory WorkflowSuggestions.fromJson(Map<String, dynamic> json) {
    final suggestionsJson = json['suggestions'] as List<dynamic>;
    final suggestions = suggestionsJson
        .map((s) => ActionSuggestion.fromJson(s as Map<String, dynamic>))
        .toList();

    return WorkflowSuggestions(suggestions: suggestions);
  }
}

/// Sugerencia de acción
class ActionSuggestion {
  final String action;
  final String priority;
  final String question;
  final Map<String, dynamic> defaultParameters;

  ActionSuggestion({
    required this.action,
    required this.priority,
    required this.question,
    required this.defaultParameters,
  });

  factory ActionSuggestion.fromJson(Map<String, dynamic> json) {
    return ActionSuggestion(
      action: json['action'] as String,
      priority: json['priority'] as String,
      question: json['question'] as String,
      defaultParameters: json['default_parameters'] as Map<String, dynamic>,
    );
  }
}

/// Resultado de validación
class ValidationResult {
  final bool valid;
  final List<String> missingRequired;
  final List<ValidationError> validationErrors;

  ValidationResult({
    required this.valid,
    required this.missingRequired,
    required this.validationErrors,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    final errorsJson = json['validation_errors'] as List<dynamic>? ?? [];
    final errors = errorsJson
        .map((e) => ValidationError.fromJson(e as Map<String, dynamic>))
        .toList();

    return ValidationResult(
      valid: json['valid'] as bool,
      missingRequired: List<String>.from(json['missing_required'] as List<dynamic>),
      validationErrors: errors,
    );
  }
}

/// Error de validación
class ValidationError {
  final String field;
  final String error;

  ValidationError({required this.field, required this.error});

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] as String,
      error: json['error'] as String,
    );
  }
}

/// Información de operación
class OperationInfo {
  final String name;
  final String description;

  OperationInfo({required this.name, required this.description});

  factory OperationInfo.fromJson(Map<String, dynamic> json) {
    return OperationInfo(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
    );
  }
}
