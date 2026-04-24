---
name: container-performance-optimization
description: Advanced techniques for minimizing Docker image sizes, maximizing build-time cache with BuildKit, tuning runtime resources, and using uv.
---
# Docker Performance Optimization

Advanced techniques for minimizing sizes, maximizing build-time cache efficiency, and tuning runtime resource consumption.

## 1. Layer Caching & Build Speed

* **Strategic Layer Ordering:** Place instructions from *least frequently changing* (OS dependencies) to *most frequently changing* (source code) to maximize layer cache hits.
  ```dockerfile
  # ✅ Good caching - dependencies cached separately
  FROM python:3.11-slim
  WORKDIR /app
  COPY requirements.txt .
  RUN pip install --no-cache-dir -r requirements.txt
  COPY . .
  ```
* **BuildKit Cache Mounts:** Persist package caches between builds without saving them to the final image.

## 2. Python & `uv` Optimization

Using `uv` reduces dependency resolution time significantly. Integrate `uv` with BuildKit cache mounts.
```dockerfile
# syntax=docker/dockerfile:1.4
FROM python:3.11-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
WORKDIR /app
COPY requirements.txt .

# Mount uv's cache directory so subsequent builds skip downloads
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system -r requirements.txt

# Compile bytecode for faster startup
ENV UV_COMPILE_BYTECODE=1
```

## 3. Image Size Reduction

* **Minimal Base Images:** Default to the smallest viable OS. 
  * `scratch` (0MB): Static Go/Rust binaries.
  * `alpine` (~5MB): General purpose minimal environments.
  * `slim` (~80-150MB): When standard `apt` packages or glibc are required (e.g., Python).
* **Aggressive Cache Purging:** Clean package manager caches within the *same layer* they are used.

## 4. Runtime Performance Tuning

* **Resource Limits:** Always define CPU and memory limits in Compose or deployment manifests to prevent starvation.
* **Read-Only Filesystems:** Where possible, run containers with `--read-only`, mounting `tmpfs` only for required temp directories.

---
