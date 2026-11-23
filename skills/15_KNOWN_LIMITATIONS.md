# 15 - Known Limitations

**Purpose:** Check which parts of the handoff are still provisional before making implementation decisions.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

| Priority | Status and evidence | Impact |
|---|---|---|
| 1 | **Verified baseline gap.** Local Git object stores were empty, GitHub returned no branches, and only instructions and planning docs were present. | Build paths, live routes, CI, operational history, schema snapshots, and test coverage are unknown. |
| 2 | **Verified spec incompleteness.** [Business logic](../business-logic-v1.0.md) retains project/feature placeholders and empty role descriptions. [Git guidelines](../git-guidelines.md) retain example product prefixes. | Access behavior and product tag names cannot be inferred safely from the templates. |
| 3 | **Verified example limitation.** The acknowledgement in [database choices](../db-design-choices.md) §6 can clear a newer edit in the in-memory example (06 #4). | Copying that expression without matching the sent version can silently lose pending work. |
| 4 | **Documented tradeoff.** Row-level timestamps decide conflicts, and timestamp ties and client clock skew affect which edit survives. | Two offline edits to different fields can lose one change. |
| 5 | **Unspecified behavior.** Durable orphan retry and deletion retention are unverified, as are the concrete data privacy controls and debug configuration. | A future cursor or cleanup policy could prevent children or tombstones from reaching peers. |

### Redesign candidates in priority order

1. Bind acknowledgements to the accepted row version and test the in-flight edit interleaving (06 #4).
2. Replace clock-dependent conflict ordering or introduce merge behavior if real workloads show frequent conflicting edits. Capture expected ties and losses before changing semantics (06 #3).
3. Consider scoped delta pull only after measuring full-pull cost and specifying handling for skipped children, scope changes and tombstones (06 #2, #5 and 12).
