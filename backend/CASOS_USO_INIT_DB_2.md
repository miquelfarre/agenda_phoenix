# Casos de Uso - init_db_2.py
# Sistema de Datos de Prueba con 100 Usuarios

## Usuario por Defecto
**USER_ID=1: Sonia Martínez** (Usuario privado que inicia la aplicación por defecto)
- Teléfono: +34600000001
- Tipo: Usuario privado (private user)
- Role: Usuario normal (no admin)

---

## 1. ESTRUCTURA DE USUARIOS (100 usuarios)

### 1.1 Usuarios Privados (85 usuarios)
**Perfiles variados:**
- **Familia de Sonia (10 usuarios)**: ID 1-10
  - Sonia (1), Miquel (2), Ada (3), Sara (4)
  - Padres, tíos, primos (5-10)

- **Amigos Cercanos (20 usuarios)**: ID 11-30
  - Compañeros de trabajo
  - Amigos de la universidad
  - Vecinos del barrio

- **Conocidos y Contactos (30 usuarios)**: ID 31-60
  - Contactos laborales
  - Conocidos de eventos
  - Amigos de amigos

- **Usuarios Nuevos/Inactivos (25 usuarios)**: ID 61-85
  - Cuentas recientes sin mucha actividad
  - Usuarios con los que Sonia tiene poca interacción

### 1.2 Usuarios Públicos (15 usuarios): ID 86-100
**Organizaciones y creadores de contenido:**
- ID 86: **@fcbarcelona** - FC Barcelona (deportes)
- ID 87: **@teatrebarcelona** - Teatro Nacional de Catalunya (cultura)
- ID 88: **@fitzonegym** - Gimnasio FitZone (fitness)
- ID 89: **@saborcatalunya** - Restaurante El Buen Sabor (gastronomía)
- ID 90: **@museupicasso** - Museo Picasso Barcelona (cultura)
- ID 91: **@festivalmerce** - Festes de la Mercè (eventos)
- ID 92: **@greenpointbcn** - Green Point Yoga (wellness)
- ID 93: **@techbarcelona** - Barcelona Tech Hub (tecnología)
- ID 94: **@cinemaverdi** - Cines Verdi (entretenimiento)
- ID 95: **@labirreria** - La Birreria Craft Beer (ocio)
- ID 96: **@casabatllo** - Casa Batlló (turismo)
- ID 97: **@primaverasound** - Primavera Sound (música)
- ID 98: **@marketgoticbcn** - Mercat Gòtic (gastronomía)
- ID 99: **@escaladabcn** - Climbat Escalada (deportes)
- ID 100: **@librerialaie** - Libreria Laie (cultura)

---

## 2. CASOS DE USO - CONTACTOS

### 2.1 Contactos Registrados
**Sonia tiene en su teléfono:**
- 50 contactos registrados en la app (tienen user_id)
- 30 contactos NO registrados (solo phone_number)

**Casos específicos:**
- Miquel está en contactos de Sonia, Ada y Sara
- Ada está en contactos de Sonia, Miquel y 15 amigos más
- Contactos duplicados: "Papá" (Sonia) y "Pere" (otros) son la misma persona
- Contactos con múltiples números: Miquel tiene 2 números en los contactos de Sonia

### 2.2 Sincronización de Contactos
- 10 usuarios que Sonia tiene guardados pero que la bloquearon
- 5 usuarios que Sonia bloqueó pero aún están en sus contactos
- 8 contactos que cambiaron de número recientemente

---

## 3. CASOS DE USO - GRUPOS

### 3.1 Grupos Familiares
**Grupo "Familia Martínez"** (owner: Sonia, ID: 1)
- Miembros: Sonia, Miquel, Ada, Sara, padres, tíos
- Rol admin: Sonia y Miquel
- 10 miembros totales

**Grupo "Primos"** (owner: Ada, ID: 2)
- Miembros: todos los primos jóvenes
- 8 miembros

### 3.2 Grupos Sociales
**Grupo "Compis Trabajo"** (owner: Sonia, ID: 3)
- 15 compañeros del equipo
- 3 admins (Sonia, Laura, Carlos)

**Grupo "Universidad UPC"** (owner: Miquel, ID: 4)
- 25 antiguos compañeros
- Grupo con mucha actividad histórica

**Grupo "Vecinos Gràcia"** (owner: Ana, ID: 5)
- 20 vecinos del barrio
- Organización de fiestas y eventos vecinales

### 3.3 Grupos de Interés
**Grupo "Running Diagonal"** (owner: Marc, ID: 6)
- 30 miembros que corren juntos
- Sonia es member, Marc es owner

**Grupo "Yoga Matinal"** (owner: Laura, ID: 7)
- 12 miembros regulares
- Evento semanal de yoga

