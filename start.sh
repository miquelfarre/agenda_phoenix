#!/usr/bin/env bash
set -euo pipefail

# start.sh - Script for backend and iOS startup with persistent containers
# Adapted for Agenda Phoenix v2.0.0
# Defaults: USER_ID=2 (Miquel), Platform=iOS, DB Script=init_db.py
# Features: Auto-cleans Hive database on each start

VERSION="2.0.0"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_ID=${USER_ID:-2}
DB_SCRIPT=${DB_SCRIPT:-init_db.py}
MODE=${1:-both}  # Can be: backend, ios, both, stop, status

# Paths for PID and logs
PID_DIR="$ROOT_DIR/.pids"
LOG_DIR="$ROOT_DIR/.logs"

# Colors
c_reset='\033[0m'; c_red='\033[0;31m'; c_green='\033[0;32m'; c_yellow='\033[0;33m'; c_blue='\033[0;34m'

log() { printf "%b[start]%b %s\n" "$c_blue" "$c_reset" "$1" >&2; }
info() { log "$1"; }
success() { printf "%b[✔]%b %s\n" "$c_green" "$c_reset" "$1" >&2; }
warn() { printf "%b[!]%b %s\n" "$c_yellow" "$c_reset" "$1" >&2; }
err() { printf "%b[x]%b %s\n" "$c_red" "$c_reset" "$1" >&2; }

