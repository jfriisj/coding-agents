# Swarm Deployment Verification Runbook (Epic 2.5)

This runbook executes the Swarm verification flow for Plan 044 using the canonical Gateway `/docs` upload workflow, KRaft-only Kafka, and a shareable evidence bundle.

## Prerequisites

- Docker Engine with Swarm enabled on the host.
- NVIDIA GPU drivers installed on GPU-capable nodes.
- NVIDIA container runtime/toolkit configured on GPU nodes.
- A container registry accessible from Swarm nodes.
- Image digests for all services (use immutable digests, not mutable tags).
- Synthetic or explicitly consented audio only.
- Runtime/service configuration maintained in root `.env` (single source of truth).

## Inputs

- Stack file: [deploy/swarm-stack.yml](../deploy/swarm-stack.yml)
- Evidence runner: [tools/swarm_evidence_cli.py](tools/swarm_evidence_cli.py)
- Evidence output location: `agent-output/validation/swarm/<run_id>/`

## Step 1: Initialize Swarm (single-node)

```bash
docker swarm init
```

Label the node for pinned stateful services:

```bash
docker node update --label-add role=stateful $(docker node ls --format '{{.Hostname}}' | head -n 1)
```

Label GPU-capable nodes for GPU workloads:

```bash
docker node update --label-add gpu=true $(docker node ls --format '{{.Hostname}}' | head -n 1)
```

## Step 2: Create secrets (MinIO)

```bash
printf '%s' "$MINIO_ROOT_USER" | docker secret create minio_root_user -
printf '%s' "$MINIO_ROOT_PASSWORD" | docker secret create minio_root_password -
printf '%s' "$MINIO_ACCESS_KEY" | docker secret create minio_access_key -
printf '%s' "$MINIO_SECRET_KEY" | docker secret create minio_secret_key -
```

## Step 3: Set image digests and KRaft cluster ID

Export image digests and cluster ID in the shell used for deploy:

```bash
export KAFKA_CLUSTER_ID=$(docker run --rm confluentinc/cp-kafka:7.5.3 kafka-storage.sh random-uuid)
export KAFKA_IMAGE_REF=confluentinc/cp-kafka@sha256:REPLACE
export SCHEMA_REGISTRY_IMAGE_REF=confluentinc/cp-schema-registry@sha256:REPLACE
export MINIO_IMAGE_REF=minio/minio@sha256:REPLACE
export MINIO_MC_IMAGE_REF=minio/mc@sha256:REPLACE
export ASR_IMAGE_REF=registry.example.com/speech-asr@sha256:REPLACE
export VAD_IMAGE_REF=registry.example.com/speech-vad@sha256:REPLACE
export TRANSLATION_IMAGE_REF=registry.example.com/speech-translation@sha256:REPLACE
export TTS_IMAGE_REF=registry.example.com/speech-tts@sha256:REPLACE
export GATEWAY_IMAGE_REF=registry.example.com/speech-gateway@sha256:REPLACE
export BFF_GATEWAY_IMAGE_REF=registry.example.com/speech-bff-gateway@sha256:REPLACE
export BFF_GATEWAY_TOKEN_SECRET=REPLACE_WITH_ROTATED_NON_PLACEHOLDER_SECRET

docker secret rm bff_gateway_token_secret >/dev/null 2>&1 || true
printf '%s' "$BFF_GATEWAY_TOKEN_SECRET" | docker secret create bff_gateway_token_secret -
```

## Step 4: Deploy the stack

Load the single runtime `.env` into the current shell and deploy:

```bash
set -a
. ./.env
set +a
docker stack deploy -c deploy/swarm-stack.yml speech
```

`docker stack deploy` uses shell environment interpolation from `.env`-loaded variables.

If you must override a value for a single deployment, export it in-shell after loading `.env`.

Example:

