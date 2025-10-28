#!/bin/bash
# check_todos.sh
# Script de verificación automática de TODOs
# Este script se debe ejecutar al iniciar trabajo en el proyecto

set -e

echo "🔍 Verificando TODOs en el proyecto EventyPop..."
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contadores
TODO_COUNT=0
FILES_WITH_TODOS=()

# Buscar TODOs en archivos Dart (Flutter)
echo "📱 Buscando en código Flutter (*.dart)..."
if DART_TODOS=$(grep -rn "// TODO\|// FIXME\|// XXX\|// HACK" --include="*.dart" app_flutter/lib/ 2>/dev/null); then
    echo -e "${RED}❌ TODOs encontrados en archivos Dart:${NC}"
    echo "$DART_TODOS"
    echo ""
    TODO_COUNT=$((TODO_COUNT + $(echo "$DART_TODOS" | wc -l)))
    FILES_WITH_TODOS+=("Dart")
fi

# Buscar TODOs en archivos Python (Backend)
echo "🐍 Buscando en código Python (*.py)..."
if PYTHON_TODOS=$(grep -rn "# TODO\|# FIXME\|# XXX\|# HACK" --include="*.py" backend/ 2>/dev/null | grep -v ".venv" | grep -v "__pycache__"); then
    echo -e "${RED}❌ TODOs encontrados en archivos Python:${NC}"
    echo "$PYTHON_TODOS"
    echo ""
    TODO_COUNT=$((TODO_COUNT + $(echo "$PYTHON_TODOS" | wc -l)))
    FILES_WITH_TODOS+=("Python")
fi

# Resultado final
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $TODO_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ ÉXITO: No se encontraron TODOs en el código${NC}"
    echo ""
    echo "El proyecto cumple con la política anti-TODO."
    echo "Puedes continuar con el desarrollo."
    echo ""
    exit 0
else
    echo -e "${RED}❌ FALLO: Se encontraron $TODO_COUNT TODO(s) en el código${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  ESTÁ PROHIBIDO POR DISEÑO DEL APLICATIVO TENER TODOs EN EL CÓDIGO${NC}"
    echo ""
    echo "Por favor, resuelve los TODOs antes de continuar:"
    echo ""
    echo "1. Revisa cada TODO y decide:"
    echo "   • Implementar la funcionalidad completa AHORA (preferido)"
    echo "   • Crear un issue en el sistema de tracking"
    echo "   • Documentar la limitación sin usar TODO"
    echo ""
    echo "2. Lee la guía completa en:"
    echo "   📄 DESARROLLO_SIN_TODOS.md"
    echo ""
    echo "3. Para verificar si las funcionalidades están implementadas:"
    echo "   ./verify_todo_implementations.sh"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    exit 1
fi
