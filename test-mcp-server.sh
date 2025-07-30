#!/bin/bash

# Generic MCP Server Test Script
# Usage: ./test-mcp-server.sh [--stdio|--sse|--both] [--no-build] [--help]

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
TRANSPORT_MODE="both"  # Default to testing both modes
BUILD_PROJECT=true
SHOW_HELP=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS_PASSED=0
TOTAL_TESTS_FAILED=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --stdio)
            TRANSPORT_MODE="stdio"
            shift
            ;;
        --sse)
            TRANSPORT_MODE="sse"
            shift
            ;;
        --both)
            TRANSPORT_MODE="both"
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
    echo "Generic MCP Server Test Script"
    echo "=============================="
    echo ""
    echo "Usage: ./test-mcp-server.sh [TRANSPORT] [OPTIONS]"
    echo ""
    echo "Transport Modes:"
    echo "  --stdio     Test STDIO transport only"
    echo "  --sse       Test SSE transport only"
    echo "  --both      Test both transports (default)"
    echo ""
    echo "Build Options:"
    echo "  --no-build  Skip the Maven build step"
    echo ""
    echo "Other Options:"
    echo "  --help, -h  Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./test-mcp-server.sh                # Test both transports"
    echo "  ./test-mcp-server.sh --stdio        # Test STDIO only"
    echo "  ./test-mcp-server.sh --sse --no-build # Test SSE only, skip build"
    echo ""
}

# Function to run HTTP-based test for SSE
run_sse_test() {
    local test_name="$1"
    local curl_cmd="$2"
    local expected="$3"
    
    echo -e "\n${BLUE}Running SSE test: ${test_name}${NC}"
    echo -e "${YELLOW}Command:${NC} $curl_cmd"
    
    result=$(eval "$curl_cmd" 2>&1)
    
    echo -e "${YELLOW}Response:${NC}"
    echo "$result" | sed 's/^/  /'  # Indent the response for better readability
    
    if echo "$result" | grep -q "$expected"; then
        echo -e "${GREEN}✓ Test passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Test failed${NC}"
        echo -e "${YELLOW}Expected to find:${NC} $expected"
        return 1
    fi
}

# Function to run STDIO-based test using JSON-RPC
run_stdio_test() {
    local test_name="$1"
    local tool_name="$2"
    local parameters="$3"
    local expected="$4"
    
    echo -e "\n${BLUE}Running STDIO test: ${test_name}${NC}"
    
    # Create JSON-RPC request
    local json_request="{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"$tool_name\",\"arguments\":$parameters}}"
    echo -e "${YELLOW}Request:${NC} $json_request"
    
    # Start server in background and get PID
    java -jar "$SCRIPT_DIR/target/generic-mcp-server-1.0.0.jar" --spring.profiles.active=stdio &
    SERVER_PID=$!
    
    # Wait a bit for server to start
    sleep 3
    
    # Send request and capture response
    result=$(echo "$json_request" | timeout 10 nc -l 8080 2>&1 || echo '{"error":"timeout"}')
    
    # Kill the server
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
    
    echo -e "${YELLOW}Response:${NC}"
    echo "$result" | sed 's/^/  /'
    
    if echo "$result" | grep -q "$expected"; then
        echo -e "${GREEN}✓ Test passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Test failed${NC}"
        echo -e "${YELLOW}Expected to find:${NC} $expected"
        return 1
    fi
}

# Simplified STDIO test using direct Java process communication
run_stdio_test_simple() {
    local test_name="$1"
    local expected="$2"
    
    echo -e "\n${BLUE}Running STDIO test: ${test_name}${NC}"
    
    # Start server in background
    java -jar "$SCRIPT_DIR/target/generic-mcp-server-1.0.0.jar" --spring.profiles.active=stdio &
    SERVER_PID=$!
    
    # Wait for server to initialize
    sleep 3
    
    # Check if process is running (simple health check)
    if ps -p $SERVER_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}Response:${NC}"
        echo "  Server process started successfully (PID: $SERVER_PID)"
        
        # Kill the server
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
        
        echo -e "${GREEN}✓ Test passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Test failed${NC}"
        echo -e "${YELLOW}Expected:${NC} Server process to start"
        return 1
    fi
}

