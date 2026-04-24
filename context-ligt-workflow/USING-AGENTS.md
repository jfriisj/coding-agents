# Using the Agents

This file contains a high-level overview of these agents and how to get started using them quickly. However, you may find you want or need more guidance. In that case, see the AGENTS-DEEP-DIVE.md file.

## Overview

This repo defines a set of `.agent.md` files that configure specialized AI personas ("agents") for a structured software delivery workflow. Each agent focuses on a specific phase or concern (planning, implementation, QA, UAT, DevOps, etc.), with clear responsibilities, constraints, and handoffs.

A typical high-level workflow looks like:

01a-Roadmap → 01b-Requirements → 02a-Planner → (02b-Analyst, 02c-Architect, 02d-Security, 02e-Critic, 02f-Designer) → 03a-Implementer → 03b-TestRunner → 03d-ContainerOps → 03c-CodeReviewer → 04a-QA → 04b-UAT → 05a-DevOps → 05b-Retrospective → 05c-ProcessImprovement

Orchestrator policy: `00-Orchestrator` is delegation-only. It triages, routes, and validates handoffs, but does not perform implementation, test execution, code review, QA, UAT, release operations, or artifact authoring itself.

**All agents use Native Workflow Memory** via the `workflow-memory` skill to provide durable cross-session continuity. Agents function without it, but handoffs and traceability are strongest when WF-node updates are maintained.

### MCP Tools (filesystem/github/analyzer)

This repo is designed to be used with MCP servers configured in `.vscode/mcp.json`. In VS Code, the MCP server name becomes the tool prefix:
- `filesystem` → `filesystem_*`
- `github` → `github_*`
- `analyzer` → `analyzer_*`

If you customize agents or rename MCP servers, make sure the agent `tools:` allowlist includes the corresponding `*/` namespace.

### Strict Bootstrap (Required)

When copying these agents to a new project, run:

