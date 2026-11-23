# 07 - Database

**Purpose:** Read before changing identity, relationships, sync fields, or a migration.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

[Database design choices](../db-design-choices.md) §§1–9 describe the design. The table names below are examples. The deployed schema and migration history are unavailable.

| Example or field | Role and why it matters |
|---|---|
| `public.note` / SQLite `note` | Shared-name entity. Postgres uses `id bigint GENERATED ALWAYS AS IDENTITY` and SQLite uses `INTEGER PRIMARY KEY`. Both uniquely store `uuid`. Syncs across independent stores by UUID. |
| `public.note_tag` | Example link carrying its own UUID and placement `rank`. `idx_note_tag_live` uniquely indexes `(note_uuid, tag_uuid)` for rows with `archived_at IS NULL`, which allows a replacement live link after archival. |
| `notebook_uuid` and other `*_uuid` fields | Portable parent references. The design allows most server relations to receive children before parents. Scoped reads must tolerate missing parents and pull must retry eligible skipped children. |
| `created_by`, `created_at`, `updated_at`, `archived_at` | Attribution and lifecycle. Server stamps actor columns. Timestamp fields compare across stores. Tombstones travel as edits so peers can hide the row. |
| `synchronized_at` | SQLite sync marker. Only sync updates it. A local edit can disappear from the next push if a writer also sets this marker. |

For forward changes, add and backfill safely before readers depend on new columns. Add lookup indexes with new scoped query paths. The SQLite sample guards additive changes with `PRAGMA table_info(note)`. Test fresh installs and upgrades, and keep legacy compatibility until older callers have upgraded (04 #5).

Inspect actual foreign-key declarations before assuming SQLite enforces a relationship. The source calls for enabling client foreign keys but the sample SQLite `note` has no `REFERENCES` clause. The design pairs client-side validation and orphan retry with permissive ordering on most server relationships.

**Dangerous changes.** Hard deletion removes the tombstone peers need. A mass restore propagates restoring every affected row. A manual server edit that leaves `updated_at` unchanged can lose to a subsequent push. Keep the original lifecycle stamps and eligibility in the test setup before changing any of these operations.
