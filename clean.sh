#!/bin/bash

# Script para limpiar completamente Docker
# Borra contenedores, imágenes, volúmenes, redes y caché de build
# También mata procesos en puertos usados por la aplicación

echo "🧹 Iniciando limpieza completa de Docker..."
echo ""

# Función para matar procesos en un puerto específico
kill_port() {
    local port=$1
    echo "🔍 Buscando procesos en puerto $port..."

    # Buscar PIDs usando lsof
    local pids=$(lsof -ti:$port 2>/dev/null)

    if [ -n "$pids" ]; then
        echo "⚠️  Encontrados procesos en puerto $port: $pids"
        echo "🔪 Matando procesos..."
        echo "$pids" | xargs kill -9 2>/dev/null

        # Verificar si se mataron correctamente
        sleep 1
        local remaining=$(lsof -ti:$port 2>/dev/null)
        if [ -z "$remaining" ]; then
            echo "✅ Puerto $port liberado"
        else
            echo "⚠️  Algunos procesos aún están en puerto $port"
        fi
    else
        echo "ℹ️  No hay procesos en puerto $port"
    fi
    echo ""
}


# Función para mostrar el espacio usado antes y después
show_space() {
    echo "📊 Espacio usado por Docker:"
    docker system df
    echo ""
}

# Mostrar espacio inicial
echo "📈 ESTADO INICIAL:"
show_space

# 1. Parar todos los contenedores en ejecución
echo "⏹️  Parando todos los contenedores..."
if [ "$(docker ps -q)" ]; then
    docker stop $(docker ps -q)
    echo "✅ Contenedores parados"
else
    echo "ℹ️  No hay contenedores ejecutándose"
fi
echo ""

# 2. Eliminar todos los contenedores (incluidos los parados)
echo "🗑️  Eliminando todos los contenedores..."
if [ "$(docker ps -aq)" ]; then
    docker rm $(docker ps -aq)
    echo "✅ Contenedores eliminados"
else
    echo "ℹ️  No hay contenedores para eliminar"
fi
echo ""

# 3. Eliminar todas las imágenes
echo "🖼️  Eliminando todas las imágenes..."
if [ "$(docker images -aq)" ]; then
    docker rmi $(docker images -aq) --force
    echo "✅ Imágenes eliminadas"
else
    echo "ℹ️  No hay imágenes para eliminar"
fi
echo ""

# 4. Eliminar todos los volúmenes
echo "💾 Eliminando todos los volúmenes..."
if [ "$(docker volume ls -q)" ]; then
    docker volume rm $(docker volume ls -q) --force
    echo "✅ Volúmenes eliminados"
else
    echo "ℹ️  No hay volúmenes para eliminar"
fi
echo ""

# 5. Eliminar todas las redes personalizadas
echo "🌐 Eliminando redes personalizadas..."
docker network prune --force
echo "✅ Redes eliminadas"
echo ""

# 6. Limpiar caché de build
echo "🔧 Limpiando caché de build..."
docker builder prune --all --force
echo "✅ Caché de build eliminado"
echo ""

# 7. Limpieza final del sistema
echo "🧽 Limpieza final del sistema..."
docker system prune --all --volumes --force
echo "✅ Sistema limpio"
echo ""

# Mostrar espacio final
echo "📉 ESTADO FINAL:"
show_space

echo "🎉 ¡Limpieza completa de Docker terminada!"
echo ""
echo "💡 Nota: Este script realizó:"
echo "   - Mató todos los procesos en puertos 8000 (backend) y 5432 (PostgreSQL)"
echo "   - Eliminó todos los contenedores (ejecutándose y parados)"
echo "   - Eliminó todas las imágenes (incluso las que están en uso)"
echo "   - Eliminó todos los volúmenes (incluso los con nombre)"
echo "   - Eliminó todas las redes personalizadas"
echo "   - Limpió todo el caché de build"
echo ""
echo "⚠️  Si tienes datos importantes en volúmenes, asegúrate de hacer backup antes de ejecutar este script."