# Artifact Audit & Deletion Runbook (Correlation ID)

## Purpose
This runbook documents how to retrieve and delete MinIO artifacts for a single pipeline run using `correlation_id`.

## Prerequisites
- Access to MinIO (mc client or S3-compatible tooling)
- The `correlation_id` for the run (from Gateway handshake or client response)

## Correlation ID Sources
- **Gateway WebSocket handshake**: Gateway returns a JSON handshake with `correlation_id` at connection start.
- **Client responses**: Any API response referencing the request includes the same `correlation_id`.

## Artifact Locations (by stage)
Bucket/prefix conventions (default reference deployment):

- **Gateway input audio**
  - Bucket: `audio-ingress`
  - Key: `${correlation_id}.wav`

- **VAD segments**
  - Bucket: `vad-segments`
  - Prefix: `${correlation_id}/`
  - Keys: `${correlation_id}/${segment_index}.wav`

- **ASR transcript output**
  - Bucket: `asr-transcripts`
  - Key: `asr/text/${correlation_id}.txt` (or `asr/text/${correlation_id}/${segment_index}.txt` when segmented)

- **Translation output text**
  - Bucket: `translation-text`
  - Key: `translation/text/${correlation_id}.txt`

- **TTS output audio**
  - Bucket: `tts-audio`
  - Key: `tts/${correlation_id}.wav`

- **TTS input text (only when Translation opts out and TTS persistence is enabled)**
  - Bucket: `tts-audio`
  - Key: `tts/input-text/${correlation_id}.txt`

## Retrieval (mc examples)
Replace `${correlation_id}` and ensure your `mc` alias is configured.

- List objects for a run:
  - `mc ls local/audio-ingress | grep ${correlation_id}`
  - `mc ls local/vad-segments/${correlation_id}/`
  - `mc ls local/asr-transcripts/asr/text/ | grep ${correlation_id}`
  - `mc ls local/translation-text/translation/text/ | grep ${correlation_id}`
  - `mc ls local/tts-audio/tts/ | grep ${correlation_id}`
  - `mc ls local/tts-audio/tts/input-text/ | grep ${correlation_id}`

## Deletion by `correlation_id` (mc examples)
Use recursive delete for per-run prefixes and delete single keys where applicable.

- `mc rm local/audio-ingress/${correlation_id}.wav`
- `mc rm --recursive --force local/vad-segments/${correlation_id}/`
- `mc rm local/asr-transcripts/asr/text/${correlation_id}.txt`
- `mc rm --recursive --force local/asr-transcripts/asr/text/${correlation_id}/` (segmented ASR)
- `mc rm local/translation-text/translation/text/${correlation_id}.txt`
- `mc rm local/tts-audio/tts/${correlation_id}.wav`
- `mc rm local/tts-audio/tts/input-text/${correlation_id}.txt`

## Notes
- Artifacts include integrity metadata in Kafka events (SHA-256, size, content type). Use these for audit verification.
- All MinIO buckets in the reference deployment enforce lifecycle retention (default ~30 days).
- Shareable evidence bundles must exclude local environment files (`.env`, `.env.*` except `.env.example`) and any credential-bearing files.

## Orchestration Evidence Bundle (Plan 064)

Runtime orchestration evidence is emitted as local validation artifacts and is consumed by QA/UAT/DevOps as release-gate evidence.

### Artifact paths

- Evidence records (JSONL): `agent-output/validation/orchestration-evidence.jsonl`
- Bundle index manifest: `agent-output/validation/orchestration-evidence.manifest.json`
- FR-012 clause mapping: `agent-output/validation/fr012_clause_mapping.json`
- Integrity manifest: `agent-output/validation/hash_manifest.sha256`

### Bundle index contract

`orchestration-evidence.manifest.json` includes:

- `schema_version` (`orchestration-evidence-bundle/v1`)
- `generated_at`
- `evidence_file`
- `evidence_sha256`
- `records`
- `evidence_schema_version`
- `latest_correlation_id`
- `latest_transition`

### Verification steps

1. Ensure evidence file exists and is non-empty:
  - `test -s agent-output/validation/orchestration-evidence.jsonl`
2. Ensure bundle index exists and record count is positive:
  - `python - <<'PY'\nimport json\nfrom pathlib import Path\nmanifest = json.loads(Path('agent-output/validation/orchestration-evidence.manifest.json').read_text(encoding='utf-8'))\nassert manifest['schema_version'] == 'orchestration-evidence-bundle/v1'\nassert manifest['records'] > 0\nprint('manifest_ok')\nPY`
3. Verify hash manifest includes both evidence and bundle index entries:
  - `grep -E 'orchestration-evidence.jsonl|orchestration-evidence.manifest.json|fr012_clause_mapping.json' agent-output/validation/hash_manifest.sha256`
4. Validate FR-012 mapping artifact status:
  - `python - <<'PY'\nimport json\nfrom pathlib import Path\nmapping = json.loads(Path('agent-output/validation/fr012_clause_mapping.json').read_text(encoding='utf-8'))\nassert mapping['schema_version'] == 'fr012-clause-mapping/v1'\nassert mapping['overall_status'] == 'pass'\nprint('fr012_mapping_ok')\nPY`

### Governance interpretation

- `evidence_schema_version` MUST be `orchestration-evidence/v1` for Plan 064 evidence acceptance.
- `fr012_clause_mapping.json` MUST report `overall_status = pass` for clause-level FR-012 acceptance.
- QA/UAT reviewers should validate `latest_correlation_id` and `latest_transition` against run context when reviewing terminal path evidence.
- DevOps release gate should reject evidence bundles missing either manifest file or hash manifest entries.
