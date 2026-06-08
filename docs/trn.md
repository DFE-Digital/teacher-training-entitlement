# TRN (Teacher Reference Number) Acquisition Flow

This document describes how TTE obtains and manages Teacher Reference Numbers (TRNs) for users.

## Overview

The TRN acquisition process involves two main flows:
1. **Authentication flow** - Capturing refresh tokens when users authenticate without a TRN
2. **Application acceptance flow** - Requesting TRN creation via the activation endpoint

## Flow Diagram

```mermaid
---
layout: elk
---

flowchart TD
    A(["User authenticates via Teacher Auth"]) --> B{"Has TRN?"}
    B -- Yes --> F["Proceed with normal flow"]
    B -- No --> C["Store refresh_token from request"]

    subgraph BackgroundJobs [Background Jobs]
        direction TB
        D["Refresh token daily<br/>(EnqueueTokenRefreshesJob)"]
        G["Poll TRN activation daily<br/>(EnqueueTrnActivationChecksJob)"]
    end

    C --> D

    E["Application accepted"] --> H["Request TRN via activation endpoint"]
    H --> I{"TRN created?"}

    %% Move the TRN Created 'Yes' path to the right
    I -- Yes --> JR["Store TRN for user"]

    I -- No --> G
    G --> JR

    %% Future webhook path outside of Daily Maintenance
    W["(Future) Receive TRN via TRS webhook"]
    I -- No --> W
    W --> JR

    classDef indigo stroke:#818cf8,fill:#eef2ff
    classDef teal stroke:#2dd4bf,fill:#f0fdfa
    classDef green stroke:#4ade80,fill:#f0fdf4
    classDef orange stroke:#fb923c,fill:#fff7ed
    classDef fuchsia stroke:#e879f9,fill:#fdf4ff

    class A,F indigo
    class B,C orange
    class D,G teal
    class E,H,I,JR green
    class W fuchsia
```

## Process Details

### Authentication Flow

1. When a user authenticates via Teacher Auth, we check if they already have a TRN
2. If they have a TRN, we store it
3. If they don't have a TRN, we store the `refresh_token` from the authentication request for later use

### Application Acceptance Flow

1. When an application is accepted, we request a TRN via the activation endpoint
2. If the TRN is created immediately, we store it
3. If the TRN is not created immediately, we poll the activation endpoint daily until we receive it

### Background Jobs

The system runs background jobs to manage TRN acquisition:

| Job | Schedule | Purpose |
|-----|----------|---------|
| `EnqueueTokenRefreshesJob` | Hourly | Refreshes tokens for users awaiting application acceptance (no `trn_requested_at` set) |
| `EnqueueTrnActivationChecksJob` | Daily at 6am | Re-polls TRN activation for users where TRN was requested but not yet returned |

The token refresh job keeps refresh tokens valid while users wait for their application to be accepted. Once an application is accepted, `RequestTrnJob` is enqueued which calls the activation endpoint. If the TRN isn't returned immediately, the daily activation check job will continue polling until the TRN is received.

### Future Enhancement

A future enhancement will allow receiving TRNs via a webhook, providing real-time notification when a TRN is created.
