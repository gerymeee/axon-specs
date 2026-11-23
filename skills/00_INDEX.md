# 00 - Index

**Purpose:** Choose the shortest reading path for the task and see the verification baseline.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

**Read 01 first.** The four local Git repositories have no commits or stored objects. The configured GitHub repositories returned no branches. The handoff is based on the checked-out instructions and specifications, plus two in-memory SQLite checks. Application entry points, routes, migrations, config, workflows, tests, and Git incident history were unavailable.

| Task | Read in order |
|---|---|
| Join the project | [01](01_ARCHITECTURE.md), [02](02_PROJECT_STRUCTURE.md), [14](14_DEVELOPER_WORKFLOWS.md) |
| Change schema or sync | [04](04_CHANGE_RULES.md), [07](07_DATABASE.md), [06](06_FAILURE_STORIES.md), [11](11_TESTING.md) |
| Add or change an endpoint | [08](08_API.md), [09](09_SECURITY.md), [04](04_CHANGE_RULES.md) |
| Diagnose a failure | [05](05_DEBUGGING_PLAYBOOK.md), [06](06_FAILURE_STORIES.md), [15](15_KNOWN_LIMITATIONS.md) |
| Review style, cost, or dependency changes | [03](03_CODE_STYLE.md), [12](12_PERFORMANCE.md), [13](13_DEPENDENCIES.md), [16](16_ENGINEERING_PRINCIPLES.md) |
| Prepare a candidate | [10](10_DEPLOYMENT.md), [11](11_TESTING.md), [14](14_DEVELOPER_WORKFLOWS.md) |

| Document | Last checked |
|---|---|
| [00 Index](00_INDEX.md) | 2026-11-23 |
| [Inbox](INBOX.md) | 2026-11-23 |
| [01 Architecture](01_ARCHITECTURE.md) | 2026-11-23 |
| [02 Project Structure](02_PROJECT_STRUCTURE.md) | 2026-11-23 |
| [03 Code Style](03_CODE_STYLE.md) | 2026-11-23 |
| [04 Change Rules](04_CHANGE_RULES.md) | 2026-11-23 |
| [05 Debugging Playbook](05_DEBUGGING_PLAYBOOK.md) | 2026-11-23 |
| [06 Failure Stories](06_FAILURE_STORIES.md) | 2026-11-23 |
| [07 Database](07_DATABASE.md) | 2026-11-23 |
| [08 API](08_API.md) | 2026-11-23 |
| [09 Security](09_SECURITY.md) | 2026-11-23 |
| [10 Deployment](10_DEPLOYMENT.md) | 2026-11-23 |
| [11 Testing](11_TESTING.md) | 2026-11-23 |
| [12 Performance](12_PERFORMANCE.md) | 2026-11-23 |
| [13 Dependencies](13_DEPENDENCIES.md) | 2026-11-23 |
| [14 Developer Workflows](14_DEVELOPER_WORKFLOWS.md) | 2026-11-23 |
| [15 Known Limitations](15_KNOWN_LIMITATIONS.md) | 2026-11-23 |
| [16 Engineering Principles](16_ENGINEERING_PRINCIPLES.md) | 2026-11-23 |

**Confidence language.** Verified in design means the named source says it. Reproduced in example means a behavior was exercised on the illustrative schema. Inferred means the evidence supports the explanation without a recorded incident. Suspected means a condition would need testing. When code lands, record the exact commit or version used to recheck a document.

### Contributions and refresh

- Add rough evidence to the [inbox](INBOX.md) or edit its destination document directly. Keep contributors’ credit with the finding.
- Refresh around releases, incidents, decisions, new lockstep changes, a full inbox, or a few quiet weeks. Diff the code since each document’s verification point, including local changes. Fix verified drift in the same change or record it in the inbox while evidence is missing.
- Verify and merge inbox entries with credit before removing the original entry. Record both evidence-backed positions and ask for a decision if they conflict. Retire outdated knowledge under a **Retired** heading with replacement and date so old advice cannot be restored by accident.
- Keep the document numbers stable. Propose promotions to 16 for review and update the verification dates and changelog after a refresh.

### Changelog

- **2026-11-23** — Created the first Axon handoff from the working-tree specs and repository instructions. Added seven cross-component change sets and five failure stories, with two behaviors reproduced against the SQLite example.
