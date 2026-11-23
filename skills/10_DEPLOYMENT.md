# 10 - Deployment

**Purpose:** Follow the documented promotion gates and review compatibility before shipping a bundle.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

The [Git guidelines](../git-guidelines.md), Part 2, define development on `main`, QA/system testing on `beta`, and independent testing of the published bundle from `release`. Production approval attaches to the exact tested release candidate. The branches, CI, hosting and signing configuration, artifacts, and deployment commands are unverified.

| Order for an additive synced change | Gate and reason |
|---|---|
| 1. Postgres schema | Apply and validate the forward migration before serving consumers that require the new fields. Old consumers must still work during rollout. |
| 2. API | Verify payload and error behavior against both existing and new clients. A new API contract ahead of the schema puts requests into failure, and a strict new contract can strand older clients. |
| 3. Affected clients | Verify fresh installs and data upgrades. Release each client that consumes the new contract only after its server dependencies work. |
| 4. Specifications | Record the approved contract revision and its verified implementation baseline. Specs candidates undergo implementation comparison and stakeholder review. |

### Release checklist

- Verify QA acceptance before promoting to `release` and publish the bundle that independent testers will actually install.
- Track `a`, `b`, and `rc` candidate stages and iteration suffixes on the correct release commit. Re-check the tag against the artifact so approval and deployment refer to the same build.
- Resolve product-prefix placeholders before assigning a real tag. The policy uses `<prefix>.0X.Y.00Z` and preserves weekly build numbering across candidate iterations. Follow the source’s ISO-week and Friday cutoff rules for weekly tags.
- After production approval, use the exact approved candidate. Carry any stabilization fix forward through reviewed history so a later development release retains it.
- Open a separate maintenance lifecycle from the production baseline when production defects are accepted for maintenance. Increment the minor component and reset the build counter per the policy, preserving the baseline being fixed.

See 04 #7 and 11 for release evidence. Per-product build and rollback commands belong here once their workflows exist.
