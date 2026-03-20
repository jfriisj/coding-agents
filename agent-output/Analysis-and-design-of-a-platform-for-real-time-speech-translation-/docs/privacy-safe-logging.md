# Privacy-Safe Observability Policy (Epic 2.9)

This policy defines **what is allowed** and **what is prohibited** in logs and traces for the speech translation MVP. The default posture is safe-by-default and suitable for sharing thesis evidence logs externally.

## 1) Telemetry Modes

### Normal telemetry (default)
- Always-on, low-volume, stable fields.
- **Safe-by-default and shareable.**
- MUST NOT include:
  - Raw audio bytes
  - Transcript text or translated text
  - Request bodies containing user content
  - URL query strings
  - Presigned URLs or credentials

### Debug telemetry (opt-in)
- MUST be explicitly enabled (never default).
- MUST emit a clear startup warning that output is **not shareable**.
- MAY increase verbosity, but MUST still avoid:
  - Raw audio bytes, transcript text, or translated text
  - Credentials (Authorization, Cookie, tokens)
  - Full presigned URLs

### Evidence mode
- Evidence runs MUST use **Normal telemetry** behavior.
- Evidence runs MUST enforce **trace attribute allowlisting**.

## 2) Prohibited Content
- Raw audio bytes or binary payloads
- Full transcripts or translated text
- Presigned URLs (bearer credentials)
- Authorization headers, cookies, tokens
- Request bodies containing user content

## 3) Allowed Fields (examples)
- `correlation_id`
- `service` / `component`
- `event_type`
- `duration_ms`
- `payload_bytes` / `artifact_bytes`
- `language` / `source_language` / `target_language`
- `error_code` (typed, not raw payload)

## 4) Redaction & Sanitization Rules
- Strip URL query strings and user:pass credentials.
- Remove Authorization/Cookie headers from any log output.
- Replace raw text with **metadata** only (length, presence).
- Exception messages must be sanitized before logging.

## 5) Trace Attributes (Evidence Mode)
- Evidence-mode spans MUST use a **strict allowlist**.
- Do not record transcript/translation content, raw payloads, or URL query strings.

**Helper**: `speech_lib.observability.allowlist_trace_attributes` provides a default allowlist and a pure filter for evidence-mode attributes.

## 6) Evidence Log Scan
- The log scan is a **guardrail**, not a guarantee.
- Prevention must happen at emission time via policy compliance.
- Scan patterns include presigned URLs, auth headers, and binary markers (e.g., WAV headers).

**Script**: `tools/log_scan.py`
- Example: `python tools/log_scan.py path/to/compose.log`

## 7) Data Classification
- Transcripts, translations, and audio are treated as **potentially sensitive/PII**.
- Do not log content; rely on MinIO artifacts for deep inspection.

## 8) Retention & Sharing
- Evidence logs/traces are considered potentially sensitive by default.
- Retention should be time-bounded and controlled (manual is acceptable for MVP).
- Debug-mode logs are **not** intended to be shared externally.

## 9) Shareable Evidence Packaging Exclusions
- Never include local environment files in shared artifacts: `.env`, `.env.*` (except `.env.example`).
- Never include secret stores or credential files (shell history, token caches, cloud credentials).
- Never include raw object-storage presigned URLs or query strings.
- Prefer metadata-only evidence files (counts, hashes, durations, event/message types).
