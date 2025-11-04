# Integración del MCP Server con EventyPop

## ✅ Estado Actual

El servidor MCP está **completamente integrado** en el sistema EventyPop y se levanta automáticamente con el resto de servicios.

## Arquitectura Implementada

```
┌──────────────────────────────────────────────────────────────┐
│  Flutter App (iOS/Android)                                   │
│  ├─ MCPClient (lib/services/mcp/mcp_client.dart)            │
│  └─ Conecta via docker exec o proceso local                 │
└────────────────────┬─────────────────────────────────────────┘
                     │ stdio/JSON-RPC
                     ↓
┌──────────────────────────────────────────────────────────────┐
│  Docker Container: agenda_phoenix_mcp (puerto 8002)          │
│  ├─ server.py (MCP Server Python)                           │
│  ├─ schemas/operations.yaml (20+ operaciones)               │
│  └─ schemas/workflows.yaml (sugerencias inteligentes)       │
└────────────────────┬─────────────────────────────────────────┘
                     │ Metadata
                     ↓
┌──────────────────────────────────────────────────────────────┐
│  Backend API (FastAPI) - puerto 8001                         │
│  └─ Endpoints: POST /api/v1/calendars, etc.                 │
└──────────────────────────────────────────────────────────────┘
```

## Arranque del Sistema

### Comando único

```bash
./start.sh
```

Esto levanta **automáticamente**:
- ✅ Base de datos PostgreSQL (puerto 5432)
- ✅ Backend FastAPI (puerto 8001)
- ✅ **MCP Server** (puerto 8002) ← **NUEVO**
- ✅ Supabase Studio (puerto 3000)
- ✅ Kong Gateway (puerto 8000)
- ✅ Realtime Server (puerto 4000)
- ✅ Storage, Auth, Meta, REST...

### Logs al arrancar

```
[start] Building Docker images (backend + MCP)...
[✔] ⚙️  FastAPI Backend on port 8001
[✔] ⚙️  EventyPop MCP Server on port 8002
[✔] ⚙️  Supabase Studio on port 3000
[✔] ⚙️  Kong API Gateway on port 8000
[start] Starting all services in Docker (detached mode)...
[✔] Backend ready at http://localhost:8001
[✔] MCP Server ready (schemas in eventypop_mcp/schemas/)
[start] All services running in Docker containers:
[start]   - Backend API: http://localhost:8001
[start]   - API Docs: http://localhost:8001/docs
[start]   - MCP Server: port 8002 (stdio mode for Flutter)
[start]   - Supabase Studio: http://localhost:3000
[start]   - Kong Gateway: http://localhost:8000
[start]
[start] 💡 MCP schemas are hot-reloadable (edit eventypop_mcp/schemas/*.yaml)
```

## Uso desde Flutter

### 1. Conectar al MCP Server

```dart
import 'package:eventypop/services/mcp/mcp_client.dart';

// El cliente se conecta automáticamente al contenedor Docker
final mcp = MCPClient();
await mcp.connect();
```

**El cliente es inteligente:**
- Si Docker está corriendo → usa el contenedor (producción)
- Si Docker no está disponible → usa proceso local (desarrollo)

### 2. Obtener Schema de una Operación

```dart
// Obtener schema completo para CREATE_CALENDAR
final schema = await mcp.getOperationSchema('CREATE_CALENDAR', language: 'es');

print(schema.operation);           // "CREATE_CALENDAR"
print(schema.endpoint.method);     // "POST"
print(schema.endpoint.path);       // "/api/v1/calendars"

// Iterar sobre los campos
for (var entry in schema.fields.entries) {
  final fieldName = entry.key;
  final fieldSchema = entry.value;

  print('Campo: $fieldName');
  print('  Tipo: ${fieldSchema.type}');
  print('  Obligatorio: ${fieldSchema.required}');
  print('  Pregunta: ${fieldSchema.question}');
}
```

