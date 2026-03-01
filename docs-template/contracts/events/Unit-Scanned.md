**Event:** Unit Scanned

> **In this document:**  
>
> [[_TOC_]]

# Overview

The **Unit Scanned** event is emitted by the Conveyance domain whenever a unit (core, sub-assembly, or finished good) is scanned at a manufacturing site. It captures the operational context of the scan, including location, movement type, and scan outcome. It serves as the authoritative trigger for downstream processes requiring scan activity awareness.

Typical consumers include:

- **MPO Domain:** Populating the `MPOConveyanceScanLog` projection for production order-scoped queries. (This is a planned consumption.)
- **Analytics and Reporting:** Updating dashboard and operational KPIs in near real time. (This is a possible consumption.)
- **Validation Workflows:** Confirming that scanned units are in the correct state or location. (This is a possible consumption.)

---

# Publisher Details

**Domain:** MFG-CVY (Manufacturing Conveyance)

**Transport Mechanism:** `sbns-mfg.{env}.{region}` (Azure Service Bus)

**Transport Element:** `cvy.unit-scanned` (Topic)

**Authoritative Source:** `ConveyanceScanLog` (Cosmos DB container)

## Ingestion & Emission Flow

:::mermaid
flowchart LR
    subgraph CVY[Conveyance Domain]
        ScanSvc[Conveyance Scan Service API]
        CSL[ConveyanceScanLog]
    end

    ScanSvc --> CSL
    CSL --> CF[Cosmos DB Change Feed]
    CF --> Event[Emit Unit Scanned<br/>cvy.unit-scanned]

:::

**Flow description:**

1. A scan event is ingested via the Conveyance Scan Service API.
2. The validated and enriched record is written to the `ConveyanceScanLog` container.
3. The Cosmos DB Change Feed detects the insert and emits a `cvy.unit-scanned` event to the Service Bus topic.
4. The event is available to any authorized subscriber; the producer does not require knowledge of specific consumers.

## Lifecycle & Retention

**Emission:** Once per scan record insert into `ConveyanceScanLog`.

**Immutability:** Events are immutable; corrections are emitted as new `cvy.unit-scanned` events with updated data.

**Retention:** Event messages follow Service Bus topic retention (per namespace configuration). Under current policy, the authoritative record remains in `ConveyanceScanLog` indefinitely.

---

# Message Specifications

## System Properties

| Property        | Value                         | Description                                                  |
| --------------- | ----------------------------- | ------------------------------------------------------------ |
| `CorrelationId` | Unique correlation identifier | Used for distributed tracing across services. Matches payload `correlationId`. |
| `ContentType`   | `application/json`            | Declares payload format.                                     |
| `Subject`       | `UnitScanned`                 | Human-readable event type.                                   |

> **Note:** This topic is not session-enabled; ordering is not guaranteed across partitions.

## Application Properties
None

## Payload

```json
{
  "id": "018f3b2e-9c2d-7b8a-bc4a-8f1f2a6e9d3b",
  "siteId": "SITE01",
  "productionOrderNumber": "PO123456",
  "scannedAtUtc": "2025-09-03T14:22:15Z",
  "scannedBy": "operator1",
  "deviceId": "SCN-001",
  "deviceType": "RackScanner",
  "scanCategory": "Load",
  "movementType": "WarehouseToCart",
  "fromLocationType": "Warehouse",
  "fromLocationId": "WH-01",
  "toLocationType": "Cart",
  "toLocationId": "CART-22",
  "serialTag": "CORE-998877",
  "unitType": "Core",
  "quantity": 1,
  "correlationId": "6dbe87fd-fad7-4809-bebd-7c0cd925ee90",
  "source": "ScanService",
  "reliabilityLevel": "OperatorScanned",
  "schemaVersion": "1.0"
}
```

| Field                   | Type     | Required | Description                                                  |
| ----------------------- | -------- | :------: | ------------------------------------------------------------ |
| `id`                    | string   |    ✔️     | Unique identifier of the scan record (UUID v7).              |
| `siteId`                | string   |    ✔️     | Manufacturing site identifier where the scan occurred.       |
| `productionOrderNumber` | string   |    ✔️     | Associated MPO production order number |
| `scannedAtUtc`          | datetime |    ✔️     | UTC timestamp when the scan occurred.                        |
| `scannedBy`             | string   |    ✔️     | The operator username or service principal that performed the scan. |
| `deviceId`              | string   |    ✖️     | Logical device identifier (e.g., workstation, handheld scanner). |
| `deviceType`            | string   |    ✔️     | Scan modality (`ManualScanner`, `RackScanner`, `FixedReader`, `APIImport`) |
| `scanCategory`          | strign   |    ✔️     | Business context (`Load`, `Delivery`, `Transfer`)            |
| `movementType`          | string   |    ✔️     | Movement classification (e.g., `WarehouseToCart`, `PodToPaint`) |
| `fromLocationType`      | string   |    ✔️     | Source location type.                                        |
| `fromLocationId`        | string   |    ✔️     | Source location identifier.                                  |
| `toLocationType`        | string   |    ✔️     | Destination location type.                                   |
| `toLocationId`          | string   |    ✔️     | Destination location identifier.                             |
| `serialTag`             | string   |    ✔️     | Identifier of the core unit.                                 |
| `unitType`              | string   |    ✔️     | Unit classification (`Core`, `SubAssembly`, `FinishedGood`)  |
| `quantity`              | int      |    ✔️     | Number of units represented by this scan (default 1).        |
| `correlationId`         | string   |    ✔️     | Logical correlation identifier across systems. Matches the `correlationId` system property. |
| `source`                | string   |    ✔️     | Originating system/process.                                  |
| `reliabilityLevel`      | string   |    ✔️     | Data confidence level (`OperatorScanned`, `DevicePolled`, `Synthetic`). |
| `schemaVersion`         | string   |    ✔️     | Schema contract version.                                     |

