# Requirements Specification — Universal Speech Translation Platform

**Date**: 2026-01-30

This document translates the problem statement into a concrete requirements specification (FR/NFR) for an event-driven microservice architecture for real-time speech-to-speech translation.

## 1. Purpose

The purpose is to define **measurable** and **testable** requirements for a system that can:

- Receive speech (stream and/or audio chunks)
- Transcribe (ASR) with ongoing partial results
- Translate continuously
- Synthesize speech (TTS)
- Deliver output as both text and audio
- Document performance, robustness and scalability via reproducible evaluation

## 2. Scope and Boundary

### 2.1 In-scope (MVP)

- Event-driven pipeline with Kafka-based communication between microservices.
- Web UI for demo.
- Single-user and **one active session at a time** in the UI.
- Support for language selection per session (dynamic), with a defined MVP language scope (see FR-002).
- Artifact storage of central pipeline outputs in object storage (MinIO/S3 compatible).
- Observability: metrics, tracing (traceparent) and log correlation.
- Local Docker Compose deployment for reproducible development and testing.
- Distributed deployment via Docker Swarm (see FR-019).
- Ray Core runtime for fine-grained scheduling and warm-loaded model execution in compute-heavy stages (see FR-021).

### 2.2 Out-of-scope (MVP)

- Multi-tenant user login and access control.
- Production hardening of commercial scale (e.g. 1000+ concurrent listeners in one session) – handled as post-MVP/extension.
- TLS/encryption in transit as production requirement (see NFR-006).
- Development of new ASR/MT/TTS models (integrating existing components).
- Kubernetes-based orchestration and Kubernetes-specific operation (explicitly deferred).

## 2.3 Technology context (chosen stack)

The requirements in this document assume the following technology choices:

- **Ray Core** is used to reduce scheduling overhead for dynamic AI tasks and to support **warm-loaded models** (Actors).
- **Docker Swarm** is used for operational simplicity and to reduce the “Kubernetes tax” in a research project.
- **Pulumi (Python)** is the preferred Infrastructure-as-Code tool for reproducible cloud provisioning (post-MVP, see FR-022).

Supplementary argumentation can be found in `Analysis-and-design-of-a-platform-for-real-time-speech-translation-/scalerbar-argumentation.md`.

## 3. Definitions

- **Session**: A logical translation context with selected source and target languages, and a coherent audio stream.
- **Segment**: An audio processing unit (e.g. VAD-based or fixed time window) that runs through the pipeline and provides partial results.
- **End-to-end latency per segment**: Time from segment is received at ingress, until translated text and (if enabled) TTS audio is ready.
- **Time-to-first-output**: Time from session start to first meaningful output (partial transcription and/or partial translation) is displayed.
- **Artifacts**: Audio input, segments, transcriptions, translations, synthesized audio.

## 4. Actors and use cases (overall)

### Actors

- **User (single-user in MVP)**: Starts/stops session and views/hears output.
- **System Administrator (implicit)**: Starts stack, monitors logs/metrics, runs tests.

### Use cases (MVP)

1. **UC-1 Live one-way speech**: One speaker → running text + running TTS.
2. **UC-2 Live two-way speech (demo)**: Two participants, but UI handles one active session (two-way handled in two separate sessions or sequentially in demo).
3. **UC-3 Audio chunk upload**: Short audio upload → fast transcription/translation/TTS.

### Use cases (post-MVP)

4. **UC-4 Conference fan-out**: One speaker → 1000+ listeners.
5. **UC-5 Multi-speaker meetings**: Multiple active speakers and dynamic speaker handling.

## 5. Requirements

The requirements are divided into **functional requirements (FR)** and **non-functional requirements (NFR)**. Priority is given as **MUST/SHOULD/COULD**.

### 5.1 Functional requirements (FR)

**FR-001 (MUST) Session management**
- The system must be able to create, start and stop a session.
- Acceptance: Web UI can start/stop one session and displays session id/correlation id.

**FR-002 (MUST) Language support and MVP language scope**
- The system must support language selection per session.
- Supported languages ​​(overall vision): Danish, English, German, French, Spanish.
- MVP: the system must at least support translation from a selected source language in the set {da,en,de,fr,es} to **English**.
- Post-MVP: the system should be extended to direct translation between all language combinations, where this is supported by selected models.
- Accept: UI can select source and target languages; if selected language pair is not directly supported in MVP, a pivot strategy (via English) is documented and used or target language is limited to English.

**FR-003 (SHOULD) Switching target/source language during active session**
- The system should be able to change language pairs during an active session.
- Accept: Switching affects subsequent segments without requiring a restart.

**FR-004 (MUST) Microphone stream as primary input**
- The system must support ingesting live audio from microphone via gateway/ingress.
- Accept: Live audio can be sent to pipeline as stream/chunks and results in partial output.

**FR-005 (MUST) Uploading audio chunks**
- The system must offer an alternative way to upload short audio chunks.
- Accept: Uploading a chunk provides output (transcription + translation + TTS) without live stream.

