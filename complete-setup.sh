#!/bin/bash

set -e  # exit on error

# Resolve script directory (works on macOS/Linux/Windows Git Bash)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🚀 Starting Databases + Adminer Setup..."

# -------------------------------
# CHECK DOCKER
# -------------------------------
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker is not running. Start Docker Desktop and try again."
        exit 1
    fi
}

# -------------------------------
# START DOCKER COMPOSE
# -------------------------------
start_stack() {
    echo "🐳 Starting Docker Compose stack..."
    docker compose up -d
    echo "⏳ Waiting for containers to start..."
}

# -------------------------------
# WAIT FOR POSTGRES
# -------------------------------
wait_for_postgres() {
    echo "🔍 Checking Postgres..."
    until docker exec postgres pg_isready -U admin >/dev/null 2>&1; do
        echo "   Postgres not ready yet..."
        sleep 2
    done
    echo "✅ Postgres is ready!"
}

# -------------------------------
# WAIT FOR MARIADB
# -------------------------------
wait_for_mariadb() {
    echo "🔍 Checking MariaDB..."

    attempts=0
    max_attempts=60

    until ( nc -z 127.0.0.1 3306 >/dev/null 2>&1 ) || \
          ( docker compose logs --tail=200 mariadb | grep -q "ready for connections" ); do

        if ! docker ps --format '{{.Names}}' | grep -q '^mariadb$'; then
            echo "   MariaDB container is not running. Showing last logs..."
            docker compose logs --tail=50 mariadb || true
        else
            echo "   MariaDB not ready yet (attempt $((attempts+1))/$max_attempts)..."
        fi

        attempts=$((attempts+1))
        if [ "$attempts" -ge "$max_attempts" ]; then
            echo "❌ MariaDB did not become ready after $max_attempts attempts."
            docker compose logs --tail=200 mariadb || true
            exit 1
        fi

        sleep 2
    done

    echo "✅ MariaDB is ready!"
}

# -------------------------------
# UNIVERSAL PYTHON + REQUIREMENTS
# -------------------------------
check_python_requirements() {
    echo "🐍 Checking Python environment..."

    PYTHON_BIN=""

    # ----- WINDOWS -----
    if command -v python.exe >/dev/null 2>&1; then
        PYTHON_BIN="$(command -v python.exe)"
    elif command -v python >/dev/null 2>&1; then
        PYTHON_BIN="$(command -v python)"
    fi

    # ----- MAC + LINUX -----
    if [ -z "$PYTHON_BIN" ]; then
        if command -v python3 >/dev/null 2>&1; then
            PYTHON_BIN="python3"
        elif [ -x "/usr/bin/python3" ]; then
            PYTHON_BIN="/usr/bin/python3"
        elif [ -x "/opt/homebrew/bin/python3" ]; then
            PYTHON_BIN="/opt/homebrew/bin/python3"
        fi
    fi

    if [ -z "$PYTHON_BIN" ]; then
        echo "❌ No valid Python installation found."
        exit 1
    fi

    echo "📌 Using Python at: $PYTHON_BIN"

    REQ="$SCRIPT_DIR/mqtt_bridge/requirements.txt"
    if [ ! -f "$REQ" ]; then
        echo "❌ requirements.txt NOT FOUND at: $REQ"
        exit 1
    fi

    if ! "$PYTHON_BIN" -m pip --version >/dev/null 2>&1; then
        echo "⚠️ pip missing — installing..."
        "$PYTHON_BIN" -m ensurepip --default-pip || true
    fi

    echo "📦 Installing Python requirements..."
    "$PYTHON_BIN" -m pip install -r "$REQ"
    echo "✅ Python requirements installed."
}


# -------------------------------
# MAIN
# -------------------------------
main() {
    check_docker
    start_stack
    wait_for_postgres
    wait_for_mariadb
    check_python_requirements

    echo ""
    echo "🎉 Everything is ready!"
    echo "==============================="
    echo "📦 Postgres running at localhost:5432"
    echo "📦 MariaDB running at localhost:3306"
    echo "🌐 Adminer UI at http://localhost:8080"
    echo ""
    echo "Useful commands:"
    echo "  docker compose logs -f"
    echo "  docker compose down"
    echo "  docker compose up -d"
}

main "$@"

echo ""
echo "Press any key to close this window..."
read -n 1 -s
