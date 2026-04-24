---
ID: workflow-terminology
Type: Reference
Status: Active
---

# Workflow Terminology & Escalation Framework

This document defines the standard terminology and escalation paths used across all automated agents in the repository.

## 1. Escalation Framework

When an agent encounters a blocker, it must categorize it into one of these four tiers and take the prescribed action:

| Tier | Timeframe | Definition | Required Action |
|---|---|---|---|
| **IMMEDIATE** | < 1h | Plan strictly conflicts with architectural constraints, or a required tool/file is missing. | **Halt.** Escalate directly to the Planner or Human user. Do not proceed. |
| **SAME-DAY** | < 4h | Code-level technical unknowns, undocumented APIs, or unexpected test failures. | **Subagent Loop.** Invoke `02b-Analyst` or `03b-TestRunner` to investigate. Proceed once resolved. |
| **PLAN-LEVEL** | N/A | The fundamental logic of the plan is flawed or impossible to implement given current system constraints. | **Reject.** Return the artifact to `02a-Planner` for a complete rewrite. |
| **PATTERN** | N/A | The same error or Critic rejection has happened 3 or more times in a row. | **Halt.** Escalate to the Human user to break the AI loop. |

## 2. Core Concepts

* **JIT Context (Just-In-Time Context):** A compiled `.context-baseline.md` file created dynamically for an agent. Prevents context window pollution by ensuring downstream agents only read the specific architectural rules relevant to their current task, rather than reading massive global specification files.
* **TDD Gate:** The non-negotiable requirement for `03a-Implementer`. The agent must write a test, prove that it fails for the correct reason (ModuleNotFoundError or AssertionError), and output that failure log *before* writing the implementation code.
* **The Review Triad:** The automated orchestration loop where `02a-Planner` sequentially invokes the `02b-Analyst`, `02c-Architect`, and `02d-Security` subagents to vet a plan before handing it to `02e-Critic`.
* **10-Line Rule:** Native `WF-*.md` workflow nodes must remain incredibly concise. They should contain frontmatter, a brief summary (under 10 lines), and standard markdown links to the heavy artifacts in `agent-output/*`.
* **The "Black Hole" Anti-Pattern:** A testing failure where a microservice crashes asynchronously (e.g., in Kafka), but the test simply waits until a generic `TimeoutError` occurs, providing no logs or stack traces.

## 3. Node Types (Workflow Graph)

* **Hub Nodes:** High-level strategic nodes (e.g., `Epic`). Created by `01a-Roadmap`. Parent is always `"none"`.
* **Child Nodes:** Execution-level nodes (e.g., `Plan`, `Implementation`). They must have an Upward Edge (defined in the `parent:` frontmatter field) linking to their parent Hub node using standard file paths.
* **Dependency Nodes:** Vetting nodes (e.g., `Analysis`, `Security`, `CodeReview`). They link laterally or upward to the active Plan or Implementation they are reviewing via standard markdown links.
