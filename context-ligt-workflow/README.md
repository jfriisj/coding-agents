# VS Code Agents (Memory)

> A multi-agent workflow system for GitHub Copilot in VS Code that brings structure, quality gates, and long-term memory to AI-assisted development.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## What This Is

This repository is a **reference implementation** for using a Memory-backed persistent memory layer in a multi-agent workflow.

These agents are intentionally designed to take advantage of long-term, workspace-scoped memory. They demonstrate what agent workflows look like when memory is treated as infrastructure rather than chat history.

## The Problem

AI coding assistants are powerful but chaotic:
- They forget context between sessions
- They try to do everything at once (plan, code, test, review)
- They skip quality gates and security reviews
- They lose track of decisions made earlier

## The Solution

This repository provides **specialized AI agents** that each own a specific part of your development workflow:

| Agent | Role |
|-------|------|
| **01a-Roadmap** | Product vision and epics |
| **01b-Requirements** | Product Owner and Requirements Analyst |
| **02a-Planner** | Implementation-ready plans (WHAT, not HOW) |
| **02b-Analyst** | Deep technical research |
| **02c-Architect** | System design and patterns |
| **02d-Security** | Comprehensive security assessment |
| **02e-Critic** | Plan quality review |
| **02f-Designer** | Technical Designer and diagram mapping |
| **03a-Implementer** | Code and tests |
| **03b-TestRunner** | Pipeline and test execution specialist |
| **03c-CodeReviewer** | Code quality gate before QA |
| **04a-QA** | Test strategy and verification |
| **04b-UAT** | Business value validation |
| **05a-DevOps** | Packaging and releases |
| **05b-Retrospective** | Lessons learned |
| **05c-ProcessImprovement** | Workflow evolution |

Each agent has **clear constraints** (Planner can't write code, Implementer can't redesign) and produces **structured documents** that create an audit trail.

Use as many or as few as you need, in any order. They are designed to know their own role and work together with other agents in this repo to create a structured and auditable development process.

## Quick Start

### 1. Get the Agents

```bash
git clone [https://github.com/jfriisj/coding-agents](https://github.com/jfriisj/coding-agents)
````

### 2\. Add to Your Project

Copy agents to your workspace (per-repo, recommended):

```text
your-project/
└── .github/
    └── agents/
        ├── 02a-Planner.agent.md
        ├── 03a-Implementer.agent.md
        └── ... (others you need)