```bash
sh .github/scripts/scaffold_required_files.sh --create-missing
sh .github/scripts/check_strict_governance.sh
sh .github/scripts/check_workflow_contract.sh
sh .github/scripts/check_skill_gate_coverage.sh
````

This guarantees required governance files are present (including non-`.github` bootstrap files such as `.vscode/mcp.json` and `agent-output/.next-id`).

## Where to Put These Files

There are two simple ways to make these agents available to VS Code:

1.  **Per-workspace (recommended for a single project)** Place the `.agent.md` files under `.github/agents/` in your repository. They will only apply to that workspace.

2.  **User-level (available in every workspace)** Place the `.agent.md` files in your [VS Code profile folder](https://code.visualstudio.com/docs/configure/profiles). Paths by OS:

      - **Linux**: `~/.config/Code/User/`
      - **macOS**: `~/Library/Application Support/Code/User/`
      - **Windows**: `%APPDATA%\Code\User\`

> [\!TIP]
> The easiest way to create a user-level agent is via the Command Palette: **Chat: New Custom Agent** → select **User profile**. VS Code will place it in the correct location automatically.

In this repo, the source copies live under `.github/agents/`; you can copy or sync from there into other workspaces as needed.

For more guidance on GitHub Copilot agents in VS Code, see the official documentation: https://code.visualstudio.com/docs/copilot/customization/custom-agents

## Using with GitHub Copilot CLI

These agents were originally written for GitHub Copilot in VS Code, but you can also use them with the GitHub Copilot CLI.

  - Place your `.agent.md` files under `.github/agents/` in each repository where you run the CLI.
  - Then invoke an agent with a command like:

<!-- end list -->

```bash
copilot --agent 02a-Planner --prompt "Create a plan for adding user authentication"
```

### Known limitation (user-level agents)

The Copilot CLI has a known upstream bug ([github/copilot-cli\#452](https://github.com/github/copilot-cli/issues/452)) where **user-level agents in `~/.copilot/agents/` are not loaded**, even though they are documented. This behavior and workaround were originally reported and documented by @rjmurillo.

**Workaround:**

  - Use per-repository agents under `.github/agents/` instead of relying on `~/.copilot/agents/`.
  - If you prefer a single source of truth, you can keep your agents in one folder and copy or symlink them into each repo’s `.github/agents/` directory.

Once the upstream bug is fixed, this section can be updated to reflect the restored user-level behavior.

## Customizing Agents

Each `.agent.md` file defines:

  - A **description** and **purpose**
  - Allowed **tools** (editing files, running tests, using GitHub, etc.)
  - **Handoffs** to other agents
  - Detailed **responsibilities** and **constraints**

To customize:

  - Edit the relevant `.agent.md` file to adjust:
      - Description and Purpose
      - Allowed tools
      - Handoff targets and prompts
  - Keep responsibilities and constraints intact unless you intentionally want to change your development process (e.g., Planner must not edit code, QA owns test strategy docs, etc.).

Custom agents give you:

  - **Separation of concerns**: planning vs coding vs QA vs UAT vs DevOps
  - **Repeatable workflow**: each phase of work is clearly owned by one agent
  - **Safety and clarity**: it's explicit who may edit what, and when

-----

## Skills

Agents can load **Skills**—modular, reusable instruction sets that provide specialized knowledge on-demand. Skills are stored in the `.github/skills/` directory.

### Available Skills

| Skill | Purpose |
|-------|---------|  
| `workflow-memory` | Native relational memory graph, JIT context, and artifact pointers |
| `analysis-methodology` | Confidence levels, gap tracking, investigation techniques |
| `architecture-patterns` | ADR templates, patterns, anti-pattern detection |
| `code-review-checklist` | Pre/post-implementation review criteria |
| `code-review-standards` | Code review checklist, severity definitions, document templates |
| `cross-repo-contract` | Multi-repo API type safety and contract coordination |
| `document-lifecycle` | Unified numbering, automated closure, orphan detection |
| `engineering-standards` | SOLID, DRY, YAGNI, KISS with detection patterns |
| `release-procedures` | Two-stage release workflow, semver, platform constraints |
| `security-patterns` | OWASP Top 10, language-specific vulnerabilities |
| `testing-patterns` | TDD workflow, test pyramid, coverage strategies |

### Skill Placement

Skills are placed in different directories depending on your VS Code version:

| Version | Location |
|---------|----------|
| **VS Code Stable (1.107.1)** | `.claude/skills/` |
| **VS Code Insiders** | `.github/skills/` |

> [\!NOTE]
> These locations are changing with upcoming VS Code releases. The `.github/skills/` location is becoming the standard. Check the [VS Code Agent Skills documentation](https://code.visualstudio.com/docs/copilot/customization/agent-skills) for the latest guidance.

-----

## Document Lifecycle Setup

Agents use a **unified numbering system** to track work across the entire pipeline. All documents in a work chain share the same ID for easy traceability.

### The `.next-id` File

Create a simple counter file to enable unified numbering:

```bash
echo "1" > agent-output/.next-id
```

**What it does:**

  - When Analyst creates analysis `080`, Planner inherits `080` for the plan
  - QA, UAT, Implementation all use `080` too
  - Easy to follow: `analysis-080.md` → `plan-080.md` → `qa-080.md` → `uat-080.md`

**If you have existing plans:** Start with your highest plan number + 1:

```bash
echo "75" > agent-output/.next-id  # If your highest plan is 074
```

**How it works:**

1.  Originating agents (Analyst, Planner) read the number, use it, then increment
2.  Downstream agents (QA, UAT, Implementer) inherit the ID from their source document
3.  Completed documents automatically move to `closed/` subfolders after commit

That's it\! The agents handle the rest automatically.

-----

## Model Test Runs & Failure Capture

Use the reference protocol and template to run end-to-end agent/model checks and preserve failures for later analysis:

  - Protocol: [.github/reference/model-test-run-protocol.md](https://www.google.com/search?q=.github/reference/model-test-run-protocol.md)
  - Failure report template: [.github/reference/model-failure-report-template.md](https://www.google.com/search?q=.github/reference/model-failure-report-template.md)
  - Run artifacts location: `agent-output/test-runs/`

Recommended flow:

1.  Create a run folder using the naming convention in the protocol.
2.  Execute the scenario with explicit acceptance criteria.
3.  If anything fails, fill `03-failure-report.md` and attach evidence under `evidence/`.
4.  Re-run after fixes and mark the report verified.

-----

## Agent-by-Agent Guide

### 01a-Roadmap – Product Vision & Epics

**Role**: Owns product vision and outcome-focused epics, maintains the product roadmap.

**Use when**:

  - Defining or revising product direction and epics
  - Checking if a plan/feature still aligns with the Master Product Objective

**Example handoff prompts**:

  - To Requirements: "Epic is defined. Ready for discovery and requirements detailing."
  - To Planner: "Epic is ready for detailed implementation planning."

**Tips**:

  - Talk about **user outcomes and business value**, not implementation details.
  - Seeds global JIT context pointers to ensure compliance across the epic.

-----

### 01b-Requirements – Product Owner & Analyst

**Role**: Translates roadmap epics into detailed, testable requirements (BDD/Gherkin) and scopes boundaries.

**Use when**:

  - An epic is defined but needs concrete acceptance criteria before planning can begin.
  - You need to establish strict "in scope" vs "out of scope" guardrails.

**Tips**:

  - Engages in discovery by asking you edge-case questions.
  - Forwards and expands JIT context pointers to the Planner.

-----

### 02a-Planner – High-Rigor Implementation Planning

**Role**: Turns roadmap epics and requirements into concrete, implementation-ready plans (WHAT/WHY, not HOW).

**Use when**:

  - Requirements are locked and you need a structured plan before coding.
  - Scope needs to be broken into implementable milestones.

**Tips**:

  - Planner writes **no code** and defines **no test cases**; it shapes the work for others.
  - Serves as the primary orchestrator for the "Review Triad" (Analyst, Architect, Security, Critic).

-----

### 02b-Analyst – Deep Technical/Context Research

**Role**: Investigates unknowns, APIs, performance questions, and tricky tradeoffs.

**Use when**:

  - The Planner or Implementer hits technical uncertainty.
  - You need API experiments, benchmarks, or comparative analysis.

**Tips**:

  - Use Analyst to **de-risk decisions** before committing to an approach.
  - Converts unknowns to evidence. Proposes validation paths if certainty is impossible.

-----

### 02c-Architect – System & Design Decisions

**Role**: Maintains architecture, patterns, boundaries, and high-level design decisions.

**Use when**:

  - A feature affects system structure, boundaries, or cross-cutting concerns.
  - You need ADRs or architectural guidance for a plan.

**Tips**:

  - Enforces "Den Gyldne Rengøringsregel" (leave architecture cleaner than found).
  - Defines WHERE things live and how they interact, not the exact code.

-----

### 02d-Security – Comprehensive Security Audit

**Role**: Security specialist reviewing plans and code for vulnerabilities and compliance.

**Use when**:

  - A feature touches sensitive data, auth, or external interfaces.
  - You want a targeted security audit or threat model.

**Tips**:

  - Applies a rigorous 5-phase framework (Architecture, Code, Dependencies, Infra, Compliance).
  - Provides actionable remediation guidance.

-----

### 02e-Critic – Plan Reviewer & Program Manager

**Role**: Critically reviews plans (and sometimes architecture/roadmap) before implementation.

**Use when**:

  - A plan is "done" and you need a quality gate before Technical Design.

**Tips**:

  - Rejects weak plans, missing JIT context pointers, and unresolved open questions.
  - Treat Critic as your pre‑implementation "red team" for plans.

-----

### 02f-Designer – Technical Designer

**Role**: Translates approved plans into Low-Level Design (LLD), component maps, and Mermaid diagrams.

**Use when**:

  - A plan has cleared the Critic and needs concrete file-level mapping before coding.

**Tips**:

  - Explicitly maps features into the `app/core/adapters` parity structure.
  - Gets architectural sign-off before handing off to the Implementer.

-----

### 03a-Implementer – Coding & Tests

**Role**: Writes and modifies code, implements the approved plan, and ensures tests exist and pass.

**Use when**:

  - The plan and technical design have been approved and you’re ready to make code changes.

**Tips**:

  - Enforces a strict **TDD Gate**—writes and runs failing tests before writing production code.
  - Relies heavily on the JIT Context compiler script to stay within token limits.

-----

### 03b-TestRunner – Pipeline Specialist

**Role**: Executes long-running integration suites, E2E tests, and Docker orchestrations.

**Use when**:

  - The Implementer needs to run a heavy pipeline or debug a microservice crash.

**Tips**:

  - Hunts down stack traces from underlying backend services using `docker logs` and returns deterministic evidence.

-----

### 03c-CodeReviewer – Code Quality Gate

**Role**: Reviews code quality, architecture alignment, and maintainability before QA.

**Use when**:

  - Implementation is complete and ready for quality review.

**Tips**:

  - CodeReviewer can **reject on code quality alone**.
  - Checks SOLID, DRY, YAGNI, TDD compliance, and architectural alignment.

-----

### 04a-QA – Testing Strategy & Execution

**Role**: Designs test strategy, ensures coverage, and runs tests to validate technical quality.

**Use when**:

  - Code review is complete and you want a thorough technical test pass.

**Tips**:

  - QA focuses on **tests, coverage, and technical risk**, not business value.
  - Validates the test execution evidence before approving a handoff to UAT.

-----

### 04b-UAT – Product Owner / Value Validation

**Role**: Validates that implementation delivers the plan’s **value statement** and user outcomes.

**Use when**:

  - QA is complete and you want to confirm that the feature actually solves the intended problem.

**Tips**:

  - Assesses code against the original Roadmap/Planner value statement, not just tests.
  - Expect a clear decision: **APPROVED FOR RELEASE** or **NOT APPROVED**.

-----

### 05a-DevOps – Packaging & Release

**Role**: Ensures packaging/versioning is correct and executes releases.

**Use when**:

  - QA and UAT are complete and you’re ready to prepare/publish a release.

**Tips**:

  - DevOps checks versions, packaging, tags, registry publish, etc.
  - **Must ask user for a final "yes" before releasing/pushing.**

-----

### 05b-Retrospective – Lessons Learned

**Role**: Runs post‑implementation/post‑release retrospectives focusing on process, not blame.

**Use when**:

  - A feature has been deployed and you want to capture systemic process gaps.

**Tips**:

  - Expect structured retrospectives defining clear controls and process-improvement candidates.

-----

### 05c-ProcessImprovement – Evolving Agents & Workflow

**Role**: Reads retrospectives and updates the **agent instructions/workflow** (with your approval).

**Use when**:

  - You have retrospectives and want to evolve how the agents work together.

**Tips**:

  - This is the only agent that should routinely edit `.agent.md` files.
  - Converts retrospective signals directly into updated agent instructions.

-----

## Putting It All Together

  - Start with **01a-Roadmap** for vision, then **01b-Requirements** for scoping.
  - Use **02a-Planner** for a concrete plan, refined by **02b-Analyst / 02c-Architect / 02d-Security / 02e-Critic**.
  - Map the low-level design with **02f-Designer**.
  - Hand off to **03a-Implementer** (and **03b-TestRunner**) for TDD coding.
  - Verify technical quality via **03c-CodeReviewer** and **04a-QA**.
  - Validate business value with **04b-UAT**.
  - Release via **05a-DevOps**.
  - Capture lessons with **05b-Retrospective** and evolve the system via **05c-ProcessImprovement**.
  - **All agents use Native WF nodes** via the `workflow-memory` skill. Agents function without it, but cross-session context and handoff quality improve significantly when maintained natively.

<