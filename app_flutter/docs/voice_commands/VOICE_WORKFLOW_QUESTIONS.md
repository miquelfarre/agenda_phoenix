# Sistema de Preguntas Inteligentes - Voice Workflow

## Filosofía del Sistema

El sistema debe ser **conversacional e inteligente**, no solo un formulario por voz. Debe:
1. **Anticipar necesidades**: Sugerir acciones relacionadas
2. **Ser contextual**: Usar información ya disponible
3. **Ser eficiente**: No preguntar lo obvio
4. **Ser flexible**: Aceptar respuestas en lenguaje natural

---

## Flujo: CREATE_CALENDAR

### Campos Obligatorios
1. **name** (string)
   - Pregunta: "¿Qué nombre quieres para el calendario?"
   - Ejemplos: "Personal", "Trabajo", "Familia", "Festivos Barcelona 2025"

### Campos Opcionales (solo si el usuario lo menciona)
2. **description** (text)
   - Pregunta: "¿Quieres añadir una descripción?"
   - Ejemplos: "Eventos de trabajo y reuniones", "Cumpleaños familiares"

3. **category** (string)
   - Pregunta: "¿De qué tipo es el calendario?"
   - Opciones: "holidays", "sports", "cultural", "work", "personal", "academic"
   - Ejemplos: "festivos", "deportes", "cultural"

4. **is_public** (boolean)
   - Pregunta: "¿Quieres que sea público o privado?"
   - Default: false (privado)

5. **start_date** / **end_date** (timestamp)
   - Para calendarios temporales
   - Pregunta: "¿Este calendario tiene una duración específica?"
   - Ejemplos: "Sí, del 1 de enero al 30 de junio de 2025"

### Acciones Sugeridas DESPUÉS de Crear Calendario

#### 1. **Hacer Público (UPDATE_CALENDAR)**
- **Pregunta:** "¿Quieres que el calendario sea público para que otros puedan suscribirse?"
- **Cuándo preguntar:** Si is_public=false
- **Parámetros:**
  - `calendar_id`: Auto (del resultado anterior)
  - `is_public`: true
  - `is_discoverable`: true (opcional)

#### 2. **Categorizar (UPDATE_CALENDAR)**
- **Pregunta:** "¿Quieres categorizar el calendario? (festivos, deportes, cultural, etc.)"
- **Cuándo preguntar:** Si category=null y is_public=true
- **Parámetros:**
  - `calendar_id`: Auto
  - `category`: "holidays", "sports", "cultural", etc.

#### 3. **Compartir con Usuario (CREATE_CALENDAR_MEMBERSHIP)**
- **Pregunta:** "¿Quieres compartir el calendario con alguien?"
- **Cuándo preguntar:** Siempre
- **Campos obligatorios:**
  - `calendar_id`: Auto
  - `user_email`: "¿Con quién quieres compartirlo? (email)"
  - `role`: "member" (default) o "admin"

- **Subpreguntas:**
  - "¿Quieres que sea miembro o administrador?"
  - Respuestas: "miembro" → role=member, "admin" → role=admin

#### 4. **Hacer Admin a Alguien (CREATE_CALENDAR_MEMBERSHIP con role=admin)**
- **Pregunta:** "¿Quieres hacer a alguien administrador del calendario?"
- **Cuándo preguntar:** Si el usuario mencionó "admin" o "administrador"
- **Campos obligatorios:**
  - `calendar_id`: Auto
  - `user_email`: "¿A quién quieres hacer admin? (email)"
  - `role`: "admin"

#### 5. **Crear Evento en el Calendario (CREATE_EVENT)**
- **Pregunta:** "¿Quieres crear un evento en este calendario?"
- **Cuándo preguntar:** Siempre (muy común)
- **Campos obligatorios:**
  - `calendar_id`: Auto
  - `title`: "¿Cuál es el nombre del evento?"
  - `start_datetime`: "¿Cuándo empieza?"

- **Campos opcionales:**
  - `end_datetime`: "¿Cuándo termina?"
  - `description`: "¿Quieres añadir una descripción?"
  - `location`: "¿Dónde será?"

#### 6. **Generar Link de Compartir (UPDATE_CALENDAR)**
- **Pregunta:** "¿Quieres generar un link para compartir el calendario fácilmente?"
- **Cuándo preguntar:** Si share_hash=null
- **Parámetros:**
  - `calendar_id`: Auto
  - `share_hash`: Generado automáticamente (8 caracteres)

