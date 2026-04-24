---
name: container-best-practices
description: Expert guidance on structuring Dockerfiles, multi-stage builds, security, and Compose. Trigger when working with dockerfile, docker-compose, security, maintainability, or uv.
---

# Docker Container Best Practices

Apply industry-standard best practices for building secure, maintainable, and predictable Docker containers.

## 1. Architectural Structure & Readability

* **Use `.dockerignore`:** Always define a `.dockerignore` file to prevent copying build artifacts, local environments, and sensitive files.
  ```text
  node_modules
  dist
  .git
  .env*
  .DS_Store
  coverage
  __pycache__
  *.pyc
  ```
* **Absolute `WORKDIR`:** Always use absolute paths (e.g., `WORKDIR /app`).
* **COPY vs. ADD:** Prefer `COPY` over `ADD` for predictability. Combine `RUN` commands using `&&` to reduce layer count.

## 2. Security Best Practices

* **Run as Non-Root:** Always create and switch to a non-root user in the final stage.
  ```dockerfile
  RUN addgroup -g 1001 appgroup && adduser -S -u 1001 -G appgroup appuser
  USER appuser
  ```
* **Base Images & Updates:** Pin specific versions (never `latest`). Run security updates (e.g., `apk update && apk upgrade`).
* **Health Checks & Metadata:** Use `HEALTHCHECK` for container readiness and `LABEL` for metadata.

## 3. Multi-Stage Build Architecture

Strictly separate development/build dependencies from your production runtime. 

**Node.js Example:**
```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
USER nodejs
EXPOSE 3000
CMD ["node", "dist/index.js"]
```
*(Use similar multi-stage patterns for Java/Spring Boot and Go as required).*

## 4. Docker Compose for Multi-Container

* Maintain logical networking and use `depends_on` tied to `healthcheck` conditions.
```yaml
services:
  app:
    build:
      context: .
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp
    depends_on:
      db:
        condition: service_healthy
  db:
    image: postgres:15-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
```



