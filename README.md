# Generic MCP Server

A generic Model Context Protocol (MCP) server built with Spring Boot 3.5.3, Spring AI 1.0.0, and Java 21. This server provides a template implementation that you can clone and customize for your specific MCP server needs.

## Features

- **WebMVC Server Transport with SSE**: Uses Server-Sent Events for real-time communication
- **Generic MCP Tools**: Pre-implemented tools that return simple strings (ready for customization)
- **Spring Boot 3.5.3**: Latest stable Spring Boot version
- **Spring AI 1.0.0**: Latest Spring AI framework integration
- **Java 21**: Modern Java features and performance improvements
- **Maven Build**: Standard Maven project structure

## Quick Start

### Prerequisites

- Java 21 or higher
- Maven 3.6 or higher

### Running the Server

```bash
# Clone and navigate to the project
cd generic-mcp-server

# Run the server
mvn spring-boot:run
```

The server will start on `http://localhost:8080` with the MCP endpoint available at `/mcp`.

### Health Check

Visit `http://localhost:8080/health` to verify the server is running.

## Available MCP Tools

This generic implementation provides the following tools:

1. **get_data** - Retrieves data based on query parameters
2. **process_text** - Processes text according to specified operations
3. **calculate** - Performs mathematical calculations
4. **get_system_info** - Retrieves system information and status
5. **validate_data** - Validates data according to specified rules
6. **list_tools** - Lists all available tools

## Customization Guide

### Adding Real Functionality

1. **Edit `/src/main/java/com/example/genericmcp/service/GenericMcpService.java`**
   - Replace simple string returns with actual business logic
   - Add your data sources (databases, APIs, files)
   - Implement proper error handling and validation

2. **Add New Tools**
   - Create new methods annotated with `@McpTool`
   - Define proper parameter schemas with `@McpSchema`
   - Add comprehensive descriptions for AI model understanding

3. **Configure Dependencies**
   - Add required dependencies to `pom.xml`
   - Update `application.yml` with your configuration

### Example Customization

```java
@McpTool(
    name = "query_database",
    description = "Queries the customer database"
)
public String queryDatabase(
        @McpSchema(description = "SQL query to execute") String query) {
    // Replace with actual database logic
    return customerRepository.executeQuery(query);
}
```

## Project Structure

```
generic-mcp-server/
├── src/main/java/com/example/genericmcp/
│   ├── GenericMcpServerApplication.java    # Main Spring Boot application
│   ├── config/
│   │   └── McpServerConfig.java            # MCP server configuration
│   ├── controller/
│   │   └── HealthController.java           # Health check endpoints
│   └── service/
│       └── GenericMcpService.java          # MCP tools implementation
├── src/main/resources/
│   └── application.yml                     # Application configuration
└── pom.xml                                # Maven dependencies
```

## Configuration

The server is configured via `src/main/resources/application.yml`:

- **Port**: 8080 (configurable)
- **MCP Endpoint**: `/mcp`
- **Transport**: WebMVC with Server-Sent Events
- **Logging**: DEBUG level for development

## Development

### Building

```bash
mvn clean compile
```

### Running Tests

```bash
mvn test
```

### Creating a JAR

```bash
mvn clean package
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