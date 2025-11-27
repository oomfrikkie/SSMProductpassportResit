#!/bin/bash

# Complete Postgres Setup Script
# Brings up Docker Compose and waits for Postgres to be ready

set -e  # Exit on error

echo "🚀 Starting Postgres + pgAdmin Setup..."

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker is not running. Start Docker Desktop and try again."
        exit 1
    fi
}

# Start Docker Compose
start_stack() {
    echo "🐳 Starting Docker Compose stack..."
    docker compose up -d

    echo "⏳ Waiting for Postgres to start..."
}

# Wait for Postgres health check
wait_for_postgres() {
    until docker exec postgres pg_isready -U admin > /dev/null 2>&1; do
        echo "   Postgres not ready yet..."
        sleep 2
    done

    echo "✅ Postgres is ready!"
}

main() {
    check_docker
    start_stack
    wait_for_postgres

    echo ""
    echo "🎉 Stack is ready!"
    echo "📦 Postgres: localhost:5432"
    echo "🌐 pgAdmin: http://localhost:5050"
    echo "   Email: admin@admin.com"
    echo "   Password: adminpassword"
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
