# Test Runner Workflow (uv-first)

This repo standardizes on a **uv-first** workflow for reproducible, dependency-complete test execution. The workflow is **test-only** and does not change runtime/service configuration.

## Preferred workflow (uv required)

1. Create a local virtual environment:

- `uv venv .venv`

2. Install test dependencies:

- `uv pip install -r tests/requirements.txt`

3. Run tests using the repo-local Python:

- `.venv/bin/python -m pytest`

## Full clean validation matrix (single command)

Run the complete clean validation flow used in this session:

- clears `agent-output/validation/`
- starts compose dependencies/services (`docker-compose.yml` + `docker-compose.gpu.yml`)
- runs per-service unit suites
- runs per-service integration suites (with translation retry/reset guard)
- runs repo e2e suite
- runs explicit full pipeline e2e smoke

Command:

- `.venv/bin/python -m tools.clean_validation_runner`

Optional flags:

- `--no-reset-translation-topics-on-failure` to disable the integration retry/reset fallback
- `--project-dir`, `--validation-dir`, `--python-executable`, `--compose-files`, `--bootstrap-servers`, `--schema-registry-url`, `--schema-dir`

## Startup resilience validator (Plan 052)

Run the 10-iteration startup resilience validation loop with metadata-only evidence output:

- `.venv/bin/python -m tools.startup_resilience_validator --iterations 10 --wait-seconds 30 --compose-file docker-compose.yml --target-services bff,gateway,vad,asr,translation,tts --output-dir agent-output/validation --keep-latest 5`

Optional debug mode writes non-shareable debug artifacts outside the default shareable run bundle:

- `.venv/bin/python -m tools.startup_resilience_validator --debug-logs`

## Gateway upload + results matrix (WS) timeout policy

Run the matrix runner used for upload + `/ws/results` verification:

- `.venv/bin/python agent-output/validation/tmp/gateway_upload_results_matrix.py`

Timeout contract for stable long-path validation:

- `single_short_input`: `300s`
- `single_long_input`: `480s`
- `multiple_short_input`: `300s`
- `multiple_long_input`: `600s`

Rationale:

- Under GPU load and concurrent long samples, translation/TTS completion can legitimately arrive after ASR with higher tail latency.
- `600s` for `multiple_long_input` prevents false-fail disconnects while preserving fail-fast behavior for real per-sample errors.

## BFF edge short/long evidence runs

Run representative BFF-native short/long evidence from the host edge:

- `BFF_GATEWAY_TOKEN_SECRET=... PYTHONPATH=. .venv/bin/python -m tools.bff_ws_evidence_cli --signing-secret "$BFF_GATEWAY_TOKEN_SECRET" --run-id bff-e2e-single-short-results-YYYYMMDD --variant-id S1.bff_gateway_e2e --entrypoint-id bff_gateway_e2e --count 1 --duration 0.5 --timeout-seconds 240 --output-dir agent-output/validation/benchmarks`
- `BFF_GATEWAY_TOKEN_SECRET=... PYTHONPATH=. .venv/bin/python -m tools.bff_ws_evidence_cli --signing-secret "$BFF_GATEWAY_TOKEN_SECRET" --run-id bff-e2e-single-long-results-YYYYMMDD --variant-id S1.bff_gateway_e2e --entrypoint-id bff_gateway_e2e --count 1 --duration 8.0 --timeout-seconds 420 --output-dir agent-output/validation/benchmarks`

## Orchestration topic smoke (Plan 064)

Run compose-backed Kafka command→decision roundtrip smoke for orchestration topics:

- `ORCH_COMPOSE_SMOKE=1 PYTHONPATH=services/orchestrator/src:shared/speech-lib/src .venv/bin/python -m pytest -q tests/test_orchestration_topics_smoke.py`

Defaults expected by the smoke test (override via env vars if needed):

