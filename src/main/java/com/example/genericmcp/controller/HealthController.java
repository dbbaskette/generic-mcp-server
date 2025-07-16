package com.example.genericmcp.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Basic health check controller for the Generic MCP Server.
 * Provides endpoints to verify the server is running and accessible.
 */
@RestController
public class HealthController {

    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of(
                "status", "UP",
                "timestamp", LocalDateTime.now(),
                "service", "Generic MCP Server",
                "version", "1.0.0"
        );
    }

    @GetMapping("/")
    public Map<String, Object> root() {
        return Map.of(
                "message", "Generic MCP Server is running",
                "mcpEndpoint", "/mcp",
                "healthEndpoint", "/health",
                "documentation", "See CLAUDE.md for customization instructions"
        );
    }
}