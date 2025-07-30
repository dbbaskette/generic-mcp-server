#!/bin/bash

# Generic MCP Server Management Script
# Usage: ./mcp-server.sh [--stdio|--sse] [start|stop|restart|status] [--no-build] [--help]

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
TRANSPORT_MODE=""
ACTION=""
BUILD_PROJECT=true
SHOW_HELP=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --sse)
            TRANSPORT_MODE="sse"
            shift
            ;;
        --stdio)
            TRANSPORT_MODE="stdio"
            shift
            ;;
        start|stop|restart|status)
            ACTION="$1"
            shift
            ;;
        --no-build)
            BUILD_PROJECT=false
            shift
            ;;
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            SHOW_HELP=true
            shift
            ;;
    esac
done

# Help function
show_help() {
    echo "Generic MCP Server Management Script"
    echo "===================================="
    echo ""
    echo "Usage: ./mcp-server.sh [TRANSPORT] [ACTION] [OPTIONS]"
    echo ""
    echo "Transport Modes (REQUIRED):"
    echo "  --stdio     STDIO mode for Claude Desktop integration"
    echo "              - Communicates via standard input/output"
    echo "              - No web server running"
    echo ""
    echo "  --sse       SSE mode for web client integration"
    echo "              - Server-Sent Events transport"
    echo "              - Web server on port 8082"
    echo "              - Endpoint: http://localhost:8082/mcp"
    echo ""
    echo "Actions (REQUIRED):"
    echo "  start       Start the MCP server"
    echo "  stop        Stop any running MCP server processes"
    echo "  restart     Stop then start the MCP server"
    echo "  status      Check if the server is running"
    echo ""
    echo "Build Options:"
    echo "  --no-build  Skip the Maven build step"
    echo ""
    echo "Other Options:"
    echo "  --help, -h  Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./mcp-server.sh --stdio start           # Start in STDIO mode"
    echo "  ./mcp-server.sh --sse start --no-build  # Start SSE mode, skip build"
    echo "  ./mcp-server.sh --stdio restart         # Restart STDIO server"
    echo "  ./mcp-server.sh --sse stop              # Stop SSE server"
    echo "  ./mcp-server.sh --stdio status          # Check STDIO server status"
    echo ""
}

# Validation function
validate_arguments() {
    if [ "$SHOW_HELP" = true ]; then
        show_help
        exit 0
    fi
    
    if [ -z "$TRANSPORT_MODE" ]; then
        echo -e "${RED}❌ Transport mode is required. Use --stdio or --sse${NC}"
        echo ""
        show_help
        exit 1
    fi
    
    if [ -z "$ACTION" ]; then
        echo -e "${RED}❌ Action is required. Use start, stop, restart, or status${NC}"
        echo ""
        show_help
        exit 1
    fi
}

# Function to find and kill existing processes
kill_existing_processes() {
    echo -e "${BLUE}🔍 Looking for existing MCP server processes...${NC}"
    
    # Find and kill any Java processes running the MCP server JAR
    PIDS=$(ps aux | grep "generic-mcp-server-1.0.0.jar" | grep -v grep | awk '{print $2}' || true)
    
    # Also look for spring-boot:run processes
    SPRING_PIDS=$(ps aux | grep "[s]pring-boot:run" | grep "generic-mcp" | awk '{print $2}' || true)
    
    # Combine PIDs
    ALL_PIDS="$PIDS $SPRING_PIDS"
    
    if [ ! -z "$ALL_PIDS" ]; then
        echo -e "${YELLOW}🛑 Found existing processes: $ALL_PIDS${NC}"
        echo "$ALL_PIDS" | xargs kill -9 2>/dev/null || true
        echo -e "${GREEN}✅ Killed existing processes${NC}"
        sleep 2  # Give processes time to fully terminate
    else
        echo -e "${GREEN}ℹ️  No existing processes found${NC}"
    fi
    
    # For SSE mode, also check port 8082
    if [ "$TRANSPORT_MODE" = "sse" ]; then
        PORT_PID=$(lsof -ti:8082 2>/dev/null || true)
        if [ -n "$PORT_PID" ]; then
            echo -e "${YELLOW}🛑 Found process using port 8082: $PORT_PID${NC}"
            kill -9 $PORT_PID 2>/dev/null || true
            echo -e "${GREEN}✅ Freed port 8082${NC}"
        fi
    fi
}

# Function to build the project
build_project() {
    # Change to script directory for build operations
    cd "$SCRIPT_DIR"
    
    if [ "$BUILD_PROJECT" = true ]; then
        echo -e "${BLUE}🔨 Building project...${NC}"
        ./mvnw clean package -DskipTests
        echo -e "${GREEN}✅ Build completed${NC}"
    else
        echo -e "${YELLOW}⏭️  Skipping build (--no-build specified)${NC}"
        
        # Check if JAR exists
        if [ ! -f "target/generic-mcp-server-1.0.0.jar" ]; then
            echo -e "${RED}❌ JAR file not found! Building is required.${NC}"
            echo -e "${BLUE}🔨 Building project...${NC}"
            ./mvnw clean package -DskipTests
            echo -e "${GREEN}✅ Build completed${NC}"
        fi
    fi
}

