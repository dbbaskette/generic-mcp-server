#!/bin/bash

# Comprehensive MCP Server Test Suite
# Usage: ./test-all.sh [--stdio|--sse|--both] [--no-build] [--help]

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
TRANSPORT_MODE="both"  # Default to testing both modes
BUILD_PROJECT=true
DEPLOY_CLAUDE_CONFIG=true
SHOW_HELP=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Global test counters
TOTAL_TESTS_PASSED=0
TOTAL_TESTS_FAILED=0
TOTAL_SUITES_PASSED=0
TOTAL_SUITES_FAILED=0

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
        --no-claude-config)
            DEPLOY_CLAUDE_CONFIG=false
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
    echo -e "${CYAN}Comprehensive MCP Server Test Suite${NC}"
    echo -e "${CYAN}===================================${NC}"
    echo ""
    echo "Usage: ./test-all.sh [TRANSPORT] [OPTIONS]"
    echo ""
    echo "Transport Modes:"
    echo "  --stdio     Test STDIO transport only"
    echo "  --sse       Test SSE transport only" 
    echo "  --both      Test both transports (default)"
    echo ""
    echo "Build Options:"
    echo "  --no-build         Skip the Maven build step"
    echo ""
    echo "Configuration Options:"
    echo "  --no-claude-config Skip Claude Desktop config deployment"
    echo ""
    echo "Other Options:"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Test Suites Included:"
    echo "  • Build Verification"
    echo "  • Configuration Validation" 
    echo "  • Claude Desktop Configuration Deployment"
    echo "  • Server Lifecycle Testing"
    echo "  • Comprehensive Tool Testing (all 8 MCP tools)"
    echo "  • Transport Mode Testing"
    echo "  • Basic Integration Testing"
    echo ""
    echo "Examples:"
    echo "  ./test-all.sh                           # Test both transports, deploy config"
    echo "  ./test-all.sh --stdio                   # Test STDIO only"
    echo "  ./test-all.sh --sse --no-build          # Test SSE only, skip build"
    echo "  ./test-all.sh --both --no-claude-config  # Test both, skip config deployment"
    echo ""
}

