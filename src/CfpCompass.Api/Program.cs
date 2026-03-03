using CfpCompass.Api.Extensions;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();
builder.AddBlobStorage(); // Aspire blob storage — uses DefaultAzureCredential in all environments

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

var app = builder.Build();

app.MapDefaultEndpoints();
app.MapControllers();

app.Run();
