#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🚀 Starting Databases + Adminer Setup..."

check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker is not running."
        exit 1
    fi
}

start_stack() {
    echo "🐳 Starting Docker Compose stack..."
    docker compose up -d
    echo "⏳ Waiting for containers to start..."
}

wait_for_postgres() {
    echo "🔍 Checking Postgres..."
    until docker exec postgres pg_isready -U admin >/dev/null 2>&1; do
        echo "   Postgres not ready yet..."
        sleep 2
    done
    echo "✅ Postgres is ready!"
}

wait_for_mariadb() {
    echo "🔍 Checking MariaDB..."
    # Some MariaDB images do not include client tools like `mysqladmin`.
    # Use a host TCP probe to port 3306 and also grep container logs
    # for the 'ready for connections' message as a fallback.
    local attempts=0
    local max_attempts=60
    while true; do
        attempts=$((attempts+1))

        # 1) Fast TCP check from host to mapped port
        if bash -c "</dev/tcp/127.0.0.1/3307" >/dev/null 2>&1; then
            echo "✅ MariaDB TCP port is open (localhost:3307)."
            break
        fi

        # 2) Check container logs for a ready message (helpful inside Docker)
        if docker compose logs mariadb --no-color --tail=200 2>/dev/null | grep -i -m1 "ready for connections" >/dev/null 2>&1; then
            echo "✅ MariaDB reports 'ready for connections' in container logs."
            break
        fi

        echo "   MariaDB not ready yet... (attempt ${attempts}/${max_attempts})"

        if [ "$attempts" -ge "$max_attempts" ]; then
            echo "❌ MariaDB did not become ready after ${max_attempts} attempts. Showing last 400 lines of logs:"
            docker compose logs mariadb --no-color --tail=400 || true
            exit 1
        fi

        sleep 2
    done
}

check_python_requirements() {
    echo "🐍 Checking Python environment..."
    # Try multiple common python executables and verify they are usable Python 3 interpreters.
    local candidates=("python3" "python" "python.exe" "py")
    PYTHON_BIN=""

    for c in "${candidates[@]}"; do
        if command -v "$c" >/dev/null 2>&1; then
            if [ "$c" = "py" ]; then
                # Use the py launcher with -3 to request Python 3
                if py -3 -c "import sys; sys.exit(0)" >/dev/null 2>&1; then
                    PYTHON_BIN="py -3"
                    break
                fi
            else
                # Verify the candidate runs and is Python 3
                if "$c" -c "import sys; sys.exit(0)" >/dev/null 2>&1; then
                    ver=$("$c" -c "import sys; print(sys.version_info[0])" 2>/dev/null || true)
                    if [ "$ver" = "3" ]; then
                        PYTHON_BIN="$c"
                        break
                    fi
                fi
            fi
        fi
    done

    if [ -z "$PYTHON_BIN" ]; then
        echo "❌ No usable Python 3 interpreter found."
        echo "   Install Python 3 and ensure it's on PATH, or disable the Microsoft Store 'App execution aliases' for Python."
        echo "   Download: https://www.python.org/downloads/"
        exit 1
    fi

    echo "📌 Using Python at: $PYTHON_BIN"

    REQ="$SCRIPT_DIR/mqtt_bridge/requirements.txt"

    if [ ! -f "$REQ" ]; then
        echo "❌ requirements.txt NOT FOUND!"
        exit 1
    fi

    # Upgrade pip where possible
    $PYTHON_BIN -m pip install --upgrade pip >/dev/null 2>&1 || true

    echo "📦 Installing Python requirements..."
    $PYTHON_BIN -m pip install -r "$REQ"

    echo "✅ Python requirements installed."
}

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
    echo "📦 MariaDB running at localhost:3307"
    echo "🌐 Adminer UI at http://localhost:8080"
    echo ""
}

main "$@"