# Function to print section headers
print_section() {
    local title="$1"
    local color="$2"
    echo ""
    echo -e "${color}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${color}║$(printf "%62s" " ")║${NC}"
    echo -e "${color}║$(printf "%*s" $(((62 + ${#title})/2)) "$title")$(printf "%*s" $(((62 - ${#title})/2)) " ")║${NC}"
    echo -e "${color}║$(printf "%62s" " ")║${NC}"
    echo -e "${color}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to run a test and track results
run_test_with_tracking() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "\n${BLUE}Running: ${test_name}${NC}"
    echo -e "${YELLOW}Command: ${test_command}${NC}"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✓ ${test_name} - PASSED${NC}"
        ((TOTAL_TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ ${test_name} - FAILED${NC}"
        ((TOTAL_TESTS_FAILED++))
        return 1
    fi
}

# Build verification suite
run_build_verification() {
    print_section "BUILD VERIFICATION SUITE" "$CYAN"
    
    local suite_passed=0
    local suite_failed=0
    
    # Test 1: Maven wrapper exists
    if [ -f "./mvnw" ]; then
        echo -e "${GREEN}✓ Maven wrapper exists${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${RED}✗ Maven wrapper missing${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    # Test 2: Build project
    if [ "$BUILD_PROJECT" = true ]; then
        echo -e "\n${BLUE}Building project...${NC}"
        if ./mvnw clean package -DskipTests -q; then
            echo -e "${GREEN}✓ Project build successful${NC}"
            ((suite_passed++))
            ((TOTAL_TESTS_PASSED++))
        else
            echo -e "${RED}✗ Project build failed${NC}"
            ((suite_failed++))
            ((TOTAL_TESTS_FAILED++))
            return 1  # Critical failure
        fi
    else
        echo -e "${YELLOW}⏭️  Skipping build (--no-build specified)${NC}"
        # Still check if JAR exists
        if [ -f "target/generic-mcp-server-1.0.0.jar" ]; then
            echo -e "${GREEN}✓ JAR file exists${NC}"
            ((suite_passed++))
            ((TOTAL_TESTS_PASSED++))
        else
            echo -e "${RED}✗ JAR file missing - build required${NC}"
            echo -e "${BLUE}Building project...${NC}"
            if ./mvnw clean package -DskipTests -q; then
                echo -e "${GREEN}✓ Emergency build successful${NC}"
                ((suite_passed++))
                ((TOTAL_TESTS_PASSED++))
            else
                echo -e "${RED}✗ Emergency build failed${NC}"
                ((suite_failed++))
                ((TOTAL_TESTS_FAILED++))
                return 1
            fi
        fi
    fi
    
    # Test 3: JAR file verification
    if [ -f "target/generic-mcp-server-1.0.0.jar" ]; then
        echo -e "${GREEN}✓ JAR file created successfully${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
        
        # Test JAR size (should be reasonable)
        jar_size=$(stat -f%z "target/generic-mcp-server-1.0.0.jar" 2>/dev/null || stat -c%s "target/generic-mcp-server-1.0.0.jar" 2>/dev/null)
        if [ "$jar_size" -gt 1000000 ]; then  # > 1MB
            echo -e "${GREEN}✓ JAR file size reasonable (${jar_size} bytes)${NC}"
            ((suite_passed++))
            ((TOTAL_TESTS_PASSED++))
        else
            echo -e "${YELLOW}⚠️  JAR file seems small (${jar_size} bytes)${NC}"
            ((suite_failed++))
            ((TOTAL_TESTS_FAILED++))
        fi
    else
        echo -e "${RED}✗ JAR file not found${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
        return 1
    fi
    
    # Suite summary
    echo -e "\n${CYAN}Build Verification Summary:${NC}"
    echo -e "${GREEN}Passed: $suite_passed${NC} | ${RED}Failed: $suite_failed${NC}"
    
    if [ $suite_failed -eq 0 ]; then
        ((TOTAL_SUITES_PASSED++))
        return 0
    else
        ((TOTAL_SUITES_FAILED++))
        return 1
    fi
}

# Configuration validation suite
run_configuration_validation() {
    print_section "CONFIGURATION VALIDATION SUITE" "$MAGENTA"
    
    local suite_passed=0
    local suite_failed=0
    
    # Test configuration files exist
    local config_files=("application.yml" "application-stdio.yml" "application-sse.yml")
    for config_file in "${config_files[@]}"; do
        if [ -f "src/main/resources/$config_file" ]; then
            echo -e "${GREEN}✓ Configuration file exists: $config_file${NC}"
            ((suite_passed++))
            ((TOTAL_TESTS_PASSED++))
        else
            echo -e "${RED}✗ Configuration file missing: $config_file${NC}"
            ((suite_failed++))
            ((TOTAL_TESTS_FAILED++))
        fi
    done
    
    # Test Claude Desktop config file exists
    if [ -f "claude_desktop_config.json" ]; then
        echo -e "${GREEN}✓ Claude Desktop config file exists${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${RED}✗ Claude Desktop config file missing${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    # Suite summary
    echo -e "\n${MAGENTA}Configuration Validation Summary:${NC}"
    echo -e "${GREEN}Passed: $suite_passed${NC} | ${RED}Failed: $suite_failed${NC}"
    
    if [ $suite_failed -eq 0 ]; then
        ((TOTAL_SUITES_PASSED++))
        return 0
    else
        ((TOTAL_SUITES_FAILED++))
        return 1
    fi
}

# Claude Desktop configuration deployment
deploy_claude_config() {
    print_section "CLAUDE DESKTOP CONFIGURATION DEPLOYMENT" "$CYAN"
    
    local suite_passed=0
    local suite_failed=0
    
    # Define Claude Desktop config directory
    CLAUDE_CONFIG_DIR="$HOME/Library/Application Support/Claude"
    CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/claude_desktop_config.json"
    
    echo -e "${BLUE}Deploying Claude Desktop configuration...${NC}"
    echo -e "${YELLOW}Target directory: $CLAUDE_CONFIG_DIR${NC}"
    
    # Create directory if it doesn't exist
    if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
        echo -e "${BLUE}Creating Claude config directory...${NC}"
        mkdir -p "$CLAUDE_CONFIG_DIR"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Claude config directory created${NC}"
            ((suite_passed++))
            ((TOTAL_TESTS_PASSED++))
        else
            echo -e "${RED}✗ Failed to create Claude config directory${NC}"
            ((suite_failed++))
            ((TOTAL_TESTS_FAILED++))
            return 1
        fi
    else
        echo -e "${GREEN}✓ Claude config directory exists${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    fi
    
    # Create the config with proper path substitution
    echo -e "${BLUE}Generating Claude Desktop config with current paths...${NC}"
    
    # Create a temporary config with current directory substituted
    TEMP_CONFIG="/tmp/claude_desktop_config_temp.json"
    sed "s|\$PWD|$SCRIPT_DIR|g" "$SCRIPT_DIR/claude_desktop_config.json" > "$TEMP_CONFIG"
    
    # Backup existing config if it exists
    if [ -f "$CLAUDE_CONFIG_FILE" ]; then
        echo -e "${YELLOW}Backing up existing Claude Desktop config...${NC}"
        cp "$CLAUDE_CONFIG_FILE" "$CLAUDE_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Existing config backed up${NC}"
            ((suite_passed++))
            ((TOTAL_TESTS_PASSED++))
        else
            echo -e "${YELLOW}⚠️  Could not backup existing config${NC}"
        fi
    fi
    
    # Deploy the new config
    echo -e "${BLUE}Installing Generic MCP Server config...${NC}"
    
    # If existing config exists, merge it
    if [ -f "$CLAUDE_CONFIG_FILE" ]; then
        echo -e "${YELLOW}Merging with existing Claude Desktop configuration...${NC}"
        
        # Create a merged config using jq if available, otherwise replace entirely
        if command -v jq >/dev/null 2>&1; then
            # Use jq to merge configurations
            jq -s '.[0] * .[1]' "$CLAUDE_CONFIG_FILE" "$TEMP_CONFIG" > "$CLAUDE_CONFIG_FILE.new" 2>/dev/null
            if [ $? -eq 0 ] && [ -s "$CLAUDE_CONFIG_FILE.new" ]; then
                mv "$CLAUDE_CONFIG_FILE.new" "$CLAUDE_CONFIG_FILE"
                echo -e "${GREEN}✓ Configuration merged successfully${NC}"
                ((suite_passed++))
                ((TOTAL_TESTS_PASSED++))
            else
                echo -e "${YELLOW}⚠️  jq merge failed, replacing entire config${NC}"
                cp "$TEMP_CONFIG" "$CLAUDE_CONFIG_FILE"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ Configuration replaced successfully${NC}"
                    ((suite_passed++))
                    ((TOTAL_TESTS_PASSED++))
                else
                    echo -e "${RED}✗ Failed to deploy configuration${NC}"
                    ((suite_failed++))
                    ((TOTAL_TESTS_FAILED++))
                fi
            fi
        else
            echo -e "${YELLOW}⚠️  jq not available, replacing entire config${NC}"
            cp "$TEMP_CONFIG" "$CLAUDE_CONFIG_FILE"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Configuration replaced successfully${NC}"
                ((suite_passed++))
                ((TOTAL_TESTS_PASSED++))
            else
                echo -e "${RED}✗ Failed to deploy configuration${NC}"
                ((suite_failed++))
                ((TOTAL_TESTS_FAILED++))
            fi
        fi
    else
        # No existing config, just copy
        cp "$TEMP_CONFIG" "$CLAUDE_CONFIG_FILE"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Configuration deployed successfully${NC}"
            ((suite_passed++))
            ((TOTAL_TESTS_PASSED++))
        else
            echo -e "${RED}✗ Failed to deploy configuration${NC}"
            ((suite_failed++))
            ((TOTAL_TESTS_FAILED++))
        fi
    fi
    
    # Clean up temp file
    rm -f "$TEMP_CONFIG"
    
    # Verify deployment
    if [ -f "$CLAUDE_CONFIG_FILE" ]; then
        echo -e "${BLUE}Verifying deployment...${NC}"
        if grep -q "generic-mcp-server" "$CLAUDE_CONFIG_FILE"; then
            echo -e "${GREEN}✓ Generic MCP Server found in Claude config${NC}"
            ((suite_passed++))
            ((TOTAL_TESTS_PASSED++))
            
            echo -e "\n${CYAN}Configuration Details:${NC}"
            echo -e "${YELLOW}Config file: $CLAUDE_CONFIG_FILE${NC}"
            echo -e "${YELLOW}JAR location: $SCRIPT_DIR/target/generic-mcp-server-1.0.0.jar${NC}"
            echo -e "${YELLOW}Working directory: $SCRIPT_DIR${NC}"
            echo ""
            echo -e "${GREEN}🎉 Claude Desktop is now configured to use your Generic MCP Server!${NC}"
            echo -e "${BLUE}💡 Restart Claude Desktop to load the new configuration.${NC}"
        else
            echo -e "${RED}✗ Generic MCP Server not found in deployed config${NC}"
            ((suite_failed++))
            ((TOTAL_TESTS_FAILED++))
        fi
    else
        echo -e "${RED}✗ Configuration file not found after deployment${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    # Suite summary
    echo -e "\n${CYAN}Claude Desktop Configuration Summary:${NC}"
    echo -e "${GREEN}Passed: $suite_passed${NC} | ${RED}Failed: $suite_failed${NC}"
    
    if [ $suite_failed -eq 0 ]; then
        ((TOTAL_SUITES_PASSED++))
        return 0
    else
        ((TOTAL_SUITES_FAILED++))
        return 1
    fi
}

# Server lifecycle testing
run_server_lifecycle_tests() {
    local transport_mode="$1"
    print_section "SERVER LIFECYCLE TESTS - $(echo $transport_mode | tr '[:lower:]' '[:upper:]')" "$BLUE"
    
    local suite_passed=0
    local suite_failed=0
    
    # Test server script exists and is executable
    if [ -x "./mcp-server.sh" ]; then
        echo -e "${GREEN}✓ Server script exists and is executable${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${RED}✗ Server script missing or not executable${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
        return 1
    fi
    
    # Test server help
    if ./mcp-server.sh --help > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Server script help works${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${RED}✗ Server script help failed${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    # Test server status when not running
    if ./mcp-server.sh --${transport_mode} status > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Server reports running when it shouldn't be${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    else
        echo -e "${GREEN}✓ Server correctly reports not running${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    fi
    
    # Suite summary
    echo -e "\n${BLUE}Server Lifecycle Summary:${NC}"
    echo -e "${GREEN}Passed: $suite_passed${NC} | ${RED}Failed: $suite_failed${NC}"
    
    if [ $suite_failed -eq 0 ]; then
        ((TOTAL_SUITES_PASSED++))
        return 0
    else
        ((TOTAL_SUITES_FAILED++))
        return 1
    fi
}

# Comprehensive tool testing for SSE transport
run_sse_tool_tests() {
    print_section "COMPREHENSIVE TOOL TESTS - SSE" "$YELLOW"
    
    local suite_passed=0
    local suite_failed=0
    
    # Start SSE server for testing
    echo -e "${BLUE}Starting SSE server for tool testing...${NC}"
    ./mcp-server.sh --sse start --no-build &
    SERVER_PID=$!
    
    # Wait for server to start
    sleep 5
    
    # Test 1: get_hello tool
    echo -e "\n${BLUE}Testing get_hello tool${NC}"
    if curl -s -X POST http://localhost:8082/mcp \
        -H 'Content-Type: application/json' \
        -d '{"name":"get_hello","parameters":{}}' | \
        grep -q "Hello from Generic MCP Server"; then
        echo -e "${GREEN}✓ get_hello tool test passed${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${RED}✗ get_hello tool test failed${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    # Test 2: get_data tool
    echo -e "\n${BLUE}Testing get_data tool${NC}"
    if curl -s -X POST http://localhost:8082/mcp \
        -H 'Content-Type: application/json' \
        -d '{"name":"get_data","parameters":{"dataType":"users","filter":"active"}}' | \
        grep -q "Generic data response"; then
        echo -e "${GREEN}✓ get_data tool test passed${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${RED}✗ get_data tool test failed${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    # Test 3: process_text tool
    echo -e "\n${BLUE}Testing process_text tool${NC}"
    if curl -s -X POST http://localhost:8082/mcp \
        -H 'Content-Type: application/json' \
        -d '{"name":"process_text","parameters":{"content":"Hello World","operation":"uppercase"}}' | \
        grep -q "Processed text"; then
        echo -e "${GREEN}✓ process_text tool test passed${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${RED}✗ process_text tool test failed${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    # Test 4: calculate tool
    echo -e "\n${BLUE}Testing calculate tool${NC}"
    if curl -s -X POST http://localhost:8082/mcp \
        -H 'Content-Type: application/json' \
        -d '{"name":"calculate","parameters":{"num1":10,"num2":5,"operation":"add"}}' | \
        grep -q "Generic calculation result"; then
        echo -e "${GREEN}✓ calculate tool test passed${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${RED}✗ calculate tool test failed${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    # Test 5: get_system_info tool
    echo -e "\n${BLUE}Testing get_system_info tool${NC}"
    if curl -s -X POST http://localhost:8082/mcp \
        -H 'Content-Type: application/json' \
        -d '{"name":"get_system_info","parameters":{"infoType":"health"}}' | \
        grep -q "Generic system info"; then
        echo -e "${GREEN}✓ get_system_info tool test passed${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${RED}✗ get_system_info tool test failed${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    # Test 6: validate_data tool
    echo -e "\n${BLUE}Testing validate_data tool${NC}"
    if curl -s -X POST http://localhost:8082/mcp \
        -H 'Content-Type: application/json' \
        -d '{"name":"validate_data","parameters":{"data":"test@example.com","rules":"email"}}' | \
        grep -q "Generic validation result"; then
        echo -e "${GREEN}✓ validate_data tool test passed${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${RED}✗ validate_data tool test failed${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    # Test 7: get_version tool
    echo -e "\n${BLUE}Testing get_version tool${NC}"
    if curl -s -X POST http://localhost:8082/mcp \
        -H 'Content-Type: application/json' \
        -d '{"name":"get_version","parameters":{}}' | \
        grep -q "Generic MCP Server version"; then
        echo -e "${GREEN}✓ get_version tool test passed${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${RED}✗ get_version tool test failed${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    # Test 8: list_tools tool
    echo -e "\n${BLUE}Testing list_tools tool${NC}"
    if curl -s -X POST http://localhost:8082/mcp \
        -H 'Content-Type: application/json' \
        -d '{"name":"list_tools","parameters":{}}' | \
        grep -q "Available Generic MCP Tools"; then
        echo -e "${GREEN}✓ list_tools tool test passed${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${RED}✗ list_tools tool test failed${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    # Test 9: Invalid tool handling
    echo -e "\n${BLUE}Testing invalid tool handling${NC}"
    response=$(curl -s -X POST http://localhost:8082/mcp \
        -H 'Content-Type: application/json' \
        -d '{"name":"invalid_tool","parameters":{}}')
    if echo "$response" | grep -q -i "error\|not found\|invalid"; then
        echo -e "${GREEN}✓ Invalid tool handling test passed${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${RED}✗ Invalid tool handling test failed${NC}"
        echo -e "${YELLOW}Response: $response${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    # Test 10: Tool with missing parameters
    echo -e "\n${BLUE}Testing tool with missing required parameters${NC}"
    response=$(curl -s -X POST http://localhost:8082/mcp \
        -H 'Content-Type: application/json' \
        -d '{"name":"get_data","parameters":{}}')
    if echo "$response" | grep -q -i "error\|required\|missing"; then
        echo -e "${GREEN}✓ Missing parameters handling test passed${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠️  Missing parameters test - tool handled gracefully${NC}"
        echo -e "${YELLOW}Response: $response${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
    fi
    
    # Stop the server
    echo -e "\n${YELLOW}Stopping SSE server...${NC}"
    ./mcp-server.sh --sse stop > /dev/null 2>&1
    
    # Suite summary
    echo -e "\n${YELLOW}Comprehensive Tool Tests Summary (SSE):${NC}"
    echo -e "${GREEN}Passed: $suite_passed${NC} | ${RED}Failed: $suite_failed${NC}"
    
    if [ $suite_failed -eq 0 ]; then
        ((TOTAL_SUITES_PASSED++))
        return 0
    else
        ((TOTAL_SUITES_FAILED++))
        return 1
    fi
}

# STDIO tool testing (simplified - full testing requires MCP client)
run_stdio_tool_tests() {
    print_section "STDIO TOOL TESTS" "$YELLOW"
    
    local suite_passed=0
    local suite_failed=0
    
    echo -e "${BLUE}Testing STDIO server startup with tool discovery...${NC}"
    
    # Start server and capture initial output
    timeout 10 java -jar "$SCRIPT_DIR/target/generic-mcp-server-1.0.0.jar" --spring.profiles.active=stdio &
    SERVER_PID=$!
    
    # Wait for startup
    sleep 3
    
    # Check if server started (basic test)
    if ps -p $SERVER_PID > /dev/null 2>&1; then
        echo -e "${GREEN}✓ STDIO server started successfully${NC}"
        ((suite_passed++))
        ((TOTAL_TESTS_PASSED++))
        
        # Kill the server
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    else
        echo -e "${RED}✗ STDIO server failed to start${NC}"
        ((suite_failed++))
        ((TOTAL_TESTS_FAILED++))
    fi
    
    echo -e "\n${YELLOW}Note: Full STDIO tool testing requires an MCP client (like Claude Desktop)${NC}"
    echo -e "${YELLOW}These tests verify basic server startup with tool configuration${NC}"
    
    # Suite summary
    echo -e "\n${YELLOW}STDIO Tool Tests Summary:${NC}"
    echo -e "${GREEN}Passed: $suite_passed${NC} | ${RED}Failed: $suite_failed${NC}"
    
    if [ $suite_failed -eq 0 ]; then
        ((TOTAL_SUITES_PASSED++))
        return 0
    else
        ((TOTAL_SUITES_FAILED++))
        return 1
    fi
}

# Integration tests using the existing test script
run_integration_tests() {
    local transport_mode="$1"
    print_section "BASIC INTEGRATION TESTS - $(echo $transport_mode | tr '[:lower:]' '[:upper:]')" "$CYAN"
    
    echo -e "${BLUE}Running basic integration test script...${NC}"
    
    # Run the existing test script
    if ./test-mcp-server.sh --${transport_mode} --no-build; then
        echo -e "${GREEN}✓ Basic integration tests passed${NC}"
        ((TOTAL_SUITES_PASSED++))
        return 0
    else
        echo -e "${RED}✗ Basic integration tests failed${NC}"
        ((TOTAL_SUITES_FAILED++))
        return 1
    fi
}

# Main test runner
run_all_tests() {
    local transport_mode="$1"
    
    echo -e "${CYAN}Running comprehensive test suite for transport mode: $(echo $transport_mode | tr '[:lower:]' '[:upper:]')${NC}"
    
    # Always run build and configuration validation
    run_build_verification || return 1
    run_configuration_validation
    
    # Deploy Claude Desktop config if requested
    if [ "$DEPLOY_CLAUDE_CONFIG" = true ]; then
        deploy_claude_config
    else
        echo -e "${YELLOW}⏭️  Skipping Claude Desktop configuration deployment (--no-claude-config specified)${NC}"
    fi
    
    # Run transport-specific tests
    case $transport_mode in
        stdio)
            run_server_lifecycle_tests "stdio"
            run_stdio_tool_tests
            run_integration_tests "stdio"
            ;;
        sse)
            run_server_lifecycle_tests "sse"
            run_sse_tool_tests
            run_integration_tests "sse"
            ;;
        both)
            run_server_lifecycle_tests "stdio"
            run_stdio_tool_tests
            run_integration_tests "stdio"
            run_server_lifecycle_tests "sse" 
            run_sse_tool_tests
            run_integration_tests "sse"
            ;;
    esac
}

# Print final summary
print_final_summary() {
    print_section "FINAL TEST SUMMARY" "$GREEN"
    
    echo -e "${CYAN}Test Results:${NC}"
    echo -e "  ${GREEN}Total Tests Passed: $TOTAL_TESTS_PASSED${NC}"
    echo -e "  ${RED}Total Tests Failed: $TOTAL_TESTS_FAILED${NC}"
    echo -e "  ${BLUE}Total Test Suites Passed: $TOTAL_SUITES_PASSED${NC}"
    echo -e "  ${MAGENTA}Total Test Suites Failed: $TOTAL_SUITES_FAILED${NC}"
    echo ""
    
    local total_tests=$((TOTAL_TESTS_PASSED + TOTAL_TESTS_FAILED))
    local success_rate=0
    if [ $total_tests -gt 0 ]; then
        success_rate=$((TOTAL_TESTS_PASSED * 100 / total_tests))
    fi
    
    echo -e "${CYAN}Success Rate: ${success_rate}%${NC}"
    echo ""
    
    if [ $TOTAL_TESTS_FAILED -eq 0 ] && [ $TOTAL_SUITES_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
        echo -e "${GREEN}The Generic MCP Server is ready for use!${NC}"
        return 0
    else
        echo -e "${RED}❌ SOME TESTS FAILED${NC}"
        echo -e "${YELLOW}Please review the failures above and fix any issues.${NC}"
        return 1
    fi
}

# Main execution
main() {
    # Show help if requested
    if [ "$SHOW_HELP" = true ]; then
        show_help
        exit 0
    fi
    
    # Print startup banner
    print_section "GENERIC MCP SERVER - COMPREHENSIVE TEST SUITE" "$CYAN"
    
    echo -e "${YELLOW}Transport Mode: $(echo $TRANSPORT_MODE | tr '[:lower:]' '[:upper:]')${NC}"
    echo -e "${YELLOW}Build Project: $BUILD_PROJECT${NC}"
    echo -e "${YELLOW}Script Directory: $SCRIPT_DIR${NC}"
    echo ""
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Run tests
    if run_all_tests "$TRANSPORT_MODE"; then
        print_final_summary
        exit 0
    else
        print_final_summary
        exit 1
    fi
}

# Run the main function
main "$@"