# 14 - Developer Workflows

**Purpose:** Inspect the current baseline and follow repeatable recipes for cross-component changes.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

### 1. Inspect the baseline

1. Read [the ecosystem instructions](../../AGENTS.md), 01, and the participating repositories’ instructions. This identifies which application owns each piece of the change.
2. From each repository root, run `git status --short --branch` and `git log --all --oneline`. If Git reports dubious ownership for a checkout you have verified, use the per-command form `git -c "safe.directory=D:/absolute/path/to/axon-repository" status --short --branch` with its resolved absolute path. This keeps trust scoped to the intended repository and command.
3. Locate manifests, setup commands, and the latest run evidence once source exists. No application startup steps can be verified on this baseline. Use the in-memory design drill in 11 to validate the example logic independently.
4. Add what surprised you to `INBOX.md`.

### 2. Add a synced field

1. Specify the canonical field, default and compatibility behavior in specs. Older clients will omit fields or send previous shapes (04 #5).
2. Add the server column and guarded backfill, then update API exchange rules and the client schema and mapping. This prevents early readers from assuming a field exists.
3. Test fresh setup, upgrade, old writes, and pull on a second client. Check that the old payload preserves any new server-populated value.
4. Add what surprised you to `INBOX.md`.

### 3. Diagnose a missing edit or delete

1. Start with one fictional row UUID and capture client and server lifecycle stamps at each stage (05).
2. Determine whether the row entered push selection, whether API received it, whether the server applied it, and whether peers received it. This separates a clean-marker failure from a scope or pull filter failure.
3. Replay the matching drill in 11. For an edit missed after acknowledgement, hold the response while making a second edit (06 #4).
4. Add what surprised you to `INBOX.md`.

### 4. Prepare a release candidate

1. Record the tested schema, API, client and spec versions because mixed generations can invalidate a passing endpoint check.
2. Follow the gates in 10 and compare the published artifact with the `release` candidate tag before final approval. This prevents deploying an untested rebuild.
3. Add what surprised you to `INBOX.md`.
