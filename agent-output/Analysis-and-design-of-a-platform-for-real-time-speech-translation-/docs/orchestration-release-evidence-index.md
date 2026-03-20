# Epic 3.10 Release Evidence Index (Plan 075)

This index is the canonical QA/UAT handoff entrypoint for orchestration runtime-activation evidence in `v0.12.9`.

## Topology and Runtime Activation Evidence

- `docs/orchestration-topology-matrix.md`
- `tests/test_orchestration_runtime_activation_contract.py`
- `tests/test_orchestration_primary_owner_contract.py`
- `tests/test_orchestration_overlay_enforcement_contract.py`

## Security and Compliance Evidence

- `docs/orchestration-topic-security-matrix.md`
- `docs/orchestration-security-control-evidence-matrix.md`
- `tests/test_orchestration_topic_security_matrix_contract.py`
- `tests/test_orchestration_security_control_evidence_matrix_contract.py`
- `tests/test_orchestration_evidence_integrity_env_contract.py`

## Test Execution Evidence

- `agent-output/implementation/075-epic-3.10-pipeline-active-orchestration-integration-plan-implementation.md`
- `services/orchestrator/tests/test_runtime.py`
- `services/orchestrator/tests/test_engine.py`
- `services/orchestrator/tests/test_telemetry.py`
- `services/orchestrator/tests/test_state_machine.py`
- `services/tts/tests/test_main.py`
- `services/tts/tests/test_config.py`
- `services/asr/tests/test_processing.py`
- `services/translation/tests/test_translation_processing.py`

## Scope and Gate Note

- This index does not replace QA/UAT judgment; it provides a stable evidence inventory for Plan 075 gate execution.
- Final release decision remains downstream in QA → UAT → DevOps sequence.