---

## 4. CASOS DE USO - CALENDARIOS

### 4.1 Calendarios Privados de Sonia
**Calendar "Personal"** (ID: 1)
- Eventos personales, citas médicas, recordatorios
- Solo Sonia tiene acceso

**Calendar "Familia"** (ID: 2)
- Compartido con Miquel (admin), Ada, Sara
- Cumpleaños, eventos familiares

**Calendar "Trabajo"** (ID: 3)
- Compartido con equipo de trabajo
- Reuniones, deadlines, eventos corporativos

### 4.2 Calendarios Públicos con Share Hash

Los calendarios públicos tienen un `share_hash` único que permite descubrirlos y suscribirse a ellos.

**Calendar "Festivos Barcelona 2025-2026"** (owner: ID 91 - Festival Mercè)
- share_hash: `bcn2025f`
- 500+ suscriptores
- Todos los festivos y celebraciones de Barcelona
- Sonia, Miquel, Ada suscritos
- **Descubrimiento**: Sonia busca "bcn2025f" y se suscribe

**Calendar "Conciertos Primavera Sound 2025"** (owner: ID 97)
- share_hash: `ps2025xx`
- 2000+ suscriptores
- Lineup completo del festival
- Sonia y 20 amigos suscritos
- **Compartido vía**: URL compartida en redes sociales

**Calendar "FC Barcelona - Temporada 2025/26"** (owner: ID 86)
- share_hash: `fcb25_26`
- 10000+ suscriptores
- Todos los partidos del Barça
- Sonia, Miquel y 30 contactos suscritos
- **Viralización**: Hash compartido en grupos de WhatsApp

**Calendar "Running Diagonal"** (owner: ID 11 - Marc)
- share_hash: `rundiag1`
- Calendario público de grupo de running
- 50 suscriptores
- Mix de miembros del grupo + suscriptores externos

**Calendar "Clases FitZone"** (owner: ID 88 - FitZone Gym)
- share_hash: `fitzone2`
- 300 suscriptores
- Todas las clases del gimnasio
- Actualizado diariamente

### 4.2.1 Casos de Descubrimiento de Calendarios

**Búsqueda directa por hash:**
- Usuario escribe `share_hash` en buscador
- Sistema retorna info del calendario
- Usuario puede suscribirse con 1 click

**Compartir via URL:**
- URL: `app://calendar/share/bcn2025f`
- Deep linking a la app
- Muestra preview del calendario antes de suscribirse

**Descubrimiento de calendarios:**
- Endpoint `/api/v1/calendars/discover` retorna calendarios populares
- Filtros: categoría, ubicación, popularidad
- Sonia descubre 5 calendarios nuevos cada semana

**Suscripciones con estado:**
- `status="active"` - Suscripción activa, recibe eventos
- `status="paused"` - Pausada temporalmente, no notificaciones
- `status="archived"` - Cancelada pero mantiene histórico

### 4.3 Calendarios Temporales
**Calendar "Curso Verano 2025"** (ID: 10)
- Start: 2025-06-15, End: 2025-08-31
- 8 miembros
- Eventos y clases del curso

**Calendar "Proyecto Q1 2026"** (ID: 11)
- Start: 2026-01-01, End: 2026-03-31
- 12 miembros del equipo
- Milestones y entregas

---

## 5. CASOS DE USO - EVENTOS

### 5.1 Eventos Privados de Sonia

#### Evento "Cena Cumpleaños Sonia" (ID: 1)
- Owner: Sonia
- Fecha: En 2 semanas
- Invitados: 25 personas (familia + amigos cercanos)
- Estados:
  - 20 aceptados
  - 3 pendientes
  - 2 rechazados
- Miquel y Ada son co-hosts (role: admin)

#### Evento "Escapada Fin de Semana" (ID: 2)
- Owner: Miquel
- Invita a: Sonia, Ada, Sara, 5 amigos
- Sonia: pendiente
- Ada: aceptado
- Sara: rechazado (tiene otro plan)

### 5.2 Eventos de Grupo

#### Evento "Comida Familia Navidad" (ID: 3)
- Owner: Padre de Sonia
- Invitados vía grupo "Familia Martínez"
- Todos aceptados excepto 2 (pendientes)

#### Evento "Quedada Running Domingo" (ID: 4)
- Owner: Marc
- Invitados vía grupo "Running Diagonal"
- 25 invitados
- 18 aceptados, 5 pendientes, 2 rechazados

### 5.3 Eventos Públicos (Usuarios Públicos)

