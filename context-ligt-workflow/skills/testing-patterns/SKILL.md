---
name: testing-patterns
description: TDD workflow, test pyramid, coverage, mocking anti-patterns, and Native Workflow Memory integration. Uses Progressive Disclosure to lazy-load language-specific framework syntax. Use this skill when designing test strategies, writing tests, or reviewing QA artifacts.
---

# Testing Patterns & Methodology

Systematic approach to effective testing. Use this skill when writing tests, designing test strategies, reviewing coverage, or evaluating pull requests.

## 1. Document & Workflow Sync (Testing)

Every test strategy or QA review must be synchronized across two structural layers:
1. **Execution Artifact (`agent-output/qa/`)**: Save the detailed test strategy, coverage reports, or QA gaps here.
2. **Workflow Graph (`workflows/`)**: Create or update the `WF-*` node linking your QA verdict to the Implementation using standard native markdown links.

---

## 2. Tooling Contract (Standard Commands)

**CRITICAL RULE**: You MUST use standard framework commands and native file tools for all testing operations.

* To run tests: Execute standard framework commands (`npm test`, `pytest`, `go test ./...`) via the terminal or task runner.
* To check coverage: Use the native framework tools (e.g., `jest --coverage`, `pytest --cov`).
* To validate missing tests: Use the native `search` tool to cross-reference source files with their `*.test.ts` or `test_*.py` counterparts.

---

## 3. Test-Driven Development (TDD)

**TDD is MANDATORY for new feature code.** Write tests before implementation.

### The TDD Cycle
1. **RED**: Write a failing test.
2. **GREEN**: Write the minimal code to pass.
3. **REFACTOR**: Clean up, keeping tests green.

**If an implementation arrives without tests:**
1. Reject it with a "TDD Required" verdict.
2. Specify which tests should exist.
3. Send it back to the Implementer.

---

## 4. The Iron Laws of Mocking & Anti-Patterns

Mocks are tools to isolate, not things to test.

**The Iron Laws:**
1. **NEVER test mock behavior:** Use mocks to isolate your unit from dependencies, but assert on the unit's behavior.
2. **NEVER mock without understanding:** Know the side effects before isolating.
3. **NEVER create incomplete mocks:** Mirror real API structures completely.

### Anti-Pattern 1: Testing Mock Behavior
* **Violation**: Asserting that a mock was called or rendered (`expect(getByTestId('mock')).toBeInTheDocument()`) instead of checking the component's actual output.
* **Fix**: Test real component behavior. Only mock to isolate external boundaries (like network or DB).

### Anti-Pattern 2: Test-Only Methods in Production
* **Violation**: Adding a `destroy()` or `reset()` method to a production class just so tests can clean up.
* **Fix**: Keep production classes pure. Put test-cleanup logic in test utilities.

### Anti-Pattern 3: Mocking Without Understanding & Incomplete Mocks
* **Violation**: Over-mocking to "be safe" or returning only partial objects (e.g., just `{ id, name }`) when the real API returns 20 fields.
* **Fix**: Mock at the correct, lowest level. Mirror the real API completely. Downstream code will fail silently if you hide structural assumptions.

---

## 5. Test Frameworks (Progressive Disclosure)

When you need specific syntax or setup boilerplate for a testing framework, use `read/readFile` to lazy-load the reference guide:

> **Read**: `.github/skills/testing-patterns/references/testing-frameworks.md`

This reference includes detailed syntax for:
* **JavaScript/TypeScript** (Jest, Vitest)
* **Python** (pytest)
* **Java** (JUnit 5, Mockito)
* **Go** (testing package)
* **VS Code Extensions**

---

## 6. Coverage & Edge Case Strategy

**What to Cover (Priority Order)**:
1. Business logic (revenue-impacting calculations)
2. Security boundaries (auth, access control)
3. Error paths (exceptions, network failures)
4. Integration points (API contracts)

**Edge Case Generation Matrix**:
* **Numbers**: `0`, `-1`, `MAX_INT`, floating point precision.
* **Strings**: `""` (empty), very long strings, special chars/unicode, whitespace only.
* **Collections**: Empty, single item, 1000+ items, null/undefined elements.
* **Dates**: Leap years, timezone boundaries, past/future extremes.

---

## 7. Event-Driven Testing Patterns (Microservices)

When writing smoke, integration, or E2E tests for asynchronous, event-driven pipelines (e.g., Kafka), you must design the tests to be observable when they fail.

**The "Black Hole" Anti-Pattern:**
* **Violation:** A test publishes a message and waits for a success event. If a downstream service crashes, the test waits blindly until a `TimeoutError` occurs, providing no clue as to *why* it failed.

**The Proactive Fix (Required):**
1. **Listen to the Error Topic (DLQ):** Your test MUST consume from the relevant Dead Letter Queue or System Error topic simultaneously. If an error event arrives with the matching `correlation_id`, the test should fail immediately and print the backend error message.
2. **Provide Agent Instructions:** If a `TimeoutError` does occur, catch the exception and print explicit terminal instructions (e.g., `docker logs ... | grep <correlation_id>`) to the standard output so the TestRunner agent knows exactly how to find the root cause.

---

## 8. Document & Workflow Sync (The Handoff Protocol)

Before concluding your turn as QA or Implementer, you must align the workflow using **standard workspace file tools**:

1. **The Artifact (`agent-output/`)**: 
   * Save test results or strategies using `edit/editFiles` or `edit/createFile`. 
   * If a QA document reaches a terminal state, use the close script via terminal: `sh .github/scripts/close_document.sh <path-to-your-file.md> "Approved"`.

2. **The Memory (Workflow Graph)**: 
   * Use native file tools to create or update your `WF-<concrete-id>-<slug>.md` node. 
   * Strictly follow the 10-Line Rule (frontmatter `type: QA` or `Implementation`, `parent`, max 3-bullet summary, and standard Markdown Artifact links).

**Final Chat Message**:
Always conclude your turn with:
> *"Handoff Ready. Parent Node context for the next agent is: agent-output/workflows/WF-...md"*