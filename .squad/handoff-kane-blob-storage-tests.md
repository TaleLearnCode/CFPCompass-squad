# Cross-Agent Handoff: Kane — Integration Test Plan Required

**From:** Scribe (on behalf of Ripley)  
**Date:** 2026-03-01  
**Issue:** #1 — Blob Storage Managed Identity  
**Status:** Planning complete; awaiting Kane action (source code phase)

## Action Item

**Integration test plan for blob upload/download/delete against Azurite emulator is needed once source exists.**

## Scope

Once Ripley's blob storage implementation is complete (IBlobStorageService, BlobStorageService, Aspire wiring), Kane must write integration tests covering:

1. **Upload operation** — `IBlobStorageService.UploadAsync` succeeds; returned URI is plain (no SAS params like `?sv=`, `?sig=`)
2. **Download operation** — `IBlobStorageService.DownloadAsync` retrieves uploaded blob as stream; content matches
3. **Delete operation** — `IBlobStorageService.DeleteAsync` removes blob; subsequent Exists returns false
4. **Local dev target** — Tests run against Azurite emulator (via Aspire) without Azure credentials

## Acceptance Criteria Checklist

- [ ] `dotnet run --project src/apphost/CFPCompass.AppHost` starts Azurite and integration tests execute
- [ ] Upload test verifies plain blob URI (no `?sv=`, `?sig=`, or SAS query params)
- [ ] Download test verifies stream content integrity
- [ ] No `StorageSharedKeyCredential`, `BlobSasBuilder`, or `GenerateSasUri` anywhere in test code
- [ ] Tests pass against Azurite emulator (dev environment only)

## Reference

Implementation plan: `.squad/agents/ripley/blob-storage-mi-plan.md` — see Acceptance Criteria Checklist (lines 326-335) for full test requirements.

## Next Step

Begin test design once Ripley opens PR with application source code. Target: unit tests mock `IBlobStorageService`; integration tests call live Azurite via DI container.