```

Or install them at the **user level** so they are available across all VS Code workspaces. User-level agents are stored in your [VS Code profile folder](https://code.visualstudio.com/docs/configure/profiles):

  - **Linux**: `~/.config/Code/User/`
  - **macOS**: `~/Library/Application Support/Code/User/`
  - **Windows**: `%APPDATA%\Code\User\`

> [\!TIP]
> The easiest way to create a user-level agent is via the Command Palette: **Chat: New Custom Agent** → select **User profile**. VS Code will place it in the correct location automatically.

### 3\. Use in Copilot Chat

In VS Code, select your agent from the **agents dropdown** at the top of the Chat panel, then type your prompt:

```text
Create a plan for adding user authentication
```

> [\!NOTE]
> Unlike built-in participants (e.g., `@workspace`), custom agents are **not** invoked with the `@` symbol. You must select them from the dropdown or use the Command Palette.

### 4\. Native Workflow Memory Context

These agents use a lightweight, native markdown structure (`workflow-memory`) for cross-session continuity.

By writing and reading concise `WF-*.md` nodes in the `workflows/` directory using standard file tools, agents can store and retrieve durable context (decisions, constraints, and handoff links) across sessions entirely natively, with zero overhead or external servers required.

### 5\. (Optional) Use with GitHub Copilot CLI

You can also use these agents with the GitHub Copilot CLI by placing your `.agent.md` files under `.github/agents/` in each repository where you run the CLI, then invoking them with commands like:

```bash
copilot --agent 02a-Planner --prompt "Create a plan for adding user authentication"
```

## Documentation

| Document | Purpose |
|----------|---------|
| [USING-AGENTS.md](https://www.google.com/search?q=USING-AGENTS.md) | Quick start guide (5 min read) |
| [AGENTS-DEEP-DIVE.md](https://www.google.com/search?q=AGENTS-DEEP-DIVE.md) | Comprehensive documentation |
| [reference/model-test-run-protocol.md](https://www.google.com/search?q=reference/model-test-run-protocol.md) | Standard protocol for model test runs |
| [reference/model-failure-report-template.md](https://www.google.com/search?q=reference/model-failure-report-template.md) | Structured failure report template for reproducible debugging |
| [reference/strict-workflow-governance.md](https://www.google.com/search?q=reference/strict-workflow-governance.md) | Mandatory strict workflow contract (context, tools, skills, role gates) |
| [reference/required-files-catalog.md](https://www.google.com/search?q=reference/required-files-catalog.md) | Required file inventory and recovery/scaffolding rules |
| [CHANGELOG.md](https://www.google.com/search?q=CHANGELOG.md) | Notable repository changes |
| [workflow-memory skill](https://www.google.com/search?q=skills/workflow-memory/SKILL.md) | Relational memory graph using native markdown WF nodes |

-----

### Typical Workflow

```text
01a-Roadmap → 01b-Requirements → 02a-Planner → 02[b-f]-Review Triad → 03a-Implementer → 03c-CodeReviewer → 04a-QA → 04b-UAT → 05a-DevOps
```

1.  **Roadmap** defines what to build and why
2.  **Requirements** translates epics into testable acceptance criteria
3.  **Planner** creates a structured plan at the feature level or smaller
4.  **Review Triad** (Analyst/Architect/Security/Critic/Designer) validates the plan and maps the architecture
5.  **Implementer** writes code using TDD
6.  **Code Reviewer** verifies code quality
7.  **QA** verifies tests and ensures robust test coverage
8.  **UAT** confirms business value was delivered
9.  **DevOps** releases (with user approval)

-----

## Key Features

### 🎯 Separation of Concerns

Each agent has one job. Planner plans. Implementer implements. No scope creep.

### 📝 Document-Driven

Agents produce Markdown documents in `agent-output/`. Every decision is recorded.

### 🔒 Quality Gates

Critic reviews plans. Security audits code. QA verifies tests. Nothing ships without checks.

### 🧠 Durable Context

Through the `workflow-memory` skill, agents carry decisions and JIT-compiled handoff context across sessions natively.

### 🔄 Handoffs

Agents hand off to each other with context. No lost information between phases.

-----

## Native Workflow Memory Integration

The repository uses native Markdown file relationships to provide a durable context layer. It solves a specific problem: assistants lose cross-session context unless decisions and handoffs are stored in a structured, retrievable way.

Agents read and write `WF-*.md` files into `agent-output/workflows/` using standard filesystem operations. This creates a highly token-efficient memory graph without external dependencies.

### MCP Tool Prefixes (`.vscode/mcp.json`)

VS Code MCP tools are namespaced by the MCP server name. The server key you configure becomes the tool prefix.

This repo ships an example MCP configuration at `.vscode/mcp.json` with these server names:

| MCP server name | Tool prefix |
|---|---|
| `filesystem` | `filesystem_*` |
| `github` | `github_*` |
| `analyzer` | `analyzer_*` |

Ensure your `.agent.md` files allow the tool namespaces they need.

-----

## Skills Catalog

All reusable skills live under `.github/skills/`. Every skill includes a `SKILL.md`, and some skills include optional `references/` resources.

| Skill | Focus | Included resources |
|-------|-------|--------------------|
| [analysis-methodology](https://www.google.com/search?q=.github/skills/analysis-methodology/SKILL.md) | Systematic investigation workflow (confidence levels, gap tracking, handoff protocol) | `SKILL.md` |
| [architecture-patterns](https://www.google.com/search?q=.github/skills/architecture-patterns/SKILL.md) | Architecture patterns, ADR templates, and anti-pattern detection | `SKILL.md`, `references/*` |
| [code-review-checklist](https://www.google.com/search?q=.github/skills/code-review-checklist/SKILL.md) | Pre/post-implementation review criteria with severity-oriented checks | `SKILL.md` |
| [code-review-standards](https://www.google.com/search?q=.github/skills/code-review-standards/SKILL.md) | Review checklist, severity definitions, and review document templates | `SKILL.md` |
| [cross-repo-contract](https://www.google.com/search?q=.github/skills/cross-repo-contract/SKILL.md) | Multi-repo API contract discovery, type safety, and coordinated contract changes | `SKILL.md` |
| [document-lifecycle](https://www.google.com/search?q=.github/skills/document-lifecycle/SKILL.md) | Unified numbering, terminal statuses, close procedures, and orphan detection | `SKILL.md` |
| [engineering-standards](https://www.google.com/search?q=.github/skills/engineering-standards/SKILL.md) | SOLID/DRY/YAGNI/KISS guidance with detection and refactoring patterns | `SKILL.md` |
| [workflow-memory](https://www.google.com/search?q=.github/skills/workflow-memory/SKILL.md) | Native relational memory graph and JIT context compilation rules | `SKILL.md` |
| [release-procedures](https://www.google.com/search?q=.github/skills/release-procedures/SKILL.md) | Versioning, release verification, and deployment process checks | `SKILL.md`, `references/*` |
| [security-patterns](https://www.google.com/search?q=.github/skills/security-patterns/SKILL.md) | OWASP + language-specific vulnerability patterns and remediation guidance | `SKILL.md`, `references/*` |
| [testing-patterns](https://www.google.com/search?q=.github/skills/testing-patterns/SKILL.md) | TDD workflow, test pyramid, coverage strategy, mocking, and anti-patterns | `SKILL.md`, `references/*` |

-----

## Requirements

  - VS Code with GitHub Copilot
  - Node.js/uv (for running standard local analyzer/filesystem tools)

-----

## License

MIT License - see [LICENSE](https://www.google.com/search?q=LICENSE)

````

---

### 2. Opdateret `USING-AGENTS.md`
```markdown
# Using the Agents

This file contains a high-level overview of these agents and how to get started using them quickly. However, you may find you want or need more guidance. In that case, see the AGENTS-DEEP-DIVE.md file.

## Overview

This repo defines a set of `.agent.md` files that configure specialized AI personas ("agents") for a structured software delivery workflow. Each agent focuses on a specific phase or concern (planning, implementation, QA, UAT, DevOps, etc.), with clear responsibilities, constraints, and handoffs.

A typical high-level workflow looks like:

01a-Roadmap → 01b-Requirements → 02a-Planner → (02b-Analyst, 02c-Architect, 02d-Security, 02e-Critic, 02f-Designer) → 03a-Implementer → 03b-TestRunner → 03c-CodeReviewer → 04a-QA → 04b-UAT → 05a-DevOps → 05b-Retrospective → 05c-ProcessImprovement

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

## Using with GitHub Copilot CLI

These agents were originally written for GitHub Copilot in VS Code, but you can also use them with the GitHub Copilot CLI.

  - Place your `.agent.md` files under `.github/agents/` in each repository where you run the CLI.
  - Then invoke an agent with a command like:

<!-- end list -->

```bash
copilot --agent 02a-Planner --prompt "Create a plan for adding user authentication"
```

### Known limitation (user-level agents)

The Copilot CLI has a known upstream bug ([github/copilot-cli\#452](https://github.com/github/copilot-cli/issues/452)) where **user-level agents in `~/.copilot/agents/` are not loaded**, even though they are documented.

**Workaround:**

  - Use per-repository agents under `.github/agents/` instead of relying on `~/.copilot/agents/`.
  - If you prefer a single source of truth, you can keep your agents in one folder and copy or symlink them into each repo’s `.github/agents/` directory.

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
  - Keep responsibilities and constraints intact unless you intentionally want to change your development process.

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

## Putting It All Together

  - Start with **Roadmap** for vision, then **Planner** for a concrete plan.
  - Use **Architect / Analyst / Security / Critic / Designer** to refine and de‑risk the plan and architecture.
  - Hand off to **Implementer** (and **TestRunner**) for code and tests, then **Code Reviewer** and **QA** for technical quality, **UAT** for value, **DevOps** for release.
  - Afterward, let **Retrospective** and **Process Improvement** update how you work next time.
  - **All agents use Native WF nodes** via the `workflow-memory` skill. Agents function without it, but cross-session context and handoff quality improve significantly when maintained.