- `KAFKA_BOOTSTRAP_SERVERS=127.0.0.1:29092`
- `SCHEMA_REGISTRY_URL=http://127.0.0.1:8081`
- `ORCH_INPUT_TOPIC=speech.orchestration.command`
- `ORCH_OUTPUT_TOPIC=speech.orchestration.decision`

## Schema governance preflight (Plan 057)

Run deterministic offline-first schema governance checks locally before opening a PR:

- `npm run schema:governance`

This command validates:
- pinned compatibility policy posture (`BACKWARD` or stricter)
- `TopicNameStrategy` subject convention (`<topic>-value`)
- machine-readable Normal telemetry output fields for pass/fail triage

Optional runtime Schema Registry verification is intentionally non-primary and should not be used as baseline pass/fail authority.

## Runtime vulnerability gate (Plan 061)

Run ONNX/runtime dependency gating with explicit threshold and waiver file:

- `.venv/bin/python -m tools.runtime_vulnerability_gate --findings agent-output/validation/runtime/findings.json --waivers agent-output/validation/runtime/waivers.json --severity-threshold high --output agent-output/validation/runtime/runtime_vulnerability_gate.json`

See `docs/runtime-vulnerability-gate-runbook.md` for waiver policy and evidence requirements.

## Runtime swap proof bundle (Plan 061)

Generate baseline-vs-onnx swap-proof artifacts from a prepared variant input file:

- `PYTHONPATH=shared/speech-lib/src:services/vad/src:services/tts/src .venv/bin/python -c "import json; from pathlib import Path; from tools.runtime_swap_proof import build_swap_proof_bundle, write_swap_proof_bundle; out_dir=Path('agent-output/validation/runtime-swap/run-061-swap-proof-20260219'); data=json.loads((out_dir/'input.json').read_text(encoding='utf-8')); bundle=build_swap_proof_bundle(baseline=data['baseline'], onnx=data['onnx'], allowed_config_delta_keys={'EXECUTION_RUNTIME'}); write_swap_proof_bundle(out_dir, bundle)"`

See `docs/runtime-swap-proof-runbook.md` for contract requirements and pass/fail interpretation.

## Service Runtime Modes (ONNX vs non-ONNX)

For operational runtime configuration (not test-only execution), see:

- `README.md` runtime mode overview
- `docs/gpu-execution.md` mode matrix and compose examples
- `services/asr/README.md`
- `services/translation/README.md`
- `services/vad/README.md`
- `services/tts/README.md`

## Test-only `PYTHONPATH` contract

Service-level unit tests may require module imports from the shared library and the service under test. Use a **test-only** `PYTHONPATH` when invoking tests:

- Shared lib: `shared/speech-lib/src`
- Service under test: `services/<service>/src`

**Example (TTS tests):**

- `PYTHONPATH=shared/speech-lib/src:services/tts/src .venv/bin/python -m pytest services/tts/tests`

> This contract is for tests only. Runtime services must rely on package/module resolution provided by their own deployment environments.

## VS Code `runTests` harness discovery (custom agents)

To ensure `runTests` discovers the full suite (and does not report **"No tests found"** for files under `tests/`), keep workspace settings aligned with `pytest.ini`:

- `python.testing.pytestEnabled`: `true`
- `python.testing.unittestEnabled`: `false`
- `python.testing.cwd`: `${workspaceFolder}`
- `python.testing.pytestArgs`: `[]` (do **not** restrict this to `services`)

With this setup, discovery follows `pytest.ini` `testpaths` (`tests`, `services`, `shared/speech-lib`) and QA evidence can rely on `runTests` instead of terminal-only fallback.

## Fallback workflow (only if uv is unavailable)

If `uv` is not available in a given environment, the supported fallback is a standard venv + pip inside the venv:

1. `python -m venv .venv`
2. `.venv/bin/pip install -r tests/requirements.txt`
3. `.venv/bin/python -m pytest`

If a CI runner is used, prefer installing `uv` in the image and use the uv-first path for deterministic installs.
