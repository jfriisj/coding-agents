# Failure-Mode Evidence Runbook (Epic 2.3)

## Safety & Compliance
- Use **synthetic or consented/licensed** inputs only.
- Fault injection is **local-only by default**; explicit opt-in required for non-local targets.
- Evidence artifacts are shareable by default and must remain content-free.

## Prerequisites
- Docker Compose stack running with Kafka, Schema Registry, MinIO, and services.
- Benchmark harness available (Kafka-delta runner + fault injection helpers).
- Gateway WS endpoint available for gateway-e2e scenarios.

## Evidence Artifacts (expected)
- `run_metadata.json`
- `results.jsonl`
- `summary.json`
- `resource_usage.csv` (if enabled)
- `log_summary.json` (aggregated failure signals)

## Standard Workflow
1. Start baseline services via Docker Compose.
2. Run a warmup (excluded from metrics).
3. Execute fault-injected scenario.
4. Confirm fault window metadata and denylist scan passed.
5. Repeat run (3x) for reproducibility if thesis evidence is needed.

## Run Isolation & Naming
- Use a unique `run_id` per scenario execution (recommended: `{date}-epic23-{scenario}-{seq}`).
- Set `variant_id` to include the scenario label (must start with `S1.` or `S2.` so `scenario_id` can be derived).
- Keep warmup and measured runs separate (`--warmup`); warmup must be excluded from summaries.

**Recommended naming examples**:
- `run_id`: `2026-02-04-epic23-dep-minio-001`
- `variant_id`: `S1.dep.minio.outage`
- `entrypoint_id`: `kafka_direct` or `gateway_e2e`

## Kafka-delta Evidence Run (example)
- Use `run_fault_injected_kafka_delta_benchmark` to:
  - inject the fault (stop/restart service)
  - record `fault_start_ms`/`fault_end_ms`
  - write artifacts in a single bundle

**CLI** (optional):
- `python tools/fault_injected_benchmark_cli.py --run-id 2026-02-04-epic23-svc-asr-001 --variant-id S1.svc.asr.restart --entrypoint-id kafka_direct --service asr --action restart --output-dir agent-output/validation/benchmarks`
- `python tools/fault_injected_benchmark_cli.py --run-id 2026-02-04-epic23-dep-minio-001 --variant-id S1.dep.minio.outage --entrypoint-id kafka_direct --service minio --action stop --restore-action start --max-fault-duration-seconds 10 --output-dir agent-output/validation/benchmarks`

## Gateway-e2e Evidence Run (example)
- Use `run_gateway_ws_evidence` to stream a short synthetic sample and capture end-to-end completion time.
- Ensure run metadata includes `entrypoint_id=gateway_e2e` and fault window metadata if injected.

**CLI** (optional):
- `python tools/gateway_ws_evidence_cli.py --run-id 2026-02-04-epic23-svc-gateway-001 --variant-id S1.svc.gateway.restart --entrypoint-id gateway_e2e --count 1 --output-dir agent-output/validation/benchmarks`

**Gateway restart (fault window) template**:
1. Trigger the gateway restart using the compose fault window helper.
2. Run the WS evidence command above during the fault window.

## Evidence Validation
- **Allowlist**: artifact fields must match the allowed schema.
- **Denylist**: run denylist scan on all artifacts (presigned URLs, query strings, raw payloads are forbidden).
- **Log summary**: aggregated counts only (no raw lines or exception messages).

## Notes on Kafka Outage Evidence
- If broker attribution remains ambiguous, document this limitation in the report; rely on harness-observable outcomes for primary claims.

## Documentation Drift Notice
- Historical references to `tests/e2e/tts_smoke.py --simulate-outage` are **stale** (script no longer exists). Use this runbook and the fault-injected benchmark helpers instead.