> **Notes:**
>
> - Events are immutable; corrections are emitted as new `cvy.unit-scanned` events.
> - `correlationId` is used across all messages to enable distributed tracking and diagnostics.
> - The authoritative record remains in `ConveyanceScanLog` indefinitely under the current retention policy.

## AsyncAPI Specification

```yaml
channels:
  cvy.unit-scanned:
    address: cvy.unit-scanned
    description: >
      Published when a unit (core, sub‑assembly, or finished good) is scanned
      at a manufacturing site. Contains operational context and scan outcome.
    bindings:
      amqp:
        queue:
          is: topic
    messages:
      - $ref: '#/components/messages/UnitScanned'
    tags:
      - name: cvy
components:
  messages:
    UnitScanned:
      name: UnitScanned
      title: Unit Scanned
      summary: Published when a scan record is inserted into ConveyanceScanLog.
      contentType: application/json
      bindings:
        amqp:
          bindingVersion: 0.2.0
          headers:
            properties:
              subject:
                type: string
                const: "UnitScanned"
                description: >
                  Logical name of the event used for filtering, diagnostics, and envelope inspection.
              contentType:
                type: string
                const: "application/json"
                description: >
                  MIME type of the payload content.
              correlationId:
                type: string
                description: >
                  Identifier for end-to-end distributed tracing.
  schemas:
    UnitScanned:
      type: object
      description: >
        Represents the occurrence of a scan event in the Conveyance domain.
        This is an immutable fact emitted for downstream processing.
      required:
        - id
        - siteId
        - productionOrderNumber
        - scannedAtUtc
        - scannedBy
        - deviceType
        - scanCategory
        - movementType
        - fromLocationType
        - fromLocationId
        - toLocationType
        - toLocationId
        - serialTag
        - unitType
        - quantity
        - correlationId
        - schemaVersion
      properties:
        id:
          type: string
          description: Unique identifier of the scan record (UUID v7).
        siteId:
          type: string
          description: Manufacturing site identifier where the scan occurred.
        productionOrderNumber:
          type: string
          description: Associated MPO production order number, if available.
        scannedAtUtc:
          type: string
          format: date-time
          description: UTC timestamp when the scan occurred.
        scannedBy:
          type: string
          description: Operator username or service principal performing the scan.
        deviceId:
          type: string
          nullable: true
          description: Logical device identifier.
        deviceType:
          type: string
          description: Scan modality.
        scanCategory:
          type: string
          description: Business context.
        movementType:
          type: string
          description: Movement classification.
        fromLocationType:
          type: string
          description: Source location type.
        fromLocationId:
          type: string
          description: Source location identifier.
        toLocationType:
          type: string
          description: Destination location type.
        toLocationId:
          type: string
          description: Destination location identifier.
        serialTag:
          type: string
          description: Identifier of the core unit.
        unitType:
          type: string
          description: Unit classification.
        quantity:
          type: integer
          description: Number of units represented by this scan.

```

---

# Governance

**Write Access:** Only the Conveyance Scan Service API writes to `ConveyanceScanLog`, which triggers this event.

**Read Access:** Any authorized subscriber to the `cvy.unit-scanned` topic.

Entra group assignments for read access are as follows:

| Entra Group            | Access                              |
| ---------------------- | ----------------------------------- |
| `AZURE_DEV_MFGTEAM`    | Read in Dev/Test.                   |
| `AZURE_DEV_DEVOPS`     | Read in Dev/Test, QA, E2E, and PRD. |
| `AZURE_DEV_ARCHITECTS` | Read in Dev/Test and QA.            |

Limited-time access (via Azure Privileged Identity Management [PIM]) may be granted on a need basis when troubleshooting requires it.

**Schema Governance:** Changes to the event payload must be versioned and documented; breaking changes require a new topic name.

---

# Related Specifications

**Related Data Models:**

- [**Conveyance Scan Log**](/Specifications/Architecture-Specifications/Data-Management/Conveyance-Scan-Log.md) - Authoritative source of the event.
- [**Scan Log by User**](/Specifications/Architecture-Specifications/Data-Management/Scan-Log-by-User.md) - Alternate index for querying scans by operator.
- [**MPO Conveyance Scan Log**](/Specifications/Architecture-Specifications/Data-Management/MPO-Conveyance-Scan-Log.md) - MPO-domain projection populated by consuming this event.

**Related Process Flows:**

- [**Conveyance Scan Added**](/Specifications/Architecture-Specifications/Process-Flows/Conveyance-Scan-Added.md): End-to-end process for receiving, validating, and persisting scan events before emission.





