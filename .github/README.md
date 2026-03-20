# Coding Agents

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
| **01-Roadmap** | Product vision and epics |
| **02-Planner** | Implementation-ready plans (WHAT, not HOW) |
| **03-Analyst** | Deep technical research |
| **04-Architect** | System design and patterns |
| **05-Security** | Comprehensive security assessment |
| **06-Critic** | Plan quality review |
| **07-Implementer** | Code and tests |
| **08-Code Reviewer** | Code quality gate before QA |
| **09-QA** | Test strategy and verification |
| **10-UAT** | Business value validation |
| **11-DevOps** | Packaging and releases |
| **12-Retrospective** | Lessons learned |
| **13-Process Improvement** | Workflow evolution |

Each agent has **clear constraints** (Planner can't write code, Implementer can't redesign) and produces **structured documents** that create an audit trail.

Use as many or as few as you need, in any order. They are designed to know their own role and work together with other agents in this repo. They are designed to work together to create a structured and auditable development process. They are also designed to challenge each other to ensure the best possible outcome.

## Quick Start

### 1. Get the Agents

```bash
git clone https://github.com/groupzer0/agents.git
```

### 2. Add to Your Project

Copy agents to your workspace (per-repo, recommended):
```text
your-project/
└── .github/
    └── agents/
        ├── 02-planner.agent.md
        ├── 07-implementer.agent.md
        └── ... (others you need)
```