#### Evento "Barça vs Madrid - El Clásico" (ID: 5)
- Owner: @fcbarcelona (ID 86)
- Tipo: Evento público
- Suscriptores: 5000+
- **Casos especiales:**
  - Sonia: suscrita al evento + invitada por Miquel (tiene 2 interactions)
  - Miquel: invita a Sonia, Ada, Sara
  - Sonia rechaza invitación de Miquel pero mantiene suscripción (is_attending=true)
  - Ada: acepta invitación de Miquel
  - Sara: no suscrita, no invitada

#### Evento "Clase Yoga Matinal" (ID: 6)
- Owner: @greenpointbcn (ID 92)
- Tipo: Evento recurrente semanal (lunes, miércoles, viernes 7:00)
- Suscriptores: 200
- Sonia: suscrita + invitada por Laura (2 interactions)
- 15 contactos de Sonia también suscritos

#### Evento "Cena Degustación" (ID: 7)
- Owner: @saborcatalunya (ID 89)
- Tipo: Evento único
- Suscriptores: 80
- Sonia: invitada por Miquel
- Plazas limitadas (50), lista de espera activa

### 5.4 Eventos Recurrentes

#### Evento Base "Sincro Lunes-Miércoles" (ID: 8)
- Owner: Sonia
- Tipo: recurring, weekly
- Schedule: Lunes 17:30, Miércoles 17:30
- End date: 2026-06-23
- Instancias: 52 eventos generados
- Invitados: Ada (todos aceptados), Sara (mitad aceptados, mitad pendientes)

#### Evento "Comida Semanal Viernes" (ID: 9)
- Owner: Padre de Sonia
- Tipo: recurring, weekly
- Schedule: Viernes 14:00
- Sin end date (perpetual)
- Invitados vía grupo "Familia Martínez"
- 4 instancias rechazadas por Sonia (vacaciones)

### 5.5 Cumpleaños (Eventos Anuales Perpetuos)

**4 cumpleaños en calendar "Familia":**
- Cumpleaños Miquel: 30 abril (recurring, yearly, perpetual)
- Cumpleaños Ada: 6 septiembre (recurring, yearly, perpetual)
- Cumpleaños Sonia: 31 enero (recurring, yearly, perpetual)
- Cumpleaños Sara: 2 diciembre (recurring, yearly, perpetual)

---

## 6. CASOS DE USO - INVITACIONES COMPLEJAS

### 6.1 Invitación con Doble Interacción
**Escenario:** Sonia está suscrita a clase de spinning de @fitzonegym (ID 88)
- Sonia tiene interaction_type="subscribed", status="accepted"
- Miquel la invita a ir juntos: interaction_type="invited", status="pending"
- **Resultado:** Sonia tiene 2 interactions para el mismo evento
- **Casos posibles:**
  a) Acepta invitación → Mantiene ambas interactions, va con Miquel
  b) Rechaza invitación → Mantiene suscripción, va sola
  c) Rechaza invitación pero asiste → status="rejected", is_attending=true

### 6.2 Invitaciones en Cadena
**Escenario:** Evento "Fiesta Casa Ada" (ID 20)
- Ada (owner) invita a: Sonia, Miquel, Laura, Carlos (4 personas)
- Sonia acepta e invita a su vez a: Marta, Ana
- Miquel acepta e invita a: Pedro, Juan
- Laura rechaza
- Carlos pendiente

**Attendees que ve cada uno:**
- Ada ve: todos (es owner)
- Sonia ve: Ada (inviter), Miquel, Carlos (invitados de Ada que aceptaron), Marta y Ana (sus invitados)
- Marta ve: Sonia (su inviter), Ana (otro invitado de Sonia)

### 6.3 Invitación Rechazada con Asistencia Independiente
**Escenario:** Concierto Primavera Sound (evento público)
- Miquel invita a Sonia
- Sonia rechaza (no quiere ir con Miquel)
- Sonia compra entrada aparte y asiste (is_attending=true)
- **Resultado:**
  - interaction_type="invited", status="rejected", is_attending=true
  - Sonia aparece en attendees pero NO en grupo de Miquel

### 6.4 Invitaciones Vía Grupo
**Escenario:** Evento "BBQ Vecinos" (ID 25)
- Owner: Ana (vecina)
- Invitados vía grupo "Vecinos Gràcia" (20 personas)
- Todos tienen invited_via_group_id=5
- 15 aceptan, 3 rechazan, 2 pendientes

---

## 7. CASOS DE USO - BLOQUEOS Y BANS

### 7.1 User Blocks
**Sonia bloquea a:**
- Ex-pareja (ID 50): Ya no aparece en sus contactos ni búsquedas
- Usuario spam (ID 75): Enviaba invitaciones no deseadas

**Usuarios que bloquearon a Sonia:**
- Usuario molesto (ID 63): Sonia no puede invitarlo ni verlo

### 7.2 Event Bans
**Evento "Fiesta Privada Carlos":**
- Carlos banea a usuario problemático (ID 82)
- Motivo: "Comportamiento inapropiado en evento anterior"

