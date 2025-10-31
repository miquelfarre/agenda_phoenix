# 📅 Especificación: Gestión de Calendarios

## 📋 Resumen

Esta especificación define el comportamiento de la pantalla "Calendarios" (anteriormente "Comunidades"), que permite a los usuarios gestionar sus calendarios privados y descubrir/suscribirse a calendarios públicos compartibles.

---

## 🎯 Los 3 Tipos de Calendarios

### **Tipo 1: Calendario PRIVADO de Usuario PRIVADO**

```yaml
Propiedades:
  - is_public: false
  - owner.is_public: false
  - share_hash: NULL
  - Acceso: Solo por invitación o joined admin

Ejemplos:
  - "Family" de Sonia
  - "Cumpleaños Family" de Sonia
  - "Temporada Esquí 2025-2026" de Sonia

Comportamiento:
  ✅ Listado: SÍ aparece automáticamente en la lista
  ✅ Buscador: SÍ se puede filtrar por nombre
  ✅ Suscripción: NO (solo membresía por invitación)
```

### **Tipo 2: Calendario PÚBLICO de Usuario PRIVADO**

```yaml
Propiedades:
  - is_public: true
  - owner.is_public: false
  - share_hash: "K3OrG1rB" (8 caracteres, base62)
  - Acceso: Suscripción pública via share_hash

Ejemplos:
  - "Festivos Barcelona 2025-2026" de Sara (share_hash: K3OrG1rB)

Comportamiento:
  ❌ Listado: NO aparece automáticamente en la lista
  ✅ Buscador: SÍ se puede buscar por share_hash (#K3OrG1rB)
  ✅ Suscripción: POST /calendars/{share_hash}/subscribe
```

### **Tipo 3: Calendario PÚBLICO de Usuario PÚBLICO**

```yaml
Propiedades:
  - is_public: true
  - owner.is_public: true
  - share_hash: NULL
  - Acceso: Suscripción al usuario público

Ejemplos:
  - "Partidos FC Barcelona" de fcbarcelona
  - "Clases FitZone" de fitzone_bcn
  - "Eventos Restaurante Sabor" de elbuen_sabor
  - "Programación Llotja" de llotja_cultural

Comportamiento:
  ❌ Listado: NO aparece en esta pantalla
  ❌ Buscador: NO se busca en esta pantalla (ignorado)
  ✅ Ubicación: Se manejan en pantalla de "Usuarios Públicos"
  ✅ Suscripción: Via suscripción al usuario público
```

---

## 🖥️ Pantalla "Calendarios"

### Cambios de Nombre

| Antes | Después |
|-------|---------|
| "Comunidades" | "Calendarios" |

**Actualizar i18n**:
- Español: "Calendarios"
- Inglés: "Calendars"

### Diseño Visual

- ❌ **Sin distinción de colores** entre calendarios
- ✅ **Mismo formato UX** que otras listas (eventos, contactos, etc.)
- ✅ **Interacciones contextuales** según rol del usuario

---

## 🔍 Buscador Dual

### Sintaxis de Búsqueda

```
#K3OrG1rB     → Busca calendario público por share_hash (Tipo 2)
Festivos      → Filtra calendarios existentes por nombre (Tipos 1 y 2)
cumpleaños    → Filtra calendarios existentes por nombre
```

### Placeholder del TextField

**i18n ES**: `"Buscar por nombre o #código"`
**i18n EN**: `"Search by name or #code"`

### Comportamiento Técnico

```dart
if (searchQuery.startsWith('#')) {
  // Búsqueda por share_hash (Tipo 2)
  final hash = searchQuery.substring(1); // Quita el #

  // Opción 1: Endpoint específico
  GET /calendars/search?hash={hash}

  // Opción 2: Endpoint existente
  GET /calendars/public?search={hash}

  // Si encuentra calendario:
  // - Mostrar resultado con botón "Suscribirse"
  // - Al suscribirse: POST /calendars/{share_hash}/subscribe

} else {
  // Filtrado local por nombre (Tipos 1 y 2)
  calendars.where((cal) =>
    cal.name.toLowerCase().contains(searchQuery.toLowerCase())
  )
}
```

### Textos de Ayuda

**i18n ES**: `"Introduce el código de 8 caracteres precedido de #"`
**i18n EN**: `"Enter the 8-character code preceded by #"`

---

## 📊 Listado de Calendarios

### Qué se lista automáticamente

**Solo Tipo 1**: Calendarios privados de usuarios privados
- Los calendarios donde el usuario es owner, admin o member
- Obtenidos via: `GET /users/{user_id}/calendars`

### Qué NO se lista