Or install them at the **user level** so they are available across all VS Code workspaces. User-level agents are stored in your [VS Code profile folder](https://code.visualstudio.com/docs/configure/profiles):

- **Linux**: `~/.config/Code/User/`
- **macOS**: `~/Library/Application Support/Code/User/`
- **Windows**: `%APPDATA%\Code\User\`

> [!TIP]
> The easiest way to create a user-level agent is via the Command Palette: **Chat: New Custom Agent** → select **User profile**. VS Code will place it in the correct location automatically.


### 3. Use in Copilot Chat

In VS Code, select your agent from the **agents dropdown** at the top of the Chat panel, then type your prompt:

```text
Create a plan for adding user authentication
```

> [!NOTE]
> Unlike built-in participants (e.g., `@workspace`), custom agents are **not** invoked with the `@` symbol. You must select them from the dropdown or use the Command Palette.

### 4. Obsidian Workflow Context

These agents are designed to benefit from Obsidian-backed workflow context for cross-session continuity.

With Obsidian enabled, agents can store and retrieve durable WF-node context (decisions, constraints, and handoff links) across sessions. Without Obsidian, agents still work, but handoffs become more manual.

Enable the `obsidian` MCP server in your environment and ensure agents have access to the `obsidian_*` tools.

### 5. (Optional) Use with GitHub Copilot CLI

You can also use these agents with the GitHub Copilot CLI by placing your `.agent.md` files under `.github/agents/` in each repository where you run the CLI, then invoking them with commands like:

```bash
copilot --agent 02-planner --prompt "Create a plan for adding user authentication"
```

**Known limitation (user-level agents):** The Copilot CLI currently has an upstream bug where user-level agents in `~/.copilot/agents/` are not loaded, even though they are documented ([github/copilot-cli#452](https://github.com/github/copilot-cli/issues/452)). This behavior and the recommended per-repository workaround were identified and documented by @rjmurillo. Until the bug is fixed, prefer `.github/agents/` in each repo.


## Documentation

| Document | Purpose |
|----------|---------|
| [USING-AGENTS.md](USING-AGENTS.md) | Quick start guide (5 min read) |
| [AGENTS-DEEP-DIVE.md](AGENTS-DEEP-DIVE.md) | Comprehensive documentation |
| [reference/model-test-run-protocol.md](reference/model-test-run-protocol.md) | Standard protocol for model test runs |
| [reference/model-failure-report-template.md](reference/model-failure-report-template.md) | Structured failure report template for reproducible debugging |
| [reference/strict-workflow-governance.md](reference/strict-workflow-governance.md) | Mandatory strict workflow contract (context, tools, skills, role gates) |
| [reference/required-files-catalog.md](reference/required-files-catalog.md) | Required file inventory and recovery/scaffolding rules |
| [CHANGELOG.md](CHANGELOG.md) | Notable repository changes |
| [obsidian-workflow skill](skills/obsidian-workflow/SKILL.md) | WF-node memory workflow patterns |
| [document-conversion-pandoc skill](skills/document-conversion-pandoc/SKILL.md) | Standardized PDF/EPUB to Markdown conversion workflow |

---

### Typical Workflow

```text
01-Roadmap → 02-Planner → 03-Analyst/04-Architect/05-Security/06-Critic → 07-Implementer → 08-Code Reviewer → 09-QA → 10-UAT → 11-DevOps
```

1. **Roadmap** defines what to build and why
2. **Planner** creates a structured plan at the feature level or smaller
3. **Analyst** researches unknowns
4. **Architect** ensures design fit. Enforces best practices.
5. **Security** audits for vulnerabilities. Recommends best practices.
6. **Critic** reviews plan quality
7. **Implementer** writes code
8. **Code Reviewer** verifies code quality
9. **QA** verifies tests. Ensures robust test coverage
10. **UAT** confirms business value was delivered
11. **DevOps** releases (with user approval)

---

## Key Features

### 🎯 Separation of Concerns
Each agent has one job. Planner plans. Implementer implements. No scope creep.

### 📝 Document-Driven
Agents produce Markdown documents in `agent-output/`. Every decision is recorded.

### 🔒 Quality Gates
Critic reviews plans. Security audits code. QA verifies tests. Nothing ships without checks.

### 🧠 Durable Context
With Obsidian WF nodes enabled, agents can carry decisions and handoff context across sessions.

### 🔄 Handoffs
Agents hand off to each other with context. No lost information between phases.

---

## Obsidian Workflow Integration

Obsidian (via MCP) provides a durable relational context layer for agents and tools. It solves a specific problem: assistants lose cross-session context unless decisions and handoffs are stored in a structured, retrievable way.

With Obsidian enabled, these agents can persist and retrieve WF-node context across sessions via the `obsidian_*` tools.

### MCP Tool Prefixes (`.vscode/mcp.json`)

VS Code MCP tools are namespaced by the MCP server name. The server key you configure becomes the tool prefix.

This repo ships an example MCP configuration at `.vscode/mcp.json` with these server names:

| MCP server name | Tool prefix |
|---|---|
| `filesystem` | `filesystem_*` |
| `github` | `github_*` |
| `analyzer` | `analyzer_*` |
| `planka` | `planka_*` |
| `obsidian` | `obsidian_*` |

If you rename a server (e.g. `filesystem` → `fs`), the tool prefix changes accordingly (e.g. `fs_*`). Ensure your `.agent.md` files allow the tool namespaces they need.

---

## Repository Structure

```text
.
├── AGENTS-DEEP-DIVE.md
├── CHANGELOG.md
├── LICENSE
├── README.md
├── USING-AGENTS.md
├── workflows/
│   └── markdown-lint.yml
└── vs-code-agents/
    ├── agents/
    │   ├── 01-roadmap.agent.md
    │   ├── 02-planner.agent.md
    │   ├── 03-analyst.agent.md
    │   ├── 04-architect.agent.md
    │   ├── 05-security.agent.md
    │   ├── 06-critic.agent.md
    │   ├── 07-implementer.agent.md
    │   ├── 08-code-reviewer.agent.md
    │   ├── 09-qa.agent.md
    │   ├── 10-uat.agent.md
    │   ├── 11-devops.agent.md
    │   ├── 12-retrospective.agent.md
    │   └── 13-pi.agent.md
    ├── reference/
    │   ├── model-failure-report-template.md
    │   ├── model-test-run-protocol.md
    │   ├── required-files-catalog.md
    │   ├── strict-workflow-governance.md
    │   └── uncertainty-review-template.md
    └── skills/
        ├── analysis-methodology/
        ├── architecture-patterns/
        ├── code-review-checklist/
        ├── code-review-standards/
        ├── cross-repo-contract/
        ├── document-conversion-pandoc/
        ├── document-lifecycle/
        ├── engineering-standards/
        ├── planka-workflow/
        ├── release-procedures/
        ├── security-patterns/
        └── testing-patterns/
```

---

## Security Agent Highlight

The **Security Agent** has been enhanced to provide truly comprehensive security reviews:

### Five-Phase Framework
1. **Architectural Security**: Trust boundaries, STRIDE threat modeling, attack surface mapping
2. **Code Security**: OWASP Top 10, language-specific vulnerability patterns
3. **Dependency Security**: CVE scanning, supply chain risk assessment
4. **Infrastructure Security**: Headers, TLS, container security
5. **Compliance**: OWASP ASVS, NIST, industry standards

### Why This Matters

Most developers don't know how to conduct thorough security reviews. They miss:
- Architectural weaknesses (implicit trust, flat networks)
- Language-specific vulnerabilities (prototype pollution, pickle deserialization)
- Supply chain risks (abandoned packages, dependency confusion)
- Compliance gaps (missing security headers, weak TLS)

The Security Agent systematically checks all of these, producing actionable findings with severity ratings and remediation guidance.You can then hand this off to the Planner agent and the Implementer to address. 

See [05-security.agent.md](agents/05-security.agent.md) for the full specification.

---

## Customization

### Modify Existing Agents

Edit `.agent.md` files to adjust:
- `description`: What shows in Copilot
- `tools`: Which VS Code tools the agent can use
- `handoffs`: Other agents it can hand off to
- Responsibilities and constraints

### Create New Agents

1. Create `your-agent.agent.md` following the existing format
2. Define purpose, responsibilities, constraints
3. Include the Obsidian workflow handoff section
4. Add to `.github/agents/` in your workspace

If you are contributing to this repository directly, place agent specs under `.github/agents/`.

---

## Skills Catalog

All reusable skills live under `skills/`. Every skill includes a `SKILL.md`, and some skills include optional `references/` resources.

| Skill | Focus | Included resources |
|-------|-------|--------------------|
| [analysis-methodology](skills/analysis-methodology/SKILL.md) | Systematic investigation workflow (confidence levels, gap tracking, handoff protocol) | `SKILL.md` |
| [architecture-patterns](skills/architecture-patterns/SKILL.md) | Architecture patterns, ADR templates, and anti-pattern detection | `SKILL.md`, `references/*` |
| [code-review-checklist](skills/code-review-checklist/SKILL.md) | Pre/post-implementation review criteria with severity-oriented checks | `SKILL.md` |
| [code-review-standards](skills/code-review-standards/SKILL.md) | Review checklist, severity definitions, and review document templates | `SKILL.md` |
| [cross-repo-contract](skills/cross-repo-contract/SKILL.md) | Multi-repo API contract discovery, type safety, and coordinated contract changes | `SKILL.md` |
| [document-lifecycle](skills/document-lifecycle/SKILL.md) | Unified numbering, terminal statuses, close procedures, and orphan detection | `SKILL.md` |
| [engineering-standards](skills/engineering-standards/SKILL.md) | SOLID/DRY/YAGNI/KISS guidance with detection and refactoring patterns | `SKILL.md` |
| [obsidian-workflow](skills/obsidian-workflow/SKILL.md) | Relational memory graph workflow with strict WF-node conventions | `SKILL.md`, `references/*` |
| [planka-workflow](skills/planka-workflow/SKILL.md) | Agile workflow synchronization across markdown artifacts, Obsidian context, and Planka execution | `SKILL.md`, `references/*` |
| [release-procedures](skills/release-procedures/SKILL.md) | Versioning, release verification, and deployment process checks | `SKILL.md`, `references/*` |
| [security-patterns](skills/security-patterns/SKILL.md) | OWASP + language-specific vulnerability patterns and remediation guidance | `SKILL.md`, `references/*` |
| [testing-patterns](skills/testing-patterns/SKILL.md) | TDD workflow, test pyramid, coverage strategy, mocking, and anti-patterns | `SKILL.md`, `references/*` |

---

## Recent Updates

Recent commits introduced significant improvements to agent workflow and capabilities:

### Uncertainty-Aware Issue Analysis (2026-01-15)

Agents now explicitly avoid forced root-cause narratives when evidence is missing.

- **Analyst**: Uses an objective hard pivot trigger (timebox/evidence gate) to switch from RCA attempts to system hardening + telemetry requirements.
- **Architect**: Treats insufficient observability as an architectural risk; defines normal vs debug logging guidance and a minimum viable incident telemetry baseline.
- **QA**: Validates diagnosability improvements; prefers asserting structured telemetry fields/events over brittle log string matching.
- **Template**: `.github/reference/uncertainty-review-template.md` provides a repeatable output format.

### Skills System (2025-12-19)

Agents now use **Claude Skills**—modular, reusable instruction sets that load on-demand:

For the current complete list of skills and included references/scripts, see [Skills Catalog](#skills-catalog).

**Skill Placement:**
- **VS Code Stable (1.107.1)**: Place in `.claude/skills/`
- **VS Code Insiders**: Place in `.github/skills/`

> [!NOTE]
> These locations are changing with upcoming VS Code releases. The `.github/skills/` location is becoming the standard. See the [VS Code Agent Skills documentation](https://code.visualstudio.com/docs/copilot/customization/agent-skills) for the latest guidance.

### Key Agent Flow Improvements

- **Numbered agent IDs**: Agent names and filenames now follow a stable numbered sequence (`01-...` through `13-...`) for predictable ordering and handoff consistency.
- **Planka workflow sync (status-only runtime)**: Agents now include a mandatory `planka-workflow` contract to keep workflow cards, list moves, stopwatch transitions, and handoff comments synchronized with markdown artifacts.
- **TDD mandatory**: Implementer and QA now require Test-Driven Development for new feature code
- **Two-stage release**: DevOps commits locally first; pushes only on explicit release approval
- **Document status tracking**: All agents update Status fields in planning docs ("Draft", "In Progress", "Released")
- **Open Question Gate**: Implementer halts if plans have unresolved questions; requires explicit user acknowledgment to proceed
- **Obsidian workflow memory**: Durable context is now maintained through `obsidian-workflow` WF-node conventions
- **Slimmed Security agent**: Reduced by 46% using skill references instead of inline content

### Cross-Repository Contract Skill (2025-12-26)

New `cross-repo-contract` skill for projects with runtime + backend repos that need to stay aligned:

- **Contract discovery**: Agents check `api-contract/` or `.contracts/` for type definitions
- **Type safety enforcement**: Implementer verifies contract definitions before coding API endpoints/clients
- **Breaking change coordination**: Plans must document contract changes and sync dependencies
- **Quality gate**: Critic verifies multi-repo plans address contract adherence

Integrated into Architect, Planner, Implementer, and Critic agents.

### Document Lifecycle System (2025-12-24)

New `document-lifecycle` skill implementing:

- **Unified numbering**: All documents in a work chain share the same ID (analysis 080 → plan 080 → qa 080 → uat 080)
- **Automated closure**: Documents move to `closed/` subfolders after commit
- **Orphan detection**: Agents self-check + Roadmap periodic sweep

This keeps active plans visible while archiving completed work for traceability.

### Previous Updates

- **Refined Memory contract (2025-12-16)**: All core agents share a unified memory contract. Agents function without memory but greatly benefit from its use.
- **Aligned agent tool names with VS Code APIs (2025-12-16)**: Agent `tools` definitions now use official VS Code agent tool identifiers.
- **Added subagent usage patterns (2025-12-15)**: Planner, Implementer, QA, Analyst, and Security document how to invoke each other as scoped subagents.
- **Background Implementer mode (2025-12-15)**: Implementation can run as local chat or background agent in isolated Git worktree.

## Contributing

Contributions welcome! Areas of interest:

- **Agent refinements**: Better constraints, clearer responsibilities
- **New agents**: For specialized workflows (e.g., Documentation, Performance)
- **Obsidian workflow patterns**: Better retrieval/storage and handoff strategies
- **Documentation**: Examples, tutorials, troubleshooting

This repository also runs an automatic **Markdown lint** check in GitHub Actions on pushes and pull requests that touch `.md` files. The workflow uses `markdownlint-cli2` with a shared configuration, and helps catch issues like missing fenced code block languages (MD040) early in review. This lint workflow was proposed based on feedback and review from @rjmurillo.

---

## Requirements

- VS Code with GitHub Copilot
- For durable context: An Obsidian MCP server enabled in your environment

---

## License

MIT License - see [LICENSE](LICENSE)

---

## Related Resources

- [GitHub Copilot Agents Documentation](https://code.visualstudio.com/docs/copilot/copilot-agents)
- [VS Code MCP Documentation](https://code.visualstudio.com/docs/copilot/customization/mcp)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
