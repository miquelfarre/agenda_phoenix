# EventyPop MCP Server

**Model Context Protocol Server** para EventyPop - Proporciona metadata dinámica sobre operaciones, schemas de API y workflows inteligentes para comandos de voz.

## ¿Qué es esto?

Este MCP server actúa como una **capa de abstracción inteligente** entre el cliente Flutter y el backend FastAPI. Proporciona:

1. **Schema dinámico de operaciones**: Qué acciones están disponibles y qué parámetros necesitan
2. **Metadata de campos**: Tipos, validaciones, si son obligatorios u opcionales
3. **Preguntas contextuales**: Qué preguntar al usuario para completar una acción
4. **Workflows inteligentes**: Qué acciones sugerir después de completar otra
5. **Mapeo a endpoints**: Cómo traducir operaciones a llamadas HTTP al backend

## Arquitectura

```
┌─────────────────┐
│  Flutter App    │
│  (Cliente)      │
└────────┬────────┘
         │ MCP Protocol
         │ (stdio/SSE)
         ↓
┌─────────────────┐
│  MCP Server     │ ← Este proyecto
│  (Python)       │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  Backend API    │
│  (FastAPI)      │
└─────────────────┘
```

## Estructura del Proyecto

```
eventypop_mcp/
├── README.md                    # Este archivo
├── pyproject.toml              # Dependencias Python
├── server.py                   # Punto de entrada del MCP server
├── schemas/                    # Definiciones de schemas
│   ├── operations.yaml         # Operaciones disponibles
│   ├── fields.yaml            # Definición de campos
│   └── workflows.yaml         # Workflows y sugerencias
├── tools/                      # Herramientas MCP
│   ├── get_operation_schema.py
│   ├── get_workflow_suggestions.py
│   └── validate_parameters.py
└── tests/                      # Tests
    └── test_operations.py
```

## Instalación

```bash
# Desde el directorio raíz de agenda_phoenix
cd eventypop_mcp

# Crear entorno virtual
python3 -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -e .
```

## Uso

### Iniciar el servidor

```bash
python server.py
```

El servidor escuchará en stdio por defecto (compatible con MCP protocol).

### Desde Flutter

```dart
// Conectar al MCP server
final mcp = MCPClient();
await mcp.connect();

// Obtener schema de una operación
final schema = await mcp.callTool('get_operation_schema', {
  'operation': 'CREATE_CALENDAR'
});

// Obtener sugerencias de workflow
final suggestions = await mcp.callTool('get_workflow_suggestions', {
  'completed_action': 'CREATE_CALENDAR',
  'result': {'id': 123}
});
```

## Herramientas Disponibles

### 1. `get_operation_schema`
Obtiene el schema completo de una operación.

**Input:**
```json
{
  "operation": "CREATE_CALENDAR"
}
```

**Output:**
```json
{
  "operation": "CREATE_CALENDAR",
  "endpoint": {
    "method": "POST",
    "path": "/api/v1/calendars"
  },
  "fields": {
    "name": {
      "type": "string",
      "required": true,
      "max_length": 255,
      "question": {
        "es": "¿Qué nombre quieres para el calendario?",
        "en": "What name do you want for the calendar?"
      }
    },
    "description": {
      "type": "string",
      "required": false,
      "max_length": 500,
      "question": {
        "es": "¿Quieres añadir una descripción?",
        "en": "Do you want to add a description?"
      }
    },
    "is_public": {
      "type": "boolean",
      "required": false,
      "default": false,
      "question": {
        "es": "¿Quieres que sea público o privado?",
        "en": "Do you want it to be public or private?"
      }
    }
  }
}
```

### 2. `get_workflow_suggestions`
Obtiene sugerencias de acciones después de completar una operación.

**Input:**
```json
{
  "completed_action": "CREATE_CALENDAR",
  "result": {
    "id": 123,
    "name": "Mi Calendario"
  }
}
```

**Output:**
```json
{
  "suggestions": [
    {
      "action": "UPDATE_CALENDAR",
      "priority": "high",
      "question": {
        "es": "¿Quieres que el calendario sea público?",
        "en": "Do you want to make the calendar public?"
      },
      "default_parameters": {
        "calendar_id": 123,
        "is_public": true
      }
    },
    {
      "action": "CREATE_EVENT",
      "priority": "high",
      "question": {
        "es": "¿Quieres crear un evento en este calendario?",
        "en": "Do you want to create an event in this calendar?"
      },
      "default_parameters": {
        "calendar_id": 123
      }
    }
  ]
}
```

### 3. `validate_parameters`
Valida parámetros antes de enviar al backend.

**Input:**
```json
{
  "operation": "CREATE_CALENDAR",
  "parameters": {
    "name": "Mi Calendario"
  }
}
```

**Output:**
```json
{
  "valid": true,
  "missing_required": [],
  "validation_errors": []
}
```

## Ventajas sobre Hardcoded

✅ **Escalable**: Añadir operaciones = editar YAML, no recompilar
✅ **Internacionalizable**: Preguntas en múltiples idiomas
✅ **Configurable**: Cambiar preguntas sin código
✅ **Dinámico**: Se adapta a cambios en la API
✅ **Source of Truth**: Schema centralizado
✅ **Versionable**: Control de cambios en Git

## Desarrollo

```bash
# Instalar en modo desarrollo
pip install -e ".[dev]"

# Ejecutar tests
pytest

# Ejecutar con hot reload
uvicorn server:app --reload
```

## Integración con Claude Code

Este MCP server se puede conectar directamente a Claude Code para proporcionar contexto sobre las operaciones disponibles:

```json
{
  "mcpServers": {
    "eventypop": {
      "command": "python",
      "args": ["/path/to/eventypop_mcp/server.py"]
    }
  }
}
```

## Próximos Pasos

- [ ] Implementar generación automática desde schema FastAPI
- [ ] Añadir soporte para OpenAPI/Swagger
- [ ] Cache inteligente de schemas
- [ ] Webhooks para notificar cambios
- [ ] Dashboard web para visualizar operaciones
