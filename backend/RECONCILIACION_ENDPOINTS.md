# Reconciliación de Endpoints - Agenda Phoenix

**Fecha**: 2025-11-12
**Estado**: ✅ Actualizado

---

## Resumen Ejecutivo

| Sistema | Cantidad | Diferencia con Backend |
|---------|----------|------------------------|
| **Backend (FastAPI)** | 76 endpoints | - |
| **Flutter (api_client.dart)** | 52 métodos | -24 endpoints |
| **Testing (eventypop_api_testing)** | 63 archivos | -13 endpoints |

---

## Análisis

### 1. Backend tiene MÁS endpoints que Flutter (-24)

**Posibles razones:**
- Endpoints administrativos no usados en app móvil
- Endpoints legacy que Flutter ya no usa
- Funcionalidad nueva en backend pendiente de implementar en Flutter

### 2. Backend tiene MÁS endpoints que Testing (-13)

**Posibles razones:**
- Tests no cubren todos los endpoints (cobertura ~83%)
- Endpoints nuevos sin tests
- Endpoints deprecados que se quitaron de tests

### 3. Testing tiene MÁS archivos que Flutter (+11)

**Interpretación:**
- Testing es más exhaustivo que lo que Flutter usa
- Algunos endpoints están testeados pero no usados en la app

---

## Estado de Reconciliación

### ✅ Completado anteriormente (Nov 12 - Parte 1):
- Eliminados 26 métodos de api_client.dart
- Eliminados 27 métodos de api_client_contract.dart
- Eliminados 27 archivos de eventypop_api_testing
- Eliminados 4 endpoints inexistentes (app_bans)

### ✅ Cambios actuales:
- Backend actualizado con funcionalidad de calendarios
- Validación: usuarios públicos NO pueden crear calendarios
- Todos los tests pasando (74/74)

---

## Próximos Pasos Recomendados

### Opción A: Auditoría Detallada
1. Listar los 24 endpoints de backend que Flutter no usa
2. Decidir si son necesarios o deprecados
3. Implementar en Flutter o eliminar del backend

### Opción B: Status Quo
- Mantener diferencia actual
- Backend puede tener más endpoints que Flutter (normal en arquitectura API)
- Flutter solo implementa lo que necesita la UI

---

## Comandos para Re-análisis

```bash
# Contar endpoints backend
grep -r "@router\." backend/routers/ | wc -l

# Contar métodos Flutter
grep -c "Future<" app_flutter/lib/services/api_client.dart

# Contar tests
find eventypop_api_testing/lib/endpoints -type f -name "*.ts" | wc -l
```

---

## Notas

- **Backend**: 76 endpoints (incluye main.py con / y /health)
- **Flutter**: 52 métodos públicos (excluye métodos privados/helpers)
- **Testing**: 63 archivos .ts (un archivo por endpoint)
- Diferencias son normales en arquitectura de microservicios
- No todos los endpoints backend necesitan estar en la app móvil
