using ModelContextProtocol.Server;
using Probe;
using Probe.Tools;
using System.Security.Claims;

var builder = WebApplication.CreateBuilder(args);

var port = Environment.GetEnvironmentVariable("PORT") ?? "4001";
builder.WebHost.UseUrls($"http://localhost:{port}");

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ScopedIdentity>();

builder.Services.AddMcpServer()
    .WithHttpTransport(o => o.Stateless = false)
    .WithTools<ProbeTools>();

var app = builder.Build();

app.Use(async (context, next) =>
{
    var userId = context.Request.Headers["x-dev-user"].ToString();
    if (string.IsNullOrEmpty(userId)) userId = "anonymous";
    context.Items["UserId"] = userId;
    context.RequestServices.GetService<ScopedIdentity>()!.UserId = userId;
    context.User = new ClaimsPrincipal(new ClaimsIdentity(
        new[] { new Claim(ClaimTypes.NameIdentifier, userId) }, "dev"));
    await next();
});

app.MapMcp();
app.Run();
