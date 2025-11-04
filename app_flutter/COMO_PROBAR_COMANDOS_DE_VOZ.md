# 🎤 Cómo Probar los Comandos de Voz - Guía Paso a Paso

## ⏱️ Tiempo estimado: 5 minutos

---

## 📱 PASO 1: Obtener API Key de Google Gemini (GRATIS)

### 1.1 Ir a Google AI Studio

1. Abre tu navegador
2. Ve a: **https://ai.google.dev**
3. Haz clic en el botón **"Get API key"** (generalmente está en la parte superior derecha)

### 1.2 Crear la API Key

1. **Inicia sesión** con tu cuenta de Google (cualquier cuenta Gmail funciona)
2. Si es la primera vez, te pedirá crear un proyecto:
   - Haz clic en **"Create API key in new project"**
3. **¡Listo!** Verás algo como:

```
AIzaSyABCDEFGHIJKLMNOPQRSTUVWXYZ1234567
```

4. **Haz clic en "Copy"** para copiar la key al portapapeles

### ✅ Confirmación
- ✅ **NO necesitas tarjeta de crédito**
- ✅ **1500 requests GRATIS al día** (suficiente para ~1500 comandos de voz)
- ✅ **Tier gratuito permanente**

---

## 🚀 PASO 2: Ejecutar la App

### 2.1 Abrir Terminal

```bash
cd /Users/miquelfarre/development/agenda_phoenix/app_flutter
```

### 2.2 Ejecutar en Dispositivo/Emulador

**Opción A: Android**
```bash
flutter run
```

**Opción B: iOS Simulator**
```bash
flutter run -d "iPhone 15"
```

**Opción C: Seleccionar dispositivo**
```bash
flutter devices  # Ver dispositivos disponibles
flutter run -d <device-id>
```

### ⏳ Espera a que compile
La primera vez puede tardar 2-3 minutos.

---

## ⚙️ PASO 3: Configurar la API Key en la App

### 3.1 Navegar a Configuración

1. Una vez que la app esté corriendo
2. Ve al **menú de navegación** (generalmente en la parte inferior)
3. Toca el icono de **"Settings"** o **"Configuración"**

### 3.2 Abrir Configuración de IA

1. En la pantalla de Settings, **desplázate hacia abajo**
2. Busca la sección **"Comandos de Voz IA"** con un icono de ✨ (sparkles)
3. Toca el botón **"Configurar IA"**

### 3.3 Guardar la API Key

1. En la pantalla de configuración de AI:
   - Verás un campo de texto que dice **"API Key"**
2. **Pega la key** que copiaste en el Paso 1:
   - **Opción A:** Usa el botón del 📋 (clipboard) a la derecha del campo
   - **Opción B:** Toca el campo y pega manualmente (Cmd+V / Ctrl+V)
3. **Verifica** que la key empiece con `AIzaSy...`
4. Toca el botón **"Guardar API Key"**

### ✅ Confirmación
Deberías ver:
- ✅ Un mensaje verde: **"✓ API key guardada correctamente"**
- ✅ Un badge verde que dice **"Configurada"**
- ✅ El toggle **"Habilitar Comandos de Voz"** debe estar activado (azul)

---

## 🎤 PASO 4: Probar un Comando de Voz

### 4.1 Ir a la Pantalla de Eventos

1. **Vuelve atrás** desde la configuración
2. Ve a la pantalla principal de **"Events"** o **"Eventos"**
3. Verás **DOS botones flotantes** en la esquina inferior derecha:
   - 🎤 **Micrófono** (arriba) - Comandos de voz
   - ➕ **Plus** (abajo) - Crear evento manualmente

### 4.2 Presionar el Botón de Micrófono

1. **Toca el botón del micrófono** (🎤)
2. Si es la primera vez, te pedirá **permiso para usar el micrófono**:
   - Toca **"Permitir"** o **"Allow"**

### 4.3 Hablar el Comando

1. Una vez que el botón cambie de color (generalmente a **rojo**), **habla claramente**:

```
"Crear reunión con Juan mañana a las 3 de la tarde"
```

2. **Espera 2-3 segundos** mientras procesa

### 4.4 Revisar la Pantalla de Confirmación

Verás una pantalla con:

#### 📊 Indicador de Confianza
- 🟢 Verde (>80%): Gemini está muy seguro
- 🟠 Naranja (50-80%): Revisa los datos
- 🔴 Rojo (<50%): Verifica cuidadosamente

#### 📝 Secciones que verás:

1. **"Lo que dijiste"**
   ```
   "Crear reunión con Juan mañana a las 3 de la tarde"
   ```

2. **"Acción a ejecutar"**
   ```
   Se creará un evento llamado "Reunión con Juan"
   el día 05/11/2025 a las 15:00
   ```

3. **"Llamada al Backend"**
   ```
   Endpoint: POST /api/v1/events
   Método: POST
   ```

4. **"Parámetros"** (editables)
   - Puedes cambiar el título, fecha, hora, etc.
   - Dos modos disponibles:
     - 📝 **Formulario**: Campos individuales
     - 💻 **JSON**: Editor de texto avanzado

