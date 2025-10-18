#!/usr/bin/env bash
set -euo pipefail

# start.sh - Script for CLI startup with backend verification
# Starts Supabase and Backend, then launches CLI

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
c_reset='\033[0m'; c_red='\033[0;31m'; c_green='\033[0;32m'; c_yellow='\033[0;33m'; c_blue='\033[0;34m'

log() { printf "%b[phoenix-cli]%b %s\n" "$c_blue" "$c_reset" "$1" >&2; }
info() { log "$1"; }
success() { printf "%b[✔]%b %s\n" "$c_green" "$c_reset" "$1" >&2; }
warn() { printf "%b[!]%b %s\n" "$c_yellow" "$c_reset" "$1" >&2; }
err() { printf "%b[x]%b %s\n" "$c_red" "$c_reset" "$1" >&2; }

# Check dependencies
check_deps() {
    local MISSING=0

    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        err "Required dependency not found: docker"
        MISSING=1
    fi

    # Check Python
    if ! command -v python3 >/dev/null 2>&1; then
        err "Required dependency not found: python3"
        MISSING=1
    fi

    if [[ $MISSING -eq 1 ]]; then
        err "Install the above dependencies and retry"
        exit 1
    fi
}

# Start backend services (Supabase + FastAPI)
start_backend() {
    info "Starting Supabase and Backend services..."

    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        err "Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi

    # Change to root directory for docker compose
    cd "$ROOT_DIR"

    # Always do a clean restart to ensure environment variables are updated
    info "Ensuring clean state (stopping any existing containers)..."
    docker compose down >/dev/null 2>&1 || true

    # Clean up stopped containers and unused networks (but keep images and volumes)
    info "Cleaning up stopped containers and unused networks..."
    docker container prune -f >/dev/null 2>&1 || true
    docker network prune -f >/dev/null 2>&1 || true

    # Stop and remove ANY Docker containers using our critical ports
    local ports_to_check=(8000 8001 5432 3000)
    info "Checking and freeing ports: ${ports_to_check[*]}..."

    for port in "${ports_to_check[@]}"; do
        # First, find and stop Docker containers using this port
        local containers=$(docker ps -q --filter "expose=$port" 2>/dev/null || true)
        if [[ -n "$containers" ]]; then
            warn "Port $port is used by Docker container(s): $containers"
            echo "$containers" | xargs docker stop 2>/dev/null || true
            echo "$containers" | xargs docker rm -f 2>/dev/null || true
            success "Docker container(s) on port $port stopped and removed"
        fi

        # Then check for non-Docker processes
        local pids=$(lsof -ti :$port 2>/dev/null || true)
        if [[ -n "$pids" ]]; then
            # Filter out Docker daemon processes (we only want to kill non-Docker apps)
            local non_docker_pids=""
            for pid in $pids; do
                local process_name=$(ps -p $pid -o comm= 2>/dev/null || echo "")
                if [[ ! "$process_name" =~ [Dd]ocker && ! "$process_name" =~ "com.docker" ]]; then
                    non_docker_pids="$non_docker_pids $pid"
                fi
            done

            if [[ -n "$non_docker_pids" ]]; then
                warn "Port $port is occupied by non-Docker processes: $non_docker_pids"
                echo "$non_docker_pids" | xargs kill -9 2>/dev/null || true
                sleep 1
                success "Port $port freed from non-Docker processes"
            fi
        fi
    done

    # Create .env if not exists
    if [[ ! -f "$ROOT_DIR/.env" ]]; then
        info "Creating .env file from .env.example..."
        cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
    fi

    # Build images
    info "Building Docker images..."
    docker compose build backend >/dev/null 2>&1

    # Start all services in detached mode
    info "Starting all services (Supabase + Backend)..."
    docker compose up -d

    # Wait for database
    info "Waiting for PostgreSQL to be ready..."
    local timeout=60
    local start=$(date +%s)

    while ! nc -z localhost 5432 2>/dev/null; do
        sleep 2
        if (( $(date +%s) - start > timeout )); then
            err "Timeout waiting for PostgreSQL"
            exit 1
        fi
    done
    success "PostgreSQL is ready"

    # Wait for Kong (Supabase API Gateway)
    info "Waiting for Supabase API Gateway (Kong) to be ready..."
    timeout=90
    start=$(date +%s)

    while true; do
        # First check if port is open
        if nc -z localhost 8000 2>/dev/null; then
            # Port is open, now verify HTTP endpoint responds (Kong returns 404 on / which is fine)
            http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ 2>/dev/null || echo "000")
            if [[ "$http_code" != "000" && "$http_code" != "" ]]; then
                success "Supabase API Gateway ready at http://localhost:8000 (HTTP $http_code)"
                break
            fi
        fi

        sleep 2
        if (( $(date +%s) - start > timeout )); then
            err "Timeout waiting for Supabase on port 8000"
            exit 1
        fi
    done

    # Wait for Backend FastAPI
    info "Waiting for Backend FastAPI to be ready..."
    timeout=60
    start=$(date +%s)

    while true; do
        # First check if port is open
        if nc -z localhost 8001 2>/dev/null; then
            # Port is open, now verify HTTP endpoint responds
            if curl -sf http://localhost:8001/ >/dev/null 2>&1; then
                success "Backend FastAPI ready at http://localhost:8001"
                break
            fi
        fi

        sleep 2
        if (( $(date +%s) - start > timeout )); then
            err "Timeout waiting for Backend on port 8001"
            exit 1
        fi
    done

    # Wait for Supabase Studio
    info "Waiting for Supabase Studio to be ready..."
    timeout=60
    start=$(date +%s)

    while ! nc -z localhost 3000 2>/dev/null; do
        sleep 2
        if (( $(date +%s) - start > timeout )); then
            warn "Timeout waiting for Supabase Studio on port 3000"
            break
        fi
    done
    success "Supabase Studio ready at http://localhost:3000"

    echo ""
    success "✅ All backend services are ready!"
    info "   📊 Supabase Studio: http://localhost:3000"
    info "   🔌 Supabase API: http://localhost:8000"
    info "   🚀 Backend API: http://localhost:8001"
    info "   🔐 Database: localhost:5432"
    echo ""

    # Additional wait to ensure backend is fully stable
    info "Waiting for backend to stabilize..."
    sleep 3
}

# Start CLI
start_cli() {
    info "Starting Agenda Phoenix CLI..."

    cd "$SCRIPT_DIR"

    # Verificar si las dependencias están instaladas
    if ! python3 -c "import questionary, rich, requests" 2>/dev/null; then
        info "Installing Python dependencies..."
        pip install -r requirements.txt
        echo ""
    fi

    echo ""
    success "🗓️  Launching Agenda Phoenix CLI..."
    echo ""

    # Iniciar el menú interactivo
    python3 menu.py
}

# Main execution
main() {
    info "🚀 Starting Agenda Phoenix CLI with backend verification"

    check_deps
    start_backend
    start_cli
}

# Run main function
main "$@"
