FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copiar archivos de dependencias
COPY requirements.txt .
COPY pyproject.toml .

# Instalar dependencias Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código del servidor
COPY server.py .
COPY schemas/ ./schemas/

# Exponer puerto (aunque MCP usa stdio, útil para debugging)
EXPOSE 8002

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import sys; sys.exit(0)"

# Comando por defecto
CMD ["python", "server.py"]
