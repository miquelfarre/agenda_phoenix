# Formato de Tests Funcionales

## Nuevo Sistema (RECOMENDADO)

Usa `expected.body` con placeholders para campos dinámicos:

```json
{
  "description": "Create user successfully",
  "setup": {
    "users": [
      {"id": 1, "name": "Alice", "phone": "+34600000001", "is_public": false}
    ]
  },
  "request": {
    "method": "POST",
    "endpoint": "/users",
    "body": {
      "contact_id": 1,
      "auth_provider": "phone",
      "auth_id": "+34600000001",
      "is_public": false
    }
  },
  "expected": {
    "status_code": 201,
    "body": {
      "id": "{{ID}}",
      "contact_id": "{{ID}}",
      "username": null,
      "auth_provider": "phone",
      "auth_id": "+34600000001",
      "is_public": false,
      "profile_picture_url": null,
      "last_login": null,
      "created_at": "{{TIMESTAMP}}",
      "updated_at": "{{TIMESTAMP}}"
    }
  }
}
```

## Placeholders Disponibles

- `"{{ID}}"` - Para cualquier campo que termine en `_id` o sea `id`
- `"{{TIMESTAMP}}"` - Para cualquier campo que termine en `_at`

## Ventajas

✅ **Explícito** - El resultado esperado está en el archivo de test
✅ **Versionado** - Los cambios en expected se ven en git
✅ **Sin falsas pasadas** - No se puede hacer --update-snapshots para ocultar bugs
✅ **Detecta cambios** - Si añades un campo nuevo y no está en expected → FALLA

## Sistema Legacy (Snapshots)

Si NO hay `expected.body` en el JSON, usa snapshots automáticos (no recomendado):

```json
{
  "description": "Old format - uses .snapshot.json file",
  "request": {...},
  "expected": {
    "status_code": 200,
    "body_contains": ["some text"]
  }
}
```

**Problema**: `pytest --update-snapshots` acepta cualquier cambio sin validar.