# Function to check server status
check_server_status() {
    case $TRANSPORT_MODE in
        stdio)
            # For STDIO, check if Java process is running
            PIDS=$(ps aux | grep "generic-mcp-server-1.0.0.jar" | grep "stdio" | grep -v grep | awk '{print $2}' || true)
            if [ ! -z "$PIDS" ]; then
                echo -e "${GREEN}✅ STDIO server is running (PID: $PIDS)${NC}"
                return 0
            else
                echo -e "${RED}❌ STDIO server is not running${NC}"
                return 1
            fi
            ;;
        sse)
            # For SSE, check both process and HTTP endpoint
            PIDS=$(ps aux | grep "generic-mcp-server-1.0.0.jar" | grep "sse" | grep -v grep | awk '{print $2}' || true)
            if [ ! -z "$PIDS" ]; then
                echo -e "${GREEN}✅ SSE server process is running (PID: $PIDS)${NC}"
                
                # Check if HTTP endpoint is responding
                if curl -s -f http://localhost:8082/actuator/health > /dev/null 2>&1; then
                    echo -e "${GREEN}✅ SSE server HTTP endpoint is healthy${NC}"
                    echo -e "${BLUE}📍 Server URL: http://localhost:8082${NC}"
                    echo -e "${BLUE}📍 MCP Endpoint: http://localhost:8082/mcp${NC}"
                    return 0
                else
                    echo -e "${YELLOW}⚠️  SSE server process running but HTTP endpoint not responding${NC}"
                    return 1
                fi
            else
                echo -e "${RED}❌ SSE server is not running${NC}"
                return 1
            fi
            ;;
    esac
}

# Function to start the server in STDIO mode
start_stdio_server() {
    echo -e "${GREEN}🚀 Starting MCP server in STDIO mode...${NC}"
    echo ""
    echo -e "${BLUE}📝 STDIO Transport Configuration:${NC}"
    echo "   • Transport: Standard Input/Output"
    echo "   • Target: Claude Desktop integration"
    echo "   • Web server: Disabled"
    echo "   • Communication: Process-based"
    echo ""
    echo -e "${YELLOW}💡 Use Ctrl+C to stop the server${NC}"
    echo ""
    echo "============================================================"
    echo -e "${GREEN}MCP SERVER STARTED (STDIO MODE)${NC}"
    echo "============================================================"
    echo ""
    
    # Run the server with stdio profile in foreground
    exec java -jar "$SCRIPT_DIR/target/generic-mcp-server-1.0.0.jar" --spring.profiles.active=stdio
}

# Function to start the server in SSE mode
start_sse_server() {
    echo -e "${GREEN}🚀 Starting MCP server in SSE mode...${NC}"
    echo ""
    echo -e "${BLUE}📝 SSE Transport Configuration:${NC}"
    echo "   • Transport: Server-Sent Events (HTTP)"
    echo "   • Target: Web client integration"
    echo "   • Web server: http://localhost:8082"
    echo "   • MCP endpoint: http://localhost:8082/mcp"
    echo "   • Health check: http://localhost:8082/actuator/health"
    echo ""
    echo -e "${YELLOW}💡 Use Ctrl+C to stop the server${NC}"
    echo ""
    echo "============================================================"
    echo -e "${GREEN}MCP SERVER STARTED (SSE MODE)${NC}"
    echo -e "${BLUE}Web URL: http://localhost:8082${NC}"
    echo -e "${BLUE}MCP Endpoint: http://localhost:8082/mcp${NC}"
    echo "============================================================"
    echo ""
    
    # Run the server with sse profile in foreground
    exec java -jar "$SCRIPT_DIR/target/generic-mcp-server-1.0.0.jar" --spring.profiles.active=sse
}

# Function to handle start action
handle_start() {
    echo -e "${BLUE}🎯 Starting Generic MCP Server${NC}"
    echo "======================================"
    echo -e "${YELLOW}Transport Mode: $(echo $TRANSPORT_MODE | tr '[:lower:]' '[:upper:]')${NC}"
    echo ""
    
    # Kill existing processes
    kill_existing_processes
    
    # Build the project
    build_project
    
    # Start the server based on transport mode
    case $TRANSPORT_MODE in
        stdio)
            start_stdio_server
            ;;
        sse)
            start_sse_server
            ;;
    esac
}

# Function to handle stop action
handle_stop() {
    echo -e "${RED}🛑 Stopping MCP Server${NC}"
    echo "======================"
    echo -e "${YELLOW}Transport Mode: $(echo $TRANSPORT_MODE | tr '[:lower:]' '[:upper:]')${NC}"
    echo ""
    
    kill_existing_processes
    echo -e "${GREEN}✅ Server stopped${NC}"
}

# Function to handle restart action
handle_restart() {
    echo -e "${BLUE}🔄 Restarting MCP Server${NC}"
    echo "========================"
    echo -e "${YELLOW}Transport Mode: $(echo $TRANSPORT_MODE | tr '[:lower:]' '[:upper:]')${NC}"
    echo ""
    
    # Stop first
    kill_existing_processes
    
    # Build the project
    build_project
    
    echo -e "${GREEN}🚀 Starting server...${NC}"
    echo ""
    
    # Start based on transport mode
    case $TRANSPORT_MODE in
        stdio)
            start_stdio_server
            ;;
        sse)
            start_sse_server
            ;;
    esac
}

# Function to handle status action
handle_status() {
    echo -e "${BLUE}📊 MCP Server Status${NC}"
    echo "===================="
    echo -e "${YELLOW}Transport Mode: $(echo $TRANSPORT_MODE | tr '[:lower:]' '[:upper:]')${NC}"
    echo ""
    
    check_server_status
}

# Main execution
main() {
    # Validate arguments
    validate_arguments
    
    # Handle the requested action
    case $ACTION in
        start)
            handle_start
            ;;
        stop)
            handle_stop
            ;;
        restart)
            handle_restart
            ;;
        status)
            handle_status
            ;;
        *)
            echo -e "${RED}❌ Invalid action: $ACTION${NC}"
            echo "Valid actions: start, stop, restart, status"
            exit 1
            ;;
    esac
}

# Run the main function
main "$@"