# Skill: Aspire Package Pairs

**When:** Adding a new Azure resource to the .NET Aspire service model.

**Pattern:** Every Azure resource in Aspire requires **two** packages that travel as a pair:

| Package Type | Installed In | Purpose | Example |
|---|---|---|---|
| **Hosting** (`Aspire.Hosting.Azure.*`) | AppHost | Resource declaration + emulator wiring (`RunAsEmulator()`, `RunAsContainer()`) | `Aspire.Hosting.Azure.Storage` |
| **Integration** (`Aspire.Azure.*`) | Service project (e.g., Infrastructure) | DI registration, health checks, telemetry, `DefaultAzureCredential` | `Aspire.Azure.Storage.Blobs` |

**Rule:** When updating ADR-013 or any Aspire dependency list, always add both the hosting package AND the integration package. Omitting either leaves a gap — the hosting package without the integration package means the emulator runs but no service can connect; the integration package without the hosting package means DI is configured but no resource exists in the local Aspire model.

**Known pairs in CFP Compass:**

| Azure Resource | Hosting Package | Integration Package |
|---|---|---|
| Service Bus | `Aspire.Hosting.Azure.ServiceBus` | `Aspire.Azure.Messaging.ServiceBus` |
| Redis | `Aspire.Hosting.Azure.Redis` | `Aspire.StackExchange.Redis` |
| SQL | `Aspire.Hosting.Azure.Sql` | `Aspire.Azure.Data.Sql` |
| Blob Storage | `Aspire.Hosting.Azure.Storage` | `Aspire.Azure.Storage.Blobs` |
| ACS | `Aspire.Hosting.Azure.CommunicationServices` | *(TBD — integration package not yet listed)* |

**Source:** Learned from ADR-013 update for Issue #1 (Blob Storage MI). The AppHost hosting package was added in an earlier update, but the integration package was missed — creating a spec gap that Ripley's implementation plan caught.
