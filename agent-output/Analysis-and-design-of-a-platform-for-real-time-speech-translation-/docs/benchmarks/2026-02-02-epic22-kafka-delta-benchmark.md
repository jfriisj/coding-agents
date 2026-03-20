# Benchmark Report — Epic 2.2 (Kafka-Delta) — 2026-02-02

**Run IDs**: `2026-02-02-epic22-s1g3` (S1.kafka_delta), `2026-02-02-epic22-s2g3` (S2.kafka_delta)
**Date**: 2026-02-02
**Environment**:
- Host: local dev workstation
- OS: Linux
- Docker: Docker Compose (local)

## Scenario Summary

| Scenario | Variant | Entrypoint | Concurrency Ladder | Warmup | Notes |
|----------|---------|------------|--------------------|--------|-------|
| S1 | S1.kafka_delta | kafka_direct | 1,2,5,10,15,20 | 0 | Kafka publish-delta only |
| S2 | S2.kafka_delta | kafka_direct | 1,2,5,10,15,20 | 0 | Includes TTS output |

## Measurement Semantics (Pinned)

- **Kafka-delta**: $T_0$ = publish `AudioInputEvent` to `speech.audio.ingress` → $T_{final}$ = final output event observed on Kafka.
- Final output event:
  - S1: `TextTranslatedEvent` on `speech.translation.text`
  - S2: `AudioSynthesisEvent` on `speech.tts.audio`

## Results

### Latency and Throughput — S1.kafka_delta

| Concurrency | P50 (ms) | P90 (ms) | P99 (ms) | Throughput (req/s) | Timeouts |
|-------------|----------|----------|----------|--------------------|----------|
| 1 | 1789.0 | 1789.0 | 1789.0 | 0.0083 | 0 |
| 2 | 3848.5 | 4628.9 | 4804.49 | 0.0167 | 0 |
| 5 | 11490.0 | 17080.0 | 17621.8 | 0.0417 | 0 |
| 10 | 29699.0 | 48378.0 | 49779.3 | 0.0833 | 0 |
| 15 | 38501.0 | 66467.4 | 69272.04 | 0.1250 | 0 |
| 20 | 54041.5 | 97801.20 | 105424.83 | 0.1667 | 0 |

### Latency and Throughput — S2.kafka_delta

| Concurrency | P50 (ms) | P90 (ms) | P99 (ms) | Throughput (req/s) | Timeouts |
|-------------|----------|----------|----------|--------------------|----------|
| 1 | 3034.0 | 3034.0 | 3034.0 | 0.0056 | 0 |
| 2 | 4994.0 | 5508.4 | 5624.14 | 0.0111 | 0 |
| 5 | 18132.0 | 21090.6 | 21562.56 | 0.0278 | 0 |
| 10 | 34372.0 | 49805.1 | 50850.81 | 0.0556 | 0 |
| 15 | 48885.0 | 76001.0 | 77605.76 | 0.0833 | 0 |
| 20 | 61621.5 | 103144.7 | 105334.04 | 0.1111 | 0 |

### Resource Usage

- CPU/memory samples captured in `resource_usage.csv` (per-service).
- Sampling cadence: 1.0s (see `run_metadata.json`).

## Evidence Artifacts

- S1 raw artifacts: `agent-output/validation/benchmarks/2026-02-02-epic22-s1g3/`
- S2 raw artifacts: `agent-output/validation/benchmarks/2026-02-02-epic22-s2g3/`

## Privacy-Safe Evidence Checks

- `tools/log_scan.py` scan results: no findings for JSON/JSONL/CSV artifacts in both run directories.

## Notes / Deviations

- Kafka-only variants executed; gateway-e2e variants remain pending.
- VAD ONNX model fetch returned 404 in logs; VAD fell back to energy-based detection.