**FR-006 (MUST) Segment and streaming processing**
- The system must be able to process both segments and continuous streaming.
- Accept: Segment-based flow produces partial results; streaming flow produces continuous updates.

**FR-007 (MUST) ASR with partial results**
- The ASR component must produce partial transcriptions continuously.
- Accept: UI displays partial transcriptions before final results.

**FR-008 (MUST) Streaming translation**
- The translation component must update the translation continuously to minimize latency.
- Accept: UI updates translated text gradually in line with ASR output.

**FR-009 (MUST) TTS as mandatory output (streaming)**
- The system must generate synthesized speech for translated text.
- MVP: playback must be continuous (streaming) to support real-time experience.
- Accept: During an active session, the UI continuously plays TTS audio that updates in line with translated text.

**FR-010 (MUST) Artifact storage in object storage**
- The system must be able to store artifacts in MinIO (S3 compatible) for auditability.
- Minimum: input audio, transcription, translation, TTS audio.
- Accept: Artifacts can be found in buckets with a deterministic key structure (session id/correlation id).

**FR-011 (MUST) Retention policy for artifacts**
- The system must support automatic deletion of artifacts after retention.
- Retention: up to 30 days (configurable).
- Accept: Lifecycle policy is documented and verifiable in MinIO.

**FR-012 (MUST) Event-driven communication and Orchestration**
- All internal service-to-service integrations must be done asynchronously via events (no direct HTTP chains between services for core flows).
- To manage the sequential nature of the pipeline, the workflow must be coordinated by a lightweight Pipeline Orchestrator using correlation IDs to ensure strict ordering and track state.
- Accept: Pipeline works end-to-end without service-to-service REST calls, and a central orchestrator successfully routes and tracks events through the system.

**FR-013 (MUST) Schema governance**
- Events must be schema-managed (e.g. Avro + Schema Registry) with compatibility requirements.
- Accept: Schemas are registered in the Schema Registry and the pipeline cannot start with incompatible changes.

**FR-014 (MUST) Correlation and trace propagation**
- The system must propagate correlation-id and traceparent between all stages.
- Accept: It is possible to follow a session through logs/traces across services.

**FR-015 (MUST) Retry and controlled degradation**
- In case of temporary errors, services must retry with backoff.
- In case of persistent errors, the system must try to skip the failing stage, if it makes sense, otherwise stop the session with an error.
- Accept: Errors are handled deterministically and reported to the UI.

**FR-016 (MUST) Durability and resumption after restart**
- The system should be able to resume after restart without losing events (at-least-once is acceptable).
- Accept: On restart, consumer groups and pipelines continue to process backlog without manual intervention.

**FR-017 (SHOULD) Duplicate handling in client/UI**
- The system should be able to handle possible duplicate events (at-least-once) without confusing the user experience.
- Accept: UI deduplicates or marks duplicates for the same segment ID.

**FR-018 (MUST) Deployment: Docker Compose**
- The system should be able to be started locally via Docker Compose.
- Accept: A new developer can start the stack and run an E2E smoke test.

**FR-019 (MUST) Deployment: Docker Swarm**
- The system should be able to be deployed to a Docker Swarm cluster.
- Accept: A “happy path” Swarm deployment is documented and reproducible (stack file, required env vars/secrets and verification steps).

**FR-020 (MUST) Horizontal scaling per service**
- Each microservice must be able to scale horizontally independently.
- Accept: It is possible to increase replicas per service without code changes.

**FR-021 (SHOULD) Ray-based compute execution (warm-loaded models)**
- Compute-heavy stages (minimum ASR and TTS; possibly also VAD and Translation) should be able to run with Ray Actors, so that models are kept warm-loaded in memory.
- Accept: The system can run in a mode where model instances remain loaded across multiple input devices, and this is documented and verifiable.

**FR-022 (SHOULD, post-MVP) Infrastructure as Code (Pulumi)**
- Infrastructure should be provisionable via IaC with Pulumi (Python) for reproducibility.
- Accept (post-MVP): A minimal Pulumi project exists that can provision necessary runtime dependencies (compute nodes + storage endpoints + network assumptions) with documented inputs/outputs.

**FR-023 (SHOULD) Architectural Guardrails**
- The system should implement runtime guardrails (e.g., filtering empty transcriptions, hallucination mitigation) to prevent invalid AI outputs from reaching the user.
- Accept: Unintelligible noise or severe model hallucinations are caught and dropped or flagged, rather than displayed as valid text.

**FR-024 (MUST) Voice Activity Detection (VAD) as Ingress Gatekeeper**
- The system must utilize VAD to identify and segment actual human speech from silence or background noise before sending data to compute-heavy ASR components.
- Accept: Prolonged periods of silence in the microphone stream do not result in unnecessary inference calls or system overload.

### 5.2 Non-functional Requirements (NFR)

