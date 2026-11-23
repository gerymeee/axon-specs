# 08 - API

**Purpose:** Read before defining an endpoint or changing an API/client contract.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

[API instructions](../../axon-api/AGENTS.md) identify the API as the boundary between both clients and Supabase. No route paths, HTTP methods, response envelope, error codes, validator names, or version prefix could be verified.

| Planned operation | Evidence and access |
|---|---|
| Google Sign-In | Requirement 1 in [business logic](../business-logic-v1.0.md). Callback, session model, and enforcement remain unspecified. |
| Sync push | [Database choices](../db-design-choices.md) §§4–6 describe authenticated server-stamped actors, field allowlists, and timestamp ordering. Per-resource write permissions are unresolved. |
| Sync pull | §§3 and 5–6 describe permission-scoped datasets, tombstones, and merge behavior. Public resource access and cursor shape are unresolved. |

### Adding an endpoint

1. Record the resource’s allowed actors and data scope before assigning a route. The draft role table cannot authorize a concrete resource (see 09).
2. Define the method, route, request fields, response and error shapes, and version compatibility with affected clients. Shared field names belong in 04 so a client release cannot silently drift.
3. Validate shared identity, supported values, and incoming fields at the boundary. Specify retry or acknowledgement semantics for writes so a repeated request does not create duplicates or clear newer edits.
4. Exercise success, invalid input, access outside the permitted scope, and an older caller before publishing the contract. Record real route and validator names here when the implementation exists.

See 04 #1–#5 and 06 #4 before adding endpoints that exchange synced rows.
