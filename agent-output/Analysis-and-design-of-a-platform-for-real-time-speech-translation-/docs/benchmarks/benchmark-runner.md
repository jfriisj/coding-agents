# Benchmark Runner (Epic 2.2)

This document describes how to run the Kafka-delta benchmark runner and where artifacts are written.

## Prerequisites

- Docker Compose environment up and healthy (Kafka + Schema Registry + services)
- uv-based test environment available (see [docs/test-runner.md](docs/test-runner.md))

## Run (Kafka-delta)

Example invocation (S1.kafka_delta, 1 concurrency):

- `.venv/bin/python -m tools.benchmark_cli \
  --run-id run-123 \
  --bootstrap 127.0.0.1:29092 \
  --schema-registry http://127.0.0.1:8081 \
  --schema-dir shared/schemas/avro \
  --sample-rate 16000 \
  --duration 1.0 \
  --timeout-seconds 120 \
  --assignment-timeout-seconds 60 \
  --wav-path tests/e2e/tts-smoke-test.wav \
  --variant-id S1.kafka_delta \
  --entrypoint-id kafka_direct \
  --concurrency 1 \
  --count 5 \
  --warmup 1 \
  --services gateway,asr,translation,tts \
  --output-dir agent-output/validation/benchmarks`

## Ray Evidence Run (Epic 2.8)

Before running a Ray-based evidence run, bring up Ray head/worker alongside the stack:

- `docker compose up -d ray-head ray-worker`

Then set the execution-mode metadata and Ray connection details for the evidence run (shareable, Normal telemetry only):

- `export ASR_EXECUTION_MODE=ray`
- `export RAY_ADDRESS=ray://ray-head:10001`
- `export ASR_RAY_NUM_ACTORS=1`
- `export RAY_VERSION=2.9.0`
- `export RAY_NUM_WORKERS=1`
- `export ASR_RAY_ACTOR_INIT_COUNT=1`
- `export ASR_RAY_WARM_LOAD_ACHIEVED=true`

Run the Kafka-delta benchmark command above to generate artifacts. Ensure the resulting `run_metadata.json` contains Ray fields and passes the denylist scan.

## Artifacts

Artifacts are written to:

- Raw artifacts: `agent-output/validation/benchmarks/<run_id>/<variant_id>/concurrency_<N>/`
- Report template: `docs/benchmarks/benchmark-report-template.md`

Each run directory includes:

- `run_metadata.json`
- `provenance_manifest.json` (schema/model/dataset provenance, metadata-only)
- `results.jsonl`
- `summary.json`
- `resource_usage.csv`
- `hash_manifest.sha256`

When denylist scanning is enabled, provenance manifests are scanned together with the rest of the artifact bundle.

## Privacy-Safe Scan

Run the log scan guardrail before sharing artifacts:

- `.venv/bin/python tools/log_scan.py agent-output/validation/benchmarks/<run_id>/**/*.json*`

## Notes

- `--services` controls which Docker containers are sampled for CPU/memory (via `docker stats`).
- Resource sampling cadence is driven by runner timing; align the measurement window to the report.