**NFR-001 (MUST) Time-to-first-output**
- First partial output must be delivered within 3 seconds.
- Verification: Measure via test harness (E2E) and log/trace timestamps.

**NFR-002 (MUST) End-to-end latency per input device**
- The real-time requirement is defined as: a maximum of 5 seconds may pass from an input being received at ingress to the output being sent.
- Target: median < 5 seconds, p95 < 10 seconds.
- Verification: Latency measurement per input device (chunk/segment) based on timestamps at ingress and at the sending of output event(s), correlated with correlation ID.

**NFR-003 (SHOULD) Scalability test**
- The system should be demonstrable with up to 20 simultaneous sessions under test.
- Note: UI can still be single-session; load testing can be performed via parallel clients.

**NFR-004 (MUST) Observability**
- There must be metrics, tracing (traceparent) and structured logs.
- Logs must be correlatable with correlation-id and session-id.

**NFR-005 (MUST) Privacy: anonymization/pseudonymization in logs**
- Logs must not contain raw audio, full transcripts or other personally identifiable data in clear text.
- Acceptance: Log fields are limited to metadata (ids, timings, sizes) and possibly redacted text.

**NFR-006 (SHOULD, post-MVP) Encryption in transit**
- MVP runs without TLS in a trusted network environment (dev/test).
- Before production, traffic between client and gateway must be encrypted (TLS), and internal service-to-service connections in a distributed deployment should also be encrypted.
- Accept (post-MVP): TLS termination/termination points and cert handling are documented (tools depend on deployment environment).

**NFR-007 (MUST) Artifact security**
- Artifact references in internal events must not be bearer secrets.
- Accept: Internal events use non-presigned references (e.g. `s3://bucket/key`), and presigning only occurs at edge/out-of-band.

**NFR-008 (SHOULD) Resource efficiency**
- The solution should be able to run on standard server hardware with GPU support.
- Accept: Services can be configured for CPU/GPU runtime without contract changes.

**NFR-009 (MUST) Reproducible evaluation**
- A documented test runbook and scripts that can repeat measurements must be available.
- Accept: An external evaluator can reproduce latency/throughput and store evidence.

**NFR-010 (SHOULD) Quality Evaluation**
- Translation quality is evaluated both automatically and via human rating.
- Acceptance: Mini-benchmark dataset + evaluation method is documented.

## 6. Test and Verification Strategy (short)

Requirements are verified through a combination of:

- **Automatic tests** (unit/integration/E2E) with opt-in integration.
- **E2E smoke tests** for pipeline.
- **Latency/trace measurements** based on correlation and timestamps.
- **Documentation/evidence** (log-snapshots, metrics export, latency summary).

## 7. Open clarifications (to avoid scope explosion)

The following should be explicitly clarified in the report so that the requirements are clear:

1. How are language pairs handled in MVP in practice: (a) target language is locked to English, or (b) pivot via English is allowed, but UI can still select other target languages.
2. Which specific input units are used in the latency measurements (fixed chunk size, VAD segments, or both), so that measurements are reproducible.
3. Which stages does Ray use in MVP vs. post-MVP (e.g. ASR+TTS in MVP; Translation later), so that the implementation scope is realistic.

---

## Appendix A — Scope Clarification (Q/A)

The Q/A below is the original scope clarification from which the requirements above are derived.

**1) Target audience and scenario**
- Goal: solution that can work across user-to-user conversation, conference (1000+ listeners) and meetings with groups.
- Both live two-way and one-way speech.
- Output: both text and speech.

**2) Language and domain**
- Dynamic language selection per session.
- Languages: Danish, English, German, French, Spanish.
- General language without domain requirements.

**3) Input form and real-time definition**
- Primarily microphone stream, but also upload of short audio chunks.
- Real-time: max end-to-end latency per segment < 5 sec.
- The system must be able to work with both segmented and continuous streaming.

**4) MVP limit**
- Simple web UI for demo.
- Single-user.
- One session at a time.

**5) Pipeline features**
- ASR: partial results continuously.
- Translation: continuously updated.
- TTS: mandatory in MVP.
- Artifact storage: yes, via MinIO.

**6) Performance/capacity**
- Time-to-first-output < 3 sec.
- Median latency < 5 sec, p95 < 10 sec.
- Test: up to 20 concurrent sessions.
- No specific hardware constraints; standard server hardware with GPU support expected.

**7) Robustness**
- Retry, then skip/continue where possible, otherwise stop with error to user.
- At-least-once acceptable.
- Resume after restart without event loss.

**8) Scalability/deployment**
- Docker Compose (minimum) + Kubernetes (requirement in MVP).
- Horizontal scaling per service.
- Observability: metrics, tracing (traceparent), log correlation.

**9) Evaluation**
- Both automatic and human quality measurement.
- Mini benchmark set is defined.
- Baselines: commercial services + single-box pipeline.

**10) Security/compliance**
- Retention: up to 30 days.
- Logs are anonymized/pseudonymized.
- TLS/encryption in transit is moved to post-MVP before production.