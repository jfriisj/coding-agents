# Epic 3.11 Release Evidence Index (Plan 076)

This index is the canonical QA/UAT handoff entrypoint for unified capability authority and tuple-contract evidence in `v0.13.0`.

## Capability Contract Evidence

- `agent-output/deployment/v0.13.0-plan-076-readiness.md`
- `agent-output/implementation/closed/076-epic-3.11-unified-capability-authority-user-facing-tuple-contract-implementation.md`
- `docs/frontend/openapi.yaml`
- `docs/frontend/asyncapi.yaml`
- `docs/frontend/api.md`
- `docs/capability-evidence-lifecycle-governance.md`

## Security and Compliance Evidence

- `docs/privacy-safe-logging.md`
- `docs/capability-evidence-lifecycle-governance.md`
- `agent-output/security/076-epic-3.11-unified-capability-authority-user-facing-tuple-contract-plan-security-architecture-security.md`

## Test Execution Evidence

- `tests/test_frontend_capability_endpoint_contract.py`
- `tests/test_frontend_developer_api_doc_contract.py`
- `tests/test_plan_076_release_readiness_artifact.py`
- `tests/test_capability_evidence_lifecycle_governance_contract.py`
- `tests/tools/test_gateway_capabilities_evidence_export.py`
- `services/gateway/tests/test_language_capabilities_contract.py`
- `services/gateway/tests/test_ws_audio_integration.py`

## Scope and Gate Note

- This index does not replace QA/UAT judgment; it provides a stable evidence inventory for Plan 076 gate execution.
- Final release decision remains downstream in QA → UAT → DevOps sequence.

## Epic 3.30 Evidence Baseline (Plan 100, `v0.13.7`)

Milestone 0 scope-lock and traceability artifacts for frontend OpenAPI/AsyncAPI runtime alignment:

- `agent-output/validation/traceability/100-epic-3.30-contract-runtime-traceability-matrix-v0.13.7.md`
- `agent-output/validation/traceability/100-epic-3.30-opaque-auth-taxonomy-compatibility-check-v0.13.7.md`
- `agent-output/planning/100-epic-3.30-frontend-openapi-asyncapi-runtime-alignment-plan.md`
- `docs/frontend/openapi.yaml`
- `docs/frontend/asyncapi.yaml`

Security/control evidence baseline linked from the Milestone 0 matrix:

- `tests/test_bff_gateway_runtime_integration.py`
- `agent-output/security/100-epic-3.30-architecture-security.md`
- `agent-output/security/100-epic-3.30-code-audit.md`

Live evidence benchmark artifacts (Milestone 4 canonical `/v1` + `/ws/sessions` traversal):

- `agent-output/validation/benchmarks/bff-e2e-single-short-results-20260316/S1.bff_gateway_e2e/concurrency_1/summary.json`
- `agent-output/validation/benchmarks/bff-e2e-single-long-results-20260316/S1.bff_gateway_e2e/concurrency_1/summary.json`
- `agent-output/validation/benchmarks/bff-e2e-multiple-short-results-20260316/S1.bff_gateway_e2e/concurrency_1/summary.json`
- `agent-output/validation/benchmarks/bff-e2e-multiple-long-results-20260316/S1.bff_gateway_e2e/concurrency_1/summary.json`
- `agent-output/validation/traceability/100-epic-3.30-contract-runtime-traceability-matrix-v0.13.7.md`

## Epic 3.30 Forwarding Closure Evidence (Plan 101, `v0.13.7`)

Plan 101 websocket forwarding closure artifacts for the BFF gateway results bridge:

- `agent-output/planning/101-bff-websocket-forwarding-plan.md`
- `agent-output/implementation/101-bff-websocket-forwarding-implementation.md`
- `agent-output/validation/traceability/101-bff-websocket-forwarding-traceability-matrix-v0.13.7.md`
- `agent-output/critiques/101-bff-websocket-forwarding-critique.md`

Runtime verification evidence for forwarding behavior:

- `tests/test_bff_gateway_runtime_integration.py`
- `services/bff-gateway/src/bff_gateway_service/app.py`