# 06 - Failure Stories

**Purpose:** Learn why the documented guards exist and which edge cases still need implementation tests.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

No historical production incidents, fixes, or reverts were visible in Git. The entries below reconstruct design failure modes. Two were reproduced using the supplied SQLite example in an in-memory database. The rest are inferred or suspected.

| # | What happened or could happen | Why and how found | Prevention and lesson | Confidence |
|---|---|---|---|---|
| 1 | A changed `note.title` remained clean. | In SQLite 3.45.1, changed the title while leaving matching `updated_at` and `synchronized_at` intact. The documented dirty predicate remained false. | Every meaningful local edit needs a changed stamp. Exercise the real mutation paths (04 #2). | Reproduced in example. |
| 2 | One device archives a row and another continues showing it. | The design requires an archive tombstone in pull. Reviewing the ordinary read predicate shows how reusing it in pull would hide the deletion. | Keep tombstones in scoped pull and filter them in normal reads. Test the entire trip between clients (04 #3). | Inferred from §5. |
| 3 | A user's field change is lost to another device’s row. | Reviewing the upsert in §6 shows one ordering comparison for the entire row. Two independent field edits can compete under one timestamp. | Document row-level conflict semantics and test two offline editors, including the delete tie case. | Inferred from §6. |
| 4 | A later local edit became clean when an earlier push was acknowledged. | SQLite example: made version A dirty, treated it as the outgoing snapshot, wrote version B, then ran the sample acknowledgement. It copied B’s current stamp into `synchronized_at`. | Proposed fix is to mark only the acknowledged snapshot clean without clearing a newer local edit. Add a controlled in-flight edit test. | Reproduced in example. Application impact unverified. |
| 5 | A child skipped for a missing parent never reappears. | §3 says to retry. A proposed cursor-based pull could move beyond a skipped row if that retry has no durable record. | Specify retry independently of cursor advancement or confirm the scoped pull rereads skipped children. Test parent-later and permission filtering. | Suspected for future delta pull. |

Source for all stories is [database design choices](../db-design-choices.md), §§3, 5, and 6.