---

## Flujo: CREATE_EVENT

### Campos Obligatorios
1. **title** (string)
   - Pregunta: "¿Cuál es el nombre del evento?"

2. **start_datetime** (timestamp)
   - Pregunta: "¿Cuándo empieza el evento?"
   - Ejemplos: "mañana a las 3", "el 15 de enero a las 10", "hoy a las 18:00"

### Campos Opcionales
3. **end_datetime** (timestamp)
   - Pregunta: "¿Cuándo termina el evento?"
   - Si no se especifica: Se asume 1 hora después del inicio

4. **calendar_id** (int)
   - Pregunta: "¿En qué calendario quieres crear el evento?"
   - Si solo tiene 1 calendario: No preguntar, usar ese
   - Si tiene múltiples: Listar opciones

5. **description** (text)
   - Pregunta: "¿Quieres añadir una descripción?"

6. **location** (string)
   - Pregunta: "¿Dónde será el evento?"

7. **event_type** (string: "regular" | "recurring")
   - Pregunta: "¿Es un evento único o recurrente?"
   - Default: "regular"

### Si event_type = "recurring"

8. **recurrence_type** (string)
   - Pregunta: "¿Con qué frecuencia se repite?"
   - Opciones: "daily", "weekly", "monthly", "yearly"
   - Ejemplos: "cada día", "cada semana", "cada mes", "cada año"

9. **recurrence_schedule** (JSON)
   - **Para weekly:**
     - Pregunta: "¿Qué días de la semana?"
     - Ejemplo: "lunes, miércoles y viernes" → {"days": [1, 3, 5]}

   - **Para monthly:**
     - Pregunta: "¿Qué día del mes?"
     - Ejemplo: "el día 15" → {"day": 15}
     - Ejemplo: "el último día" → {"day": "last"}

   - **Para yearly:**
     - Pregunta: "¿Qué fecha?"
     - Ejemplo: "25 de diciembre" → {"month": 12, "day": 25}

10. **recurrence_end_date** (timestamp)
    - Pregunta: "¿Hasta cuándo se repite?"
    - Ejemplo: "hasta el 31 de diciembre"
    - Si no se especifica: null (perpetuo)

### Acciones Sugeridas DESPUÉS de Crear Evento

#### 1. **Invitar Usuario (CREATE_EVENT_INTERACTION)**
- **Pregunta:** "¿Quieres invitar a alguien a este evento?"
- **Cuándo preguntar:** Siempre
- **Campos obligatorios:**
  - `event_id`: Auto
  - `user_email`: "¿A quién quieres invitar? (email)"
  - `interaction_type`: "invited"
  - `role`: null (default member) o "admin"

#### 2. **Añadir Nota Personal (CREATE_EVENT_INTERACTION con note)**
- **Pregunta:** "¿Quieres añadir una nota personal sobre este evento?"
- **Cuándo preguntar:** Rara vez (solo si usuario lo menciona)
- **Campos:**
  - `event_id`: Auto
  - `note`: "¿Qué quieres apuntar?"

#### 3. **Hacer Evento Público (UPDATE_EVENT)**
- **Pregunta:** "¿Quieres que el evento sea público?"
- **Cuándo preguntar:** Si el calendario es público
- **Parámetros:**
  - `event_id`: Auto
  - `is_public`: true

#### 4. **Crear Otro Evento en el Mismo Calendario**
- **Pregunta:** "¿Quieres crear otro evento en este calendario?"
- **Cuándo preguntar:** Si se creó en un calendario específico
- **Parámetros:**
  - `calendar_id`: Auto (mismo calendario)

---

## Flujo: COMPARTIR CALENDARIO (Memberships)

### Acción: INVITE_TO_CALENDAR

#### Campos Obligatorios
1. **calendar_id** (int)
   - Pregunta: "¿Qué calendario quieres compartir?"
   - Si se viene del flujo de CREATE_CALENDAR: Auto

2. **user_email** (string)
   - Pregunta: "¿Con quién quieres compartir el calendario? (email)"
   - Validación: Email válido

3. **role** (string: "member" | "admin")
   - Pregunta: "¿Quieres que sea miembro o administrador?"
   - Default: "member"
   - Opciones:
     - "miembro" / "member" → role=member
     - "admin" / "administrador" → role=admin

#### Subpreguntas según rol:

**Si role = "admin":**
- Confirmar: "Los administradores pueden editar el calendario e invitar a otros. ¿Confirmas?"

