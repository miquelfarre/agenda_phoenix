# EventDateHeader - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/widgets/event_date_header.dart`
**Líneas**: 19
**Tipo**: StatelessWidget
**Propósito**: Header simple para separar grupos de eventos por fecha

## 2. CLASE Y PROPIEDADES

### EventDateHeader (líneas 4-18)

**Propiedades**:
- `text` (String, required): Texto del header (ej: "Hoy", "Lunes, 3 de noviembre")

## 3. MÉTODO BUILD

### build(BuildContext context) (líneas 9-17)

**Estructura**:
```
Padding(h: 16, v: 8)
└── Text(text)
    - style: headlineSmall
    - color: grey700
    - fontWeight: bold
```

## 4. ESTILO

**Padding**: horizontal 16px, vertical 8px
**Typography**: AppStyles.headlineSmall con modificaciones
**Color**: grey700
**FontWeight**: bold

## 5. USO TÍPICO

En EventsList (events_list.dart):
```dart
EventDateHeader(text: 'Hoy')
EventDateHeader(text: 'Lunes, 3 • Noviembre')
```

## 6. NOTAS

- Widget extremadamente simple
- Solo presentacional, sin lógica
- Usado en listas agrupadas por fecha
- Consistente con diseño de la app