# Check dependencies
check_deps() {
    local MISSING=0
    for cmd in docker python3 flutter xcrun; do
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

# Generic helpers for background processes
is_pid_running() {
    local pid_file="$1"
    [[ -f "$pid_file" ]] || return 1
    local pid
    pid=$(cat "$pid_file" 2>/dev/null || echo "")
    [[ -n "$pid" ]] || return 1
    if ps -p "$pid" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

kill_if_running() {
    local name="$1" pid_file="$2"
    if is_pid_running "$pid_file"; then
        local pid
        pid=$(cat "$pid_file")
        info "Stopping $name (pid=$pid)"
        kill "$pid" >/dev/null 2>&1 || true
        # Give it a moment, then force kill if needed
        sleep 1
        if ps -p "$pid" >/dev/null 2>&1; then
            kill -9 "$pid" >/dev/null 2>&1 || true
        fi
        rm -f "$pid_file"
        success "$name stopped"
    fi
}

# Start backend services (persistent containers)
start_backend() {
    info "Starting backend services (Agenda Phoenix v2.0.0)..."

    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        err "Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi

    # Always do a clean restart to ensure environment variables are updated
    info "Ensuring clean state (stopping any existing containers)..."
    docker compose down >/dev/null 2>&1 || true

    # Check if port 8001 is still in use by something else
    if lsof -Pi :8001 -sTCP:LISTEN -t >/dev/null 2>&1; then
        err "Port 8001 is occupied by another process (not our containers)."
        info "Process using port 8001:"
        lsof -Pi :8001 -sTCP:LISTEN || true
        info "Please stop the process manually"
        exit 1
    fi

    # Build backend image if needed
    info "Building backend Docker image..."
    docker compose build backend

    # Start database and backend in detached mode
    info "Starting PostgreSQL and Backend in Docker (detached mode)..."
    success "⚙️  FastAPI Backend on port 8001"
    INIT_SCRIPT="$DB_SCRIPT" docker compose up -d db backend

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

    # Wait for backend to be ready
    info "Waiting for backend to be ready..."
    timeout=60
    start=$(date +%s)

    while ! nc -z localhost 8001 2>/dev/null; do
        sleep 2
        if (( $(date +%s) - start > timeout )); then
            err "Timeout waiting for backend on port 8001"
            exit 1
        fi
    done

    success "Backend ready at http://localhost:8001"
    info "Backend running in Docker container"
    info "API Docs: http://localhost:8001/docs"
    info ""
    info "Use './start.sh stop' to stop the backend containers"
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

    # If none booted, select first available iPhone device and return its UDID
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
        # Wait for simulator to boot completely
        if ! xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1; then
            # If bootstatus doesn't work, give reasonable wait time
            sleep 4
        fi
    fi

    # Open Simulator app if not open
    if ! pgrep -f "Simulator.app" >/dev/null; then
        info "Opening Simulator.app..."
        open -a Simulator 2>/dev/null || warn "Could not open Simulator.app automatically"
        # Wait for app to open
        sleep 2
    fi
}

# Clean Hive database by uninstalling the app
clean_hive_data() {
    local device_udid="$1"

    info "Cleaning Hive database (uninstalling app from simulator)..."

    # Get bundle identifier
    local bundle_id="com.eventypop.app"

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

    info "Starting Flutter app with USER_ID=$USER_ID..."

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

    # Generate localizations (always regenerate)
    info "Generating localizations..."
    flutter gen-l10n >/dev/null

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
        flutter run -d "$flutter_device_id" --dart-define=USER_ID="$USER_ID"
    else
        warn "No iOS device found by Flutter, trying without device specification..."
        flutter run --dart-define=USER_ID="$USER_ID"
    fi
}

# Stop backend containers
stop_backend() {
    info "Stopping backend containers..."
    docker compose down
    success "Backend containers stopped"
}

# Check backend status
check_backend_status() {
    local backend_status=""
    local db_status=""

    if docker compose ps -q backend >/dev/null 2>&1; then
        backend_status=$(docker compose ps backend --format "{{.State}}")
    fi

    if docker compose ps -q db >/dev/null 2>&1; then
        db_status=$(docker compose ps db --format "{{.State}}")
    fi

    info "Backend Status:"
    info "  Database: ${db_status:-not running}"
    info "  Backend:  ${backend_status:-not running}"

    if [[ "$backend_status" == "running" ]]; then
        if nc -z localhost 8001 2>/dev/null; then
            success "Backend is accessible at http://localhost:8001"
        else
            warn "Backend container running but not accessible on port 8001"
        fi
    fi
}

# Show usage
usage() {
    cat <<EOF
Usage: ./start.sh [mode] [options]

Script to start Agenda Phoenix backend and iOS app with persistent containers.

Modes:
    backend       Start only backend containers (persistent)
    ios           Start only iOS Flutter app (requires backend running)
    both          Start backend and iOS app (default)
    stop          Stop backend containers
    status        Check status of backend

Options:
  -h, --help     Show this help
  -u, --user-id  USER_ID (default: 1)
  -s, --script   Database script (default: init_db.py)

Environment variables:
  USER_ID        User ID to use (default: 1)
  DB_SCRIPT      Database script to run (default: init_db.py)

Examples:
    ./start.sh                    # Start backend and iOS app (default)
    ./start.sh backend            # Start only backend (persistent)
    ./start.sh ios                # Start only iOS app
    ./start.sh stop               # Stop backend containers
    ./start.sh status             # Check status of backend
    ./start.sh -u 42              # USER_ID=42
    ./start.sh backend -s custom_db.py   # Custom database script

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
        -u|--user-id)
            if [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]]; then
                USER_ID="$2"
                shift 2
            else
                err "The --user-id argument requires a valid number"
                exit 1
            fi
            ;;
        -s|--script)
            if [[ -n "${2:-}" ]]; then
                DB_SCRIPT="$2"
                shift 2
            else
                err "The --script argument requires a script name"
                exit 1
            fi
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
            info "🚀 Starting backend containers (USER_ID=$USER_ID, DB_SCRIPT=$DB_SCRIPT)"
            check_deps
            start_backend
            ;;
        ios)
            info "📱 Starting iOS app (USER_ID=$USER_ID)"
            check_deps

            # Check if backend is running first
            if ! nc -z localhost 8001 2>/dev/null; then
                err "Backend is not running. Start it first with: ./start.sh backend"
                exit 1
            fi

            local device_udid
            device_udid=$(detect_ios_device)
            start_ios_simulator "$device_udid"
            start_flutter "$device_udid"
            ;;
        both)
            info "🚀 Starting backend and iOS app (USER_ID=$USER_ID, DB_SCRIPT=$DB_SCRIPT)"
            check_deps
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
