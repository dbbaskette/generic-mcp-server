package com.example.genericmcp;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest
@TestPropertySource(properties = {
    "spring.ai.mcp.server.enabled=true"
})
class GenericMcpServerApplicationTests {

    @Test
    void contextLoads() {
        // This test ensures that the Spring context loads successfully
        // and all beans are properly configured
    }
}