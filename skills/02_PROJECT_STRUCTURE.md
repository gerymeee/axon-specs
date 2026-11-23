# 02 - Project Structure

**Purpose:** Find the current sources and place a change with the component that owns it.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

| Path from ecosystem root | What exists or belongs there |
|---|---|
| [AGENTS.md](../../AGENTS.md) | Read order for the ecosystem. |
| [handoff.md](../../handoff.md) | Requirements for this documentation set. |
| [axon-api/](../../axon-api/AGENTS.md) | API integration boundary. No source, manifest, or route tree was available. |
| [axon-android/](../../axon-android/AGENTS.md) | Android application boundary. No Gradle project or source tree was available. |
| [axon-web/](../../axon-web/AGENTS.md) | Web and compliance application boundary. No package manifest or source tree was available. |
| [axon-specs/business-logic-v1.0.md](../business-logic-v1.0.md) | Draft product requirements and unfinished role matrix. |
| [axon-specs/db-design-choices.md](../db-design-choices.md) | Sync and relational design rationale with example SQL. |
| [axon-specs/git-guidelines.md](../git-guidelines.md) | Commit and release policy, including placeholder product codes. |
| [axon-specs/sense-making.md](../sense-making.md) | Separate planning research instructions. |
| [axon-specs/skills/](00_INDEX.md) | Numbered engineering handoff and contributor inbox. |

Place product requirements and cross-component contracts in specs so both clients can review the same baseline. Put persistence, route handlers, and UI in the repository that owns the behavior once its source layout exists. Assign each migration to its target store and record both locations under 04. Otherwise a one-sided migration can leave one client unable to read synchronized data.

In the design, `id` means store-local identity and `uuid` means sync identity. A `*_uuid` name identifies a UUID relationship. Keep that distinction in code and payloads so a store-local number cannot be mistaken for a cross-device identifier. See 04 #1.
