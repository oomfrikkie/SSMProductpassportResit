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
    until docker exec mariadb mysqladmin ping -uadmin -padminpassword --silent >/dev/null 2>&1; do
        echo "   MariaDB not ready yet..."
        sleep 2
    done
    echo "✅ MariaDB is ready!"
}

check_python_requirements() {
    echo "🐍 Checking Python environment..."

    if command -v python3 >/dev/null 2>&1; then
        PYTHON_BIN="python3"
    elif command -v python >/dev/null 2>&1; then
        PYTHON_BIN="python"
    elif command -v python.exe >/dev/null 2>&1; then
        PYTHON_BIN="python.exe"
    else
        echo "❌ No Python found."
        exit 1
    fi

    echo "📌 Using Python at: $PYTHON_BIN"

    REQ="$SCRIPT_DIR/mqtt_bridge/requirements.txt"

    if [ ! -f "$REQ" ]; then
        echo "❌ requirements.txt NOT FOUND!"
        exit 1
    fi

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
    echo "📦 MariaDB running at localhost:3306"
    echo "🌐 Adminer UI at http://localhost:8080"
    echo ""
}

main "$@"
