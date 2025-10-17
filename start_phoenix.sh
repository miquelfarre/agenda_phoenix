#!/usr/bin/env bash
set -euo pipefail

# start_phoenix.sh - Script for Supabase, Backend and iOS startup
# Defaults: Platform=iOS
# Features: Auto-cleans Hive database on each start

VERSION="1.0.0"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=${1:-both}  # Can be: backend, ios, both, stop, status

# Paths for PID and logs
PID_DIR="$ROOT_DIR/.pids"
LOG_DIR="$ROOT_DIR/.logs"

# Colors
c_reset='\033[0m'; c_red='\033[0;31m'; c_green='\033[0;32m'; c_yellow='\033[0;33m'; c_blue='\033[0;34m'

log() { printf "%b[phoenix]%b %s\n" "$c_blue" "$c_reset" "$1" >&2; }
info() { log "$1"; }
success() { printf "%b[✔]%b %s\n" "$c_green" "$c_reset" "$1" >&2; }
warn() { printf "%b[!]%b %s\n" "$c_yellow" "$c_reset" "$1" >&2; }
err() { printf "%b[x]%b %s\n" "$c_red" "$c_reset" "$1" >&2; }

# Check dependencies
check_deps() {
    local MISSING=0
    for cmd in docker flutter xcrun; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            err "Required dependency not found: $cmd"
            MISSING=1
        fi
    done

    if [[ $MISSING -eq 1 ]]; then
        err "Install the above dependencies and retry"
        exit 1
    fi
}

# Ensure dirs for pids and logs
ensure_runtime_dirs() {
    mkdir -p "$PID_DIR" "$LOG_DIR"
}

# Start backend services (Supabase + FastAPI)
start_backend() {
    info "Starting Supabase and Backend services..."

    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        err "Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi

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

    while ! nc -z localhost 8000 2>/dev/null; do
        sleep 2
        if (( $(date +%s) - start > timeout )); then
            err "Timeout waiting for Supabase on port 8000"
            exit 1
        fi
    done
    success "Supabase API Gateway ready at http://localhost:8000"

    # Wait for Backend FastAPI
    info "Waiting for Backend FastAPI to be ready..."
    timeout=60
    start=$(date +%s)

    while ! nc -z localhost 8001 2>/dev/null; do
        sleep 2
        if (( $(date +%s) - start > timeout )); then
            err "Timeout waiting for Backend on port 8001"
            exit 1
        fi
    done
    success "Backend FastAPI ready at http://localhost:8001"

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
    success "✅ All services are ready!"
    info "   📊 Supabase Studio: http://localhost:3000"
    info "   🔌 Supabase API: http://localhost:8000"
    info "   🚀 Backend API: http://localhost:8001"
    info "   🔐 Database: localhost:5432"
    echo ""
    info "Use './start_phoenix.sh stop' to stop all services"
}

# Detect iOS device automatically (returns UDID)
detect_ios_device() {
    info "Detecting available iOS devices (searching for UDID)..."

    # Prioritize already booted devices
    local booted_udid=$(xcrun simctl list devices | grep -E "iPhone.*\(.*\).*Booted" | head -1 | sed -E 's/.*\(([0-9A-Fa-f-]+)\).*/\1/')

    if [[ -n "$booted_udid" ]]; then
        info "Using already booted simulator (UDID: $booted_udid)"
        echo "$booted_udid"
        return 0
    fi

    # If none booted, select first available iPhone device
    local available_udid=$(xcrun simctl list devices available | grep -E "iPhone" | head -1 | sed -E 's/.*\(([0-9A-Fa-f-]+)\).*/\1/')

    if [[ -n "$available_udid" ]]; then
        info "Available simulator detected (UDID: $available_udid)"
        echo "$available_udid"
        return 0
    fi

    err "No iOS devices available"
    info "Complete device list:"
    xcrun simctl list devices
    exit 1
}

# Start iOS simulator if needed
start_ios_simulator() {
    local udid="$1"
    info "Starting iOS simulator (UDID: $udid)..."

    # Check if UDID corresponds to an already booted device
    if xcrun simctl list devices | grep -q "$udid.*(Booted)"; then
        info "Simulator (UDID: $udid) is already running"
    else
        info "Booting simulator (UDID: $udid)..."
        if ! xcrun simctl boot "$udid" >/dev/null 2>&1; then
            warn "Could not boot simulator UDID=$udid with simctl boot"
        fi
        # Wait for simulator to boot
        if ! xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1; then
            sleep 4
        fi
    fi

    # Open Simulator app if not open
    if ! pgrep -f "Simulator.app" >/dev/null; then
        info "Opening Simulator.app..."
        open -a Simulator 2>/dev/null || warn "Could not open Simulator.app automatically"
        sleep 2
    fi
}

# Clean Hive database by uninstalling the app
clean_hive_data() {
    local device_udid="$1"

    info "Cleaning Hive database (uninstalling app from simulator)..."

    # Get bundle identifier
    local bundle_id="com.agendaphoenix.appFlutter"

    # Uninstall app to clear all data including Hive
    if xcrun simctl uninstall "$device_udid" "$bundle_id" 2>/dev/null; then
        success "Hive data cleared (app uninstalled)"
    else
        info "App not installed or already clean"
    fi
}