---

## 8. CASOS DE USO - SUSCRIPCIONES

### 8.1 Suscripciones Activas de Sonia
- @fcbarcelona (ID 86): 20 eventos de fútbol
- @fitzonegym (ID 88): 15 clases fitness
- @saborcatalunya (ID 89): 8 eventos gastronómicos
- @teatrebarcelona (ID 87): 5 obras de teatro
- @greenpointbcn (ID 92): 10 clases de yoga

**Total:** 58 eventos públicos a los que está suscrita

### 8.2 Suscripciones Pausadas
- @cinemaverdi (ID 94): status="paused" (no quiere notificaciones temporalmente)
- @casabatllo (ID 96): status="paused"

### 8.3 Descubrimiento de Nuevas Organizaciones
**10 usuarios públicos** que Sonia no ha descubierto aún pero que tienen eventos relevantes para ella

---

## 9. CASOS DE USO - INTERACCIONES ESPECIALES

### 9.1 Notas Personales
**Sonia tiene notas en:**
- Evento "Clase Patinaje": "Llevar patines nuevos 🛼"
- Evento "Cena Sara": "Preguntar por su nuevo trabajo"
- Evento "Regalo Ada": "Comprar libro que me recomendó"

### 9.2 Read/Unread
**Interacciones no leídas de Sonia (badge rojo):**
- 5 invitaciones pendientes creadas en las últimas 24h
- 2 actualizaciones de eventos aceptados
- 1 cancelación de evento (created hace 2h)

### 9.3 Eventos Cancelados
**3 eventos cancelados** con mensajes:
- "Quedada Running": "Llueve mucho, lo dejamos para la semana que viene"
- "Cena Japonés": "El restaurante cerró inesperadamente"
- "Concierto Jazz": Organización canceló (no se vendieron suficientes entradas)

---

## 10. MÉTRICAS Y ESTADÍSTICAS

### 10.1 Distribución de Usuarios
- 85 usuarios privados (85%)
- 15 usuarios públicos (15%)

### 10.2 Eventos Totales
- 200+ eventos únicos
- 500+ instancias de eventos recurrentes
- 150 eventos pasados
- 300 eventos futuros
- 50 eventos en curso

### 10.3 Invitaciones
- 1000+ interacciones de tipo "invited"
- 700 aceptadas (70%)
- 200 pendientes (20%)
- 100 rechazadas (10%)

### 10.4 Suscripciones
- 3000+ interacciones de tipo "subscribed"
- 15 usuarios públicos generan el 80% de eventos públicos
- Promedio: 200 suscriptores por usuario público

---

## 11. CASOS EDGE Y PROBLEMAS COMUNES

### 11.1 Conflictos de Horario
**Sonia tiene:**
- 3 eventos solapados el sábado 14:00-16:00
- Sistema NO impide, solo avisa

### 11.2 Límites y Capacidad
**Eventos con plazas limitadas:**
- Clase Spinning: 20/20 (llena, lista espera activa)
- Taller Cocina: 12/15 (3 plazas libres)

### 11.3 Cambios de Última Hora
- Evento cambiado de fecha 2 veces
- Algunos usuarios confirmaron fecha original
- Renotificación automática

### 11.4 Usuarios Inactivos
- 10 usuarios sin login desde hace 6+ meses
- Sus eventos antiguos persisten
- No reciben notificaciones

---

## 12. ESCENARIOS DE REALTIME

### 12.1 Sonia ve en Tiempo Real
- Nueva invitación mientras está en la app
- Miquel acepta evento al que ambos están invitados
- Usuario público publica nuevo evento de categoría suscrita
- Cancelación de evento confirmado

### 12.2 Actualizaciones Masivas
- Organización pública actualiza 50 eventos (cambio venue)
- Todos los suscriptores reciben notificación realtime

---

## RESUMEN EJECUTIVO

**100 Usuarios:**
- 1 usuario principal (Sonia, ID=1)
- 84 usuarios privados adicionales
- 15 usuarios públicos (organizaciones)

**Relaciones:**
- 2000+ contactos en agendas
- 50+ grupos (familiares, sociales, interés)
- 30+ calendarios (privados, públicos, temporales)

**Eventos:**
- 700+ eventos totales (regulares + recurrentes)
- 3000+ interacciones (invited, subscribed, joined)
- 100+ casos edge documentados

**Complejidad:**
- Todos los tipos de usuarios mezclados
- Todos los tipos de interacciones
- Casos de invitaciones complejas (doble interaction, rechazos con asistencia)
- Grupos, bloqueos, bans, suscripciones

**Objetivo:** Dataset completo y realista para testing exhaustivo de todos los flujos de la aplicación.
