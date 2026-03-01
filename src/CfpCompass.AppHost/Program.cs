var builder = DistributedApplication.CreateBuilder(args);

var storage = builder.AddAzureStorage("storage")
    .RunAsEmulator(); // local dev uses Azurite emulator; Azure envs use real storage + MI

var blobs = storage.AddBlobs("blobs");

var api = builder.AddProject<Projects.CfpCompass_Api>("api")
    .WithReference(blobs)
    .WithExternalHttpEndpoints();

builder.Build().Run();
