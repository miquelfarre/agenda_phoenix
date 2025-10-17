#!/bin/bash
# Script de inicio para Agenda Phoenix CLI

echo "🗓️  Iniciando Agenda Phoenix..."
echo ""

# Verificar si las dependencias están instaladas
if ! python3 -c "import questionary, rich, requests" 2>/dev/null; then
    echo "⚠️  Instalando dependencias..."
    pip install -r requirements.txt
    echo ""
fi

# Iniciar el menú interactivo
python3 menu.py
