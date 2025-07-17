#!/bin/bash

# =============================================
# Stop Script for Generic MCP Server
# =============================================
# This script stops all running instances of the Generic MCP Server
# by finding and killing Java processes running the server jar file.

set -e

JAR_NAME="generic-mcp-server-1.0.0.jar"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🛑 Stopping Generic MCP Server..."

# Find and kill processes running the server jar
PIDS=$(pgrep -f "$JAR_NAME" || true)

if [ -z "$PIDS" ]; then
    echo "✅ No running Generic MCP Server instances found."
else
    echo "📋 Found running instances with PIDs: $PIDS"
    
    # Kill each process
    for PID in $PIDS; do
        echo "🔪 Stopping process $PID..."
        kill "$PID" 2>/dev/null || true
        
        # Wait a moment for graceful shutdown
        sleep 2
        
        # Force kill if still running
        if kill -0 "$PID" 2>/dev/null; then
            echo "⚡ Force stopping process $PID..."
            kill -9 "$PID" 2>/dev/null || true
        fi
    done
    
    echo "✅ All Generic MCP Server instances stopped."
fi

echo "🏁 Stop script completed."