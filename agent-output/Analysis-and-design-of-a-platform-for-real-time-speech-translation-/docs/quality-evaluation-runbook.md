# Translation Quality Evaluation Runbook (Epic 2.4)

This runbook describes how to generate **reproducible**, **privacy-safe** translation quality evidence.

## Canonical Artifacts

- Human evaluation rubric: `docs/quality-evaluation-rubric.md`
- Baseline A comparison narrative (current): `docs/quality-evaluation-baseline-a-comparison-2026-02-13.md`

## Inputs

- Dataset: synthetic `da→en` JSONL dataset
  - Default: `datasets/translation-quality/da-en-synth-v1.jsonl`

## Outputs (Evidence Bundle)

Generated outputs are written under:

- `agent-output/validation/quality/<run_id>/`

### Shareable-by-default artifacts (aggregate-only)

These files are intended to be shareable:

- `run_metadata.json`
- `provenance_manifest.json` (schema/model/dataset provenance, metadata-only)
- `metrics_summary.json`
- `metric_scores.json` (contains only `sample_id`, numeric scores, and lengths)
- `human_summary.json` (aggregate-only)
- `denylist_scan.json`
- `hash_manifest.sha256`

### Restricted artifacts (text-bearing)

Text-bearing artifacts are written under:

- `agent-output/validation/quality/<run_id>/restricted/`

Example:

- `translations.jsonl` (contains source/reference/hypothesis strings)

## Safety Gates (Fail Closed)

- Shareable JSON artifacts enforce an explicit allowlist schema, including top-level and nested structures.
- A denylist scan is run over produced artifacts; if it finds presigned URLs, auth headers, or binary markers, the run fails.
- A SHA256 hash manifest is written for integrity.

## Running the evaluation

From repo root:

- `python -m tools.quality_eval_cli --run-id run-001`

Optional flags:

- `--dataset-path datasets/translation-quality/da-en-synth-v1.jsonl`
- `--model-id Helsinki-NLP/opus-mt-da-en`
- `--model-revision <immutable-revision>` (required for reproducible evidence, e.g. git SHA/tag/digest/hash)
- `--device cpu` (or `cuda` if your environment supports it)

### Provenance requirements (Plan 056)

- `model_revision` is required for quality evidence runs and must be explicitly provided via:
  - `--model-revision`, or
  - `QUALITY_MODEL_REVISION` environment variable.
- `dataset_id` recorded in provenance must be a repo-relative POSIX path (for example `datasets/translation-quality/da-en-synth-v1.jsonl`).
- Absolute dataset identifiers, `~` prefixes, and traversal segments (`.`/`..`) are rejected.

### Dependencies

The default translator uses Hugging Face Transformers + Torch. If those are not installed, translation will fail at runtime.

## Human evaluation (CSV → aggregate-only)

1) Create a ratings CSV with **no free-form text columns**. Required structure:

- Columns: `sample_id,adequacy,fluency`
- Rating scale (recommended): 1–5
- Template: `datasets/translation-quality/human-ratings-template.csv`

2) Run evaluation with the ratings CSV:

- `python -m tools.quality_eval_cli --run-id run-001 --human-ratings-csv path/to/ratings.csv`

The shareable output will contain aggregates only (means/min/max/counts per dimension).

## Baseline Comparison Narrative

After generating primary and Baseline A runs, update and/or publish a comparison narrative grounded in produced artifacts:

- `docs/quality-evaluation-baseline-a-comparison-2026-02-13.md`

The narrative must reference:
- primary and baseline `run_metadata.json`
- both `metrics_summary.json` files
- both `human_summary.json` files (if human ratings were supplied)

## Translation Pair Smoke Evidence (Epic 2.6)

Use this smoke path to prove second language pair flexibility with metadata-only shareable outputs.

### Command

From repo root:

- `python -m tools.translation_pair_smoke_cli --run-id run-001 --source-language en --target-language es --model-id Helsinki-NLP/opus-mt-en-es --model-revision main --execution-device cpu`

### Output paths

- Shareable: `agent-output/validation/translation-smoke/<run_id>/`
- Restricted (optional): `agent-output/validation/translation-smoke/restricted/<run_id>/`

Example completed run:

- `agent-output/validation/translation-smoke/run-049-2026-02-13-01/`

### Shareable artifacts

- `run_metadata.json` (includes `git_sha`, `model_id`, `model_revision`, language pair, and command metadata)
- `smoke_summary.json`
- `denylist_scan.json`
- `hash_manifest.sha256`

### Optional restricted artifact

- `translation_sample.txt` (written only when `--include-restricted-sample` is provided)

### Safety gates

- Explicit allowlist-key validation for shareable JSON artifacts.
- Denylist scanning across shareable outputs.
- Integrity manifest generation via SHA-256.

## Bidirectional Conversation Value Evidence (Epic 2.12.1)

Use this workflow to generate the canonical user-value proof for one session that demonstrates both directions (`A_to_B`, `B_to_A`) with translated text and receiver-side TTS playback observability.

### Canonical contract outputs

Generated outputs are written under:

- `agent-output/validation/benchmarks/<run_id>/<variant>/concurrency_<n>/conversation-value-evidence/`

Primary artifacts:

- `conversation_value_evidence.json`
- `run_metadata.json`
- `denylist_scan.json`
- `hash_manifest.sha256`

### Canonical schema requirements

`conversation_value_evidence.json` includes:

- `evidence_schema_version` (current: `1.0.0`)
- `run_id`
- `session_id`
- `shareability` (`shareable` or `restricted`)
- `status` (`complete`, `partial`, or `invalid`)
- `observations[]` with required fields:
  - `direction` (`A_to_B`/`B_to_A`)
  - `correlation_id`
  - `text_observed`
  - `tts_playback_status` (`success`/`fail`/`timeout`)
  - `speech_start_ts_ms`
  - `tts_playback_start_ts_ms`

### Timeout timestamp semantics

- For `tts_playback_status = timeout`, `tts_playback_start_ts_ms` uses sentinel `0` (no playback start observed).
- TTFO samples include `tts_playback_timeout_ts_ms` for timeout cases to record when timeout was established.
- Reviewers MUST interpret sentinel `0` as non-start, not as a measured playback start timestamp.

### Fail-closed readiness gate

- Release readiness is blocked unless `status == complete`.
- `partial` and `invalid` are treated as failed value-evidence runs.

### Shareability and security gates

- All artifacts carry an explicit shareability posture.
- `restricted` outputs must not be included in shareable publication bundles.
- Auth bypass is not allowed in canonical value-evidence runs.
- Denylist and integrity checks are required before handoff.

### Identifier handling policy (internal vs external sharing)

- Internal review mode:
  - Restricted-context bundles may retain raw operational identifiers (`session_id`, `correlation_id`) when access is limited to authorized project roles.
- External sharing mode:
  - Shareable bundles must use deterministic pseudonymized identifiers for `session_id` and `correlation_id`.
  - Pseudonymized identifiers must preserve run-level comparability across artifacts within the same run.

### Retention and access governance (Epic 2.12.1)

- Retention baselines:
  - `dev/local` evidence artifacts: minimum 7 days.
  - `qa/uat/release evidence` artifacts: minimum 30 days.
- Policy owner:
  - Default owner is DevOps evidence-storage lifecycle owner unless explicitly overridden in handoff artifacts.
- Access controls:
  - Restricted artifacts are writable only by execution principals.
  - Reviewer access to restricted artifacts is read-only by default.
  - Any write-capable reviewer exception must be explicitly approved and documented in handoff notes.
- Verification evidence:
  - Each closure run must include lifecycle enforcement evidence (rule/config reference and verification timestamp/result).

