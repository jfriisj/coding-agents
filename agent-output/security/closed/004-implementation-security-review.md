# Security Review: Epic 1.4 - Implementation Narrative and Reproducibility Traceability

**Mode**: Targeted Code Review (Planning)  
**Scope**: Plan 004 ([agent-output/planning/004-epic-1.4-implementation-narrative-and-reproducibility.md](agent-output/planning/004-epic-1.4-implementation-narrative-and-reproducibility.md))  
**Status**: APPROVED WITH HARDENING RECOMMENDATIONS

## 1. Executive Summary
The plan for Epic 1.4 successfully incorporates prior architectural invariants regarding privacy-safe logging and data encryption. However, from a security implementation narrative perspective, there are gaps in describing **Identity & Access Management (IAM)** and **Network Segmentation** at the implementation layer (Swarm/Kafka). Failure to narrate these controls risks presenting the system as "secure by policy" but "flat by implementation."

## 2. Findings & Hardening Requirements

### 2.1 Least Privilege in Event Flow (Severity: Medium)
*   **Risk**: If the implementation narrative only describes "event handling" without mentioning topic-level ACLs or service-specific credentials, the reader may assume a flat security model where any service can read any topic.
*   **Recommendation**: In **Milestone 1**, ensure the narrative for the orchestrator explicitly mentions the **Topic Security Matrix** implementation. Narrate how services (ASR, MT, TTS) are restricted to specific publish/consume permissions as defined in `docs/orchestration-topic-security-matrix.md`.

### 2.2 Claim-Check Token Lifecycle (Severity: Medium)
*   **Risk**: Pre-signed URLs used in the Claim-Check pattern are bearer tokens. If their TTL (Time-To-Live) is not managed or narrated, they pose a lingering exposure risk.
*   **Recommendation**: In **Milestone 2**, add a point to narrate the implementation of **Token Expiry Policies** for the pre-signed URLs. Confirm that the implementation uses short-lived tokens (e.g., < 1 hour) to minimize the window of opportunity for leaked URLs.

### 2.3 Secrets Management in Reproducibility (Severity: High)
*   **Risk**: The plan mentions narrating the `.env` file as a single source of truth for environment parity. If this narrative does not emphasize **Secrets Decoupling**, it could inadvertently encourage insecure practices (committing secrets).
*   **Recommendation**: In **Milestone 4**, explicitly narrate how sensitive values (Kafka credentials, MinIO keys) are handled during the transition from `docker-compose` to **Docker Swarm Secrets**. The narrative MUST reflect that secrets are *injected* at runtime and not stored in plain text within the manuscript or repository artifacts.

### 2.4 Internal-Only Ingress Enforcement (Severity: Medium)
*   **Risk**: Documentation of the Swarm bootstrap might focus on functionality, overlooking the enforcement of "Internal-Only" access for stateful services.
*   **Recommendation**: In **Milestone 4**, narrate the implementation of **Network Overlays** in Docker Swarm. Specifically, how stateful components (Kafka, MinIO) are isolated on a `backend_net` overlay, inaccessible from the public-facing Gateway's `frontend_net`.

## 3. Mandatory Implementation Checklist (for Milestone 5)
- [ ] Verify narrative includes topic-level ACL implementation (Kafka).
- [ ] Verify narrative includes short-lived pre-signed URL policy (MinIO).
- [ ] Verify narrative includes Docker Swarm Secrets usage for sensitive `.env` keys.
- [ ] Verify narrative includes network segmentation (Frontend vs Backend overlays).

## 4. Verdict
**APPROVED WITH HARDENING RECOMMENDATIONS**

The plan is strong but must bridge the gap between "what" is built and "how" it is secured at the implementation layer to be academically and technically defensible.

---
**Handoff Ready**. Parent Node context for the next agent is [[WF-E1.4-security-review]] (Planka Card: 1732017089281000924).
