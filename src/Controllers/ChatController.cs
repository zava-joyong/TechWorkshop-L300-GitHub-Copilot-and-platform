using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Models;
using ZavaStorefront.Services;
using Newtonsoft.Json;

namespace ZavaStorefront.Controllers;

public class ChatController : Controller
{
    private readonly ILogger<ChatController> _logger;
    private readonly ChatService _chatService;

    public ChatController(ILogger<ChatController> logger, ChatService chatService)
    {
        _logger = logger;
        _chatService = chatService;
    }

    public IActionResult Index()
    {
        _logger.LogInformation("Loading chat page");
        
        // Initialize chat history in session if not exists
        if (HttpContext.Session.GetString("ChatHistory") == null)
        {
            var initialHistory = new List<ChatMessage>
            {
                new ChatMessage
                {
                    Role = "assistant",
                    Content = "Hello! I'm your AI assistant for Zava Storefront. How can I help you today?",
                    Timestamp = DateTime.UtcNow
                }
            };
            HttpContext.Session.SetString("ChatHistory", JsonConvert.SerializeObject(initialHistory));
        }

        // Load chat history from session
        var chatHistoryJson = HttpContext.Session.GetString("ChatHistory");
        var chatHistory = string.IsNullOrEmpty(chatHistoryJson) 
            ? new List<ChatMessage>() 
            : JsonConvert.DeserializeObject<List<ChatMessage>>(chatHistoryJson) ?? new List<ChatMessage>();

        return View(chatHistory);
    }

    [HttpPost]
    public async Task<IActionResult> SendMessage(string userMessage)
    {
        if (string.IsNullOrWhiteSpace(userMessage))
        {
            return RedirectToAction("Index");
        }

        _logger.LogInformation("Sending user message to chat service");

        // Load chat history from session
        var chatHistoryJson = HttpContext.Session.GetString("ChatHistory");
        var chatHistory = string.IsNullOrEmpty(chatHistoryJson) 
            ? new List<ChatMessage>() 
            : JsonConvert.DeserializeObject<List<ChatMessage>>(chatHistoryJson) ?? new List<ChatMessage>();

        // Add user message to history
        chatHistory.Add(new ChatMessage
        {
            Role = "user",
            Content = userMessage,
            Timestamp = DateTime.UtcNow
        });

        // Get response from AI service
        var response = await _chatService.SendMessageAsync(userMessage);

        // Add assistant response to history
        chatHistory.Add(new ChatMessage
        {
            Role = "assistant",
            Content = response,
            Timestamp = DateTime.UtcNow
        });

        // Save updated chat history to session
        HttpContext.Session.SetString("ChatHistory", JsonConvert.SerializeObject(chatHistory));

        return RedirectToAction("Index");
    }

    [HttpPost]
    public IActionResult ClearChat()
    {
        _logger.LogInformation("Clearing chat history");
        
        // Reset chat history with initial greeting
        var initialHistory = new List<ChatMessage>
        {
            new ChatMessage
            {
                Role = "assistant",
                Content = "Hello! I'm your AI assistant for Zava Storefront. How can I help you today?",
                Timestamp = DateTime.UtcNow
            }
        };
        HttpContext.Session.SetString("ChatHistory", JsonConvert.SerializeObject(initialHistory));

        return RedirectToAction("Index");
    }
}
