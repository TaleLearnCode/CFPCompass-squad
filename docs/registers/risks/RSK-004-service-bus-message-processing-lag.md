---
title: "RSK-004: Service Bus Message Processing Lag"
description: Azure Service Bus message processing lag may cause delays in asynchronous workflows, impacting user experience.
tags:
  - risk
  - risk-register
  - azure-service-bus
---

# Service Bus Message Processing Lag

**ID:** RSK-004

## Risk Statement

Azure Functions consuming Service Bus topics may experience processing delays under periods of elevated submission load, causing CFPs to remain in a "Processing" status for longer than expected after submission, and causing notification emails (confirmations, deadline reminders, admin moderation alerts) to be delayed past the platform's informal SLO of 2 minutes.

## Root Cause / Trigger

- Azure Functions on the Consumption plan scale based on incoming message volume; scaling is not instantaneous.
- Functions on Consumption plan have cold starts (typically 1–3 seconds) that add to per-message processing latency when scaling up from zero.
- High-volume submission bursts — for example, when a major conference opens its CFP and many organizers submit simultaneously — can create a queue backlog before Functions scale out to handle the load.
- All five Function processors (`CfpSubmissionProcessor`, `UserAccountProcessor`, `NotificationProcessor`, `StatusUpdateProcessor`, `CacheInvalidationProcessor`) compete for Consumption plan compute resources in the same Function App.

## Impact Assessment

- **Submitting organizers:** See "Processing" status in the submission confirmation page for longer than expected. Confirmation email may be delayed by minutes rather than arriving near-instantly.
- **Admin moderation queue:** New submissions appear in the admin queue with delay proportional to `CfpSubmissionProcessor` backlog. Time-sensitive moderation (e.g., organizer requests fast approval) is affected.
- **Deadline reminder emails:** If `NotificationProcessor` is delayed, deadline reminder emails may be sent after the deadline window (though this is only relevant if the reminder job coincides with a processing backlog).
- **Data consistency:** Eventual consistency is an accepted design principle (ADR-007). Delays of minutes are architecturally tolerable — no data is lost.
- **User perception:** Most harmful when processing lag exceeds 10 minutes; users at that threshold may assume their submission failed and resubmit (creating duplicate detection work for admins).

## Likelihood

**Low** for MVP (expected submission volume is low and sporadic; queue backlogs are unlikely at launch).

**Medium** if the platform gains significant community traction and submission volumes grow — particularly during popular CFP windows (e.g., major .NET or cloud conferences opening their CFPs).

## Severity

**Low**

Eventual consistency is accepted by design (ADR-007). Submission data is not lost — the Service Bus topic retains messages with a 14-day TTL. Dead-letter queue captures failures after 3 retry attempts. Processing delays of minutes do not cause data loss, only user experience degradation and email timing imprecision.

## Mitigation Strategy

- **Automatic scale-out:** Azure Functions on Consumption plan automatically scale out based on Service Bus backlog depth. No manual intervention is required for normal traffic spikes.
- **Dead-letter queue:** All Service Bus topics are configured with `maxDeliveryCount = 3`. After 3 failed delivery attempts, messages land in the dead-letter queue for investigation and replay — preventing silent message loss.
- **`StatusUpdateProcessor`:** Provides visibility into per-submission processing state via the `/api/v1/submissions/{id}/status` polling endpoint. Users can observe real-time processing progress rather than assuming failure.
- **Separate Function Apps:** If processing lag becomes a persistent concern, `NotificationProcessor` can be moved to a separate Function App to isolate notification latency from submission processing backlog.
- **Service Bus Standard tier:** Supports multiple topics and subscriptions with message ordering and duplicate detection (ADR-007). Queue depth metrics are available natively in Azure Monitor.

## Detection Signals

- Azure Monitor alert: Service Bus active message count > 50 on any topic for more than 5 minutes (indicates backlog building faster than Functions are processing).
- Azure Monitor alert: Service Bus dead-letter queue depth > 0 on any topic (indicates processing failures, not just lag).
- Azure Monitor alert: Service Bus message age (time-in-queue) > 5 minutes for any message (SLO breach signal).
- Application Insights: Azure Function execution duration P95 > 10 seconds (indicates individual processing is slow, not just queued).
- Application Insights: Azure Function failure rate > 2% over 10-minute window (indicates systemic processing errors).

## Contingency Plan

1. Investigate dead-letter queue for failure patterns. If messages are failing due to SQL cold start during processing burst, increase Function `functionTimeout` and Service Bus lock timeout in `host.json`.
2. If backlog is growing due to Functions not scaling fast enough, temporarily configure a higher `maxConcurrentCalls` in the Service Bus trigger binding to increase parallelism per Function instance.
3. Replay dead-letter messages once the root cause of failures is resolved (via Service Bus Explorer or Azure CLI `az servicebus topic dead-letter`).
4. For persistent high-volume lag, evaluate migrating from Consumption to Premium plan Functions for predictable latency and no cold starts.
5. Communicate processing delays to users via a status banner on the submission confirmation page if lag exceeds 10 minutes.

## Review Schedule

Review at MVP launch (first 30 days), then at each major feature release that adds new Service Bus topics or processors. Re-evaluate the Consumption plan choice if dead-letter queue activity becomes routine or if processing lag complaints from admins increase.