**Output ejemplo:**
```
Campo: name
  Tipo: string
  Obligatorio: true
  Pregunta: ¿Qué nombre quieres para el calendario?

Campo: description
  Tipo: string
  Obligatorio: false
  Pregunta: ¿Quieres añadir una descripción al calendario?

Campo: is_public
  Tipo: boolean
  Obligatorio: false
  Pregunta: ¿Quieres que el calendario sea público o privado?
```

### 3. Obtener Sugerencias de Workflow

```dart
// Después de crear un calendario
final suggestions = await mcp.getWorkflowSuggestions(
  completedAction: 'CREATE_CALENDAR',
  result: {'id': 123, 'name': 'Mi Calendario'},
  parameters: {},
  language: 'es',
);

// Mostrar sugerencias al usuario
for (var suggestion in suggestions.suggestions) {
  print('${suggestion.priority}: ${suggestion.question}');
  print('  Acción: ${suggestion.action}');
  print('  Params por defecto: ${suggestion.defaultParameters}');
}
```

**Output ejemplo:**
```
high: ¿Quieres crear un evento en este calendario?
  Acción: CREATE_EVENT
  Params por defecto: {calendar_id: 123}

high: ¿Quieres compartir el calendario con alguien?
  Acción: INVITE_TO_CALENDAR
  Params por defecto: {calendar_id: 123, role: member}

medium: ¿Quieres que el calendario sea público?
  Acción: UPDATE_CALENDAR
  Params por defecto: {calendar_id: 123, is_public: true}
```

### 4. Validar Parámetros

```dart
// Antes de enviar al backend, validar
final validation = await mcp.validateParameters(
  'CREATE_CALENDAR',
  {'name': 'Mi Calendario'},
);

if (!validation.valid) {
  print('Faltan campos: ${validation.missingRequired}');
  for (var error in validation.validationErrors) {
    print('Error en ${error.field}: ${error.error}');
  }
}
```

### 5. Listar Todas las Operaciones

```dart
final operations = await mcp.listOperations();

for (var op in operations) {
  print('${op.name}: ${op.description}');
}
```

## Ventajas del Sistema MCP

### ✅ No más Hardcoded

**Antes (hardcoded):**
```dart
// En código Dart
static const Map<String, List<String>> byAction = {
  'CREATE_CALENDAR': ['name'],  // ← Hay que cambiar código
  'CREATE_EVENT': ['title', 'start_datetime'],
};
```

**Ahora (dinámico):**
```yaml
# En eventypop_mcp/schemas/operations.yaml
CREATE_CALENDAR:
  fields:
    name:
      type: string
      required: true
      questions:
        es: "¿Qué nombre quieres para el calendario?"
        en: "What name do you want for the calendar?"
```

### ✅ Hot-Reload de Schemas

Edita `eventypop_mcp/schemas/operations.yaml` → Los cambios se aplican **sin reiniciar**:

```bash
# Los schemas están montados como volumen read-only
volumes:
  - ./eventypop_mcp/schemas:/app/schemas:ro
```

### ✅ Multiidioma Automático

```yaml
questions:
  es: "¿Qué nombre quieres?"
  en: "What name do you want?"
  ca: "Quin nom vols?"
```

```dart
// Cambiar idioma es trivial
await mcp.getOperationSchema('CREATE_CALENDAR', language: 'en');
```

### ✅ Workflows Inteligentes

El sistema sugiere acciones contextuales:

```yaml
workflows:
  CREATE_CALENDAR:
    suggestions:
      - action: CREATE_EVENT
        priority: high
        questions:
          es: "¿Quieres crear un evento en este calendario?"
      - action: INVITE_TO_CALENDAR
        priority: high
        questions:
          es: "¿Quieres compartir el calendario con alguien?"
```

### ✅ Validación Centralizada

No necesitas validar manualmente:

```yaml
name:
  type: string
  required: true
  max_length: 255
  validation:
    not_empty: true
```

