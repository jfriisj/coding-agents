---
name: container-testing-protocols
description: Mandatory skill for managing Docker/Swarm test environments, orchestrating microservices for E2E tests, and hunting distributed logs.
---

# Docker Testing Protocols

## Hunting Event-Driven Timeouts (Microservices)
If an integration or E2E test fails with a `TimeoutError` while waiting for a Kafka event (e.g., ASR, Translation, TTS), the failure is NOT in the test script itself. A backend microservice crashed or dropped the message.

**When you see a TimeoutError in the test output:**
1. **Extract the Correlation ID**: Look for the `correlation_id` printed in the test output or error message.
2. **Grep the Backend Logs**: You MUST run `docker compose logs --tail=200 | grep -C 5 "<correlation_id>"` (or use the exact command printed by the test script) to find the exact container and stack trace that caused the pipeline to stall.
3. **Return the Root Cause**: Do not just tell the Implementer "the test timed out." Return the results of the `grep` command so the Implementer can see the actual Python exception from the backend service.

## Hunting Event-Driven Timeouts (DLQ / Error Topic)
If the repository or smoke test exposes a known Dead Letter Queue or system-error topic, listen to it in parallel with the success topic.
1. Fail immediately when a matching `correlation_id` appears on the error topic.
2. Surface the backend `source_service` and `error_message` in the test output.
3. If the error topic is unavailable or undocumented, fall back to the timeout debug command above and use the backend logs to identify the root cause.

## 1. Environment Lifecycle (The Golden Rule)
Always ensure a clean slate. 
- **Before running tests**: Always run `docker compose down -v` (or your equivalent teardown script) to clear out orphaned containers and volumes.
- **After running tests**: Always tear down the environment to free up ports and memory.

## 2. Running Microservice Test Suites
When spinning up a test suite, prefer commands that automatically exit when the tests finish, such as:
`docker compose -f docker-compose.test.yml up --build --abort-on-container-exit`

## 3. Log Hunting (Finding the Root Cause)
If an integration or E2E test fails, the test runner output will often only show a generic HTTP error (e.g., 500, 502, 504). **You must find the actual error in the microservice containers.**

**The Log Hunting Process:**
1. Check running/exited containers: `docker ps -a`
2. Identify the service that likely caused the failure (e.g., if the test failed on login, look at the `auth` container).
3. Extract the last 100 lines of logs for that specific service: `docker logs --tail 100 <container_name_or_id>`
4. If multiple services interact, extract logs from the API Gateway/BFF and the downstream service.

## 4. Handoff Formatting
When sending a failure back to the Implementer, you MUST include:
1. The test runner failure (e.g., Jest/Cypress/Pytest output).
2. The exact Docker logs from the failing microservice container showing the stack trace or crash.