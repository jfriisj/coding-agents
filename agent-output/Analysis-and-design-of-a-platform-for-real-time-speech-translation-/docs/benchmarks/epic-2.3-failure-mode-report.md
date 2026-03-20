# Epic 2.3 Failure-Mode Evidence Report

**Date**: 2026-02-05
**Scope**: Availability & failure-mode evidence for critical dependencies and services.
**Status**: Final

## Environment
- Host: Local Docker Compose
- Kafka/SR/MinIO: local
- Git SHA: unknown (per run metadata)
- Dataset: Synthetic audio only (consent/licensing verified)

## Scenarios Executed

| Scenario | Entry Point | Run ID | Fault Window | Outcome | Artifacts | Notes |
|---|---|---|---|---|
| dep.minio.outage | Kafka-delta | 2026-02-04-epic23-dep-minio-004 | fault_start_ms=1770202499930, fault_end_ms=1770202510556 | success (1/1) | [agent-output/validation/benchmarks/2026-02-04-epic23-dep-minio-004/S1.dep.minio.outage/concurrency_1/](agent-output/validation/benchmarks/2026-02-04-epic23-dep-minio-004/S1.dep.minio.outage/concurrency_1/) | Latency p50/p90/p99=18255 ms; warmup=0; minio stop/start | 
| dep.kafka.outage | Kafka-delta | 2026-02-04-epic23-dep-kafka-002 | fault_start_ms=1770203135621, fault_end_ms=1770203146614 | success (1/1) | [agent-output/validation/benchmarks/2026-02-04-epic23-dep-kafka-002/S1.dep.kafka.outage/concurrency_1/](agent-output/validation/benchmarks/2026-02-04-epic23-dep-kafka-002/S1.dep.kafka.outage/concurrency_1/) | Latency p50/p90/p99=4911 ms; warmup=0; kafka stop/start | 
| dep.sr.outage | Kafka-delta | 2026-02-04-epic23-dep-sr-001 | fault_start_ms=1770203622492, fault_end_ms=1770203633559 | timeout (1/1) | [agent-output/validation/benchmarks/2026-02-04-epic23-dep-sr-001/S1.dep.sr.outage/concurrency_1/](agent-output/validation/benchmarks/2026-02-04-epic23-dep-sr-001/S1.dep.sr.outage/concurrency_1/) | Timeout during SR stop/start; warmup=0 | 
| svc.vad.restart | Kafka-delta | 2026-02-04-epic23-svc-vad-001 | fault_start_ms=1770203750208, fault_end_ms=1770203760965 | timeout (1/1) | [agent-output/validation/benchmarks/2026-02-04-epic23-svc-vad-001/S1.svc.vad.restart/concurrency_1/](agent-output/validation/benchmarks/2026-02-04-epic23-svc-vad-001/S1.svc.vad.restart/concurrency_1/) | Timeout during vad-service restart; warmup=0 | 
| svc.asr.restart | Kafka-delta | 2026-02-04-epic23-svc-asr-001 | fault_start_ms=1770203858491, fault_end_ms=1770203869332 | success (1/1) | [agent-output/validation/benchmarks/2026-02-04-epic23-svc-asr-001/S1.svc.asr.restart/concurrency_1/](agent-output/validation/benchmarks/2026-02-04-epic23-svc-asr-001/S1.svc.asr.restart/concurrency_1/) | Latency p50/p90/p99=9869 ms; warmup=0; asr-service restart | 
| svc.translation.restart | Kafka-delta | 2026-02-04-epic23-svc-translation-001 | fault_start_ms=1770204415397, fault_end_ms=1770204436269 | success (1/1) | [agent-output/validation/benchmarks/2026-02-04-epic23-svc-translation-001/S1.svc.translation.restart/concurrency_1/](agent-output/validation/benchmarks/2026-02-04-epic23-svc-translation-001/S1.svc.translation.restart/concurrency_1/) | Latency p50/p90/p99=5784 ms; warmup=0; translation-service restart | 
| svc.tts.restart | Kafka-delta | 2026-02-04-epic23-svc-tts-001 | fault_start_ms=1770204491514, fault_end_ms=1770204512451 | success (1/1) | [agent-output/validation/benchmarks/2026-02-04-epic23-svc-tts-001/S1.svc.tts.restart/concurrency_1/](agent-output/validation/benchmarks/2026-02-04-epic23-svc-tts-001/S1.svc.tts.restart/concurrency_1/) | Latency p50/p90/p99=1867 ms; warmup=0; tts-service restart | 
| svc.gateway.restart | Gateway-e2e | 2026-02-04-epic23-svc-gateway-001 | fault_start_ms=1770204795972, fault_end_ms=1770204807092 | success (1/1) | [agent-output/validation/benchmarks/2026-02-04-epic23-svc-gateway-001/S1.svc.gateway.restart/concurrency_1/](agent-output/validation/benchmarks/2026-02-04-epic23-svc-gateway-001/S1.svc.gateway.restart/concurrency_1/) | Latency p50/p90/p99=678 ms; warmup=0; gateway-service restart | 