**Si role = "member":**
- (Sin confirmación adicional)

### Acciones Sugeridas DESPUÉS de Invitar

#### 1. **Invitar a Más Usuarios**
- **Pregunta:** "¿Quieres invitar a alguien más?"
- **Parámetros:**
  - `calendar_id`: Auto (mismo calendario)

#### 2. **Cambiar Rol de Usuario Existente (UPDATE_MEMBERSHIP)**
- **Pregunta:** "¿Quieres cambiar el rol de algún miembro?"
- **Cuándo:** Solo si ya hay miembros
- **Campos:**
  - `membership_id`: Auto
  - `role`: "member" / "admin"

---

## Flujo: SUSCRIBIRSE A CALENDARIO PÚBLICO

### Acción: SUBSCRIBE_TO_CALENDAR

#### Campos Obligatorios
1. **calendar_id** (int)
   - Pregunta: "¿A qué calendario quieres suscribirte?"
   - Alternativa: Buscar por nombre o categoría
     - "¿Qué calendario buscas?" → Buscar en calendarios públicos

#### Búsqueda Inteligente:
```
Usuario: "Quiero suscribirme a calendarios de festivos"
Sistema: [Busca calendarios con category="holidays" y is_public=true]
Sistema: "He encontrado 3 calendarios de festivos:"
  1. Festivos Barcelona 2025 (324 suscriptores)
  2. Festivos España 2025 (1.2k suscriptores)
  3. Festivos Cataluña 2025 (856 suscriptores)
Sistema: "¿A cuál quieres suscribirte?"
Usuario: "El primero"
Sistema: ✅ Suscrito a "Festivos Barcelona 2025"
```

### Acciones Sugeridas DESPUÉS de Suscribirse

#### 1. **Pausar Suscripción (UPDATE_SUBSCRIPTION)**
- **Pregunta:** "¿Quieres pausar las notificaciones de este calendario?"
- **Cuándo:** Solo si el usuario lo menciona
- **Parámetros:**
  - `subscription_id`: Auto
  - `status`: "paused"

---

## Flujo: INVITAR A EVENTO

### Acción: INVITE_USER_TO_EVENT

#### Campos Obligatorios
1. **event_id** (int)
   - Pregunta: "¿A qué evento quieres invitar?"
   - Si viene del flujo CREATE_EVENT: Auto

2. **user_email** (string)
   - Pregunta: "¿A quién quieres invitar? (email)"

#### Campos Opcionales
3. **role** (string: null | "admin")
   - Pregunta: "¿Quieres que sea organizador del evento?"
   - Default: null (miembro normal)

4. **note** (text)
   - Pregunta: "¿Quieres incluir un mensaje personal en la invitación?"
   - Ejemplo: "Por favor confirma asistencia"

### Acciones Sugeridas DESPUÉS de Invitar

#### 1. **Invitar a Más Usuarios**
- **Pregunta:** "¿Quieres invitar a alguien más?"
- **Parámetros:**
  - `event_id`: Auto (mismo evento)

#### 2. **Invitar Vía Grupo (CREATE_EVENT_INTERACTION con group_id)**
- **Pregunta:** "¿Quieres invitar a un grupo completo?"
- **Cuándo:** Si el usuario tiene grupos creados
- **Campos:**
  - `event_id`: Auto
  - `group_id`: "¿Qué grupo quieres invitar?"

---

## Flujo: EVENTOS RECURRENTES

### Configuración Avanzada de Recurrencia

#### Para recurrence_type = "weekly"
```json
{
  "days": [1, 3, 5],  // Lunes, Miércoles, Viernes
  "interval": 1        // Cada semana (2 = cada 2 semanas)
}
```

**Preguntas:**
1. "¿Qué días de la semana?" → "lunes, miércoles y viernes"
2. "¿Cada cuántas semanas?" → "cada semana" (default 1)

#### Para recurrence_type = "monthly"
```json
{
  "day": 15,           // Día 15 de cada mes
  "interval": 1        // Cada mes (3 = cada 3 meses)
}
```

**Preguntas:**
1. "¿Qué día del mes?" → "el 15" o "el último día"
2. "¿Cada cuántos meses?" → "cada mes" (default 1)

#### Para recurrence_type = "yearly"
```json
{
  "month": 12,         // Diciembre
  "day": 25,           // Día 25
  "interval": 1        // Cada año
}
```

**Preguntas:**
1. "¿Qué fecha?" → "25 de diciembre"

