package com.example.genericmcp;

/**
 * Main entry point for the Generic MCP Server.
 *
 * This Spring Boot application is designed to run as a stdio (standard input/output) process,
 * making it compatible with tools like Claude Desktop that communicate via process pipes.
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