# Benchmark Report Template (Epic 2.2)

**Run ID**: 
**Date**: 
**Environment**:
- Host: 
- OS: 
- CPU: 
- RAM: 
- Docker: 

## Scenario Summary

| Scenario | Variant | Entrypoint | Concurrency Ladder | Warmup | Notes |
|----------|---------|------------|--------------------|--------|-------|
| S1 | S1.kafka_delta | kafka_direct | 1,2,5,10,15,20 | 2 | |
| S1 | S1.gateway_e2e | gateway_ws_stream | 1,2,5,10,15,20 | 2 | |
| S2 | S2.kafka_delta | kafka_direct | 1,2,5,10,15,20 | 2 | |
| S2 | S2.gateway_e2e | gateway_ws_stream | 1,2,5,10,15,20 | 2 | |

## Measurement Semantics (Pinned)

- **Kafka-delta**: $T_0$ = publish `AudioInputEvent` to `speech.audio.ingress` → $T_{final}$ = final output event observed on Kafka.
- **Gateway-e2e**: $T_0$ = client request start → $T_{final}$ = final output event observed on Kafka.
- Final output event:
  - S1: `TextTranslatedEvent` on `speech.translation.text`
  - S2: `AudioSynthesisEvent` on `speech.tts.audio`

## Results

### Latency and Throughput

| Variant | Concurrency | P50 (ms) | P90 (ms) | P99 (ms) | Throughput (req/s) | Errors |
|---------|-------------|----------|----------|----------|--------------------|--------|
| S1.kafka_delta | 1 | | | | | |
| S1.kafka_delta | 2 | | | | | |
| S1.kafka_delta | 5 | | | | | |
| ... | ... | | | | | |

### Resource Usage

- CPU/memory samples captured in `resource_usage.csv` (per-service).
- Sampling cadence: 

## Evidence Artifacts

- Raw artifacts: `agent-output/validation/benchmarks/<run_id>/...`
- Reports: `docs/benchmarks/`

## Privacy-Safe Evidence Checks

- `tools/log_scan.py` scan results for:
  - Service logs
  - Benchmark artifacts

## Notes / Deviations

- Concurrency ladder deviations: 
- Environment variance: 
- Known issues: 