```dart
// El MCP valida automáticamente
final validation = await mcp.validateParameters('CREATE_CALENDAR', params);
```

## Modificar Schemas

### Añadir una nueva operación

1. Edita `eventypop_mcp/schemas/operations.yaml`:

```yaml
operations:
  MY_NEW_OPERATION:
    description: Mi nueva operación
    endpoint:
      method: POST
      path: /api/v1/my_endpoint
    fields:
      my_field:
        type: string
        required: true
        questions:
          es: "¿Cuál es el valor?"
```

2. **No necesitas recompilar** - El MCP lee el archivo al vuelo

3. Úsalo inmediatamente desde Flutter:

```dart
final schema = await mcp.getOperationSchema('MY_NEW_OPERATION');
```

### Añadir sugerencias de workflow

Edita `eventypop_mcp/schemas/workflows.yaml`:

```yaml
workflows:
  MY_NEW_OPERATION:
    suggestions:
      - action: ANOTHER_ACTION
        priority: high
        questions:
          es: "¿Quieres hacer X?"
        default_parameters:
          some_id: "{result.id}"
```

## Monitoreo y Debugging

### Ver logs del MCP Server

```bash
docker logs -f agenda_phoenix_mcp
```

### Verificar que el MCP está corriendo

```bash
docker ps | grep mcp
```

```
CONTAINER ID   IMAGE                    COMMAND             STATUS
abc123def456   eventypop_mcp:latest    "python server.py"  Up 2 minutes
```

### Probar el MCP manualmente

```bash
# Ejecutar comando dentro del contenedor
docker exec -it agenda_phoenix_mcp python -c "
import yaml
with open('schemas/operations.yaml') as f:
    ops = yaml.safe_load(f)
    print(list(ops['operations'].keys()))
"
```

### Reiniciar solo el MCP

```bash
docker compose restart mcp
```

## Solución de Problemas

### El MCP no arranca

```bash
# Ver logs detallados
docker logs agenda_phoenix_mcp

# Verificar que el Dockerfile es correcto
docker compose build mcp

# Reiniciar todo
./start.sh stop
./start.sh
```

### Flutter no se conecta al MCP

```dart
// El cliente intenta Docker primero, luego local
// Ver logs en Flutter:
DebugConfig.info('...', tag: 'MCP');
```

### Cambios en schemas no se reflejan

```bash
# Los schemas están en volumen read-only
# Verifica que el archivo local cambió:
cat eventypop_mcp/schemas/operations.yaml | grep MY_OPERATION

# Reinicia el MCP si es necesario
docker compose restart mcp
```

## Próximos Pasos

Ahora que el MCP está integrado, puedes:

1. **Refactorizar voice services** para usar el MCP en lugar de hardcoded fields
2. **Añadir más operaciones** al schema (eventos recurrentes, grupos, etc.)
3. **Implementar workflows complejos** con múltiples acciones encadenadas
4. **Añadir más idiomas** (catalán, francés, etc.)
5. **Generar schemas automáticamente** desde el backend FastAPI

## Estructura de Archivos

```
agenda_phoenix/
├── eventypop_mcp/                    ← Proyecto MCP Server
│   ├── server.py                     ← Servidor MCP (Python)
│   ├── Dockerfile                    ← Imagen Docker
│   ├── requirements.txt              ← Dependencias
│   ├── schemas/
│   │   ├── operations.yaml           ← 20+ operaciones
│   │   └── workflows.yaml            ← Sugerencias
│   └── README.md                     ← Documentación MCP
│
├── app_flutter/
│   └── lib/services/mcp/
│       └── mcp_client.dart           ← Cliente MCP para Flutter
│
├── docker-compose.yml                ← MCP como servicio
├── start.sh                          ← Arranque coordinado
└── INTEGRATION.md                    ← Este archivo
```

---

**Sistema MCP completamente operativo** ✅

Todo está listo para usar. Ejecuta `./start.sh` y el MCP estará disponible automáticamente.
