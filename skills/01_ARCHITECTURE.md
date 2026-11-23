# 01 - Architecture

**Purpose:** Read first when tracing a feature across the clients, API, and database.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

Axon’s repository instructions assign the web and Android clients to their own projects and place an API between those clients and Supabase. The offline-first design describes a SQLite client accepting edits locally and synchronizing through the API to central Postgres. The Android and web sync implementations, including whether web stores data offline, remain unverified.

| Component | Responsibility and evidence |
|---|---|
| [axon-android](../../axon-android/AGENTS.md) | Android application. SQLite is the client database in the design ([database choices](../db-design-choices.md), §1). |
| [axon-web](../../axon-web/AGENTS.md) | Web application, including regulatory compliance responsibilities. Its persistence and routing are unspecified. |
| [axon-api](../../axon-api/AGENTS.md) | Connects both clients to the Supabase database API. The design places server-derived attribution and scoped exchange across this boundary (see 09). |
| [axon-specs](../AGENTS.md) | Product requirements, design rationale, and release policy. See [business logic](../business-logic-v1.0.md) for draft requirements. |

**Documented sync flow.** Create or change a client record using its UUID and bump its change stamp. Push dirty records through the API. Resolve conflicts at the server and return the scoped rows, including tombstones. Pull applies eligible incoming rows, preserves dirty local edits, and retries children whose parents are missing. See 04 #1–#6.

### Decision: Offline UUID identity (date and author unrecorded)
**Status:** proposed for Axon. The choice is documented and implementation is unverified.
**Context.** Client-created rows need stable identity before the first connection.
**Choice.** Use a shared UUID with independent integer keys in each database.
**Alternatives.** Server-assigned integer identity would require connectivity at creation. UUID-only primary keys would remove an index but change the documented local indexing tradeoff.
**Consequences.** Sync can address records independently of numeric IDs. Both stores maintain their own primary key and UUID uniqueness (see 07).

### Decision: Timestamp-based row conflict resolution (date and author unrecorded)
**Status:** proposed for Axon. The design describes the choice.
**Context.** Multiple devices may edit the same row offline.
**Choice.** Use row-level last-write-wins with a deletion tie rule.
**Alternatives.** Field-level merge is a redesign candidate. The source records no evaluated rejection.
**Consequences.** One stamp per row simplifies sync gating. Concurrent changes to different fields can still lose one edit (see 06 #3).

### Ranked design debt

1. Specify version-aware push acknowledgement and timestamp tie handling before sync ships. Losing a newer local edit can look like a completed sync.
2. Define a durable orphan retry and scoped pull contract before choosing cursor semantics. A child can otherwise remain missing.
3. Finalize the MVP role matrix and account/session model before exposing routes. Blank permissions leave the intended access boundary undefined.
