# 11 - Testing

**Purpose:** Use the design’s edge cases to shape tests and distinguish examples from application evidence.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

No project test suite, fixtures, CI, or test commands were available. The two verified checks in 06 #1 and #4 used Python SQLite 3.45.1 with the source’s example `note` schema and dirty/acknowledgement expressions. They establish behavior of the examples.

| Proposed drill | What must be observable |
|---|---|
| Two offline clients create related rows | Distinct UUIDs and correct relationships after two repeated exchanges. |
| Child arrives before parent | Child appears after the parent arrives and retry runs. An intentionally out-of-scope parent remains outside that account’s data. |
| Archive and same-second tie | The documented delete tie rule applies. Standard views and aggregates hide the archived row while scoped peers receive its tombstone. |
| Dirty local edit during pull and during push acknowledgement | Pull preserves a dirty row. An acknowledgement for an older snapshot leaves any newer edit eligible for push. |
| Fresh install and an older database carrying real-shaped fictional rows | Migration creates the same expected columns and preserves legacy field data and compatible payloads. |
| Different roles and resource scopes | The API returns only eligible rows and stamps actor fields from the authenticated session. |
| Candidate package | QA/system evidence supports promotion, and independent testing uses the exact package to be approved (see 10). |

Use a controlled clock and transport in unit tests so same-second and in-flight cases are repeatable. Use actual SQLite/Postgres in integration tests for uniqueness, constraints, and merge ordering, since mocks skip database comparison semantics. For a manual drill, use a staged environment and fictional records, record pre/post row stamps on both clients, and match screenshots or logs to the tested version.
