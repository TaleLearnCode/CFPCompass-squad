# Skill: Azure SDK Managed Identity Pattern

**When:** Adding any new Azure SDK client to a CFP Compass service project that requires authentication.

---

## The Pattern

All Azure SDK clients use `DefaultAzureCredential` — never connection strings or shared keys in application code.

```csharp
// ✅ CORRECT — endpoint URI + DefaultAzureCredential
var client = new SomeAzureClient(new Uri(endpoint), new DefaultAzureCredential());

// ❌ WRONG — connection string carries secret material
var client = new SomeAzureClient(connectionString);
```

`DefaultAzureCredential` resolves (in order):
1. **Local dev** — `az login` / Visual Studio / VS Code credentials
2. **CI** — `AZURE_CLIENT_ID` + `AZURE_CLIENT_SECRET` env vars
3. **Azure Container Apps** — system-assigned Managed Identity (IMDS)

---

## Aspire Integration (when available)

Prefer Aspire's `AddAzure*` helpers — they wire `DefaultAzureCredential` automatically:

```csharp
// AppHost/Program.cs
var blobs = storage.AddBlobs("blobs");
api.WithReference(blobs);

// Service/Extensions/BlobStorageExtensions.cs
builder.AddAzureBlobServiceClient("blobs"); // DefaultAzureCredential wired automatically
```

See the `aspire-package-pairs` skill for known hosting/integration package pairs.

---

## Direct Registration (when Aspire integration is unavailable)

When no Aspire integration package exists (e.g., ACS Email), register directly:

```csharp
// Read endpoint from configuration — never a connection string
var endpoint = new Uri(
    builder.Configuration.GetConnectionString("acs")
        ?? throw new InvalidOperationException("ConnectionStrings:acs is required."));

// Register as singleton — DefaultAzureCredential is thread-safe
builder.Services.AddSingleton(new EmailClient(endpoint, new DefaultAzureCredential()));
builder.Services.AddSingleton<IEmailService, AcsEmailService>();
```

**Configuration key pattern:** Always `ConnectionStrings:{resource-name}` — matches Aspire's convention so the wiring is uniform regardless of whether Aspire manages the resource.

---

## Terraform RBAC Module Pattern

Every Azure SDK MI adoption requires a Terraform RBAC module. Follow the `blob-storage-rbac` module as the reference implementation:

```hcl
# modules/acs-email-rbac/main.tf
resource "azurerm_role_assignment" "acs_email_sender" {
  for_each = var.container_app_principal_ids

  name               = uuidv5("url", "acs-email-rbac-${var.environment}-${each.key}-${var.acs_resource_id}")
  scope              = var.acs_resource_id
  role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/${local.role_id}"
  principal_id       = each.value
  principal_type     = "ServicePrincipal"
}
```

Key rules:
- Use `uuidv5("url", ...)` for deterministic role assignment names (prevents Terraform drift)
- Always `principal_type = "ServicePrincipal"` for system-assigned MIs
- Module variables: `{resource}_id`, `container_app_principal_ids` (map), `environment`

---

## Known Role IDs (CFP Compass)

| Azure Service | Role | Role ID |
|---|---|---|
| Blob Storage | Storage Blob Data Contributor | `ba92f5b4-2d11-453d-a403-e96b0029c9fe` |
| ACS Email | ACS Email Sender | `b9d4cd7b-d855-4f0c-b635-164d572a3f89` |

---

## ACS-Specific Notes

- **No Aspire hosting package** — `Aspire.Hosting.Azure.CommunicationServices` does not exist on NuGet. ACS has no local emulator.
- **Local dev:** Set `ConnectionStrings:acs` to your ACS endpoint in `appsettings.Development.json` or user secrets.
- **Never provision** `ACS-ConnectionString` as a Key Vault secret — only the endpoint URI (non-sensitive) should be in config.
- `EmailClient` constructor: `new EmailClient(Uri endpoint, TokenCredential credential)` — endpoint only, no key.

---

**Source:** Issues #1 (Blob Storage MI) and #3 (ACS Email MI), 2026-03-03.
