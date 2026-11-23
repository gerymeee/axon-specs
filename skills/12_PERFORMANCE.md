# 12 - Performance

**Purpose:** Identify likely sync costs and the correctness checks to preserve while measuring them.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

No hard throughput, batch, payload, retention, or latency limits were established. [Database choices](../db-design-choices.md) describe the costs below. Axon measurements are unavailable.

| Path | Design tradeoff and what to measure |
|---|---|
| Sync by UUID | The surrogate key and unique UUID each require an index. Measure UUID lookups and write costs separately before considering a different identifier strategy. |
| Dirty scan | The design derives pending work from `updated_at` and `synchronized_at`. Measure how sync cost changes with total and dirty row counts. A separate queue would add another piece of state that can drift from the record. |
| Scoped pull | Without delta pull the scope is reread on every sync. Measure row count, bytes, and parent joins. A cursor optimization must preserve tombstones, scope changes, and retries for missed parents (06 #5). |
| Parent and live-row lookup | §1 shows `idx_note_notebook` and SQLite `idx_note_notebook_live`. Check actual query plans and selectivity before adding an index. Extra indexes cost each write and the example keys may differ from the real access path. |
| Denormalized reads | Some duplicates support partial client datasets or preserve historical snapshots. Measure joins and write amplification before changing the schema, as removing a stored value can make a view depend on unavailable parents. |

At implementation time, time client selection, transport, server query, and local apply separately on a reproducible dataset. Record dataset size, dirty ratio, and application/schema versions so an apparent regression can be reproduced.
