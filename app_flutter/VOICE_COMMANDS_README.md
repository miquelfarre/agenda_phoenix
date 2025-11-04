# Comandos de Voz con Google Gemini AI 🎤

## 📖 Descripción

Esta funcionalidad permite a los usuarios de la app crear y gestionar eventos de su agenda usando **comandos de voz en lenguaje natural**, interpretados por **Google Gemini** de forma **100% GRATUITA**.

## ✨ Características

- 🎤 **Grabación de audio** on-device (iOS/Android)
- 🗣️ **Transcripción de voz a texto** usando el motor nativo del dispositivo
- 🤖 **Interpretación inteligente** con Gemini 1.5 Flash
- ✅ **Pantalla de confirmación** con preview de la acción y datos editables
- 🔒 **Almacenamiento seguro** de la API key
- 📝 **Soporte para múltiples acciones**: crear eventos, actualizar, eliminar, listar, etc.
- 💚 **GRATIS**: 1500 requests/día sin tarjeta de crédito

## 🏗️ Arquitectura

```
[Usuario habla]
    ↓
[Micrófono del dispositivo]
    ↓
[speech_to_text] → Transcripción on-device (GRATIS)
    ↓
[Google Gemini 1.5 Flash API] → Interpretación del comando (GRATIS)
    ↓
[Pantalla de confirmación] → Usuario revisa y edita
    ↓
[ApiClient] → Ejecución en el backend
```

## 📦 Dependencias Añadidas

```yaml
# pubspec.yaml
dependencies:
  record: ^5.1.2                    # Grabación de audio
  speech_to_text: ^7.0.0            # Transcripción de voz a texto
  shared_preferences: ^2.3.3        # Almacenamiento de API key
```

## 🚀 Configuración (100% GRATIS)

### 1. Obtener API Key de Google Gemini (SIN TARJETA)

