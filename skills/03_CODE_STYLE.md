# 03 - Code Style

**Purpose:** Keep naming, guard comments, and history useful to engineers reviewing changes.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

| Practice | Reason and failure |
|---|---|
| Put the reason beside a compatibility or sync guard. For example, on a normal read explain why `archived_at IS NULL` belongs here while pull keeps tombstones. | A later cleanup can otherwise make deleted rows reappear or stop deletions from reaching peers. See 06 #2. |
| Use `uuid` and `*_uuid` for shared identity, and keep `id` and `synchronized_at` outside shared payloads. | Integer keys can collide across stores, and transmitting a local sync marker can hide unsent work. See 04 #1 and #2. |
| Validate closed vocabularies across the API and both data stores before emitting a new value from a client. | An older client or a storage constraint can reject an entire batch. See 04 #5. |
| When defining errors and logs, preserve the operation and failure stage and omit tokens and raw sensitive data. | Operators need to distinguish failed authorization, merge, and retry without creating a parallel store of sensitive records. See 05 and 09. |
| Use the scoped imperative commit format in [git guidelines](../git-guidelines.md), with a summary of at most 50 characters. Explain reasons in the body for changes with lasting consequences. | Scope explains which repository contract changed. The body preserves the failure a future maintainer needs to avoid. |

**Evidence.** The naming and Git rules are documented. Logging and error handling above are proposed review practices. No formatter, linter, framework error type, or logging library could be verified.
