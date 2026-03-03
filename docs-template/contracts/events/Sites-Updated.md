**Event:** Sites Updated (`lds.sites.updated`)

> **In this document:**  
>
> [[_TOC_]]

---

# Overview

The Conveyance (CVY) domain consumes the **Sites Updated** event to keep its local projection of site metadata (`ConveyanceLocalSites`) in sync with the enterprise-wide site registry maintained by MFG-LDS. When a site is added, updated, or marked obsolete in LDS, this event ensures Conveyance has the latest site information for scan validation, routing, and reporting.

---

# Subscription Details

| Property                    | Value                                         |
| --------------------------- |-----------------------------------------------|
| **Domain**                  | MFG-CVY (Manufacturing Conveyance)            |
| **Transport Mechanism**     | `sbns-mfg.{env}.{region}` (Azure Service Bus) |
| **Subscription Name**       | `mfg-cvy`                                     |
| **Topic**                   | `lds.mps.sites.updated`                       |
| **Content Type**            | `application/json`                            |
| **Expected Schema Version** | `1.0`                                         |

---

# Consumption Flow

:::mermaid
flowchart TB
    subgraph CVY[Conveyance Domain]
        Sub[Service Bus Subscription<br/>lds.sites.updated]
        Handler[SitesUpdatedHandler<br/>Azure Function]
        CLS[ConveyanceLocalSites]
    end

    Sub --> Handler
    Handler --> CLS
:::

**Flow Description:**

1. Conveyance subscribes to the `lds.mps.sites.updated` topic via a dedicated Service Bus subscription.
2. The `SitesUpdatedHandler` function queries `/mfg/lds/v1/sites` for the updated sites data.
3. The handler overwrites the local Sites data with the fresh data returned from the API.

---

# Message Contract (as consumed)

## System Properties

| Property        | Value                         | Description                                                  |
| --------------- | ----------------------------- | ------------------------------------------------------------ |
| `MessageId`     | Auto-assigned                 | A unique identifier for the message is in the Service Bus.   |
| `CorrelationId` | Unique correlation identifier | Used for distributed tracing across services; matches payload `correlationId` if present. |
| `ContentType`   | `application/json`            | Declares payload format.                                     |
| `Label`         | `SitesUpdated`                | Human-readable event type.                                   |

> **Note:** This topic is not session-enabled; ordering is not guaranteed across partitions.

## Application Properties

CVY currently uses no application properties for this incoming message.

## Payload

LDS sends an empy message notifying consumer to query the API for updated data.
---


# Error Handling

**Transient Failures**  
Retry according to the Azure Functions / Service Bus trigger retry policy.

**Poison Messages**  
Messages repeatedly failing processing are moved to the subscription's dead-letter queue for manual review.

**Logging**  
All processing outcomes (success, validation failure, dead-letter) are logged with `correlationId` if present.

---

# Governance

**Read Access**  
Only the Conveyance Sites projection handler subscribes to this topic.

Entra group assignments for read access are as follows:

| Entra Group            | Access                              |
| ---------------------- | ----------------------------------- |
| `AZURE_DEV_MFGTEAM`    | Read in Dev/Test.                   |
| `AZURE_DEV_DEVOPS`     | Read in Dev/Test, QA, E2E, and PRD. |
| `AZURE_DEV_ARCHITECTS` | Read in Dev/Test and QA.            |

Limited-time access (via Azure Privileged Identity Management [PIM]) may be granted on a need basis when troubleshooting requires it.

**Schema Governance**  
Any changes to the payload contract must be coordinated with LDS and validated against the handler's schema version support.

---

# Related Specifications

**Related Data Models:**

- [**Conveyance Local Sites**](/Specifications/Architecture-Specifications/Data-Management/Conveyance-Local-Sites.md): Updated by this event to reflect the current MFG-LDS site list.

**Related Process Flows:**

- [**Sites Synchronization**](/Specifications/Architecture-Specifications/Process-Flows/Sites-Synchronization.md): End-to-end process for keeping `ConveyanceLocalSites` aligned with LDS.