1. Ve a [ai.google.dev](https://ai.google.dev)
2. Haz clic en **"Get API key in Google AI Studio"**
3. Inicia sesión con tu cuenta de Google
4. Haz clic en **"Create API key"**
5. Copia la key (empieza con `AIzaSy...`)

**✅ NO necesitas tarjeta de crédito**
**✅ 1500 requests GRATIS al día**
**✅ Tier gratuito permanente**

### 2. Configurar en la App

1. Abre la app
2. Ve a **Configuración** (Settings)
3. Selecciona **"Configuración de AI"**
4. Pega tu API key en el campo correspondiente
5. Presiona **"Guardar API Key"**
6. Asegúrate de que el toggle **"Habilitar Comandos de Voz"** está activado

### 3. Instalar Dependencias

```bash
cd app_flutter
flutter pub get
```

## 📱 Uso

### Añadir el botón a una pantalla

**Opción 1: Botón flotante extendido**

```dart
import 'package:eventypop/widgets/voice_command_button.dart';

class EventsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // ... tu contenido
      floatingActionButton: VoiceCommandButton(
        onCommandExecuted: (result) {
          // Se ejecuta cuando el comando se completa exitosamente
          print('Comando ejecutado: $result');
          // Refrescar la lista de eventos, etc.
        },
      ),
    );
  }
}
```

**Opción 2: FAB circular simple**

```dart
floatingActionButton: VoiceCommandFab(
  onCommandExecuted: (result) {
    // Acción después de ejecutar
  },
  backgroundColor: Colors.purple,  // Opcional
),
```

### Ejemplos de Comandos

| Comando de voz | Acción |
|---------------|--------|
| "Crear reunión con Juan mañana a las 3 de la tarde" | Crea evento "Reunión con Juan" para mañana 15:00 |
| "Nuevo evento cena el viernes a las 8 y media" | Crea evento "Cena" para el viernes 20:30 |
| "Qué eventos tengo esta semana" | Lista todos los eventos de la semana actual |
| "Elimina el evento de reunión" | Solicita confirmación para eliminar |
| "Crear calendario personal" | Crea un nuevo calendario |
| "Invitar a María al evento" | Crea invitación (requiere más info) |

## 📋 Acciones Soportadas

### 1. CREATE_EVENT - Crear Evento

**Parámetros:**
- `title` (string, requerido) - Título del evento
- `start_datetime` (ISO 8601, requerido) - Fecha y hora de inicio
- `end_datetime` (ISO 8601, opcional) - Fecha y hora de fin
- `description` (string, opcional) - Descripción
- `location` (string, opcional) - Ubicación
- `calendar_id` (int, opcional) - ID del calendario
- `all_day` (boolean, opcional) - Evento de todo el día

**Ejemplo de comando:** *"Crear evento cumpleaños de Ana el 15 de marzo a las 6 de la tarde"*

### 2. UPDATE_EVENT - Actualizar Evento

**Parámetros:**
- `event_id` (int, requerido) - ID del evento a actualizar
- `title`, `start_datetime`, `end_datetime`, etc. (opcionales)

**Ejemplo de comando:** *"Cambiar la reunión del lunes a las 4"*

### 3. DELETE_EVENT - Eliminar Evento

**Parámetros:**
- `event_id` (int, requerido) - ID del evento a eliminar
- `confirmation` (boolean) - Debe ser true

**Ejemplo de comando:** *"Eliminar el evento de hoy"*

### 4. LIST_EVENTS - Listar Eventos

**Parámetros:**
- `calendar_id` (int, opcional) - Filtrar por calendario
- `date_from` (date, opcional) - Desde fecha
- `date_to` (date, opcional) - Hasta fecha

**Ejemplo de comando:** *"Qué eventos tengo la próxima semana"*

### 5. CREATE_CALENDAR - Crear Calendario

**Parámetros:**
- `name` (string, requerido) - Nombre del calendario
- `description` (string, opcional) - Descripción
- `color` (hex, opcional) - Color del calendario

**Ejemplo de comando:** *"Crear calendario de trabajo"*

### 6. INVITE_USER - Invitar Usuario

**Parámetros:**
- `event_id` (int, requerido) - ID del evento
- `user_id` (int) o `email` (string, requerido) - Usuario a invitar
- `message` (string, opcional) - Mensaje de invitación

**Ejemplo de comando:** *"Invitar a juan@example.com al evento"*

## 🎨 Pantalla de Confirmación

Después de grabar el comando, se muestra una pantalla de confirmación con:

### 1. Indicador de Confianza
- 🟢 **Alta confianza** (>80%): Gemini está muy seguro de la interpretación
- 🟠 **Media confianza** (50-80%): Revisa los datos
- 🔴 **Baja confianza** (<50%): Verifica cuidadosamente

### 2. Secciones de la Pantalla

#### Lo que dijiste
Muestra el texto transcrito exactamente como se capturó.

#### Acción a ejecutar
Descripción en lenguaje natural de lo que se va a hacer.

#### Llamada al Backend
Muestra:
- Endpoint que se va a llamar (ej: `POST /api/v1/events`)
- Método HTTP (GET, POST, PUT, DELETE)

#### Parámetros
Datos que se enviarán al backend, con dos modos:
- **Modo Formulario**: Campos editables individuales
- **Modo JSON**: Editor de texto para usuarios avanzados

### 3. Acciones Disponibles

- **Cancelar**: Descarta el comando sin ejecutar nada
- **Confirmar y Ejecutar**: Envía la petición al backend

## 🔧 Archivos Creados

```
app_flutter/
├── lib/
│   ├── services/
│   │   ├── gemini_voice_service.dart           # Servicio principal de voz con Gemini
│   │   └── ai_config_service.dart              # Gestión de configuración
│   ├── screens/
│   │   ├── voice_command_confirmation_screen.dart  # Pantalla de confirmación
│   │   └── ai_settings_screen.dart             # Configuración de Gemini API
│   └── widgets/
│       └── voice_command_button.dart           # Botones de UI
├── android/app/src/main/AndroidManifest.xml    # Permisos Android
├── ios/Runner/Info.plist                       # Permisos iOS
└── VOICE_COMMANDS_README.md                    # Este archivo
```

## 🔐 Seguridad y Privacidad

### API Key
- Almacenada localmente con `SharedPreferences`
- Nunca se sincroniza con el backend
- Validación de formato antes de guardar
- Opción de eliminar en cualquier momento

### Grabaciones de Audio
- Se procesan on-device para transcripción
- No se envían a Gemini (solo texto transcrito)
- Se eliminan después del procesamiento
- No se almacenan permanentemente

### Datos Enviados a Gemini
- Solo se envía el **texto transcrito**
- Se incluye el **prompt del sistema** con las acciones disponibles
- **No se envían** datos sensibles del usuario
- Revisa la [Política de Privacidad de Google](https://policies.google.com/privacy)

## 💰 Costes

### ✅ 100% GRATIS

**Gemini 1.5 Flash - Tier Gratuito:**
- ✅ **1500 requests/día** GRATIS
- ✅ **60 requests/minuto** GRATIS
- ✅ **NO requiere tarjeta de crédito**
- ✅ **Tier gratuito permanente**

**Suficiente para:**
- ~1500 comandos de voz al día
- Uso ilimitado para POC y desarrollo
- Producción para apps pequeñas/medianas

**Si excedes el límite gratuito:**
- Gemini Flash es muy barato: $0.075 / 1M tokens input
- ~1 comando = ~1000 tokens ≈ $0.000075 (casi gratis)

Revisa precios en [ai.google.dev/pricing](https://ai.google.dev/pricing)

## 🐛 Solución de Problemas

### "Gemini API key no configurada"
**Solución:** Ve a Configuración → Configuración de AI y añade tu API key de Google Gemini.

### "Permiso de micrófono denegado"
**Solución:**
- **iOS:** Settings → EventyPop → Microphone → Permitir
- **Android:** Configuración → Apps → EventyPop → Permisos → Micrófono

### "Speech to text no disponible"
**Solución:** Asegúrate de que tu dispositivo tiene el idioma español instalado en la configuración del sistema.

### "Error 400 al llamar a Gemini API"
**Solución:** Tu API key es inválida. Verifica que la copiaste correctamente desde Google AI Studio.

### "Error 429 - Rate limit"
**Solución:** Has excedido 1500 requests/día o 60/minuto. Espera y reintenta.

### La transcripción no reconoce bien mi voz
**Solución:**
- Habla más despacio y claro
- Reduce el ruido de fondo
- Acércate más al micrófono
- Verifica que el idioma del sistema es español

## 📊 Logs y Debug

Para ver logs detallados, activa el modo debug:

```dart
// lib/config/debug_config.dart
DebugConfig.enableLogs = true;
```

Los logs incluyen:
- `[VoiceService]` - Eventos de grabación y transcripción
- `[AIConfig]` - Configuración de API key
- `[VoiceButton]` - Interacciones del usuario
- `[API]` - Llamadas al backend

## 🔄 Migración a Claude o OpenAI

El código está estructurado para facilitar la migración a otros proveedores:

### Pasos para migrar:

1. **Crear nuevo servicio** (ej: `claude_voice_service.dart`)
2. **Implementar la misma interfaz** (`VoiceCommandResult`, métodos públicos)
3. **Actualizar el provider** en `voice_command_button.dart`
4. **Actualizar la configuración** en `ai_settings_screen.dart`

La pantalla de confirmación y widgets son **agnósticos al proveedor**.

## 🚧 Próximas Mejoras

- [ ] Soporte para múltiples idiomas
- [ ] Historial de comandos de voz
- [ ] Sugerencias de comandos frecuentes
- [ ] Shortcuts de voz personalizados
- [ ] Comandos en modo offline (cache)
- [ ] Soporte para comandos encadenados
- [ ] Integración con Siri/Google Assistant
- [ ] Selector de proveedor AI (Gemini/Claude/OpenAI)

## 📚 Referencias

- [Google Gemini API](https://ai.google.dev)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [speech_to_text package](https://pub.dev/packages/speech_to_text)
- [record package](https://pub.dev/packages/record)
- [Gemini Pricing](https://ai.google.dev/pricing)

## 🤝 Contribuir

Para reportar bugs o sugerir mejoras en esta funcionalidad:

1. Crea un issue en el repositorio
2. Describe el problema o mejora
3. Incluye logs si es posible
4. Menciona tu versión de la app

---

**Desarrollado con ❤️ usando Google Gemini AI**

*Última actualización: 2025-11-04*
