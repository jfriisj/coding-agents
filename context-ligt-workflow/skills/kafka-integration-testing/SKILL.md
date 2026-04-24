---
name: kafka-integration-testing
description: Mandatory protocols for writing and executing integration/E2E tests for event-driven Kafka microservices. Defines the 3-stage testing pyramid.
argument-hint: Use this skill when designing or writing integration tests, E2E tests, or testing Kafka pub/sub consumers and producers.
metadata:
  version: 1.0.0
---

# Kafka Integration Testing Protocols

Event-driven microservices cannot be tested like synchronous REST APIs. You must employ a strict 3-stage validation strategy using real Kafka brokers in a Docker environment.

## 1. The 3-Stage Testing Pyramid

When tasked with creating integration tests for the Kafka pipeline, you MUST implement tests in this exact order. If Stage 1 fails, do not proceed to Stage 2.

### Stage 1: Isolated Component Testing (Single Service)
* **Goal:** Verify that a single service (e.g., `asr-service`) correctly consumes its input topic, processes data, and produces to its output topic.
* **Method:** 1. Spin up Kafka, Zookeeper/KRaft, and the SINGLE target service in Docker.
  2. The test script acts as the Producer (sending a mock event to the input topic).
  3. The test script acts as the Consumer (listening to the output topic).
  4. Assert the output payload matches expectations.

### Stage 2: Orchestration Testing (Routing Validation)
* **Goal:** Verify that the Orchestrator correctly routes messages between services based on the `correlation_id` and capability snapshots.
* **Method:**
  1. Spin up Kafka, the Orchestrator, and mock lightweight consumers representing the downstream services.
  2. Send an Ingress event.
  3. Validate that the Orchestrator emits the correct command event to the correct stage topic.

### Stage 3: Full Pipeline E2E
* **Goal:** Validate the entire system end-to-end.
* **Method:**
  1. Spin up the ENTIRE `docker-compose.yml` stack.
  2. Send a real payload (e.g., `AudioInputEvent` + `OrchestrationCommandEvent`) to the edge topics.
  3. Wait for the final `AudioSynthesisEvent` (TTS) to arrive.

## 2. Mandatory Kafka Testing Mechanics

When writing the Python/TS test scripts, you MUST implement these mechanical safety guards:

* **Unique Correlation IDs:** Every test run MUST generate a unique `correlation_id` (e.g., `uuid4()`). The test consumer must ignore any messages on the topic that do not match this ID to prevent test cross-contamination.
* **Deterministic Topic Priming:** Before producing a test message, the test script MUST connect its consumer to the output topic and wait for partition assignment. *Never produce a message before the consumer is actively listening.*
* **Strict Timeouts:** Use `time.time() + timeout_seconds` loops when polling for messages. 

## 3. The "Black Hole" Debugging Protocol

If a test times out waiting for a Kafka message, it means a microservice crashed silently or dropped the message. 

* **For the Implementer (Writing the test):** Catch `TimeoutError` exceptions. In the `except` block, print explicit instructions to `stdout` containing the exact `docker logs` command needed to find the crash, including the `correlation_id`.
* **For the TestRunner (Executing the test):** If you see a `TimeoutError`, you MUST execute the printed `docker logs` command on the suspected failing microservice. You MUST return those container logs to the Implementer; do not just report "The test timed out."

## 4. Docker Environment Lifecycle

* **Wait-For-It:** Kafka takes time to boot. Test scripts MUST implement a retry mechanism to ping the Kafka broker (e.g., fetching cluster metadata) before attempting to create topics or send messages.
* **Clean Slate:** The test environment must be torn down completely (`docker compose down -v`) between test suite runs to clear Kafka volume states.