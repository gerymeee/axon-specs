# 09 - Security

**Purpose:** Review access and data boundaries when defining a feature, route, or sync operation.
**Confidence note:** Verified against the Axon working-tree documentation baseline on 2026-11-23. Application code was unavailable. The code wins (see [16](16_ENGINEERING_PRINCIPLES.md)).

[Business logic](../business-logic-v1.0.md) calls for Google Sign-In and security and privacy by design. It names Data Privacy Act compliance, location protection, retention limits, no per-user trails, aggregation thresholds, and consent for resale. Those are stated requirements. This handoff provides no compliance determination, retention period, or approved threshold.

| Review surface | Design and reason |
|---|---|
| Identity and roles | Google Sign-In identifies users in the draft. The API still needs server-side role and resource authorization. A client-side visibility check alone cannot enforce access. |
| Sync scope and authorship | Keep pulls scoped and derive row/action authors from the verified session. Exclude those fields from push allowlists so incoming data cannot replace server-derived attribution. See 04 #4. |
| Private data | Define what location data enters the system, what is retained, and who can see raw vs aggregated results. Every data output, including logs, can otherwise undo the draft privacy constraints. |
| Query input | Native database and API bindings are unverified. Review future query construction and keep incoming filters and enum values within their declared contracts so requests cannot alter query semantics. |
| Secrets and debug gates | No environment variable names, logging controls, or debug routes were verified. Record key names when configuration lands and omit values. Check debug features before packaging so test access does not carry into release bundles. |

For each change, check two permitted scopes and a denied one, verify actor fields on accepted writes, and inspect returned fields for privacy-sensitive data. Use fictional accounts and location data for the drills in 11. No security exception, role matrix for concrete endpoints, or deployment acceptance was recorded.
