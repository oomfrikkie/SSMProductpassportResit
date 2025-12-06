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
    local attempts=0
    local max_attempts=60

    while true; do
        attempts=$((attempts+1))

        if bash -c "</dev/tcp/127.0.0.1/3307" >/dev/null 2>&1; then
            echo "✅ MariaDB TCP port is open (localhost:3307)."
            break
        fi

        if docker compose logs mariadb --tail=80 | grep -qi "ready for connections"; then
            echo "✅ MariaDB is ready (log check)."
            break
        fi

        echo "   MariaDB not ready... (${attempts}/${max_attempts})"

        if [ "$attempts" -ge "$max_attempts" ]; then
            echo "❌ MariaDB failed to start."
            docker compose logs mariadb --tail=200
            exit 1
        fi

        sleep 2
    done
}

create_venv_and_install() {
    echo "🐍 Preparing Python environment..."

    REQ="$SCRIPT_DIR/mqtt_bridge/requirements.txt"
    if [ ! -f "$REQ" ]; then
        echo "❌ requirements.txt NOT FOUND!"
        exit 1
    fi

    if [ ! -d "$SCRIPT_DIR/.venv" ]; then
        echo "📦 Creating new virtual environment (.venv)..."
        python3 -m venv "$SCRIPT_DIR/.venv"
    fi

    echo "📌 Activating virtual environment..."
    source "$SCRIPT_DIR/.venv/bin/activate"

    echo "📦 Installing Python requirements..."
    pip install --upgrade pip setuptools wheel
    pip install -r "$REQ"

    echo "✅ Python virtual environment ready!"
}

main() {
    check_docker
    start_stack
    wait_for_postgres
    wait_for_mariadb
    create_venv_and_install

    echo ""
    echo "🎉 Everything is ready!"
    echo "==============================="
    echo "📦 Postgres: localhost:5432"
    echo "📦 MariaDB : localhost:3307"
    echo "🌐 Adminer : http://localhost:8080"
    echo "🐍 Python venv created at: $SCRIPT_DIR/.venv"
    echo ""
}

main "$@"
