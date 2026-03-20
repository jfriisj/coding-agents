# Benchmark Report — Epic 2.2 (Kafka-Delta) — 2026-02-03

**Run IDs**: `2026-02-03-epic22-s1g4` (S1.kafka_delta), `2026-02-03-epic22-s2g4` (S2.kafka_delta)
**Date**: 2026-02-03
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

## Measurement Window

- The runner writes `window_start_ms/window_end_ms` to each `run_metadata.json` under `agent-output/validation/benchmarks/2026-02-03-epic22-s1g4/*` and `...-s2g4/*`; the interval between those UTC-aligned timestamps defines the throughput measurement window. Throughput per concurrency point is computed as $\frac{\text{requests_completed}}{(\text{window\_end\_ms}-\text{window\_start\_ms})/1000}$, where `requests_completed` equals the concurrency level because the runner issues one request per worker within the window.

## Results

### Latency and Throughput — S1.kafka_delta

| Concurrency | P50 (ms) | P90 (ms) | P99 (ms) | Throughput (req/s) | Timeouts |
|-------------|----------|----------|----------|--------------------|----------|
| 1 | 7041.0 | 7041.0 | 7041.0 | 0.0083 | 0 |
| 2 | 2708.5 | 3085.7 | 3170.57 | 0.0167 | 0 |
| 5 | 13084.0 | 18462.0 | 19059.6 | 0.0417 | 0 |
| 10 | 21393.0 | 37749.3 | 39144.93 | 0.0833 | 0 |
| 15 | 32067.0 | 58804.4 | 61502.24 | 0.1250 | 0 |
| 20 | 44648.5 | 79432.7 | 85176.05 | 0.1667 | 0 |

### Latency and Throughput — S2.kafka_delta

| Concurrency | P50 (ms) | P90 (ms) | P99 (ms) | Throughput (req/s) | Timeouts |
|-------------|----------|----------|----------|--------------------|----------|
| 1 | 3057.0 | 3057.0 | 3057.0 | 0.0056 | 0 |
| 2 | 4449.0 | 4928.2 | 5036.02 | 0.0111 | 0 |
| 5 | 15623.0 | 17896.8 | 18340.68 | 0.0278 | 0 |
| 10 | 30739.5 | 40257.0 | 41229.0 | 0.0556 | 0 |
| 15 | 41888.0 | 65812.6 | 67337.64 | 0.0833 | 0 |
| 20 | 57414.0 | 86898.6 | 89113.86 | 0.1111 | 0 |

### Resource Usage

- CPU/memory samples captured in `resource_usage.csv` (per-service).
- Sampling cadence: 1.0s (see `run_metadata.json`).

## Evidence Artifacts

- S1 raw artifacts: `agent-output/validation/benchmarks/2026-02-03-epic22-s1g4/`
- S2 raw artifacts: `agent-output/validation/benchmarks/2026-02-03-epic22-s2g4/`

## Privacy-Safe Evidence Checks

- `tools/log_scan.py` scan results: no findings for JSON/JSONL/CSV artifacts in both run directories.

## Notes / Deviations

- Kafka-only variants executed; gateway-e2e variants remain pending.
- VAD ONNX model resolved via `onnx-community/silero-vad` with filename `onnx/model.onnx`.
