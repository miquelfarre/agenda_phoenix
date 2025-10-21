# Guía Rápida: Tests Funcionales con Snapshots

## ¿Qué Archivos Necesito?

### Esenciales
```
func_tests/
├── conftest.py           # Configuración
├── test_snapshots.py     # El único test file que necesitas
└── events/create_event/
    ├── case1.json        # Input del test
    └── case1.snapshot.json  # Output esperado (auto-generado)
```

### Opcionales (puedes borrar)
```
- test_runner.py       # Alternativa más simple (no detecta todos los cambios)
- show_output.py       # Script para debugging
- README.md           # Documentación larga
- POC_SUMMARY.md     # Resumen de la POC
- OUTPUT_FILES.md    # Guía de .output.json
- SNAPSHOTS_GUIDE.md # Guía completa de snapshots
- *.output.json      # Ejemplos de documentación
```

## Comandos Básicos

### 1. Crear Snapshots (Primera Vez)
```bash
pytest func_tests/test_snapshots.py --update-snapshots
```

Resultado: Crea archivos `.snapshot.json` con el output real.

### 2. Ejecutar Tests
```bash
pytest func_tests/test_snapshots.py -v
```

Resultado: 
- ✅ Si output coincide con snapshot → PASS
- ❌ Si output cambió → FAIL (muestra diff)

### 3. Actualizar Snapshots (Después de Cambio Intencional)
```bash
pytest func_tests/test_snapshots.py --update-snapshots
```

## Añadir Nuevo Test

```bash
# 1. Crear JSON del caso
cat > func_tests/events/my_endpoint/case1.json << 'JSON'
{
  "name": "Test my endpoint",
  "setup": {"users": [{"id": 1, "name": "Test"}]},
  "request": {"method": "POST", "endpoint": "/my-endpoint", "body": {...}},
  "expected_response": {"status_code": 200}
}
JSON

# 2. Crear snapshot
pytest func_tests/test_snapshots.py --update-snapshots

# 3. Verificar que se creó
cat func_tests/events/my_endpoint/case1.snapshot.json

# 4. Ejecutar test
pytest func_tests/test_snapshots.py -v
```

## Archivos a Borrar (Si Quieres Simplificar)

```bash
cd /Users/miquelfarre/development/agenda_phoenix/backend/func_tests

# Borrar alternativa más simple (no detecta todos los cambios)
rm test_runner.py

# Borrar documentación (mantener solo esta guía rápida)
rm README.md POC_SUMMARY.md OUTPUT_FILES.md SNAPSHOTS_GUIDE.md

# Borrar script de debugging (opcional)
rm show_output.py

# Borrar ejemplos de documentación
rm events/create_event/*.output.json
```

## Resumen

**1 solo archivo de tests**: `test_snapshots.py`

**Comandos clave**:
- Crear: `pytest func_tests/test_snapshots.py --update-snapshots`
- Ejecutar: `pytest func_tests/test_snapshots.py -v`
- Actualizar: `pytest func_tests/test_snapshots.py --update-snapshots`

**Archivos por test**:
- `case1.json` → Lo que creas (input)
- `case1.snapshot.json` → Auto-generado (output esperado)

¡Eso es todo!
