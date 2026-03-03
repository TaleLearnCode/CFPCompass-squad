var builder = DistributedApplication.CreateBuilder(args);

var storage = builder.AddAzureStorage("storage")
    .RunAsEmulator(); // local dev uses Azurite emulator; Azure envs use real storage + MI

var blobs = storage.AddBlobs("blobs");

// ACS has no local emulator and no Aspire hosting package.
// For local dev, set ConnectionStrings__acs to your ACS endpoint URI in appsettings.Development.json
// or user secrets: dotnet user-secrets set "ConnectionStrings:acs" "https://<resource>.communication.azure.com/"
// In production, the endpoint URI is injected via environment variable or Key Vault app config reference.

var api = builder.AddProject<Projects.CfpCompass_Api>("api")
    .WithReference(blobs)
    .WithExternalHttpEndpoints();

builder.Build().Run();
