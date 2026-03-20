# Baseline A Comparison Narrative (Epic 2.4)

## Purpose

Provide the minimum required comparison narrative for Plan 048 by comparing a primary run against Baseline A on the same synthetic `da→en` dataset.

## Compared Runs

- **Primary run**: `2026-02-13-epic24-primary`
  - Model: `Helsinki-NLP/opus-mt-da-en`
  - Metadata: `agent-output/validation/quality/2026-02-13-epic24-primary/run_metadata.json`
- **Baseline A run**: `2026-02-13-epic24-baseline-a`
  - Model: `Helsinki-NLP/opus-mt-mul-en` (second open model)
  - Metadata: `agent-output/validation/quality/2026-02-13-epic24-baseline-a/run_metadata.json`

Both runs use:
- Dataset: `datasets/translation-quality/da-en-synth-v1.jsonl`
- Dataset hash: `e5703458c19ba676804af623e87a4926d6df31363ce56dd2cface87d1c4b5672`
- Deterministic sampling: `deterministic-file-order`
- Seed: `0`

## Results Summary

### Automated metric (`bleu1`)

- Primary (`metrics_summary.json`):
  - `score_mean`: `0.6112964800888657`
  - `score_min`: `0.23884377019126307`
  - `score_max`: `1.0`
  - `sample_count`: `12`
- Baseline A (`metrics_summary.json`):
  - `score_mean`: `0.5986496487353399`
  - `score_min`: `0.23884377019126307`
  - `score_max`: `1.0`
  - `sample_count`: `12`

Observed delta (Primary − Baseline A):
- `bleu1 score_mean`: `+0.0126468313535258`

### Human aggregate summary (`human_summary.json`)

- Primary:
  - Adequacy mean: `4.5833`
  - Fluency mean: `4.3333`
- Baseline A:
  - Adequacy mean: `4.5833`
  - Fluency mean: `4.3333`

Human aggregate deltas are `0.0` for both dimensions in this run pair because the same ratings file was used for both run IDs.

## Interpretation

For this synthetic mini-benchmark and BLEU-1 metric, the primary model (`opus-mt-da-en`) performs slightly better than Baseline A (`opus-mt-mul-en`) by `+0.0126` mean BLEU-1. This supports a small but measurable advantage for the primary model under the current evaluation setup.

## Limitations

- Dataset is intentionally small and synthetic (`n=12`), so external generalization is limited.
- BLEU-1 is lexical and does not fully capture semantic adequacy.
- Human aggregates were computed from one shared ratings file across run IDs; independent blinded rater rounds per model would provide stronger comparative evidence.
- `model_revision` is currently recorded as `unknown` in run metadata.

## Evidence Links

- Primary metrics: `agent-output/validation/quality/2026-02-13-epic24-primary/metrics_summary.json`
- Primary human summary: `agent-output/validation/quality/2026-02-13-epic24-primary/human_summary.json`
- Baseline A metrics: `agent-output/validation/quality/2026-02-13-epic24-baseline-a/metrics_summary.json`
- Baseline A human summary: `agent-output/validation/quality/2026-02-13-epic24-baseline-a/human_summary.json`
