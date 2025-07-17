package com.example.genericmcp.config;

import com.example.genericmcp.service.GenericMcpService;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.ai.tool.method.MethodToolCallbackProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration class to register tools with the MCP server.
 * This creates a ToolCallbackProvider bean that Spring AI MCP can discover.
 */
@Configuration
public class ToolConfiguration {

    /**
     * Creates a ToolCallbackProvider bean from the GenericMcpService @Tool methods.
     * This is required for Spring AI MCP server to discover and expose the tools.
     */
    @Bean
    public ToolCallbackProvider toolCallbackProvider(GenericMcpService genericMcpService) {
        return MethodToolCallbackProvider.builder()
            .toolObjects(genericMcpService)
            .build();
    }
}