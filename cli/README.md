# Agenda Phoenix CLI

CLI para gestionar la aplicación Agenda Phoenix desde la línea de comandos.

## Instalación

```bash
cd cli
pip install -r requirements.txt
```

## Configuración

Por defecto, la CLI se conecta a `http://localhost:8001`. Puedes cambiar la URL de la API configurando la variable de entorno `AGENDA_API_URL`:

```bash
export AGENDA_API_URL="http://tu-servidor:puerto"
```

## Uso

La CLI tiene varios comandos organizados por categorías:

### Verificar estado de la API

```bash
python agenda.py status
```

### Gestión de Usuarios

**Listar todos los usuarios:**
```bash
python agenda.py users list
```

**Ver detalles de un usuario:**
```bash
python agenda.py users get 1
```

**Crear un nuevo usuario:**
```bash
python agenda.py users create --name "Juan Pérez" --email "juan@email.com" --phone "612345678"
```

**Crear un usuario público:**
```bash
python agenda.py users create --name "FC Barcelona" --public
```

### Gestión de Eventos

**Listar eventos de un usuario:**
```bash
python agenda.py events list --user 2
```

**Listar eventos con rango de fechas:**
```bash
python agenda.py events list --user 2 --from 2025-10-01 --to 2025-12-31
```

**Ver detalles de un evento:**
```bash
python agenda.py events get 5
```

**Crear un evento:**
```bash
python agenda.py events create \
  --name "Reunión importante" \
  --owner 1 \
  --start "2025-11-15 10:00" \
  --end "2025-11-15 11:00" \
  --desc "Discutir el proyecto"
```

**Crear un evento en un calendario:**
```bash
python agenda.py events create \
  --name "Cena familiar" \
  --owner 1 \
  --start "2025-11-20 20:00" \
  --calendar 1
```

**Eliminar un evento:**
```bash
python agenda.py events delete 10
```

**Eliminar sin confirmación:**
```bash
python agenda.py events delete 10 --yes
```

### Gestión de Calendarios

**Listar todos los calendarios:**
```bash
python agenda.py calendars list
```

**Ver detalles de un calendario:**
```bash
python agenda.py calendars get 1
```

**Crear un calendario:**
```bash
python agenda.py calendars create \
  --name "Trabajo" \
  --owner 1 \
  --desc "Calendario de eventos laborales"
```

**Crear un calendario de cumpleaños:**
```bash
python agenda.py calendars create \
  --name "Cumpleaños" \
  --owner 1 \
  --birthdays
```

**Compartir un calendario:**
```bash
python agenda.py calendars share \
  --calendar 1 \
  --user 2 \
  --role admin \
  --invited-by 1
```

**Listar miembros de un calendario:**
```bash
python agenda.py calendars members 1
```

### Gestión de Subscripciones

**Suscribirse a un usuario público:**
```bash
python agenda.py subscribe subscribe --user 2 --to 7
```
Esto suscribe al usuario #2 a todos los eventos del usuario público #7 (por ejemplo, FC Barcelona).

**Desuscribirse de un usuario público:**
```bash
python agenda.py subscribe unsubscribe --user 2 --from 7
```

### Gestión de Interacciones con Eventos

**Invitar a un usuario a un evento:**
```bash
python agenda.py interact invite --event 5 --user 3
```

**Aceptar una invitación:**
```bash
python agenda.py interact accept --event 5 --user 3
```

**Rechazar una invitación:**
```bash
python agenda.py interact reject --event 5 --user 3
```

**Listar interacciones de un evento:**
```bash
python agenda.py interact list 5
```

## Ejemplos Prácticos

### Ejemplo 1: Crear un usuario y su calendario personal

```bash
# Crear usuario
python agenda.py users create --name "María García" --email "maria@email.com"
# Supongamos que se crea con ID 8

# Crear calendario personal
python agenda.py calendars create --name "Personal" --owner 8 --desc "Calendario personal de María"
```

### Ejemplo 2: Crear un evento y invitar a usuarios

```bash
# Crear evento
python agenda.py events create \
  --name "Fiesta de cumpleaños" \
  --owner 1 \
  --start "2025-12-15 19:00" \
  --end "2025-12-15 23:00" \
  --desc "¡Celebración de cumpleaños!"

# Supongamos que el evento se crea con ID 50

# Invitar usuarios
python agenda.py interact invite --event 50 --user 2
python agenda.py interact invite --event 50 --user 3
python agenda.py interact invite --event 50 --user 4
```

### Ejemplo 3: Suscribirse a eventos de FC Barcelona

```bash
# Listar usuarios para encontrar el ID de FC Barcelona
python agenda.py users list

# Suscribirse al usuario FC Barcelona (ID 7)
python agenda.py subscribe subscribe --user 2 --to 7

# Ver eventos del usuario (ahora incluye los de FC Barcelona)
python agenda.py events list --user 2
```

### Ejemplo 4: Compartir un calendario familiar

```bash
# Crear calendario familiar
python agenda.py calendars create --name "Familia" --owner 1 --desc "Calendario compartido familiar"
# Supongamos que se crea con ID 10

# Compartir con miembros de la familia
python agenda.py calendars share --calendar 10 --user 2 --role admin --invited-by 1
python agenda.py calendars share --calendar 10 --user 3 --role member --invited-by 1
python agenda.py calendars share --calendar 10 --user 4 --role member --invited-by 1

# Ver miembros del calendario
python agenda.py calendars members 10
```

## Ayuda

Para ver la ayuda general:
```bash
python agenda.py --help
```

Para ver ayuda de un comando específico:
```bash
python agenda.py users --help
python agenda.py events create --help
```

## Roles en Calendarios

- **owner**: Propietario del calendario, tiene control total
- **admin**: Administrador, puede gestionar el calendario y sus miembros
- **member**: Miembro, puede ver y crear eventos en el calendario

## Tipos de Interacciones con Eventos

- **invited**: Usuario invitado a un evento (pendiente de respuesta)
- **accepted**: Usuario aceptó la invitación
- **rejected**: Usuario rechazó la invitación
- **subscribed**: Usuario suscrito a eventos de un usuario público

## Tips

1. **Uso de aliases**: Puedes crear un alias para facilitar el uso:
   ```bash
   alias agenda="python /ruta/a/cli/agenda.py"
   ```

2. **Auto-completado**: Typer incluye auto-completado. Para habilitarlo en bash:
   ```bash
   eval "$(_AGENDA_COMPLETE=bash_source python agenda.py)"
   ```

3. **Variables de entorno**: Puedes configurar la URL de la API de forma permanente en tu `.bashrc` o `.zshrc`:
   ```bash
   export AGENDA_API_URL="http://localhost:8001"
   ```

4. **Formato de fechas**: Las fechas pueden ser en varios formatos:
   - `2025-11-15 10:00`
   - `2025-11-15T10:00:00`
   - `2025-11-15`

## Solución de Problemas

**Error de conexión:**
```
L No se pudo conectar a la API en http://localhost:8001
```
Verifica que el backend esté corriendo:
```bash
docker compose ps
```

**Error 404 en endpoints:**
Asegúrate de que los IDs que estás usando existen. Puedes listar los recursos primero:
```bash
python agenda.py users list
python agenda.py calendars list
```
