import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai/ai_config_service.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/adaptive/adaptive_button.dart';
import '../config/app_constants.dart';

/// Pantalla de configuración de Google Gemini API
class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscureApiKey = true;
  bool _voiceCommandsEnabled = true;
  String? _errorMessage;
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    try {
      final config = await AIConfigService.getInstance();
      setState(() {
        _hasApiKey = config.hasApiKey;
        _voiceCommandsEnabled = config.voiceCommandsEnabled;
        if (_hasApiKey) {
          // Mostrar solo los últimos 4 caracteres
          final apiKey = config.geminiApiKey!;
          final visiblePart = apiKey.length > 4
              ? apiKey.substring(apiKey.length - 4)
              : apiKey;
          _apiKeyController.text = '••••$visiblePart';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar configuración: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingresa una API key');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final config = await AIConfigService.getInstance();

      if (!config.isValidApiKeyFormat(apiKey)) {
        setState(() {
          _errorMessage =
              'Formato de API key inválido. Debe ser una cadena alfanumérica de al menos 30 caracteres.';
          _isSaving = false;
        });
        return;
      }

      final success = await config.setGeminiApiKey(apiKey);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ API key guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _hasApiKey = true;
          _isSaving = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al guardar la API key';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isSaving = false;
      });
    }
  }

  Future<void> _clearApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar API Key'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar la API key de Gemini? '
          'Los comandos de voz dejarán de funcionar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final config = await AIConfigService.getInstance();
      final success = await config.clearGeminiApiKey();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key eliminada'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _hasApiKey = false;
          _apiKeyController.clear();
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error al eliminar: $e');
    }
  }

  Future<void> _toggleVoiceCommands(bool enabled) async {
    try {
      final config = await AIConfigService.getInstance();
      final success = await config.setVoiceCommandsEnabled(enabled);

      if (success) {
        setState(() => _voiceCommandsEnabled = enabled);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AdaptivePageScaffold(
        title: 'Configuración de AI',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AdaptivePageScaffold(
      title: 'Configuración de AI',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildApiKeySection(),
            const SizedBox(height: 24),
            _buildVoiceCommandsToggle(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
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
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Text(
                  'Sobre Google Gemini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Google Gemini API permite interpretar comandos de voz y ejecutar acciones '
              'en tu agenda de forma inteligente.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cómo obtener tu API key GRATIS:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStep('1', 'Ve a ai.google.dev'),
            _buildStep('2', 'Haz clic en "Get API key in Google AI Studio"'),
            _buildStep('3', 'Inicia sesión con tu cuenta de Google'),
            _buildStep('4', 'Haz clic en "Create API key"'),
            _buildStep('5', 'Copia y pega la key aquí abajo'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade700, width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '100% GRATIS - 1500 requests/día sin tarjeta de crédito',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildApiKeySection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Google Gemini API Key',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_hasApiKey)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Configurada',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'AIzaSy...',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscureApiKey
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscureApiKey = !_obscureApiKey);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_paste),
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          _apiKeyController.text = data!.text!;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AdaptiveButton(
                    config: AdaptiveButtonConfig.primary(),
                    onPressed: _isSaving ? null : _saveApiKey,
                    text: _isSaving ? 'Guardando...' : 'Guardar API Key',
                    icon: Icons.save,
                  ),
                ),
                if (_hasApiKey) ...[
                  const SizedBox(width: 12),
                  AdaptiveButton(
                    config: AdaptiveButtonConfig.secondary(),
                    onPressed: _clearApiKey,
                    text: 'Eliminar',
                    icon: Icons.delete,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCommandsToggle() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: SwitchListTile(
        title: const Text(
          'Habilitar Comandos de Voz',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Permite usar comandos de voz para crear eventos y gestionar tu agenda',
        ),
        value: _voiceCommandsEnabled,
        onChanged: _hasApiKey ? _toggleVoiceCommands : null,
        secondary: const Icon(Icons.mic),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
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

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
