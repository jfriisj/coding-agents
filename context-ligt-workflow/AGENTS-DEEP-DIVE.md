# VS Code Agents - Deep Dive Documentation

> This comprehensive guide covers advanced usage patterns, agent collaboration, native workflow memory integration, document lifecycle tracking, and the design philosophy behind this multi-agent workflow.
>
> **New users**: Start with [USING-AGENTS.md](USING-AGENTS.md) for quick setup.

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Agent Collaboration Patterns](#agent-collaboration-patterns)
3. [The Document-Driven Workflow](#the-document-driven-workflow)
4. [Native Workflow Memory Integration](#native-workflow-memory-integration)
5. [Agent Deep Dives](#agent-deep-dives)
6. [Customization Guide](#customization-guide)
7. [Troubleshooting & FAQ](#troubleshooting--faq)
8. [Agent Orchestration Playbook](#agent-orchestration-playbook)

---

## Design Philosophy

### Why Multiple Specialized Agents?

A single general-purpose AI tries to do everything—plan, code, test, review—often poorly. By splitting responsibilities:

1. **Each agent has clear constraints**: Planner can't write code, Implementer can't redesign.
2. **Quality gates are built in**: Critic reviews before implementation, Security audits before production.
3. **Handoffs create checkpoints**: Work is documented at each stage.
4. **Specialization improves quality**: A security-focused agent catches vulnerabilities a general agent misses.

### Orchestrator Discipline (Non-Negotiable)

`00-Orchestrator` is a delegation-only phase manager.
- It triages, routes, and validates handoffs.
- It does not implement, test, review, or edit artifacts directly.
- If work must happen, Orchestrator dispatches the correct subagent and validates concrete `WF-*` output.

### Native MCP First (Zero Terminal Overhead)

To ensure high reliability, extreme token efficiency, and no annoying manual terminal approvals, this system is strictly designed around **Native MCP Tools**:
* **`filesystem`**: Handles all file reading, writing, and directory creation (e.g., `read_file`, `move_file`).
* **`analyzer`**: Replaces fragile bash scripts for linting and code complexity checks (RUFF, VULTURE).
* **`github`**: Native interactions with PRs and issues.

**Rule**: *Terminal commands and external Python/Bash scripts are strictly forbidden for core workflow operations (like moving files or compiling context outside of designated JIT scripts).*

### The Separation of Concerns (Full Role Matrix)

| Agent | Non-negotiable responsibility |
|---|---|
| **01a-Roadmap** | Own epic/release truth and seed global JIT context pointers |
| **01b-Requirements** | Translate epic into explicit scope/ACs, interview user, and forward JIT pointers |
| **02a-Planner** | Enforce AC list and export exact JIT Context Pointers (no monolithic specs) |
| **02b-Analyst** | Convert unknowns to evidence or explicit uncertainty with validation path |
| **02c-Architect** | Enforce system coherence, diagnosability invariants, and JIT pointer export |
| **02d-Security** | Apply mode-scoped security gate with reproducible findings |
| **02e-Critic** | Block weak plans, missing JIT pointers, and unresolved open-question risk |
| **02f-Designer**| Translate plan into LLD, Mermaid diagrams, and app/core/adapter parity maps |
| **03a-Implementer** | Execute/Read JIT context first, then deliver TDD-backed implementation |
| **03b-TestRunner** | Execute heavy integration/E2E pipelines and gather deterministic terminal evidence logs |
| **03d-ContainerOps** | Validate Docker/Compose/Swarm + observability + Kafka platform readiness before QA |
| **03c-CodeReviewer** | Enforce maintainability/architecture quality gate before QA |
| **04a-QA** | Validate test sufficiency and execution evidence |
| **04b-UAT** | Validate business-value delivery and epic decision |
| **05a-DevOps** | Enforce release gate + user approval before push/release |
| **05b-Retrospective** | Capture systemic process lessons and control gaps |
| **05c-ProcessImprovement**| Convert retrospective signals into instruction updates |

---

## Agent Collaboration Patterns

### Pattern 1: The Planning Pipeline (Phase 01 & 02)

```text
┌─────────────┐    ┌────────────────┐    ┌─────────────┐
│ 01a-Roadmap │───▶│01b-Requirements│───▶│ 02a-Planner │
│  (vision)   │    │  (scope/ACs)   │    │   (plan)    │
└─────────────┘    └────────────────┘    └─────────────┘
                                                │
                                  ┌─────────────┴─────────────┐
                                  ▼                           ▼
                           ┌─────────────┐             ┌────────────┐
                           │ The Review  │──▶(Loop)───▶│ 02e-Critic │
                           │ Triad       │             │  (audit)   │
                           │(02b/02c/02d)│             └────────────┘
                           └─────────────┘                    │
                                                              ▼
                                                       ┌────────────┐
                                                       │02f-Designer│
                                                       │   (LLD)    │
                                                       └────────────┘
```

**When to use**: Starting a new feature from scratch.

### Pattern 2: The Implementation Loop (Phase 03, 04 & 05)

```text
┌───────────────┐    ┌────────────────┐    ┌────────────────┐    ┌────────┐    ┌────────┐    ┌──────────┐
│03a-Implementer│───▶│03d-ContainerOps│───▶│03c-CodeReviewer│───▶│ 04a-QA │───▶│04b-UAT │───▶│05a-DevOps│
│ (w/ 03b tests)│    │  (platform gate)│   │   (quality)    │    │ (test) │    │(value) │    │ (release)│
└───────────────┘    └────────────────┘    └────────────────┘    └────────┘    └────────┘    └──────────┘
       ▲                     │                       │                │
       └─────────────────────┴───────────────────────┴────────────────┘
                                 (fix issues)
```

**When to use**: Plan is approved, coding phase.

### Pattern 3: The Investigation Branch

**When to use**: Hit technical uncertainty during any phase.

1. Implementer or Planner hits technical unknown.
2. Select **02b-Analyst** → investigates → `agent-output/analysis/002-topic-analysis.md`
3. Findings go back to calling agent.
*If RCA is uncertain, Analyst triggers a "Hard Pivot" to system hardening and telemetry tracking via `analysis-methodology` skill.*

---

## The Document-Driven Workflow

### Document Naming Convention

```text
NNN-feature-name-type.md
```

* **NNN**: Sequential number (001, 002, ...) matching the unified `.next-id`
* **feature-name**: Descriptive name (auth-system, api-refactor)
* **type**: Document type (plan, analysis, critique, security, etc.)

### Document Status Tracking

All agents track and update document status fields in the YAML frontmatter. This provides at-a-glance visibility into document state:

| Status | Meaning |
| --- | --- |
| `Draft` | Initial creation, not yet reviewed |
| `In Progress` | Actively being worked on |
| `Pending Review` | Ready for next agent's review |
| `Approved` | Passed review gate |
| `Blocked` | Cannot proceed until issues resolved |
| `Committed` | Changes committed to git (awaiting release) |
| `Released` | Successfully pushed/published to production |

### Document Lifecycle and Closure

Completed documents move to `closed/` subfolders to keep active work visible. **Agents MUST use the native `filesystem` MCP tools (`move_file`) for this.**

```text
agent-output/
├── planning/
│   ├── 085-active-feature.md      ← currently active
│   └── closed/
│       ├── 080-completed.md       ← archived after commit
```

**Key concepts:**
* **Unified numbering**: All documents in a work chain share the same ID (analysis 080 → plan 080 → qa 080) via `agent-output/.next-id`.
* **Terminal statuses**: `Committed`, `Released`, `Abandoned`, `Deferred` trigger native closure moves.

### Open Question Gate
Plans may contain `OPEN QUESTION` items. 
* Implementer scans for unresolved questions.
* If found, Implementer **halts and strongly recommends resolution**.
* Requires explicit user acknowledgment to proceed.

---

## Native Workflow Memory Integration

### Replacing External Memory Servers
Instead of relying on external, opaque Memory MCP servers or heavy graph databases that dump massive JSON blobs into the context window, this workflow uses **Native Workflow Memory** via clean, deterministic markdown files.

**Why Native Memory is superior**:
* **Token Efficiency**: Agents load tiny "summary nodes" (`WF-*`) instead of full document histories.
* **JIT Context**: Downstream agents compile exactly what they need based on specific pointers.
* **No Dependencies**: Works out of the box with standard VS Code filesystem tools.

### The "Summary Node" Pattern (The 10-Line Rule)
Agents create lightweight `WF-<concrete-id>` (Workflow) nodes in `agent-output/workflows/`. These nodes act as **pointers and semantic edges**.

*Example of a Workflow Node (`workflows/WF-P002-Auth.md`):*

```markdown
---
type: Plan
parent: "workflows/WF-E1.2.md"
---
### Summary
* Decided to use JWT tokens over session cookies.
* Defined 4 implementation milestones.

### Required Context Pointers
- [architecture.md#Authentication]
- [security-policy.md^jwt-rules]

## Artifacts
- [Implementation Doc](agent-output/planning/002-auth-plan.md)
```

### JIT Context Protection (Baseline vs. Append)
To prevent agents from hallucinating or overwriting global specifications:

1. **Planners/Generators** map exact headers via `### Required Context Pointers`.
2. **Consumers** (Implementers) run `compile_context.sh` which generates `agent-output/.context-baseline.md`.
3. **The Override Guard**: `.context-baseline.md` is STRICTLY READ-ONLY. 
4. **The Append Log**: If an Implementer discovers new rules during execution, they write to `agent-output/.context-append.md` instead.

### Handoff Protocol
When handing off between agents, we rely on a strict final chat message:
> "Handoff Ready. Parent Node context for the next agent is `agent-output/workflows/WF-...md`."

---

## Agent Deep Dives

*(See Full Role Matrix in Section 1 for quick reference)*

### Phase 01: Strategy & Requirements
* **01a-Roadmap**: Owns the Master Product Objective. Defines WHAT and WHY. Seeds global JIT context pointers into Epic nodes.
* **01b-Requirements**: The Product Owner. Translates epics into explicit scope and BDD/Gherkin Acceptance Criteria. Interviews user for edge cases.

### Phase 02: Planning & Design
* **02a-Planner**: Transforms ACs into implementation-ready milestones. Generates the exact JIT Context Pointers for downstream. Never writes code.
* **02b-Analyst**: Investigates technical unknowns. Uses hard-pivot triggers if RCA is unprovable.
* **02c-Architect**: The design authority. Enforces "Den Gyldne Rengøringsregel" (diagnosability invariants).
* **02d-Security**: Applies a strict 5-phase security framework (Architecture, Code, Dependencies, Infra, Compliance).
* **02e-Critic**: The program manager. Rejects weak plans, missing JIT pointers, or unresolved open questions.
* **02f-Designer**: Translates approved plans into Low-Level Design (LLD), component maps (`app/core/adapters`), and Mermaid diagrams.

### Phase 03: Build & Execute
* **03a-Implementer**: The execution engine. Reads JIT context FIRST. Enforces the TDD Gate (Test Written First -> Failure Verified -> Implement).
* **03b-TestRunner**: Subagent for heavy lifting. Orchestrates Docker, runs E2E pipelines, and hunts down backend stack traces to return to the Implementer.
* **03d-ContainerOps**: Container platform gate. Stabilizes Docker/Compose/Swarm runtime and verifies observability/Kafka readiness before QA.
* **03c-CodeReviewer**: Quality gate. Checks architecture alignment, SOLID principles, and code smells BEFORE QA wastes time testing.

### Phase 04: Validation
* **04a-QA**: Validates test sufficiency. Refuses to pass undocumented testing black-holes.
* **04b-UAT**: Validates business-value delivery against the original 01a/01b vision.

### Phase 05: Release & Ops
* **05a-DevOps**: Enforces the release gate. Prepares packages. Requires explicit user approval to push.
* **05b-Retrospective**: Analyzes the workflow. Captures process gaps and systemic lessons.
* **05c-ProcessImprovement**: The meta-agent. Converts retrospective signals into actual updates to the `.agent.md` instructions.

---

## Skills System

Agents leverage **Skills**—modular, reusable instruction sets that load on-demand.

### Available Skills

| Skill | Purpose |
| --- | --- |
| `workflow-memory` | Native relational memory graph using standard Markdown files and JIT context. |
| `analysis-methodology` | Investigation techniques (Hard pivot triggers, confidence levels). |
| `architecture-patterns` | ADR templates, embedded Mermaid diagram templates. |
| `code-review-checklist` | Technical checks and severity definitions. |
| `cross-repo-contract` | API sync rules via `filesystem` tools. |
| `document-lifecycle` | Numbering, closure procedures, status updates. |
| `engineering-standards` | SOLID, DRY, YAGNI, embedded Refactoring Catalog. |
| `release-procedures` | Two-stage workflow, semver validation. |
| `security-patterns` | OWASP Top 10, language-specific vulnerabilities. |
| `testing-patterns` | TDD workflows, test pyramid, anti-patterns. |

> [!NOTE]
> Skills are located in `.github/skills/` (Insiders/Standard) or `.claude/skills/` (Legacy Stable).

---

## Customization Guide

### Adding New Agents

1. Create `your-agent.agent.md` in `.github/agents/`
2. Follow the frontmatter format (name, tools, handoffs).
3. Include the `workflow-memory` and `document-lifecycle` mandatory blocks.

### Modifying Existing Agents

**Safe to modify**:
* `description`: Update for clarity
* `model`: Change to preferred model
* `handoffs`: Add/remove handoff targets

**Generally don't modify**:
* Core separation of concerns (e.g., making Planner write code)
* Native File memory constraints

---

## Troubleshooting & FAQ

### Agent Issues
**Q: Agent not appearing in Copilot**
* Check file location: `.github/agents/` for workspace. Verify extension is `.agent.md`. Reload VS Code.

**Q: Agent ignores constraints**
* Re-invoke with explicit constraint reminder. Models sometimes drift; be explicit.

**Q: Agent tries to do another agent's job**
* Use explicit handoff: "Hand off to [Agent] for [task]".

### Workflow Issues
**Q: Plans have too much implementation detail**
* Remind 02a-Planner of constraint: "WHAT and WHY, not HOW".

**Q: Security review is superficial**
* Request specific phases: "Conduct Phase 2 (Code Security Review)".

**Q: JIT Context is missing / Implementer is hallucinating**
* Ensure Planner properly appended `### Required Context Pointers` to the WF node, and ensure Implementer actually ran the `compile_context.sh` script via terminal before coding.

---

## Agent Orchestration Playbook

> This section documents when and how to use local, background, and subagent execution patterns.

### Execution Modes Overview

| Mode | When to Use | Key Characteristics |
| --- | --- | --- |
| **Local Interactive** | Planning, strategy, review, handoffs | User in the loop, real-time collaboration |
| **Background Agent** | Long-running implementation, parallel tasks | Git worktree isolation, hands-off execution |
| **Subagent** | Focused subtask delegation | Context-isolated, returns findings to caller |

### Subagent Usage Patterns

**Definition**: A subagent is invoked by another agent (the "caller") using the `agent` tool to perform a focused, context-isolated task.

**Subagent-Eligible Agents** (may be auto-invoked):
* **02b-Analyst**: Clarify technical questions mid-planning or mid-implementation.
* **02c-Architect**: Verify 02f-Designer's Mermaid diagrams.
* **03b-TestRunner**: Offload heavy E2E pipelines from Implementer.
* **03d-ContainerOps**: Enforce container/platform readiness gate (Docker/Compose/Swarm, Kafka, observability) before QA.
* **02d-Security**: Targeted security review of specific code.

### Orchestration Quick Reference

```text
┌─────────────────────────────────────────────────────────────────────┐
│                    AGENT ORCHESTRATION FLOW                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  PHASE 1 & 2: LOCAL INTERACTIVE (Strategy & Planning)               │
│  ┌───┐   ┌───┐   ┌───┐   ┌─────────────┐   ┌───┐   ┌───┐            │
│  │01a│──▶│01b│──▶│02a│──▶│02b/02c/02d  │──▶│02e│──▶│02f│            │
│  └───┘   └───┘   └───┘   └─────────────┘   └───┘   └───┘            │
│                                                                     │
│  PHASE 3: BACKGROUND (Execution) ─── Git Worktree Isolation         │
│  ┌─────────────────┐  ◀───▶  ┌────────────────┐  ◀───▶  ┌────────────────┐ │
│  │ 03a-Implementer │         │ 03b-TestRunner │         │03d-ContainerOps│ │
│  └─────────────────┘         └────────────────┘         └────────────────┘ │
│                                                                     │
│  PHASE 4 & 5: LOCAL INTERACTIVE (Validation & Release)              │
│  ┌─────────┐   ┌────────┐   ┌────────┐   ┌─────────┐                │
│  │ 04a-Rev │──▶│ 04a-QA │──▶│04b-UAT │──▶│05a-DevOp│                │
│  └─────────┘   └────────┘   └────────┘   └─────────┘                │
│                                               ▲                     │
│                                               │                     │
│                                   [USER APPROVAL REQUIRED]          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## License

MIT License - see [LICENSE](https://www.google.com/search?q=LICENSE)