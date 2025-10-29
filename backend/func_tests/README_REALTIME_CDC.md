# Tests de Realtime/CDC

## 📋 Descripción

Estos tests verifican que la arquitectura **Change Data Capture (CDC)** funciona correctamente end-to-end:

1. **API call** crea/modifica datos en PostgreSQL
2. **Triggers** actualizan automáticamente `user_subscription_stats`
3. **Realtime** puede detectar cambios (verificado indirectamente vía stats actualizadas)

## 🎯 Objetivo

Demostrar que el flujo completo funciona:
```
API POST /events → PostgreSQL INSERT → Trigger actualiza stats → Realtime emite CDC event
```

## ✅ Tests Implementados (7 tests)

| Test | Descripción | Verifica |
|------|-------------|----------|
| `test_create_event_updates_stats_via_trigger` | Crear evento incrementa `total_events_count` | ✅ Trigger INSERT funciona |
| `test_delete_event_decrements_stats_via_trigger` | Eliminar evento decrementa `total_events_count` | ✅ Trigger DELETE funciona |
| `test_subscription_increments_subscribers_count` | Suscribirse incrementa `subscribers_count` del owner | ✅ Trigger subscription funciona |
| `test_unsubscription_decrements_subscribers_count` | Desuscribirse decrementa `subscribers_count` | ✅ Trigger unsubscription funciona |
| `test_new_events_count_tracks_recent_events` | Contador de eventos recientes (< 7 días) | ✅ Lógica de conteo funciona |
| `test_stats_table_has_correct_structure` | Verificar estructura de tabla | ✅ Tabla tiene columnas correctas y REPLICA IDENTITY |
| `test_triggers_exist_on_events_and_interactions` | Verificar que los 4 triggers existen | ✅ Triggers creados correctamente |

## 🚀 Cómo Ejecutar

### Prerequisitos

1. **Backend corriendo**:
   ```bash
   ./start.sh backend
   ```

2. **PostgreSQL accesible** en `localhost:5432`

### Ejecutar Todos los Tests

```bash
cd backend
pytest func_tests/test_realtime_cdc.py -v
```

**Resultado esperado**: `7 passed`

### Ejecutar Test Específico

```bash
# Test individual
pytest func_tests/test_realtime_cdc.py::TestRealtimeCDC::test_create_event_updates_stats_via_trigger -v

# Solo tests de estructura (rápidos)
pytest func_tests/test_realtime_cdc.py -k "structure or triggers" -v
```

## 🔧 Configuración

Los tests usan estas variables de entorno (con defaults):

```bash
export DB_HOST=localhost
export DB_PORT=5432
export POSTGRES_DB=postgres
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=yoursupersecretandlongpostgrespassword
```

## 📊 Qué Verifican Estos Tests

### 1. Triggers Funcionan Automáticamente
```python
# ANTES: total_events_count = 10
api_request("POST", "/events", data={...})
# DESPUÉS: total_events_count = 11  ← Actualizado por trigger
```

### 2. Datos Correctos en Stats
```python
stats = get_user_stats(user_id=1)
assert stats['total_events_count'] == expected
assert stats['subscribers_count'] == expected
```

### 3. Infraestructura CDC Lista
```python
# Verifica REPLICA IDENTITY FULL
# Verifica triggers existen en tablas correctas
# Verifica estructura de tabla
```

## 🆚 Diferencia con `test_snapshots.py`

| Aspecto | `test_snapshots.py` | `test_realtime_cdc.py` |
|---------|---------------------|------------------------|
| **BD** | SQLite (in-memory) | PostgreSQL (real) |
| **Objetivo** | Validar responses de API | Validar triggers CDC + Realtime |
| **Scope** | Endpoints individuales | Flujo end-to-end |
| **Triggers** | ❌ No se ejecutan | ✅ Se ejecutan |
| **Realtime** | ❌ No disponible | ✅ Verificado indirectamente |

## 🐛 Troubleshooting

### Error: `password authentication failed`
```bash
# Verifica password correcta
docker exec agenda_phoenix_backend env | grep POSTGRES_PASSWORD

# Actualiza en test_realtime_cdc.py línea 28
```

### Error: `connection refused`
```bash
# Verifica backend corriendo
docker ps | grep agenda_phoenix_backend

# Verifica PostgreSQL
nc -z localhost 5432
```

### Tests fallan con `assert` error
```bash
# Ver detalles completos
pytest func_tests/test_realtime_cdc.py -v --tb=long

# Ver stats manualmente
docker exec agenda_phoenix_db psql -U postgres -d postgres \
  -c "SELECT * FROM user_subscription_stats WHERE user_id = 1;"
```

## 📈 Cobertura

Estos tests cubren:
- ✅ 4 triggers de `user_subscription_stats`
- ✅ Endpoints POST/DELETE de events
- ✅ Endpoints POST/DELETE de interactions
- ✅ Estructura de tabla optimizada para Realtime
- ✅ Contadores incrementales/decrementales

## 🔮 Próximos Pasos

Para testing completo de Realtime en Flutter:
1. ✅ **Backend** (este archivo) - Triggers funcionan
2. ⏭️ **Integration Tests Flutter** - Verificar Hive se actualiza
3. ⏭️ **E2E Tests** - Verificar latencia < 2 segundos

## 📝 Notas

- Los tests hacen **cleanup automático** (eliminan datos creados)
- Son **idempotentes** (se pueden ejecutar múltiples veces)
- No requieren **datos específicos** en BD (funcionan con cualquier estado inicial)
- Verifican **comportamiento real** (no mocks)
