# Runtime Swap Proof Runbook (Plan 061 Milestone 3)

This runbook defines a reproducible, metadata-only workflow for proving configuration-driven runtime swap (`baseline` vs `onnx`) for the selected service pair (`vad-service`, `tts-service`).

## Purpose

- Prove runtime/model swap is configuration-driven.
- Preserve deterministic comparability metadata across baseline and onnx variants.
- Emit privacy-safe, shareable artifacts for QA/UAT.

## Required Variant Fields

Each variant payload (`baseline`, `onnx`) must include:

- `proof_contract_version`
- `run_id`
- `scenario_id`
- `swap_attempt_id`
- `swap_variant_id`
- `execution_mode` (`baseline` or `onnx`)
- `runtime_requested`
- `runtime_effective`
- `fallback_policy`
- `evidence_mode`
- `git_sha`
- `service_pair`
- `model_artifacts` (per-service `model_id`, `model_family_type`, `model_revision`, `model_sha256`)
- `config_snapshot`

Comparability constraints:

- `run_id`, `scenario_id`, `swap_attempt_id`, `git_sha`, and `service_pair` must match between variants.
- Allowed config-only delta keys are explicitly constrained (default for this proof: `EXECUTION_RUNTIME`).

## Execute Swap-Proof Builder

Input file convention:

- `agent-output/validation/runtime-swap/<run_id>/input.json`

Execution command:

```bash
PYTHONPATH=shared/speech-lib/src:services/vad/src:services/tts/src \
.venv/bin/python -c "import json; from pathlib import Path; from tools.runtime_swap_proof import build_swap_proof_bundle, write_swap_proof_bundle; out_dir=Path('agent-output/validation/runtime-swap/run-061-swap-proof-20260219'); data=json.loads((out_dir/'input.json').read_text(encoding='utf-8')); bundle=build_swap_proof_bundle(baseline=data['baseline'], onnx=data['onnx'], allowed_config_delta_keys={'EXECUTION_RUNTIME'}); write_swap_proof_bundle(out_dir, bundle)"
```

## Expected Outputs

Under `agent-output/validation/runtime-swap/<run_id>/`:

- `baseline.json`
- `onnx.json`
- `comparison_summary.json`
- `hash_manifest.sha256`
- `artifact_governance.json`

Pass criteria in `comparison_summary.json`:

- `status` is `pass`
- `execution_modes.baseline` is `baseline`
- `execution_modes.onnx` is `onnx`
- `runtime_contract.baseline.runtime_requested` is `native`
- `runtime_contract.onnx.runtime_requested` is `onnx`
- `changed_config_keys` only includes approved delta keys

## Fail-Closed Conditions

Swap-proof generation fails if:

- identity fields mismatch (`run_id`, `scenario_id`, `git_sha`, `service_pair`)
- execution modes/runtime contract values are inconsistent
- changed config keys include non-approved keys
- denylist scan detects restricted content

## Access, Retention, and Disposal Metadata

Each run folder must include `artifact_governance.json` with:

- RBAC posture (`writer_role`, `reviewer_role`, classification)
- retention owner and minimum retention duration
- disposal verification requirement and verification method

Default reference posture for Plan 061 swap-proof artifacts:

- shareability: metadata-only shareable
- retention minimum: 30 days
- owner: `devops-evidence-storage`
- reviewer access: read-only by default

## Plan 062 Addendum — Service Coverage and Security Traceability

Plan 062 extends runtime swap evidence with machine-checkable closure summaries.

### Service Coverage Summary

Output folder example:

- `agent-output/validation/runtime-swap/run-062-service-coverage-20260219/`

Required outputs:

- `service_coverage_summary.json`
- `hash_manifest.sha256`

Pass criteria:

- `status` is `pass`
- `missing_services` is `[]`
- `cross_service_coverage` is `pass`

### Security Control Traceability Summary

Output folder example:

- `agent-output/validation/runtime-swap/run-062-security-traceability-20260219/`

Required outputs:

- `security_control_traceability_summary.json`
- `hash_manifest.sha256`

Pass criteria:

- `status` is `pass`
- `missing_controls` is `[]`
- `failing_controls` is `[]`

### Execution-Backed Closure Coverage Summary

Output folder example:

- `agent-output/validation/runtime-swap/run-062-execution-backed-20260219/`

Required outputs:

- `execution_backed_scenarios.json`
- `execution_backed_coverage_summary.json`
- `hash_manifest.sha256`

Scenario record requirements for closure-valid entries:

- `scenario_id`
- `services`
- `scenario_type`
- `execution_source`
- `evidence_refs`
- `config_delta_ref`
- `implementation_delta_statement_ref`
- `config_only_swap`
- `no_rewrite_required`

Pass criteria:

- `status` is `pass`
- `missing_services` is `[]`
- `cross_service_coverage` is `pass`
- `failing_scenarios` is `[]`
- `config_only_swap_coverage` is `pass`
- `no_rewrite_coverage` is `pass`
