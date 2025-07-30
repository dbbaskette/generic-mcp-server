# Generic MCP Server

A generic Model Context Protocol (MCP) server built with Spring Boot 3.5.3, Spring AI 1.0.0, and Java 21. This server provides a template implementation that you can clone and customize for your specific MCP server needs.

## Features

- **Configurable Transport Support**: 
  - **Stdio Transport**: For integration with tools like Claude Desktop (runs as a process, communicates via standard input/output)
  - **SSE Transport**: Web server with Server-Sent Events at http://localhost:8082/mcp
  - **Profile-Based Selection**: Use Spring profiles to run specific transport modes
- **Generic MCP Tools**: Pre-implemented tools that return simple strings (ready for customization)
- **Spring Boot 3.5.3**: Latest stable Spring Boot version
- **Spring AI 1.0.0**: Latest Spring AI framework integration
- **Java 21**: Modern Java features and performance improvements
- **Maven Build**: Standard Maven project structure with Maven Wrapper

## Quick Start

### Prerequisites

- Java 21 or higher
- No need to install Maven globally (Maven Wrapper included)

### Running the Server

```bash
# Clone and navigate to the project
git clone https://github.com/dbbaskette/generic-mcp-server.git
cd generic-mcp-server

# Build the project
./mvnw clean package

# Run with STDIO transport (for Claude Desktop)
java -jar target/generic-mcp-server-1.0.0.jar --spring.profiles.active=stdio

# OR run with SSE transport (for web clients)
java -jar target/generic-mcp-server-1.0.0.jar --spring.profiles.active=sse

# OR run with default configuration (STDIO transport)
./start.sh
```

**Transport Mode Selection:**
- **Default**: STDIO transport (most common - for Claude Desktop integration)
- **SSE Profile**: `--spring.profiles.active=sse` - Web server at http://localhost:8082/mcp for SSE transport
- **Explicit STDIO**: `--spring.profiles.active=stdio` - Same as default but explicit

### Stopping the Server
- Use `Ctrl+C` in the terminal to stop the server.

## Available MCP Tools

This generic implementation provides the following tools (see `GenericMcpService.java`):

1. **get_hello** - Returns a simple greeting from the MCP server
2. **get_data** - Retrieves data based on query parameters
3. **process_text** - Processes text according to specified operations
4. **calculate** - Performs mathematical calculations
5. **get_system_info** - Retrieves system information and status
6. **validate_data** - Validates data according to specified rules
7. **list_tools** - Lists all available tools

## Configuration

The server supports multiple configuration files for different transport modes:

### Application Profiles

**Default Configuration** (`application.yml`):
- Enables STDIO transport (most common use case)
- Disables web server for clean STDIO-only operation

**STDIO Profile** (`application-stdio.yml`):
- Enables only STDIO transport for Claude Desktop
- Disables web server (`server.port: -1`)
- Use with: `--spring.profiles.active=stdio`

**SSE Profile** (`application-sse.yml`):
- Enables only SSE transport for web clients
- Disables STDIO transport (`stdio: false`)
- Web server on port 8082
- Use with: `--spring.profiles.active=sse`

### Configuration Examples

**STDIO Profile Configuration:**
```yaml
spring:
  ai:
    mcp:
      server:
        enabled: true
        stdio: true
        capabilities:
          tools: true
          resources: true
          prompts: true
server:
  port: -1  # Disable web server
```

**SSE Profile Configuration:**
```yaml
spring:
  ai:
    mcp:
      server:
        enabled: true
        stdio: false  # Disable STDIO
        capabilities:
          tools: true
          resources: true
          prompts: true
server:
  port: 8082  # Enable web server for SSE
```

## Project Structure

```
generic-mcp-server/
├── src/main/java/com/example/genericmcp/
│   ├── GenericMcpServerApplication.java    # Main Spring Boot application (dual transport)
│   ├── config/                            # (Optional) Configuration classes
│   └── service/
│       └── GenericMcpService.java         # MCP tools implementation (all tool logic here)
├── src/main/resources/
│   └── application.yml                    # Application configuration
├── mvnw, mvnw.cmd, .mvn/                  # Maven Wrapper scripts and config
├── start.sh                               # Start script (kills, builds, and runs server)
└── pom.xml                                # Maven dependencies
```

## Main Classes

- **GenericMcpServerApplication.java**: Entry point for the Spring Boot application. Supports both stdio transport (for Claude Desktop) and SSE transport (for web clients).
- **GenericMcpService.java**: Contains all MCP tool implementations. Each method is annotated with `@Tool` and can be customized for your use case.

## Transport Modes

### Stdio Transport
- Used by Claude Desktop and similar tools
- Communicates via standard input/output
- No web port required
- Run with: `java -jar target/generic-mcp-server-1.0.0.jar --spring.profiles.active=stdio`

### SSE Transport (Web)
- Available at http://localhost:8082/mcp
- Uses Server-Sent Events for real-time communication
- Useful for web-based clients
- Run with: `java -jar target/generic-mcp-server-1.0.0.jar --spring.profiles.active=sse`

### Profile Selection Benefits
- **Cleaner separation**: Each transport mode runs independently
- **Resource efficiency**: No unnecessary servers running
- **Production ready**: Choose the exact transport needed for your use case

## Development

### Building

```bash
./mvnw clean package
```

### Running Tests

```bash
./mvnw test
```

### Creating a JAR

```bash
./mvnw clean package
```

## Extending the Server

1. **Add Database Support**: Include Spring Data JPA and your database driver
2. **Add External API Integration**: Include HTTP client dependencies
3. **Add Authentication**: Implement Spring Security for protected endpoints
4. **Add Metrics**: Include Spring Boot Actuator for monitoring

## References

- [Spring AI MCP Documentation](https://docs.spring.io/spring-ai/reference/api/mcp/mcp-overview.html)
- [Spring AI MCP Server Boot Starter](https://docs.spring.io/spring-ai/reference/api/mcp/mcp-server-boot-starter-docs.html)
- [Spring AI Examples](https://github.com/spring-projects/spring-ai-examples/tree/main/model-context-protocol)
- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)

## License

This project is provided as a template for creating MCP servers. Customize and use as needed for your projects.