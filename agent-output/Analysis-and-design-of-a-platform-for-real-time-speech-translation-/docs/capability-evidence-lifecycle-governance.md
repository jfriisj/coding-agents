# Epic 3.11 Capability Evidence Lifecycle Governance

## Scope
This artifact governs lifecycle handling for Plan 076 capability evidence outputs generated from gateway capability publication and exporter automation.

Covered evidence classes:
- Gateway capability snapshot evidence (`capability_evidence`)
- Exporter verification metadata (`verification_contract`)
- Cross-authority drift comparison output (`authority_drift_report`)

Primary generation surfaces:
- `tools/gateway_capabilities_evidence_export.py`
- `/v1/demo/capabilities/evidence`

## Retention Policy
- Baseline retention owner: platform QA operations.
- Default retention period: 30 days for release-gating evidence.
- Extended retention is allowed only for release-audit investigations with explicit ticket reference.
- Retention applies to JSON artifacts containing `capability_evidence`, `verification_contract`, and `authority_drift_report`.

## Access Control
- Read access: QA / UAT / DevOps.
- Write access: Implementer automation and release pipeline jobs only.
- Mutation of previously produced evidence artifacts is prohibited; regenerated artifacts must use a new run identifier.
- Integrity verification steps are fail-closed at release gate when required fields are absent or mismatched.

## Deletion and Disposal
- Evidence artifacts are deleted at retention expiry unless legal or audit hold is explicitly documented.
- Deletion action must include timestamp, actor, and run identifier in release notes or audit trail.
- Disposal verification requires checksum manifest mismatch check after deletion to prevent stale copies from being reused.

## Shareability Classification
- Shareable externally: Normal telemetry-derived capability metadata only, with no sensitive payload content.
- Not shareable externally: Debug telemetry captures and any artifact containing secrets or credential-bearing URLs.
- Classification follows `docs/privacy-safe-logging.md` policy for prohibited content and evidence-mode constraints.

## Telemetry Mode Alignment
- `Normal telemetry` evidence is the release-gate baseline for capability lifecycle verification.
- `Debug telemetry` is explicitly non-shareable and cannot replace Normal telemetry evidence for release approval.

## Verification and Gate Ownership
- Verification owner at release gate: QA / UAT / DevOps.
- Required verification contract posture:
  - `verification_contract.verification_owner` identifies release-gate ownership.
  - `verification_contract.mismatch_handling` remains `fail_closed`.
  - Required checks remain present for gateway evidence and capability evidence checksums.

## Compliance Notes
- This governance artifact is mandatory evidence for Plan 076 Milestone 5 gate completion.
- Any contract drift between exporter output and this governance policy is a release blocker until reconciled.