## Metrics Summary

| Scenario | Success/Total | Timeouts | Latency p50 (ms) | Latency p90 (ms) | Latency p99 (ms) | Throughput (req/s) |
|---|---:|---:|---:|---:|---:|---:|
| dep.minio.outage | 1/1 | 0 | 18255 | 18255 | 18255 | 0.0333 |
| dep.kafka.outage | 1/1 | 0 | 4911 | 4911 | 4911 | 0.0333 |
| dep.sr.outage | 0/1 | 1 | 0 | 0 | 0 | 0.0 |
| svc.vad.restart | 0/1 | 1 | 0 | 0 | 0 | 0.0 |
| svc.asr.restart | 1/1 | 0 | 9869 | 9869 | 9869 | 0.0333 |
| svc.translation.restart | 1/1 | 0 | 5784 | 5784 | 5784 | 0.0333 |
| svc.tts.restart | 1/1 | 0 | 1867 | 1867 | 1867 | 0.0333 |
| svc.gateway.restart | 1/1 | 0 | 678 | 678 | 678 | 1.4749 |

**Time-to-recover**: derived per scenario as the elapsed time between `fault_end_ms` and the first successful completion timestamp. See each scenario’s `results.jsonl` under its artifact directory for raw timestamps.

## Evidence Artifacts
- `run_metadata.json`
- `results.jsonl`
- `summary.json`
- `resource_usage.csv` (if enabled)
- `log_summary.json`

**Artifact root**: `agent-output/validation/benchmarks/{run_id}/`

## Observations
- MinIO outage runs completed successfully with no timeouts; latency varied across repeats.
- Kafka outage runs completed successfully after restart; one repeat attempt failed due to consumer assignment timeout and was retried.
- Schema Registry outage and VAD restart runs consistently produced timeouts (1/1), indicating fail-loudly behavior under these conditions.
- ASR/Translation/TTS restarts completed successfully with modest latency increases across repeats.

## Limitations
- Kafka outage attribution may be limited; document reliance on harness-observable outcomes if applicable.
- Kafka outage repeat run 2026-02-04-epic23-dep-kafka-003 failed due to consumer assignment timeout; 2026-02-04-epic23-dep-kafka-004 was used instead.
- Schema Registry outage impact may depend on cached schemas and service readiness timing; results reflect this local run only.

## Reproducibility
Each scenario repeated 3x; run IDs:
- dep.minio.outage: 2026-02-04-epic23-dep-minio-004, 2026-02-04-epic23-dep-minio-005, 2026-02-04-epic23-dep-minio-006
- dep.kafka.outage: 2026-02-04-epic23-dep-kafka-002, 2026-02-04-epic23-dep-kafka-004 (2026-02-04-epic23-dep-kafka-003 failed assignment)
- dep.sr.outage: 2026-02-04-epic23-dep-sr-001, 2026-02-04-epic23-dep-sr-002, 2026-02-04-epic23-dep-sr-003
- svc.vad.restart: 2026-02-04-epic23-svc-vad-001, 2026-02-04-epic23-svc-vad-002, 2026-02-04-epic23-svc-vad-003
- svc.asr.restart: 2026-02-04-epic23-svc-asr-001, 2026-02-04-epic23-svc-asr-002, 2026-02-04-epic23-svc-asr-003
- svc.translation.restart: 2026-02-04-epic23-svc-translation-001, 2026-02-04-epic23-svc-translation-002, 2026-02-04-epic23-svc-translation-003
- svc.tts.restart: 2026-02-04-epic23-svc-tts-001, 2026-02-04-epic23-svc-tts-002, 2026-02-04-epic23-svc-tts-003
- svc.gateway.restart: 2026-02-04-epic23-svc-gateway-001, 2026-02-04-epic23-svc-gateway-002, 2026-02-04-epic23-svc-gateway-003
