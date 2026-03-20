# Epic 2.3 Scenario Catalog (v1)

**Scope**: Roadmap Option A — one controlled failure scenario per critical dependency and per critical service.

## Measurement Rubric (v1)
- **Fail loudly**: measurable increase in failures/timeouts during fault window, with privacy-safe failure signals (counts + timestamps) and explicit fault window metadata.
- **Recovery**: time from `fault_end_ms` to first successful completion (and/or return to baseline success rate).
- **User-visible impact**: completion rate and latency deltas (p50/p90/p99 for `t_final - t0`), and time-to-first output where available.

## Scenario Catalog

### Dependencies

| scenario_id | Target | Injection | Preconditions | Expected Behavior | User-Visible Metrics | Operator Signals (privacy-safe) |
|---|---|---|---|---|---|---|
| dep.minio.outage | MinIO | `stop` → `start` | Storage enabled; normal workload in progress | Fail loudly during outage; recover on restore | Completion rate drop + latency deltas; time-to-recover | `claim_check_drop` counts by reason; fault window metadata |
| dep.kafka.outage | Kafka | `stop` → `start` | Kafka-delta workload active | Fail loudly and/or stall; recovery after restore | Completion rate + latency deltas; time-to-recover | Harness-observable publish/timeout counts; log summary if available |
| dep.sr.outage | Schema Registry | `stop` → `start` | Services already running | Expected: minimal impact steady-state; document observed behavior | Completion rate + latency deltas | Fault window metadata; consumer lifecycle signals |

### Services

| scenario_id | Target | Injection | Preconditions | Expected Behavior | User-Visible Metrics | Operator Signals (privacy-safe) |
|---|---|---|---|---|---|---|
| svc.gateway.restart | Gateway | `restart` | Gateway-e2e workload active | Transient disconnect; recover on restart | Completion rate + latency deltas | Fault window metadata; gateway error counts (if available) |
| svc.vad.restart | VAD | `restart` | Kafka-delta workload active | Transient stall/fail; recover on restart | Completion rate + latency deltas | Consumer lifecycle signals |
| svc.asr.restart | ASR | `restart` | Kafka-delta workload active | Transient stall/fail; recover on restart | Completion rate + latency deltas | Consumer lifecycle signals |
| svc.translation.restart | Translation | `restart` | Kafka-delta workload active | Transient stall/fail; recover on restart | Completion rate + latency deltas | Consumer lifecycle signals |
| svc.tts.restart | TTS | `restart` | Kafka-delta workload active | Transient stall/fail; recover on restart | Completion rate + latency deltas | Consumer lifecycle signals |

## Evidence Artifacts (expected)
- `run_metadata.json` (includes fault window metadata when injected)
- `results.jsonl`
- `summary.json`
- `resource_usage.csv` (if enabled)
- `log_summary.json` (aggregated failure signals)

## Notes
- Fault injection must be local-only by default.
- Evidence artifacts must be content-free and denylist-scanned by default.
- Kafka outage evidence must document any attribution limitations explicitly.