### 4.5 Confirmar y Ejecutar

1. **Revisa** que los datos sean correctos
2. Si necesitas cambiar algo:
   - Edita los campos directamente
   - O usa el botón de código (</>) para modo JSON
3. Cuando todo esté bien, toca **"Confirmar y Ejecutar"**

### ✅ Resultado
Deberías ver:
- ✅ Un mensaje verde: **"✓ Acción ejecutada exitosamente"**
- ✅ Volver automáticamente a la pantalla de eventos
- ✅ **El evento aparecerá en tu lista**

---

## 🎯 Ejemplos de Comandos para Probar

### Comandos Simples

```bash
# 1. Crear evento básico
"Crear evento reunión mañana a las 10"

# 2. Con ubicación
"Nuevo evento cena el viernes a las 8 en el restaurante"

# 3. Todo el día
"Crear evento vacaciones del 15 al 20 de diciembre"
```

### Comandos Avanzados

```bash
# 4. Con descripción
"Crear reunión de equipo el lunes a las 9 con descripción revisar proyectos"

# 5. Listar eventos
"Qué eventos tengo esta semana"

# 6. Crear calendario
"Crear calendario de trabajo"
```

---

## 🐛 Solución de Problemas

### Problema: "Gemini API key no configurada"
**Solución:**
1. Ve a Settings → Configurar IA
2. Verifica que pegaste la API key correctamente
3. La key debe empezar con `AIzaSy...`

---

### Problema: "Permiso de micrófono denegado"

**En iOS:**
1. Ve a **Settings del teléfono** (no de la app)
2. Busca **EventyPop**
3. Toca **Microphone**
4. Activa el permiso

**En Android:**
1. Ve a **Configuración del teléfono**
2. **Apps** → **EventyPop**
3. **Permisos** → **Micrófono**
4. Selecciona **"Permitir"**

---

### Problema: "Speech to text no disponible"
**Solución:**
1. Ve a la configuración del teléfono
2. **Idioma y región**
3. Asegúrate de que **Español** está instalado
4. Reinicia la app

---

### Problema: "Error 400 al llamar a Gemini API"
**Solución:**
1. Tu API key es inválida
2. Ve a https://ai.google.dev
3. Verifica que copiaste la key completa
4. Genera una nueva key si es necesario

---

### Problema: "La transcripción no reconoce bien mi voz"
**Soluciones:**
- 🗣️ Habla **más despacio** y **claro**
- 🔇 Reduce el **ruido de fondo**
- 📱 **Acércate** más al micrófono
- 🌐 Verifica que el idioma del sistema sea **Español**

---

### Problema: El botón de micrófono no aparece
**Solución:**
1. Verifica que compiló sin errores:
   ```bash
   flutter analyze
   ```
2. Si hay errores, ejecuta:
   ```bash
   flutter pub get
   flutter clean
   flutter run
   ```

---

## 📹 Video de Demostración (Opcional)

Si quieres grabar un video de prueba:

1. **Abre la app**
2. **Graba tu pantalla** mientras:
   - Presionas el botón de micrófono
   - Dices el comando
   - Revisas la confirmación
   - Ejecutas la acción
3. Comparte el video para feedback

---

## 📊 Monitoreo de Uso

Para ver cuántos requests llevas:

1. Ve a **https://aistudio.google.com**
2. Inicia sesión
3. Ve a **"Usage"** o **"Uso"**
4. Verás tus requests del día

**Recuerda:**
- ✅ Límite: 1500 requests/día
- ✅ Cada comando de voz = 1 request
- ✅ Se resetea cada 24 horas

---

## 🎓 Próximos Pasos

Una vez que funcione correctamente:

### 1. Probar Más Comandos
Intenta crear diferentes tipos de eventos:
- Eventos de todo el día
- Eventos con ubicación
- Eventos recurrentes (si está implementado)

### 2. Probar Otras Acciones
- "Qué eventos tengo hoy"
- "Crear calendario personal"
- "Invitar a [email] al evento"

### 3. Migrar a Claude (Opcional)
Si más adelante quieres usar Claude en lugar de Gemini:
- Los archivos ya están preparados en `lib/services/ai/`
- Solo necesitas cambiar el provider en el código

---

## 📝 Feedback

Si encuentras algún problema:

1. **Anota el error exacto**
2. **Revisa los logs**:
   ```bash
   flutter logs
   ```
3. **Toma una screenshot** del error
4. **Reporta** el issue con toda la info

---

## ✨ ¡Éxito!

Si llegaste hasta aquí y el comando funcionó:

🎉 **¡Felicidades!** Ya tienes comandos de voz funcionando con IA

Ahora puedes:
- ✅ Crear eventos hablando
- ✅ Ahorrar tiempo en tu agenda
- ✅ Usar IA de forma gratuita
- ✅ Migrar a otros proveedores cuando quieras

---

**Última actualización:** 2025-11-04
**Versión:** 1.0.0
**Powered by:** Google Gemini AI
