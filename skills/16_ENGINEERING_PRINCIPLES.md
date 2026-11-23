# 16 - Engineering Principles

**Purpose:** Use these principles during design and review when the implementation details vary.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

1. **A sync acknowledgement applies to a version.** A response for an earlier snapshot must preserve subsequent local work. The example demonstrates the lost-dirty-state failure (06 #4). **Proposed for adoption.**
2. **An offline deletion travels as state.** Peers need the tombstone to converge, and normal views hide it once received. The rationale follows the deletion path in 06 #2. **Verified in design.**
3. **A meaningful local mutation changes its sync version.** Eligibility is derived from stamps. Updating only the visible field leaves a row clean in the SQLite exercise (06 #1). **Verified on the example.**
4. **Test conflict behavior at the row boundary.** Last-write-wins applies to the whole row. Multi-device tests reveal the lost-field behavior a single editor cannot exercise (06 #3). **Inferred from the design.**

trust the code over any document, including this one
