# Documentación de Agenda Phoenix

## 📁 Estructura de Documentación

Esta carpeta centraliza toda la documentación técnica del proyecto.

```
docs/
├── README.md          # Este archivo - índice principal
├── screens/           # Documentación de pantallas (18 archivos)
├── widgets/           # Documentación de widgets (24 archivos)
└── analysis/          # Reportes y análisis
```

---

## 📱 Pantallas (18)

Documentación completa de todas las pantallas de la aplicación.

**Ubicación**: `docs/screens/`

### Eventos (5 pantallas)
- `events_screen.md` - Pantalla principal de eventos
- `event_detail_screen.md` - Detalle de evento
- `create_edit_event_screen.md` - Crear/editar evento
- `event_series_screen.md` - Serie de eventos recurrentes
- `birthdays_screen.md` - Cumpleaños

### Calendarios (3 pantallas)
- `calendars_screen.md` - Gestión de calendarios
- `calendar_events_screen.md` - Eventos de un calendario
- `create_calendar_screen.md` - Crear calendario
- `edit_calendar_screen.md` - Editar calendario

### Contactos y Suscripciones (5 pantallas)
- `people_groups_screen.md` - Contactos y grupos
- `contact_detail_screen.md` - Detalle de contacto
- `subscriptions_screen.md` - Suscripciones
- `subscription_detail_screen.md` - Detalle de suscripción
- `public_user_events_screen.md` - Eventos públicos de usuario

### Configuración y Sistema (5 pantallas)
- `settings_screen.md` - Configuración
- `splash_screen.md` - Pantalla de carga
- `access_denied_screen.md` - Acceso denegado
- `invite_users_screen.md` - Invitar usuarios

**Índice detallado**: `docs/screens/SCREENS.md`

---

## 🧩 Widgets (24 documentados)

Documentación de widgets reutilizables de la aplicación.

**Ubicación**: `docs/widgets/`

### Widgets de Eventos (11)
- `event_card.md` - Tarjeta de evento principal
- `event_card_header.md` - Header de tarjeta (+ EventCardAttendeesRow)
- `event_card_actions.md` - Acciones de tarjeta
- `event_card_badges.md` - Badges (NEW, Calendar, etc.)
- `event_card_config.md` - Configuración de tarjeta
- `event_list_item.md` - Item de lista de eventos
- `events_list.md` - Lista agrupada de eventos
- `event_detail_actions.md` - Acciones en detalle
- `event_date_header.md` - Header de fecha
- `empty_state.md` - Estado vacío genérico
- `user_avatar.md` - Avatar de usuario

### Widgets Adaptativos (12)
- `adaptive_app.md` - App adaptativa
- `adaptive_scaffold.md` - Scaffold adaptativo
- `adaptive_button.md` - Botón adaptativo
- `adaptive_card.md` - Tarjeta adaptativa
- `adaptive_text_field.md` - Campo de texto adaptativo
- `button_config.md` - Configuración de botones
- `card_config.md` - Configuración de tarjetas
- `text_field_config.md` - Configuración de campos
- `platform_theme.md` - Temas adaptativos
- `validation_framework.md` - Framework de validación
- `app_initializer.md` - Inicializador
- `base_card.md` - Card base

**Índice detallado**: `docs/widgets/INDEX.md`

### ⚠️ Widgets Pendientes de Documentar (22)

**Alta prioridad** (usados en pantallas):
1. personal_note_widget
2. contact_card
3. subscription_card
4. selectable_card
5. language_selector
6. country_timezone_selector
7. custom_datetime_widget
8. calendar_horizontal_selector
9. timezone_horizontal_selector
10. recurrence_time_selector

**Media prioridad** (11 widgets)
**Baja prioridad** (1 widget)

Ver detalles en: `docs/analysis/ANALISIS_WIDGETS.md`

---

## 📊 Análisis y Reportes

**Ubicación**: `docs/analysis/`

- `ANALISIS_WIDGETS.md` - Análisis completo de widgets documentados vs código real
  - Problemas identificados
  - Widgets faltantes
  - Soluciones propuestas
  - Plan de acción

---

## 🎯 Estado de la Documentación

### Pantallas
- ✅ **18/18 documentadas** (100%)
- ✅ Todas incluyen sección "WIDGETS UTILIZADOS"
- ✅ Formato estandarizado

### Widgets
- ⚠️ **11/33 documentados** (33%)
- ❌ 22 widgets sin documentar
- ❌ 1 documentación de widget inexistente (event_action_section)

### Tareas Pendientes
1. 🔧 Eliminar `event_action_section.md` (no existe en código)
2. 📝 Documentar 10 widgets de alta prioridad
3. 📝 Documentar 12 widgets de media/baja prioridad
4. ✏️ Actualizar INDEX.md con estadísticas correctas

---

## 📝 Convenciones de Documentación

Todas las documentaciones siguen el mismo formato:

### Pantallas
```markdown
## 1. INFORMACIÓN GENERAL
## 2. WIDGETS UTILIZADOS
## 3. CLASE Y PROPIEDADES
## 4. CICLO DE VIDA
## 5. MÉTODOS
## 6. DEPENDENCIAS
```

### Widgets
```markdown
## 1. INFORMACIÓN GENERAL
## 2. CLASE Y PROPIEDADES
## 3. CICLO DE VIDA
## 4. MÉTODOS PRINCIPALES
## 5. LÓGICA DE NEGOCIO
## 6. PROVIDERS/UTILS
## 7. ESTILOS
## 8. LOCALIZACIÓN
## 9. CASOS DE USO
## 10. DEPENDENCIAS
```

---

## 🔗 Enlaces Útiles

- **Código fuente de pantallas**: `lib/screens/`
- **Código fuente de widgets**: `lib/widgets/`
- **Documentación de pantallas**: `docs/screens/`
- **Documentación de widgets**: `docs/widgets/`

---

**Última actualización**: 2025-11-03
**Versión**: 1.0.0
**Mantenedor**: Documentación generada con Claude Code
