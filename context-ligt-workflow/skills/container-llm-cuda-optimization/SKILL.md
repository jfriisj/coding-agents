---
name: container-llm-cuda-optimization
description: Expert guidance for building highly optimized, GPU-accelerated Docker containers for LLMs and CUDA. Trigger when working with cuda, llm, gpu, pytorch, nvidia, tensorrt, vllm, flash-attn, or weights.
---

# Docker Optimization for LLMs & CUDA

Building containers for Large Language Models (LLMs) requires specific strategies to prevent image sizes from exploding (from 15GB to 40+GB) and to ensure optimal GPU utilization. 

## 1. Nvidia Base Image Strategy (The Devel vs. Runtime Rule)

Nvidia provides three tiers of CUDA images. Using the wrong one in production is the #1 cause of massive image bloat.

* **`base`:** Includes only the CUDA runtime (no libraries). Extremely small, but rarely enough for PyTorch.
* **`runtime`:** Includes CUDA math libraries (cuDNN, cuBLAS). **This is your production target.**
* **`devel`:** Includes the full CUDA toolkit, nvcc compiler, and headers. **Never use this in production.**

**Best Practice:** Use a multi-stage build where you compile custom CUDA kernels (like `flash-attn` or `vLLM` components) in a `devel` stage, and copy the compiled wheels to a `runtime` stage.

## 2. Multi-Stage CUDA Architecture

```dockerfile
# Stage 1: Build Environment (Massive image, discarded after build)
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04 AS builder

# Install build tools and uv
RUN apt-get update && apt-get install -y --no-install-recommends git build-essential
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /build
ENV UV_COMPILE_BYTECODE=1

# Compile complex CUDA extensions (e.g., flash-attention)
# Using BuildKit cache mounts is critical here to avoid re-downloading PyTorch
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system torch==2.1.2+cu121 --index-url [https://download.pytorch.org/whl/cu121](https://download.pytorch.org/whl/cu121) && \
    uv pip install --system flash-attn --no-build-isolation


# Stage 2: Production Runtime (Lean image)
FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04 AS production

# Install Python and uv
RUN apt-get update && apt-get install -y --no-install-recommends python3.10 python3.10-venv && \
    rm -rf /var/lib/apt/lists/*
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Copy compiled libraries from builder
COPY --from=builder /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages

# Copy application code
COPY . .

# Set NVIDIA runtime variables
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

CMD ["python3.10", "inference_server.py"]
```

## 3. Dependency Management (PyTorch & `uv`)

PyTorch binaries are massive (~2.5GB). If you are not careful, package managers will download the CPU version alongside the GPU version, doubling your size.

* **Explicit Index URLs:** Always explicitly define the PyTorch index URL in your `requirements.txt` or `pyproject.toml` so `uv` only fetches the exact CUDA flavor you need.
    ```text
    --extra-index-url [https://download.pytorch.org/whl/cu121](https://download.pytorch.org/whl/cu121)
    torch==2.1.2+cu121
    torchaudio==2.1.2+cu121
    torchvision==0.16.2+cu121
    ```
* **Strip Unnecessary Files:** If you are strictly doing inference, you can strip out test binaries and development headers from the PyTorch installation in the final image to save hundreds of megabytes.

## 4. Handling Model Weights (The 20GB Problem)

**Never `COPY` massive model weights directly into the Docker image** if it can be avoided. Baking a 40GB model into an image makes pushing, pulling, and caching impossible.

* **Best Practice - Volume Mounts:** Mount the weights at runtime via Docker Compose or Kubernetes PVCs.
    ```yaml
    services:
      llm-inference:
        image: my-llm-app:latest
        deploy:
          resources:
            reservations:
              devices:
                - driver: nvidia
                  count: 1
                  capabilities: [gpu]
        volumes:
          - ./model-weights:/app/models
    ```
* **Alternative - Dynamic Download:** Use `huggingface-cli` with `HF_HUB_ENABLE_HF_TRANSFER=1` in an init-container or at container startup to pull weights to a shared volume quickly.