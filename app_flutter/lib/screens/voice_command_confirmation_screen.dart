import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/ai/gemini_voice_service.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/adaptive/adaptive_button.dart';
import '../widgets/voice_recording_dialog.dart';
import '../config/app_constants.dart';

/// Pantalla de confirmación de comandos de voz
/// Muestra los objetos que se van a crear de forma clara y no editable
class VoiceCommandConfirmationScreen extends StatefulWidget {
  final String transcribedText;
  final Map<String, dynamic> interpretation;
  final GeminiVoiceService voiceService;

  const VoiceCommandConfirmationScreen({
    super.key,
    required this.transcribedText,
    required this.interpretation,
    required this.voiceService,
  });

  @override
  State<VoiceCommandConfirmationScreen> createState() =>
      _VoiceCommandConfirmationScreenState();
}

class _VoiceCommandConfirmationScreenState
    extends State<VoiceCommandConfirmationScreen> {
  bool _isExecuting = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _getActions() {
    // Verificar si hay múltiples acciones
    if (widget.interpretation.containsKey('actions')) {
      return List<Map<String, dynamic>>.from(
        widget.interpretation['actions'] as List<dynamic>,
      );
    }

    // Una sola acción
    return [
      {
        'action': widget.interpretation['action'],
        'parameters': widget.interpretation['parameters'],
      }
    ];
  }

  Future<void> _executeAction() async {
    setState(() {
      _isExecuting = true;
      _errorMessage = null;
    });

    try {
      print('\n🚀 ===== EJECUTANDO COMANDO DE VOZ =====');
      print('📝 Texto transcrito: "${widget.transcribedText}"');
      print('🎯 Confianza: ${(widget.interpretation['confidence'] as double? ?? 0.0) * 100}%');

      final actions = _getActions();
      print('\n📊 Total de acciones a ejecutar: ${actions.length}');

      for (int i = 0; i < actions.length; i++) {
        final action = actions[i];
        final actionType = action['action'] as String;
        final parameters = action['parameters'] as Map<String, dynamic>;
        final dependsOnPrevious = action['depends_on_previous'] as bool? ?? false;

        print('\n┌─────────────────────────────────────────────────');
        print('│ ACCIÓN ${i + 1}/${actions.length}: $actionType');
        print('├─────────────────────────────────────────────────');

        if (dependsOnPrevious) {
          print('│ 🔗 Depende de la acción anterior');
        }

        // Mostrar endpoint REST
        final restInfo = _getRestEndpointInfo(actionType, parameters);
        print('│ 🌐 REST API:');
        print('│    Método: ${restInfo['method']}');
        print('│    URL: ${restInfo['url']}');
        print('│    Body:');

        // Mostrar el body JSON formateado
        final bodyJson = const JsonEncoder.withIndent('│       ').convert(parameters);
        print('│    {');
        for (final line in bodyJson.split('\n').skip(1)) {
          if (line.trim() == '}') {
            print('│    }');
          } else {
            print('│  $line');
          }
        }

        print('└─────────────────────────────────────────────────');
      }

      print('\n⏳ Iniciando ejecución...\n');

      // Ejecutar la acción
      final result = await widget.voiceService.executeAction(widget.interpretation);

      if (!mounted) return;

      print('\n✅ ===== COMANDO EJECUTADO EXITOSAMENTE =====\n');

      // Mostrar resultado y volver
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Acción ejecutada exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop(result);

    } catch (e, stackTrace) {
      print('\n❌ ===== ERROR AL EJECUTAR COMANDO =====');
      print('Error: $e');
      print('Stack trace: $stackTrace\n');

      setState(() {
        _errorMessage = e.toString();
        _isExecuting = false;
      });
    }
  }

  Map<String, String> _getRestEndpointInfo(String actionType, Map<String, dynamic> parameters) {
    switch (actionType) {
      case 'CREATE_CALENDAR':
        return {
          'method': 'POST',
          'url': 'http://localhost:8001/api/v1/calendars',
        };
      case 'UPDATE_CALENDAR':
        final calendarId = parameters['calendar_id'];
        return {
          'method': 'PUT',
          'url': 'http://localhost:8001/api/v1/calendars/$calendarId',
        };
      case 'DELETE_CALENDAR':
        final calendarId = parameters['calendar_id'];
        return {
          'method': 'DELETE',
          'url': 'http://localhost:8001/api/v1/calendars/$calendarId',
        };
      case 'CREATE_EVENT':
        return {
          'method': 'POST',
          'url': 'http://localhost:8001/api/v1/events',
        };
      case 'UPDATE_EVENT':
        final eventId = parameters['event_id'];
        return {
          'method': 'PUT',
          'url': 'http://localhost:8001/api/v1/events/$eventId',
        };
      case 'DELETE_EVENT':
        final eventId = parameters['event_id'];
        return {
          'method': 'DELETE',
          'url': 'http://localhost:8001/api/v1/events/$eventId',
        };
      case 'INVITE_TO_CALENDAR':
        return {
          'method': 'POST',
          'url': 'http://localhost:8001/api/v1/calendar_memberships',
        };
      case 'INVITE_USER':
        return {
          'method': 'POST',
          'url': 'http://localhost:8001/api/v1/interactions',
        };
      case 'ADD_EVENT_NOTE':
        return {
          'method': 'POST',
          'url': 'http://localhost:8001/api/v1/interactions',
        };
      case 'LIST_EVENTS':
        return {
          'method': 'GET',
          'url': 'http://localhost:8001/api/v1/events',
        };
      default:
        return {
          'method': 'UNKNOWN',
          'url': 'UNKNOWN',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final confidence = widget.interpretation['confidence'] as double? ?? 0.0;
    final theme = Theme.of(context);
    final actions = _getActions();

    return AdaptivePageScaffold(
      title: 'Confirmar Comando',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Confianza
            _buildConfidenceIndicator(confidence),

            const SizedBox(height: 24),

            // Lo que dijiste
            _buildSectionCard(
              icon: Icons.mic,
              title: 'Lo que dijiste',
              color: Colors.blue,
              child: Text(
                '"${widget.transcribedText}"',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Título de objetos a crear
            Text(
              'Se crearán ${actions.length} ${actions.length == 1 ? 'objeto' : 'objetos'}:',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Tarjetas de cada acción/objeto
            ...actions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildActionCard(action, index + 1),
              );
            }),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(),
            ],

            const SizedBox(height: 24),

            // Nota informativa
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Si quieres cambiar algo, dilo por voz después de confirmar',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botones de acción
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> actionData, int number) {
    final actionType = actionData['action'] as String;
    final parameters = actionData['parameters'] as Map<String, dynamic>;
    final dependsOnPrevious = actionData['depends_on_previous'] as bool? ?? false;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: BorderSide(
          color: _getActionColor(actionType).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con número y tipo
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getActionColor(actionType),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getActionIcon(actionType),
                            color: _getActionColor(actionType),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getActionTitle(actionType),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getActionColor(actionType),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (dependsOnPrevious) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.link,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Depende de la acción anterior',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Detalles del objeto (pasamos el número para que pueda buscar acciones anteriores)
            _buildObjectDetails(actionType, parameters, number),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectDetails(String actionType, Map<String, dynamic> parameters, int actionNumber) {
    switch (actionType) {
      case 'CREATE_CALENDAR':
        return _buildCalendarDetails(parameters);
      case 'CREATE_EVENT':
        return _buildEventDetails(parameters, actionNumber);
      case 'INVITE_TO_CALENDAR':
      case 'INVITE_USER':
        return _buildInvitationDetails(parameters, actionNumber);
      case 'ADD_EVENT_NOTE':
        return _buildEventNoteDetails(parameters, actionNumber);
      case 'UPDATE_CALENDAR':
        return _buildUpdateCalendarDetails(parameters);
      case 'UPDATE_EVENT':
        return _buildUpdateEventDetails(parameters);
      case 'DELETE_EVENT':
      case 'DELETE_CALENDAR':
        return _buildDeleteDetails(parameters);
      default:
        return _buildGenericDetails(parameters);
    }
  }

  Widget _buildCalendarDetails(Map<String, dynamic> params) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(Icons.label, 'Nombre', params['name'] ?? 'Sin nombre'),
        if (params['description'] != null)
          _buildDetailRow(Icons.description, 'Descripción', params['description']),
        if (params['color'] != null)
          _buildDetailRow(Icons.palette, 'Color', params['color']),
        if (params['is_public'] != null)
          _buildDetailRow(
            params['is_public'] ? Icons.public : Icons.lock,
            'Visibilidad',
            params['is_public'] ? 'Público' : 'Privado',
          ),
      ],
    );
  }

  Widget _buildEventDetails(Map<String, dynamic> params, int actionNumber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(Icons.title, 'Título', params['title'] ?? 'Sin título'),
        if (params['start_datetime'] != null)
          _buildDetailRow(Icons.schedule, 'Fecha y hora', _formatDateTime(params['start_datetime'])),
        if (params['end_datetime'] != null)
          _buildDetailRow(Icons.schedule_send, 'Termina', _formatDateTime(params['end_datetime'])),
        if (params['location'] != null)
          _buildDetailRow(Icons.location_on, 'Ubicación', params['location']),
        if (params['description'] != null)
          _buildDetailRow(Icons.notes, 'Descripción', params['description']),
        if (params['all_day'] == true)
          _buildDetailRow(Icons.calendar_today, 'Todo el día', 'Sí'),
        if (params['calendar_id'] != null)
          _buildDetailRow(
            Icons.calendar_month,
            'En calendario',
            _formatPlaceholderWithContext(
              params['calendar_id'].toString(),
              'El calendario recién creado',
              actionNumber,
              'calendar',
            ),
          ),
      ],
    );
  }

  Widget _buildInvitationDetails(Map<String, dynamic> params, int actionNumber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (params['user_id'] != null)
          _buildDetailRow(Icons.person, 'Usuario ID', _formatPlaceholder(params['user_id'].toString(), 'El usuario recién añadido')),
        if (params['email'] != null)
          _buildDetailRow(Icons.email, 'Email', params['email']),
        if (params['user_emails'] != null)
          _buildDetailRow(Icons.group, 'Usuarios', (params['user_emails'] as List).join(', ')),
        if (params['calendar_id'] != null)
          _buildDetailRow(
            Icons.calendar_month,
            'Al calendario',
            _formatPlaceholderWithContext(
              params['calendar_id'].toString(),
              'El calendario recién creado',
              actionNumber,
              'calendar',
            ),
          ),
        if (params['event_id'] != null)
          _buildDetailRow(
            Icons.event,
            'Al evento',
            _formatPlaceholderWithContext(
              params['event_id'].toString(),
              'El evento recién creado',
              actionNumber,
              'event',
            ),
          ),
        if (params['role'] != null)
          _buildDetailRow(Icons.badge, 'Rol', params['role']),
        if (params['message'] != null && params['message'].toString().isNotEmpty)
          _buildDetailRow(Icons.note, 'Nota personal', params['message']),
      ],
    );
  }

  Widget _buildEventNoteDetails(Map<String, dynamic> params, int actionNumber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (params['event_id'] != null)
          _buildDetailRow(
            Icons.event,
            'Para el evento',
            _formatPlaceholderWithContext(
              params['event_id'].toString(),
              'El evento recién creado',
              actionNumber,
              'event',
            ),
          ),
        if (params['note'] != null)
          _buildDetailRow(Icons.sticky_note_2, 'Mi nota', params['note']),
        // Indicador de que se creará o actualizará
        _buildDetailRow(
          Icons.info_outline,
          'Información',
          'Si ya tienes una nota en este evento, se reemplazará con esta nueva',
        ),
      ],
    );
  }

  Widget _buildUpdateCalendarDetails(Map<String, dynamic> params) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(Icons.edit, 'Actualizando calendario', 'ID: ${params['calendar_id']}'),
        if (params['name'] != null)
          _buildDetailRow(Icons.label, 'Nuevo nombre', params['name']),
        if (params['description'] != null)
          _buildDetailRow(Icons.description, 'Nueva descripción', params['description']),
        if (params['is_public'] != null)
          _buildDetailRow(
            params['is_public'] ? Icons.public : Icons.lock,
            'Nueva visibilidad',
            params['is_public'] ? 'Público' : 'Privado',
          ),
      ],
    );
  }

  Widget _buildUpdateEventDetails(Map<String, dynamic> params) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(Icons.edit, 'Actualizando evento', 'ID: ${params['event_id']}'),
        if (params['title'] != null)
          _buildDetailRow(Icons.title, 'Nuevo título', params['title']),
        if (params['start_datetime'] != null)
          _buildDetailRow(Icons.schedule, 'Nueva fecha', _formatDateTime(params['start_datetime'])),
        if (params['location'] != null)
          _buildDetailRow(Icons.location_on, 'Nueva ubicación', params['location']),
      ],
    );
  }

  Widget _buildDeleteDetails(Map<String, dynamic> params) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
          Icons.warning,
          'Atención',
          'Esta acción no se puede deshacer',
        ),
        if (params['event_id'] != null)
          _buildDetailRow(Icons.event, 'Evento a eliminar', 'ID: ${params['event_id']}'),
        if (params['calendar_id'] != null)
          _buildDetailRow(Icons.calendar_month, 'Calendario a eliminar', 'ID: ${params['calendar_id']}'),
      ],
    );
  }

  Widget _buildGenericDetails(Map<String, dynamic> params) {
    if (params.isEmpty) {
      return const Text('Sin parámetros adicionales');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: params.entries.map((entry) {
        return _buildDetailRow(
          Icons.info,
          entry.key,
          entry.value?.toString() ?? 'null',
        );
      }).toList(),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic datetime) {
    if (datetime == null) return '';
    try {
      final dt = DateTime.parse(datetime.toString());
      final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} a las ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return datetime.toString();
    }
  }

  String _formatPlaceholder(String value, String friendlyText) {
    // Detectar si el valor contiene un placeholder como {{previous_result.id}}
    if (value.contains('{{') && value.contains('}}')) {
      return friendlyText;
    }
    // Si es un ID numérico, mostrarlo con formato
    if (int.tryParse(value) != null) {
      return 'ID: $value';
    }
    return value;
  }

  /// Versión mejorada que busca el nombre real del objeto en acciones anteriores
  String _formatPlaceholderWithContext(
    String value,
    String fallbackText,
    int currentActionNumber,
    String objectType, // 'calendar', 'event', etc.
  ) {
    // Si no es un placeholder, devolver el valor tal cual
    if (!value.contains('{{') || !value.contains('}}')) {
      if (int.tryParse(value) != null) {
        return 'ID: $value';
      }
      return value;
    }

    // Buscar en acciones anteriores el objeto que se está referenciando
    final actions = _getActions();

    // Buscar la acción anterior que creó este objeto
    for (int i = 0; i < currentActionNumber - 1; i++) {
      final previousAction = actions[i];
      final actionType = previousAction['action'] as String;
      final params = previousAction['parameters'] as Map<String, dynamic>;

      String? objectName;

      // Buscar el nombre según el tipo de objeto
      if (objectType == 'calendar' && actionType == 'CREATE_CALENDAR') {
        objectName = params['name'] as String?;
      } else if (objectType == 'event' && actionType == 'CREATE_EVENT') {
        objectName = params['title'] as String?;
      }

      // Si encontramos el nombre, devolverlo con un indicador
      if (objectName != null && objectName.isNotEmpty) {
        return '$objectName (recién creado)';
      }
    }

    // Si no encontramos nada, devolver el texto genérico
    return fallbackText;
  }

  String _getActionTitle(String action) {
    switch (action) {
      case 'CREATE_EVENT':
        return 'Evento';
      case 'CREATE_CALENDAR':
        return 'Calendario';
      case 'INVITE_TO_CALENDAR':
        return 'Invitación a calendario';
      case 'INVITE_USER':
        return 'Invitación a evento';
      case 'ADD_EVENT_NOTE':
        return 'Nota personal';
      case 'UPDATE_EVENT':
        return 'Actualizar evento';
      case 'UPDATE_CALENDAR':
        return 'Actualizar calendario';
      case 'DELETE_EVENT':
        return 'Eliminar evento';
      case 'DELETE_CALENDAR':
        return 'Eliminar calendario';
      default:
        return action.replaceAll('_', ' ');
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'CREATE_EVENT':
      case 'UPDATE_EVENT':
        return Icons.event;
      case 'CREATE_CALENDAR':
      case 'UPDATE_CALENDAR':
        return Icons.calendar_month;
      case 'INVITE_TO_CALENDAR':
      case 'INVITE_USER':
        return Icons.person_add;
      case 'ADD_EVENT_NOTE':
        return Icons.sticky_note_2;
      case 'DELETE_EVENT':
      case 'DELETE_CALENDAR':
        return Icons.delete_forever;
      default:
        return Icons.settings;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'CREATE_EVENT':
      case 'CREATE_CALENDAR':
        return Colors.green;
      case 'UPDATE_EVENT':
      case 'UPDATE_CALENDAR':
        return Colors.orange;
      case 'INVITE_TO_CALENDAR':
      case 'INVITE_USER':
        return Colors.blue;
      case 'ADD_EVENT_NOTE':
        return Colors.purple;
      case 'DELETE_EVENT':
      case 'DELETE_CALENDAR':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildConfidenceIndicator(double confidence) {
    Color color;
    String label;
    IconData icon;

    if (confidence >= 0.8) {
      color = Colors.green;
      label = 'Alta confianza';
      icon = Icons.check_circle;
    } else if (confidence >= 0.5) {
      color = Colors.orange;
      label = 'Confianza media';
      icon = Icons.warning;
    } else {
      color = Colors.red;
      label = 'Baja confianza';
      icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: confidence,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(confidence * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botón de corregir con voz
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isExecuting ? null : _correctWithVoice,
            icon: const Icon(Icons.mic, color: Colors.orange),
            label: const Text(
              'Corregir con voz',
              style: TextStyle(color: Colors.orange),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Botones de cancelar y ejecutar
        Row(
          children: [
            Expanded(
              child: AdaptiveButton(
                config: AdaptiveButtonConfig.secondary(),
                onPressed: _isExecuting ? null : () => Navigator.of(context).pop(),
                text: 'Cancelar',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AdaptiveButton(
                config: AdaptiveButtonConfig.primary(),
                onPressed: _isExecuting ? null : _executeAction,
                text: _isExecuting ? 'Ejecutando...' : 'Confirmar y Ejecutar',
                icon: _isExecuting ? null : Icons.check,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _correctWithVoice() async {
    print('\n🎤 ===== USUARIO QUIERE CORREGIR CON VOZ =====');

    // Mostrar diálogo de grabación
    final recordingSecondsNotifier = ValueNotifier<int>(0);
    bool shouldStopRecording = false;

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

    try {
      // Grabar corrección
      final correctionText = await widget.voiceService.transcribeAudioOnDevice(
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

      if (correctionText.isEmpty) {
        _showError('No se detectó ninguna corrección');
        return;
      }

      print('📝 Corrección transcrita: "$correctionText"');

      // Crear un prompt especial para que Gemini interprete la corrección
      final correctionPrompt = '''
Contexto: El usuario había pedido realizar estas acciones:
"${widget.transcribedText}"

Interpretación actual:
${const JsonEncoder.withIndent('  ').convert(widget.interpretation)}

Ahora el usuario quiere hacer una corrección o añadir información:
"$correctionText"

Por favor, genera una nueva interpretación COMPLETA que incluya las correcciones del usuario.
Si el usuario quiere añadir una acción nueva, añádela al array de actions.
Si el usuario quiere modificar una acción existente, actualiza los parámetros correspondientes.
Si el usuario quiere eliminar una acción, no la incluyas en la respuesta.

IMPORTANTE: Devuelve la interpretación completa y actualizada en el mismo formato JSON que antes.
''';

      print('🤖 Enviando corrección a Gemini...');

      // Interpretar la corrección
      final updatedInterpretation = await widget.voiceService.interpretWithGemini(
        correctionText,
        customPrompt: correctionPrompt,
      );

      print('✅ Nueva interpretación recibida');
      print('📊 Interpretación actualizada: ${const JsonEncoder.withIndent('  ').convert(updatedInterpretation)}');

      // Cerrar esta pantalla y volver al FAB con la nueva interpretación
      // El FAB volverá a abrir la pantalla de confirmación con los datos actualizados
      if (mounted) {
        // Navegar de vuelta con la nueva interpretación
        Navigator.of(context).pop(); // Cerrar pantalla de confirmación actual

        // Abrir nueva pantalla de confirmación con datos actualizados
        final executionResult = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VoiceCommandConfirmationScreen(
              transcribedText: '$widget.transcribedText\n[Corrección: $correctionText]',
              interpretation: updatedInterpretation,
              voiceService: widget.voiceService,
            ),
          ),
        );

        // Si se ejecutó, propagar el resultado
        if (executionResult != null && mounted) {
          Navigator.of(context).pop(executionResult);
        }
      }

    } catch (e, stackTrace) {
      print('❌ Error al corregir con voz: $e');
      print('Stack trace: $stackTrace');

      recordingSecondsNotifier.dispose();

      // Cerrar diálogo si está abierto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showError('Error al procesar la corrección: ${e.toString()}');
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
}
