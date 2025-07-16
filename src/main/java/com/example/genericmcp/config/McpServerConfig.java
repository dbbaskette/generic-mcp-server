package com.example.genericmcp.config;

import com.example.genericmcp.service.GenericMcpService;
import org.springframework.ai.mcp.spec.ServerMcpTransport;
import org.springframework.ai.mcp.server.McpServer;
import org.springframework.ai.mcp.server.transport.SseServerMcpTransport;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class McpServerConfig {

    @Bean
    public ServerMcpTransport serverMcpTransport() {
        return new SseServerMcpTransport("/mcp");
    }

    @Bean
    public McpServer mcpServer(ServerMcpTransport transport, GenericMcpService genericMcpService) {
        return McpServer.builder()
                .transport(transport)
                .requestHandler(genericMcpService)
                .build();
    }
}