```bash
export EXECUTION_RUNTIME=onnx
export EXECUTION_DEVICE=cpu
docker stack deploy -c deploy/swarm-stack.yml speech
```

Wait for services to stabilize and for `kafka-init` and `minio-init` to complete.

Swarm consumes the BFF signing secret via `BFF_GATEWAY_TOKEN_SECRET_FILE` mounted from `bff_gateway_token_secret`; local compose continues to require `BFF_GATEWAY_TOKEN_SECRET` as an environment value.

## Step 5: Run primary-edge/fallback verification and docs-first evidence capture

Because `bff-gateway-service` is now the published edge while `gateway-service` is retained as internal fallback, verify both paths before evidence capture:

```bash
docker service ls --format '{{.Name}} {{.Replicas}}' | grep -E 'speech_bff-gateway-service|speech_gateway-service'

docker run --rm \
  --network speech_speech_net \
  python:3.11-slim \
  python - <<'PY'
import socket

for host, port in [("bff-gateway-service", 8000), ("gateway-service", 8000)]:
    sock = socket.create_connection((host, port), timeout=5)
    sock.close()
    print(f"connectivity_ok={host}:{port}")
PY
```

Then run the legacy docs/upload evidence CLI from a container on the overlay network (this verifies fallback continuity until BFF-native evidence flow is fully cut over). First, capture the supporting evidence inputs used by the bundle:

```bash
mkdir -p agent-output/validation/swarm/tmp

./.venv/bin/python - <<'PY'
import json
import subprocess
from pathlib import Path

from tools.swarm_collectors import (
  collect_image_digests,
  collect_kafka_kraft_markers,
  collect_kafka_topic_partitions,
  collect_stack_fingerprint,
  collect_swarm_status_summary,
  parse_service_ls,
)

def run(cmd):
  return subprocess.check_output(cmd).decode("utf-8")

services_output = run([
  "docker",
  "service",
  "ls",
  "--format",
  "{{.Name}}|{{.Mode}}|{{.Replicas}}|{{.Image}}",
])
service_rows = parse_service_ls(services_output)
services = [row["service"] for row in service_rows]

image_digests = collect_image_digests(services=services, command_runner=run)
topic_partitions = collect_kafka_topic_partitions(stack_name="speech", command_runner=run)
stack_fingerprint = collect_stack_fingerprint("deploy/swarm-stack.yml")
swarm_status = collect_swarm_status_summary(stack_name="speech", command_runner=run)
kraft_markers = collect_kafka_kraft_markers(stack_name="speech", command_runner=run)

Path("agent-output/validation/swarm/tmp/stack_fingerprint.json").write_text(
  json.dumps(stack_fingerprint, indent=2),
  encoding="utf-8",
)
Path("agent-output/validation/swarm/tmp/image_digests.json").write_text(
  json.dumps(image_digests, indent=2),
  encoding="utf-8",
)
Path("agent-output/validation/swarm/tmp/swarm_status_summary.json").write_text(
  json.dumps(swarm_status, indent=2),
  encoding="utf-8",
)
Path("agent-output/validation/swarm/tmp/kafka_topic_partitions.json").write_text(
  json.dumps(topic_partitions, indent=2),
  encoding="utf-8",
)
Path("agent-output/validation/swarm/tmp/kafka_kraft_markers.json").write_text(
  json.dumps(kraft_markers, indent=2),
  encoding="utf-8",
)
PY
```

Then run the evidence CLI from a container on the overlay network:

```bash
docker run --rm \
  --network speech_speech_net \
  -v "$PWD":/workspace \
  -w /workspace \
  python:3.11-slim \
  bash -lc "pip install websockets && python -m tools.swarm_evidence_cli \
    --run-id run-006 \
    --http-base-url http://gateway-service:8000 \
    --ws-url ws://gateway-service:8000/ws/results \
    --output-dir agent-output/validation/swarm \
    --dataset-provenance synthetic \
    --stack-fingerprint agent-output/validation/swarm/tmp/stack_fingerprint.json \
    --image-digests agent-output/validation/swarm/tmp/image_digests.json \
    --swarm-status agent-output/validation/swarm/tmp/swarm_status_summary.json \
    --kafka-kraft-markers agent-output/validation/swarm/tmp/kafka_kraft_markers.json \
    --kafka-topic-partitions agent-output/validation/swarm/tmp/kafka_topic_partitions.json"
```

