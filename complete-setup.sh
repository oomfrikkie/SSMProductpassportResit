#!/bin/bash

# Complete Dgraph Setup Script
# This script loads images, starts containers, and initializes the database

set -e  # Exit on any error

echo "🚀 Complete Dgraph Setup Starting..."

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to load images if they don't exist
load_images_if_needed() {
    echo "🔍 Checking for required Docker images..."
    
    if ! docker image inspect dgraph/dgraph:v24.1.3 > /dev/null 2>&1; then
        echo "📦 Loading dgraph image..."
        if [ -f "dgraph_v24.1.3.tgz" ]; then
            docker load -i dgraph_v24.1.3.tgz
            docker tag dgraph/dgraph:latest dgraph/dgraph:v24.1.3
        else
            echo "❌ dgraph_v24.1.3.tgz not found!"
            exit 1
        fi
    else
        echo "✅ dgraph/dgraph:v24.1.3 already exists"
    fi
    
    if ! docker image inspect dgraph/ratel:v24.1.3 > /dev/null 2>&1; then
        echo "📦 Loading ratel image..."
        if [ -f "ratel_v24.1.3.tgz" ]; then
            docker load -i ratel_v24.1.3.tgz
            docker tag dgraph/ratel:latest dgraph/ratel:v24.1.3
        else
            echo "❌ ratel_v24.1.3.tgz not found!"
            exit 1
        fi
    else
        echo "✅ dgraph/ratel:v24.1.3 already exists"
    fi
}

# Function to start the stack
start_stack() {
    echo "🐳 Starting Docker Compose stack..."
    docker compose up -d
    
    echo "⏳ Waiting for services to be ready..."
    sleep 10 # Wait for services to stabilize
}

# Function to initialize database (original setup-database.sh content)
initialize_database() {
    echo "🗃️ Initializing database schema and data..."
    
    # Wait for Dgraph to be ready...
    echo "⏳ Waiting for Dgraph to be ready..."
    until curl -f http://localhost:8080/health > /dev/null 2>&1; do 
        echo "   Still waiting for Dgraph..."
        sleep 2
    done
    
    echo "✅ Dgraph is ready!"
    
    # Load schema
    if [ -f "data/schema/schema.graphql" ]; then
        echo "📋 Loading schema..."
        curl -X POST http://localhost:8080/admin/schema --data-binary '@data/schema/schema.graphql'
        echo "✅ Schema loaded successfully"
    else
        echo "⚠️  Schema file not found, skipping..."
    fi
    
    # Load data
    if [ -f "data/import/data.json" ]; then
        echo "📊 Loading initial data..."
        curl -X POST http://localhost:8080/mutate?commitNow=true -H "Content-Type: application/json" -d @data/import/data.json
        echo "✅ Data loaded successfully"
    else
        echo "⚠️  Data file not found, skipping..."
    fi
}

# Main execution
main() {
    check_docker
    load_images_if_needed
    start_stack
    initialize_database
    
    echo ""
    echo "🎉 Dgraph stack is fully initialized and ready!"
    echo "📊 Ratel UI: http://localhost:8000"
    echo "🔍 Dgraph Alpha API: http://localhost:8080"
    echo "🩺 Health Check: http://localhost:8080/health"
    echo ""
    echo "Useful commands:"
    echo "  View logs: docker compose logs -f"
    echo "  Stop stack: docker compose down"
    echo "  Restart: ./complete-setup.sh"
}

# Run main function
main "$@"

# Keep the window open - wait for user input before closing
echo ""
echo "Press any key to close this window..."
read -n 1 -s