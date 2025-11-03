# Índice de Documentación de Widgets

**Total de widgets en app**: 49
**Widgets documentados**: 24
**Última actualización**: 2025-11-03

## Widgets Documentados

### Widgets de Eventos (11 documentos)

1. **event_card.md** - EventCard (214 líneas)
   - Widget principal para mostrar eventos en listas
   - Múltiples variantes y estados de invitación

2. **event_card_header.md** - EventCardHeader + EventCardAttendeesRow (228 líneas)
   - Banner de invitación y info del owner
   - Fila de asistentes del evento

3. **event_card_actions.md** - EventCardActions (161 líneas)
   - Botones de acción (aceptar/rechazar, eliminar, chevron)
   - Lógica de permisos integrada

4. **event_card_badges.md** - EventCardBadges (156 líneas)
   - Badges: NEW, Calendar, Birthday, Recurring
   - Parsing de colores de calendarios

5. **event_card_config.md** - EventCardConfig (119 líneas)
   - Clase de configuración inmutable
   - Factories predefinidos

6. **event_list_item.md** - EventListItem (30 líneas)
   - Wrapper simplificado de EventCard
   - Optimizado para listas

7. **events_list.md** - EventsList (127 líneas)
   - Lista agrupada por fecha
   - Estado vacío integrado

8. **event_detail_actions.md** - EventDetailActions (45 líneas)
   - Botones en pantalla de detalle
   - Invitar y editar

9. **event_action_section.md** - EventActionSection (170 líneas)
   - Sección completa de acciones
   - Cancelación con notificación y remover de lista

10. **event_date_header.md** - EventDateHeader (19 líneas)
    - Header simple para separar fechas

11. **empty_state.md** - EmptyState (60 líneas)
    - Estado vacío genérico reutilizable
    - Imagen/icono, mensaje, acción opcional

### Widgets Adaptativos (12 documentos previos)

12. **adaptive_app.md**
    - Wrapper de aplicación adaptativo

13. **adaptive_scaffold.md**
    - Scaffold con navegación inferior

14. **adaptive_button.md**
    - Botón multi-variante adaptativo

15. **adaptive_card.md**
    - Tarjeta adaptativa multi-estilo

16. **adaptive_text_field.md**
    - Campo de texto con validación

17. **button_config.md**
    - Configuración de botones

18. **card_config.md**
    - Configuración de tarjetas

19. **text_field_config.md**
    - Configuración de text fields

20. **platform_theme.md**
    - Temas adaptativos

21. **validation_framework.md**
    - Framework de validación reutilizable

22. **app_initializer.md**
    - Inicializador de app (legacy)

23. **base_card.md**
    - Card base genérica

### Widgets de Visualización (1 documento adicional)

24. **user_avatar.md** - UserAvatar (96 líneas)
    - Avatar con cache local, URL, iniciales
    - Color generado por hash del nombre

## Widgets Pendientes de Documentar (25)

### Eventos (1):
- event_actions.dart (acciones de evento)

### Formularios y Selectores (11):
- custom_datetime_widget.dart
- country_timezone_selector.dart
- language_selector.dart
- recurrence_time_selector.dart
- recurring_event_toggle.dart
- horizontal_selector_widget.dart
- calendar_horizontal_selector.dart
- timezone_horizontal_selector.dart
- event_location_fields.dart
- pickers/city_search_picker.dart
- pickers/country_picker.dart

### Recurrencia (3):
- recurrence_pattern_list.dart
- pattern_card.dart
- pattern_edit_dialog.dart

### Visualización (6):
- contact_card.dart
- contacts_permission_dialog.dart
- group_card.dart
- subscription_card.dart
- user_group_avatar.dart
- personal_note_widget.dart

### Utilidades (3):
- confirmation_action_widget.dart
- selectable_card.dart
- styled_container.dart

### Common (1):
- common/configurable_styled_container.dart

## Prioridad de Documentación

### Alta (uso frecuente):
1. personal_note_widget.dart
2. confirmation_action_widget.dart
3. custom_datetime_widget.dart
4. contact_card.dart
5. group_card.dart
6. subscription_card.dart

### Media (contextos específicos):
7. recurrence_pattern_list.dart
8. pattern_card.dart
9. horizontal_selector_widget.dart
10. calendar_horizontal_selector.dart

### Baja (especializados):
11-25. Resto de widgets

## Estructura de Documentación

Cada documento sigue el formato:
1. Información General
2. Clase y Propiedades
3. Ciclo de Vida (si aplica)
4. Métodos principales
5. Lógica de negocio
6. Providers/Utils utilizados
7. Estilos y constantes
8. Localización
9. Casos de uso
10. Dependencias
11. Notas adicionales

## Estadísticas

- **Widgets más complejos**: EventCard (214 líneas), EventCardHeader (228 líneas)
- **Widgets más simples**: EventDateHeader (19 líneas), EventListItem (30 líneas)
- **Promedio de líneas**: ~97 líneas por widget documentado
- **Total de líneas documentadas**: ~2,328 líneas de código explicadas

## Convenciones

- Todos los archivos .md están en `lib/widgets_md/`
- Formato detallado con ejemplos de código
- Referencias a líneas específicas del código
- Diagramas de estructura cuando aplica
- Casos de uso reales