---

## Preguntas Contextuales Inteligentes

### Contexto: Usuario tiene múltiples calendarios

**Crear Evento:**
```
Usuario: "crear evento reunión mañana a las 3"
Sistema: "Tienes 3 calendarios: Personal, Trabajo, Familia. ¿En cuál quieres crear el evento?"
Usuario: "trabajo"
Sistema: ✅ Evento creado en calendario "Trabajo"
```

### Contexto: Calendario sin eventos

**Después de crear calendario:**
```
Sistema: "Has creado el calendario 'Proyecto X'. ¿Quieres crear un evento inicial?"
Usuario: "sí, reunión de kickoff el lunes a las 10"
Sistema: ✅ Evento "Reunión de kickoff" creado
```

### Contexto: Usuario mencionó "público" en el comando original

**Crear Calendario:**
```
Usuario: "crear un calendario público de festivos de Barcelona"
Sistema: [Detecta is_public=true, category="holidays", name="Festivos de Barcelona"]
Sistema: "¿Quieres hacerlo descubrible para que otros lo encuentren?"
Usuario: "sí"
Sistema: ✅ Calendario público creado (is_discoverable=true)
```

### Contexto: Calendario público sin categoría

**Después de hacer calendario público:**
```
Sistema: "¿De qué tipo es el calendario para que otros puedan encontrarlo?"
Opciones: festivos, deportes, cultural, académico, etc.
Usuario: "festivos"
Sistema: ✅ Categoría actualizada
```

---

## Priorización de Preguntas

### Después de CREATE_CALENDAR (orden de prioridad):

1. **ALTA PRIORIDAD** (preguntar siempre si tiene sentido):
   - ¿Quieres crear un evento? (muy común)
   - ¿Quieres compartirlo con alguien? (común en calendarios colaborativos)

2. **MEDIA PRIORIDAD** (preguntar si el contexto lo sugiere):
   - ¿Quieres hacerlo público? (solo si is_public=false)
   - ¿Quieres categorizar? (solo si is_public=true y category=null)

3. **BAJA PRIORIDAD** (solo si usuario lo menciona):
   - ¿Quieres generar link de compartir?
   - ¿Quieres hacer a alguien administrador?

### Después de CREATE_EVENT (orden de prioridad):

1. **ALTA PRIORIDAD**:
   - ¿Quieres invitar a alguien? (muy común)

2. **MEDIA PRIORIDAD**:
   - ¿Quieres crear otro evento en este calendario? (si tiene calendario)

3. **BAJA PRIORIDAD**:
   - ¿Quieres añadir más detalles? (descripción, ubicación)
   - ¿Quieres añadir nota personal?

---

## Ejemplos de Flujos Completos

### Ejemplo 1: Calendario Personal Simple
```
Usuario: "crear calendario"
Sistema: "¿Qué nombre quieres para el calendario?"
Usuario: "Personal"
Sistema: ✅ Calendario "Personal" creado
Sistema: "¿Quieres crear un evento en este calendario?"
Usuario: "no, gracias"
Sistema: ✅ Listo
```

### Ejemplo 2: Calendario Público de Festivos
```
Usuario: "crear un calendario público de festivos de Barcelona 2025"
Sistema: [Detecta: name="Festivos Barcelona 2025", is_public=true, category="holidays"]
Sistema: ✅ Calendario público creado
Sistema: "¿Quieres crear un evento inicial? Por ejemplo, el primer festivo del año"
Usuario: "sí, año nuevo el 1 de enero"
Sistema: ✅ Evento "Año Nuevo" creado (01/01/2025)
Sistema: "¿Quieres añadir más festivos?"
Usuario: "no, los añadiré luego"
Sistema: ✅ Listo. Tu calendario ya está publicado y otros pueden suscribirse.
```

### Ejemplo 3: Calendario Colaborativo de Trabajo
```
Usuario: "crear calendario de equipo de desarrollo"
Sistema: "¿Qué nombre quieres para el calendario?"
Usuario: "Equipo Dev"
Sistema: ✅ Calendario "Equipo Dev" creado
Sistema: "¿Quieres compartir el calendario con alguien?"
Usuario: "sí, con juan@empresa.com y maria@empresa.com como admins"
Sistema: "¿Quieres que Juan sea miembro o administrador?"
Usuario: "admin"
Sistema: ✅ Juan invitado como admin
Sistema: "¿Y María?"
Usuario: "también admin"
Sistema: ✅ María invitada como admin
Sistema: "¿Quieres crear un evento en este calendario?"
Usuario: "sí, reunión semanal cada lunes a las 10"
Sistema: "¿Hasta cuándo se repite?"
Usuario: "indefinidamente"
Sistema: ✅ Evento recurrente creado
Sistema: "¿Quieres invitar al equipo a la reunión?"
Usuario: "sí"
Sistema: [Ya tiene a Juan y María como miembros del calendario, los invita automáticamente]
Sistema: ✅ Listo. Calendario compartido con reunión semanal configurada.
```

