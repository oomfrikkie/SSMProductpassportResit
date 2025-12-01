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

    attempts=0
    max_attempts=60

    # Wait until either the published TCP port responds (host-level check) or
    # the container logs explicitly show the server is "ready for connections".
    until ( nc -z 127.0.0.1 3306 >/dev/null 2>&1 ) || \
          ( docker compose logs --tail=200 mariadb | grep -q "ready for connections" ); do
        # If container isn't running, show recent logs to help debugging
        if ! docker ps --format '{{.Names}}' | grep -q '^mariadb$'; then
            echo "   MariaDB container is not running. Showing last logs..."
            docker compose logs --tail=50 mariadb || true
        else
            echo "   MariaDB not ready yet (attempt $((attempts+1))/$max_attempts)..."
        fi

        attempts=$((attempts+1))
        if [ "$attempts" -ge "$max_attempts" ]; then
            echo "❌ MariaDB did not become ready after $max_attempts attempts. Showing logs and exiting."
            docker compose logs --tail=200 mariadb || true
            exit 1
        fi

        sleep 2
    done

    echo "✅ MariaDB is ready (TCP or logs indicate readiness)!"
}



# -------------------------------
# CHECK PYTHON + PAHO MQTT
# -------------------------------
# -------------------------------
# CHECK PYTHON + PAHO MQTT
# -------------------------------
check_python_requirements() {
    echo "🐍 Checking Python environment..."

    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    if ! command -v python3 >/dev/null 2>&1; then
        echo "❌ Python3 is not installed. Install Python 3 first."
        exit 1
    fi

    REQ="$SCRIPT_DIR/mqtt_bridge/requirements.txt"

    if ! python3 -c "import paho.mqtt.client" 2>/dev/null; then
        echo "📦 Installing paho-mqtt..."
        python3 -m pip install -r "$REQ"
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
