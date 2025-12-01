#!/bin/bash

set -e  # exit on error

# ---------------------------------------------------------
# FIX PATH FOR MACOS (Finder has a broken PATH)
# ---------------------------------------------------------
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Resolve script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🚀 Starting Databases + Adminer Setup..."

# -------------------------------
# CHECK DOCKER
# -------------------------------
check_docker() {
    if ! docker info > /dev/null 2>&1; then
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
    until docker exec postgres pg_isready -U admin > /dev/null 2>&1; do
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
# CHECK PYTHON + PAHO MQTT
# -------------------------------
check_python_requirements() {
    echo "🐍 Checking Python environment..."
    # Locate python3
    PYTHON_BIN=""
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_BIN="$(command -v python3)"
    elif [ -x "/opt/homebrew/bin/python3" ]; then
        PYTHON_BIN="/opt/homebrew/bin/python3"
    elif [ -x "/usr/bin/python3" ]; then
        PYTHON_BIN="/usr/bin/python3"
    fi

    # If Python3 not found try common package managers to install it (best-effort)
    if [ -z "$PYTHON_BIN" ]; then
        echo "⚠️  Python3 was not found. Attempting to install Python3 automatically..."

        if command -v brew >/dev/null 2>&1; then
            echo "   -> Installing Python3 using Homebrew (requires Homebrew and network)..."
            brew update || true
            brew install python || true
        elif command -v apt-get >/dev/null 2>&1; then
            echo "   -> Installing Python3 using apt-get (requires sudo)..."
            sudo apt-get update && sudo apt-get install -y python3 python3-venv python3-pip || true
        elif command -v dnf >/dev/null 2>&1; then
            echo "   -> Installing Python3 using dnf (requires sudo)..."
            sudo dnf install -y python3 python3-venv python3-pip || true
        elif command -v yum >/dev/null 2>&1; then
            echo "   -> Installing Python3 using yum (requires sudo)..."
            sudo yum install -y python3 python3-venv python3-pip || true
        elif command -v pacman >/dev/null 2>&1; then
            echo "   -> Installing Python3 using pacman (requires sudo)..."
            sudo pacman -S --noconfirm python || true
        else
            echo "\nCould not detect a supported package manager to auto-install Python3."
            echo "Please install Python 3 manually and re-run this script. Suggestions:" 
            echo "  - macOS (Homebrew): /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"; brew install python"
            echo "  - Ubuntu/Debian: sudo apt-get update && sudo apt-get install -y python3 python3-venv python3-pip"
            echo "  - CentOS/Fedora: sudo dnf install -y python3"
            exit 1
        fi

        # re-detect python after attempted install
        if command -v python3 >/dev/null 2>&1; then
            PYTHON_BIN="$(command -v python3)"
        fi
    fi

    if [ -z "$PYTHON_BIN" ]; then
        echo "❌ Python3 is not installed or could not be installed automatically."
        exit 1
    fi

    echo "📌 Using Python at: $PYTHON_BIN"

    REQ="$SCRIPT_DIR/mqtt_bridge/requirements.txt"
    if [ ! -f "$REQ" ]; then
        echo "❌ requirements.txt NOT FOUND at: $REQ"
        exit 1
    fi

    # Ensure pip is available for this Python
    if ! "$PYTHON_BIN" -m pip --version >/dev/null 2>&1; then
        echo "   -> pip not found for $PYTHON_BIN; trying to bootstrap pip..."
        if "$PYTHON_BIN" -m ensurepip >/dev/null 2>&1; then
            echo "   -> ensurepip succeeded"
        else
            echo "   -> ensurepip failed; attempting get-pip.py"
            curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py || true
            "$PYTHON_BIN" /tmp/get-pip.py || true
        fi
    fi

    # Install (or upgrade) all requirements unconditionally — pip is idempotent
    echo "📦 Installing Python requirements from $REQ..."
    "$PYTHON_BIN" -m pip install --upgrade pip
    "$PYTHON_BIN" -m pip install -r "$REQ"
    echo "✅ Python requirements installed (or already satisfied)."
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
