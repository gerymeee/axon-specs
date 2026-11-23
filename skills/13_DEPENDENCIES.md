# 13 - Dependencies

**Purpose:** Understand the documented technology choices before introducing or upgrading dependencies.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

| Dependency or integration | Why it appears in the design | Upgrade or adoption trap |
|---|---|---|
| Supabase database API | The backend repository is defined as the integration point between clients and Supabase. | Record the real SDK/client and authentication boundary before changing it. A mismatch changes how scoped requests reach persistence. |
| Postgres | Central relational store in [database choices](../db-design-choices.md). Design examples use UUID, `timestamptz`, upserts, and partial unique indexes. | Validate index predicates and upsert ordering in the actual target store. Differences affect live-link uniqueness and conflict outcomes. |
| SQLite | Local client store for offline creation and updates. | Test the supported client SQLite versions through both fresh setup and existing data upgrades. A migration that only works on the developer’s engine can fail on the device. |
| Google Sign-In | Initial authentication requirement in [business logic](../business-logic-v1.0.md). | Verify login, expiry and server session verification when selecting or upgrading the integration. An identity change can break ownership continuity. |

Use the owning repository’s manifest and lockfile to establish exact package versions once available. Document a compatibility test for dependency changes that affect two components and link it to 04. No actual manifest, pinned versions, platform SDK ranges, or framework evaluations were available. The database document explains its UUID and sync choices, including alternatives, but records no library or framework rejection.
