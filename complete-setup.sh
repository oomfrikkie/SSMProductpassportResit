#!/bin/bash

# Complete Setup Script: Postgres + MariaDB + Adminer + Python MQTT Bridge
# ----------------------------------------------------------------------

set -e  # Exit on error

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
    until docker exec mariadb mysqladmin ping -uadmin -padminpassword --silent > /dev/null 2>&1; do
        echo "   MariaDB not ready yet..."
        sleep 2
    done
    echo "✅ MariaDB is ready!"
}

# -------------------------------
# CHECK PYTHON + PAHO MQTT
# -------------------------------
check_python_requirements() {
    echo "🐍 Checking Python environment..."

    if ! command -v python3 >/dev/null 2>&1; then
        echo "❌ Python3 is not installed. Install Python 3 first."
        exit 1
    fi

    if ! python3 -c "import paho.mqtt.client" 2>/dev/null; then
        echo "📦 Installing paho-mqtt..."
        pip3 install -r mqtt_bridge/requirements.txt

        echo "✅ Installed paho-mqtt"
    else
        echo "✅ paho-mqtt already installed"
    fi
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
    echo "📦 Postgres running at:"
    echo "    host: localhost"
    echo "    port: 5432"
    echo "    user: admin"
    echo "    pass: adminpassword"
    echo "    DB:   testdb"
    echo ""
    echo "📦 MariaDB running at:"
    echo "    host: localhost"
    echo "    port: 3306"
    echo "    user: admin"
    echo "    pass: adminpassword"
    echo "    DB:   mariadb_testdb"
    echo ""
    echo "🌐 Adminer UI:"
    echo "    http://localhost:8080"
    echo ""
    echo "🟢 Use 'postgres' or 'mariadb' in the Adminer dropdown"
    echo ""
    echo "Useful commands:"
    echo "  docker compose logs -f"
    echo "  docker compose down"
    echo "  docker compose up -d"
    echo ""
}

main "$@"

echo ""
echo "Press any key to close this window..."
read -n 1 -s
