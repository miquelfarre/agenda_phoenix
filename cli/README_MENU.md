# Agenda Phoenix CLI - Guía de Uso del Menú Interactivo

## 🎯 Inicio Rápido

La forma más fácil de usar Agenda Phoenix es con el menú interactivo:

```bash
# Opción 1: Usar el script de inicio
./start.sh

# Opción 2: Ejecutar directamente
python3 menu.py
```

## 📋 Características del Menú Interactivo

### ✨ Interfaz Visual
- **Navegación con teclado**: Usa las flechas ↑ ↓ para moverte entre opciones
- **Tablas con colores**: Información organizada y fácil de leer
- **Paneles informativos**: Detalles claros y estructurados
- **Indicador de conexión**: Verifica el estado de la API en tiempo real

### 🎨 Código de Colores
- 🟢 **Verde**: Operación exitosa
- 🔴 **Rojo**: Error o problema
- 🟡 **Amarillo**: Advertencia o información
- 🔵 **Azul**: Datos e información general

## 📚 Funcionalidades Disponibles

### 👥 Gestión de Usuarios

**Ver todos los usuarios**
- Lista completa de usuarios registrados
- Muestra username, contacto asociado, teléfono y proveedor de autenticación
- Información organizada en tabla visual

**Ver detalles de un usuario**
- Información completa de un usuario específico
- Incluye datos del contacto asociado si existe
- Muestra fechas de creación y última actividad

**Crear nuevo usuario**
- Formulario guiado paso a paso
- Opción de asociar con contacto existente
- Selección de proveedor de autenticación (phone, instagram, twitter, etc.)
- Validación de datos en tiempo real

### 📞 Gestión de Contactos

**Ver todos los contactos**
- Lista de contactos con nombre y teléfono
- Formato de tabla clara y ordenada

**Ver detalles de un contacto**
- Información completa del contacto
- Fecha de creación

**Crear nuevo contacto**
- Formulario simple: nombre y teléfono
- Validación de campos requeridos

### 📅 Gestión de Eventos

**Ver eventos de un usuario**
- Selección de usuario de una lista
- Muestra hasta 20 eventos más recientes
- Incluye eventos propios y suscritos
- Información: ID, nombre, fecha, tipo y propietario

**Ver detalles de un evento**
- Información completa del evento
- Fechas de inicio y fin
- Tipo de evento (regular, recurrente, cumpleaños)
- Calendario asociado si existe

**Crear nuevo evento**
- Formulario guiado completo
- Selección de propietario
- Fechas con formato flexible (YYYY-MM-DD HH:MM)
- Opción de fecha de fin
- Descripción opcional

**Eliminar evento**
- Solicita confirmación antes de eliminar
- Operación segura con doble verificación

### 📆 Gestión de Calendarios

**Ver todos los calendarios**
- Lista completa de calendarios
- Muestra nombre, descripción, propietario
- Indica si es calendario de cumpleaños

**Ver detalles de un calendario**
- Información completa
- Color y configuración
- Tipo de calendario

**Ver miembros de un calendario**
- Lista de usuarios con acceso
- Rol de cada miembro (owner, admin, member)
- Estado de la membresía (accepted, pending)
- Quién invitó a cada miembro

**Crear nuevo calendario**
- Formulario guiado
- Selección de propietario
- Opción de marcar como calendario de cumpleaños
- Descripción opcional

## 🎮 Controles de Navegación

### Teclas Principales
- **↑ ↓** : Navegar entre opciones
- **Enter** : Seleccionar/Confirmar
- **Ctrl+C** : Salir en cualquier momento
- **Esc** : Cancelar operación actual (en algunos campos)

### Flujo de Navegación
1. **Menú Principal**: Selecciona la sección (Usuarios, Contactos, Eventos, Calendarios)
2. **Submenú**: Elige la operación que deseas realizar
3. **Formularios**: Completa los campos necesarios
4. **Confirmación**: Revisa los resultados
5. **Volver**: Regresa al menú anterior con la opción "⬅️ Volver"

## 💡 Consejos de Uso

### Para Usuarios Nuevos
1. Comienza viendo las listas ("Ver todos...") para familiarizarte con los datos
2. Usa "Ver detalles" para entender la estructura de la información
3. Practica creando contactos antes de usuarios (son más simples)
4. Los eventos requieren usuarios existentes, así que créalos primero

### Para Operaciones Rápidas
- Anota los IDs de los recursos que usas frecuentemente
- Los formularios permiten escribir directamente sin navegar
- Puedes cancelar cualquier operación con Ctrl+C
- La API se verifica automáticamente al iniciar

### Para Evitar Errores
- Verifica que el backend esté corriendo (docker compose up)
- Usa el formato correcto de fechas: YYYY-MM-DD HH:MM
- Los teléfonos deben incluir código de país: +34XXXXXXXXX
- Confirma siempre antes de eliminar

## 🔧 Solución de Problemas

### Error: "No se pudo conectar a la API"
```bash
# Verifica que el backend esté corriendo
cd ..
docker compose ps

# Si no está activo, inícialo
docker compose up -d
```

### Error: "Módulo no encontrado"
```bash
# Reinstala las dependencias
pip install -r requirements.txt
```

### El menú no se ve bien
- Asegúrate de usar una terminal moderna (iTerm2, Terminal, etc.)
- Aumenta el tamaño de la ventana de la terminal
- Verifica que tu terminal soporte colores

### Caracteres extraños en pantalla
```bash
# Tu terminal puede no soportar Unicode
# Prueba con una terminal diferente o actualiza tu sistema
```

## 🚀 Ejemplos de Uso Común

### Escenario 1: Configurar Usuarios Iniciales
1. Ejecuta `python3 menu.py`
2. Selecciona "📞 Gestionar Contactos"
3. Elige "➕ Crear nuevo contacto"
4. Crea contactos para: Sonia, Miquel, Ada, Sara
5. Vuelve al menú principal
6. Selecciona "👥 Gestionar Usuarios"
7. Elige "➕ Crear nuevo usuario"
8. Asocia cada usuario con su contacto

### Escenario 2: Ver Eventos de un Usuario
1. Ejecuta `python3 menu.py`
2. Selecciona "📅 Gestionar Eventos"
3. Elige "📋 Ver eventos de un usuario"
4. Selecciona el usuario (ej: Miquel)
5. Verás todos sus eventos incluyendo suscriciones

### Escenario 3: Crear un Evento de Cumpleaños
1. Asegúrate de tener usuarios creados
2. Selecciona "📅 Gestionar Eventos"
3. Elige "➕ Crear nuevo evento"
4. Nombre: "Cumpleaños de Miquel"
5. Selecciona propietario
6. Fecha: 2026-04-30 00:00
7. Fecha fin: 2026-04-30 23:59
8. El evento se creará automáticamente

## 📖 Documentación Adicional

Para información sobre los comandos CLI avanzados, consulta `README.md`

Para información sobre la API del backend, consulta `../backend/README.md`

## 🆘 Ayuda

Si encuentras problemas:
1. Verifica que el backend esté corriendo
2. Revisa los logs del backend: `docker compose logs backend`
3. Prueba los comandos CLI individuales para aislar el problema
4. Reporta issues en el repositorio del proyecto

---

**Desarrollado con ❤️ usando Python, Rich y Questionary**