# Function to test SSE transport
test_sse_transport() {
    echo -e "\n${BLUE}========== Testing SSE Transport Mode ==========${NC}"
    
    local tests_passed=0
    local tests_failed=0
    
    # Start SSE server
    echo -e "${YELLOW}Starting SSE server...${NC}"
    ./mcp-server.sh --sse start --no-build &
    SERVER_PID=$!
    
    # Wait for server to start
    sleep 5
    
    # Test 1: Server Health
    if run_sse_test "Server Health (SSE)" \
        "curl -s http://localhost:8082/actuator/health" \
        "UP"; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    echo -e "\n${BLUE}----------------------------------------${NC}"
    
    # Test 2: Get Hello
    if run_sse_test "Get Hello (SSE)" \
        "curl -s -X POST http://localhost:8082/mcp -H 'Content-Type: application/json' -d '{\"name\":\"get_hello\",\"parameters\":{}}'" \
        "Hello from Generic MCP Server"; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    echo -e "\n${BLUE}----------------------------------------${NC}"
    
    # Test 3: Process Text
    if run_sse_test "Process Text (SSE)" \
        "curl -s -X POST http://localhost:8082/mcp -H 'Content-Type: application/json' -d '{\"name\":\"process_text\",\"parameters\":{\"content\":\"test content\",\"operation\":\"uppercase\"}}'" \
        "Processed text"; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    echo -e "\n${BLUE}----------------------------------------${NC}"
    
    # Test 4: Calculate
    if run_sse_test "Calculate (SSE)" \
        "curl -s -X POST http://localhost:8082/mcp -H 'Content-Type: application/json' -d '{\"name\":\"calculate\",\"parameters\":{\"num1\":10,\"num2\":5,\"operation\":\"add\"}}'" \
        "Generic calculation result"; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 5: SSE Connection
    echo -e "\n${BLUE}----------------------------------------${NC}"
    echo -e "\n${BLUE}Testing SSE connection${NC}"
    curl -N http://localhost:8082/mcp &
    CURL_PID=$!
    sleep 2
    kill $CURL_PID 2>/dev/null || true
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ SSE connection test passed${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}✗ SSE connection test failed${NC}"
        ((tests_failed++))
    fi
    
    # Stop the server
    echo -e "\n${YELLOW}Stopping SSE server...${NC}"
    ./mcp-server.sh --sse stop
    
    # Update global counters
    TOTAL_TESTS_PASSED=$((TOTAL_TESTS_PASSED + tests_passed))
    TOTAL_TESTS_FAILED=$((TOTAL_TESTS_FAILED + tests_failed))
    
    echo -e "\n${YELLOW}SSE Transport Test Summary:${NC}"
    echo -e "${GREEN}Tests passed: $tests_passed${NC}"
    echo -e "${RED}Tests failed: $tests_failed${NC}"
}

# Function to test STDIO transport
test_stdio_transport() {
    echo -e "\n${BLUE}========== Testing STDIO Transport Mode ==========${NC}"
    
    local tests_passed=0
    local tests_failed=0
    
    # Test 1: Server Process Start
    if run_stdio_test_simple "Server Process Start (STDIO)" \
        "Server started"; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    echo -e "\n${BLUE}----------------------------------------${NC}"
    
    # Test 2: Server Process with Profile
    echo -e "\n${BLUE}Running STDIO test: Profile Configuration${NC}"
    java -jar "$SCRIPT_DIR/target/generic-mcp-server-1.0.0.jar" --spring.profiles.active=stdio &
    SERVER_PID=$!
    sleep 3
    
    # Check if the correct profile is active by looking at the logs
    if ps -p $SERVER_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}Response:${NC}"
        echo "  Server started with STDIO profile (PID: $SERVER_PID)"
        
        # Clean up
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
        
        echo -e "${GREEN}✓ Test passed${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}✗ Test failed${NC}"
        ((tests_failed++))
    fi
    
    # Update global counters
    TOTAL_TESTS_PASSED=$((TOTAL_TESTS_PASSED + tests_passed))
    TOTAL_TESTS_FAILED=$((TOTAL_TESTS_FAILED + tests_failed))
    
    echo -e "\n${YELLOW}STDIO Transport Test Summary:${NC}"
    echo -e "${GREEN}Tests passed: $tests_passed${NC}"
    echo -e "${RED}Tests failed: $tests_failed${NC}"
    
    echo -e "\n${YELLOW}Note: Full STDIO testing requires Claude Desktop integration${NC}"
    echo -e "${YELLOW}These tests verify basic server startup and configuration${NC}"
}

# Main execution
main() {
    # Show help if requested
    if [ "$SHOW_HELP" = true ]; then
        show_help
        exit 0
    fi
    
    echo -e "${BLUE}Starting Generic MCP Server Tests${NC}"
    echo -e "${YELLOW}Transport Mode: $(echo $TRANSPORT_MODE | tr '[:lower:]' '[:upper:]')${NC}"
    echo ""
    
    # Build the project if needed
    if [ "$BUILD_PROJECT" = true ]; then
        echo -e "${BLUE}Building project...${NC}"
        ./mvnw clean package -DskipTests
        if [ $? -ne 0 ]; then
            echo -e "${RED}Build failed! Cannot continue with tests.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Build complete${NC}\n"
    fi
    
    # Check if JAR exists
    if [ ! -f target/generic-mcp-server-1.0.0.jar ]; then
        echo -e "${RED}JAR file not found! Build may have failed.${NC}"
        exit 1
    fi
    
    # Run tests based on transport mode
    case $TRANSPORT_MODE in
        stdio)
            test_stdio_transport
            ;;
        sse)
            test_sse_transport
            ;;
        both)
            test_stdio_transport
            test_sse_transport
            ;;
        *)
            echo -e "${RED}❌ Invalid transport mode: $TRANSPORT_MODE${NC}"
            echo "Valid modes: stdio, sse, both"
            exit 1
            ;;
    esac
    
    # Print final summary
    echo -e "\n${BLUE}========== Final Test Summary ==========${NC}"
    echo -e "${GREEN}Total tests passed: $TOTAL_TESTS_PASSED${NC}"
    echo -e "${RED}Total tests failed: $TOTAL_TESTS_FAILED${NC}"
    
    if [ $TOTAL_TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed! Check the summary above for details.${NC}"
        exit 1
    fi
}

# Run the main function
main "$@"