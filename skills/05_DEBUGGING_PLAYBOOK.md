# 05 - Debugging Playbook

**Purpose:** Trace a sync symptom to the layer that could have caused it.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

No application log locations or exact runtime error strings exist in the inspected sources. The messages below either come from the tooling used here or are symptom descriptions. Cause order follows the cheapest useful check in the design. Incident frequencies are unknown.

| Message or symptom | Diagnostic shortcut |
|---|---|
| Git reports `fatal: detected dubious ownership in repository` | Use a per-command repository-specific trust setting only after confirming this is the intended checkout. See 14. |
| Git status reports `No commits yet on main` | Check all refs with `git log --all --oneline` and branch names with `git branch -a`. The current local repositories were unborn and the configured GitHub repositories showed no branches. |
| A local edit never reaches another client | Inspect the UUID, `updated_at`, and `synchronized_at` at mutation, push selection, and acknowledgement. Start with 06 #1, then #4 if changes happen during sync. |
| Deleted item stays visible on another client | Follow `archived_at` and `updated_at` from the producer to scoped pull and normal reads. If only a list or total is wrong, inspect its live-row predicate (06 #2). |
| Child stays missing after parent has arrived | Check the parent UUID and authorization scope, then inspect whether a skipped child can be retried after a pull or cursor advances (06 #5). |
| Changed values revert after sync | Compare the outgoing stamp with the server’s stamp and inspect any concurrent dirty local edit. The design uses row-level ordering (06 #3–#4). |
| New data writes fail during a mixed-version rollout | Compare the deployed schema, translators, and allowed enum values. Check migration ordering and verify the old payload preserves server-populated fields (04 #5). |

Start in the client store for edits and eligibility, in API request/response diagnostics for scoping and acknowledgement, and in Postgres for stored state and merge outcomes. Use fictional data and record just the fields needed to show the transition. Capture the real message and originating layer in the inbox once the implementation emits it.