Expected output is a set of JSON artifacts under `agent-output/validation/swarm/run-006/` and a `hash_manifest.sha256`.

For BFF-native bridge/event evidence (short + long variants) without legacy gateway WS tooling:

```bash
docker run --rm \
  --network speech_speech_net \
  -e BFF_GATEWAY_TOKEN_SECRET="$BFF_GATEWAY_TOKEN_SECRET" \
  -v "$PWD":/workspace \
  -w /workspace \
  python:3.11-slim \
  bash -lc "pip install websockets httpx && python -m tools.bff_ws_evidence_cli \
    --run-id bff-short-run-001 \
    --http-base-url http://bff-gateway-service:8000 \
    --session-ws-base-url ws://bff-gateway-service:8000 \
    --variant-id S1.bff_gateway_e2e \
    --entrypoint-id bff_gateway_e2e \
    --count 1 \
    --duration 0.5 \
    --output-dir agent-output/validation/benchmarks"

docker run --rm \
  --network speech_speech_net \
  -e BFF_GATEWAY_TOKEN_SECRET="$BFF_GATEWAY_TOKEN_SECRET" \
  -v "$PWD":/workspace \
  -w /workspace \
  python:3.11-slim \
  bash -lc "pip install websockets httpx && python -m tools.bff_ws_evidence_cli \
    --run-id bff-long-run-001 \
    --http-base-url http://bff-gateway-service:8000 \
    --session-ws-base-url ws://bff-gateway-service:8000 \
    --variant-id S1.bff_gateway_e2e \
    --entrypoint-id bff_gateway_e2e \
    --count 1 \
    --duration 8.0 \
    --output-dir agent-output/validation/benchmarks"
```

## Step 6: Verify evidence bundle

- Confirm required artifacts exist (see Plan 044 Evidence Bundle Checklist).
- Confirm `denylist_scan.json` reports `status=pass`.
- Confirm `kafka_topic_partitions.json` shows partitions >= replicas (min 2).
- Confirm BFF evidence summary/result artifact structure matches gateway evidence schema expectations for benchmark continuity.

## BFF Signing Secret Rotation Posture

Ownership:

- Release operator/on-call SRE for deploy target.

Trigger conditions:

- Scheduled credential rotation window.
- Suspected credential exposure.
- Operator/role transition requiring immediate secret turnover.

Execution pathway:

1. Generate a new non-placeholder secret value.
2. Compose target: export the rotated `BFF_GATEWAY_TOKEN_SECRET` value and restart `bff-gateway-service`.
3. Swarm target: recreate `bff_gateway_token_secret` and redeploy the stack so `/run/secrets/bff_gateway_token_secret` is refreshed.
4. Re-run Step 5 primary-edge/fallback checks and evidence capture smoke to confirm healthy post-rotation behavior.

## Rollback

Rollback trigger conditions:

- `speech_bff-gateway-service` fails to maintain desired replicas after stabilization window.
- Primary-edge acceptance checks fail for BFF routing while fallback continuity is still required.
- Evidence capture cannot complete on the approved edge path.

Rollback action:

1. Redeploy the last known-good stack revision that exposes `gateway-service` as browser edge.
2. Re-run the Step 5 connectivity/evidence flow against `gateway-service`.
3. Record rollback rationale, trigger, and artifact references in release evidence.

```bash
docker stack rm speech
```

If further diagnosis is needed, preserve `kafka_data` and `minio_data` volumes; otherwise, remove them explicitly.
