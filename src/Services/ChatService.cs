using Azure.Identity;
using System.Text;
using System.Text.Json;

namespace ZavaStorefront.Services;

public class ChatService
{
    private readonly ILogger<ChatService> _logger;
    private readonly IConfiguration _configuration;
    private readonly HttpClient _httpClient;
    private readonly string? _endpoint;
    private readonly bool _isConfigured;

    public ChatService(ILogger<ChatService> logger, IConfiguration configuration, IHttpClientFactory httpClientFactory)
    {
        _logger = logger;
        _configuration = configuration;
        _httpClient = httpClientFactory.CreateClient();

        // Get Azure AI Services endpoint from configuration
        _endpoint = _configuration["AZURE_AI_SERVICES_ENDPOINT"];
        
        if (!string.IsNullOrEmpty(_endpoint))
        {
            _isConfigured = true;
            _logger.LogInformation("ChatService initialized with Azure AI Services endpoint: {Endpoint}", _endpoint);
        }
        else
        {
            _isConfigured = false;
            _logger.LogWarning("AZURE_AI_SERVICES_ENDPOINT not configured. ChatService will operate in mock mode.");
        }
    }

    public async Task<string> SendMessageAsync(string userMessage)
    {
        if (string.IsNullOrWhiteSpace(userMessage))
        {
            return "Please enter a message.";
        }

        _logger.LogInformation("Processing chat message: {Message}", userMessage);

        // If not configured, return a mock response
        if (!_isConfigured)
        {
            _logger.LogInformation("Operating in mock mode - returning simulated response");
            return await GetMockResponseAsync(userMessage);
        }

        try
        {
            // Get access token using Managed Identity
            var credential = new ManagedIdentityCredential();
            var token = await credential.GetTokenAsync(
                new Azure.Core.TokenRequestContext(new[] { "https://cognitiveservices.azure.com/.default" }));

            // Prepare request to Azure AI Services
            var requestBody = new
            {
                messages = new[]
                {
                    new { role = "system", content = "You are a helpful AI assistant for the Zava Storefront e-commerce platform. Help customers with their questions about products, orders, and shopping." },
                    new { role = "user", content = userMessage }
                },
                max_tokens = 500,
                temperature = 0.7,
                model = "Phi-4"
            };

            var requestJson = JsonSerializer.Serialize(requestBody);
            var content = new StringContent(requestJson, Encoding.UTF8, "application/json");

            // Add authorization header
            _httpClient.DefaultRequestHeaders.Clear();
            _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {token.Token}");

            // Send request to Azure AI Services
            var chatEndpoint = $"{_endpoint?.TrimEnd('/')}/openai/deployments/Phi-4/chat/completions?api-version=2024-02-01";
            var response = await _httpClient.PostAsync(chatEndpoint, content);

            if (response.IsSuccessStatusCode)
            {
                var responseJson = await response.Content.ReadAsStringAsync();
                var responseData = JsonSerializer.Deserialize<JsonElement>(responseJson);
                
                if (responseData.TryGetProperty("choices", out var choices) && choices.GetArrayLength() > 0)
                {
                    var firstChoice = choices[0];
                    if (firstChoice.TryGetProperty("message", out var message) && 
                        message.TryGetProperty("content", out var messageContent))
                    {
                        var result = messageContent.GetString() ?? "No response available.";
                        _logger.LogInformation("Received response from Azure AI Services");
                        return result;
                    }
                }
            }
            
            _logger.LogWarning("Failed to get response from Azure AI Services. Status: {Status}", response.StatusCode);
            return "I'm sorry, I couldn't process your request at this time. Please try again.";
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "HTTP error calling Azure AI Services");
            return "I'm sorry, I encountered a network error while processing your request. Please try again later.";
        }
        catch (TaskCanceledException ex)
        {
            _logger.LogError(ex, "Request to Azure AI Services was canceled or timed out");
            return "I'm sorry, your request took too long to process. Please try again.";
        }
        catch (OperationCanceledException ex)
        {
            _logger.LogError(ex, "Operation to call Azure AI Services was canceled");
            return "I'm sorry, your request was canceled before it could be completed. Please try again.";
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Error parsing response from Azure AI Services");
            return "I'm sorry, I encountered an error processing the service response. Please try again later.";
        }
    }

    private async Task<string> GetMockResponseAsync(string userMessage)
    {
        // Simulate a small delay
        await Task.Delay(500);

        var lowerMessage = userMessage.ToLower();

        if (lowerMessage.Contains("hello") || lowerMessage.Contains("hi"))
        {
            return "Hello! Welcome to Zava Storefront. How can I assist you today?";
        }
        else if (lowerMessage.Contains("product") || lowerMessage.Contains("shop"))
        {
            return "We have a wide range of products including headphones, smartwatches, speakers, and more. You can browse our catalog on the home page!";
        }
        else if (lowerMessage.Contains("help"))
        {
            return "I'm here to help! You can ask me about our products, how to place an order, or any other questions about Zava Storefront.";
        }
        else if (lowerMessage.Contains("price") || lowerMessage.Contains("cost"))
        {
            return "Our products range from $29.99 to $199.99. Check out our home page to see the full catalog with prices!";
        }
        else
        {
            return $"Thank you for your message: \"{userMessage}\". I'm currently in demo mode. When connected to Azure AI Services, I'll be able to provide more detailed and intelligent responses!";
        }
    }
}
