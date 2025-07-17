# Generic MCP Server

A generic Model Context Protocol (MCP) server built with Spring Boot 3.5.3, Spring AI 1.0.0, and Java 21. This server provides a template implementation that you can clone and customize for your specific MCP server needs.

## Features

- **Stdio Transport**: Designed for integration with tools like Claude Desktop (runs as a process, communicates via standard input/output)
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

# Start the server (kills any running instance, builds, and runs)
./start.sh
```

The server will start and wait for stdio input (no web port is exposed by default).

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

The server is configured via `src/main/resources/application.yml`:

```yaml
spring:
  application:
    name: generic-mcp-server   # Application name
  main:
    banner-mode: off          # Disable Spring Boot banner
    log-startup-info: false   # Suppress startup info logs
  ai:
    mcp:
      server:
        enabled: true         # Enable MCP server
        # Stdio transport only for Claude Desktop compatibility
        capabilities:
          tools: true         # Enable tool support
          resources: true     # Enable resource support
          prompts: true       # Enable prompt support

logging:
  level:
    com.example.genericmcp: DEBUG           # Debug logging for app
    org.springframework.ai.mcp: DEBUG       # Debug logging for MCP
    org.springframework.ai: DEBUG           # Debug logging for Spring AI
    root: WARN                             # Default log level
```

## Project Structure

```
generic-mcp-server/
├── src/main/java/com/example/genericmcp/
│   ├── GenericMcpServerApplication.java    # Main Spring Boot application (stdio entrypoint)
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

- **GenericMcpServerApplication.java**: Entry point for the Spring Boot application. Starts the server in stdio mode for integration with tools like Claude Desktop.
- **GenericMcpService.java**: Contains all MCP tool implementations. Each method is annotated with `@Tool` and can be customized for your use case.

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