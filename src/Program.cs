using ZavaStorefront.Services;
using Microsoft.AspNetCore.DataProtection;
using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();
builder.Services.AddHttpClient();

// Configure Data Protection
// In Azure App Service, use the built-in key storage
var dataProtectionBuilder = builder.Services.AddDataProtection()
    .SetApplicationName("ZavaStorefront");

// Check if running in Azure (App Service provides WEBSITE_SITE_NAME)
if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("WEBSITE_SITE_NAME")))
{
    // Azure App Service has built-in key storage - just set app name for key isolation
    // Keys are automatically persisted by the platform
    builder.Services.AddLogging(logging => logging.AddConsole());
}
else
{
    // Local development - persist to filesystem
    var keysDirectory = Path.Combine(builder.Environment.ContentRootPath, "keys");
    Directory.CreateDirectory(keysDirectory);
    dataProtectionBuilder.PersistKeysToFileSystem(new DirectoryInfo(keysDirectory));
}

// Add session support with more resilient cookie settings
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
});

// Register application services
builder.Services.AddHttpContextAccessor();
builder.Services.AddSingleton<ProductService>();
builder.Services.AddScoped<CartService>();
builder.Services.AddScoped<ChatService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseSession();

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
