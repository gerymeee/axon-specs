# INBOX - Inbox

**Purpose:** Capture observations that a future contributor can verify and place in the handoff.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

A rough entry beats none. Include what you saw, where to find evidence, and what improves or breaks. Keep secrets, tokens, and identifiable sample data out of entries.

| Entry type | Destination |
|---|---|
| Best practice | 03 or 14 |
| Methodology | 10, 11, or 14 |
| Design choice | 01 decision record |
| Change rule | 04 lockstep set |
| Failure story | 06, with references from 04, 05, and 16 as applicable |
| Debugging tip | 05 |
| Limitation | 15 |
| Dependency note | 13 |
| Principle | 16 once proven and accepted |

For each refresh, verify the entry or label it **Unverified** while evidence is missing. Preserve its substance and credit at the destination. Record competing claims and supporting evidence for a user decision before resolving a conflict. Remove the inbox entry after merging it. Log the publication in [00_INDEX.md](00_INDEX.md) so future readers can follow the change.

### Entry template

> ### <summary>
> - **Type / Author / Date:**
> - **What:**
> - **Why:** what improves, or what breaks without it.
> - **Evidence:** files, commits, PRs, or the incident.

There are no pending submissions on this baseline.