### Ejemplo 4: Suscripción a Calendario Público
```
Usuario: "quiero ver los festivos de Barcelona"
Sistema: [Busca calendarios públicos con "festivos" y "barcelona"]
Sistema: "He encontrado: 'Festivos Barcelona 2025' (324 suscriptores). ¿Quieres suscribirte?"
Usuario: "sí"
Sistema: ✅ Suscrito. Ahora verás todos los festivos de Barcelona en tu calendario.
```

---

## Casos Especiales

### Usuario cancela durante el flujo
```
Usuario: "cancelar" / "déjalo" / "olvídalo"
Sistema: "¿Seguro que quieres cancelar?"
Usuario: "sí"
Sistema: ✅ Operación cancelada
```

### Usuario dice "no sé" o no entiende
```
Usuario: "no sé"
Sistema: "No pasa nada. ¿Prefieres configurar esto más tarde?"
Usuario: "sí"
Sistema: ✅ [Guarda lo que se ha hecho hasta ahora y finaliza]
```

### Usuario quiere editar algo ya creado
```
Durante el flujo:
Usuario: "espera, el nombre debería ser otro"
Sistema: "¿Qué nombre prefieres?"
Usuario: "Calendario Familiar"
Sistema: ✅ Nombre actualizado a "Calendario Familiar"
```

---

## Resumen de Todas las Acciones Posibles

### Calendarios
1. `CREATE_CALENDAR` - Crear calendario
2. `UPDATE_CALENDAR` - Actualizar calendario (hacerlo público, categorizar, generar share_hash)
3. `DELETE_CALENDAR` - Eliminar calendario (con opción delete_events)
4. `LIST_CALENDARS` - Listar calendarios del usuario
5. `SEARCH_PUBLIC_CALENDARS` - Buscar calendarios públicos

### Membresías (Calendarios Privados)
6. `CREATE_CALENDAR_MEMBERSHIP` - Invitar usuario a calendario
7. `UPDATE_MEMBERSHIP` - Cambiar rol (member ↔ admin)
8. `ACCEPT_MEMBERSHIP` - Aceptar invitación
9. `REJECT_MEMBERSHIP` - Rechazar invitación
10. `DELETE_MEMBERSHIP` - Eliminar miembro

### Suscripciones (Calendarios Públicos)
11. `SUBSCRIBE_TO_CALENDAR` - Suscribirse a calendario público
12. `UNSUBSCRIBE_FROM_CALENDAR` - Desuscribirse
13. `PAUSE_SUBSCRIPTION` - Pausar notificaciones
14. `RESUME_SUBSCRIPTION` - Reanudar notificaciones

### Eventos
15. `CREATE_EVENT` - Crear evento
16. `UPDATE_EVENT` - Actualizar evento
17. `DELETE_EVENT` - Eliminar evento
18. `LIST_EVENTS` - Listar eventos (filtros: calendario, fechas, etc.)

### Eventos Recurrentes
19. `CREATE_RECURRING_EVENT` - Crear evento recurrente
20. `UPDATE_RECURRING_CONFIG` - Actualizar configuración de recurrencia
21. `DELETE_RECURRING_SERIES` - Eliminar serie completa

### Invitaciones a Eventos
22. `INVITE_USER_TO_EVENT` - Invitar usuario a evento
23. `ACCEPT_EVENT_INVITATION` - Aceptar invitación
24. `REJECT_EVENT_INVITATION` - Rechazar invitación
25. `UPDATE_EVENT_INTERACTION` - Actualizar nota, asistencia, etc.

### Grupos (para invitaciones masivas)
26. `INVITE_GROUP_TO_EVENT` - Invitar grupo completo a evento
27. `INVITE_GROUP_TO_CALENDAR` - Invitar grupo a calendario

---

Esta documentación completa debería cubrir TODOS los casos de uso relacionados con calendarios en tu aplicación.
