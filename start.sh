#!/bin/bash

# Generic MCP Server Start Script
# This script kills any running instances and starts the server fresh

set -e  # Exit on any error

echo "🚀 Starting Generic MCP Server..."

# Function to kill existing processes
kill_existing_processes() {
    echo "🔍 Looking for existing MCP server processes..."
    
    # Find and kill any Java processes running the MCP server
    PIDS=$(ps aux | grep "generic-mcp-server" | grep -v grep | awk '{print $2}')
    
    if [ ! -z "$PIDS" ]; then
        echo "🛑 Found existing processes: $PIDS"
        echo "$PIDS" | xargs kill -9 2>/dev/null || true
        echo "✅ Killed existing processes"
        sleep 2  # Give processes time to fully terminate
    else
        echo "ℹ️  No existing processes found"
    fi
}

# Function to build the project
build_project() {
    echo "🔨 Building project..."
    ./mvnw clean package -DskipTests
    echo "✅ Build completed"
}

# Function to start the server
start_server() {
    echo "🚀 Starting MCP server..."
    echo "📝 Server will be ready to accept stdio connections"
    echo "💡 Use Ctrl+C to stop the server"
    echo ""
    echo "=" * 50
    echo "MCP SERVER STARTED - Waiting for stdio input..."
    echo "=" * 50
    echo ""
    
    # Run the server
    java -jar target/generic-mcp-server-1.0.0.jar
}

# Main execution
main() {
    echo "🎯 Generic MCP Server Startup Script"
    echo "====================================="
    echo ""
    
    # Kill existing processes
    kill_existing_processes
    
    # Build the project
    build_project
    
    # Start the server
    start_server
}

# Run the main function
main "$@" 