# Cross-Agent Handoff: Dallas — ADR-013 Update Required

**From:** Scribe (on behalf of Parker & Ripley)  
**Date:** 2026-03-01  
**Issue:** #1 — Blob Storage Managed Identity  
**Status:** Planning complete; awaiting Dallas action

## Action Item

**ADR-013 (Aspire packages list) must include `Aspire.Hosting.Azure.Storage`** in AppHost dependencies.

## Reason

Ripley's application implementation for Issue #1 requires `Aspire.Hosting.Azure.Storage` to wire the Azurite emulator for local development and to declare the blob storage resource in the Aspire service model.

**Current gap:** The architecture spec lists Aspire packages for SQL, Redis, and Service Bus, but omits Azure Storage.

**Required for:**
- `builder.AddAzureStorage("storage").RunAsEmulator()` in AppHost/Program.cs
- `var blobs = storage.AddBlobs("blob-storage")` for container declarations
- `.WithReference(blobs)` bindings to Api/Workers projects

## Artifact

Ripley's implementation plan: `.squad/agents/ripley/blob-storage-mi-plan.md` — see AppHost wiring section (lines 62-97).

## Next Step

Update ADR-013 with `Aspire.Hosting.Azure.Storage Version="9.*"` in the AppHost NuGet package list. No changes to other decisions required.