# Start Flutter app
start_flutter() {
    local device_udid="$1"

    info "Starting Flutter app..."

    cd "$ROOT_DIR/app_flutter"

    # Clean Hive data before starting
    clean_hive_data "$device_udid"

    # Deep clean all Flutter build artifacts
    info "Deep cleaning Flutter build artifacts..."
    rm -rf build/ .dart_tool/ ios/build/ >/dev/null 2>&1 || true
    flutter clean >/dev/null

    # Get Flutter dependencies
    info "Getting Flutter dependencies..."
    flutter pub get >/dev/null

    # Ensure iOS pods are up to date
    info "Updating iOS pods..."
    cd ios && pod install --repo-update >/dev/null 2>&1 || true && cd ..

    # Wait for Flutter to detect the device
    info "Waiting for Flutter to detect iOS simulator..."
    local timeout=60
    local waited=0
    local flutter_device_id=""

    while (( waited < timeout )); do
        local devices_output=$(flutter devices 2>/dev/null || true)

        # Look for device with UDID
        if echo "$devices_output" | grep -F "$device_udid" >/dev/null 2>&1; then
            flutter_device_id=$(echo "$devices_output" | grep -F "$device_udid" | head -1 | awk '{print $1}')
            break
        fi

        # Fallback: look for any iPhone device
        if echo "$devices_output" | grep -E "iPhone.*\(mobile\)" >/dev/null 2>&1; then
            flutter_device_id=$(echo "$devices_output" | grep -E "iPhone.*\(mobile\)" | head -1 | awk '{print $1}')
            break
        fi

        sleep 2
        waited=$((waited + 2))
    done

    if [[ -n "$flutter_device_id" ]]; then
        info "Running Flutter on device: $flutter_device_id"
        flutter run -d "$flutter_device_id"
    else
        warn "No iOS device found by Flutter, trying without device specification..."
        flutter run
    fi
}

# Stop backend containers
stop_backend() {
    info "Stopping all services..."
    docker compose down
    success "All services stopped"
}

# Check backend status
check_backend_status() {
    info "Checking services status..."

    # Check if docker compose is running
    if ! docker compose ps >/dev/null 2>&1; then
        warn "Docker compose not available or no services running"
        return
    fi

    docker compose ps

    echo ""
    info "Service URLs:"

    if nc -z localhost 8000 2>/dev/null; then
        success "Supabase API: http://localhost:8000 (accessible)"
    else
        warn "Supabase API: http://localhost:8000 (not accessible)"
    fi

    if nc -z localhost 8001 2>/dev/null; then
        success "Backend API: http://localhost:8001 (accessible)"
    else
        warn "Backend API: http://localhost:8001 (not accessible)"
    fi

    if nc -z localhost 3000 2>/dev/null; then
        success "Supabase Studio: http://localhost:3000 (accessible)"
    else
        warn "Supabase Studio: http://localhost:3000 (not accessible)"
    fi

    if nc -z localhost 5432 2>/dev/null; then
        success "PostgreSQL: localhost:5432 (accessible)"
    else
        warn "PostgreSQL: localhost:5432 (not accessible)"
    fi
}

# Show usage
usage() {
    cat <<EOF
Usage: ./start_phoenix.sh [mode] [options]

Script to start Supabase, Backend and iOS app.

Modes:
    backend       Start only backend services (Supabase + FastAPI)
    ios           Start only iOS Flutter app (requires backend running)
    both          Start backend and iOS app (default)
    stop          Stop all services
    status        Check status of services

Options:
  -h, --help     Show this help

Examples:
    ./start_phoenix.sh                # Start all services and iOS app (default)
    ./start_phoenix.sh backend        # Start only backend services
    ./start_phoenix.sh ios            # Start only iOS app
    ./start_phoenix.sh stop           # Stop all services
    ./start_phoenix.sh status         # Check status

EOF
}

# Parse arguments
MODE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        backend|ios|both|stop|status)
            if [[ -z "$MODE" ]]; then
                MODE="$1"
                shift
            else
                err "Multiple modes specified. Use only one mode."
                exit 1
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            err "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

# Set default mode if none specified
[[ -z "$MODE" ]] && MODE="both"

# Main execution
main() {
    case "$MODE" in
        backend)
            info "🚀 Starting backend services (Supabase + FastAPI)"
            check_deps
            ensure_runtime_dirs
            start_backend
            ;;
        ios)
            info "📱 Starting iOS app"
            check_deps

            # Check if backend is running first
            if ! nc -z localhost 8000 2>/dev/null; then
                err "Supabase is not running. Start it first with: ./start_phoenix.sh backend"
                exit 1
            fi

            local device_udid
            device_udid=$(detect_ios_device)
            start_ios_simulator "$device_udid"
            start_flutter "$device_udid"
            ;;
        both)
            info "🚀 Starting all services (Supabase + Backend + iOS)"
            check_deps
            ensure_runtime_dirs
            start_backend

            local device_udid
            device_udid=$(detect_ios_device)
            start_ios_simulator "$device_udid"
            start_flutter "$device_udid"
            ;;
        stop)
            stop_backend
            ;;
        status)
            check_backend_status
            ;;
        *)
            err "Invalid mode: $MODE"
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
