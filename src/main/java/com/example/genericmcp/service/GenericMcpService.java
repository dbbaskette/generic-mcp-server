package com.example.genericmcp.service;

import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Service;

/**
 * Generic MCP Service that provides template implementations for common MCP tools.
 * 
 * DUAL TRANSPORT SUPPORT:
 * This server supports both transport methods:
 * - Stdio Transport: For Claude Desktop integration (spawned as a process)
 * - WebMVC SSE Transport: For web clients at http://localhost:8081/mcp
 * 
 * TO CUSTOMIZE THIS SERVICE:
 * 1. Replace the simple string returns with actual business logic
 * 2. Add proper input validation and error handling
 * 3. Integrate with your data sources (databases, APIs, files, etc.)
 * 4. Add additional tools by creating new methods
 * 5. Update tool descriptions and parameter descriptions to match your use case
 */
@Service
public class GenericMcpService {

    /**
     * Simple greeting tool for testing MCP functionality.
     * 
     * CUSTOMIZATION GUIDE:
     * - Replace with actual greeting logic (user lookup, personalization, etc.)
     * - Add authentication or user context if needed
     */
    @Tool(description = "Returns a simple hello greeting from the MCP server")
    public String getHello() {
        // TODO: Replace with actual greeting logic
        // Example implementations:
        // - Personalized greeting: return "Hello, " + userService.getCurrentUser().getName();
        // - Time-based greeting: return greetingService.getTimeBasedGreeting();
        
        return "Hello from Generic MCP Server! Ready to process your requests.";
    }

    /**
     * Generic data retrieval tool.
     * 
     * CUSTOMIZATION GUIDE:
     * - Replace with actual data source queries (database, API calls, etc.)
     * - Add proper parameter validation
     * - Implement error handling for data source failures
     * - Consider adding pagination for large datasets
     */
    @Tool(description = "Retrieves data based on the provided query parameters")
    public String getData(
            @ToolParam(description = "The type of data to retrieve") String dataType,
            @ToolParam(description = "Optional filter criteria", required = false) String filter) {
        // TODO: Replace with actual data retrieval logic
        // Example implementations:
        // - Query database: return databaseService.findByTypeAndFilter(dataType, filter);
        // - Call external API: return apiClient.getData(dataType, filter);
        // - Read from file: return fileService.readData(dataType, filter);
        
        return String.format("Generic data response for type: %s, filter: %s", dataType, filter);
    }

    /**
     * Generic text processing tool.
     * 
     * CUSTOMIZATION GUIDE:
     * - Implement actual text processing logic (NLP, transformation, validation)
     * - Add support for different processing types
     * - Integrate with external text processing services
     * - Add proper error handling for malformed input
     */
    @Tool(description = "Processes text according to the specified operation")
    public String processText(
            @ToolParam(description = "The text content to process") String content,
            @ToolParam(description = "The type of processing to perform") String operation) {
        // TODO: Replace with actual text processing logic
        // Example implementations:
        // - Sentiment analysis: return sentimentService.analyze(content);
        // - Text summarization: return summaryService.summarize(content);
        // - Language detection: return languageService.detect(content);
        // - Text translation: return translationService.translate(content, operation);
        
        return String.format("Processed text using operation '%s': %s", operation, content.substring(0, Math.min(50, content.length())));
    }

    /**
     * Generic calculation tool.
     * 
     * CUSTOMIZATION GUIDE:
     * - Implement mathematical calculations, statistical analysis, or business metrics
     * - Add support for complex calculations with multiple parameters
     * - Integrate with calculation libraries or external computation services
     * - Add proper number validation and overflow handling
     */
    @Tool(description = "Performs calculations based on provided numbers and operation")
    public String calculate(
            @ToolParam(description = "First number for calculation") Double num1,
            @ToolParam(description = "Second number for calculation") Double num2,
            @ToolParam(description = "Operation to perform (add, subtract, multiply, divide)") String operation) {
        // TODO: Replace with actual calculation logic
        // Example implementations:
        // - Financial calculations: return financialService.calculate(num1, num2, operation);
        // - Statistical analysis: return statisticsService.analyze(numbers, operation);
        // - Unit conversions: return conversionService.convert(num1, num2, operation);
        
        return String.format("Generic calculation result: %f %s %f = [calculated result]", num1, operation, num2);
    }

    /**
     * Generic system information tool.
     * 
     * CUSTOMIZATION GUIDE:
     * - Return actual system metrics, health checks, or status information
     * - Integrate with monitoring systems or health check endpoints
     * - Add security considerations for sensitive system information
     * - Implement proper access controls for system data
     */
    @Tool(description = "Retrieves system information and status")
    public String getSystemInfo(
            @ToolParam(description = "Type of system information to retrieve") String infoType) {
        // TODO: Replace with actual system information retrieval
        // Example implementations:
        // - Health checks: return healthService.getHealth(infoType);
        // - System metrics: return metricsService.getMetrics(infoType);
        // - Application status: return statusService.getStatus(infoType);
        // - Environment info: return environmentService.getInfo(infoType);
        
        return String.format("Generic system info for type: %s - Status: OK, Version: 1.0.0", infoType);
    }

    /**
     * Generic validation tool.
     * 
     * CUSTOMIZATION GUIDE:
     * - Implement actual validation logic for your domain objects
     * - Add support for different validation rules and schemas
     * - Integrate with validation frameworks or external validation services
     * - Return detailed validation results with specific error messages
     */
    @Tool(description = "Validates data according to specified rules")
    public String validateData(
            @ToolParam(description = "The data to validate") String data,
            @ToolParam(description = "The validation rules to apply") String rules) {
        // TODO: Replace with actual validation logic
        // Example implementations:
        // - Schema validation: return schemaValidator.validate(data, rules);
        // - Business rule validation: return businessRuleService.validate(data, rules);
        // - Data format validation: return formatValidator.validate(data, rules);
        
        return String.format("Generic validation result for data: %s, rules: %s - Status: VALID", 
                             data.substring(0, Math.min(30, data.length())), rules);
    }

    /**
     * Lists all available tools provided by this MCP server.
     * This is useful for clients to discover what capabilities are available.
     */
    @Tool(description = "Lists all available tools and their descriptions")
    public String listTools() {
        return """
               Available Generic MCP Tools:
               
               1. get_hello - Returns a simple greeting from the MCP server
               2. get_data - Retrieves data based on query parameters
               3. process_text - Processes text according to specified operations
               4. calculate - Performs mathematical calculations
               5. get_system_info - Retrieves system information and status
               6. validate_data - Validates data according to specified rules
               7. list_tools - Lists all available tools (this tool)
               
               Each tool returns a simple string response in this generic implementation.
               Customize the implementations in GenericMcpService.java to add real functionality.
               """;
    }
}