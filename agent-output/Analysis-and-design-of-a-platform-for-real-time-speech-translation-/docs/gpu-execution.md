# GPU Execution Reference (Epic 3.2)

This document describes how to enable GPU execution for ASR, Translation, TTS, and VAD in Compose and Swarm deployments.

## Prerequisites

- NVIDIA GPU drivers installed on GPU-capable hosts.
- NVIDIA container runtime/toolkit configured for Docker.
- Minimum reference GPU baseline: RTX 3060 (8GB VRAM).

## Execution Contract (All Model Services)

- `EXECUTION_DEVICE`: `cpu|cuda` (default `cpu`)
- `EVIDENCE_MODE`: `true|false` (default `false`)
  - When `true`, requesting CUDA with no CUDA available causes startup failure.
- `EXECUTION_PRECISION`: optional `fp32|fp16|bf16`
- `CUDA_VISIBLE_DEVICES`: optional standard CUDA variable

## Runtime Mode Matrix (ONNX vs non-ONNX)

### ASR

- non-ONNX: `ASR_EXECUTION_MODE=baseline`, `EXECUTION_RUNTIME=native`
- ONNX: `ASR_EXECUTION_MODE=onnx_baseline`, `EXECUTION_RUNTIME=onnx`

### Translation

- non-ONNX: `TRANSLATION_MODEL_ENGINE=hf_seq2seq`, `EXECUTION_RUNTIME=native`
- ONNX: `TRANSLATION_MODEL_ENGINE=onnx_seq2seq`, `EXECUTION_RUNTIME=onnx`

### VAD

- non-ONNX: `VAD_USE_ONNX=0`, `EXECUTION_RUNTIME=native`
- ONNX: `VAD_USE_ONNX=1`, `VAD_MODEL_FILENAME=onnx/model.onnx`, `EXECUTION_RUNTIME=onnx`

### TTS

- non-ONNX: `TTS_MODEL_ENGINE=kokoro_hf`, `EXECUTION_RUNTIME=native`
- ONNX: `TTS_MODEL_ENGINE=kokoro_onnx`, `TTS_MODEL_FILENAME=onnx/model.onnx`, `EXECUTION_RUNTIME=onnx`

## Docker Compose (Local GPU)

Set execution vars for GPU-capable services before bringing up Compose:

```bash
export EXECUTION_DEVICE=cuda
export EVIDENCE_MODE=false
```

If your GPU has limited VRAM, set a smaller ASR model:

```bash
export MODEL_NAME=openai/whisper-small
```

Optional: restrict visible devices

```bash
export CUDA_VISIBLE_DEVICES=0
```

Start the stack:

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

### Compose Examples

Run all services in ONNX mode on CPU:

```bash
EXECUTION_DEVICE=cpu \
EXECUTION_RUNTIME=onnx \
ASR_EXECUTION_MODE=onnx_baseline \
TRANSLATION_MODEL_ENGINE=onnx_seq2seq \
VAD_USE_ONNX=1 \
VAD_MODEL_FILENAME=onnx/model.onnx \
TTS_MODEL_ENGINE=kokoro_onnx \
TTS_MODEL_FILENAME=onnx/model.onnx \
docker compose -f docker-compose.yml up -d
```

Run all services in non-ONNX mode on CPU:

```bash
EXECUTION_DEVICE=cpu \
EXECUTION_RUNTIME=native \
ASR_EXECUTION_MODE=baseline \
TRANSLATION_MODEL_ENGINE=hf_seq2seq \
VAD_USE_ONNX=0 \
TTS_MODEL_ENGINE=kokoro_hf \
docker compose -f docker-compose.yml up -d
```

Run mixed mode (example: ASR/TTS CUDA + ONNX, Translation/VAD CPU):

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml -f agent-output/validation/onnx-readiness/run-063-live-compose-20260219/compose.onnx.override.yml up -d --build
```

GPU devices are requested via `device_requests` in `docker-compose.gpu.yml` and require the NVIDIA container runtime.

## Image Build Args (GPU wheels)

Use build args to select GPU-enabled packages:

- ASR / Translation / TTS (PyTorch):
  - `TORCH_INDEX_URL` (default `https://download.pytorch.org/whl/cpu`)
  - `TORCH_PACKAGE` (translation-only, default `torch==2.6.0+cpu`)
- VAD (ONNX):
  - `ONNXRUNTIME_PACKAGE` (default `onnxruntime`, use `onnxruntime-gpu` for CUDA)

## GPU Dockerfiles

GPU builds use CUDA runtime base images:

- ASR: `services/asr/Dockerfile.gpu`
- Translation: `services/translation/Dockerfile.gpu`
- TTS: `services/tts/Dockerfile.gpu`
- VAD: `services/vad/Dockerfile.gpu`

Default base image: `nvidia/cuda:12.6.1-cudnn-runtime-ubuntu24.04`.

## Docker Swarm (GPU Reference Posture)

GPU-capable services are constrained to nodes labeled `gpu=true`.

Label GPU nodes:

```bash
docker node update --label-add gpu=true --generic-resource GPU=1 <gpu-node-name>
```

Set execution vars before deploying the stack:

```bash
export EXECUTION_DEVICE=cuda
export EVIDENCE_MODE=true
```

Deploy:

```bash
docker stack deploy -c deploy/swarm-stack.yml speech
```

GPU services in Swarm reserve devices via `deploy.resources.reservations.generic_resources` (kind `GPU`) and are constrained to `node.labels.gpu == true`.

## Evidence Signals (Normal Telemetry)

Each model service emits `execution_telemetry` on startup with:

- `execution_device_requested`
- `execution_device_effective`
- `cuda_available`
- `device_count`
- `device_name`
- `model_id`

Runtime evidence:

- PyTorch services (ASR/Translation/TTS): `attention_backend_effective`
- ONNX VAD: `onnx_provider_effective`

## Rollback (Hotfix)

To force CPU execution:

```bash
export EXECUTION_DEVICE=cpu
export EVIDENCE_MODE=false
export EXECUTION_RUNTIME=native
```
