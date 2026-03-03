**Event:** Production Order State Updated (`mpo.production-orders.updated`)

> **In this document:**  
>
> [[_TOC_]]

---

# Overview

The Conveyance (CVY) domain consumes the **Production Order State Updated** event to keep its local projection of production order data (`ConveyanceLocalProductionOrders`) aligned with the authoritative manufacturing production order records maintained by MFG-MPO.

When a production order is created or updated in MPO, this event notifies CVY of the change. CVY uses the `ProductionOrderStatus` application property to filter for only those orders in the correct state for processing. At this time, CVY processes only events where `ProductionOrderStatus = OrderNextUnitInitiated`.

If CVY requires the full production order details, it queries MPO directly using the event `productionOrderNumber`.

---

# Subscription Details

| Property                    | Value                                         |
| --------------------------- | --------------------------------------------- |
| **Domain**                  | MFG-CVY (Manufacturing Conveyance)            |
| **Transport Mechanism**     | `sbns-mfg.{env}.{region}` (Azure Service Bus) |
| **Subscription Name**       | `mfg-cvy`                                     |
| **Topic**                   | `mpo.production-orders.updated`               |
| **Content Type**            | `application/json`                            |
| **Expected Schema Version** | `1.0`                                         |

**Subscription Filter Example**  
To ensure CVY only processes production orders in the correct state, the subscription applies a SQL filter on the `ProductionOrderStatus` application property:

```sql
ProductionOrderStatus = 'OrderNextUnitInitiated'
```

This filter is configured at the Service Bus subscription level so that only matching messages are delivered to the CVY handler.

---

:::mermaid
flowchart TB
    subgraph CVY[Conveyance Domain]
        Sub[Service Bus Subscription<br/>mpo.production-orders.updated]
        Filter[Message Filter<br/>ProductionOrderStatus = OrderNextUnitInitiated]
        Handler[ProductionOrderStateUpdatedHandler<br/>Azure Function]
        CLPO[ProductionOrders]
    end

    Sub --> Filter
    Filter --> Handler
    Handler --> CLPO
:::

**Flow Description:**

1. CVY subscribes to the `mpo.production-orders.updated` topic via a dedicated Service Bus subscription.
2. The subscription filters the `ProductionOrderStatus` application property to deliver messages with the value `OrderNextUnitInitiated`.
3. The `ProductionOrderStateUpdatedHandler` function processes each filtered message:
   - Deserializes the JSON payload.
   - Validates `schemaVersion` and required fields.
   - Maps payload fields to the `ProductionOrders` schema.
4. The handler performs an **idempotent upsert** into `ConveyanceLocalProductionOrders` keyed by `PartitionKey = siteId` and `RowKey = tagNumber`.
5. If additional details are required, the handler queries MPO for the latest production order state.

---

# Message Contract (as consumed)

## System Properties

| Property        | Value                         | Description                                                  |
| --------------- | ----------------------------- | ------------------------------------------------------------ |
| `MessageId`     | Auto-assigned                 | A unique identifier for the message is in the Service Bus.   |
| `ContentType`   | `application/json`            | Declares payload format.                                     |
| `CorrelationId` | The production order number   | Used for distributed tracing and correlation with MPO records. |
| `Label`         | `ProductionOrderStateUpdated` | Human-readable event type.                                   |

> **Note:** This topic is not session-enabled; ordering is not guaranteed across partitions.

## Application Properties

| Property                | Description                                                  | Possible Values                                      |
| ----------------------- | ------------------------------------------------------------ | ---------------------------------------------------- |
| `ProductionOrderStatus` | The current state of the production order. Used for message filtering. | String - CVY processes only `OrderNextUnitInitiated` |
| `SchemaVersion`         | Schema contract version.                                     | String - Expected value is `1.0`                     |

## Payload

```json
{
  "productionOrderNumber": "123456",
  "productionOrderStatus": "OrderNextUnitInitiated",
  "tagNumber": "78910",
  "siteId": 100,
  "podNumber": "40"
}
```

| Field                   | Type   | Required | Description                                 |
| ----------------------- | ------ | :------: | ------------------------------------------- |
| `productionOrderNumber` | string |    ✔️     | Unique identifier for the production order. |
| `productionOrderStatus` | string |    ✔️     | Current status of the production order.     |
| `tagNumber`             | string |    ✔️     | Serial Tag Number of the production order.     |
| `siteId`                | number |    ✔️     | Identifier for the site associated with the production order.     |
| `podNumber`             | string |    ✔️     | Identifier for the pod associated with the production order.     |

---

# Processing Rules

**Idempotency**  
The handler must be idempotent; repeated delivery of the same event must not create duplicates or corrupt data.

**Schema Validation**  
Messages with missing required fields or unsupported/missing `schemaVersion` are rejected and sent to the dead-letter queue.

**Filtering**  
Only messages with `ProductionOrderStatus = OrderNextUnitInitiated` are processed; all others are ignored at the subscription filter level.

**Partial Updates**  
All fields in the payload overwrite the local record's values for that `productionOrderNumber` / `tagNumber`.

---

# Error Handling

**Transient Failures**  
Retry according to the Azure Functions / Service Bus trigger retry policy.

**Poison Messages**  
Messages repeatedly failing processing are moved to the subscription's dead-letter queue for manual review.

**Logging**  
All processing outcomes (success, validation failure, dead letter) are logged with the `CorrelationId` (production order number).

---

# Governance

**Read Access**  
Only the Conveyance Production Orders projection handler subscribes to this topic.

Entra group assignments for read access are as follows:

| Entra Group            | Access                              |
| ---------------------- | ----------------------------------- |
| `AZURE_DEV_MFGTEAM`    | Read in Dev/Test.                   |
| `AZURE_DEV_DEVOPS`     | Read in Dev/Test, QA, E2E, and PRD. |
| `AZURE_DEV_ARCHITECTS` | Read in Dev/Test and QA.            |

Limited-time access (via Azure Privileged Identity Management [PIM]) may be granted on a need basis when troubleshooting requires it.

**Schema Governance**  
Any changes to the payload contract or application/system properties must be coordinated with MPO and validated against the handler's schema version support.

---

# Related Specifications

**Related Data Models:**

- [**Conveyance Local Production Orders**](/Specifications/Architecture-Specifications/Data-Management/Conveyance-Local-Production-Orders.md): Updated by this event to reflect the current state of the MFG-MPO production order.

**Related Process Flows:**

- [**Manufacturing Production Order Synchronization**](/Specifications/Architecture-Specifications/Process-Flows/Manufacturing-Production-Order-Synchronization.md): End-to-end process for keeping `ConveyanceLocalProductionOrders` aligned with MPO.