- **Tipo 2**: Calendarios públicos de usuarios privados (buscar por #hash)
- **Tipo 3**: Calendarios públicos de usuarios públicos (pantalla aparte)

---

## 🎮 Interacciones por Rol

### Si el usuario es Owner o Admin

```yaml
Acciones disponibles:
  - ✏️ Editar calendario
  - 🗑️ Eliminar calendario
  - 👥 Gestionar miembros
  - ⚙️ Configuración
```

### Si el usuario es Member o Subscriber

```yaml
Acciones disponibles:
  - 🚪 Abandonar calendario
     - Tipo 1 (privado): Elimina membresía (DELETE /calendar_memberships/{id})
     - Tipo 2 (público): Cancela suscripción (DELETE /calendars/{share_hash}/subscribe)
```

---

## 🔗 Endpoints Backend Necesarios

### Endpoints Existentes ✅

```http
# Obtener calendarios del usuario (Tipo 1)
GET /users/{user_id}/calendars

# Suscribirse a calendario público por hash (Tipo 2)
POST /calendars/{share_hash}/subscribe

# Desuscribirse de calendario público (Tipo 2)
DELETE /calendars/{share_hash}/subscribe

# Obtener calendarios públicos (con filtros)
GET /calendars/public?category={cat}&search={text}
```

### Endpoints a Crear/Verificar ⚠️

```http
# Buscar calendario específico por share_hash
GET /calendars/search?hash={hash}
# O reusar existente:
GET /calendars/public?search={hash}

# Verificar si usuario está suscrito a calendario
GET /calendars/{id}/subscription/status
```

---

## 📱 Flujos de Usuario

### Flujo 1: Ver mis calendarios privados

1. Usuario abre pantalla "Calendarios"
2. App carga: `GET /users/{user_id}/calendars`
3. Muestra lista de calendarios Tipo 1
4. Usuario puede filtrar por nombre en buscador

### Flujo 2: Buscar calendario público por código

1. Usuario escribe: `#K3OrG1rB`
2. App detecta `#` y extrae hash: `K3OrG1rB`
3. App consulta: `GET /calendars/search?hash=K3OrG1rB`
4. Si encuentra: Muestra calendario con botón "Suscribirse"
5. Usuario pulsa "Suscribirse"
6. App ejecuta: `POST /calendars/K3OrG1rB/subscribe`
7. Calendario se añade a la lista del usuario

### Flujo 3: Abandonar calendario

**Si es Tipo 1 (privado)**:
1. Usuario pulsa "Abandonar" en calendario privado
2. App confirma acción
3. App ejecuta: `DELETE /calendar_memberships/{membership_id}`
4. Calendario desaparece de la lista

**Si es Tipo 2 (público suscrito)**:
1. Usuario pulsa "Abandonar" en calendario público
2. App confirma acción
3. App ejecuta: `DELETE /calendars/{share_hash}/subscribe`
4. Calendario desaparece de la lista

---

## 🎨 Notas de Diseño

### Colores
- ❌ No usar colores distintivos para calendarios
- ✅ Usar mismo esquema que resto de listas

### Iconos Sugeridos
- 🔒 Calendario privado (Tipo 1)
- 🌐 Calendario público (Tipo 2)
- 👤 Owner/Admin
- 👥 Member/Subscriber

### Estados Visuales
- **Listado**: Calendarios Tipo 1
- **Resultado de búsqueda**: Calendario Tipo 2 encontrado
- **Vacío**: "No tienes calendarios. Busca por #código para suscribirte."

---

## ✅ Checklist de Implementación

### Backend
- [x] Modelo Calendar con is_public, share_hash, category, subscriber_count
- [x] Endpoint POST /calendars/{share_hash}/subscribe
- [x] Endpoint DELETE /calendars/{share_hash}/subscribe
- [x] Trigger para actualizar subscriber_count
- [ ] Endpoint GET /calendars/search?hash={hash} (o reusar /calendars/public)
- [ ] Tests funcionales de búsqueda por hash

### Frontend (Flutter)
- [ ] Actualizar textos i18n (ES/EN)
- [ ] Renombrar pestaña "Comunidades" → "Calendarios"
- [ ] Implementar buscador con detección de #hash
- [ ] Implementar lista unificada de calendarios (Tipo 1)
- [ ] Implementar resultado de búsqueda (Tipo 2)
- [ ] Implementar botón "Suscribirse" para Tipo 2
- [ ] Implementar botón "Abandonar" contextual
- [ ] Actualizar modelos Calendar y CalendarHive
- [ ] Tests de integración

---

## 📚 Referencias

- **Archivo de datos**: `/backend/datos.txt` (líneas 31-43)
- **Modelos backend**: `/backend/models.py` (Calendar model)
- **Schemas backend**: `/backend/schemas.py` (CalendarResponse)
- **Router backend**: `/backend/routers/calendars.py`
- **Tests funcionales**: `/backend/func_tests/test_calendar_subscriptions.py`
- **Tests realtime**: `/backend/func_tests/realtime_tests/test_realtime_calendar_subscriptions.py`
- **Modelos Flutter**: `/app_flutter/lib/models/calendar.dart`
- **Modelos Hive**: `/app_flutter/lib/models/calendar_hive.dart`

---

## 🔧 Configuración Actual

### Calendarios de Ejemplo en BD

**Tipo 1 (Privados)**:
- "Family" (Sonia)
- "Cumpleaños Family" (Sonia)
- "Temporada Esquí 2025-2026" (Sonia)

**Tipo 2 (Públicos de usuario privado)**:
- "Festivos Barcelona 2025-2026" (Sara) - share_hash: `K3OrG1rB`
- 29 eventos (15 festivos 2025 + 14 festivos 2026)

**Tipo 3 (Públicos de usuario público)**:
- "Partidos FC Barcelona" (fcbarcelona)
- "Clases FitZone" (fitzone_bcn)
- "Eventos Restaurante Sabor" (elbuen_sabor)
- "Programación Llotja" (llotja_cultural)

---

**Última actualización**: 31 de octubre de 2025
**Versión**: 1.0
