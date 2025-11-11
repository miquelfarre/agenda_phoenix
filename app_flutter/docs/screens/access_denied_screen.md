# AccessDeniedScreen - Documentación

## 1. INFORMACIÓN GENERAL

**Archivo**: `lib/screens/access_denied_screen.dart`
**Líneas**: 89
**Tipo**: StatelessWidget
**Propósito**: Pantalla estática que muestra un mensaje de acceso denegado cuando el usuario no tiene permisos para acceder a un recurso

---

## 2. WIDGETS UTILIZADOS

### 2.1. Widgets Propios de la App

#### **AdaptivePageScaffold** (línea 14)
**Archivo**: `lib/widgets/adaptive_scaffold.dart`
**Documentación**: `lib/widgets_md/adaptive_page_scaffold.md`

**Uso**: Scaffold principal con título "Error"

**Total de widgets propios**: 1 (AdaptivePageScaffold)

**Nota**: Esta es una pantalla completamente estática sin widgets custom adicionales, usa solo componentes nativos y estilos.

---

## 3. CLASE Y PROPIEDADES

### AccessDeniedScreen (líneas 8-15)
Widget sin estado que extiende `StatelessWidget`

**Propiedades**: Ninguna (constructor solo con key)

## 3. MÉTODO BUILD

### build(BuildContext context) (líneas 12-15)
**Tipo de retorno**: `Widget`

**Propósito**: Construye la UI principal de la pantalla

**Lógica**:
1. Obtiene `l10n` del contexto
2. Retorna `AdaptivePageScaffold` con:
   - key: 'access_denied_screen_scaffold'
   - title: "Error" (traducido)
   - body: llama a `_buildContent(l10n)`

## 4. MÉTODO DE CONSTRUCCIÓN DE CONTENIDO

### _buildContent(AppLocalizations l10n) (líneas 17-87)
**Tipo de retorno**: `Widget`

**Parámetros**:
- `l10n`: Localizaciones para los textos

**Propósito**: Construye el contenido centrado de la pantalla de error

**Estructura**:
- SafeArea con Center y Padding (32px)
- Column centrada verticalmente con:

1. **Icono contenedor** (líneas 25-34):
   - Container de 120x120
   - Degradado gris (grey400 → grey600 → grey700)
   - Border radius 24px
   - Sombra negra con opacidad 0.1
   - Icono: clear_thick blanco (tamaño 60)

2. **Espaciador**: 32px

3. **Título** (líneas 38-42):
   - Texto: "Acceso denegado" (traducido)
   - Tamaño 32, bold, negro87
   - Letter spacing -0.5
   - Centrado

4. **Espaciador**: 16px

5. **Mensaje primario** (líneas 46-50):
   - Descripción del error principal
   - Tamaño 16, gris700, peso 500
   - Height 1.5 (interlineado)
   - Centrado

6. **Espaciador**: 8px

7. **Mensaje secundario** (líneas 54-58):
   - Descripción adicional
   - Tamaño 14, gris600
   - Height 1.5
   - Centrado

8. **Espaciador**: 40px

9. **Caja de información** (líneas 62-81):
   - Container con padding 16px
   - Fondo azul claro (blueShade50)
   - Border azul claro (blueShade100)
   - Border radius 12px
   - Row con:
     - Icono: info azul (tamaño 24)
     - Espaciador 12px
     - Texto expandido: "Contacta al admin si crees que es un error"
     - Estilo: tamaño 14, azul600, peso 500

## 5. DEPENDENCIAS

### Widgets externos:
- Ninguno complejo (solo widgets básicos de Flutter)

### Widgets internos:
- `AdaptivePageScaffold`: Scaffold adaptativo

### Helpers:
- `PlatformWidgets.platformIcon()`: Icono adaptativo
- `context.l10n`: Localizaciones
- `AppStyles`: Estilos de la app (colores, helpers)

### Localización:
Strings usados:
- `error`: Título del scaffold
- `accessDeniedTitle`: Título principal
- `accessDeniedMessagePrimary`: Mensaje principal
- `accessDeniedMessageSecondary`: Mensaje secundario
- `contactAdminIfError`: Mensaje de ayuda

## 6. CARACTERÍSTICAS DE LA PANTALLA

### Funcionalidades:
- Pantalla estática, solo informativa
- No tiene acciones ni navegación
- Solo muestra mensajes de error

### Uso típico:
Se navega a esta pantalla cuando:
- El usuario intenta acceder a un evento sin permisos
- El usuario intenta ver un calendario al que no tiene acceso
- Errores de autorización en general

### Diseño visual:
- **Centrada**: Todo el contenido centrado vertical y horizontalmente
- **Icono grande**: Container con degradado gris y icono X blanco
- **Jerarquía de texto**: Título grande, mensajes medianos con diferentes pesos
- **Caja de ayuda**: Destacada con fondo azul claro y borde
- **Espaciado generoso**: 32-40px entre secciones principales

## 7. ESTRUCTURA DEL CÓDIGO

**Total de líneas**: 89
**Métodos**: 2 (build, _buildContent)
**Tipo**: Stateless (sin estado)

**Distribución**:
- Imports: ~7 líneas (7.9%)
- Declaración de clase: ~2 líneas (2.2%)
- build method: ~4 líneas (4.5%)
- _buildContent method: ~71 líneas (79.8%)
- Resto: ~5 líneas (5.6%)

## 8. CARACTERÍSTICAS TÉCNICAS

### Widget sin estado:
- Extiende `StatelessWidget`
- No mantiene estado
- Contenido completamente estático

### Diseño responsivo:
- Usa padding y spacing fijos
- Centro absoluto con Column
- Se adapta a diferentes tamaños de pantalla naturalmente

### Estilos consistentes:
- Usa `AppStyles` para todos los colores
- Gradientes predefinidos
- Sombras y borders redondeados

### Key para testing:
- 'access_denied_screen_scaffold': Para identificar el scaffold en tests

### Sin navegación:
- No tiene botones de acción
- Usuario debe usar botón de "atrás" del sistema
- Pantalla de "dead end" informativa

### Accesibilidad:
- Todos los textos son legibles (tamaños adecuados)
- Contraste suficiente en todos los elementos
- Textos centrados y bien espaciados
- Icono grande y reconocible
