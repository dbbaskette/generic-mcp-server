package com.example.genericmcp;

/**
 * Main entry point for the Generic MCP Server.
 *
 * This Spring Boot application supports dual transport modes:
 * - Stdio transport: For integration with tools like Claude Desktop (process pipes)
 * - SSE transport: Web server with Server-Sent Events at http://localhost:8082/mcp
 *
 * The server automatically handles both transport modes simultaneously,
 * allowing clients to connect via either method.
 *
 * To customize server behavior, see GenericMcpService.java for tool implementations.
 */
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class GenericMcpServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(GenericMcpServerApplication.class, args);
    }
}